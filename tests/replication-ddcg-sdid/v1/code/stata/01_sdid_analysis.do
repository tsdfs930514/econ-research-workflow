/*==============================================================================
Project:    DDCG Democracy & Growth -- Synthetic Difference-in-Differences
Version:    v1
Script:     01_sdid_analysis.do
Purpose:    Test /run-sdid skill using DDCG data adapted for SDID estimation.
            Constructs a clean binary treatment from dem indicator, subsets to
            a balanced panel of democratizers (1980-2000) plus never-treated
            controls, and estimates SDID, DID, and SC for comparison.
Author:     Claude Code
Created:    2026-02-26
Modified:   2026-02-26
Input:      v1/data/raw/DDCGdata_final.dta
Output:     v1/output/tables/tab_sdid_results.tex
            v1/output/tables/sdid_crossval.csv
            v1/output/figures/sdid_graph.pdf
            v1/output/logs/01_sdid_analysis.log
==============================================================================*/

* Required packages:
*   ssc install sdid
*   ssc install estout
*   ssc install ftools

version 18
clear all
set more off
set maxvar 32767
set matsize 11000
set seed 12345

* --- Paths -------------------------------------------------------------------
local basedir "F:/Learning/econ-research-workflow/tests/replication-ddcg-sdid/v1"
local rawdir  "`basedir'/data/raw"
local cleandir "`basedir'/data/clean"
local tempdir  "`basedir'/data/temp"
local outdir  "`basedir'/output/tables"
local figdir  "`basedir'/output/figures"
local logdir  "`basedir'/output/logs"

* --- Ensure output directories exist -----------------------------------------
cap mkdir "`outdir'"
cap mkdir "`figdir'"
cap mkdir "`logdir'"
cap mkdir "`cleandir'"
cap mkdir "`tempdir'"

* --- Log ---------------------------------------------------------------------
cap log close _all
log using "`logdir'/01_sdid_analysis.log", replace text

di as txt ""
di as txt "=================================================================="
di as txt "  SDID Analysis of DDCG Democracy & Growth Data"
di as txt "  Started: `c(current_date)' `c(current_time)'"
di as txt "=================================================================="
di as txt ""


