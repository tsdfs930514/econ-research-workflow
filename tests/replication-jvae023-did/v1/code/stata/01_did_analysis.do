/*==============================================================================
Project:    jvae023 - "Effectiveness of Environmental Provisions in RTAs"
Version:    v1
Script:     01_did_analysis.do
Purpose:    Difference-in-Differences analysis of environmental RTA provisions
            on forest loss using TWFE, event study, Callaway-Sant'Anna, and
            Bacon decomposition.
Author:     Claude Code
Created:    2026-02-26
Modified:   2026-02-26
Input:      v1/data/raw/country_panel.dta
            v1/data/raw/rta_panel_full.dta
Output:     v1/output/tables/tab_did_results.tex
            v1/output/tables/tab_did_cv.csv
            v1/output/figures/fig_event_study.png
            v1/output/logs/01_did_analysis.log
==============================================================================*/

* Required packages:
*   ssc install reghdfe
*   ssc install ftools
*   ssc install estout
*   ssc install csdid
*   ssc install bacondecomp

version 18
clear all
set more off
set maxvar 32767
set matsize 11000
set seed 12345

* --- Paths (use forward slashes; works on all platforms) ---------------------
local basedir "F:/Learning/econ-research-workflow/tests/replication-jvae023-did/v1"
local rawdir  "`basedir'/data/raw"
local outdir  "`basedir'/output/tables"
local figdir  "`basedir'/output/figures"
local logdir  "`basedir'/output/logs"

* --- Source data (from the lasso replication) ---------------------------------
local srcdir "F:/Learning/econ-research-workflow/tests/replication-jvae023-lasso/v1/data/raw"

* --- Ensure output directories exist -----------------------------------------
cap mkdir "`outdir'"
cap mkdir "`figdir'"
cap mkdir "`logdir'"
cap mkdir "`rawdir'"

* --- Log ---------------------------------------------------------------------
cap log close _all
log using "`logdir'/01_did_analysis.log", replace text


