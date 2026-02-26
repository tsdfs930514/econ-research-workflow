/*==============================================================================
  REPLICATION TEST: Culture & Development — /run-bootstrap
  Data:    EAShort.dta (Ethnographic Atlas)
  Target:  Table 3 — Bootstrap regressions (bs, reps(500))
  Vars:    Y=kinship_score, X=s_malariaindex, Cluster=cluster
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "v1/output/logs/01_bootstrap_analysis.log", replace

* --- Install packages ---
foreach pkg in reghdfe ftools estout boottest parmest coefplot {
    cap which `pkg'
    if _rc != 0 cap ssc install `pkg', replace
}

* --- Load data ---
use "v1/data/raw/EAShort.dta", clear

* --- Data exploration ---
di "============================================="
di "STEP 0: DATA DESCRIPTION"
di "============================================="
desc kinship_score s_malariaindex small_scale cluster malaria_sample
sum kinship_score s_malariaindex small_scale, detail
tab malaria_sample, missing

* Define globals (following Generate_results.do)
global controls_history "ln_time_obs_ea"

* --- Step 1: Pairs Cluster Bootstrap (compact bs syntax) ---
di "============================================="
di "STEP 1: COMPACT BOOTSTRAP (bs prefix)"
di "============================================="

eststo clear

* Spec 1: OLS without bootstrap (baseline)
eststo ols_base: reg kinship_score s_malariaindex, cluster(cluster)
local b_ols = _b[s_malariaindex]
local se_ols = _se[s_malariaindex]
di "OLS (no bootstrap): b = `b_ols' (SE = `se_ols')"

* Spec 2: Compact bootstrap (Table 3 Column 4 pattern)
eststo bs_simple: bs, reps(500) seed(12345): reg kinship_score s_malariaindex if malaria_sample==1, cluster(cluster)
local b_bs = _b[s_malariaindex]
local se_bs = _se[s_malariaindex]
di "Bootstrap (500 reps): b = `b_bs' (SE = `se_bs')"

* Bootstrap CI methods (bca requires saving bca CIs during bootstrap — omit if not saved)
cap noisily estat bootstrap, percentile bc
if _rc != 0 {
    di "NOTE: estat bootstrap CI failed — may need explicit bca save option"
}

* Spec 3: With controls (Table 3 Column 5 pattern)
eststo bs_controls: bs, reps(500) seed(12345): reg kinship_score s_malariaindex small_scale $controls_history if malaria_sample==1, cluster(cluster)
di "Bootstrap + controls: b = " _b[s_malariaindex] " (SE = " _se[s_malariaindex] ")"

* Spec 4: Alternative malaria measure (s_distance_mutation)
eststo bs_mutation: bs, reps(500) seed(12345): reg kinship_score s_distance_mutation if malaria_sample==1, cluster(cluster)
di "Bootstrap (mutation): b = " _b[s_distance_mutation] " (SE = " _se[s_distance_mutation] ")"

* Spec 5: TSI measure
eststo bs_tsi: bs, reps(500) seed(12345): reg kinship_score s_tsi if malaria_sample==1, cluster(cluster)
di "Bootstrap (TSI): b = " _b[s_tsi] " (SE = " _se[s_tsi] ")"

* --- Step 2: Full bootstrap command (panel-style) ---
di "============================================="
di "STEP 2: FULL BOOTSTRAP COMMAND"
di "============================================="

* Full bootstrap with saving for distribution analysis
bootstrap _b, reps(500) seed(12345) cluster(cluster) ///
    saving("v1/data/temp/bs_distribution.dta", replace): ///
    reg kinship_score s_malariaindex if malaria_sample==1, cluster(cluster)
eststo bs_full

* Compare compact vs full bootstrap SEs
di "Compact bs SE:  `se_bs'"
di "Full bootstrap SE: " _se[s_malariaindex]

* --- Step 3: Wild Cluster Bootstrap ---
di "============================================="
di "STEP 3: WILD CLUSTER BOOTSTRAP"
di "============================================="

* Re-estimate for boottest
qui reg kinship_score s_malariaindex if malaria_sample==1, cluster(cluster)

* Wild cluster bootstrap (Rademacher weights)
cap noisily boottest s_malariaindex, cluster(cluster) boottype(rademacher) reps(999) seed(12345)
if _rc != 0 {
    di "NOTE: boottest failed — may need reghdfe version or different syntax"
}

* Wild cluster bootstrap (Webb weights — better for few clusters)
cap noisily boottest s_malariaindex, cluster(cluster) boottype(webb) reps(999) seed(12345)

* --- Step 4: Bootstrap Distribution Analysis ---
di "============================================="
di "STEP 4: DISTRIBUTION ANALYSIS"
di "============================================="

* Load bootstrap replications
preserve
use "v1/data/temp/bs_distribution.dta", clear
desc
* Variable names depend on estimation command — try common patterns
cap rename _bs_1 b_malariaindex
if _rc != 0 {
    cap rename s_malariaindex b_malariaindex
}
if _rc != 0 {
    * List all variables and use whatever exists
    ds
    local firstvar : word 1 of `r(varlist)'
    rename `firstvar' b_malariaindex
}
sum b_malariaindex, detail
di "Bootstrap distribution: mean = " r(mean) ", SD = " r(sd) ", skewness = " r(skewness)

* Histogram
hist b_malariaindex, bin(50) ///
    title("Bootstrap Distribution: Malaria → Kinship") ///
    xtitle("Bootstrap Coefficient") ytitle("Density") ///
    xline(`b_bs', lcolor(cranberry) lpattern(dash))
graph export "v1/output/figures/fig_bootstrap_dist.pdf", replace
restore

* --- Step 5: Cross-Validation Data ---
di "============================================="
di "STEP 5: CROSS-VALIDATION DATA"
di "============================================="

* Re-run analytical OLS for Python comparison
qui reg kinship_score s_malariaindex if malaria_sample==1, cluster(cluster)
di "=== CROSS-VALIDATION DATA ==="
di "OLS_malaria_coef = " _b[s_malariaindex]
di "OLS_malaria_se = " _se[s_malariaindex]
di "OLS_N = " e(N)

* --- Step 6: Output Tables ---
di "============================================="
di "STEP 6: OUTPUT TABLES"
di "============================================="

esttab ols_base bs_simple bs_controls bs_mutation bs_tsi ///
    using "v1/output/tables/tab_bootstrap_main.tex", ///
    se(3) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs replace ///
    mtitles("OLS" "BS(malaria)" "BS+ctrl" "BS(mutation)" "BS(TSI)") ///
    title("Kinship Score Determinants: Bootstrap Inference (Table 3 Replication)") ///
    note("Bootstrap standard errors with 500 replications." ///
         "Cluster-level resampling. Sample restricted to malaria_sample==1.")

di "============================================="
di "BOOTSTRAP ANALYSIS COMPLETE"
di "============================================="

log close
