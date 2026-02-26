/*==============================================================================
  REPLICATION TEST: Mexico Retail Entry — /run-iv
  Source Paper:  Large-scale chain entry and the effect on small retailers
  Data:          Replication package (Procesamiento/Trabajo/Data/)
  Target:        Table 2 Col 5 — 2SLS: chain entry on corner store counts
                 Table 1 — Store-level: profits_wkr regressed on chain entry
  Endogenous:    N_xl_con_1km (number of large chain stores within 1km)
  Instrument:    SIVL_TPSTA_vc_sum_n2_tm1_1km (street suitability x lagged
                 neighbor-municipality chain concentration interaction)
  Controls:      Count_ret_fac*1km (PCA/factor of other retail establishments)
  FE:            market_c (or year#mun_c)
  Cluster:       mun_c (municipality)
  Note:          The replication package requires running the full data-build
                 pipeline (panel 1999-2019.do -> panel establishments.do ->
                 panel markets.do -> pca factor.do) from raw Economic Census
                 microdata. If the processed .dta files are not available,
                 this script constructs a simulated panel that mirrors the
                 paper's IV structure for testing /run-iv skill execution.
==============================================================================*/
clear all
set more off
set matsize 5000
set seed 12345

cap log close
log using "v1/output/logs/01_iv_analysis.log", replace

timer clear
timer on 1

* ===========================================================================
* STEP 0: Install required packages
* ===========================================================================
di "============================================="
di "STEP 0: INSTALLING REQUIRED PACKAGES"
di "============================================="

foreach pkg in ranktest ivreg2 ftools reghdfe ivreghdfe estout outreg2 {
    cap which `pkg'
    if _rc != 0 {
        di "Installing `pkg'..."
        cap ssc install `pkg', replace
    }
    else {
        di "`pkg' already installed."
    }
}

* ===========================================================================
* STEP 1: Attempt to load real replication data
* ===========================================================================
di ""
di "============================================="
di "STEP 1: DATA LOADING"
di "============================================="

* --- Define paths to replication package ---
* The replication package stores processed data in Data/Clean/
* and raw uploaded data in Data/Uploaded/
local repl_root "F:/Learning/replication pakage/Replication/Procesamiento/Trabajo"
local data_clean "`repl_root'/Data/Clean"
local data_uploaded "`repl_root'/Data/Uploaded"

local real_data_loaded = 0

* --- Attempt 1: Load Panel_Markets.dta (market-level IV analysis) ---
di "Attempting to load Panel_Markets.dta from replication package..."
cap use "`data_clean'/Panel_Markets.dta", clear
if _rc == 0 {
    di "SUCCESS: Panel_Markets.dta loaded."
    local real_data_loaded = 1

    * Save copy to local raw directory
    save "v1/data/raw/Panel_Markets.dta", replace
    di "Saved copy to v1/data/raw/Panel_Markets.dta"

    * Describe the data
    di ""
    di "--- Data Description ---"
    describe, short
    di ""
    describe
    di ""
    sum year N_corner_1km N_xl_con_1km SIVL_TPSTA_vc_sum_n2_tm1_1km mun_c market_c, detail
}
else {
    di "Panel_Markets.dta not found (rc = `=_rc'). Trying other sources..."
}

* --- Attempt 2: Load Panel_Stores.dta (store-level) ---
if `real_data_loaded' == 0 {
    di "Attempting to load Panel_Stores.dta..."
    cap use "`data_clean'/Panel_Stores.dta", clear
    if _rc == 0 {
        di "SUCCESS: Panel_Stores.dta loaded."
        local real_data_loaded = 2
        save "v1/data/raw/Panel_Stores.dta", replace
        describe, short
    }
    else {
        di "Panel_Stores.dta not found (rc = `=_rc')."
    }
}

* --- Attempt 3: Load Panel PCA Factor.dta ---
if `real_data_loaded' == 0 {
    di "Attempting to load Panel PCA Factor.dta..."
    cap use "`data_clean'/Panel PCA Factor.dta", clear
    if _rc == 0 {
        di "SUCCESS: Panel PCA Factor.dta loaded."
        local real_data_loaded = 3
        save "v1/data/raw/Panel_PCA_Factor.dta", replace
        describe, short
    }
    else {
        di "Panel PCA Factor.dta not found (rc = `=_rc')."
    }
}

* --- Attempt 4: Load CP_IV_ToMerge.dta (uploaded instrument data) ---
if `real_data_loaded' == 0 {
    di "Attempting to load CP_IV_ToMerge.dta (instrument components)..."
    cap use "`data_uploaded'/CP_IV_ToMerge.dta", clear
    if _rc == 0 {
        di "SUCCESS: CP_IV_ToMerge.dta loaded."
        local real_data_loaded = 4
        save "v1/data/raw/CP_IV_ToMerge.dta", replace
        di ""
        di "--- CP_IV_ToMerge Variable List ---"
        describe
        di ""
        sum, detail
    }
    else {
        di "CP_IV_ToMerge.dta not found (rc = `=_rc')."
    }
}

