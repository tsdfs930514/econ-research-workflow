# Roadmap

## Phase 1 — Core Quality Infrastructure (Current)

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

## Phase 3 — Polish (Planned)

### Socratic Research Tools

- `/interview-me` — Socratic questioning to formalize research ideas (bilingual: EN/CN)
  - Walks through: research question → hypothesis → identification strategy → data requirements → expected results
  - Outputs structured research proposal

- `/devils-advocate` — systematic challenges to identification strategy
  - Enumerates threats to internal validity
  - Suggests falsification tests
  - Proposes alternative explanations

### Self-Extension Infrastructure

- `/learn` — create new rules or skills from within sessions
  - Example: after discovering a new Stata convention, run `/learn` to codify it as a rule
  - Auto-generates properly formatted .md files in `.claude/rules/` or `.claude/skills/`

### Governance

- **Spec-then-plan protocol** — before any implementation, produce a requirements spec with MUST/SHOULD/MAY classifications, then a plan, then implement
- `CONSTITUTION.md` — immutable principles for the template:
  - Raw data is never modified
  - Every result must be reproducible from code + raw data
  - Cross-validation is mandatory for all regressions
  - Version directories are never deleted, only superseded
  - Quality scores are recorded, never fabricated

---

## Timeline

| Phase | Target | Depends On |
|-------|--------|------------|
| Phase 1 | Done | — |
| Phase 2 | Done | Phase 1 stable |
| Phase 3 | Following round | Phase 2 hooks working reliably |
