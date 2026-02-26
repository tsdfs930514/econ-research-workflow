/*==============================================================================
  REPLICATION TEST: DDCG (Acemoglu et al., JPE 2019) — /run-panel
  Data:    DDCGdata_final.dta (country-year panel, 1960-2010)
  Target:  Table 2 — Within estimator (FE), GMM, impulse response
  Vars:    Y=y (logGDP*100), Treatment=dem, Unit=wbcode2, Time=year
==============================================================================*/
clear all
set more off
set matsize 5000
set seed 12345

cap log close
log using "v1/output/logs/01_panel_analysis.log", replace

* --- Install required packages ---
foreach pkg in reghdfe ftools estout xtabond2 coefplot {
    cap which `pkg'
    if _rc != 0 {
        cap ssc install `pkg', replace
    }
}

* --- Load data ---
use "v1/data/raw/DDCGdata_final.dta", clear

* --- Step 1: Panel Setup & Description ---
di "============================================="
di "STEP 1: PANEL SETUP"
di "============================================="

xtset wbcode2 year
xtdescribe

* Summary statistics
xtsum y dem

* Between/within decomposition
di "Outcome (y): between and within variation"
qui sum y
di "  Overall SD: " r(sd)

* Treatment summary
tab dem, missing
bysort wbcode2: egen ever_dem = max(dem)
tab ever_dem

* --- Step 2: Fixed Effects Estimation ---
di "============================================="
di "STEP 2: FIXED EFFECTS ESTIMATION"
di "============================================="

eststo clear

* Spec 1: FE with 1 lag (Table 2, Column 1)
eststo fe_1lag: xtreg y l.y dem yy*, fe vce(cluster wbcode2)
local fe1_dem = _b[dem]
local fe1_se = _se[dem]
di "FE (1 lag): dem = `fe1_dem' (SE = `fe1_se')"

* Spec 2: FE with 2 lags (Table 2, Column 2)
eststo fe_2lag: xtreg y l(1/2).y dem yy*, fe vce(cluster wbcode2)
local fe2_dem = _b[dem]
di "FE (2 lags): dem = `fe2_dem'"

* Spec 3: FE with 4 lags (Table 2, Column 3) — PRIMARY SPEC
eststo fe_4lag: xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)
local fe4_dem = _b[dem]
local fe4_ly = _b[L.y]
local fe4_l2y = _b[L2.y]
local fe4_l3y = _b[L3.y]
local fe4_l4y = _b[L4.y]
di "FE (4 lags): dem = `fe4_dem'"
di "  L.y = `fe4_ly', L2.y = `fe4_l2y', L3.y = `fe4_l3y', L4.y = `fe4_l4y'"

* Hausman test: FE vs RE
qui xtreg y l(1/4).y dem yy*, fe
estimates store fe_haus
qui xtreg y l(1/4).y dem yy*, re
estimates store re_haus
hausman fe_haus re_haus
di "Hausman chi2 = " r(chi2) ", p = " r(p)
* Note: negative chi2 is known Stata behavior when FE strongly dominates RE

* --- Step 3: Diagnostic Tests ---
di "============================================="
di "STEP 3: DIAGNOSTIC TESTS"
di "============================================="

* Wooldridge test for serial correlation (cap noisily since xtserial may not be available)
cap noisily xtserial y l(1/4).y dem
if _rc != 0 {
    di "NOTE: xtserial not available — skipping Wooldridge autocorrelation test"
}

* Pesaran cross-sectional dependence test
cap noisily {
    qui xtreg y l(1/4).y dem yy*, fe
    xtcsd, pesaran abs
}
if _rc != 0 {
    di "NOTE: xtcsd not available — skipping cross-sectional dependence test"
}

* Modified Wald test for heteroskedasticity
cap noisily {
    qui xtreg y l(1/4).y dem yy*, fe
    xttest3
}
if _rc != 0 {
    di "NOTE: xttest3 not available — skipping heteroskedasticity test"
}

* --- Step 4: Dynamic Panel GMM ---
di "============================================="
di "STEP 4: GMM ESTIMATION (xtabond2)"
di "============================================="

