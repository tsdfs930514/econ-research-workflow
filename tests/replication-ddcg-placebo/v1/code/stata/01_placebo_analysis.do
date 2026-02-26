/*==============================================================================
Project:    DDCG Placebo Analysis
Version:    v1
Script:     01_placebo_analysis.do
Purpose:    Placebo timing test and permutation inference for democracy-growth
            relationship using DDCG (Acemoglu et al.) data.
Author:     Claude Code
Created:    2026-02-26
Modified:   2026-02-26
Input:      v1/data/raw/DDCGdata_final.dta
Output:     v1/output/tables/tab_placebo_timing.tex
            v1/output/figures/fig_placebo_permutation.png
            v1/output/logs/01_placebo_analysis.log
            v1/data/temp/permutation_results.dta
            v1/data/temp/permutation_coefs_stata.csv
            v1/data/temp/cross_validation_stata.csv
==============================================================================*/

clear all
set more off
set matsize 5000
set seed 12345

* ---------------------------------------------------------------------------- *
* Logging
* ---------------------------------------------------------------------------- *
cap log close
log using "v1/output/logs/01_placebo_analysis.log", replace

display "====================================="
display " DDCG Placebo Analysis"
display " Date: $S_DATE  Time: $S_TIME"
display "====================================="

* ---------------------------------------------------------------------------- *
* Install required packages
* ---------------------------------------------------------------------------- *
cap which reghdfe
if _rc != 0 {
    cap ssc install reghdfe, replace
}

cap which ftools
if _rc != 0 {
    cap ssc install ftools, replace
}

cap which estout
if _rc != 0 {
    cap ssc install estout, replace
}

display "Package checks complete."

* ============================================================================ *
* 1. Load data and set up panel
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 1: Loading data and setting up panel"
display "============================================"

use "v1/data/raw/DDCGdata_final.dta", clear

* Examine key variables
describe y dem wbcode2 year, short
summarize y dem, detail

* Set panel structure
xtset wbcode2 year
display "Panel is set: wbcode2 (country) x year"

* ============================================================================ *
* 2. Baseline regression
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 2: Baseline regression"
display "============================================"

* Baseline: GDP on democracy with 4 lags of GDP, country FE, year dummies
* This replicates the core DDCG specification
xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)

* Store baseline democracy coefficient
scalar baseline_dem_coef = _b[dem]
scalar baseline_dem_se   = _se[dem]
scalar baseline_dem_t    = baseline_dem_coef / baseline_dem_se
scalar baseline_dem_p    = 2 * ttail(e(df_r), abs(baseline_dem_t))

display _newline
display "Baseline democracy coefficient: " %9.6f baseline_dem_coef
display "Baseline standard error:        " %9.6f baseline_dem_se
display "Baseline t-statistic:           " %9.4f baseline_dem_t
display "Baseline p-value:               " %9.4f baseline_dem_p

estimates store baseline

* ============================================================================ *
* 3. Placebo timing test
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 3: Placebo timing test"
display "============================================"
display "Creating fake treatment 5 years before actual democratization."
display "Restricting to pre-treatment sample only."

* Preserve the original dataset
preserve

cap noisily {
    * Identify the exact year of first democratization for each country.
    * A democratization event is dem switching from 0 to 1.
    gen dem_switch = (dem == 1 & L.dem == 0)
    bysort wbcode2 (year): egen first_dem_year = min(cond(dem_switch == 1, year, .))

    * Create placebo treatment: turns on 5 years before actual democratization
    gen placebo_treat = 0
    replace placebo_treat = 1 if first_dem_year != . & year >= (first_dem_year - 5)

    * Restrict sample to pre-treatment period only.
    * For countries that democratized, keep only obs before the actual event.
    * For countries that never democratized, keep all observations.
    drop if first_dem_year != . & year >= first_dem_year

    display "Sample restricted to pre-democratization period."
    tab placebo_treat, missing

    * Run the placebo timing regression (same spec, placebo_treat instead of dem)
    xtreg y l(1/4).y placebo_treat yy*, fe vce(cluster wbcode2)

    * Store placebo timing coefficient
    scalar placebo_timing_coef = _b[placebo_treat]
    scalar placebo_timing_se   = _se[placebo_treat]
    scalar placebo_timing_t    = placebo_timing_coef / placebo_timing_se
    scalar placebo_timing_p    = 2 * ttail(e(df_r), abs(placebo_timing_t))

    display _newline
    display "Placebo timing coefficient: " %9.6f placebo_timing_coef
    display "Placebo timing std. error:  " %9.6f placebo_timing_se
    display "Placebo timing t-statistic: " %9.4f placebo_timing_t
    display "Placebo timing p-value:     " %9.4f placebo_timing_p

    * Assess: under the null, placebo should be insignificant
    if placebo_timing_p > 0.10 {
        display _newline "RESULT: Placebo timing effect is NOT significant (p = " ///
            %5.3f placebo_timing_p "). Consistent with null expectation."
    }
    else {
        display _newline "WARNING: Placebo timing effect IS significant (p = " ///
            %5.3f placebo_timing_p "). Investigate further."
    }

    estimates store placebo_timing
}