* --- Attempt 5: Load AGEBs_1km_center_Intersect.dta (market structure) ---
if `real_data_loaded' == 0 {
    di "Attempting to load AGEBs_1km_center_Intersect.dta..."
    cap use "`data_uploaded'/AGEBs_1km_center_Intersect.dta", clear
    if _rc == 0 {
        di "SUCCESS: AGEBs_1km_center_Intersect.dta loaded."
        local real_data_loaded = 5
        save "v1/data/raw/AGEBs_1km_center_Intersect.dta", replace
        describe
    }
    else {
        di "AGEBs_1km_center_Intersect.dta not found (rc = `=_rc')."
    }
}

di ""
di "Real data loading result: `real_data_loaded'"
di "(0 = none found, 1 = Panel_Markets, 2 = Panel_Stores,"
di " 3 = PCA Factor, 4 = CP_IV, 5 = AGEBs)"

* ===========================================================================
* STEP 2: Construct simulated Mexico retail panel if no processed data
* ===========================================================================
* If Panel_Markets not available (real_data_loaded != 1), we construct a
* simulated panel mirroring the paper's IV structure:
*   - Markets (AGEBs) observed across 5 census years
*   - Outcome: N_corner_1km (corner stores within 1km)
*   - Endogenous: N_xl_con_1km (large chain stores within 1km)
*   - Instrument: SIVL_TPSTA_vc_sum_n2_tm1_1km (street suitability x
*     lagged neighbor chain concentration)
*   - Controls: Count_ret_fac1_1km (factor score of other retail)
*   - FE: market_c, year#mun_c
*   - Cluster: mun_c

if `real_data_loaded' != 1 {
    di ""
    di "============================================="
    di "STEP 2: CONSTRUCTING SIMULATED MEXICO RETAIL PANEL"
    di "============================================="
    di "Note: Processed data unavailable. Building simulated panel"
    di "      that mirrors the paper's IV structure."
    di ""

    clear
    set seed 12345

    * --- Panel dimensions matching paper ---
    * Paper: ~66,000 AGEBs (markets), 5 census years, ~580 municipalities
    * For testing: 3,000 markets, 5 years, 150 municipalities
    local N_markets = 3000
    local N_years   = 5
    local N_mun     = 150
    local N_obs = `N_markets' * `N_years'

    set obs `N_obs'

    * Market and year identifiers
    gen long market_id = ceil(_n / `N_years')
    gen year = 1999 + (mod(_n - 1, `N_years') * 5)
    label variable market_id "Market (AGEB) identifier"
    label variable year "Census year"

    * Municipality assignment (markets nested in municipalities)
    gen mun_c = ceil(market_id / (`N_markets' / `N_mun'))
    label variable mun_c "Municipality cluster"

    * Market-level fixed effect
    gen market_c = market_id
    label variable market_c "Market fixed effect"

    * --- Generate pre-determined suitability components ---
    * Street suitability: trunk + primary + secondary + tertiary road length
    * normalized by sqrt(area). Fixed at market level (time-invariant geography).
    * In the paper this is TPST_L / sqrt(area_ageb_L) standardized within sample.
    bys market_id (year): gen TPST_suitability = rnormal(0, 1) if _n == 1
    bys market_id (year): replace TPST_suitability = TPST_suitability[1]
    label variable TPST_suitability "Standardized street suitability (time-invariant)"

    * --- Neighbor municipality chain concentration (shift component) ---
    * vc_sum_n2_tm1: vector of chain counts in 2nd-degree neighbor
    * municipalities, lagged one period. Varies by municipality x year.
    * Generate municipality-level time trend + noise.
    bys mun_c (year): gen mun_trend = rnormal(0.5, 0.3) if _n == 1
    bys mun_c (year): replace mun_trend = mun_trend[1]

    * Lagged neighbor concentration: grows with time, varies by municipality
    gen vc_sum_n2_tm1 = max(0, mun_trend * (year - 1994) / 5 + rnormal(0, 0.5))
    label variable vc_sum_n2_tm1 "Lagged neighbor municipality chain concentration"

    * --- Construct the Bartik/shift-share instrument ---
    * SIVL_TPSTA_vc_sum_n2_tm1_1km = std(TPST_suitability) * std(vc_sum_n2_tm1)
    * Standardize within sample
    egen std_TPST = std(TPST_suitability)
    egen std_vc = std(vc_sum_n2_tm1)
    gen SIVL_TPSTA_vc_sum_n2_tm1_1km = std_TPST * std_vc
    label variable SIVL_TPSTA_vc_sum_n2_tm1_1km ///
        "IV: street suitability x lagged neighbor chain concentration"
    drop std_TPST std_vc

    * --- Generate endogenous variable: chain store entry ---
    * N_xl_con_1km driven by the instrument + municipality-year shocks
    * plus unobservable demand/profitability shocks (endogeneity source)
    gen demand_shock = rnormal(0, 1)
    bys mun_c year: gen mun_year_shock = rnormal(0, 0.5) if _n == 1
    bys mun_c year: replace mun_year_shock = mun_year_shock[1]

    gen N_xl_con_1km = max(0, ///
        1.5 * SIVL_TPSTA_vc_sum_n2_tm1_1km ///  /* instrument relevance */
        + 0.8 * demand_shock ///                  /* endogenous shock */
        + mun_year_shock ///                      /* mun-year FE component */
        + rnormal(2, 1.5))                        /* baseline + noise */
    label variable N_xl_con_1km "Number of large chain stores within 1km"

    * --- Generate outcome: corner store counts ---
    * N_corner_1km: negatively affected by chain entry (displacement)
    * but positively affected by demand shocks (endogeneity bias)
    gen N_corner_1km = max(0, ///
        15 ///                                     /* baseline corner stores */
        - 1.2 * N_xl_con_1km ///                   /* true causal effect */
        + 2.5 * demand_shock ///                   /* confound: demand */
        + mun_year_shock * 0.5 ///                 /* mun-year component */
        + rnormal(0, 3))                           /* idiosyncratic */
    label variable N_corner_1km "Number of corner stores within 1km"

    * --- Store-level profit outcome (market-level average) ---
    * profits_wkr: average profit per worker for corner stores
    gen profits_wkr = max(0, ///
        50 ///                                     /* baseline profit/worker */
        - 3.5 * N_xl_con_1km ///                   /* competition effect */
        + 8.0 * demand_shock ///                   /* demand -> profits */
        + rnormal(0, 10))                          /* noise */
    label variable profits_wkr "Corner store profits per worker (1000s pesos)"

    * --- Control variables: PCA/factor of other retail establishments ---
    * In the paper: Count_ret_fac1_1km through Count_ret_fac5_1km from PCA
    * of counts of retail establishments (pharmacies, restaurants, etc.)
    forvalues j = 1/3 {
        gen Count_ret_fac`j'_1km = rnormal(0, 1) + 0.3 * demand_shock
        label variable Count_ret_fac`j'_1km ///
            "Retail establishment PCA factor `j' (1km radius)"
    }

    * --- Additional outcomes from the paper ---
    * Entry rate
    gen N_corner_entry_1km = max(0, ///
        3 - 0.4 * N_xl_con_1km + rnormal(0, 1.5))
    label variable N_corner_entry_1km "Corner store entries within 1km"

    * Exit rate
    gen N_corner_exit_tm1_1km = max(0, ///
        2 + 0.3 * N_xl_con_1km + rnormal(0, 1))
    label variable N_corner_exit_tm1_1km "Corner store exits (lagged) within 1km"

    * Share of corner store entry
    gen share_corner_entry_1km = N_corner_entry_1km / ///
        (N_corner_1km + 0.01)
    label variable share_corner_entry_1km "Share corner store entry"

    * AGEB existence indicator for sample restriction
    gen N_xl_con_AGEB = max(0, round(N_xl_con_1km * 0.4 + rnormal(0, 0.5)))
    label variable N_xl_con_AGEB "Chain stores in own AGEB"

    * Clean up construction variables
    drop demand_shock mun_year_shock mun_trend

    * --- Panel structure ---
    sort market_id year
    xtset market_id year, delta(5)

    di ""
    di "--- Simulated Panel Summary ---"
    di "Markets (AGEBs): `N_markets'"
    di "Municipalities: `N_mun'"
    di "Census years: 1999 2004 2009 2014 2019"
    di "Total observations: `=_N'"
    di ""

    describe
    di ""
    sum N_corner_1km N_xl_con_1km SIVL_TPSTA_vc_sum_n2_tm1_1km ///
        profits_wkr Count_ret_fac*_1km, detail

    * Save constructed dataset
    compress
    save "v1/data/raw/mexico_retail_iv_simulated.dta", replace
    di "Saved simulated data to v1/data/raw/mexico_retail_iv_simulated.dta"
}

