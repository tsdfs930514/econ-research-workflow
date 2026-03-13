---
name: run-lasso
description: "Run LASSO and regularized regression pipeline -- variable selection, cross-validated penalty, post-LASSO OLS, post-double-selection (Belloni-Chernozhukov-Hansen), rigorous LASSO, elastic net, LASSO propensity score matching. Use when: 'LASSO', 'variable selection', 'regularization', 'post-double-selection', 'high-dimensional controls', 'penalized regression', 'elastic net', 'pdslasso'."
user_invocable: true
---

# /run-lasso — LASSO & Regularized Regression Pipeline

When the user invokes `/run-lasso`, execute a complete regularized regression pipeline covering standard LASSO for prediction, cross-validated penalty selection, post-LASSO OLS, post-double-selection for causal inference (Belloni, Chernozhukov, Hansen 2014), rigorous LASSO with valid inference, and Python cross-validation.

## Stata Execution Command

Run .do files via the auto-approved wrapper: `bash .claude/scripts/run-stata.sh "<project_dir>" "code/stata/script.do"`. The wrapper handles `cd`, Stata execution (`-e` flag), and automatic log error checking. See `CLAUDE.md` for details.

## When to Use LASSO / Regularization

- **Many candidate controls**: When you have dozens/hundreds of potential controls and need principled selection
- **Causal inference with high-dimensional covariates**: Post-double-selection selects controls for BOTH outcome and treatment models, avoiding omitted variable bias while preventing overfitting
- **Prediction tasks**: When the goal is forecasting rather than inference
- **Variable selection for robustness**: Complement hand-picked controls with data-driven selection
- **Avoiding cherry-picking**: Reviewer concern about which controls were included — LASSO provides a principled answer

**Important**: Standard LASSO does NOT provide valid inference on selected coefficients. For causal inference, use post-double-selection (Step 4) or rigorous LASSO (Step 5).

## Step 0: Gather Inputs

Ask the user for:

- **Dataset**: path to .dta file
- **Outcome variable**: dependent variable Y
- **Treatment variable** (if causal inference): the key variable whose effect is of interest
- **Candidate regressors**: full list of potential controls (can be large)
- **Fixed effects** (optional): FE to absorb before LASSO
- **Cluster variable**: for clustered standard errors in post-selection inference
- **Purpose**: prediction, variable selection, or causal inference via post-double-selection
- **Model type**: linear, logit, or poisson (Stata 16+ `lasso` supports all). **Note**: `lasso logit` may fail with r(430) convergence error when the binary outcome has near-perfect separation with some predictors. Wrap in `cap noisily` and fall back to `rlasso` if needed (Issue #18).

Determine Stata version: LASSO built-ins (`lasso`, `dsregress`) require Stata 16+. For earlier versions, use community packages (`lassopack`: `cvlasso`, `rlasso`, `pdslasso`).

## Steps 1-7: Implementation

For complete Stata/Python/R code templates for each step, read `references/lasso-templates.md`.

The pipeline follows these steps:

1. **Standard LASSO** — CV-based variable selection (Stata 16+ `lasso` or `cvlasso`). Log to `output/logs/lasso_01_selection.log`. Report number of selected variables and lambda values. Compare CV-min vs 1-SE rule.
2. **Selection Path** — Coefficient path visualization (`coefpath`/`lassoknots`). Compare LASSO-selected vs hand-picked vs full model vs minimal model for treatment coefficient stability. Log to `lasso_02_path.log`.
3. **Post-LASSO OLS** — Run OLS on LASSO-selected variables for unbiased coefficients (LASSO regularization biases coefficients toward zero). Check `e(k_nonzero_sel) > 0` before proceeding — CV LASSO may select 0 variables in small samples. Log to `lasso_03_postlasso.log`.
4. **Post-Double-Selection** — The key causal inference method. LASSO selects controls for BOTH the Y equation and the D equation, then OLS uses the union. Three implementations: `dsregress` (Stata 16+, recommended), `pdslasso` (community), manual (rlasso × 2 + reghdfe). Log to `lasso_04_pds.log`.
5. **Rigorous LASSO** — Theory-driven penalty via `rlasso` (Belloni, Chen, Chernozhukov & Hansen 2012) with cluster-robust penalty. Also elastic net comparison (alpha grid 0-1). Log to `lasso_05_rlasso.log`.
6. **Python Cross-Validation** — sklearn `LassoCV`, post-LASSO OLS via statsmodels, manual PDS, CV error plot. PDS comparison uses 1% threshold (different CV splits may select different variables).
7. **LASSO Propensity Score Matching** — R `glmnet` for logistic LASSO P-score, 1:1 NN matching, DiD on matched panel. Pattern from Abman, Lundberg & Ruta (JEEA 2024). Includes IHS transformation for near-zero outcomes.

## Step 8: Diagnostics Summary

After all steps, provide:

1. **Variable Selection**: How many variables selected by LASSO vs total candidates? Are key theoretical controls included?
2. **CV Error Plot**: Is the minimum well-defined or is the error curve flat (suggesting weak signal)?
3. **Post-LASSO vs Full OLS**: Does the treatment coefficient change substantially when switching from LASSO-selected to full control set? Stability supports robustness.
4. **Post-Double-Selection**: Report controls selected for Y-equation vs D-equation. If the union is much larger than either alone, important confounders were missed by single-equation selection.
5. **PDS vs Hand-Picked**: Compare PDS treatment effect with hand-picked specification. Large divergence suggests the hand-picked set may be misspecified.
6. **Rigorous LASSO**: Compare CV-based and theory-based (rlasso) selected variables. If they agree, selection is stable.
7. **Cross-Validation**: Stata vs Python post-double-selection coefficient comparison.

## Required Stata Packages

```stata
* Stata 16+ built-in: lasso, dsregress, elasticnet (no install needed)

* Community packages (any Stata version):
ssc install lassopack, replace     // cvlasso, rlasso, lasso2
net install pdslasso, from("https://raw.githubusercontent.com/statalasso/pdslasso/master")
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
```

## Key References

- Belloni, A., Chernozhukov, V. & Hansen, C. (2014). "Inference on Treatment Effects after Selection among High-Dimensional Controls." REStud, 81(2), 608-650.
- Belloni, A., Chen, D., Chernozhukov, V. & Hansen, C. (2012). "Sparse Models and Methods for Optimal Instruments with an Application to Eminent Domain." Econometrica, 80(6), 2369-2429.
- Tibshirani, R. (1996). "Regression Shrinkage and Selection via the Lasso." JRSSB.
- Ahrens, A., Hansen, C.B. & Schaffer, M.E. (2020). "lassopack: Model Selection and Prediction with Regularized Regression in Stata." Stata Journal.
