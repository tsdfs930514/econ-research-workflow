/*==============================================================================
  REPLICATION TEST: DDCG (Acemoglu et al., JPE 2019) — /run-iv
  Data:    DDCGdata_final.dta
  Target:  Table 6 — 2SLS with regional democracy waves as instrument
  Endogenous: dem, Instrument: demreg (regional democracy wave)
  Outcome: y (logGDP*100), Unit: wbcode2, Time: year
==============================================================================*/
clear all
set more off
set matsize 5000
set seed 12345

cap log close
log using "v1/output/logs/01_iv_analysis.log", replace

* --- Install required packages (dependency-ordered) ---
cap which ranktest
if _rc != 0 cap ssc install ranktest, replace
cap which ivreg2
if _rc != 0 cap ssc install ivreg2, replace
cap which reghdfe
if _rc != 0 cap ssc install reghdfe, replace
cap which ftools
if _rc != 0 cap ssc install ftools, replace
cap which ivreghdfe
if _rc != 0 cap ssc install ivreghdfe, replace
cap which estout
if _rc != 0 cap ssc install estout, replace

* --- Load data ---
use "v1/data/raw/DDCGdata_final.dta", clear

* Create instrument variable (following Table 6)
gen instrument = demreg

* Panel setup
xtset wbcode2 year

* --- Step 1: First Stage ---
di "============================================="
di "STEP 1: FIRST STAGE"
di "============================================="

* First stage: dem ~ l(1/4).instrument + l(1/4).y + yy*
eststo clear
eststo first_stage: xtreg dem l(1/4).y l(1/4).instrument yy*, fe vce(cluster wbcode2)
di "First-stage N = " e(N)
di "First-stage R2w = " e(r2_w)

* Test excluded instruments: l(1/4).instrument
test l.instrument l2.instrument l3.instrument l4.instrument
local fs_F = r(F)
local fs_p = r(p)
di "First-stage F (excluded instruments) = `fs_F'"
di "First-stage p-value = `fs_p'"
di "Stock-Yogo threshold (10): " cond(`fs_F' > 10, "PASS", "FAIL")
di "Lee et al. (2022) threshold (23): " cond(`fs_F' > 23, "PASS", "FAIL")

* --- Step 2: 2SLS Estimation ---
di "============================================="
di "STEP 2: 2SLS ESTIMATION"
di "============================================="

* Primary spec: xtivreg2 (matches original Table 6 Column 2)
eststo iv_4lag: xtivreg2 y l(1/4).y (dem=l(1/4).instrument) yy*, ///
    fe cluster(wbcode2) r partial(yy*)
local iv_dem = _b[dem]
local iv_se = _se[dem]
local kp_f = e(widstat)
local kp_lm = e(idstat)
local kp_lm_p = e(idp)
local hansen_j = e(j)
local hansen_p = e(jp)
di "2SLS dem coef = `iv_dem' (SE = `iv_se')"
di "KP Wald F (weak IV) = `kp_f'"
di "KP LM stat (underid) = `kp_lm' (p = `kp_lm_p')"
di "Hansen J (overid) = `hansen_j' (p = `hansen_p')"

* OLS baseline for comparison
eststo ols_4lag: xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)
local ols_dem = _b[dem]
di "OLS dem coef = `ols_dem'"
di "2SLS vs OLS: " cond(`iv_dem' > `ols_dem', "2SLS > OLS (consistent with attenuation bias)", "2SLS < OLS")

* LIML for weak-IV robustness (via ivreg2 with liml option)
cap noisily {
    ivreg2 y l(1/4).y (dem=l(1/4).instrument) i.year i.wbcode2, ///
        cluster(wbcode2) liml first
    eststo liml_4lag
    local liml_dem = _b[dem]
    di "LIML dem coef = `liml_dem'"
    di "2SLS-LIML gap = " abs(`iv_dem' - `liml_dem')
}

* --- Step 3: Diagnostics ---
di "============================================="
di "STEP 3: IV DIAGNOSTICS"
di "============================================="

* Re-run xtivreg2 for full diagnostics
qui xtivreg2 y l(1/4).y (dem=l(1/4).instrument) yy*, ///
    fe cluster(wbcode2) r partial(yy*)

* Endogeneity test (DWH)
local dwh = e(estatp)
di "DWH endogeneity test p = `dwh'"
di "Endogeneity: " cond(`dwh' < 0.05, "Reject exogeneity (IV needed)", "Cannot reject exogeneity")

* Anderson-Rubin test for weak-IV robust inference
cap noisily {
    qui xtivreg2 y l(1/4).y (dem=l(1/4).instrument) yy*, ///
        fe cluster(wbcode2) r partial(yy*)
    di "AR test: Not directly available from xtivreg2; use weakiv package"
}

* --- Step 4: Alternative IV specs ---
di "============================================="
di "STEP 4: ALTERNATIVE SPECIFICATIONS"
di "============================================="

* Spec with 1 lag of instrument only (Table 6 Column 1)
eststo iv_1inst: xtivreg2 y l(1/4).y (dem=l.instrument) yy*, ///
    fe cluster(wbcode2) r partial(yy*)
di "IV (1 inst lag): dem = " _b[dem] ", KP F = " e(widstat)

* --- Step 5: Cross-Validation Data ---
di "============================================="
di "STEP 5: CROSS-VALIDATION DATA"
di "============================================="

* Re-run primary spec for coefficient extraction
qui xtivreg2 y l(1/4).y (dem=l(1/4).instrument) yy*, ///
    fe cluster(wbcode2) r partial(yy*)
di "=== CROSS-VALIDATION DATA ==="
di "IV_dem_coef = " _b[dem]
di "IV_dem_se = " _se[dem]
di "IV_ly_coef = " _b[L.y]
di "IV_N = " e(N)
di "IV_widstat = " e(widstat)

* --- Step 6: Output Tables ---
di "============================================="
di "STEP 6: OUTPUT TABLES"
di "============================================="

esttab ols_4lag iv_1inst iv_4lag using "v1/output/tables/tab_iv_main.tex", ///
    se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(dem L.y L2.y L3.y L4.y) ///
    order(dem L.y L2.y L3.y L4.y) ///
    label booktabs replace ///
    mtitles("OLS-FE" "2SLS(1inst)" "2SLS(4inst)") ///
    scalars("widstat KP Wald F" "jp Hansen J p-value" "N Observations") ///
    title("Democracy and GDP: IV Estimates (DDCG Table 6 Replication)") ///
    note("Instrument: regional democracy waves (demreg)." ///
         "Standard errors clustered at country level. Year FE partialled out.")

di "============================================="
di "IV ANALYSIS COMPLETE"
di "============================================="

log close