* ===========================================================================
* STEP 3: Determine variable availability and set estimation locals
* ===========================================================================
di ""
di "============================================="
di "STEP 3: VARIABLE AVAILABILITY CHECK"
di "============================================="

* Confirm which key variables exist in the loaded dataset
local has_profits_wkr = 0
local has_N_corner_1km = 0
local has_N_xl_con_1km = 0
local has_instrument = 0
local has_pca_controls = 0
local has_market_fe = 0

foreach v in profits_wkr {
    cap confirm variable `v'
    if _rc == 0 local has_profits_wkr = 1
}
foreach v in N_corner_1km {
    cap confirm variable `v'
    if _rc == 0 local has_N_corner_1km = 1
}
foreach v in N_xl_con_1km {
    cap confirm variable `v'
    if _rc == 0 local has_N_xl_con_1km = 1
}
foreach v in SIVL_TPSTA_vc_sum_n2_tm1_1km {
    cap confirm variable `v'
    if _rc == 0 local has_instrument = 1
}
foreach v in Count_ret_fac1_1km {
    cap confirm variable `v'
    if _rc == 0 local has_pca_controls = 1
}
foreach v in market_c {
    cap confirm variable `v'
    if _rc == 0 local has_market_fe = 1
}

di "profits_wkr available:         `has_profits_wkr'"
di "N_corner_1km available:        `has_N_corner_1km'"
di "N_xl_con_1km available:        `has_N_xl_con_1km'"
di "Instrument (SIVL) available:   `has_instrument'"
di "PCA factor controls available: `has_pca_controls'"
di "Market FE (market_c) available:`has_market_fe'"

* ===========================================================================
* STEP 4: First Stage Estimation
* ===========================================================================
di ""
di "============================================="
di "STEP 4: FIRST STAGE — Instrument Relevance"
di "============================================="

