/*===========================================================================
  01_lasso_analysis.do
  ===========================================================================
  jvae023 - "Effectiveness of Environmental Provisions in RTAs"
  Abman, Lundberg & Ruta

  Purpose:  LASSO variable selection on the country_panel data, plus
            post-LASSO OLS and (if available) post-double-selection.
            Also loads rta_panel_full for a richer covariate set.

  Requirements:
    - Stata 18+ (built-in lasso command)
    - Data files already converted to .dta via 01_convert_csv.py

  Outputs:
    - v1/output/tables/tab_lasso_results.tex
    - v1/output/logs/01_lasso_analysis.log
  ===========================================================================*/

clear all
set more off
set seed 12345
set matsize 5000

* --- Paths (use forward slashes; works on all platforms) -------------------
local basedir "F:/Learning/econ-research-workflow/tests/replication-jvae023-lasso/v1"
local rawdir  "`basedir'/data/raw"
local outdir  "`basedir'/output/tables"
local logdir  "`basedir'/output/logs"

* --- Ensure output directories exist ---------------------------------------
cap mkdir "`outdir'"
cap mkdir "`logdir'"

* --- Log -------------------------------------------------------------------
cap log close _all
log using "`logdir'/01_lasso_analysis.log", replace text


/*===========================================================================
  PART A:  Country Panel -- LASSO on forest-loss outcome
  ===========================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART A: country_panel.dta -- LASSO on forest loss"
di as txt "=================================================================="
di as txt ""

use "`rawdir'/country_panel.dta", clear
desc, short
desc

* ---- Identify the outcome variable ----------------------------------------
* The country_panel has: loss, loss_rate, and lead/lag RTA indicators.
* We use `loss` as the primary outcome (forest loss in hectares).

local outcome ""
foreach v in loss loss_rate defor biodiv {
    cap confirm numeric variable `v'
    if _rc == 0 {
        local outcome "`v'"
        di as txt ">>> Outcome variable identified: `outcome'"
        continue, break
    }
}

if "`outcome'" == "" {
    di as err "*** No suitable outcome variable found in country_panel."
    di as err "    Listing all numeric variables for reference:"
    ds, has(type numeric)
}

* ---- Summarize key variables -----------------------------------------------
sum loss loss_rate rta enviro_rta, detail

* ---- Build candidate regressors -------------------------------------------
* In country_panel, the regressors are the RTA lead/lag indicators:
*   rta, lag_1, lag_2, lag_3, lag_LR, enviro_rta, enviro_lag_1, ...
* We include all numeric vars except the outcome and the identifier.

ds, has(type numeric)
local allnumeric `r(varlist)'

* Remove outcome and identifiers from candidate list
local candidates ""
foreach v of local allnumeric {
    if "`v'" == "`outcome'" continue
    if "`v'" == "year"       continue
    local candidates "`candidates' `v'"
}

local ncand : word count `candidates'
di as txt ""
di as txt ">>> Number of candidate regressors: `ncand'"
di as txt ">>> Candidates: `candidates'"
di as txt ""


* ===========================================================================
* A1: Stata 18 built-in LASSO (cross-validated)
* ===========================================================================

di as txt "--- A1: Built-in lasso linear (10-fold CV) ---"

cap noisily {
    lasso linear `outcome' `candidates', selection(cv) folds(10) rseed(12345)

    * Store results
    estimates store lasso_cv

    * Report selected variables
    di as txt ""
    di as txt ">>> LASSO CV: Variables selected by cross-validation:"
    lassocoef, display(coef, standardized)

    * Which variables were selected?
    local selected_vars ""
    lassoknots
    di as txt ""
    lassoinfo
}

* Try to extract the selected variables for post-LASSO OLS
cap noisily {
    * lassocoef stores results; grab selected variable list
    lasso linear `outcome' `candidates', selection(cv) folds(10) rseed(12345)
    local sel_from_lasso ""

    * Use e(allvars_sel) if available (Stata 18)
    cap local sel_from_lasso = e(allvars_sel)

    if "`sel_from_lasso'" != "" {
        di as txt ""
        di as txt ">>> Post-LASSO OLS with selected variables:"
        di as txt "    Selected: `sel_from_lasso'"
        reg `outcome' `sel_from_lasso', robust
        estimates store postlasso_ols
    }
    else {
        di as txt ">>> Could not extract selected variables from e(allvars_sel)."
        di as txt "    Running lasso with selection(adaptive) as alternative:"
        cap noisily {
            lasso linear `outcome' `candidates', selection(adaptive) rseed(12345)
            estimates store lasso_adaptive
            lassocoef, display(coef, standardized)
        }
    }
}


* ===========================================================================
* A2: LASSO with selection(plugin) -- BRT/plugin penalty
* ===========================================================================

di as txt ""
di as txt "--- A2: Built-in lasso linear (plugin penalty) ---"

cap noisily {
    lasso linear `outcome' `candidates', selection(plugin) rseed(12345)
    estimates store lasso_plugin
    lassocoef, display(coef, standardized)
}


* ===========================================================================
* A3: Post-double-selection (dsregress) if treatment variable available
* ===========================================================================

di as txt ""
di as txt "--- A3: Post-double-selection with dsregress ---"
di as txt "    Treatment: enviro_rta  |  Outcome: `outcome'"

* enviro_rta is the key treatment in the paper (whether the RTA has
* environmental provisions)
cap confirm numeric variable enviro_rta
if _rc == 0 {
    * Build controls list (exclude outcome and treatment)
    local ds_controls ""
    foreach v of local candidates {
        if "`v'" == "enviro_rta" continue
        local ds_controls "`ds_controls' `v'"
    }

    di as txt "    Controls: `ds_controls'"

    cap noisily {
        dsregress `outcome' enviro_rta, controls(`ds_controls') ///
            selection(cv) folds(10) rseed(12345)
        estimates store ds_enviro
        di as txt ""
        di as txt ">>> dsregress results (treatment effect of enviro_rta on `outcome'):"
        estat summarize
    }

    * Also try with plain rta as treatment
    cap confirm numeric variable rta
    if _rc == 0 {
        local ds_controls2 ""
        foreach v of local candidates {
            if "`v'" == "rta" continue
            local ds_controls2 "`ds_controls2' `v'"
        }

        cap noisily {
            dsregress `outcome' rta, controls(`ds_controls2') ///
                selection(cv) folds(10) rseed(12345)
            estimates store ds_rta
        }
    }
}
else {
    di as txt "    enviro_rta not found; skipping dsregress."
}


* ===========================================================================
* A4: rlasso from lassopack (community-contributed fallback)
* ===========================================================================

di as txt ""
di as txt "--- A4: rlasso from lassopack (fallback) ---"

cap which rlasso
if _rc != 0 {
    di as txt "    lassopack not installed. Attempting ssc install..."
    cap noisily ssc install lassopack, replace
}

cap noisily {
    rlasso `outcome' `candidates', seed(12345)
    estimates store rlasso_result

    di as txt ""
    di as txt ">>> rlasso: Variables selected (rigorous / theory-driven penalty):"
    di as txt "    Selected: `e(selected)'"

    * Post-rlasso OLS
    local rlasso_sel "`e(selected)'"
    if "`rlasso_sel'" != "" {
        di as txt ">>> Post-rlasso OLS:"
        reg `outcome' `rlasso_sel', robust
        estimates store post_rlasso_ols
    }
}


/*===========================================================================
  PART B:  RTA Panel Full -- LASSO with richer covariates
  ===========================================================================
  This dataset has agricultural/forestry activity, expenditure, and trade
  variables at the agreement-year level.
  ===========================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART B: rta_panel_full.dta -- LASSO with rich covariates"
di as txt "=================================================================="
di as txt ""

cap noisily {
    use "`rawdir'/rta_panel_full.dta", clear
    desc, short

    * Summarize key variables
    cap noisily sum loss avg_loss_rate rta enviro_rta, detail

    * Identify outcome
    local outcome_b ""
    foreach v in loss avg_loss_rate group_loss_rate tropical_loss {
        cap confirm numeric variable `v'
        if _rc == 0 {
            local outcome_b "`v'"
            di as txt ">>> Part B outcome: `outcome_b'"
            continue, break
        }
    }

    if "`outcome_b'" == "" {
        di as err "*** No outcome found in rta_panel_full."
    }
    else {
        * Select candidate regressors: continuous/economic variables
        * (exclude country dummies -- there are ~200 of them -- to keep
        *  the LASSO tractable; include aggregate economic variables)
        local econ_vars ""
        foreach v in harvest_ha harvest_ton harvest_yield ///
                      ag_exp_ton ag_exp_val for_prod_exports for_prod_output ///
                      ag_recur_tot rnd_ag_tot ag_cap_tot for_recur_tot for_cap_tot ///
                      dev_harvest_ha dev_harvest_ton dev_harvest_yield ///
                      dev_ag_exp_ton dev_ag_exp_val dev_for_prod_exports ///
                      dev_for_prod_output dev_ag_recur_tot dev_rnd_ag_tot ///
                      dev_ag_cap_tot dev_for_recur_tot dev_for_cap_tot ///
                      tropical_harvest_ha tropical_harvest_ton tropical_harvest_yield ///
                      tropical_ag_exp_ton tropical_ag_exp_val ///
                      tropical_for_prod_exports tropical_for_prod_output ///
                      tropical_ag_recur_tot tropical_rnd_ag_tot tropical_ag_cap_tot ///
                      tropical_for_recur_tot tropical_for_cap_tot ///
                      parties parties_in_data in_force forest_prov ///
                      rta enviro_rta enviro_enforce_rta {
            cap confirm numeric variable `v'
            if _rc == 0 {
                if "`v'" != "`outcome_b'" {
                    local econ_vars "`econ_vars' `v'"
                }
            }
        }

        local ncand_b : word count `econ_vars'
        di as txt ""
        di as txt ">>> Part B candidates (`ncand_b' vars): `econ_vars'"

        * Drop observations where outcome is missing
        drop if missing(`outcome_b')

        * B1: Built-in lasso
        di as txt ""
        di as txt "--- B1: lasso linear on rta_panel_full ---"

        cap noisily {
            lasso linear `outcome_b' `econ_vars', selection(cv) folds(10) rseed(12345)
            estimates store lasso_rtapanel
            lassocoef, display(coef, standardized)
        }

        * B2: dsregress with enviro_rta as treatment
        cap confirm numeric variable enviro_rta
        if _rc == 0 {
            local ds_econ ""
            foreach v of local econ_vars {
                if "`v'" == "enviro_rta" continue
                local ds_econ "`ds_econ' `v'"
            }

            di as txt ""
            di as txt "--- B2: dsregress on rta_panel_full ---"
            cap noisily {
                dsregress `outcome_b' enviro_rta, controls(`ds_econ') ///
                    selection(cv) folds(10) rseed(12345)
                estimates store ds_rtapanel
            }
        }

        * B3: rlasso fallback
        di as txt ""
        di as txt "--- B3: rlasso on rta_panel_full ---"
        cap noisily {
            rlasso `outcome_b' `econ_vars', seed(12345)
            estimates store rlasso_rtapanel
            di as txt ">>> rlasso selected: `e(selected)'"
        }
    }
}


/*===========================================================================
  PART C:  RTA Data (cross-section) -- LASSO on defor/biodiv indicators
  ===========================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART C: rta_data.dta -- LASSO on deforestation provisions"
di as txt "=================================================================="
di as txt ""

cap noisily {
    use "`rawdir'/rta_data.dta", clear
    desc, short

    * This is a cross-section of RTAs. Key outcome: defor, biodiv
    cap noisily sum defor biodiv enviro_rta enviro_enforce_rta ///
        forest_total forest_total_percent max_biodiver avg_biodiver, detail

    * Candidates: agreement-level geographic & structural variables
    local rta_candidates ""
    foreach v in parties forest_total forest_total_percent land_total ///
                  max_biodiver avg_biodiver tropical_N template_N ///
                  Africa_N NAm_N LatAm_N Eur_N ESEAsia_N CAsia_N AusAsia_N ///
                  tropical_any template_any template ///
                  Africa_any NAm_any LatAm_any Eur_any ESEAsia_any ///
                  CAsia_any AusAsia_any entry_sq sig_sq ///
                  enviro_rta enviro_enforce_rta {
        cap confirm numeric variable `v'
        if _rc == 0 {
            local rta_candidates "`rta_candidates' `v'"
        }
    }

    local ncand_c : word count `rta_candidates'
    di as txt ">>> Part C candidates (`ncand_c' vars): `rta_candidates'"

    * C1: LASSO for defor (binary: does the RTA have deforestation provisions?)
    cap confirm numeric variable defor
    if _rc == 0 {
        * Remove defor from candidates
        local cand_no_defor ""
        foreach v of local rta_candidates {
            if "`v'" == "defor" continue
            if "`v'" == "biodiv" continue
            local cand_no_defor "`cand_no_defor' `v'"
        }

        di as txt ""
        di as txt "--- C1: lasso linear for defor ---"
        cap noisily {
            lasso linear defor `cand_no_defor', selection(cv) folds(10) rseed(12345)
            estimates store lasso_defor
            lassocoef, display(coef, standardized)
        }

        * Also try logit lasso since defor is binary
        di as txt ""
        di as txt "--- C1b: lasso logit for defor ---"
        cap noisily {
            lasso logit defor `cand_no_defor', selection(cv) folds(10) rseed(12345)
            estimates store lasso_defor_logit
            lassocoef, display(coef, standardized)
        }
    }

    * C2: LASSO for biodiv
    cap confirm numeric variable biodiv
    if _rc == 0 {
        local cand_no_biodiv ""
        foreach v of local rta_candidates {
            if "`v'" == "biodiv" continue
            if "`v'" == "defor"  continue
            local cand_no_biodiv "`cand_no_biodiv' `v'"
        }

        di as txt ""
        di as txt "--- C2: lasso linear for biodiv ---"
        cap noisily {
            lasso linear biodiv `cand_no_biodiv', selection(cv) folds(10) rseed(12345)
            estimates store lasso_biodiv
            lassocoef, display(coef, standardized)
        }

        di as txt ""
        di as txt "--- C2b: lasso logit for biodiv ---"
        cap noisily {
            lasso logit biodiv `cand_no_biodiv', selection(cv) folds(10) rseed(12345)
            estimates store lasso_biodiv_logit
            lassocoef, display(coef, standardized)
        }
    }
}


/*===========================================================================
  PART D:  Export results to LaTeX
  ===========================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  PART D: Export results to LaTeX"
di as txt "=================================================================="
di as txt ""

* Use esttab if available; otherwise write a manual table
cap which esttab
if _rc != 0 {
    di as txt "    esttab not found. Attempting install..."
    cap noisily ssc install estout, replace
}

cap noisily {
    * Collect whichever estimates were stored successfully
    local est_list ""
    foreach e in lasso_cv lasso_plugin postlasso_ols post_rlasso_ols {
        cap estimates restore `e'
        if _rc == 0 {
            local est_list "`est_list' `e'"
        }
    }

    if "`est_list'" != "" {
        di as txt ">>> Exporting estimates: `est_list'"
        esttab `est_list' using "`outdir'/tab_lasso_results.tex", ///
            replace booktabs label ///
            title("LASSO Variable Selection -- jvae023 RTA \& Environment") ///
            note("Data: country\_panel.dta from Abman, Lundberg \& Ruta.") ///
            star(* 0.10 ** 0.05 *** 0.01) ///
            se(%9.4f) b(%9.4f)
        di as txt ">>> Table saved to: `outdir'/tab_lasso_results.tex"
    }
    else {
        di as txt ">>> No stored estimates available for esttab."
        di as txt ">>> Writing a manual summary table..."

        * Fallback: write a minimal LaTeX table with whatever we have
        cap file close texfile
        file open texfile using "`outdir'/tab_lasso_results.tex", write replace
        file write texfile "\begin{table}[htbp]" _n
        file write texfile "\centering" _n
        file write texfile "\caption{LASSO Variable Selection Results -- jvae023}" _n
        file write texfile "\label{tab:lasso_results}" _n
        file write texfile "\begin{tabular}{lcc}" _n
        file write texfile "\hline\hline" _n
        file write texfile "Method & Variables Selected & Notes \\" _n
        file write texfile "\hline" _n
        file write texfile "Built-in lasso (CV)  & See log & selection(cv) folds(10) \\" _n
        file write texfile "Built-in lasso (plugin) & See log & selection(plugin) \\" _n
        file write texfile "rlasso (lassopack) & See log & Rigorous penalty \\" _n
        file write texfile "dsregress & See log & Post-double-selection \\" _n
        file write texfile "\hline\hline" _n
        file write texfile "\multicolumn{3}{p{10cm}}{\small\textit{Note:} " _n
        file write texfile "Results from LASSO analysis on country\_panel data " _n
        file write texfile "from Abman, Lundberg \& Ruta (jvae023). " _n
        file write texfile "See log file for coefficient details.} \\" _n
        file write texfile "\end{tabular}" _n
        file write texfile "\end{table}" _n
        file close texfile

        di as txt ">>> Fallback table written to: `outdir'/tab_lasso_results.tex"
    }
}


/*===========================================================================
  Wrap-up
  ===========================================================================*/

di as txt ""
di as txt "=================================================================="
di as txt "  LASSO ANALYSIS COMPLETE"
di as txt "=================================================================="
di as txt ""
di as txt "  Log file:    `logdir'/01_lasso_analysis.log"
di as txt "  LaTeX table: `outdir'/tab_lasso_results.tex"
di as txt ""

cap log close _all

exit
