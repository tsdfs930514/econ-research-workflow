/*==============================================================================
  REPLICATION TEST: Enhanced RDD — /run-rdd
  Data:    synthetic_rdd.dta (from test2-rdd)
  Tests:   Edge cases: discrete running var, donut hole, fuzzy RDD,
           bandwidth sensitivity, placebo cutoffs
==============================================================================*/
clear all
set more off
set seed 12345

cap log close
log using "v1/output/logs/01_rdd_analysis.log", replace

* --- Install packages ---
foreach pkg in rdrobust rddensity coefplot estout {
    cap which `pkg'
    if _rc != 0 {
        cap noisily {
            if "`pkg'" == "rdrobust" {
                net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
            }
            else if "`pkg'" == "rddensity" {
                net install rddensity, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata) replace
            }
            else {
                ssc install `pkg', replace
            }
        }
    }
}

* --- Load data ---
use "v1/data/raw/synthetic_rdd.dta", clear
desc
sum

* Identify variables
ds
local allvars `r(varlist)'
di "Variables: `allvars'"

* Standard RDD variables (from test2-rdd synthetic data)
* Expected: running_var, outcome, treatment (or similar names)
cap confirm numeric variable running_var
if _rc != 0 {
    * Try alternative names
    foreach v in score x running run_var {
        cap confirm numeric variable `v'
        if _rc == 0 {
            rename `v' running_var
            continue, break
        }
    }
}

cap confirm numeric variable outcome
if _rc != 0 {
    foreach v in y outcome_var dep_var {
        cap confirm numeric variable `v'
        if _rc == 0 {
            rename `v' outcome
            continue, break
        }
    }
}

* Assume cutoff at 0 (standard for synthetic RDD)
local cutoff = 0

* --- Step 1: Sharp RDD Main Estimation ---
di "============================================="
di "STEP 1: MAIN RD ESTIMATION"
di "============================================="

cap noisily {
    rdrobust outcome running_var, c(`cutoff') kernel(triangular) bwselect(mserd) all
    local tau_conv = e(tau_cl)
    local se_conv = e(se_tau_cl)
    local tau_bc = e(tau_bc)
    local se_robust = e(se_tau_rb)
    local bw_l = e(h_l)
    local bw_r = e(h_r)
    local N_eff = e(N_h_l) + e(N_h_r)
    di "Conventional: `tau_conv' (SE = `se_conv')"
    di "Bias-corrected: `tau_bc' (Robust SE = `se_robust')"
    di "Bandwidth L/R: `bw_l' / `bw_r'"
    di "Effective N: `N_eff'"
}

* --- Step 2: Density Test ---
di "============================================="
di "STEP 2: MANIPULATION TEST (rddensity)"
di "============================================="

cap noisily {
    rddensity running_var, c(`cutoff')
    * Try multiple ways to get p-value
    cap local dens_p = e(pv_q)
    if "`dens_p'" == "" | "`dens_p'" == "." {
        cap local dens_p = r(p)
    }
    di "Density test p-value = `dens_p'"
}

* --- Step 3: Bandwidth Sensitivity ---
di "============================================="
di "STEP 3: BANDWIDTH SENSITIVITY"
di "============================================="

cap noisily {
    rdrobust outcome running_var, c(`cutoff') kernel(triangular) bwselect(mserd)
    local bw_opt = e(h_l)

    foreach mult in 0.50 0.75 1.00 1.25 1.50 2.00 {
        local bw_test = `bw_opt' * `mult'
        cap noisily rdrobust outcome running_var, c(`cutoff') kernel(triangular) h(`bw_test')
        if _rc == 0 {
            di "`mult'x BW (`bw_test'): tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
        }
    }
}

* --- Step 4: Polynomial Sensitivity ---
di "============================================="
di "STEP 4: POLYNOMIAL ORDER SENSITIVITY"
di "============================================="

forvalues p = 1/3 {
    cap noisily {
        rdrobust outcome running_var, c(`cutoff') kernel(triangular) bwselect(mserd) p(`p')
        di "p=`p': tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
    }
}

* --- Step 5: Kernel Sensitivity ---
di "============================================="
di "STEP 5: KERNEL SENSITIVITY"
di "============================================="

foreach kern in triangular uniform epanechnikov {
    cap noisily {
        rdrobust outcome running_var, c(`cutoff') kernel(`kern') bwselect(mserd)
        di "`kern': tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
    }
}

* --- Step 6: Placebo Cutoffs ---
di "============================================="
di "STEP 6: PLACEBO CUTOFFS"
di "============================================="

sum running_var, detail
local p25 = r(p25)
local p75 = r(p75)

* Below cutoff
cap noisily {
    rdrobust outcome running_var if running_var < `cutoff', c(`p25') kernel(triangular) bwselect(mserd)
    di "Placebo at p25 (`p25'): tau = " e(tau_cl) " (p = " e(pv_cl) ")"
}

* Above cutoff
cap noisily {
    rdrobust outcome running_var if running_var > `cutoff', c(`p75') kernel(triangular) bwselect(mserd)
    di "Placebo at p75 (`p75'): tau = " e(tau_cl) " (p = " e(pv_cl) ")"
}

* --- Step 7: Donut Hole RDD ---
di "============================================="
di "STEP 7: DONUT HOLE RDD"
di "============================================="

foreach donut in 0.1 0.25 0.5 1.0 {
    cap noisily {
        rdrobust outcome running_var if abs(running_var - `cutoff') > `donut', ///
            c(`cutoff') kernel(triangular) bwselect(mserd)
        di "Donut +-`donut': tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
    }
}

* --- Step 8: Discrete Running Variable Test ---
di "============================================="
di "STEP 8: DISCRETE RUNNING VARIABLE"
di "============================================="

* Create discretized version
preserve
gen running_discrete = round(running_var, 0.5)
cap noisily {
    rdrobust outcome running_discrete, c(`cutoff') kernel(triangular) bwselect(mserd) all
    di "Discrete RV: tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
}
restore

* --- Step 9: Fuzzy RDD Simulation ---
di "============================================="
di "STEP 9: FUZZY RDD (simulated compliance)"
di "============================================="

preserve
* Create fuzzy treatment: imperfect compliance
gen treat_sharp = (running_var >= `cutoff')
gen compliance_noise = rnormal(0, 0.3)
gen treat_fuzzy = (running_var + compliance_noise >= `cutoff')
* Ensure some non-compliance
replace treat_fuzzy = 0 if running_var < `cutoff' - 1 & treat_fuzzy == 1
replace treat_fuzzy = 1 if running_var > `cutoff' + 1 & treat_fuzzy == 0

tab treat_sharp treat_fuzzy

cap noisily {
    rdrobust outcome running_var, c(`cutoff') fuzzy(treat_fuzzy) kernel(triangular) bwselect(mserd) all
    di "Fuzzy RD: tau = " e(tau_cl) " (SE = " e(se_tau_cl) ")"
}
restore

* --- Step 10: Cross-Validation Data ---
di "============================================="
di "STEP 10: CROSS-VALIDATION DATA"
di "============================================="

cap noisily {
    rdrobust outcome running_var, c(`cutoff') kernel(triangular) bwselect(mserd)
    di "=== CROSS-VALIDATION DATA ==="
    di "RD_tau_conv = " e(tau_cl)
    di "RD_se_conv = " e(se_tau_cl)
    di "RD_bw_l = " e(h_l)
    di "RD_N_eff = " e(N_h_l) + e(N_h_r)
}

di "============================================="
di "RDD ANALYSIS COMPLETE"
di "============================================="

log close