eststo clear

if `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    * --- 4a: Simple first stage (no controls, no FE) ---
    di "--- First Stage: No controls ---"
    eststo fs_simple: reg N_xl_con_1km SIVL_TPSTA_vc_sum_n2_tm1_1km, ///
        vce(cluster mun_c)
    local fs_simple_b = _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
    local fs_simple_F = e(F)
    di "Instrument coef = `fs_simple_b'"
    di "F-statistic = `fs_simple_F'"

    * --- 4b: First stage with PCA controls ---
    if `has_pca_controls' == 1 {
        di ""
        di "--- First Stage: With PCA retail controls ---"
        cap noisily {
            eststo fs_controls: reg N_xl_con_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                vce(cluster mun_c)
            di "Instrument coef = " _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
        }
    }

    * --- 4c: First stage with FE (paper specification) ---
    di ""
    di "--- First Stage: With year x municipality FE ---"
    cap noisily {
        eststo fs_fe: reghdfe N_xl_con_1km ///
            SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
            absorb(year#mun_c) vce(cluster mun_c)
        local fs_fe_b = _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
        local fs_fe_N = e(N)
        di "First-stage coef (with FE) = `fs_fe_b'"
        di "N = `fs_fe_N'"

        * Partial F-test on excluded instrument
        test SIVL_TPSTA_vc_sum_n2_tm1_1km
        local fs_F_partial = r(F)
        local fs_p_partial = r(p)
        di "Partial F on excluded instrument = `fs_F_partial'"
        di "p-value = `fs_p_partial'"
        di "Stock-Yogo 10% threshold (F>16.38 for 1 instrument): " ///
            cond(`fs_F_partial' > 16.38, "PASS", "FAIL")
        di "Rule of thumb (F>10): " ///
            cond(`fs_F_partial' > 10, "PASS", "FAIL")
    }

    * --- 4d: First stage with market + year x municipality FE (Table 2 spec) ---
    if `has_market_fe' == 1 {
        di ""
        di "--- First Stage: With market FE + year#mun FE (Table 2 spec) ---"
        cap noisily {
            eststo fs_fullfe: reghdfe N_xl_con_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                absorb(market_c year#mun_c) vce(cluster mun_c)
            local fs_fullfe_b = _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
            di "First-stage coef (full FE) = `fs_fullfe_b'"
            test SIVL_TPSTA_vc_sum_n2_tm1_1km
            local fs_fullfe_F = r(F)
            di "Partial F (full FE) = `fs_fullfe_F'"
        }
    }
}
else {
    di "WARNING: Missing endogenous variable or instrument. Skipping first stage."
}

* ===========================================================================
* STEP 5: 2SLS / IV Estimation — Main Specifications
* ===========================================================================
di ""
di "============================================="
di "STEP 5: 2SLS ESTIMATION — MAIN SPECIFICATIONS"
di "============================================="