/*==============================================================================
  PART 1: Load data and inspect structure
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 1: Load and inspect DDCG data"
di as txt "=================================================================="
di as txt ""

use "`rawdir'/DDCGdata_final.dta", clear
desc, short
desc

* Panel structure
xtset wbcode2 year
di as txt ""
di as txt ">>> Panel variable: wbcode2 (country code)"
di as txt ">>> Time variable:  year"
di as txt ">>> Balance check:"
xtdescribe

* Key variables
di as txt ""
di as txt ">>> Summary of key variables:"
sum dem y, detail


/*==============================================================================
  PART 2: Construct clean binary treatment indicator
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 2: Construct treatment indicator for SDID"
di as txt "=================================================================="
di as txt ""

* SDID requires a single treatment adoption time per unit: once treated,
* always treated (absorbing treatment). The DDCG `dem` variable can
* switch on and off. We identify the FIRST year each country has dem==1
* and define treatment as an absorbing indicator from that year forward.

* Step 2a: Identify first year of democratization per country
bysort wbcode2 (year): gen first_dem_year = year if dem == 1
bysort wbcode2: egen treatment_year = min(first_dem_year)
drop first_dem_year
label variable treatment_year "First year country has dem==1"

* Step 2b: Create absorbing binary treatment
gen treatment = (year >= treatment_year) if treatment_year != .
replace treatment = 0 if treatment_year == .
label variable treatment "Binary treatment: 1 if year >= first democratization"

* Step 2c: Diagnostics
di as txt ">>> Treatment year distribution:"
tab treatment_year if treatment_year != ., sort

di as txt ""
di as txt ">>> Treatment status overall:"
tab treatment

di as txt ""
di as txt ">>> Number of countries by treatment status:"
preserve
    bysort wbcode2: keep if _n == 1
    gen ever_treated = (treatment_year != .)
    label variable ever_treated "Ever democratized"
    tab ever_treated
    di as txt ""
    di as txt ">>> Summary of treatment years (treated countries only):"
    sum treatment_year if ever_treated == 1, detail
restore


/*==============================================================================
  PART 3: Subset to manageable sample
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 3: Subset to balanced panel for SDID"
di as txt "=================================================================="
di as txt ""

* SDID works best with a clear treatment structure. We select:
*   (a) Countries that democratized between 1980 and 2000 (treated group)
*   (b) Countries that NEVER democratized in the full sample (control group)
* This gives a clean staggered-to-absorbing design.

* Identify never-treated countries (dem==0 for all years)
bysort wbcode2: egen max_dem = max(dem)
gen never_treated = (max_dem == 0)
label variable never_treated "Country never had dem==1"

* Flag countries treated between 1980-2000
gen treated_1980_2000 = (treatment_year >= 1980 & treatment_year <= 2000 & treatment_year != .)
label variable treated_1980_2000 "Democratized between 1980-2000"

* Subset
keep if treated_1980_2000 == 1 | never_treated == 1

* Report sample composition
di as txt ">>> Subset sample composition:"
preserve
    bysort wbcode2: keep if _n == 1
    di as txt "    Treated (democratized 1980-2000):"
    count if treated_1980_2000 == 1
    di as txt "    Never-treated controls:"
    count if never_treated == 1
    di as txt "    Total countries:"
    count
restore

* Step 3b: Verify balanced panel within subset
xtset wbcode2 year
xtdescribe

* Confirm balance
di as txt ""
di as txt ">>> Verifying panel balance:"
qui xtset wbcode2 year
local bal = r(balanced)
di as txt "    Panel balance status: `bal'"

* If not balanced, force balance by keeping only the common year range
if "`bal'" != "strongly balanced" {
    di as txt "    Panel not strongly balanced. Forcing balance..."

    * Find the min and max year across all units
    qui sum year
    local ymin = r(min)
    local ymax = r(max)

    * Count expected observations per unit
    local expected_T = `ymax' - `ymin' + 1

    * Drop units that don't have all years
    bysort wbcode2: gen nobs_unit = _N
    tab nobs_unit
    keep if nobs_unit == `expected_T'
    drop nobs_unit

    * Re-verify
    xtset wbcode2 year
    xtdescribe
    di as txt "    After forcing balance:"
    qui xtset wbcode2 year
    di as txt "    Panel balance status: `r(balanced)'"
}

* Step 3c: Prepare outcome variable
* Use log GDP per capita (lgdp) or GDP growth (y) as outcome
* y = GDP growth rate is the standard DDCG outcome
rename y gdp_growth
label variable gdp_growth "GDP growth rate (DDCG outcome)"

* Check for missing values in key variables
di as txt ""
di as txt ">>> Missing values check:"
misstable summarize gdp_growth treatment wbcode2 year

* Drop observations with missing outcome (SDID cannot handle missing data)
drop if missing(gdp_growth)

* Re-verify balance after dropping missing
xtset wbcode2 year
qui xtset wbcode2 year
local bal = r(balanced)
di as txt "    After dropping missing outcome, balance: `bal'"

if "`bal'" != "strongly balanced" {
    di as txt "    Dropping units with incomplete panels..."
    qui sum year
    local ymin = r(min)
    local ymax = r(max)
    local expected_T = `ymax' - `ymin' + 1
    bysort wbcode2: gen nobs_unit = _N
    keep if nobs_unit == `expected_T'
    drop nobs_unit
    xtset wbcode2 year
    xtdescribe
}

* Final sample summary
di as txt ""
di as txt ">>> Final analysis sample:"
di as txt "    Year range:"
sum year
di as txt "    Number of country-year observations:"
count
preserve
    bysort wbcode2: keep if _n == 1
    di as txt "    Number of countries:"
    count
    di as txt "    Treated:"
    count if treatment_year != .
    di as txt "    Controls:"
    count if treatment_year == .
restore

* Save clean analysis dataset
save "`cleandir'/ddcg_sdid_sample.dta", replace


/*==============================================================================
  PART 4: Install SDID package
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 4: Install required packages"
di as txt "=================================================================="
di as txt ""

* Install sdid
cap which sdid
if _rc != 0 {
    di as txt ">>> sdid not found. Installing from SSC..."
    cap noisily ssc install sdid, replace
}
else {
    di as txt ">>> sdid already installed."
}

* Install estout for esttab
cap which esttab
if _rc != 0 {
    di as txt ">>> estout not found. Installing from SSC..."
    cap noisily ssc install estout, replace
}
else {
    di as txt ">>> estout (esttab) already installed."
}


/*==============================================================================
  PART 5: SDID estimation -- Main specification
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 5: Synthetic Difference-in-Differences (SDID)"
di as txt "=================================================================="
di as txt ""

* Initialize result locals (Issue #24: use locals, not estimates store)
local sdid_att = .
local sdid_se  = .
local sdid_N   = .
local sdid_ok  = 0

* --- 5a: SDID with bootstrap VCE (Issue #25: skip jackknife for staggered) ---
di as txt "--- 5a: SDID estimation with bootstrap VCE ---"
di as txt ""

cap noisily {
    sdid gdp_growth wbcode2 year treatment, ///
        vce(bootstrap) method(sdid) seed(12345) reps(50) ///
        graph g1_opt(xtitle("") saving("`figdir'/sdid_graph.pdf", replace)) ///
        graph_export("`figdir'/sdid_", .pdf)
}

if _rc == 0 {
    local sdid_att = e(ATT)
    local sdid_se  = e(se)
    local sdid_N   = e(N)
    local sdid_ok  = 1

    di as txt ""
    di as txt ">>> SDID Results (bootstrap VCE):"
    di as txt "    ATT  = " %9.4f `sdid_att'
    di as txt "    SE   = " %9.4f `sdid_se'
    di as txt "    N    = " `sdid_N'
}
else {
    di as err ">>> SDID estimation failed with error code: " _rc
    di as err ">>> Will attempt with simpler subset in Part 8."
}


/*==============================================================================
  PART 6: Traditional DID comparison
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 6: Traditional DID comparison"
di as txt "=================================================================="
di as txt ""

local did_att = .
local did_se  = .
local did_N   = .
local did_ok  = 0

di as txt "--- 6a: sdid with method(did), bootstrap VCE ---"
di as txt ""

cap noisily {
    use "`cleandir'/ddcg_sdid_sample.dta", clear
    xtset wbcode2 year

    sdid gdp_growth wbcode2 year treatment, ///
        vce(bootstrap) method(did) seed(12345) reps(50)
}

if _rc == 0 {
    local did_att = e(ATT)
    local did_se  = e(se)
    local did_N   = e(N)
    local did_ok  = 1

    di as txt ""
    di as txt ">>> DID Results (via sdid package, bootstrap VCE):"
    di as txt "    ATT  = " %9.4f `did_att'
    di as txt "    SE   = " %9.4f `did_se'
    di as txt "    N    = " `did_N'
}
else {
    di as err ">>> DID estimation failed with error code: " _rc
}


/*==============================================================================
  PART 7: Synthetic Control comparison
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 7: Synthetic Control (SC) comparison"
di as txt "=================================================================="
di as txt ""

local sc_att = .
local sc_se  = .
local sc_N   = .
local sc_ok  = 0

di as txt "--- 7a: sdid with method(sc), bootstrap VCE ---"
di as txt ""

cap noisily {
    use "`cleandir'/ddcg_sdid_sample.dta", clear
    xtset wbcode2 year

    sdid gdp_growth wbcode2 year treatment, ///
        vce(bootstrap) method(sc) seed(12345) reps(50)
}

if _rc == 0 {
    local sc_att = e(ATT)
    local sc_se  = e(se)
    local sc_N   = e(N)
    local sc_ok  = 1

    di as txt ""
    di as txt ">>> SC Results (via sdid package, bootstrap VCE):"
    di as txt "    ATT  = " %9.4f `sc_att'
    di as txt "    SE   = " %9.4f `sc_se'
    di as txt "    N    = " `sc_N'
}
else {
    di as err ">>> SC estimation failed with error code: " _rc
}


/*==============================================================================
  PART 8: Fallback -- Simpler subset if main estimation failed
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 8: Fallback with simpler subset (if needed)"
di as txt "=================================================================="
di as txt ""

* Check if we have any SDID result; if not, try a simpler sample
if `sdid_ok' == 0 {
    di as txt ">>> Main SDID estimate not available."
    di as txt ">>> Attempting with a smaller, simpler subset..."
    di as txt ""

    * Reload the raw data and construct an even simpler sample:
    * Pick a narrow treatment window (1990-1995) with fewer countries
    use "`rawdir'/DDCGdata_final.dta", clear
    xtset wbcode2 year

    * Identify first dem year
    bysort wbcode2 (year): gen first_dem_year = year if dem == 1
    bysort wbcode2: egen treatment_year = min(first_dem_year)
    drop first_dem_year

    * Create absorbing treatment
    gen treatment = (year >= treatment_year) if treatment_year != .
    replace treatment = 0 if treatment_year == .

    * Identify never-treated
    bysort wbcode2: egen max_dem = max(dem)
    gen never_treated = (max_dem == 0)

    * Narrow treated group: democratized 1990-1995 only
    gen treated_narrow = (treatment_year >= 1990 & treatment_year <= 1995 & treatment_year != .)

    * Keep only these plus never-treated
    keep if treated_narrow == 1 | never_treated == 1

    * Restrict to 1970-2010 to reduce panel length
    keep if year >= 1970 & year <= 2010

    * Drop missing outcome
    rename y gdp_growth
    drop if missing(gdp_growth)

    * Force balance
    qui sum year
    local ymin = r(min)
    local ymax = r(max)
    local expected_T = `ymax' - `ymin' + 1
    bysort wbcode2: gen nobs_unit = _N
    keep if nobs_unit == `expected_T'
    drop nobs_unit

    * Verify
    xtset wbcode2 year
    xtdescribe

    preserve
        bysort wbcode2: keep if _n == 1
        di as txt "    Fallback sample -- countries:"
        count
        di as txt "    Treated:"
        count if treatment_year != .
        di as txt "    Controls:"
        count if treatment_year == .
    restore

    * Save fallback sample
    save "`tempdir'/ddcg_sdid_fallback.dta", replace

    * Try SDID on fallback sample
    di as txt ""
    di as txt "--- Fallback SDID estimation ---"

    cap noisily {
        sdid gdp_growth wbcode2 year treatment, ///
            vce(bootstrap) method(sdid) seed(12345) reps(50)
    }

    if _rc == 0 {
        local sdid_att = e(ATT)
        local sdid_se  = e(se)
        local sdid_N   = e(N)
        local sdid_ok  = 1

        di as txt ">>> Fallback SDID ATT = " %9.4f `sdid_att'
        di as txt ">>> Fallback SDID SE  = " %9.4f `sdid_se'
    }
    else {
        di as err ">>> Fallback SDID also failed. Error code: " _rc
    }

    * Try DID on fallback
    di as txt ""
    di as txt "--- Fallback DID estimation ---"

    cap noisily {
        use "`tempdir'/ddcg_sdid_fallback.dta", clear
        xtset wbcode2 year

        sdid gdp_growth wbcode2 year treatment, ///
            vce(bootstrap) method(did) seed(12345) reps(50)
    }

    if _rc == 0 {
        local did_att = e(ATT)
        local did_se  = e(se)
        local did_N   = e(N)
        local did_ok  = 1

        di as txt ">>> Fallback DID ATT = " %9.4f `did_att'
        di as txt ">>> Fallback DID SE  = " %9.4f `did_se'
    }

    * Try SC on fallback
    di as txt ""
    di as txt "--- Fallback SC estimation ---"

    cap noisily {
        use "`tempdir'/ddcg_sdid_fallback.dta", clear
        xtset wbcode2 year

        sdid gdp_growth wbcode2 year treatment, ///
            vce(bootstrap) method(sc) seed(12345) reps(50)
    }

    if _rc == 0 {
        local sc_att = e(ATT)
        local sc_se  = e(se)
        local sc_N   = e(N)
        local sc_ok  = 1

        di as txt ">>> Fallback SC ATT = " %9.4f `sc_att'
        di as txt ">>> Fallback SC SE  = " %9.4f `sc_se'
    }
}
else {
    di as txt ">>> Main SDID estimate available. Skipping fallback."
}


/*==============================================================================
  PART 9: Comparison table with esttab
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 9: Comparison table (SDID vs DID vs SC)"
di as txt "=================================================================="
di as txt ""

* Report available results from local macros (Issue #24 fix)
di as txt ">>> Results summary:"
di as txt "    SDID: ok=`sdid_ok'  ATT=" %9.4f `sdid_att' "  SE=" %9.4f `sdid_se'
di as txt "    DID:  ok=`did_ok'   ATT=" %9.4f `did_att'  "  SE=" %9.4f `did_se'
di as txt "    SC:   ok=`sc_ok'    ATT=" %9.4f `sc_att'   "  SE=" %9.4f `sc_se'
di as txt ""

local any_ok = (`sdid_ok' + `did_ok' + `sc_ok' > 0)

if `any_ok' {
    * Build LaTeX table from local macros (not estimates store)
    cap file close texfile
    file open texfile using "`outdir'/tab_sdid_results.tex", write replace
    file write texfile "\begin{table}[htbp]" _n
    file write texfile "\centering" _n
    file write texfile "\caption{Synthetic DID vs Traditional DID vs Synthetic Control}" _n
    file write texfile "\label{tab:sdid_results}" _n
    file write texfile "\begin{tabular}{lccc}" _n
    file write texfile "\hline\hline" _n
    file write texfile " & SDID & DID & SC \\" _n
    file write texfile "\hline" _n

    * ATT row
    file write texfile "ATT"
    foreach m in sdid did sc {
        if ``m'_ok' {
            local att_str : di %9.4f ``m'_att'
            local se_val = ``m'_se'
            local pval = 2 * normal(-abs(``m'_att' / ``m'_se'))
            local stars ""
            if `pval' < 0.01      local stars "***"
            else if `pval' < 0.05 local stars "**"
            else if `pval' < 0.10 local stars "*"
            file write texfile " & `att_str'`stars'"
        }
        else {
            file write texfile " & ---"
        }
    }
    file write texfile " \\" _n

    * SE row
    file write texfile "  "
    foreach m in sdid did sc {
        if ``m'_ok' {
            local se_str : di %9.4f ``m'_se'
            file write texfile " & (`se_str')"
        }
        else {
            file write texfile " & "
        }
    }
    file write texfile " \\" _n

    * N row
    file write texfile "N"
    foreach m in sdid did sc {
        if ``m'_ok' {
            file write texfile " & ``m'_N'"
        }
        else {
            file write texfile " & "
        }
    }
    file write texfile " \\" _n

    file write texfile "\hline\hline" _n
    file write texfile "\multicolumn{4}{p{12cm}}{\small\textit{Note:} " _n
    file write texfile "ATT estimates from DDCG Democracy \& Growth panel data. " _n
    file write texfile "Treatment = first year of democratization. " _n
    file write texfile "Bootstrap VCE with 50 replications, seed 12345. " _n
    file write texfile "SDID = Arkhangelsky et al.\ (2021). " _n
    file write texfile "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.} \\" _n
    file write texfile "\end{tabular}" _n
    file write texfile "\end{table}" _n
    file close texfile

    di as txt ">>> Table saved to: `outdir'/tab_sdid_results.tex"
}
else {
    di as err ">>> No estimates available. All methods failed."
    di as err ">>> Writing diagnostic table..."

    cap file close texfile
    file open texfile using "`outdir'/tab_sdid_results.tex", write replace
    file write texfile "\begin{table}[htbp]" _n
    file write texfile "\centering" _n
    file write texfile "\caption{SDID Analysis -- All Methods Failed}" _n
    file write texfile "\label{tab:sdid_results}" _n
    file write texfile "\begin{tabular}{lp{10cm}}" _n
    file write texfile "\hline\hline" _n
    file write texfile "Method & Status \\" _n
    file write texfile "\hline" _n
    file write texfile "SDID & Failed -- check log for error details \\" _n
    file write texfile "DID  & Failed -- check log for error details \\" _n
    file write texfile "SC   & Failed -- check log for error details \\" _n
    file write texfile "\hline\hline" _n
    file write texfile "\multicolumn{2}{p{12cm}}{\small\textit{Note:} " _n
    file write texfile "The \texttt{sdid} package requires a strongly balanced panel " _n
    file write texfile "with a clean absorbing treatment structure. The DDCG data " _n
    file write texfile "may have features incompatible with the package. " _n
    file write texfile "See log for diagnostics.} \\" _n
    file write texfile "\end{tabular}" _n
    file write texfile "\end{table}" _n
    file close texfile

    di as txt ">>> Diagnostic table written to: `outdir'/tab_sdid_results.tex"
}


/*==============================================================================
  PART 10: Cross-validation data export
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 10: Cross-validation data export"
di as txt "=================================================================="
di as txt ""

* Export results to CSV from local macros (Issue #24 fix)
cap noisily {
    clear
    set obs 3
    gen str20 method = ""
    gen att = .
    gen se = .
    gen pvalue = .
    gen str20 source = "stata_sdid"

    local row = 1
    foreach m in sdid did sc {
        replace method = "`m'" in `row'
        if ``m'_ok' {
            replace att = ``m'_att' in `row'
            replace se = ``m'_se' in `row'
            replace pvalue = 2 * normal(-abs(``m'_att' / ``m'_se')) in `row'
        }
        local row = `row' + 1
    }

    list, clean noobs
    export delimited using "`outdir'/sdid_crossval.csv", replace
    di as txt ">>> Cross-validation data saved to: `outdir'/sdid_crossval.csv"
}

if _rc != 0 {
    di as err ">>> Failed to export cross-validation CSV. Error: " _rc
}


/*==============================================================================
  PART 11: Summary diagnostics
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 11: Summary diagnostics"
di as txt "=================================================================="
di as txt ""

* Reload the analysis sample and report final diagnostics
cap noisily {
    cap use "`cleandir'/ddcg_sdid_sample.dta", clear
    if _rc != 0 {
        cap use "`tempdir'/ddcg_sdid_fallback.dta", clear
    }

    if _rc == 0 {
        xtset wbcode2 year

        di as txt ">>> Final sample diagnostics:"
        di as txt ""

        * Panel structure
        di as txt "    Panel structure:"
        xtdescribe

        * Outcome summary
        di as txt ""
        di as txt "    Outcome variable (gdp_growth) by treatment status:"
        bysort treatment: sum gdp_growth

        * Treatment timing
        di as txt ""
        di as txt "    Treatment year distribution:"
        preserve
            bysort wbcode2: keep if _n == 1
            tab treatment_year if treatment_year != .
        restore

        * Pre-treatment parallel trends visual check
        di as txt ""
        di as txt "    Pre-treatment mean outcome by treatment group:"
        preserve
            bysort wbcode2: egen min_treat_yr = min(treatment_year)
            gen pre_period = (year < min_treat_yr) if min_treat_yr != .
            replace pre_period = 1 if treatment_year == .

            gen treated_group = (treatment_year != .)
            collapse (mean) gdp_growth, by(year treated_group)
            list if year >= 1970, clean
        restore
    }
}


/*==============================================================================
  Wrap-up
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  SDID ANALYSIS COMPLETE"
di as txt "=================================================================="
di as txt ""
di as txt "  Log file:         `logdir'/01_sdid_analysis.log"
di as txt "  LaTeX table:      `outdir'/tab_sdid_results.tex"
di as txt "  Cross-val CSV:    `outdir'/sdid_crossval.csv"
di as txt "  Clean data:       `cleandir'/ddcg_sdid_sample.dta"
di as txt "  Figures:          `figdir'/sdid_graph.pdf"
di as txt ""
di as txt "  Finished: `c(current_date)' `c(current_time)'"
di as txt ""

cap log close _all

exit
