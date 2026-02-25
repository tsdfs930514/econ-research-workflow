---
description: "Run Synthetic Difference-in-Differences (SDID) analysis pipeline"
user_invocable: true
---

# /run-sdid — Synthetic Difference-in-Differences Pipeline

When the user invokes `/run-sdid`, execute a Synthetic DID analysis following Arkhangelsky et al. (2021, AER). SDID combines Synthetic Control unit weights with DiD time weights to produce estimates that are generally more robust than either method alone.

## Stata Execution Command

Run .do files via `"D:\Stata18\StataMP-64.exe" -e do "code/stata/script.do"` from the project directory in Git Bash. See `CLAUDE.md` for flag rules (`-e` required, `-b` and `/e` forbidden) and log file conventions.

## When to Use SDID vs Other DID Methods

- **SDID preferred when**: Few treated units, many control units, staggered adoption can be handled via cohort-specific SDID, concern about parallel trends
- **CS-DiD preferred when**: Many treated/control groups, staggered adoption is the main design challenge, doubly-robust estimation wanted
- **TWFE preferred when**: Uniform treatment timing, homogeneous treatment effects confirmed

## Step 0: Gather Inputs

Ask the user for:

- **Dataset**: path to .dta file (must be a balanced panel)
- **Outcome variable**: dependent variable Y
- **Unit variable**: entity identifier (state, firm, etc.)
- **Time variable**: period/year identifier
- **Treatment variable**: binary indicator (0 before treatment for all; 1 after treatment for treated only)
- **First treatment period** (for staggered): earliest treatment year if staggered adoption
- **Cluster variable**: for standard error clustering (default: unit variable)

## Step 1: Data Preparation (Stata .do file)

```stata
/*==============================================================================
  SDID Analysis — Step 1: Data Preparation
  Reference: Arkhangelsky, Athey, Hirshberg, Imbens & Wager (AER 2021)
==============================================================================*/
clear all
set more off
set seed 12345

log using "output/logs/sdid_01_prep.log", replace

use "DATASET_PATH", clear

* --- Verify balanced panel ---
xtset UNIT_VAR TIME_VAR
xtdescribe
* SDID requires a balanced panel. Drop units with missing periods if needed.

* --- Identify treatment groups ---
tab TREAT_VAR
bysort UNIT_VAR: egen ever_treated = max(TREAT_VAR)
tab ever_treated

* Pre-treatment periods for weight estimation
sum TIME_VAR if TREAT_VAR == 0 & ever_treated == 1
local T0 = r(max)  // last pre-treatment period
di "Last pre-treatment period: `T0'"

* Summary statistics
estpost tabstat OUTCOME_VAR, by(ever_treated) stat(mean sd n) columns(statistics)

log close
```

## Step 2: SDID Estimation (Stata .do file)

```stata
/*==============================================================================
  SDID Analysis — Step 2: Main Estimation
  Packages required: sdid (Clarke et al. 2023)
==============================================================================*/
clear all
set more off
set seed 12345

log using "output/logs/sdid_02_estimation.log", replace

use "DATASET_PATH", clear

* --- Synthetic DiD ---
sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(jackknife) method(sdid) graph ///
    g1_opt(xtitle("") ytitle("Unit Weights")) ///
    g2_opt(xtitle("Time") ytitle("Outcome"))
graph export "output/figures/fig_sdid_main.pdf", replace
estimates store sdid_main

* --- Comparison: Traditional DiD ---
sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(jackknife) method(did)
estimates store did_trad

* --- Comparison: Synthetic Control ---
sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(jackknife) method(sc)
estimates store sc_main

* --- Comparison Table ---
eststo clear
eststo sdid_main
eststo did_trad
eststo sc_main

