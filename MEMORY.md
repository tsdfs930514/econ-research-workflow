# MEMORY.md - Cross-Session Learning

> **Instructions for Claude**: During every session, append new entries to the appropriate section below using the tagged format. Never delete existing entries — only add. Use the following tags:
>
> - `[LEARN]` — New knowledge about the project, tools, or environment
> - `[DECISION]` — Methodological or structural decisions made
> - `[ISSUE]` — Problems encountered and their resolutions
> - `[PREFERENCE]` — User preferences for formatting, style, or workflow
>
> **Format**: `[TAG] YYYY-MM-DD: description`
>
> At the end of each session, add a brief summary to the Session Log section.

---

## Project Decisions Log

Track key methodological and structural decisions.

| Date | Decision | Rationale |
|---|---|---|
| | | |

<!-- Example:
| 2026-02-25 | Use Poisson regression for count outcome | Dependent variable is non-negative integer; OLS residuals showed overdispersion |
| 2026-02-25 | Cluster SEs at county level | Treatment assigned at county level; within-county correlation expected |
-->

---

## Data Issues Encountered

Document data problems and how they were resolved.

| Date | Issue | Resolution |
|---|---|---|
| | | |

<!-- Example:
| 2026-02-25 | 342 observations with negative income values | Confirmed data entry errors with source; dropped observations and noted in appendix |
| 2026-02-25 | Missing state FIPS codes for 2018 observations | Merged supplementary crosswalk from Census Bureau |
-->

---

## Reviewer Feedback Tracker

Track feedback from co-authors, referees, and seminar participants.

| Round | Reviewer | Key Points | Status |
|---|---|---|---|
| | | | |

<!-- Example:
| R&R Round 1 | Referee 1 | Add robustness check with alternative FE specification | Addressed in v2 |
| R&R Round 1 | Referee 2 | Concerns about sample selection; requested Heckman correction | In progress |
| Seminar | Prof. Smith | Suggested difference-in-differences as alternative identification | Noted for discussion |
-->

---

## Methodology Notes

Record key methodological choices and their justifications.

| Method | Key Parameters | Justification |
|---|---|---|
| | | |

<!-- Example:
| Two-way Fixed Effects | Entity + Year FE | Control for time-invariant entity characteristics and common shocks |
| Conley Standard Errors | Cutoff = 100km | Account for spatial correlation in outcome variable |
| Winsorization | 1st and 99th percentiles | Reduce influence of extreme outliers in revenue data |
-->

---

## Cross-Check Results

Log comparisons between Stata and Python outputs to ensure consistency.

| Date | Comparison | Discrepancies Found |
|---|---|---|
| | | |

<!-- Example:
| 2026-02-25 | Main regression Table 2 (Stata vs pyfixest) | None - coefficients match to 6 decimal places |
| 2026-02-25 | Summary statistics Table 1 | Minor difference in median (Stata uses interpolation, Python uses midpoint); documented |
-->

---

## LaTeX/Formatting Preferences

Record learned formatting preferences for consistency.

| Element | Preference | Notes |
|---|---|---|
| | | |

<!-- Example:
| Table font size | \small | Journal requires compact tables |
| Figure width | 0.8\textwidth | Consistent sizing across all figures |
| Citation style | Author-year (natbib) | Required by target journal |
| Number format | Comma separator for thousands | US convention |
| Table notes | Minipage below table | Preferred by co-author |
-->

---

## Learnings from Test Suite

Issues discovered during the 5-test validation suite (2026-02-25). These inform defensive coding practices across all skills.