restore

* ============================================================================ *
* 4. Placebo output table
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 4: Output table"
display "============================================"

cap noisily {
    esttab baseline placebo_timing using ///
        "v1/output/tables/tab_placebo_timing.tex", ///
        replace ///
        label ///
        title("Baseline vs. Placebo Timing Test") ///
        mtitles("Baseline" "Placebo (5yr early)") ///
        keep(dem placebo_treat L.y L2.y L3.y L4.y) ///
        order(dem placebo_treat L.y L2.y L3.y L4.y) ///
        cells(b(star fmt(4)) se(par fmt(4))) ///
        starlevels(* 0.10 ** 0.05 *** 0.01) ///
        stats(N N_g r2_w, ///
            labels("Observations" "Countries" "Within R-squared") ///
            fmt(0 0 4)) ///
        note("Fixed effects regression with clustered standard errors." ///
             "Placebo assigns treatment 5 years before actual democratization," ///
             " restricted to pre-treatment sample.") ///
        booktabs

    display "Table written to v1/output/tables/tab_placebo_timing.tex"
}

* ============================================================================ *
* 5. Permutation inference
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 5: Permutation inference (200 reps)"
display "============================================"
display "Shuffling dem across countries within each year."

* Define program for simulate.
* Strategy: within each year, randomly permute which country gets which
* dem value. We do this via a tempfile-based merge:
*   1. Sort data by (year, wbcode2) and record a canonical within-year rank.
*   2. Sort data by (year, random) and record a shuffled within-year rank.
*   3. Save (year, shuffled_rank, dem_orig) to a tempfile, renaming
*      shuffled_rank -> canonical_rank so the merge reassigns dem values
*      from one country to another within the same year.
*   4. Merge back on (year, canonical_rank) to get the shuffled dem.
*   5. Re-sort by (wbcode2, year), re-set panel, run the regression.

