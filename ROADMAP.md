# Roadmap

## Phase 1 — Core Quality Infrastructure

**Status**: Implemented

- 6 new adversarial agents (3 critic-fixer pairs: code, econometrics, tables)
- `/adversarial-review` skill orchestrating multi-round critic-fixer loops
- Executable `quality_scorer.py` (6 dimensions, 100 pts, auto-detects methods)
- `/score`, `/commit`, `/compile-latex`, `/context-status` skills
- MEMORY.md activation with tagged entries and session logging
- README.md with English main body + Chinese quick-start
- Orchestrator protocol update with "Just Do It" mode

---

## Phase 2 — Infrastructure (Implemented)

**Status**: Implemented

### Hooks (`settings.json`)

3 lifecycle hooks in `.claude/settings.json`:

| Hook | Trigger | Action |
|------|---------|--------|
| Session-start loader | `SessionStart` | Read MEMORY.md, display recent entries, last session, last quality score |
| Pre-compact save | `PreCompact` | Prompt Claude to append session summary to MEMORY.md before compaction |
| Post-Stata log check | `PostToolUse` (Bash) | Auto-parse .log for `r(xxx)` errors after Stata execution |

Hook scripts: `.claude/hooks/session-loader.py`, `.claude/hooks/stata-log-check.py`

### Path-Scoped Rules

4 rules scoped via `paths:` frontmatter; 1 always-on:

| Rule | `paths:` Pattern |
|------|-----------------|
| `stata-conventions.md` | `**/*.do` |
| `python-conventions.md` | `**/*.py` |
| `econometrics-standards.md` | `**/code/**`, `**/output/**` |
| `replication-standards.md` | `**/REPLICATION.md`, `**/master.do`, `**/docs/**` |
| `orchestrator-protocol.md` | *(always-on, no paths)* |

### Exploration Sandbox

- `/explore` skill — creates `explore/` workspace with relaxed quality thresholds (>= 60 vs 80)
- `/promote` skill — graduates files from `explore/` to `vN/`, renumbers, runs `/score` to verify

### Session Continuity

- `/session-log` skill — explicit session start/end with MEMORY.md context loading and recording
- `personal-memory.md` (gitignored) — machine-specific preferences (Stata path, editor, directories)

---

## Phase 3 — Polish (Implemented)

**Status**: Implemented

### Socratic Research Tools

- `/interview-me` — bilingual (EN/CN) Socratic questioning to formalize research ideas
  - Walks through: research question → hypothesis → identification strategy → data requirements → expected results
  - Asks one question at a time; sections are skippable
  - Outputs structured research proposal to `vN/docs/research_proposal.md`

- `/devils-advocate` — systematic pre-analysis challenges to identification strategy
  - Universal threats (OVB, reverse causality, measurement error, selection, SUTVA)
  - Method-specific threats (DID/IV/RDD/Panel/SDID)
  - 3 alternative explanations per key result
  - Falsification test recommendations
  - Threat matrix with severity levels (Critical/High/Medium/Low, matching `econometrics-critic`)

### Self-Extension Infrastructure

- `/learn` — create new rules or skills from within sessions
  - Guided creation: type → content → validate → preview → write
  - Auto-generates properly formatted .md files in `.claude/rules/` or `.claude/skills/`
  - Constitution guard: cannot create rules/skills violating `constitution.md`
  - Logs `[LEARN]` entries to MEMORY.md

### Governance

- **`constitution.md`** — 5 immutable principles (always-on rule, no `paths:` frontmatter):
  1. Raw data integrity (`data/raw/` never modified)
  2. Full reproducibility (every result traceable from code + raw data)
  3. Mandatory cross-validation (Stata ↔ Python, < 0.1%; relaxed in `explore/`)
  4. Version preservation (`vN/` never deleted)
  5. Score integrity (scores recorded faithfully)

- **Spec-then-plan protocol** — Phase 0 added to orchestrator protocol:
  - Triggered when task affects >= 3 files, changes identification strategy, creates skills/rules/agents, or modifies the protocol itself
  - Format: MUST / SHOULD / MAY requirements + acceptance criteria + out of scope
  - Written once per task; review loop restarts at Phase 1

---

## Timeline

| Phase | Target | Depends On |
|-------|--------|------------|
| Phase 1 | Done | — |
| Phase 2 | Done | Phase 1 stable |
| Phase 3 | Done | Phase 2 hooks working reliably |
