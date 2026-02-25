# Econ Research Workflow - Quick Reference

## Skills Reference

| Command | Description | Typical Use |
|---------|-------------|-------------|
| `/init-project` | Initialize project structure | Start of project |
| `/data-describe` | Descriptive statistics | After data cleaning |
| `/run-did` | DID/TWFE/CS analysis | Causal estimation |
| `/run-iv` | IV/2SLS analysis | Causal estimation |
| `/run-rdd` | RDD analysis | Causal estimation |
| `/run-panel` | Panel FE/GMM analysis | Causal estimation |
| `/cross-check` | Stata<->Python validation | After any regression |
| `/robustness` | Robustness test suite | After main results |
| `/make-table` | LaTeX tables | Before paper writing |
| `/write-section` | Write paper section | Paper drafting |
| `/review-paper` | Simulated peer review | Before submission |
| `/lit-review` | Literature review | Early stage / revision |

---

## Agents Reference

| Agent | Role |
|-------|------|
| `econometrics-reviewer` | Checks identification strategy and estimation |
| `code-reviewer` | Reviews Stata/Python code quality |
| `paper-reviewer` | Simulates journal referee |
| `tables-reviewer` | Checks table formatting and compliance |
| `robustness-checker` | Suggests missing robustness tests |
| `cross-checker` | Compares Stata vs Python results |

---

## Typical Workflow Sequences

### Full Paper Pipeline
```
/init-project
  -> /data-describe
  -> /run-{method}
  -> /cross-check
  -> /robustness
  -> /make-table
  -> /write-section
  -> /review-paper
```

### Quick Regression Check
```
/run-{method} -> /cross-check -> /make-table
```

### Revision Response
```
/robustness -> /make-table -> /write-section -> /review-paper
```

### Literature Deep-Dive
```
/lit-review -> /write-section (Literature Review)
```

---

## Quality Scoring

| Score | Meaning |
|-------|---------|
| >= 95 | Publication ready |
| >= 90 | Minor revisions needed |
| >= 80 | Major revisions needed |
| < 80 | Significant redo required |

Scores are assigned by review agents across dimensions: identification, robustness, code quality, presentation.

---

## Key Conventions

### File Paths
- Raw data (READ-ONLY): `vN/data/raw/`
- Cleaned data: `vN/data/cleaned/`
- Stata code: `vN/code/stata/`
- Python code: `vN/code/python/`
- All output: `vN/output/`
- Tables: `vN/output/tables/`
- Figures: `vN/output/figures/`
- Paper: `vN/paper/`

### Stata Execution (Git Bash)
```bash
"D:\Stata18\StataMP-64.exe" -e do "code/stata/script.do"
```
- **必须用 `-e`**（自动退出），**禁止用 `-b`**（需手动确认）或 **`/e`**（Git Bash 路径冲突）
- Always check the `.log` file after every Stata run
- Non-zero exit or `r(xxx)` in log = failure

### Versioning
- Each major revision lives in its own `vN/` directory
- `_VERSION_INFO.md` tracks version metadata
- `docs/CHANGELOG.md` tracks project-level changes

### Naming Conventions
- Stata do-files: `01_clean_data.do`, `02_desc_stats.do`, `03_reg_main.do`, ...
- Output tables: `tab_main_results.tex`, `tab_robustness.tex`, ...
- Output figures: `fig_event_study.pdf`, `fig_parallel_trends.pdf`, ...

---

## Common Patterns

### Adding a Robustness Check
1. Run `/robustness` to get suggestions
2. Implement suggested checks in `04_robustness.do`
3. Run `/cross-check` to validate
4. Run `/make-table` to format results

### Responding to Referee Comments
1. Create new version directory `vN+1/`
2. Copy and modify relevant code
3. Run `/robustness` for additional tests
4. Run `/make-table` for updated tables
5. Run `/write-section` for response letter
6. Run `/review-paper` to self-check

### Cross-Validation Workflow
1. Run regression in Stata via `/run-{method}`
2. Run `/cross-check` to replicate in Python
3. Review coefficient comparison table
4. Tolerance: coefficients within 1%, SEs within 5%

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Stata log shows error | Read full log, fix do-file, re-run |
| Cross-check mismatch | Check clustering, sample restrictions, variable definitions |
| LaTeX table won't compile | Check `\input{}` paths, missing packages |
| Version conflict | Always work in latest `vN/` directory |
