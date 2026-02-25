# Stata Code Conventions

These conventions apply to ALL Stata .do files in this project.

## Header Template

Every .do file MUST start with this header block:

```stata
/*==============================================================================
Project:    [Project Name]
Version:    [vN]
Script:     [filename.do]
Purpose:    [Brief description]
Author:     [Name]
Created:    [Date]
Modified:   [Date]
Input:      [Input files]
Output:     [Output files]
==============================================================================*/
```

## Standard Settings

Every .do file must include these settings immediately after the header:

```stata
version 18
clear all
set more off
set maxvar 32767
set matsize 11000
set seed 12345
```

## Logging

Every .do file must:
1. Close any existing log first (with `cap log close` to avoid error if no log open)
2. Start a new log
3. End with `log close`

```stata
cap log close
log using "output/logs/XX_script_name.log", replace
* ... all code ...
log close
```

## Cluster Standard Errors

Always use `vce(cluster var)` as the default for ALL regressions. Never report non-clustered standard errors unless explicitly justified.

```stata
reghdfe y x1 x2, absorb(fe) vce(cluster firmid)
```

## Fixed Effects

Use `reghdfe` for multi-way fixed effects, with `absorb()` syntax:

```stata
reghdfe y x1 x2, absorb(firmid year) vce(cluster firmid)
```

For single-dimension FE, `reghdfe` is still preferred for consistency.

## Table Output

Use `esttab`/`estout` for LaTeX table generation. Store estimates with `estimates store`:

```stata
eststo clear
reghdfe y x1 x2, absorb(fe) vce(cluster firmid)
estimates store m1
reghdfe y x1 x2 x3, absorb(fe) vce(cluster firmid)
estimates store m2
esttab m1 m2 using "output/tables/results.tex", ///
    se(4) b(4) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs replace
```

Note: Use 4 decimal places for coefficients (TOP5 standard for causal inference).

## Variable Labels

All variables MUST have labels. Apply `label variable` immediately after `gen` or `rename`:

```stata
gen log_wage = ln(wage)
label variable log_wage "Log of hourly wage"
```

## Data Safety

- NEVER write to `data/raw/` -- raw data is read-only.
- All modifications go to `data/clean/` or `data/temp/`.
- Save cleaned datasets with descriptive names and version suffixes if needed.

```stata
* CORRECT
save "data/clean/panel_cleaned.dta", replace

* WRONG -- never do this
save "data/raw/original_data.dta", replace
```

## Path Convention

Use relative paths from the project root. Define globals for base paths at the top of each .do file or in a master .do file:

```stata
global root    "."
global data    "$root/data"
global raw     "$data/raw"
global clean   "$data/clean"
global temp    "$data/temp"
global output  "$root/output"
global tables  "$output/tables"
global figures "$output/figures"
global logs    "$output/logs"
```

## Reproducibility

Set `set seed 12345` before ANY randomization, bootstrapping, or simulation:

```stata
set seed 12345
bootstrap, reps(1000) cluster(firmid): reg y x1 x2
```

Always save intermediate datasets so that each script can be run independently.

## Defensive Programming

Use `isid` and `assert` to validate data integrity:

```stata
* Verify unique identifier
isid panel_id year

* Verify expected values
assert treatment >= 0 & treatment <= 1
assert !missing(outcome, treatment, running_var)

* Verify panel structure
xtset panel_id year
assert r(balanced) == "strongly balanced"
```

## Memory Management

Use `compress` before saving large datasets:

```stata
compress
save "data/clean/panel_cleaned.dta", replace
```

## Required Packages

List all required packages in a comment block at the top of each .do file or in master.do:

```stata
* Required packages:
*   ssc install reghdfe
*   ssc install ftools
*   ssc install estout
*   ssc install coefplot
```

## Master.do Pattern

Organize projects with a master.do file that:
1. Sets all globals
2. Creates output directories
3. Runs all analysis scripts in order
4. Verifies outputs

See `init-project.md` for the full master.do template.
