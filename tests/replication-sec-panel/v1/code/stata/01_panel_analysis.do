********************************************************************************
* 01_panel_analysis.do
*
* Replication of Table 4 Panel B -- SEC Comment Letters & Insider Trading
* Data: xsec9b_final_rep.dta
*
* This script:
*   1. Loads and explores the SEC comment-letter panel data
*   2. Estimates the main specification (areg with firm-cluster SEs)
*   3. Cross-checks with reghdfe (coefficients should match)
*   4. Estimates a second specification with an alternative DV
*   5. Exports a formatted LaTeX table
********************************************************************************

* ---------------------------------------------------------------------------- *
* Housekeeping
* ---------------------------------------------------------------------------- *
cap log close
log using "v1/output/logs/01_panel_analysis.log", replace

set more off
clear all

* ---------------------------------------------------------------------------- *
* Install required packages (skip if already installed)
* ---------------------------------------------------------------------------- *
cap which reghdfe
if _rc != 0 {
    ssc install reghdfe, replace
}

cap which ftools
if _rc != 0 {
    ssc install ftools, replace
}

cap which estout
if _rc != 0 {
    ssc install estout, replace
}

* After installing reghdfe, make sure ftools is registered
cap reghdfe, compile

* ---------------------------------------------------------------------------- *
* 1. Load data
* ---------------------------------------------------------------------------- *
use "v1/data/raw/xsec9b_final_rep.dta", clear

di as txt _n "=========================================="
di as txt "  SEC Comment Letters Panel Data Loaded"
di as txt "==========================================" _n

* ---------------------------------------------------------------------------- *
* 2. Explore: describe and summarize key variables
* ---------------------------------------------------------------------------- *
di as txt _n "--- Variable descriptions ---"
desc ex_net_volbuyp0p5 ncc_conv_median ff_12 gvkey fyear

di as txt _n "--- Summary statistics for key variables ---"
summarize ex_net_volbuyp0p5 ncc_conv_median ff_12 gvkey fyear, detail

* Quick missingness check on the main estimation sample variables
di as txt _n "--- Observations with non-missing values for key regressors ---"
count if !missing(ex_net_volbuyp0p5, ncc_conv_median, ff_12, gvkey, fyear)

* ---------------------------------------------------------------------------- *
* 3. Create year fixed-effect dummies
* ---------------------------------------------------------------------------- *
tab fyear, gen(fyear_fe)

di as txt _n "--- Year FE dummies created ---"
desc fyear_fe*

* ---------------------------------------------------------------------------- *
* 4. Main regression -- areg (Table 4 Panel B, Column 1 analog)
*    DV: ex_net_volbuyp0p5
*    Absorb: ff_12 (Fama-French 12 industry)
*    Cluster: gvkey (firm)
*    Year FE entered manually via dummies (fyear_fe2 - fyear_fe8)
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  AREG: Main specification"
di as txt "==========================================" _n

areg ex_net_volbuyp0p5 ///
    ncc_conv_median    ///
    inst_pct_dedm      ///
    connect0m          ///
    restate1           ///
    i819               ///
    i924               ///
    logsize            ///
    mtb                ///
    loganalysts        ///
    inst_perc_all_w    ///
    fyear_fe2-fyear_fe8, ///
    absorb(ff_12) cluster(gvkey)

estimates store areg_main

* ---------------------------------------------------------------------------- *
* 5. Cross-check with reghdfe (coefficients should match areg)
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  REGHDFE: Same specification for comparison"
di as txt "==========================================" _n

reghdfe ex_net_volbuyp0p5 ///
    ncc_conv_median       ///
    inst_pct_dedm         ///
    connect0m             ///
    restate1              ///
    i819                  ///
    i924                  ///
    logsize               ///
    mtb                   ///
    loganalysts           ///
    inst_perc_all_w       ///
    i.fyear,              ///
    absorb(ff_12) vce(cluster gvkey)

estimates store reghdfe_main

* ---------------------------------------------------------------------------- *
* 6. Compare areg vs reghdfe coefficients
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  COMPARISON: areg vs reghdfe"
di as txt "==========================================" _n

estimates table areg_main reghdfe_main, ///
    keep(ncc_conv_median inst_pct_dedm connect0m restate1 ///
         i819 i924 logsize mtb loganalysts inst_perc_all_w) ///
    b(%9.6f) se(%9.6f) stats(N r2_a)

