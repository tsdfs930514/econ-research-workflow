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

## Phase 2 — Infrastructure (Planned)

### Hooks (`settings.json`)

4 lifecycle hooks to automate session management:

| Hook | Trigger | Action |
|------|---------|--------|
| Pre-compact save | Before context compaction | Save MEMORY.md session state |
| Post-compact restore | After context compaction | Reload MEMORY.md and _VERSION_INFO.md |
| Post-Stata log check | After Bash runs Stata | Auto-parse .log for `r(xxx)` errors |
| Session-start loader | Session begins | Load MEMORY.md, display last quality score, show pending issues |

### Path-Scoped Rules

Add `globs:` frontmatter to scope rules to relevant files:

| Rule | Glob Pattern |
|------|-------------|
| `stata-conventions.md` | `**/*.do` |
| `python-conventions.md` | `**/*.py` |
| `econometrics-standards.md` | `**/code/**`, `**/output/**` |
| `replication-standards.md` | `**/REPLICATION.md`, `**/master.do` |

### Exploration Sandbox

- `/explore` skill — experimental analysis workspace with relaxed quality thresholds
- Sandbox rules: results marked as "exploratory", not subject to full review pipeline
- Graduation path: promote exploratory results to main analysis via `/promote`

### Session Continuity

- `/session-log` skill — explicit session start/end with MEMORY.md updates
- Two-tier memory: `personal-memory.md` (gitignored) for machine-specific preferences (Stata path, editor, etc.)

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
| Phase 2 | Next round | Phase 1 stable, user feedback collected |
| Phase 3 | Following round | Phase 2 hooks working reliably |