- [ISSUE] 2026-02-25: `boottest` does not work after `reghdfe` with multiple absorbed FE — wrap with `cap noisily` in /run-did
- [ISSUE] 2026-02-25: `csdid` and `bacondecomp` are version-sensitive and may fail on dependency issues — always wrap with `cap noisily`
- [ISSUE] 2026-02-25: `rddensity` p-value may be missing (stored in different scalars across versions) — try `e(p)`, `r(p)`, and scalar fallbacks in /run-rdd
- [ISSUE] 2026-02-25: Synthetic IV data with only random noise for instrument has near-zero partial F after absorbing FE — DGP must include county-specific slopes for within-FE variation
- [ISSUE] 2026-02-25: `tab treatment, missing` fails on continuous variables (too many unique values) — use `summarize treatment, detail` for continuous treatments in /run-iv
- [ISSUE] 2026-02-25: `xtserial` removed from SSC — use `cap ssc install` and `cap noisily` wrapper; package may be built into Stata 18
- [ISSUE] 2026-02-25: `xtcsd` and `xttest3` installation fails when `xtserial` install error interrupts batch — each `ssc install` should be independent with `cap` prefix
- [ISSUE] 2026-02-25: Hausman test produces negative chi2 (= -808, p=1) when FE strongly dominates RE — this is known Stata behavior, FE is still the correct choice
- [ISSUE] 2026-02-25: `assert treated == post` fails when missing values present — add `if !missing(treated)` condition
- [LEARN] 2026-02-25: In Git Bash, Stata flags must use dash prefix (`-e`) not slash prefix (`/e`, `/b`) — slash is interpreted as Unix path

### Learnings from Replication Package 1: Acemoglu et al. (2019) — Democracy Does Cause Growth

- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added `L(1/N).var` dynamic lag syntax documentation (not just `L.var`). Published papers routinely use 4 or 8 lags of the dependent variable.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added Helmert / forward orthogonal deviations option for GMM (`orthogonal` option in xtabond2, or custom `helm` program pattern).
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added difference-only GMM documentation (`noleveleq` option in xtabond2).
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added multi-way clustering syntax: `vce(cluster var1 var2)`.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added note about custom ado programs in published replication code (vareffects, helm, hhkBS patterns).
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added `xtivreg2` as alternative for panel IV with native `fe` option and `partial()` for year dummies.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added interaction FE syntax: `absorb(fe1 fe2#fe3)` or `absorb(fe1 i.fe2#i.fe3)`.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added shift-share / Bartik IV section with Adao-Kolesár-Morales (2019) exposure-robust SE correction.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added `savefirst` option documentation for storing first-stage estimates.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added multiple endogenous variables pattern (e.g., democracy + spatial lag).
- [SKILL-UPDATE] 2026-02-25: `/data-describe` — Added `.sas7bdat` format support via `pd.read_sas()`.
- [SKILL-UPDATE] 2026-02-25: `/data-describe` — Added large dataset guidance (subsample for histograms if N > 1M, use polars).
- [LEARN] 2026-02-25: ivreghdfe works as first-choice for panel IV — successfully replicated Table 6 without falling back to xtivreg2.
- [LEARN] 2026-02-25: Cross-validation of FE panel results: Stata reghdfe vs Python pyfixest match to 0.000000% coefficient difference.
- [LEARN] 2026-02-25: GMM diagnostics pattern — AR(2) p=0.514, Hansen J p=1.000 for 4-lag specification. AR(2) rejection at 1-lag (p=0.010) but not at 4-lag — confirms need for sufficient lags.
- [LEARN] 2026-02-25: IV results from DDCG — 2SLS coef (1.149) > OLS coef (0.787), consistent with attenuation bias story. LIML (1.152) very close to 2SLS, confirming instrument strength.

### Learnings from Replication Package 2: Mexico Retail Entry

- [ISSUE] 2026-02-25: Package 2 cannot run end-to-end — Economic Census input data (`Insumo1999-2019.dta`) not included in replication ZIP. Only `Data/Uploaded/` analysis files present. Data prep scripts (9 scripts) require external census data.
- [LEARN] 2026-02-25: `e(rkf)` is the correct scalar for KP rk F-stat after `ivreghdfe` (not `e(widstat)` which is from `ivreg2`). Different commands store diagnostics in different scalars.
- [LEARN] 2026-02-25: PCA for control construction is common in applied micro: `pca Count_46*_market` → `predict pc1-pcN, score` → use predicted components as controls. This reduces dimensionality of many retail establishment type counts.
- [LEARN] 2026-02-25: `outreg2` is widely used in published code as alternative to `esttab`. Syntax: `outreg2 using table_X, excel replace addtext(...) nor2 drop(...)`. Our skills use `esttab` which is more flexible but `outreg2` is simpler for quick output.
- [LEARN] 2026-02-25: `joinby` used for many-to-many spatial matching (AGEB census blocks to overlapping market areas). Alternative to `merge m:m` which is generally discouraged.
- [LEARN] 2026-02-25: Large dataset pattern — `compress` called frequently to reduce memory; `gstats` from `gtools` package used instead of `sum` for efficiency on large datasets.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Noted that `e(rkf)` is the KP F scalar after `ivreghdfe`, while `e(widstat)` is from `ivreg2`. Both are valid but stored differently.

