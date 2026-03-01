# Econ Research Workflow

A Claude Code-powered template for reproducible economics research, featuring automated Stata/Python pipelines, adversarial quality assurance, and cross-validation infrastructure.

Inspired by [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow).

---

## Features

- **34 skills** — slash-command workflows covering the full research lifecycle (data cleaning, DID/IV/RDD/Panel/SDID/Bootstrap/Placebo/Logit-Probit/LASSO estimation, cross-validation, tables, paper writing, translation, polishing, de-AI rewriting, logic checking, review, pipeline orchestration, synthesis reporting, exploration sandbox, session continuity, Socratic research tools, and self-extension)
- **12 agents** — specialized reviewers plus 3 adversarial critic-fixer pairs (code, econometrics, tables) enforcing separation of concerns
- **7 rules** — 4 path-scoped coding/econometrics conventions + 3 always-on (constitution, orchestrator protocol, Stata error verification)
- **3 lifecycle hooks** — automatic session context loading, pre-compaction memory save, and post-Stata error detection
- **Adversarial QA loop** — `/adversarial-review` runs critic → fixer → re-critic cycles (up to 5 rounds) until quality score >= 95
- **Executable quality scorer** — `quality_scorer.py` scores projects on 6 dimensions (100 pts), including method-specific diagnostics auto-detected from .do files
- **Exploration sandbox** — `/explore` for hypothesis testing with relaxed thresholds; `/promote` to graduate results to the main pipeline
- **Stata + Python/R cross-validation** — every regression is verified across languages via `pyfixest` and R `fixest`
- **Multi-format output** — Chinese journals (经济研究/管理世界), English TOP5 (AER/QJE), NBER Working Paper, and SSRN preprint styles
- **Version-controlled analysis** — `v1/`, `v2/`, ... directory structure with full replication packages
- **Session continuity** — `/session-log` for explicit session management with MEMORY.md integration

---

## How It Works

This repository is a **project-level template**. The `.claude/` directory contains all skills, agents, and rules — Claude Code automatically loads them when you run `claude` inside the project directory. Nothing is installed globally.

You can use it in two ways:

- **As a full project template** — fork it to start a new research project with the complete workflow
- **Cherry-pick individual skills** — copy specific `.claude/skills/*.md` files into your own project's `.claude/skills/` directory

## Quick Start

### 1. Fork and clone

```bash
# Fork this repo on GitHub, then:
git clone https://github.com/<your-username>/econ-research-workflow.git
cd econ-research-workflow
```

### 2. Install prerequisites

