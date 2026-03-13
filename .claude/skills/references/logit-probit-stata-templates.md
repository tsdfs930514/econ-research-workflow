# Logit/Probit & Treatment Effects Templates

Code templates for `/run-logit-probit`. Covers Stata estimation (logit, probit, teffects,
clogit, extensions) and Python cross-validation.

## Table of Contents

- [Step 1: Standard Logit/Probit Estimation](#step-1-standard-estimation)
- [Step 2: Propensity Score Estimation](#step-2-propensity-score)
- [Step 3: Treatment Effects (RA, IPW, AIPW)](#step-3-treatment-effects)
- [Step 4: Conditional Logit](#step-4-conditional-logit)
- [Step 5: Diagnostics](#step-5-diagnostics)
- [Step 6: Extensions](#step-6-extensions)
- [Step 7: Python Cross-Validation](#step-7-python-cross-validation)

---

## Step 1: Standard Estimation

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 1: Standard Estimation & Marginal Effects
  Reports AME (Average Marginal Effects) and MEM (Marginal Effects at Means)
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_01_estimation.log", replace

use "DATASET_PATH", clear

eststo clear

* --- Probit ---
eststo probit_main: probit OUTCOME_VAR TREATMENT_VAR COVARIATES, ///
    vce(cluster CLUSTER_VAR)

* Average Marginal Effects (AME) -- preferred for most applications
margins, dydx(*) post
eststo probit_ame

* Re-run probit for MEM
probit OUTCOME_VAR TREATMENT_VAR COVARIATES, vce(cluster CLUSTER_VAR)
* Marginal Effects at Means (MEM)
margins, dydx(*) atmeans post
eststo probit_mem

* --- Logit ---
eststo logit_main: logit OUTCOME_VAR TREATMENT_VAR COVARIATES, ///
    vce(cluster CLUSTER_VAR)

* AME for logit
margins, dydx(*) post
eststo logit_ame

* --- Comparison: LPM (Linear Probability Model) ---
eststo lpm: reghdfe OUTCOME_VAR TREATMENT_VAR COVARIATES, ///
    absorb(FIXED_EFFECTS) vce(cluster CLUSTER_VAR)

* --- Table ---
esttab probit_main logit_main probit_ame logit_ame lpm ///
    using "output/tables/tab_logit_probit.tex", ///
    se(4) b(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(TREATMENT_VAR) label booktabs replace ///
    mtitles("Probit" "Logit" "Probit AME" "Logit AME" "LPM") ///
    title("Binary Outcome: Logit, Probit, and LPM") ///
    note("Columns (1)-(2): coefficient estimates." ///
         "Columns (3)-(4): average marginal effects." ///
         "Column (5): linear probability model with FE." ///
         "Standard errors clustered at CLUSTER_VAR level.")

log close
```

---

## Step 2: Propensity Score

Following Acemoglu et al. (2019, JPE) Table A11 pattern.

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 2: Propensity Score Estimation
  Reference: DDCG Table A11
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_02_pscore.log", replace

use "DATASET_PATH", clear

* --- Propensity score via probit ---
probit TREATMENT_VAR COVARIATES i.YEAR_VAR, vce(cluster CLUSTER_VAR)

margins, dydx(COVARIATES) post
eststo pscore_margins

* Predicted propensity score
probit TREATMENT_VAR COVARIATES i.YEAR_VAR, vce(cluster CLUSTER_VAR)
predict _pscore, pr

* --- Diagnostics ---
tabstat _pscore, by(TREATMENT_VAR) stat(mean sd min p5 p25 p50 p75 p95 max n)

* --- Overlap / Common Support ---
twoway (kdensity _pscore if TREATMENT_VAR == 1, lcolor(cranberry) lwidth(medthick)) ///
       (kdensity _pscore if TREATMENT_VAR == 0, lcolor(navy) lwidth(medthick)), ///
    legend(order(1 "Treated" 2 "Control") rows(1)) ///
    title("Propensity Score Overlap") ///
    xtitle("Propensity Score") ytitle("Density")
graph export "output/figures/fig_pscore_overlap.pdf", replace

* --- Trim to common support ---
sum _pscore if TREATMENT_VAR == 1, detail
local trim_lo = r(min)
sum _pscore if TREATMENT_VAR == 0, detail
local trim_hi = r(max)
gen byte common_support = (_pscore >= `trim_lo' & _pscore <= `trim_hi')
tab common_support TREATMENT_VAR

* --- Covariate balance after IPW weighting ---
gen _ipw = cond(TREATMENT_VAR == 1, 1/_pscore, 1/(1-_pscore))

foreach var of varlist COVARIATES {
    sum `var' [aw=_ipw] if TREATMENT_VAR == 1
    local mean_t = r(mean)
    sum `var' [aw=_ipw] if TREATMENT_VAR == 0
    local mean_c = r(mean)
    sum `var'
    local sd_pool = r(sd)
    local std_diff = (`mean_t' - `mean_c') / `sd_pool'
    di "Balance `var': std diff = `std_diff' (target: < 0.1)"
}

log close
```

---

## Step 3: Treatment Effects

Following Acemoglu et al. (2019, JPE) Table 5 pattern.

`teffects` commands (ra, ipw, ipwra, nnmatch) only work with cross-sectional data.
They fail on panel data with repeated observations per unit (r(459) or similar).
For panel data, collapse to a cross-section first or use manual IPW with `reghdfe`.

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 3: Treatment Effects via teffects
  NOTE: teffects requires cross-sectional data (no repeated observations)
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_03_teffects.log", replace

use "DATASET_PATH", clear

eststo clear

* --- 1. Regression Adjustment (RA) ---
cap noisily teffects ra (OUTCOME_VAR COVARIATES) (TREATMENT_VAR), atet
if _rc == 0 {
    eststo tef_ra
    local atet_ra = _b[r1vs0.TREATMENT_VAR]
}
else {
    di "teffects ra failed (likely panel data with repeated obs). Skipping."
}

* --- 2. Inverse Probability Weighting (IPW) with probit ---
cap noisily teffects ipw (OUTCOME_VAR) (TREATMENT_VAR COVARIATES, probit), atet
if _rc == 0 {
    eststo tef_ipw
    local atet_ipw = _b[r1vs0.TREATMENT_VAR]
}
else {
    di "teffects ipw failed (likely panel data). Skipping."
}

* --- 3. Doubly Robust: AIPW (Augmented IPW) ---
cap noisily teffects ipwra (OUTCOME_VAR COVARIATES) (TREATMENT_VAR COVARIATES, probit), atet
if _rc == 0 {
    eststo tef_aipw
    local atet_aipw = _b[r1vs0.TREATMENT_VAR]
}
else {
    di "teffects ipwra failed (likely panel data). Skipping."
}

* --- 4. Nearest Neighbor Matching ---
cap noisily teffects nnmatch (OUTCOME_VAR COVARIATES) (TREATMENT_VAR), ///
    atet nneighbor(5) metric(mahalanobis)
if _rc == 0 {
    eststo tef_nn
    local atet_nn = _b[r1vs0.TREATMENT_VAR]
}
else {
    di "teffects nnmatch failed (likely panel data). Skipping."
}

* --- Comparison table ---
esttab tef_ra tef_ipw tef_aipw tef_nn ///
    using "output/tables/tab_treatment_effects.tex", ///
    se(4) b(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("RA" "IPW" "AIPW" "NN-Match") ///
    label booktabs replace ///
    title("Average Treatment Effect on the Treated (ATET)") ///
    note("RA = regression adjustment. IPW = inverse probability weighting (probit)." ///
         "AIPW = augmented IPW (doubly robust). NN = nearest-neighbor matching." ///
         "AIPW is preferred: consistent if either outcome or treatment model correct.")

log close
```

---

## Step 4: Conditional Logit

Following Mexico Retail Table 5 pattern.

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 4: Conditional Logit (Discrete Choice)
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_04_clogit.log", replace

use "DATASET_PATH", clear

eststo clear
eststo clogit_main: clogit CHOICE_VAR ALT_SPECIFIC_VARS ///
    [pw=WEIGHT_VAR], group(GROUP_VAR) vce(cluster CLUSTER_VAR)

margins, dydx(*) post
eststo clogit_ame

eststo clogit_full: clogit CHOICE_VAR ALT_SPECIFIC_VARS ADDITIONAL_CONTROLS ///
    [pw=WEIGHT_VAR], group(GROUP_VAR) vce(cluster CLUSTER_VAR)

esttab clogit_main clogit_full clogit_ame ///
    using "output/tables/tab_conditional_logit.tex", ///
    se(4) b(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Full Controls" "AME") ///
    label booktabs replace ///
    title("Conditional Logit: Discrete Choice") ///
    note("Conditional logit estimated via clogit." ///
         "Choice groups defined by GROUP_VAR." ///
         "Standard errors clustered at CLUSTER_VAR level.")

log close
```

---

## Step 5: Diagnostics

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 5: Model Diagnostics
  ROC, Hosmer-Lemeshow, link test, classification
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_05_diagnostics.log", replace

use "DATASET_PATH", clear

logit OUTCOME_VAR TREATMENT_VAR COVARIATES, vce(cluster CLUSTER_VAR)

* --- ROC Curve and AUC ---
lroc, title("ROC Curve") note("AUC = area under curve; 0.5 = random, 1.0 = perfect")
graph export "output/figures/fig_roc_curve.pdf", replace
lstat
* AUC > 0.7 acceptable; > 0.8 good; > 0.9 excellent

* --- Hosmer-Lemeshow ---
logit OUTCOME_VAR TREATMENT_VAR COVARIATES
estat gof, group(10)
* Null: model fits well. Reject (p < 0.05) = poor fit

* --- Link Test (Pregibon) ---
linktest
* _hat significant, _hatsq NOT significant = good fit

* --- Classification ---
estat classification

log close
```

---

## Step 6: Extensions

```stata
/*==============================================================================
  Logit/Probit Analysis -- Step 6: Extensions
  Multinomial logit, ordered logit/probit, IV probit
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "output/logs/logit_06_extensions.log", replace

use "DATASET_PATH", clear

* --- Multinomial Logit (unordered categories) ---
eststo mlogit_main: mlogit MULTI_OUTCOME COVARIATES, ///
    vce(cluster CLUSTER_VAR) baseoutcome(BASE_CATEGORY)
margins, dydx(TREATMENT_VAR) predict(outcome(CATEGORY_1)) post

* --- Ordered Logit ---
eststo ologit_main: ologit ORDERED_OUTCOME COVARIATES, ///
    vce(cluster CLUSTER_VAR)
margins, dydx(TREATMENT_VAR) predict(outcome(CATEGORY_1)) post

* --- Ordered Probit ---
eststo oprobit_main: oprobit ORDERED_OUTCOME COVARIATES, ///
    vce(cluster CLUSTER_VAR)

* --- IV Probit (endogenous binary treatment) ---
eststo ivprobit_main: ivprobit OUTCOME_VAR COVARIATES ///
    (TREATMENT_VAR = INSTRUMENT), vce(cluster CLUSTER_VAR)
margins, dydx(TREATMENT_VAR) post

log close
```

---

## Step 7: Python Cross-Validation

```python
"""
Logit/Probit Cross-Validation: Stata vs Python (statsmodels, sklearn)
"""
import pandas as pd
import numpy as np
import statsmodels.api as sm
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score, classification_report

df = pd.read_stata("DATASET_PATH")

# --- Logit via statsmodels ---
X = df[["TREATMENT_VAR"] + COVARIATES_LIST]
X = sm.add_constant(X)
y = df["OUTCOME_VAR"]

logit_model = sm.Logit(y, X).fit(cov_type="cluster",
                                  cov_kwds={"groups": df["CLUSTER_VAR"]})
print("=== Python Logit (statsmodels) ===")
print(logit_model.summary())

# --- Marginal effects (AME) ---
ame = logit_model.get_margeff(at="overall")
print("\n=== Average Marginal Effects ===")
print(ame.summary())

# --- Probit via statsmodels ---
probit_model = sm.Probit(y, X).fit(cov_type="cluster",
                                    cov_kwds={"groups": df["CLUSTER_VAR"]})

# --- Cross-validate with Stata ---
stata_logit_ame = STATA_LOGIT_AME  # AME from Step 1
python_logit_ame = ame.margeff[0]
pct_diff = abs(stata_logit_ame - python_logit_ame) / abs(stata_logit_ame) * 100
print(f"\nCross-validation (Logit AME on treatment):")
print(f"  Stata:  {stata_logit_ame:.6f}")
print(f"  Python: {python_logit_ame:.6f}")
print(f"  Diff:   {pct_diff:.4f}%")
print(f"  Status: {'PASS' if pct_diff < 0.5 else 'CHECK'}")

# --- ROC/AUC ---
y_pred_prob = logit_model.predict(X)
auc = roc_auc_score(y, y_pred_prob)
print(f"\nPython AUC: {auc:.4f}")

# --- sklearn for comparison ---
lr = LogisticRegression(penalty=None, max_iter=10000)
X_sk = df[["TREATMENT_VAR"] + COVARIATES_LIST]
lr.fit(X_sk, y)
print(f"sklearn Logit coef (treatment): {lr.coef_[0][0]:.6f}")
```
