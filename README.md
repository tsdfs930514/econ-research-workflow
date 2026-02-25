# Econ Research Workflow

A Claude Code-powered template for reproducible economics research, featuring automated Stata/Python pipelines, adversarial quality assurance, and cross-validation infrastructure.

Inspired by [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow).

---

## Features

- **21 skills** — slash-command workflows covering the full research lifecycle (data cleaning, DID/IV/RDD/Panel estimation, cross-validation, tables, paper writing, review, exploration sandbox, session continuity, and more)
- **12 agents** — specialized reviewers plus 3 adversarial critic-fixer pairs (code, econometrics, tables) enforcing separation of concerns
- **3 lifecycle hooks** — automatic session context loading, pre-compaction memory save, and post-Stata error detection
- **Adversarial QA loop** — `/adversarial-review` runs critic → fixer → re-critic cycles (up to 5 rounds) until quality score >= 95
- **Executable quality scorer** — `quality_scorer.py` scores projects on 6 dimensions (100 pts), including method-specific diagnostics auto-detected from .do files
- **Exploration sandbox** — `/explore` for hypothesis testing with relaxed thresholds; `/promote` to graduate results to the main pipeline
- **Stata + Python cross-validation** — every regression is verified across both languages via `pyfixest`
- **Bilingual support** — Chinese (经济研究/管理世界 style) and English (AER/QJE style) output
- **Version-controlled analysis** — `v1/`, `v2/`, ... directory structure with full replication packages
- **Session continuity** — `/session-log` for explicit session management with MEMORY.md integration

---

## Quick Start

1. **Fork** this repository
2. **Configure** `CLAUDE.md` — fill in `[PLACEHOLDER]` fields (project name, institution, researcher, Stata path)
3. **Run** `/init-project` in Claude Code to scaffold a new research project
4. Place raw data in `v1/data/raw/`
5. Use `/data-describe` → `/run-did` (or `/run-iv`, `/run-rdd`, `/run-panel`) → `/cross-check` → `/make-table`
6. Run `/adversarial-review` for automated quality assurance
7. Run `/score` to get a quantitative quality report

---

## Skills Reference

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/init-project` | Start a new project | Initialize standardized directory structure with master.do, REPLICATION.md, templates |
| `/data-describe` | Explore data | Generate descriptive statistics and variable distributions (Stata + Python) |
| `/run-did` | DID analysis | Full DID/TWFE/Callaway-Sant'Anna/SDID pipeline with diagnostics |
| `/run-iv` | IV analysis | Complete IV/2SLS pipeline with first-stage, weak-instrument tests, LIML comparison |
| `/run-rdd` | RDD analysis | Complete RDD pipeline with bandwidth sensitivity, density test, placebo cutoffs |
| `/run-panel` | Panel analysis | Panel FE/RE/GMM pipeline with Hausman, serial correlation, CD tests |
| `/cross-check` | Validate results | Cross-validate Stata vs Python regression results (target: < 0.1% coefficient diff) |
| `/robustness` | Robustness tests | Comprehensive robustness test suite for regression results |
| `/make-table` | Format tables | Generate publication-quality LaTeX regression tables (AER or 三线表 style) |
| `/write-section` | Draft paper | Write a paper section in Chinese or English following journal conventions |
| `/review-paper` | Simulate review | Three simulated peer reviewers giving structured feedback |
| `/lit-review` | Literature review | Structured literature review with BibTeX entries |
| `/adversarial-review` | Quality assurance | Adversarial critic-fixer loop across code, econometrics, and tables domains |
| `/score` | Quality scoring | Run executable quality scorer (6 dimensions, 100 pts) on current version |
| `/commit` | Git commit | Smart commit with type prefix, data safety warnings, auto-generated message |
| `/compile-latex` | Compile paper | Run pdflatex/bibtex pipeline with error checking |
| `/context-status` | Session context | Display current version, recent decisions, quality scores, git state |
| `/run-sdid` | SDID analysis | Synthetic DID analysis with unit/time weights and inference |
| `/explore` | Exploration sandbox | Set up `explore/` directory with relaxed quality thresholds (>= 60) |
| `/promote` | Promote results | Graduate exploratory files to main `vN/` pipeline with quality check |
| `/session-log` | Session continuity | Start/end sessions with MEMORY.md context loading and recording |

---

## Agents Reference

| Agent | Role | Tools |
|-------|------|-------|
| `code-reviewer` | Code quality evaluation (correctness, reproducibility, style) | Read-only |
| `econometrics-reviewer` | Identification strategy and estimation review | Read-only |
| `tables-reviewer` | Table formatting and content accuracy review | Read-only |
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
    → /score → /compile-latex → /commit
```