* --- 5a: Table 2 Column 5 replication: N_corner_1km on N_xl_con_1km ---
* ivreghdfe N_corner_1km Count_ret_fac*1km (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km),
*     cluster(mun_c) absorb(market_c year#mun_c)

if `has_N_corner_1km' == 1 & `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    * --- OLS baseline (Table 2 Col 1-4) ---
    di "--- OLS baseline: N_corner on N_xl_con ---"

    * Column 1: Simple OLS
    eststo ols_simple: reg N_corner_1km N_xl_con_1km, vce(cluster mun_c)
    local ols_b = _b[N_xl_con_1km]
    di "OLS (no controls): coef = `ols_b'"

    * Column 2: With year x mun FE
    di ""
    cap noisily {
        eststo ols_fe: reghdfe N_corner_1km N_xl_con_1km, ///
            absorb(year#mun_c) vce(cluster mun_c)
        di "OLS (year#mun FE): coef = " _b[N_xl_con_1km]
    }

    * Column 3: With PCA controls + year x mun FE
    if `has_pca_controls' == 1 {
        di ""
        cap noisily {
            eststo ols_ctrl: reghdfe N_corner_1km N_xl_con_1km ///
                Count_ret_fac*_1km, absorb(year#mun_c) vce(cluster mun_c)
            di "OLS (controls + year#mun FE): coef = " _b[N_xl_con_1km]
        }
    }

    * Column 4: With PCA controls + market FE + year x mun FE
    if `has_market_fe' == 1 & `has_pca_controls' == 1 {
        di ""
        cap noisily {
            eststo ols_fullfe: reghdfe N_corner_1km N_xl_con_1km ///
                Count_ret_fac*_1km, absorb(market_c year#mun_c) ///
                vce(cluster mun_c)
            di "OLS (full FE + controls): coef = " _b[N_xl_con_1km]
        }
    }

    * --- Column 5: IV / 2SLS with ivreghdfe (MAIN SPECIFICATION) ---
    di ""
    di "============================================="
    di "MAIN IV SPECIFICATION (Table 2, Column 5)"
    di "============================================="

    if `has_market_fe' == 1 {
        * Full specification with market_c FE (Table 2 exact)
        cap noisily {
            eststo iv_main: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(mun_c) absorb(market_c year#mun_c) savefirst

            local iv_b = _b[N_xl_con_1km]
            local iv_se = _se[N_xl_con_1km]
            local iv_N = e(N)
            local kp_f = e(rkf)
            local kp_lm = e(idstat)
            local kp_lm_p = e(idp)

            di "2SLS N_xl_con_1km coef = `iv_b' (SE = `iv_se')"
            di "N = `iv_N'"
            di "KP rk Wald F (weak instrument) = `kp_f'"
            di "KP rk LM (underidentification) = `kp_lm' (p = `kp_lm_p')"
            di "Stock-Yogo 10% threshold (F>16.38): " ///
                cond(`kp_f' > 16.38, "PASS", "FAIL")
            di "Rule of thumb (F>10): " ///
                cond(`kp_f' > 10, "PASS", "FAIL")

            * Mean dependent variable
            cap drop sample_reg
            gen sample_reg = e(sample)
            sum N_corner_1km if sample_reg == 1
            local mean_dep = r(mean)
            di "Mean dep. var (N_corner_1km) = `mean_dep'"
            sum N_xl_con_1km if sample_reg == 1 & N_xl_con_1km > 0
            local mean_endog_cond = r(mean)
            di "Mean endogenous (cond > 0) = `mean_endog_cond'"

            * OLS comparison
            di ""
            di "OLS coef = `ols_b'"
            di "IV coef = `iv_b'"
            di "IV/OLS ratio = " `iv_b' / `ols_b'
            di "Interpretation: " cond(abs(`iv_b') > abs(`ols_b'), ///
                "IV larger in magnitude (OLS attenuated toward zero)", ///
                "IV smaller (possible)")
        }
    }
    else {
        * Without market_c FE, use year#mun_c only
        cap noisily {
            eststo iv_main: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(mun_c) absorb(year#mun_c) savefirst

            local iv_b = _b[N_xl_con_1km]
            local iv_se = _se[N_xl_con_1km]
            local iv_N = e(N)
            local kp_f = e(rkf)
            local kp_lm = e(idstat)
            local kp_lm_p = e(idp)

            di "2SLS N_xl_con_1km coef = `iv_b' (SE = `iv_se')"
            di "N = `iv_N'"
            di "KP rk Wald F = `kp_f'"
            di "KP rk LM = `kp_lm' (p = `kp_lm_p')"
            di "Stock-Yogo (F>10): " cond(`kp_f' > 10, "PASS", "FAIL")
        }
    }

    * --- Column 6: Reduced form ---
    di ""
    di "--- Reduced Form: corner stores on instrument directly ---"
    cap noisily {
        if `has_market_fe' == 1 {
            eststo rf_main: reghdfe N_corner_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                absorb(market_c year#mun_c) vce(cluster mun_c)
        }
        else {
            eststo rf_main: reghdfe N_corner_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                absorb(year#mun_c) vce(cluster mun_c)
        }
        local rf_b = _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
        di "Reduced form coef = `rf_b'"
        di "Implied IV = RF/FS = " `rf_b' / `fs_fe_b'
    }

    * --- Column 7: First stage as separate regression ---
    di ""
    di "--- First stage as OLS: N_xl_con on instrument ---"
    cap noisily {
        if `has_market_fe' == 1 {
            eststo fs_shown: reghdfe N_xl_con_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                absorb(market_c year#mun_c) vce(cluster mun_c)
        }
        else {
            eststo fs_shown: reghdfe N_xl_con_1km ///
                SIVL_TPSTA_vc_sum_n2_tm1_1km Count_ret_fac*_1km, ///
                absorb(year#mun_c) vce(cluster mun_c)
        }
        di "First stage coef = " _b[SIVL_TPSTA_vc_sum_n2_tm1_1km]
    }
}
else {
    di "ERROR: Required variables not found. Cannot run main IV specification."
}

* ===========================================================================
* STEP 6: Store-Level Profits Specification (Table 1 / Figure 3)
* ===========================================================================
di ""
di "============================================="
di "STEP 6: STORE-LEVEL PROFITS IV"
di "============================================="

if `has_profits_wkr' == 1 & `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    di "--- profits_wkr on N_xl_con_1km (paper's main store-level result) ---"
    di "Specification: ivreghdfe profits_wkr Count_ret_fac*1km"
    di "  (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km),"
    di "  cluster(mun_c) absorb(year#mun_c)"
    di ""

    * OLS baseline
    cap noisily {
        eststo profit_ols: reghdfe profits_wkr N_xl_con_1km ///
            Count_ret_fac*_1km, absorb(year#mun_c) vce(cluster mun_c)
        local profit_ols_b = _b[N_xl_con_1km]
        di "OLS profits_wkr coef = `profit_ols_b'"
    }

    * IV specification
    cap noisily {
        eststo profit_iv: ivreghdfe profits_wkr Count_ret_fac*_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) absorb(year#mun_c) savefirst

        local profit_iv_b = _b[N_xl_con_1km]
        local profit_iv_se = _se[N_xl_con_1km]
        local profit_kp_f = e(rkf)
        local profit_iv_N = e(N)

        di "IV profits_wkr coef = `profit_iv_b' (SE = `profit_iv_se')"
        di "N = `profit_iv_N'"
        di "KP Wald F = `profit_kp_f'"
        di "Stock-Yogo (F>10): " cond(`profit_kp_f' > 10, "PASS", "FAIL")

        * Sample mean
        cap drop sample_profit
        gen sample_profit = e(sample)
        sum profits_wkr if sample_profit == 1
        di "Mean profits_wkr = " r(mean)
        di "SD profits_wkr = " r(sd)
    }

    di ""
    di "OLS vs IV comparison (profits_wkr):"
    di "  OLS = `profit_ols_b'"
    di "  IV  = `profit_iv_b'"
    di "  Ratio IV/OLS = " `profit_iv_b' / `profit_ols_b'
}
else {
    di "profits_wkr not available. Skipping store-level profits IV."
}

* ===========================================================================
* STEP 7: Table 3 — Entry and Exit Decomposition
* ===========================================================================
di ""
di "============================================="
di "STEP 7: ENTRY & EXIT DECOMPOSITION (Table 3)"
di "============================================="

if `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    * Entry
    cap confirm variable N_corner_entry_1km
    if _rc == 0 {
        di "--- IV: Corner store ENTRY ---"
        cap noisily {
            eststo iv_entry: ivreghdfe N_corner_entry_1km ///
                Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(mun_c) absorb(year#mun_c) savefirst
            local entry_b = _b[N_xl_con_1km]
            local entry_kp = e(rkf)
            di "Entry coef = `entry_b', KP F = `entry_kp'"
        }
    }

    * Exit
    cap confirm variable N_corner_exit_tm1_1km
    if _rc == 0 {
        di ""
        di "--- IV: Corner store EXIT ---"
        cap noisily {
            eststo iv_exit: ivreghdfe N_corner_exit_tm1_1km ///
                Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(mun_c) absorb(year#mun_c) savefirst
            local exit_b = _b[N_xl_con_1km]
            local exit_kp = e(rkf)
            di "Exit coef = `exit_b', KP F = `exit_kp'"
        }
    }

    * Share entry
    cap confirm variable share_corner_entry_1km
    if _rc == 0 {
        di ""
        di "--- IV: Share of corner store ENTRY ---"
        cap noisily {
            eststo iv_share_entry: ivreghdfe share_corner_entry_1km ///
                Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(mun_c) absorb(year#mun_c) savefirst
            di "Share entry coef = " _b[N_xl_con_1km] ", KP F = " e(rkf)
        }
    }
}
else {
    di "Skipping entry/exit decomposition (variables missing)."
}

* ===========================================================================
* STEP 8: IV Diagnostics — Weak Instrument & Endogeneity Tests
* ===========================================================================
di ""
di "============================================="
di "STEP 8: IV DIAGNOSTICS"
di "============================================="

if `has_N_corner_1km' == 1 & `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    * --- 8a: Re-estimate with ivreg2 for fuller diagnostics ---
    di "--- ivreg2 diagnostics (no FE for diagnostic output) ---"
    cap noisily {
        ivreg2 N_corner_1km Count_ret_fac*_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) first

        local ivreg2_kp_f = e(widstat)
        local ivreg2_kp_lm = e(idstat)
        local ivreg2_kp_lm_p = e(idp)

        di ""
        di "--- Weak Instrument Diagnostics ---"
        di "Cragg-Donald Wald F: " e(cdf)
        di "Kleibergen-Paap rk Wald F: `ivreg2_kp_f'"
        di "Stock-Yogo 10% max IV size (1 endog, 1 inst): 16.38"
        di "Stock-Yogo 15% max IV size: 8.96"
        di "Stock-Yogo 20% max IV size: 6.66"
        di "Stock-Yogo 25% max IV size: 5.53"
        di "Assessment: " cond(`ivreg2_kp_f' > 16.38, "STRONG instrument", ///
            cond(`ivreg2_kp_f' > 10, "Adequate instrument", ///
            "WEAK instrument concern"))

        di ""
        di "--- Underidentification Test ---"
        di "KP rk LM statistic: `ivreg2_kp_lm'"
        di "p-value: `ivreg2_kp_lm_p'"
        di "Assessment: " cond(`ivreg2_kp_lm_p' < 0.05, ///
            "Reject underidentification (instruments relevant)", ///
            "FAIL: Cannot reject underidentification")

        di ""
        di "--- Endogeneity (DWH) Test ---"
        local endog_stat = e(estat)
        local endog_p = e(estatp)
        di "Endogeneity statistic: `endog_stat'"
        di "p-value: `endog_p'"
        di "Assessment: " cond(`endog_p' < 0.05, ///
            "Reject exogeneity -> IV needed", ///
            "Cannot reject exogeneity -> OLS may be consistent")
    }

    * --- 8b: LIML for weak-IV robustness ---
    di ""
    di "--- LIML Estimation for Weak-IV Robustness ---"
    cap noisily {
        ivreg2 N_corner_1km Count_ret_fac*_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) liml

        local liml_b = _b[N_xl_con_1km]
        di "LIML N_xl_con_1km coef = `liml_b'"
        di "2SLS coef = `iv_b'"
        di "LIML-2SLS gap = " abs(`liml_b' - `iv_b')
        di "Assessment: " cond(abs(`liml_b' - `iv_b') / abs(`iv_b') < 0.10, ///
            "Small gap (<10%) -> weak IV not a major concern", ///
            "Large gap (>10%) -> potential weak IV bias")
    }

    * --- 8c: Anderson-Rubin weak-IV robust confidence set ---
    di ""
    di "--- Anderson-Rubin Test (weak-IV robust inference) ---"
    cap noisily {
        ivreg2 N_corner_1km Count_ret_fac*_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) first
        * AR statistic stored by ivreg2
        di "Note: For formal AR confidence sets, use -weakiv- package"
    }
}
else {
    di "Skipping diagnostics (missing required variables)."
}

* ===========================================================================
* STEP 9: Robustness — Alternative Specifications
* ===========================================================================
di ""
di "============================================="
di "STEP 9: ROBUSTNESS CHECKS"
di "============================================="

if `has_N_corner_1km' == 1 & `has_N_xl_con_1km' == 1 & `has_instrument' == 1 {

    * --- 9a: Different functional form (IHS of outcome) ---
    di "--- Robustness: Inverse hyperbolic sine of outcome ---"
    cap noisily {
        gen as_N_corner_1km = asinh(N_corner_1km)
        label variable as_N_corner_1km "IHS(corner stores 1km)"

        eststo iv_ihs: ivreghdfe as_N_corner_1km Count_ret_fac*_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) absorb(year#mun_c) savefirst
        di "IHS outcome: coef = " _b[N_xl_con_1km] ", KP F = " e(rkf)
    }

    * --- 9b: Conditional on chains present ---
    di ""
    di "--- Robustness: Conditional on chains > 0 ---"
    cap noisily {
        cap confirm variable N_xl_con_AGEB
        if _rc == 0 {
            eststo iv_cond: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km) ///
                if N_xl_con_AGEB != ., ///
                cluster(mun_c) absorb(year#mun_c) savefirst
            di "Conditional: coef = " _b[N_xl_con_1km] ///
                ", N = " e(N) ", KP F = " e(rkf)
        }
        else {
            di "N_xl_con_AGEB not available; using N_xl_con_1km > 0 instead"
            eststo iv_cond: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km) ///
                if N_xl_con_1km > 0, ///
                cluster(mun_c) absorb(year#mun_c) savefirst
            di "Conditional (chains>0): coef = " _b[N_xl_con_1km] ///
                ", N = " e(N) ", KP F = " e(rkf)
        }
    }

    * --- 9c: Different clustering (AGEB / market level) ---
    di ""
    di "--- Robustness: Clustering at market level ---"
    cap noisily {
        if `has_market_fe' == 1 {
            eststo iv_clust: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(market_c) absorb(year#mun_c) savefirst
            di "Market-clustered: coef = " _b[N_xl_con_1km] ///
                ", SE = " _se[N_xl_con_1km] ", KP F = " e(rkf)
        }
        else {
            eststo iv_clust: ivreghdfe N_corner_1km Count_ret_fac*_1km ///
                (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
                cluster(market_id) absorb(year#mun_c) savefirst
            di "Market-clustered: coef = " _b[N_xl_con_1km] ///
                ", SE = " _se[N_xl_con_1km] ", KP F = " e(rkf)
        }
    }

    * --- 9d: Without PCA controls ---
    di ""
    di "--- Robustness: Without PCA retail controls ---"
    cap noisily {
        eststo iv_noctrl: ivreghdfe N_corner_1km ///
            (N_xl_con_1km = SIVL_TPSTA_vc_sum_n2_tm1_1km), ///
            cluster(mun_c) absorb(year#mun_c) savefirst
        di "No controls: coef = " _b[N_xl_con_1km] ", KP F = " e(rkf)
    }
}
else {
    di "Skipping robustness checks (missing variables)."
}

* ===========================================================================
* STEP 10: Cross-Validation Data Output
* ===========================================================================
di ""
di "============================================="
di "STEP 10: CROSS-VALIDATION DATA"
di "============================================="

di "=== CROSS-VALIDATION DATA ==="
cap noisily {
    di "IV_corner_coef = `iv_b'"
    di "IV_corner_se = `iv_se'"
    di "IV_corner_N = `iv_N'"
    di "IV_KP_F = `kp_f'"
    di "IV_KP_LM = `kp_lm'"
    di "IV_KP_LM_p = `kp_lm_p'"
    if "`profit_iv_b'" != "" {
        di "IV_profits_coef = `profit_iv_b'"
        di "IV_profits_se = `profit_iv_se'"
        di "IV_profits_N = `profit_iv_N'"
        di "IV_profits_KP_F = `profit_kp_f'"
    }
}

* Save estimation results for cross-validation
cap noisily {
    * Create a dataset with key results
    preserve
    clear
    set obs 10
    gen str40 statistic = ""
    gen double value = .

    replace statistic = "iv_corner_coef" in 1
    cap replace value = `iv_b' in 1
    replace statistic = "iv_corner_se" in 2
    cap replace value = `iv_se' in 2
    replace statistic = "iv_corner_N" in 3
    cap replace value = `iv_N' in 3
    replace statistic = "iv_kp_f" in 4
    cap replace value = `kp_f' in 4
    replace statistic = "iv_kp_lm" in 5
    cap replace value = `kp_lm' in 5
    replace statistic = "ols_corner_coef" in 6
    cap replace value = `ols_b' in 6
    replace statistic = "iv_profits_coef" in 7
    cap replace value = `profit_iv_b' in 7
    replace statistic = "iv_profits_se" in 8
    cap replace value = `profit_iv_se' in 8
    replace statistic = "iv_profits_N" in 9
    cap replace value = `profit_iv_N' in 9
    replace statistic = "iv_profits_kp_f" in 10
    cap replace value = `profit_kp_f' in 10

    save "v1/output/tables/iv_crossval_data.dta", replace
    export delimited using "v1/output/tables/iv_crossval_data.csv", replace
    restore
}

* ===========================================================================
* STEP 11: Output Tables
* ===========================================================================
di ""
di "============================================="
di "STEP 11: OUTPUT TABLES"
di "============================================="

cap noisily {
    * Table 2 replication: OLS -> IV progression
    esttab ols_simple ols_fe ols_ctrl iv_main rf_main fs_shown ///
        using "v1/output/tables/tab_iv_table2.tex", ///
        se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
        keep(N_xl_con_1km SIVL_TPSTA_vc_sum_n2_tm1_1km) ///
        order(N_xl_con_1km SIVL_TPSTA_vc_sum_n2_tm1_1km) ///
        label booktabs replace ///
        mtitles("OLS" "OLS+FE" "OLS+Ctrl" "2SLS" "Reduced" "1st Stage") ///
        scalars("rkf KP Wald F" "idstat KP LM" "N Observations") ///
        title("Effect of Chain Entry on Corner Stores (Table 2 Replication)") ///
        note("Instrument: street suitability x lagged neighbor chain concentration." ///
             "Standard errors clustered at municipality level.")
}

cap noisily {
    * Profits table
    esttab profit_ols profit_iv ///
        using "v1/output/tables/tab_iv_profits.tex", ///
        se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
        keep(N_xl_con_1km) ///
        label booktabs replace ///
        mtitles("OLS" "2SLS") ///
        scalars("rkf KP Wald F" "N Observations") ///
        title("Effect of Chain Entry on Corner Store Profits per Worker") ///
        note("Dependent variable: profits per worker (1000s pesos)." ///
             "Instrument: street suitability x lagged neighbor chain concentration." ///
             "Standard errors clustered at municipality level.")
}

cap noisily {
    * Entry/Exit decomposition
    esttab iv_entry iv_exit iv_share_entry ///
        using "v1/output/tables/tab_iv_entry_exit.tex", ///
        se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
        keep(N_xl_con_1km) ///
        label booktabs replace ///
        mtitles("Entry" "Exit" "Share Entry") ///
        scalars("rkf KP Wald F" "N Observations") ///
        title("Entry and Exit Decomposition (Table 3 Replication)") ///
        note("Instrument: street suitability x lagged neighbor chain concentration." ///
             "Standard errors clustered at municipality level.")
}

cap noisily {
    * Robustness table
    esttab iv_main iv_ihs iv_cond iv_clust iv_noctrl ///
        using "v1/output/tables/tab_iv_robustness.tex", ///
        se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
        keep(N_xl_con_1km) ///
        label booktabs replace ///
        mtitles("Main" "IHS" "Cond>0" "Mkt Clust" "No Ctrl") ///
        scalars("rkf KP Wald F" "N Observations") ///
        title("Robustness: Alternative IV Specifications") ///
        note("Standard errors clustered as noted.")
}

* ===========================================================================
* STEP 12: Summary Statistics for Diagnostics Report
* ===========================================================================
di ""
di "============================================="
di "STEP 12: DIAGNOSTICS SUMMARY"
di "============================================="

di ""
di "╔══════════════════════════════════════════════════════════╗"
di "║         MEXICO RETAIL IV — RESULTS SUMMARY              ║"
di "╠══════════════════════════════════════════════════════════╣"
cap noisily {
    di "║ Data source: " cond(`real_data_loaded' == 1, "REAL (Panel_Markets)", ///
        cond(`real_data_loaded' == 4, "PARTIAL (CP_IV)", "SIMULATED"))
    di "║"
    di "║ MAIN IV (Table 2, Col 5):"
    di "║   Dep var: N_corner_1km"
    di "║   Endog:   N_xl_con_1km"
    di "║   IV:      SIVL_TPSTA_vc_sum_n2_tm1_1km"
    di "║   Coef:    `iv_b'"
    di "║   SE:      `iv_se'"
    di "║   N:       `iv_N'"
    di "║   KP F:    `kp_f'"
    di "║"
    di "║ PROFITS IV (Table 1 / Figure 3):"
    di "║   Dep var: profits_wkr"
    di "║   Coef:    `profit_iv_b'"
    di "║   SE:      `profit_iv_se'"
    di "║   KP F:    `profit_kp_f'"
    di "║"
    di "║ FIRST STAGE (instrument relevance):"
    di "║   F > 10:  " cond(`kp_f' > 10, "PASS", "FAIL")
    di "║   F > 16.38 (Stock-Yogo 10%): " cond(`kp_f' > 16.38, "PASS", "FAIL")
}
di "╚══════════════════════════════════════════════════════════╝"

* ===========================================================================
* DONE
* ===========================================================================

timer off 1
timer list

di ""
di "============================================="
di "MEXICO IV ANALYSIS COMPLETE"
di "============================================="

log close