cap program drop perm_dem
program define perm_dem, rclass

    preserve

    * --- Step 1: Canonical rank within year ---
    sort year wbcode2
    by year: gen long _canon_rank = _n

    * --- Step 2: Random rank within year ---
    gen double _rng = runiform()
    sort year _rng
    by year: gen long _shuffled_rank = _n

    * --- Step 3: Build mapping file ---
    * Each obs currently carries its own dem value and a shuffled rank.
    * Save (year, _shuffled_rank, dem) with _shuffled_rank relabeled
    * as _canon_rank. When merged back, each canonical-rank position
    * will receive the dem value from a randomly chosen country.
    tempfile shuf_map
    tempvar dem_save
    gen double `dem_save' = dem

    keep year _shuffled_rank `dem_save'
    rename _shuffled_rank _canon_rank
    rename `dem_save' dem_new
    sort year _canon_rank
    save `shuf_map'

    restore
    preserve

    * --- Step 4: Merge shuffled dem back ---
    sort year wbcode2
    by year: gen long _canon_rank = _n

    merge 1:1 year _canon_rank using `shuf_map', nogenerate

    * Replace dem with the shuffled version
    drop dem
    rename dem_new dem

    drop _canon_rank

    * --- Step 5: Re-sort, re-set panel, run regression ---
    sort wbcode2 year
    cap xtset wbcode2 year

    cap xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)

    if _rc == 0 {
        return scalar perm_coef = _b[dem]
    }
    else {
        return scalar perm_coef = .
    }

    restore
end

* Run the permutation simulation
display _newline
display "Running 200 permutation replications..."
display "This may take several minutes."

cap noisily {
    simulate perm_coef=r(perm_coef), reps(200) seed(12345) ///
        saving("v1/data/temp/permutation_results.dta", replace): perm_dem
}

* ============================================================================ *
* 6. Permutation p-value and histogram
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 6: Permutation results and histogram"
display "============================================"

cap noisily {
    * Load permutation results
    use "v1/data/temp/permutation_results.dta", clear

    * Summary of permutation distribution
    summarize perm_coef, detail

    * Count how many permutation coefficients exceed the baseline in magnitude
    * Two-sided permutation p-value
    gen byte exceed = (abs(perm_coef) >= abs(baseline_dem_coef)) if perm_coef != .
    summarize exceed, meanonly
    scalar perm_pvalue = r(mean)

    display _newline
    display "Baseline democracy coefficient:    " %9.6f baseline_dem_coef
    display "Permutation p-value (two-sided):   " %9.4f perm_pvalue
    display "Number of valid replications:      " %9.0f r(N)

    if perm_pvalue < 0.05 {
        display _newline "Permutation p-value < 0.05: baseline effect is unlikely due to chance."
    }
    else {
        display _newline "Permutation p-value >= 0.05: cannot reject null that effect is due to chance."
    }

    * --- Histogram of permutation distribution ---
    local bcoef = baseline_dem_coef

    histogram perm_coef, ///
        bin(30) ///
        fraction ///
        color(navy%60) ///
        lcolor(navy) ///
        title("Permutation Distribution of Democracy Coefficient") ///
        subtitle("200 random permutations of treatment across countries within year") ///
        xtitle("Permuted Democracy Coefficient") ///
        ytitle("Fraction") ///
        xline(`bcoef', lcolor(red) lwidth(medthick) lpattern(dash)) ///
        note("Red dashed line = baseline estimate" ///
             "Permutation p-value = `=string(perm_pvalue, "%5.3f")'") ///
        scheme(s2color)

    graph export "v1/output/figures/fig_placebo_permutation.png", ///
        as(png) width(1200) height(800) replace

    display "Histogram saved to v1/output/figures/fig_placebo_permutation.png"
}

* ============================================================================ *
* 7. Cross-validation data for Python comparison
* ============================================================================ *
display _newline(2)
display "============================================"
display " Step 7: Cross-validation data for Python"
display "============================================"

cap noisily {
    * Reload permutation results
    use "v1/data/temp/permutation_results.dta", clear

    * Export permutation coefficients to CSV for Python
    export delimited using "v1/data/temp/permutation_coefs_stata.csv", replace
    display "Permutation coefficients exported to v1/data/temp/permutation_coefs_stata.csv"

    * Create a summary file with key scalars for Python cross-validation
    clear
    set obs 1

    gen double baseline_coef    = baseline_dem_coef
    gen double baseline_se      = baseline_dem_se
    gen double baseline_t       = baseline_dem_t
    gen double baseline_p       = baseline_dem_p
    gen double placebo_coef     = placebo_timing_coef
    gen double placebo_se       = placebo_timing_se
    gen double placebo_t        = placebo_timing_t
    gen double placebo_p        = placebo_timing_p
    gen double perm_pval        = perm_pvalue
    gen int    perm_reps        = 200
    gen int    seed_value       = 12345

    export delimited using "v1/data/temp/cross_validation_stata.csv", replace
    display "Cross-validation summary exported to v1/data/temp/cross_validation_stata.csv"

    * Also save as .dta for direct Stata reuse
    save "v1/data/temp/cross_validation_stata.dta", replace
    display "Cross-validation summary saved to v1/data/temp/cross_validation_stata.dta"

    * Print summary for log
    list, noobs clean
}

* ============================================================================ *
* Wrap up
* ============================================================================ *
display _newline(3)
display "====================================="
display " PLACEBO ANALYSIS COMPLETE"
display "====================================="
display _newline
display " Outputs:"
display "   Table:      v1/output/tables/tab_placebo_timing.tex"
display "   Figure:     v1/output/figures/fig_placebo_permutation.png"
display "   Log:        v1/output/logs/01_placebo_analysis.log"
display "   Perm data:  v1/data/temp/permutation_results.dta"
display "   Cross-val:  v1/data/temp/cross_validation_stata.csv"
display _newline
display "PLACEBO ANALYSIS COMPLETE"

log close
exit
