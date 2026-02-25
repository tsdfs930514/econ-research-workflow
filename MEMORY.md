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

---

## Session Log

<!-- Add a brief summary at the end of each Claude Code session -->

| Date | Session Summary |
|---|---|
| 2026-02-25 | Initial test suite run (5 tests). Identified 10 issues across DID, RDD, IV, Panel tests. All tests passing after fixes. Created ISSUES_LOG.md. |
| 2026-02-25 | Phase 1 implementation: added 6 adversarial agents, 5 new skills, quality scorer, README, ROADMAP. Activated MEMORY.md. |