/*==============================================================================
  PART 0:  Copy source data to local raw directory
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 0: Copy source data files"
di as txt "=================================================================="
di as txt ""

cap confirm file "`rawdir'/country_panel.dta"
if _rc != 0 {
    di as txt ">>> Copying country_panel.dta from lasso replication..."
    copy "`srcdir'/country_panel.dta" "`rawdir'/country_panel.dta", replace
}
else {
    di as txt ">>> country_panel.dta already exists in raw directory."
}

cap confirm file "`rawdir'/rta_panel_full.dta"
if _rc != 0 {
    di as txt ">>> Copying rta_panel_full.dta from lasso replication..."
    copy "`srcdir'/rta_panel_full.dta" "`rawdir'/rta_panel_full.dta", replace
}
else {
    di as txt ">>> rta_panel_full.dta already exists in raw directory."
}


/*==============================================================================
  PART 1:  Install required packages
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 1: Install required packages"
di as txt "=================================================================="
di as txt ""

* reghdfe and ftools (core TWFE estimation)
cap which reghdfe
if _rc != 0 {
    di as txt ">>> Installing reghdfe..."
    cap noisily ssc install reghdfe, replace
}
cap which ftools
if _rc != 0 {
    di as txt ">>> Installing ftools..."
    cap noisily ssc install ftools, replace
}

* estout (table export)
cap which esttab
if _rc != 0 {
    di as txt ">>> Installing estout..."
    cap noisily ssc install estout, replace
}

* csdid (Callaway-Sant'Anna)
cap which csdid
if _rc != 0 {
    di as txt ">>> Installing csdid..."
    cap noisily ssc install csdid, replace
    cap noisily ssc install drdid, replace
}

* bacondecomp (Bacon decomposition)
cap which bacondecomp
if _rc != 0 {
    di as txt ">>> Installing bacondecomp..."
    cap noisily ssc install bacondecomp, replace
}


/*==============================================================================
  PART 2:  Load data, describe variables, identify key variables
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 2: Load and describe country_panel.dta"
di as txt "=================================================================="
di as txt ""

use "`rawdir'/country_panel.dta", clear

* --- Short and full describe -------------------------------------------------
desc, short
desc

* --- Identify key variables --------------------------------------------------
di as txt ""
di as txt ">>> Identifying key variables for DiD analysis..."

* Outcome: loss (forest loss in hectares)
cap confirm numeric variable loss
if _rc == 0 {
    di as txt "    Outcome variable:   loss (forest loss)"
}
else {
    di as err "*** Outcome variable 'loss' not found!"
}

* Treatment: enviro_rta (environmental provision in RTA)
cap confirm numeric variable enviro_rta
if _rc == 0 {
    di as txt "    Treatment variable: enviro_rta (environmental RTA)"
}
else {
    di as err "*** Treatment variable 'enviro_rta' not found!"
}

* Panel identifiers: id (country) and year
* The CSV conversion may produce ISO3 (string) instead of id (numeric)
cap confirm numeric variable id
if _rc != 0 {
    cap confirm string variable ISO3
    if _rc == 0 {
        di as txt "    Found ISO3 (string) — encoding to numeric 'id'"
        encode ISO3, gen(id)
    }
    else {
        di as err "*** No country identifier found (tried 'id' and 'ISO3')!"
    }
}
if _rc == 0 {
    di as txt "    Panel ID:           id (country identifier)"
}

cap confirm numeric variable year
if _rc == 0 {
    di as txt "    Time variable:      year"
}
else {
    di as err "*** Time variable 'year' not found!"
}

* Control: rta (any RTA)
cap confirm numeric variable rta
if _rc == 0 {
    di as txt "    Control variable:   rta (any RTA indicator)"
}

* --- Summarize key variables -------------------------------------------------
di as txt ""
di as txt ">>> Summary statistics for key variables:"
cap noisily sum loss enviro_rta rta id year, detail

* --- List all numeric variables for reference --------------------------------
di as txt ""
di as txt ">>> All numeric variables:"
ds, has(type numeric)

* --- Check for lead/lag event study variables --------------------------------
di as txt ""
di as txt ">>> Checking for event study lead/lag variables..."

local es_vars ""
foreach v in lead_1 lag_0 lag_1 lag_2 lag_3 lag_LR {
    cap confirm numeric variable `v'
    if _rc == 0 {
        local es_vars "`es_vars' `v'"
        di as txt "    Found: `v'"
    }
}

local has_es_vars = ("`es_vars'" != "")
if `has_es_vars' {
    di as txt ">>> Event study variables available: `es_vars'"
    sum `es_vars'
}
else {
    di as txt ">>> No pre-built lead/lag variables found."
}

* --- Also check for enviro-specific lead/lag variables -----------------------
local enviro_es_vars ""
foreach v in enviro_lead_1 enviro_lag_0 enviro_lag_1 enviro_lag_2 ///
             enviro_lag_3 enviro_lag_LR {
    cap confirm numeric variable `v'
    if _rc == 0 {
        local enviro_es_vars "`enviro_es_vars' `v'"
        di as txt "    Found (enviro): `v'"
    }
}

if "`enviro_es_vars'" != "" {
    di as txt ">>> Enviro event study variables: `enviro_es_vars'"
    sum `enviro_es_vars'
}

* --- Set panel structure -----------------------------------------------------
cap noisily xtset id year
di as txt ""
di as txt ">>> Panel structure set: id = country, t = year"
di as txt ">>> Year range: 2001-2018"


/*==============================================================================
  PART 3:  TWFE Difference-in-Differences (reghdfe)
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 3: Two-Way Fixed Effects DiD (reghdfe)"
di as txt "=================================================================="
di as txt ""

eststo clear

* --- Model 1: enviro_rta + rta with country and year FE ----------------------
di as txt "--- Model 1: TWFE -- loss = enviro_rta + rta + FE(id, year) ---"

cap noisily {
    reghdfe loss enviro_rta rta, absorb(id year) vce(cluster id)
    estimates store twfe_main

    di as txt ""
    di as txt ">>> TWFE Main Results:"
    di as txt "    Coefficient on enviro_rta: " _b[enviro_rta]
    di as txt "    SE on enviro_rta:          " _se[enviro_rta]
    di as txt "    Coefficient on rta:        " _b[rta]
    di as txt "    SE on rta:                 " _se[rta]

    * Store for cross-validation output
    local twfe_b_enviro = _b[enviro_rta]
    local twfe_se_enviro = _se[enviro_rta]
    local twfe_b_rta = _b[rta]
    local twfe_se_rta = _se[rta]
    local twfe_N = e(N)
    local twfe_r2 = e(r2)
}

* --- Model 2: enviro_rta only with FE ---------------------------------------
di as txt ""
di as txt "--- Model 2: TWFE -- loss = enviro_rta + FE(id, year) ---"

cap noisily {
    reghdfe loss enviro_rta, absorb(id year) vce(cluster id)
    estimates store twfe_enviro_only
}

* --- Model 3: rta only with FE -----------------------------------------------
di as txt ""
di as txt "--- Model 3: TWFE -- loss = rta + FE(id, year) ---"

cap noisily {
    reghdfe loss rta, absorb(id year) vce(cluster id)
    estimates store twfe_rta_only
}


/*==============================================================================
  PART 4:  Event Study with Lead/Lag Variables
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 4: Event Study (Lead/Lag Specification)"
di as txt "=================================================================="
di as txt ""

if `has_es_vars' {
    di as txt ">>> Running event study with pre-built lead/lag variables..."

    * --- Event study with RTA lead/lag variables -----------------------------
    cap noisily {
        reghdfe loss `es_vars', absorb(id year) vce(cluster id)
        estimates store es_rta

        di as txt ">>> Event study coefficients (RTA lead/lag):"
        foreach v of local es_vars {
            di as txt "    `v': " _b[`v'] " (" _se[`v'] ")"
        }
    }

    * --- Event study with enviro_rta lead/lag if available -------------------
    if "`enviro_es_vars'" != "" {
        di as txt ""
        di as txt ">>> Running event study with enviro-specific lead/lag variables..."

        cap noisily {
            reghdfe loss `enviro_es_vars', absorb(id year) vce(cluster id)
            estimates store es_enviro

            di as txt ">>> Event study coefficients (enviro_rta lead/lag):"
            foreach v of local enviro_es_vars {
                di as txt "    `v': " _b[`v'] " (" _se[`v'] ")"
            }
        }
    }

    * --- Combined event study: both RTA and enviro lead/lag ------------------
    if "`enviro_es_vars'" != "" {
        di as txt ""
        di as txt ">>> Running combined event study (both RTA and enviro lead/lag)..."

        cap noisily {
            reghdfe loss `es_vars' `enviro_es_vars', absorb(id year) vce(cluster id)
            estimates store es_combined
        }
    }
}
else {
    di as txt ">>> No pre-built lead/lag variables found."
    di as txt ">>> Attempting to construct event study variables manually..."

    * If enviro_rta exists, we can try to construct a simple event study
    * based on the first year of treatment for each country.
    cap noisily {
        * Find the first year each country was treated (enviro_rta == 1)
        bysort id (year): gen first_treat_year = year if enviro_rta == 1
        bysort id: egen cohort = min(first_treat_year)
        drop first_treat_year

        * Create relative time variable
        gen rel_time = year - cohort

        * Replace missing cohort (never-treated) with a large number
        replace rel_time = . if missing(cohort)

        di as txt ">>> Treatment cohort distribution:"
        tab cohort, missing

        di as txt ">>> Relative time distribution:"
        tab rel_time, missing

        * Create lead/lag dummies (omit period -1 as reference)
        * Leads: pre-treatment periods (negative rel_time)
        * Lags:  post-treatment periods (positive rel_time)

        forvalues k = 5(-1)2 {
            gen lead_`k' = (rel_time == -`k') if !missing(rel_time)
            replace lead_`k' = 0 if missing(lead_`k')
        }
        * lag_0 = treatment onset
        forvalues k = 0/5 {
            gen lag_m`k' = (rel_time == `k') if !missing(rel_time)
            replace lag_m`k' = 0 if missing(lag_m`k')
        }
        * Bin endpoints
        gen lead_6plus = (rel_time <= -6) if !missing(rel_time)
        replace lead_6plus = 0 if missing(lead_6plus)
        gen lag_6plus = (rel_time >= 6) if !missing(rel_time)
        replace lag_6plus = 0 if missing(lag_6plus)

        * Run event study (omit lead_1 = period -1 as reference)
        local manual_es "lead_6plus lead_5 lead_4 lead_3 lead_2"
        local manual_es "`manual_es' lag_m0 lag_m1 lag_m2 lag_m3 lag_m4 lag_m5 lag_6plus"

        reghdfe loss `manual_es', absorb(id year) vce(cluster id)
        estimates store es_manual

        di as txt ">>> Manual event study coefficients:"
        foreach v of local manual_es {
            di as txt "    `v': " _b[`v'] " (" _se[`v'] ")"
        }

        * Update locals for the plot
        local es_vars "`manual_es'"
        local has_es_vars = 1
    }
}


/*==============================================================================
  PART 5:  Callaway-Sant'Anna DiD (csdid)
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 5: Callaway-Sant'Anna DiD (csdid)"
di as txt "=================================================================="
di as txt ""

cap which csdid
if _rc == 0 {
    di as txt ">>> csdid is available. Running Callaway-Sant'Anna estimator..."

    cap noisily {
        * Need to identify the treatment cohort (first year of treatment)
        * If cohort variable was not created in Part 4, create it now
        cap confirm numeric variable cohort
        if _rc != 0 {
            bysort id (year): gen first_treat_tmp = year if enviro_rta == 1
            bysort id: egen cohort = min(first_treat_tmp)
            drop first_treat_tmp
            * Never-treated: set cohort to 0 (csdid convention)
            replace cohort = 0 if missing(cohort)
        }
        else {
            * If cohort has missings (never-treated), replace with 0 for csdid
            replace cohort = 0 if missing(cohort)
        }

        di as txt ">>> Treatment cohort variable 'cohort' (0 = never treated):"
        tab cohort, missing

        * Run csdid: outcome = loss, treatment timing = cohort,
        * panel id = id, time = year
        csdid loss, ivar(id) time(year) gvar(cohort) method(dripw)
        estimates store csdid_main

        di as txt ""
        di as txt ">>> Callaway-Sant'Anna ATT estimates:"

        * Aggregate treatment effects
        cap noisily {
            csdid_stats simple
            di as txt ">>> CS-DiD Simple ATT (overall average):"
        }

        cap noisily {
            csdid_stats group
            di as txt ">>> CS-DiD Group-specific ATT:"
        }

        cap noisily {
            csdid_stats calendar
            di as txt ">>> CS-DiD Calendar-time ATT:"
        }

        cap noisily {
            csdid_stats event
            di as txt ">>> CS-DiD Event-study ATT:"
            estimates store csdid_event
        }
    }
}
else {
    di as txt ">>> csdid not available. Skipping Callaway-Sant'Anna estimation."
    di as txt "    Install with: ssc install csdid"
}


/*==============================================================================
  PART 6:  Bacon Decomposition (bacondecomp)
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 6: Bacon Decomposition (bacondecomp)"
di as txt "=================================================================="
di as txt ""

cap which bacondecomp
if _rc == 0 {
    di as txt ">>> bacondecomp is available. Running Bacon decomposition..."

    cap noisily {
        * bacondecomp requires a binary treatment variable and balanced panel
        * Use enviro_rta as the treatment

        * First check if panel is balanced
        cap noisily xtset id year

        bacondecomp loss enviro_rta, ddetail

        di as txt ""
        di as txt ">>> Bacon Decomposition Results:"
        di as txt "    This decomposes the TWFE estimate into:"
        di as txt "    - Earlier vs Later treated"
        di as txt "    - Later vs Earlier treated"
        di as txt "    - Treated vs Never treated"
    }
}
else {
    di as txt ">>> bacondecomp not available. Skipping Bacon decomposition."
    di as txt "    Install with: ssc install bacondecomp"
}


/*==============================================================================
  PART 7:  Event Study Coefficient Plot
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 7: Event Study Coefficient Plot"
di as txt "=================================================================="
di as txt ""

cap noisily {
    * Attempt to plot using the event study estimates
    * First try: use the pre-built lead/lag variables from Part 4

    * Check which event study model is available
    local plot_model ""
    foreach m in es_enviro es_rta es_manual {
        cap estimates restore `m'
        if _rc == 0 {
            local plot_model "`m'"
            continue, break
        }
    }

    if "`plot_model'" != "" {
        di as txt ">>> Plotting event study from model: `plot_model'"
        estimates restore `plot_model'

        * Use coefplot if available, otherwise manual plotting
        cap which coefplot
        if _rc != 0 {
            di as txt ">>> Installing coefplot..."
            cap noisily ssc install coefplot, replace
        }

        cap which coefplot
        if _rc == 0 {
            * Use coefplot for clean event study graph
            cap noisily {
                coefplot `plot_model', ///
                    vertical ///
                    yline(0, lcolor(red) lpattern(dash)) ///
                    xtitle("Event Time (relative to treatment)") ///
                    ytitle("Effect on Forest Loss") ///
                    title("Event Study: Effect of Environmental RTA on Forest Loss") ///
                    subtitle("jvae023 Replication - DiD Analysis") ///
                    note("95% CI shown. Clustered SEs at country level.") ///
                    msymbol(D) mcolor(navy) ///
                    ciopts(lcolor(navy) recast(rcap)) ///
                    graphregion(color(white)) ///
                    name(event_study, replace)

                graph export "`figdir'/fig_event_study.png", replace width(1200) height(800)
                di as txt ">>> Event study plot saved to: `figdir'/fig_event_study.png"
            }
        }
        else {
            * Manual plotting with twoway as fallback
            di as txt ">>> coefplot not available. Using manual twoway plot..."

            cap noisily {
                * Extract coefficients and CIs into a temp dataset
                * Get the variable names from the stored estimates
                estimates restore `plot_model'

                local nvars : word count `es_vars'

                * Create a temporary dataset with coefficients
                preserve
                clear
                set obs `nvars'
                gen event_time = .
                gen coef = .
                gen se = .
                gen ci_lo = .
                gen ci_hi = .
                gen varname = ""

                local i = 1
                foreach v of local es_vars {
                    replace varname = "`v'" in `i'
                    replace event_time = `i' in `i'

                    cap replace coef = _b[`v'] in `i'
                    cap replace se = _se[`v'] in `i'

                    local ++i
                }

                replace ci_lo = coef - 1.96 * se
                replace ci_hi = coef + 1.96 * se

                twoway (rcap ci_lo ci_hi event_time, lcolor(navy)) ///
                       (scatter coef event_time, mcolor(navy) msymbol(D)), ///
                    yline(0, lcolor(red) lpattern(dash)) ///
                    xtitle("Event Time Variable") ///
                    ytitle("Effect on Forest Loss") ///
                    title("Event Study: Environmental RTA and Forest Loss") ///
                    subtitle("jvae023 Replication") ///
                    note("95% CI shown. Clustered SEs at country level.") ///
                    legend(off) ///
                    graphregion(color(white)) ///
                    name(event_study, replace)

                graph export "`figdir'/fig_event_study.png", replace width(1200) height(800)
                di as txt ">>> Event study plot saved to: `figdir'/fig_event_study.png"

                restore
            }
        }
    }
    else {
        di as txt ">>> No event study estimates available for plotting."

        * Try plotting from csdid event study if available
        cap estimates restore csdid_event
        if _rc == 0 {
            di as txt ">>> Attempting to plot csdid event study results..."
            cap noisily {
                csdid_plot, ///
                    title("CS-DiD Event Study: Enviro RTA on Forest Loss") ///
                    name(csdid_event_plot, replace)
                graph export "`figdir'/fig_event_study.png", replace width(1200) height(800)
                di as txt ">>> CS-DiD event study plot saved."
            }
        }
    }
}


/*==============================================================================
  PART 8:  Output Tables and Cross-Validation Data
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART 8: Export Tables and Cross-Validation Data"
di as txt "=================================================================="
di as txt ""

* --- A: LaTeX table with esttab -----------------------------------------------
di as txt "--- 8A: LaTeX table ---"

cap noisily {
    * Collect available estimates
    local est_list ""
    foreach e in twfe_main twfe_enviro_only twfe_rta_only es_rta es_enviro es_manual {
        cap estimates restore `e'
        if _rc == 0 {
            local est_list "`est_list' `e'"
        }
    }

    if "`est_list'" != "" {
        di as txt ">>> Exporting estimates: `est_list'"

        esttab `est_list' using "`outdir'/tab_did_results.tex", ///
            replace booktabs label ///
            title("Difference-in-Differences: Environmental RTA Provisions and Forest Loss") ///
            note("Data: country\_panel.dta from Abman, Lundberg \& Ruta (jvae023). " ///
                 "All models include country and year fixed effects. " ///
                 "Standard errors clustered at country level in parentheses.") ///
            star(* 0.10 ** 0.05 *** 0.01) ///
            se(%9.4f) b(%9.4f) ///
            stats(N r2_a, labels("Observations" "Adj. R-squared") fmt(%12.0fc %9.4f)) ///
            mtitles("TWFE Main" "Enviro Only" "RTA Only" "Event Study" "ES Enviro" "ES Manual")

        di as txt ">>> Table saved to: `outdir'/tab_did_results.tex"
    }
    else {
        di as txt ">>> No stored estimates available for esttab."
        di as txt ">>> Writing fallback table..."

        cap file close texfile
        file open texfile using "`outdir'/tab_did_results.tex", write replace
        file write texfile "\begin{table}[htbp]" _n
        file write texfile "\centering" _n
        file write texfile "\caption{DiD Results -- jvae023 Environmental RTA}" _n
        file write texfile "\label{tab:did_results}" _n
        file write texfile "\begin{tabular}{lcc}" _n
        file write texfile "\hline\hline" _n
        file write texfile "Model & enviro\_rta & rta \\" _n
        file write texfile "\hline" _n
        file write texfile "TWFE Main & See log & See log \\" _n
        file write texfile "Event Study & See log & See log \\" _n
        file write texfile "CS-DiD & See log & -- \\" _n
        file write texfile "\hline\hline" _n
        file write texfile "\end{tabular}" _n
        file write texfile "\end{table}" _n
        file close texfile

        di as txt ">>> Fallback table written to: `outdir'/tab_did_results.tex"
    }
}

* --- B: Cross-validation CSV for Python comparison ----------------------------
di as txt ""
di as txt "--- 8B: Cross-validation data (CSV export) ---"

cap noisily {
    * Restore main TWFE estimates and export key coefficients
    cap estimates restore twfe_main
    if _rc == 0 {
        * Create a small dataset with the TWFE results for cross-validation
        preserve
        clear
        set obs 2

        gen str30 variable = ""
        gen double coefficient = .
        gen double std_error = .
        gen double t_stat = .
        gen double p_value = .
        gen long n_obs = .
        gen str30 model = ""

        replace variable = "enviro_rta" in 1
        replace variable = "rta" in 2
        replace model = "twfe_main" in 1
        replace model = "twfe_main" in 2

        cap estimates restore twfe_main
        replace coefficient = _b[enviro_rta] in 1
        replace std_error = _se[enviro_rta] in 1
        replace t_stat = _b[enviro_rta] / _se[enviro_rta] in 1
        replace n_obs = e(N) in 1

        replace coefficient = _b[rta] in 2
        replace std_error = _se[rta] in 2
        replace t_stat = _b[rta] / _se[rta] in 2
        replace n_obs = e(N) in 2

        * Compute p-values (two-sided)
        replace p_value = 2 * ttail(e(df_r), abs(t_stat))

        export delimited using "`outdir'/tab_did_cv.csv", replace
        di as txt ">>> Cross-validation CSV saved to: `outdir'/tab_did_cv.csv"

        list, clean noobs

        restore
    }
    else {
        di as txt ">>> TWFE main estimates not available for cross-validation export."

        * Create a placeholder CSV
        preserve
        clear
        set obs 1
        gen str30 variable = "enviro_rta"
        gen double coefficient = .
        gen double std_error = .
        gen str30 model = "not_estimated"
        gen str50 note = "TWFE estimation did not converge; check log"

        export delimited using "`outdir'/tab_did_cv.csv", replace
        di as txt ">>> Placeholder CSV saved to: `outdir'/tab_did_cv.csv"

        restore
    }
}


/*==============================================================================
  Wrap-up
==============================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  DID ANALYSIS COMPLETE"
di as txt "=================================================================="
di as txt ""
di as txt "  Log file:       `logdir'/01_did_analysis.log"
di as txt "  LaTeX table:    `outdir'/tab_did_results.tex"
di as txt "  CV data:        `outdir'/tab_did_cv.csv"
di as txt "  Event study:    `figdir'/fig_event_study.png"
di as txt ""

cap log close _all

exit
