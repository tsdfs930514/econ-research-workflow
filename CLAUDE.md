# CLAUDE.md - Project Configuration
# This file is loaded at the start of every Claude Code session.
# Fill in template fields marked with [PLACEHOLDER] for your project.

---

## Project Identity

- **Project Name**: [PROJECT_NAME]
- **Institution**: [INSTITUTION_NAME]
- **Researcher(s)**: [RESEARCHER_NAMES]
- **Current Version**: v1
- **Created**: [DATE]
- **Last Updated**: [DATE]

---

## Active Version

The current working version is **v1/**. All new code, output, and analysis
should be placed under this version directory unless migrating to a new version.

When creating a new version (e.g., v2/), copy the directory structure from the
previous version and update this field.

---

## Directory Convention

Raw data is stored at the project root level, shared across all versions:

```
data/
  raw/                    # Original, unmodified data (READ-ONLY, shared across versions)
```

Each version follows the structure:

```
vN/
  _VERSION_INFO.md        # Version metadata
  code/
    stata/                # .do files
    python/               # .py files
    sas/                  # .sas files (if needed)
  data/
    clean/                # Cleaned and constructed datasets
    temp/                 # Intermediate/temporary data
  output/
    tables/               # LaTeX tables (.tex)
    figures/              # Figures (.pdf/.png)
    logs/                 # Stata .log / Python output
  paper/
    main_cn.tex           # Chinese paper
    main_en.tex           # English paper
    sections/             # Section .tex files
    bib/                  # BibTeX files
```

---

## Stata Configuration

- **Executable Path**: `D:\Stata18\StataMP-64.exe`
- **Execution Command** (auto-approved wrapper):
  ```bash
  bash .claude/scripts/run-stata.sh "<project_dir>" "<do_file>"
  ```
- **Example**:
  ```bash
  bash .claude/scripts/run-stata.sh "F:/Learning/econ-research-workflow/tests/test1-did/v1" "code/stata/01_did_analysis.do"
  ```
- **Flag notes**:
  - The wrapper uses `-e` (auto-exit) internally
  - `-b` and `/e` are forbidden (see original rationale)
  - Log checking is built into the wrapper — no manual `tail` needed
- **Fallback** (if wrapper unavailable):
  ```bash
  cd "<project_dir>"
  "D:\Stata18\StataMP-64.exe" -e do "<do_file>"
  ```

---

## Python Configuration

- **Core Packages**:
  - `pyfixest` -- Fixed-effects regression and inference
  - `pandas` -- Data manipulation and analysis
  - `polars` -- High-performance DataFrame library
  - `matplotlib` -- Plotting and visualization
  - `stargazer` -- Regression table formatting
  - `csmarapi` -- CSMAR (国泰安) database API client

- **Regression Cross-Validation**:
  Use `feols()` from `pyfixest` to cross-validate Stata regression results:
  ```python
  import pyfixest as pf
  result = pf.feols("y ~ x1 + x2 | fe1 + fe2", data=df)
  result.summary()
  ```

- **CSMAR Data Access**:
  Use `csmarapi` to fetch Chinese stock market and accounting data from CSMAR (国泰安):
  ```python
  from csmarapi import CsmarService
  csmar = CsmarService()
  csmar.login(account, password)
  df = csmar.query(tableName="TRD_Dalyr", columns="Stkcd,Trddt,Dretwd", condition="Stkcd = '000001'")
  ```
  See `/fetch-csmar` for the full workflow with auto-pagination, provenance tracking, and standardized file naming.

---

## Code Naming Conventions

All scripts use a numbered prefix to indicate execution order.

**Stata (.do files)**:
```
01_clean_data.do
02_desc_stats.do
03_reg_main.do
04_reg_robust.do
05_tables_export.do
06_figures.do
```

**Python (.py files)**:
```
01_clean_data.py
02_desc_stats.py
03_reg_crossval.py
04_figures.py
```

- Prefix numbers define the execution order within a version.
- Use descriptive names after the number prefix.
- Keep Stata and Python scripts in the same `code/` directory.

---

## Skills Quick Reference

| Skill | Description |
|---|---|
| `/init-project` | Initialize a new research project with standardized directory structure |
| `/data-describe` | Generate descriptive statistics and variable distributions (Stata + Python) |
| `/run-did` | Run complete DID/TWFE/Callaway-Sant'Anna analysis pipeline (see `/run-sdid` for Synthetic DID) |
| `/run-iv` | Run complete IV/2SLS analysis pipeline with diagnostics |
| `/run-rdd` | Run complete RDD analysis pipeline with all diagnostics |
| `/run-panel` | Run complete Panel FE/RE/GMM analysis pipeline |
| `/run-sdid` | Run Synthetic DID analysis with unit/time weights and inference |
| `/cross-check` | Cross-validate regression results between Stata, Python pyfixest, and R fixest |
| `/robustness` | Run robustness test suite for baseline regression results — alternative specs, subsamples, clustering, Oster bounds, wild bootstrap |
| `/make-table` | Generate publication-quality LaTeX regression tables |
| `/write-section` | Write a specific paper section in Chinese or English |
| `/review-paper` | Simulate peer review with three reviewers giving structured feedback; optional APE-style multi-round deep review |
| `/lit-review` | Generate structured literature review with BibTeX entries |
| `/adversarial-review` | Run adversarial critic-fixer QA loop (code, econometrics, tables) |
| `/score` | Run executable quality scorer (6 dimensions, 100 pts) on current version |
| `/commit` | Smart git commit with type prefix and data safety warnings |
| `/compile-latex` | Compile LaTeX paper with pdflatex/bibtex and error checking |
| `/context-status` | Display current version, recent decisions, quality scores, git state |
| `/explore` | Set up exploration sandbox with relaxed quality thresholds (>= 60) for quick hypothesis testing and alternative specifications |
| `/promote` | Graduate exploratory files from explore/ sandbox to main vN/ pipeline with renumbering and quality check |
| `/session-log` | Session start/end manager — load context, record decisions and learnings |
| `/interview-me` | Bilingual Socratic research interview — formalizes ideas into structured proposals |
| `/devils-advocate` | Pre-analysis identification strategy challenger — threat assessment, not code fixes |
| `/learn` | Create new rules or skills from within a session (constitution-guarded) |
| `/run-bootstrap` | Run bootstrap & resampling inference pipeline (pairs, wild cluster, residual, teffects) |
| `/run-placebo` | Run placebo tests & randomization inference pipeline (timing, outcome, instrument, permutation) |
| `/run-logit-probit` | Run logit/probit, propensity score, treatment effects (RA/IPW/AIPW), and conditional logit pipeline |
| `/run-lasso` | Run LASSO, post-double-selection, and regularized regression pipeline for variable selection and causal inference |
| `/run-pipeline` | Auto-detect methods from research plan and orchestrate full skill pipeline end-to-end |
| `/synthesis-report` | Collect all analysis outputs and generate structured synthesis report (Markdown + LaTeX) |
| `/translate` | Translate academic economics papers between Chinese and English with journal-specific conventions |
| `/polish` | Polish academic papers — English/Chinese polish, refinement, condensing, and expanding (5 sub-modes) |
| `/de-ai` | Detect and remove AI-generated writing patterns to produce natural, human-like academic prose |
| `/fetch-csmar` | Browse CSMAR databases and fetch Chinese stock market & accounting data via Python API |
| `/logic-check` | Final-pass logic check for paper drafts — catches only critical errors, not style preferences |

---

## Hooks

4 lifecycle hooks are configured in `.claude/settings.json`:

| Hook | Event | Action |
|------|-------|--------|
| Session-start loader | `SessionStart` | Reads MEMORY.md, displays recent entries, last session, and last quality score |
| Pre-compact save | `PreCompact` | Prompts Claude to append a session summary to MEMORY.md before context compaction |
| Post-Stata log check | `PostToolUse` (Bash) | Parses `.log` files for `r(xxx)` errors after Stata execution |
| Raw data guard | `PostToolUse` (Bash) | Compares `data/raw/` file snapshots to detect unauthorized modifications (catches Python/R script bypass) |

Hook scripts are located in `.claude/hooks/`:
- `session-loader.py` — session start context loader
- `stata-log-check.py` — automatic Stata error detection
- `raw-data-guard.py` — data/raw integrity monitor (defence layer 2)

### Always-On Rules

4 always-on rules (loaded in every session, no path scope):

| Rule | Purpose |
|------|---------|
| `constitution.md` | 5 immutable principles governing all workflow components |
| `orchestrator-protocol.md` | Spec-Plan-Implement-Verify-Review-Fix-Score task cycle |
| `stata-error-verification.md` | Mandatory hook output reading before re-running Stata scripts |
| `bash-conventions.md` | No chained commands (`&&`, `||`, `;`); use separate tool calls and absolute paths |

### Permissions & Security

The permission system uses a **allow-all + deny-list** model configured in `.claude/settings.json`:

**Allow** (in `settings.local.json`, gitignored, personal):

By default, forked repos prompt for every operation. To skip prompts, copy the template:
```
cp .claude/settings.local.json.example .claude/settings.local.json
```
This adds `Read`, `Edit`, `Write`, `Bash` to the allow list locally.

**Deny** (in `settings.json`, shared, everyone gets these — 3 categories):

| Category | Rules | Purpose |
|----------|-------|---------|
| Raw data protection | `Edit/Write(data/raw/**)`, `Bash(*rm/mv/cd*data/raw*)` | Constitution Principle 1 |
| Destructive operations | `Bash(*rm -rf /*)`, `Bash(*git push*--force*)`, `Bash(*git reset --hard*)` | Prevent irreversible damage |
| Credential & infrastructure | `Read/Edit/Write(*.env)`, `Read/Edit/Write(*.credentials*)`, `Edit/Write(.claude/hooks/**)`, `Edit/Write(.claude/scripts/**)`, `Edit/Write(.claude/settings.json)` | Protect secrets and workflow infrastructure |

**Defence-in-depth architecture**:

| Layer | Mechanism | What It Catches |
|-------|-----------|----------------|
| 1 | `deny` rules | Claude tool-level misoperations (string matching) |
| 2 | `raw-data-guard.py` hook | Python/R scripts that modify `data/raw/` via OS calls |
| 3 | `attrib +R` (OS-level) | Everything — must be set manually per project |
| 4 | Constitution + rules | Behavioural constraints (Claude should follow, not enforced) |

---

## Personal Preferences

Machine-specific preferences (Stata path, editor, directories) are stored in `personal-memory.md` at the project root. This file is **gitignored** and not shared via version control. Copy the template and fill in your local settings.

---

## Quality Thresholds (Sant'Anna Scoring System)

All deliverables are scored on a 0-100 scale:

| Score | Rating | Action |
|---|---|---|
| >= 95 | Publication Ready | No further changes needed |
| >= 90 | Minor Revisions | Address small issues before submission |
| >= 80 | Major Revisions | Significant rework required |
| < 80 | Redo | Fundamental problems; start section over |

Scoring criteria include: methodological rigor, code correctness, output
formatting, robustness of results, and clarity of exposition.

Use `/adversarial-review` for automated multi-round quality assurance with
critic-fixer separation. Use `/score` for quantitative scoring.

---

## Quality Scoring

The executable quality scorer (`scripts/quality_scorer.py`) evaluates projects on 6 dimensions:

| Dimension | Points | Key Checks |
|-----------|--------|------------|
| Code Conventions | 15 | .do headers, `set seed`, numbered naming, log pattern, `vce(cluster)` |
| Log Cleanliness | 15 | No `r(xxx)` errors, no `variable not found`, no `command not found` |
| Output Completeness | 15 | Tables (.tex), figures (.pdf/.png), and logs exist and are non-empty |
| Cross-Validation | 15 | Python script exists, coefficient comparison, pass/fail threshold |
| Documentation | 15 | REPLICATION.md with content, _VERSION_INFO.md, data sources documented |
| Method Diagnostics | 25 | Auto-detected: DID pre-trends, IV first-stage F, RDD density test, Panel Hausman |

Run via: `python scripts/quality_scorer.py v1/` or use the `/score` skill.

---

## Data Safety Rules

1. **`data/raw/` is READ-ONLY.** Never modify, overwrite, or delete raw data files. Raw data lives at the project root level (`data/raw/`), shared across all versions.
2. All data transformations must read from `data/raw/` and write to `data/clean/` or `data/temp/` within the version directory.
3. Cleaning scripts must document every transformation applied.
4. Keep a record of the original data source and download date in `docs/`.
5. Before any destructive operation, confirm the target is NOT in `data/raw/`.

---

## Paper Formats

4 output styles supported via `/write-section` and `/init-project`:

| Format | Template | Use Case |
|--------|----------|----------|
| Chinese journals | `main_cn.tex` | 经济研究, 管理世界, 经济学季刊 submissions |
| English TOP5 | `main_en.tex` | AER, QJE, JPE, Econometrica, REStud submissions |
| NBER Working Paper | `main_nber.tex` | NBER WP series with JEL codes, acknowledgments, extended appendices |
| SSRN Preprint | `main_ssrn.tex` | Rapid dissemination, "draft — comments welcome" format |

---

## Output Standards

### Numerical Formatting
- **Coefficients**: 3 decimal places by default (e.g., `0.123`); 4 decimal places for TOP5/AER causal inference tables (see `/make-table`)
- **Standard Errors**: 3 decimal places by default, in parentheses (e.g., `(0.045)`); 4 for TOP5/AER
- **Significance Stars**: `*** p<0.01`, `** p<0.05`, `* p<0.10`
- **R-squared**: 3 decimal places
- **Observations**: Comma-separated integers (e.g., `12,345`)

### Table Standards
- Include dependent variable name in column headers.
- Report number of observations and R-squared in every table.
- Note fixed effects and clustering in table footer.
- Use consistent column ordering across related tables.

### Figure Standards
- Label all axes with variable names and units.
- Include titles and source notes.
- Use high-resolution export (300+ DPI for raster, vector preferred).
- Consistent color scheme across all figures in a version.