### Learnings from Replication Package 3: SEC Comment Letters (mnsc.2021.4259)

- [LEARN] 2026-02-25: Event study / CAR computation uses log-return formulation: `CAR = exp(sum(log(1+R_stock))) - exp(sum(log(1+R_market)))`. This avoids compounding errors vs simple return summation.
- [LEARN] 2026-02-25: Event study windowing pattern: pre-event benchmark [-30,-16], pre-event [-15,-1] and [-5,-1], event [0,+5] and [0,+15]. Excess measures = event_window - benchmark.
- [LEARN] 2026-02-25: SAS day-ID mapping pattern: create continuous day numbering from DSI data (`day_id = _n_`) for efficient event-date matching via inequalities.
- [LEARN] 2026-02-25: Cross-sectional OLS with absorbed FE: `areg Y X controls fyear_dummies, absorb(industry_fe) cluster(firm_id)` — common in accounting/finance papers.
- [LEARN] 2026-02-25: SAS winsorization pattern: PROC MEANS for percentiles by group, then data step caps. Unlike Stata `winsor2`, SAS requires manual implementation.
- [LEARN] 2026-02-25: Package provides both .sas7bdat and .dta for the final regression dataset — dual-format distribution enables cross-validation.
- [SKILL-UPDATE] 2026-02-25: `/data-describe` — Confirmed .sas7bdat support pattern. Package 3 has 8 .sas7bdat files alongside 1 .dta file.

### Learnings from Replication Package 4: Bond Market Liquidity (mnsc.2022.4646)

- [LEARN] 2026-02-25: R `lfe::felm()` formula syntax: `y ~ X | fe1 + fe2 + fe3 | 0 | cluster1 + cluster2`. Part 3 = IVs (0 = none), Part 4 = clustering variables.
- [LEARN] 2026-02-25: Multi-way clustering in R via `felm()` native syntax (e.g., `| cusip + date`) or via `multiwayvcov::cluster.vcov(lm_obj, cbind(var1, var2))`.
- [LEARN] 2026-02-25: Network centrality as regressor: `igraph::eigen_centrality()` on interdealer network graph, computed year-by-year, merged as `dlr_egcent_100`.
- [LEARN] 2026-02-25: R standardization pattern for panel regression: `mutate_at(vars, ~(.x - mean(.x, na.rm=T)) / sd(.x, na.rm=T))` within subgroups.
- [LEARN] 2026-02-25: SAS HASH objects for LIFO inventory tracking in trade classification — advanced SAS pattern for sequential record processing.
- [LEARN] 2026-02-25: Amihud illiquidity measure computation: `ami = abs(ret) / volume` where `ret = (prc - lag_prc) / lag_prc`.
- [SKILL-UPDATE] 2026-02-25: `/cross-check` — Added R `lfe::felm()` formula syntax documentation for R-based cross-validation.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Multi-way clustering confirmed: Stata `vce(cluster var1 var2)`, R `felm(... | 0 | cluster1 + cluster2)`.

### Deep Skill Updates from Replication Package 1 (DDCG) — Advanced Stata Patterns

- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added complete `vareffects` program: nlcom chain for computing cumulative impulse response functions (25-year dynamic effects) in panels with lagged dependent variables. Includes recursion formula: `effect_j = sum_{k=1}^{P} effect_{j-k} * lag_k + shortrun`.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added complete `helm` program: Helmert / forward orthogonal deviation transformation implementation. Formula: `h_x = sqrt(n/(n+1)) * (x_t - forward_mean_t)`. Used as alternative to first-differencing for GMM.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added HHK minimum distance estimator pattern: year-by-year k-class IV on Helmert-transformed data, pooled via inverse-variance weighting, with bootstrap SEs.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added k-class estimation via `ivreg2 ... , k(lambda)` where `lambda = 1 + e(sargandf)/e(N)`.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added `bootstrap _b, cluster() idcluster()` pattern for panel cluster bootstrap (idcluster required for resampling with replacement).
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added `gen sample = e(sample)` pattern for consistent samples across specifications.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added interaction heterogeneity with percentile centering: `gen inter = dem * (gdp1960 - r(p25))`.
- [SKILL-UPDATE] 2026-02-25: `/run-panel` — Added matrix operations for custom estimators: `matrix def J()`, `inv(V)`, `ereturn post b V, obs() esample()`.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added multiple endogenous with interaction terms: `(dem inter = l(1/4).demreg l(1/4).intereg)`.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added k-class estimation section with `ivreg2 ... , k(lambda)` pattern.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added spatial lags via `spmat idistance` + `spmat lag` for constructing spatially-lagged instruments.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added bootstrap IV inference with `cluster()` + `idcluster()` for panel bootstrap.
- [SKILL-UPDATE] 2026-02-25: `/run-iv` — Added consistent sample pattern: `gen samp = e(sample)` after each `xtivreg2` call.
- [SKILL-UPDATE] 2026-02-25: `/make-table` — Added nested `\input{}` LaTeX table pattern: main table + `_Add.tex` subsidiary with impulse response rows.
- [SKILL-UPDATE] 2026-02-25: `/make-table` — Added `#delimit ;` syntax for complex estout commands.
- [SKILL-UPDATE] 2026-02-25: `/make-table` — Added `stardrop()` option documentation.
- [SKILL-UPDATE] 2026-02-25: `/make-table` — Added multi-estimator layout (FE/GMM/HHK × 4 lag specs = 12 columns).
- [SKILL-UPDATE] 2026-02-25: `/make-table` — Added auxiliary p-value file pattern via `file open/write/close`.

### Learnings from New Replication Packages (jvae023 & data_programs)

- [LEARN] 2026-02-25: jvae023 (Abman, Lundberg & Ruta, JEEA 2024 — RTAs & Environment) uses R `glmnet::cv.glmnet(x, y, family="binomial", nfolds=50)` for LASSO propensity score estimation, then 1:1 nearest-neighbor matching on LASSO P-score, then DiD event study on matched panel via `lfe::felm()`. This is the LASSO-for-matching workflow (not LASSO for coefficient selection).
- [LEARN] 2026-02-25: jvae023 uses `lambda.min` vs `lambda.1se` selection in `cv.glmnet` — `lambda.min` minimizes CV error, `lambda.1se` gives more parsimonious model. For propensity score matching, `lambda.min` is preferred (want accurate P-score).
- [LEARN] 2026-02-25: jvae023 IHS transformation: `ihs <- function(x) log(x + sqrt(x^2 + 1))` — inverse hyperbolic sine. Better than `log(1+x)` for near-zero outcomes (deforestation, trade flows). Symmetric around 0, approximates log for large x.
- [LEARN] 2026-02-25: jvae023 custom clustered SE for matched samples: `cluster_se_match()` function accounts for cross-cluster correlation via shared RTA membership matrix. Standard `vce(cluster)` underestimates SE when matched pairs share cluster membership (e.g., bilateral trade agreements).
- [LEARN] 2026-02-25: data_programs (Culture & Development, Stata) uses compact bootstrap prefix: `eststo: bs, reps(500): reg y x, cluster(c)`. This is different from `bootstrap _b, reps(): command` — `bs` is shorthand and works inside `eststo` chains. Cannot use `idcluster()` option with `bs` (use full `bootstrap` command for panel resampling).
- [LEARN] 2026-02-25: data_programs uses `areg Y X, a(MATCH_FE) cluster(C)` for matched-pair fixed effects. The `a()` option in `areg` absorbs one FE dimension (pre-`reghdfe` pattern). Equivalent to `reghdfe Y X, absorb(MATCH_FE) vce(cluster C)`.
- [LEARN] 2026-02-25: data_programs (Culture & Development) uses contiguous-pairs design: `keep if geodist<=500` restricts sample to ethnographic groups within 500km of each other. Geographic distance restriction controls for confounders that vary across space.
- [DECISION] 2026-02-25: Advanced Stata patterns (impulse response, Helmert, HHK, k-class, bootstrap, spatial lags) extracted to non-user-invocable reference file `advanced-stata-patterns.md` rather than kept inline in run-*.md skills. Reduces file size and keeps skill files focused.
- [LEARN] 2026-02-25: Discovered 6 additional replication packages beyond original 4: Mexico Retail full (Replication.zip), RTAs & Environment (jvae023), Culture & Development (data_programs.zip), APE 0119/0185/0439.
- [LEARN] 2026-02-25: No lasso/regularization found in any Stata replication package. LASSO is implemented in R (glmnet) in published applied micro — when authors use LASSO at all.
- [SKILL-UPDATE] 2026-02-25: `/run-lasso` — Added Step 7: R `glmnet` LASSO propensity score matching pipeline (jvae023 pattern): cv.glmnet → predict P-score → nearest-neighbor match → felm() DiD on matched panel. Also added IHS transformation and custom matched-sample SE note.
- [SKILL-UPDATE] 2026-02-25: `/run-bootstrap` — Added compact `bs, reps(N): command` prefix syntax (data_programs pattern). Documented difference from full `bootstrap _b, reps() cluster() idcluster():` syntax.

