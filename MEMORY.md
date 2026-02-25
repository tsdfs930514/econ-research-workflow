# MEMORY.md - Cross-Session Learning
# This file persists knowledge across Claude Code sessions.
# Update it as the project evolves to maintain continuity.

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