* Formal coefficient comparison on ncc_conv_median
local b_areg    = _b[ncc_conv_median]   // from last estimates restore
estimates restore areg_main
local b_areg    = _b[ncc_conv_median]
estimates restore reghdfe_main
local b_reghdfe = _b[ncc_conv_median]
local diff      = abs(`b_areg' - `b_reghdfe')

di as txt _n "ncc_conv_median coefficient (areg)   : " %12.8f `b_areg'
di as txt    "ncc_conv_median coefficient (reghdfe): " %12.8f `b_reghdfe'
di as txt    "Absolute difference                  : " %12.8f `diff'

if `diff' < 1e-6 {
    di as res _n "PASS: areg and reghdfe coefficients match (diff < 1e-6)."
}
else {
    di as err _n "NOTE: areg and reghdfe coefficients differ by " %12.8f `diff' "."
    di as err    "      Small differences may arise from convergence tolerance."
}

* ---------------------------------------------------------------------------- *
* 7. Second specification -- alternative dependent variable
*    DV: ex_net_volbuyp0p15
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  AREG: Second specification (DV = ex_net_volbuyp0p15)"
di as txt "==========================================" _n

areg ex_net_volbuyp0p15 ///
    ncc_conv_median     ///
    inst_pct_dedm       ///
    connect0m           ///
    restate1            ///
    i819                ///
    i924                ///
    logsize             ///
    mtb                 ///
    loganalysts         ///
    inst_perc_all_w     ///
    fyear_fe2-fyear_fe8, ///
    absorb(ff_12) cluster(gvkey)

estimates store areg_alt

* ---------------------------------------------------------------------------- *
* 8. Cross-validation: print ncc_conv_median coefficient and SE
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  CROSS-VALIDATION: Key coefficient"
di as txt "==========================================" _n

* From the main specification (areg)
estimates restore areg_main
local b_main  = _b[ncc_conv_median]
local se_main = _se[ncc_conv_median]
local t_main  = `b_main' / `se_main'
local p_main  = 2 * ttail(e(df_r), abs(`t_main'))

di as txt "Main spec (DV = ex_net_volbuyp0p5):"
di as txt "  ncc_conv_median  coef = " %10.6f `b_main'
di as txt "  ncc_conv_median  SE   = " %10.6f `se_main'
di as txt "  ncc_conv_median  t    = " %10.4f `t_main'
di as txt "  ncc_conv_median  p    = " %10.4f `p_main'

* From the alternative specification
estimates restore areg_alt
local b_alt  = _b[ncc_conv_median]
local se_alt = _se[ncc_conv_median]
local t_alt  = `b_alt' / `se_alt'
local p_alt  = 2 * ttail(e(df_r), abs(`t_alt'))

di as txt _n "Alt spec  (DV = ex_net_volbuyp0p15):"
di as txt "  ncc_conv_median  coef = " %10.6f `b_alt'
di as txt "  ncc_conv_median  SE   = " %10.6f `se_alt'
di as txt "  ncc_conv_median  t    = " %10.4f `t_alt'
di as txt "  ncc_conv_median  p    = " %10.4f `p_alt'

* ---------------------------------------------------------------------------- *
* 9. Output table to LaTeX
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as txt "  Exporting LaTeX table"
di as txt "==========================================" _n

esttab areg_main areg_alt using "v1/output/tables/tab_sec_panel.tex", ///
    replace                                                           ///
    label                                                             ///
    b(%9.4f) se(%9.4f)                                                ///
    star(* 0.10 ** 0.05 *** 0.01)                                    ///
    keep(ncc_conv_median inst_pct_dedm connect0m restate1             ///
         i819 i924 logsize mtb loganalysts inst_perc_all_w)           ///
    order(ncc_conv_median inst_pct_dedm connect0m restate1            ///
          i819 i924 logsize mtb loganalysts inst_perc_all_w)          ///
    stats(N r2_a, labels("Observations" "Adjusted R-squared")        ///
          fmt(%9.0fc %9.4f))                                          ///
    title("Table 4 Panel B -- SEC Comment Letters and Insider Trading") ///
    mtitles("ex_net_volbuyp0p5" "ex_net_volbuyp0p15")                ///
    note("Industry (FF-12) fixed effects absorbed. Standard errors clustered by firm (gvkey).") ///
    booktabs

di as txt _n "Table saved to: v1/output/tables/tab_sec_panel.tex"

* ---------------------------------------------------------------------------- *
* Done
* ---------------------------------------------------------------------------- *
di as txt _n "=========================================="
di as res    "  SEC PANEL ANALYSIS COMPLETE"
di as txt    "==========================================" _n

log close