esttab sdid_main did_trad sc_main using "output/tables/tab_sdid_comparison.tex", ///
    se(4) b(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("SDID" "DiD" "SC") ///
    label booktabs replace ///
    title("Treatment Effect: SDID vs DiD vs SC") ///
    note("Jackknife standard errors. SDID = Arkhangelsky et al. (2021).")

* --- Report SDID diagnostic info ---
* SDID estimate should fall between SC and DiD bounds
* If DiD and SC agree → high confidence in treatment effect
* If they disagree → SDID provides a compromise

di "============================================="
di "SDID COMPARISON"
di "============================================="
estimates restore sdid_main
di "  SDID estimate:    " _b[TREAT_VAR]
estimates restore did_trad
di "  DiD estimate:     " _b[TREAT_VAR]
estimates restore sc_main
di "  SC estimate:      " _b[TREAT_VAR]
di "============================================="

log close
```

## Step 3: Robustness (Stata .do file)

```stata
/*==============================================================================
  SDID Analysis — Step 3: Robustness Checks
==============================================================================*/
clear all
set more off
set seed 12345

log using "output/logs/sdid_03_robustness.log", replace

use "DATASET_PATH", clear

* --- Alternative VCE: Bootstrap ---
sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(bootstrap) reps(200) method(sdid)
estimates store sdid_boot

* --- Placebo: Randomize treatment assignment ---
* Permutation inference: shuffle treated/control labels
sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(placebo) reps(200) method(sdid)
estimates store sdid_placebo

* --- Leave-one-unit-out ---
* Check sensitivity to individual units
levelsof UNIT_VAR if ever_treated == 0, local(controls)
foreach u of local controls {
    cap sdid OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR if UNIT_VAR != `u', ///
        vce(jackknife) method(sdid)
    if _rc == 0 {
        di "LOSO (drop unit `u'): " _b[TREAT_VAR] " (SE: " _se[TREAT_VAR] ")"
    }
}

* --- Alternative outcome ---
sdid ALT_OUTCOME_VAR UNIT_VAR TIME_VAR TREAT_VAR, ///
    vce(jackknife) method(sdid)
estimates store sdid_alt

log close
```

## Step 4: Python Cross-Validation

```python
"""
SDID Cross-Validation using synthdid Python package or manual implementation
"""
import pandas as pd
import numpy as np

df = pd.read_stata("DATASET_PATH")

# Option 1: Use synthdid Python package (if available)
try:
    from synthdid.model import SynthDID
    model = SynthDID(df, unit="UNIT_VAR", time="TIME_VAR",
                     outcome="OUTCOME_VAR", treatment="TREAT_VAR")
    model.fit()
    print(f"Python SDID estimate: {model.att:.6f}")
    print(f"Python SDID SE (jackknife): {model.se:.6f}")
except ImportError:
    print("synthdid not available. Using pyfixest for TWFE comparison.")
    import pyfixest as pf
    model = pf.feols("OUTCOME_VAR ~ TREAT_VAR | UNIT_VAR + TIME_VAR",
                     data=df, vcov={"CRV1": "UNIT_VAR"})
    print(model.summary())

# Cross-validate with Stata
stata_sdid = STATA_SDID_COEF
python_coef = model.att if hasattr(model, 'att') else model.coef()["TREAT_VAR"]
pct_diff = abs(stata_sdid - python_coef) / abs(stata_sdid) * 100
print(f"\nCross-validation (SDID):")
print(f"  Stata:  {stata_sdid:.6f}")
print(f"  Python: {python_coef:.6f}")
print(f"  Diff:   {pct_diff:.4f}%")
```

## Step 5: Diagnostics Summary

After all steps, provide:

1. **SDID vs DiD vs SC**: Does SDID fall between DiD and SC? If all three agree, high confidence. If DiD and SC disagree substantially, discuss which identifying assumption is more plausible.
2. **Unit Weights**: Are weights concentrated on a few control units or diffuse? Concentrated weights may indicate fragility.
3. **Time Weights**: Do time weights emphasize pre-treatment periods close to treatment onset? This is expected.
4. **Inference**: Report jackknife SE, bootstrap SE, and placebo p-value. Note if they disagree.
5. **LOSO Sensitivity**: Do results change when individual control units are dropped?
6. **Recommendation**: SDID is preferred when SC weights produce a good pre-treatment fit and DiD parallel trends are questionable. If pre-treatment fit is poor for SC and parallel trends are plausible, DiD may be preferred.

## Required Stata Packages

```stata
ssc install sdid
ssc install reghdfe
ssc install ftools
```

## Key References

- Arkhangelsky, D., Athey, S., Hirshberg, D., Imbens, G. & Wager, S. (2021). "Synthetic Difference-in-Differences." AER, 111(12), 4088-4118.
- Clarke, D., Pailañir, D., Athey, S. & Imbens, G. (2023). "Synthetic Difference-in-Differences Estimation." Stata Journal.