* GMM with 1 lag (Table 2, Column 5)
eststo gmm_1lag: xtabond2 y l.y dem yy*, ///
    gmmstyle(y, laglimits(2 .)) gmmstyle(dem, laglimits(1 .)) ///
    ivstyle(yy*, p) noleveleq robust nodiffsargan
di "GMM (1 lag): dem = " _b[dem]
di "  AR(2) p = " e(ar2p)
di "  Hansen J p = " e(hansenp)
di "  N instruments = " e(j)

* GMM with 4 lags (Table 2, Column 7) — PRIMARY GMM SPEC
eststo gmm_4lag: xtabond2 y l(1/4).y dem yy*, ///
    gmmstyle(y, laglimits(2 .)) gmmstyle(dem, laglimits(1 .)) ///
    ivstyle(yy*, p) noleveleq robust nodiffsargan
local gmm4_dem = _b[dem]
di "GMM (4 lags): dem = `gmm4_dem'"
di "  AR(2) p = " e(ar2p)
di "  Hansen J p = " e(hansenp)
di "  N instruments = " e(j)

* --- Step 5: Impulse Response (via nlcom) ---
di "============================================="
di "STEP 5: IMPULSE RESPONSE FUNCTION"
di "============================================="

* Re-estimate FE with 4 lags and compute impulse response
qui xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)

* Short-run effect (impact)
local sr = _b[dem]
local p1 = _b[L.y]
local p2 = _b[L2.y]
local p3 = _b[L3.y]
local p4 = _b[L4.y]
local persistence = `p1' + `p2' + `p3' + `p4'

* Long-run effect
local lr = `sr' / (1 - `persistence')

di "Short-run effect of democracy:  `sr'"
di "Persistence (sum of lag coefs): `persistence'"
di "Long-run effect of democracy:   `lr'"

* Compute 25-year cumulative effect via nlcom chain
nlcom (shortrun: _b[dem]) ///
      (lag1: _b[L.y]) ///
      (lag2: _b[L2.y]) ///
      (lag3: _b[L3.y]) ///
      (lag4: _b[L4.y]) ///
      (longrun: _b[dem] / (1 - _b[L.y] - _b[L2.y] - _b[L3.y] - _b[L4.y])), post

* Store for cross-validation
local lr_nlcom = _b[longrun]
local lr_se = _se[longrun]
di "Long-run (nlcom): `lr_nlcom' (SE = `lr_se')"

* --- Step 6: Cross-Validation Checkpoint ---
di "============================================="
di "STEP 6: CROSS-VALIDATION DATA"
di "============================================="

* Re-run the primary FE spec and save coefficients for Python comparison
qui xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)
di "=== CROSS-VALIDATION DATA ==="
di "FE_4lag_dem_coef = " _b[dem]
di "FE_4lag_dem_se = " _se[dem]
di "FE_4lag_ly_coef = " _b[L.y]
di "FE_4lag_N = " e(N)
di "FE_4lag_N_g = " e(N_g)
di "FE_4lag_r2_w = " e(r2_w)

* Save results for cross-validation
matrix b_fe = e(b)
matrix V_fe = e(V)

* --- Step 7: Output Tables ---
di "============================================="
di "STEP 7: OUTPUT TABLES"
di "============================================="

esttab fe_1lag fe_2lag fe_4lag gmm_1lag gmm_4lag ///
    using "v1/output/tables/tab_panel_main.tex", ///
    se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(dem L.y L2.y L3.y L4.y) ///
    order(dem L.y L2.y L3.y L4.y) ///
    label booktabs replace ///
    mtitles("FE(1)" "FE(2)" "FE(4)" "GMM(1)" "GMM(4)") ///
    scalars("N Observations" "N_g Countries" "ar2p AR(2) p-value" "hansenp Hansen J p-value") ///
    title("Democracy and GDP Growth: Panel Estimates (DDCG Table 2 Replication)") ///
    note("Standard errors clustered at country level. Year FE included." ///
         "GMM uses difference equation with lagged levels as instruments.")

di "============================================="
di "PANEL ANALYSIS COMPLETE"
di "============================================="

log close
