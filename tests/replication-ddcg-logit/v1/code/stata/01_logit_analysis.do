********************************************************************************
* 01_logit_analysis.do
* Logit/Probit Analysis of Democracy (dem) using DDCG data
* Tests the /run-logit-probit skill
*
* Outcome: dem (0/1 democracy indicator)
* Predictors: GDP (y) and its lags, year dummies (yy*)
********************************************************************************

clear all
set more off
set seed 12345

* ---------------------------------------------------------------------------- *
* Close any open log, then start fresh log
* ---------------------------------------------------------------------------- *
cap log close
log using "v1/output/logs/01_logit_analysis.log", replace

* ---------------------------------------------------------------------------- *
* Install required packages
* ---------------------------------------------------------------------------- *
cap which reghdfe
if _rc {
    cap ssc install reghdfe, replace
}

cap which ftools
if _rc {
    cap ssc install ftools, replace
}

cap which estout
if _rc {
    cap ssc install estout, replace
}

* ---------------------------------------------------------------------------- *
* 1. Load DDCG data
* ---------------------------------------------------------------------------- *
di as txt "============================================================"
di as txt "  Loading DDCGdata_final.dta"
di as txt "============================================================"

use "v1/data/raw/DDCGdata_final.dta", clear

* Describe key variables
describe dem y wbcode2 year
summarize dem y

* Set panel structure
xtset wbcode2 year

* ---------------------------------------------------------------------------- *
* 2. Logit: dem on l.y and year dummies, clustered SEs
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  LOGIT: dem = f(l.y, yy*)"
di as txt "============================================================"

logit dem l.y yy*, vce(cluster wbcode2)
estimates store logit_main

* Save logit coefficient on l.y for cross-validation
local logit_coef_ly = _b[L.y]
di as txt "Logit coefficient on L.y: " %9.6f `logit_coef_ly'

* ---------------------------------------------------------------------------- *
* 3. Logit Average Marginal Effects (AME)
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  LOGIT: Average Marginal Effects"
di as txt "============================================================"

estimates restore logit_main
margins, dydx(*) post
estimates store logit_ame

* Save AME of l.y for cross-validation
local logit_ame_ly = _b[L.y]
di as txt "Logit AME on L.y: " %9.6f `logit_ame_ly'

* ---------------------------------------------------------------------------- *
* 4. Probit: dem on l.y and year dummies, clustered SEs
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  PROBIT: dem = f(l.y, yy*)"
di as txt "============================================================"

probit dem l.y yy*, vce(cluster wbcode2)
estimates store probit_main

local probit_coef_ly = _b[L.y]
di as txt "Probit coefficient on L.y: " %9.6f `probit_coef_ly'

* ---------------------------------------------------------------------------- *
* 5. Probit Average Marginal Effects (AME)
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  PROBIT: Average Marginal Effects"
di as txt "============================================================"

estimates restore probit_main
margins, dydx(*) post
estimates store probit_ame

local probit_ame_ly = _b[L.y]
di as txt "Probit AME on L.y: " %9.6f `probit_ame_ly'

* ---------------------------------------------------------------------------- *
* 6. LPM via reghdfe: dem on l.y with country and year FE
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  LPM (reghdfe): dem = f(l.y) + country FE + year FE"
di as txt "============================================================"

reghdfe dem l.y, absorb(wbcode2 year) vce(cluster wbcode2)
estimates store lpm_fe