### Quick Check (single regression)

```
/run-did → /cross-check → /score
```

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
│   ├── rules/            # Coding conventions, econometrics standards (4 path-scoped + 1 always-on)
│   ├── settings.json     # Hook configuration (3 hooks)
│   └── skills/           # 21 slash-command skills
├── scripts/
│   └── quality_scorer.py # Executable 6-dimension quality scorer
├── tests/                # Test cases (DID, RDD, IV, Panel, Full Pipeline)
├── CLAUDE.md             # Project configuration (fill in placeholders)
├── MEMORY.md             # Cross-session learning and decision log
├── ROADMAP.md            # Phase 2-3 future plans
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

## Prerequisites

- **Stata 18** (MP recommended) — all econometric estimation
- **Python 3.10+** — cross-validation via `pyfixest`, `pandas`, `numpy`
- **Claude Code** — CLI tool for running skills and agents
- **Git Bash** (Windows) — shell environment for Stata execution
- **LaTeX distribution** (optional) — for `/compile-latex` (pdflatex + bibtex)

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

## 中文快速上手指南

### 安装与配置

1. Fork 本仓库到你的 GitHub 账户
2. 安装 [Claude Code](https://claude.com/claude-code) CLI 工具
3. 确保已安装 Stata 18 和 Python 3.10+
4. 打开 `CLAUDE.md`，填写项目信息（项目名、机构、研究者姓名等）

### 基本用法

```bash
# 在项目目录中启动 Claude Code
claude

# 初始化新研究项目
/init-project

# 运行 DID 分析（支持 TWFE、CS-DiD、BJS 等）
/run-did

# 交叉验证 Stata 与 Python 结果
/cross-check

# 生成发表质量的回归表格（支持三线表和 booktabs）
/make-table

# 对抗式质量审查（代码 + 计量 + 表格）
/adversarial-review

# 量化质量评分（6 维度，100 分制）
/score
```

### 支持的计量方法

| 方法 | 技能命令 | 主要工具 |
|------|----------|----------|
| 双重差分 (DID) | `/run-did` | reghdfe, csdid, did_multiplegt, bacondecomp |
| 工具变量 (IV) | `/run-iv` | ivreghdfe, ivreg2, weakiv |
| 断点回归 (RDD) | `/run-rdd` | rdrobust, rddensity, rdplot |
| 面板数据 | `/run-panel` | reghdfe, xtabond2 |
| 合成 DID | `/run-sdid` | sdid |

### 质量评分标准

| 分数 | 等级 | 操作 |
|------|------|------|
| >= 95 | 可发表 | 无需修改 |
| >= 90 | 小修 | 处理小问题后提交 |
| >= 80 | 大修 | 需要显著修改 |
| < 80 | 重做 | 存在根本性问题 |

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for Phase 3 (Socratic tools, self-extension, governance) plans.

### Hooks

3 lifecycle hooks configured in `.claude/settings.json`:

| Hook | Trigger | What It Does |
|------|---------|-------------|
| Session-start loader | `SessionStart` | Reads MEMORY.md, shows recent entries and last quality score |
| Pre-compact save | `PreCompact` | Prompts session summary to MEMORY.md before context compaction |
| Post-Stata log check | `PostToolUse` (Bash) | Auto-parses `.log` files for `r(xxx)` errors after Stata runs |

---

## Credits

- Template architecture inspired by [Pedro H.C. Sant'Anna's claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow)
- Econometric methods follow guidelines from Angrist & Pischke, Callaway & Sant'Anna (2021), Rambachan & Roth (2023), and Cattaneo, Idrobo & Titiunik (2020)
- Quality scoring framework adapted from AEA Data Editor replication standards

---

## License

MIT