| Software | Version | Purpose |
|----------|---------|---------|
| **Stata** | 18 (MP recommended) | All econometric estimation |
| **Python** | 3.10+ | Cross-validation (`pyfixest`, `pandas`, `numpy`) |
| **Claude Code** | Latest | CLI tool — install from [claude.com/claude-code](https://claude.com/claude-code) |
| **Git Bash** (Windows) | — | Shell environment for Stata execution |
| **LaTeX** | Optional | `/compile-latex` paper compilation (pdflatex + bibtex) |

```bash
pip install pyfixest pandas numpy polars matplotlib stargazer
```

### 3. Configure

Open `CLAUDE.md` and fill in the `[PLACEHOLDER]` fields:
- `[PROJECT_NAME]` — your research project name
- `[INSTITUTION_NAME]` — your institution
- `[RESEARCHER_NAMES]` — researcher name(s)
- `[DATE]` — creation date
- Update the Stata executable path to match your local installation

### 4. Launch Claude Code and start working

```bash
# Start Claude Code in the project directory
claude

# Initialize a new research project (creates v1/ directory structure)
/init-project
```

Place raw data in `v1/data/raw/`, then run your analysis:

```bash
/data-describe → /run-did (or /run-iv, /run-rdd, /run-panel)
    → /cross-check → /make-table → /adversarial-review → /score
```

---

## Skills Reference

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/init-project` | Start a new project | Initialize standardized directory structure with master.do, REPLICATION.md, templates |
| `/data-describe` | Explore data | Generate descriptive statistics and variable distributions (Stata + Python) |
| `/run-did` | DID analysis | Full DID/TWFE/Callaway-Sant'Anna pipeline with diagnostics |
| `/run-iv` | IV analysis | Complete IV/2SLS pipeline with first-stage, weak-instrument tests, LIML comparison |
| `/run-rdd` | RDD analysis | Complete RDD pipeline with bandwidth sensitivity, density test, placebo cutoffs |
| `/run-panel` | Panel analysis | Panel FE/RE/GMM pipeline with Hausman, serial correlation, CD tests |
| `/cross-check` | Validate results | Cross-validate Stata vs Python/R regression results (target: < 0.1% coefficient diff) |
| `/robustness` | Robustness tests | Robustness test suite for baseline regression results — alternative specs, subsamples, clustering, Oster bounds, wild bootstrap |
| `/make-table` | Format tables | Generate publication-quality LaTeX regression tables (AER or 三线表 style) |
| `/write-section` | Draft paper | Write a paper section in Chinese or English following journal conventions |
| `/review-paper` | Simulate review | Three simulated peer reviewers with structured feedback; optional APE-style multi-round deep review |
| `/lit-review` | Literature review | Structured literature review with BibTeX entries |
| `/adversarial-review` | Quality assurance | Adversarial critic-fixer loop across code, econometrics, and tables domains |
| `/score` | Quality scoring | Run executable quality scorer (6 dimensions, 100 pts) on current version |
| `/commit` | Git commit | Smart commit with type prefix, data safety warnings, auto-generated message |
| `/compile-latex` | Compile paper | Run pdflatex/bibtex pipeline with error checking |
| `/context-status` | Session context | Display current version, recent decisions, quality scores, git state |
| `/run-sdid` | SDID analysis | Synthetic DID analysis with unit/time weights and inference |
| `/run-bootstrap` | Bootstrap inference | Pairs, wild cluster, residual, and teffects bootstrap pipelines |
| `/run-placebo` | Placebo tests | Timing, outcome, instrument, and permutation placebo test pipelines |
| `/run-logit-probit` | Logit/Probit analysis | Logit/probit, propensity score, treatment effects (RA/IPW/AIPW), conditional logit |
| `/run-lasso` | LASSO/regularization | LASSO, post-double-selection, rigorous LASSO, R `glmnet` matching pipeline |
| `/explore` | Exploration sandbox | Set up `explore/` directory with relaxed quality thresholds (>= 60) for quick hypothesis testing and alternative specifications |
| `/promote` | Promote results | Graduate exploratory files from `explore/` sandbox to main `vN/` pipeline with renumbering and quality check |
| `/session-log` | Session continuity | Start/end sessions with MEMORY.md context loading and recording |
| `/interview-me` | Research ideation | Bilingual Socratic interview to formalize research ideas into structured proposals |
| `/devils-advocate` | Strategy challenge | Pre-analysis threat assessment for identification strategy (threats, alternatives, falsification) |
| `/learn` | Self-extension | Create new rules or skills from within a session, with constitution guard |
| `/run-pipeline` | Orchestrate pipeline | Auto-detect methods from research plan and run full skill sequence end-to-end |
| `/synthesis-report` | Generate report | Collect all outputs into structured synthesis report (Markdown + LaTeX) |
| `/translate` | Translate paper | Translate academic papers between Chinese and English with journal-specific conventions |
| `/polish` | Polish paper | English/Chinese polish, refinement, condensing, and expanding (5 sub-modes) |
| `/de-ai` | Remove AI patterns | Detect and remove AI-generated writing patterns for natural academic prose |
| `/logic-check` | Logic check | Final-pass red-line check — catches only critical errors, not style preferences |

---

## Agents Reference

| Agent | Role | Tools |
|-------|------|-------|
| `code-reviewer` | ~~Code quality evaluation~~ **(DEPRECATED — use `code-critic`)** | Read-only |
| `econometrics-reviewer` | ~~Identification strategy review~~ **(DEPRECATED — use `econometrics-critic`)** | Read-only |
| `tables-reviewer` | ~~Table formatting review~~ **(DEPRECATED — use `tables-critic`)** | Read-only |
| `robustness-checker` | Missing robustness checks and sensitivity analysis | Read-only |
| `paper-reviewer` | Full paper review simulating peer referees | Read-only |
| `cross-checker` | Stata vs Python cross-validation | Read + Bash |
| `code-critic` | Adversarial code review (conventions, safety, defensive programming) | Read-only |
| `code-fixer` | Implements fixes from code-critic findings | Full access |
| `econometrics-critic` | Adversarial econometrics review (diagnostics, identification, robustness) | Read-only |
| `econometrics-fixer` | Implements fixes from econometrics-critic findings | Full access |
| `tables-critic` | Adversarial table review (format, stars, reporting completeness) | Read-only |
| `tables-fixer` | Implements fixes from tables-critic findings | Full access |

---

## Typical Workflow Sequences

### Full Paper Pipeline

```
/init-project → /data-describe → /run-did → /cross-check → /robustness
    → /make-table → /write-section → /review-paper → /adversarial-review
    → /score → /synthesis-report → /compile-latex → /commit
```

### Automated Pipeline (single command)

```
/run-pipeline  →  auto-detects method  →  runs full sequence  →  /synthesis-report
```

### Quick Check (single regression)

```
/run-{method} → /cross-check → /score
```

Supported methods: `did`, `iv`, `rdd`, `panel`, `sdid`, `bootstrap`, `placebo`, `logit-probit`, `lasso`

### Research Ideation

```
/interview-me → /devils-advocate → /data-describe → /run-{method}
```

### Paper Writing & Editing

```
/write-section → /polish → /de-ai → /logic-check → /compile-latex
```

For translation: `/translate` (CN→EN or EN→CN with journal-specific conventions)

### Revision Response

```
/context-status → (address reviewer comments) → /adversarial-review → /score → /commit
```

---

## Directory Structure

```
econ-research-workflow/
├── .claude/
│   ├── agents/           # 12 specialized agents
│   ├── hooks/            # Lifecycle hook scripts (session loader, Stata log check)
│   ├── scripts/          # Auto-approved wrapper scripts (run-stata.sh)
│   ├── rules/            # Coding conventions, econometrics standards (4 path-scoped + 3 always-on incl. constitution)
│   ├── settings.json     # Hook + permission configuration
│   └── skills/           # 34 slash-command skills + 1 reference guide
├── scripts/
│   └── quality_scorer.py # Executable 6-dimension quality scorer
├── tests/                # Test cases (DID, RDD, IV, Panel, Full Pipeline)
├── CLAUDE.md             # Project configuration (fill in placeholders)
├── MEMORY.md             # Cross-session learning and decision log
├── ROADMAP.md            # Phase 1-7 implementation history
└── README.md             # This file
```

Each research project created with `/init-project` follows:

```
project-name/
└── v1/
    ├── code/stata/       # .do files (numbered: 01_, 02_, ...)
    ├── code/python/      # .py files for cross-validation
    ├── data/raw/         # Original data (READ-ONLY)
    ├── data/clean/       # Processed datasets
    ├── data/temp/        # Intermediate files
    ├── output/tables/    # LaTeX tables (.tex)
    ├── output/figures/   # Figures (.pdf/.png)
    ├── output/logs/      # Stata .log files
    ├── paper/sections/   # LaTeX section files
    ├── paper/bib/        # BibTeX files
    ├── _VERSION_INFO.md  # Version metadata
    └── REPLICATION.md    # AEA Data Editor format replication instructions
```

---

## Test Suite

5 end-to-end tests covering all major estimation methods:

| Test | Method | Status |
|------|--------|--------|
| `test1-did` | DID / TWFE / Callaway-Sant'Anna | Pass |
| `test2-rdd` | RDD / rdrobust / density test | Pass |
| `test3-iv` | IV / 2SLS / first-stage diagnostics | Pass |
| `test4-panel` | Panel FE / RE / GMM | Pass |
| `test5-full-pipeline` | End-to-end multi-script pipeline | Pass |

Issues discovered during testing are documented in `tests/ISSUES_LOG.md` and tracked in `MEMORY.md`.

---

## Governance

The workflow operates under a **constitution** (`.claude/rules/constitution.md`) defining 5 immutable principles: raw data integrity, full reproducibility, mandatory cross-validation, version preservation, and score integrity. All skills, agents, and rules operate within this envelope. The `/learn` skill cannot create rules that violate it.

Non-trivial tasks follow a **spec-then-plan** protocol (Phase 0 in the orchestrator) requiring MUST/SHOULD/MAY requirements before implementation begins.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full Phase 1-7 implementation history.

### Hooks

4 lifecycle hooks configured in `.claude/settings.json`:

| Hook | Trigger | What It Does |
|------|---------|-------------|
| Session-start loader | `SessionStart` | Reads MEMORY.md, shows recent entries and last quality score |
| Pre-compact save | `PreCompact` | Prompts session summary to MEMORY.md before context compaction |
| Post-Stata log check | `PostToolUse` (Bash) | Auto-parses `.log` files for `r(xxx)` errors after Stata runs |
| Raw data guard | `PostToolUse` (Bash) | Compares `data/raw/` file snapshots to detect unauthorized modifications |

### Always-On Rules

4 always-on rules (no path scope, loaded in every session):

| Rule | Purpose |
|------|---------|
| `constitution.md` | 5 immutable principles (raw data integrity, reproducibility, cross-validation, version preservation, score integrity) |
| `orchestrator-protocol.md` | Spec-Plan-Implement-Verify-Review-Fix-Score cycle with "Just Do It" mode |
| `stata-error-verification.md` | Enforces reading hook output before re-running Stata; prevents log-overwrite false positives |
| `bash-conventions.md` | No chained commands (`&&`, `||`, `;`); use separate tool calls and absolute paths |

### Permissions & Security

The permission system uses an **allow-all + deny-list** model:

- **Allow**: `Read`, `Edit`, `Write`, `Bash` — all tools auto-approved, zero prompts.
- **Deny**: 35 rules across 3 categories — raw data protection (Constitution Principle 1), destructive operations (`rm -rf`, `git push --force`, `git reset --hard`), and credential/infrastructure protection (`.env`, `.credentials`, `.claude/hooks/**`, `.claude/scripts/**`, `.claude/settings.json`).

Defence-in-depth:

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| 1 | `deny` rules in settings.json | Tool-level string matching (prevents common mistakes) |
| 2 | `raw-data-guard.py` PostToolUse hook | Detects `data/raw/` changes after Bash (catches Python/R script bypass) |
| 3 | OS-level `attrib +R` on `data/raw/` | Filesystem-enforced read-only (set manually per project) |
| 4 | Constitution + behavioural rules | Claude follows constraints voluntarily |

---

## Changelog

| Date | Time (GMT) | Version | Description |
|------|------------|---------|-------------|
| 2026-02-25 | 09:25 | v0.1 | Initial commit — 14 skills, 6 agents, CLAUDE.md template, directory conventions |
| 2026-02-25 | 10:32 | v0.2 | Phase 1 — adversarial QA loop (`/adversarial-review`), quality scorer (`quality_scorer.py`), 6 new skills, README |
| 2026-02-25 | 11:24 | v0.3 | Phase 2 — 3 lifecycle hooks (session loader, pre-compact save, Stata log check), path-scoped rules, exploration sandbox (`/explore` + `/promote`), session continuity (`/session-log`) |
| 2026-02-25 | 12:09 | v0.4 | NBER Working Paper and SSRN preprint LaTeX style support |
| 2026-02-25 | 12:50 | v0.5 | Phase 3 — Socratic research tools (`/interview-me`, `/devils-advocate`), self-extension (`/learn`), constitution governance |
| 2026-02-25 | 15:32 | v0.6 | 4 new skills (`/run-bootstrap`, `/run-placebo`, `/run-logit-probit`, `/run-lasso`), replication package audit (jvae023, data_programs) |
| 2026-02-26 | 06:44 | v0.7 | Phase 5 — real-data replication testing across 11 package × skill combinations, 15 issues found and fixed, all 9 `/run-*` skills hardened with defensive programming |
| 2026-02-26 | 07:51 | v0.8 | Stata auto-approve wrapper (`run-stata.sh` + `permissions.allow`), orchestrator protocol update |
| 2026-02-26 | 15:24 | v0.9 | Stata error verification rule — enforces reading hook output before re-running, prevents log-overwrite false positives (Issue #26) |
| 2026-02-26 | 15:55 | v0.10 | Consistency audit — fixed 31 issues across docs, regex, YAML frontmatter, cross-references, and feature descriptions |
| 2026-02-27 | — | v0.11 | Phase 6 — Pipeline orchestration (`/run-pipeline`), synthesis report (`/synthesis-report`), legacy agent rewiring, orchestrator Phase 7 (Report), score persistence |
| 2026-02-27 | — | v0.12 | Writing tools — 4 new writing skills (`/translate`, `/polish`, `/de-ai`, `/logic-check`) |
| 2026-02-28 | — | v0.13 | Skill audit — 8 skills updated per skill-creator best practices: removed persona statements, added mode guides, false-positive caveats, improved descriptions |
| 2026-03-01 | — | v0.14 | Security hardening — allow-all + deny-list permissions, `raw-data-guard.py` PostToolUse hook, `bash-conventions.md` rule (no chained commands), 35 deny rules, 4-layer defence-in-depth, credential/infrastructure protection |

---

## Credits

- Template architecture inspired by [Pedro H.C. Sant'Anna's claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow)
- Econometric methods follow guidelines from Angrist & Pischke, Callaway & Sant'Anna (2021), Rambachan & Roth (2023), and Cattaneo, Idrobo & Titiunik (2020)
- Quality scoring framework adapted from AEA Data Editor replication standards

---

## License

MIT