local lpm_coef_ly = _b[L.y]
di as txt "LPM coefficient on L.y: " %9.6f `lpm_coef_ly'

* ---------------------------------------------------------------------------- *
* 7. Treatment Effects: Regression Adjustment (RA)
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  teffects ra: (y l.y) (dem), atet"
di as txt "============================================================"

cap noisily teffects ra (y l.y) (dem), atet
if !_rc {
    estimates store te_ra
    di as txt "RA ATET estimate stored successfully."
}
else {
    di as err "teffects ra failed (common with panel data). Skipping."
}

* ---------------------------------------------------------------------------- *
* 8. Treatment Effects: Inverse Probability Weighting (IPW)
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  teffects ipw: (y) (dem l.y, probit), atet"
di as txt "============================================================"

cap noisily teffects ipw (y) (dem l.y, probit), atet
if !_rc {
    estimates store te_ipw
    di as txt "IPW ATET estimate stored successfully."
}
else {
    di as err "teffects ipw failed (common with panel data). Skipping."
}

* ---------------------------------------------------------------------------- *
* 9. Treatment Effects: Augmented IPW (AIPW / IPWRA)
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  teffects ipwra: (y l.y) (dem l.y, probit), atet"
di as txt "============================================================"

cap noisily teffects ipwra (y l.y) (dem l.y, probit), atet
if !_rc {
    estimates store te_aipw
    di as txt "AIPW ATET estimate stored successfully."
}
else {
    di as err "teffects ipwra failed (common with panel data). Skipping."
}

* ---------------------------------------------------------------------------- *
* 10. Output comparison tables
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  Comparison Tables"
di as txt "============================================================"

* --- Table A: Logit vs Probit coefficients ---
di as txt _n "--- Logit vs Probit: Structural Coefficients ---"
estimates table logit_main probit_main, b(%9.4f) se(%9.4f) stats(N ll aic bic)

* --- Table B: AME comparison ---
di as txt _n "--- Logit AME vs Probit AME ---"
estimates table logit_ame probit_ame, b(%9.6f) se(%9.6f) stats(N)

* --- Table C: LPM for comparison ---
di as txt _n "--- LPM (reghdfe) ---"
estimates table lpm_fe, b(%9.6f) se(%9.6f) stats(N r2)

* --- LaTeX output: Logit & Probit comparison ---
di as txt _n "--- Exporting LaTeX table to v1/output/tables/tab_logit_probit.tex ---"

* Build model list for esttab
local models "logit_main probit_main logit_ame probit_ame lpm_fe"

* Add teffects models only if they were stored
cap estimates dir te_ra
if !_rc {
    local models "`models' te_ra"
}
cap estimates dir te_ipw
if !_rc {
    local models "`models' te_ipw"
}
cap estimates dir te_aipw
if !_rc {
    local models "`models' te_aipw"
}

esttab `models' using "v1/output/tables/tab_logit_probit.tex", replace   ///
    b(%9.4f) se(%9.4f)                                                    ///
    label star(* 0.10 ** 0.05 *** 0.01)                                   ///
    title("Logit, Probit, LPM, and Treatment Effects: Democracy and GDP") ///
    mtitles("Logit" "Probit" "Logit AME" "Probit AME" "LPM (FE)"         ///
            "RA" "IPW" "AIPW")                                            ///
    stats(N ll aic bic r2, fmt(%9.0f %9.2f %9.2f %9.2f %9.4f)            ///
          labels("Observations" "Log-Likelihood" "AIC" "BIC" "R-squared"))

di as txt "Table exported: v1/output/tables/tab_logit_probit.tex"

* ---------------------------------------------------------------------------- *
* 11. CROSS-VALIDATION DATA
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  CROSS-VALIDATION DATA"
di as txt "============================================================"

di as txt _n "Logit coefficient on L.y:  " %12.6f `logit_coef_ly'
di as txt    "Logit AME on L.y:          " %12.6f `logit_ame_ly'
di as txt    "Probit coefficient on L.y: " %12.6f `probit_coef_ly'
di as txt    "Probit AME on L.y:         " %12.6f `probit_ame_ly'
di as txt    "LPM coefficient on L.y:    " %12.6f `lpm_coef_ly'

* ---------------------------------------------------------------------------- *
* 12. Done
* ---------------------------------------------------------------------------- *
di as txt _n "============================================================"
di as txt "  LOGIT-PROBIT ANALYSIS COMPLETE"
di as txt "============================================================"

log close