---

## Session Log

<!-- Add a brief summary at the end of each Claude Code session -->

| Date | Session Summary |
|---|---|
| 2026-02-25 | Initial test suite run (5 tests). Identified 10 issues across DID, RDD, IV, Panel tests. All tests passing after fixes. Created ISSUES_LOG.md. |
| 2026-02-25 | Phase 1 implementation: added 6 adversarial agents, 5 new skills, quality scorer, README, ROADMAP. Activated MEMORY.md. |
| 2026-02-25 | Replication stress test: Ran 4 packages through workflow. Package 1 (DDCG, JPE 2019): full end-to-end success — Panel FE, GMM, IV all ran, cross-validation PASS (0.000% diff). Package 2 (Mexico Retail): project created but data prep blocked by missing Economic Census input data — code patterns extracted. Package 3 (SEC Comment Letters): read-only — event study/CAR patterns, SAS pipeline, areg regression extracted. Package 4 (Bond Market Liquidity): read-only — R lfe::felm patterns, multi-way clustering, network centrality extracted. Updated 4 skills (/run-panel, /run-iv, /data-describe, /cross-check) with 18 [SKILL-UPDATE] entries. Test suite verified (test3, test4 still pass). |
| 2026-02-25 | Deep skill update from DDCG replication code: Added 18 advanced Stata patterns to 3 skills (/run-panel, /run-iv, /make-table). Key additions: complete `vareffects` nlcom impulse response program, `helm` Helmert transformation program, HHK minimum distance estimator with k-class estimation, bootstrap with cluster/idcluster, nested `\input{}` LaTeX tables, `#delimit ;` estout, spatial lags via spmat, interaction heterogeneity with percentile centering, matrix operations for custom estimators. Test suite verified (test3-iv, test4-panel still pass with 0 errors). |
| 2026-02-25 | Skill consolidation: Extracted advanced patterns from run-panel.md (665→371 lines) and run-iv.md (528→323 lines) into new advanced-stata-patterns.md (443 lines, non-user-invocable). Compressed Stata execution blocks in all 5 run-* files. Removed duplicate package list from run-iv.md. Total: 2,175→2,083 lines (-92 net). |
| 2026-02-25 | Created 4 new standalone skills: /run-bootstrap (pairs/wild/residual/teffects bootstrap), /run-placebo (timing/outcome/instrument/permutation placebos), /run-logit-probit (logit/probit/propensity/teffects/clogit), /run-lasso (LASSO/post-double-selection/rigorous LASSO/glmnet matching). Extracted jvae023 and data_programs.zip — found R glmnet LASSO P-score matching and compact bs prefix syntax. Updated run-lasso.md and run-bootstrap.md with new patterns. Total skills: 28 user-invocable + 1 reference. |
