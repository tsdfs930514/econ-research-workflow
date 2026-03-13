---
name: run-logit-probit
description: "Run logit/probit and treatment effects pipeline -- binary outcome, marginal effects (AME/MEM), propensity score, IPW, AIPW, regression adjustment, conditional logit, multinomial logit, ordered logit, IV probit, nearest-neighbor matching, ROC/AUC diagnostics. Use when: 'logit', 'probit', 'binary outcome', 'propensity score', 'treatment effects', 'IPW', 'AIPW', 'discrete choice', 'conditional logit'."
user_invocable: true
---

# /run-logit-probit — Logit/Probit & Discrete Choice Pipeline

When the user invokes `/run-logit-probit`, execute a complete discrete choice and treatment effects pipeline covering standard logit/probit estimation with marginal effects, propensity score estimation, treatment effects via RA/IPW/AIPW, conditional logit for discrete choice, diagnostics (overlap, ROC, Hosmer-Lemeshow), and Python cross-validation.

## Stata Execution Command

Run .do files via the auto-approved wrapper: `bash .claude/scripts/run-stata.sh "<project_dir>" "code/stata/script.do"`. The wrapper handles `cd`, Stata execution (`-e` flag), and automatic log error checking. See `CLAUDE.md` for details.

## When to Use This Pipeline

- **Binary outcome**: Y is 0/1 — use logit or probit
- **Propensity score matching/weighting**: Estimating P(Treatment=1|X) for causal inference
- **Treatment effects**: ATET via regression adjustment, IPW, or doubly robust (AIPW)
- **Discrete choice**: Consumer/firm choice among alternatives — use conditional logit (clogit)
- **Ordered outcome**: Likert scale, rating categories — use ologit/oprobit
- **Multinomial outcome**: Unordered categories (occupation, transport mode) — use mlogit

## Step 0: Gather Inputs

Ask the user for:

- **Dataset**: path to .dta file
- **Outcome type**: binary (0/1), ordered, multinomial, or conditional choice
- **Dependent variable**: outcome variable
- **Treatment variable** (if propensity score / treatment effects): binary treatment indicator
- **Covariates**: control variables for the model
- **Choice group variable** (if conditional logit): group identifier (e.g., household-year)
- **Alternative-specific variables** (if conditional logit): variables that vary across alternatives
- **Cluster variable**: for clustered standard errors
- **Fixed effects** (if applicable): for absorbed FE
- **Weight variable** (optional): sampling weights (e.g., `[pw=weight]`)
- **Purpose**: estimation only, propensity score for matching/weighting, or full treatment effects

## Steps 1-7: Implementation

For complete Stata/Python code templates for each step, read `references/logit-probit-stata-templates.md`.

The pipeline follows these steps:

1. **Standard Logit/Probit** — Estimate logit and probit with AME (Average Marginal Effects) and MEM (Marginal Effects at Means). Compare with LPM (Linear Probability Model). If AME ~ MEM ~ LPM, nonlinearity is minimal. Log to `output/logs/logit_01_estimation.log`.
2. **Propensity Score** — Probit-based P-score estimation (following DDCG Table A11 pattern). Overlap diagnostics: kernel density plot, histogram, common support trimming. Covariate balance after IPW weighting (standardized differences, target < 0.1). Log to `logit_02_pscore.log`.
3. **Treatment Effects** — RA, IPW, AIPW, NN-matching via `teffects`. **Important**: `teffects` only works with cross-sectional data — panel data with repeated obs causes r(459). Wrap in `cap noisily`. For panel data, collapse to cross-section first or use manual IPW with `reghdfe`. AIPW preferred (doubly robust). Log to `logit_03_teffects.log`.
4. **Conditional Logit** — McFadden discrete choice model via `clogit`. Data must be in long format (one row per alternative per choice occasion). Following Mexico Retail Table 5 pattern. Log to `logit_04_clogit.log`.
5. **Diagnostics** — ROC/AUC (> 0.7 acceptable, > 0.8 good), Hosmer-Lemeshow GOF, Pregibon link test (_hat significant, _hatsq not), classification table, pseudo R-squared comparison. Log to `logit_05_diagnostics.log`.
6. **Extensions** — Multinomial logit (mlogit), ordered logit/probit (ologit/oprobit), IV probit for endogenous binary treatment. Log to `logit_06_extensions.log`.
7. **Python Cross-Validation** — statsmodels Logit/Probit with clustered SE, AME via `get_margeff()`, sklearn LogisticRegression, ROC/AUC comparison. AME comparison uses 0.5% threshold (numerical integration differences).

## Step 8: Diagnostics Summary

After all steps, provide:

1. **Model Selection**: Logit vs probit — coefficients differ but AME should be similar. If AME diverges, report both and note which is preferred.
2. **LPM Comparison**: LPM coefficient vs logit/probit AME. If similar, nonlinearity is minimal.
3. **Propensity Score**: Overlap quality (visual + numeric). Flag if common support excludes > 10% of observations.
4. **Treatment Effects**: RA, IPW, AIPW convergence. If all three agree, result is robust. If IPW diverges from RA, treatment model may be misspecified.
5. **Diagnostics**: ROC/AUC, Hosmer-Lemeshow, link test results. Flag poor fit (AUC < 0.7 or H-L rejection).
6. **Conditional Logit** (if applicable): IIA assumption discussion, marginal effects interpretation.
7. **Cross-Validation**: Stata vs Python AME comparison.

## Required Stata Packages

```stata
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install coefplot, replace
```

## Key References

- Acemoglu, D., Naidu, S., Restrepo, P. & Robinson, J.A. (2019). "Democracy Does Cause Growth." JPE, 127(1), 47-100.
- Imbens, G.W. (2004). "Nonparametric Estimation of Average Treatment Effects Under Exogeneity." REStat.
- McFadden, D. (1974). "Conditional Logit Analysis of Qualitative Choice Behavior."
- Cattaneo, M.D. (2010). "Efficient Semiparametric Estimation of Multi-Valued Treatment Effects." JoE.
