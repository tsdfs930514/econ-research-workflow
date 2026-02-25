# Orchestrator Protocol: Contractor Mode

All non-trivial tasks follow the **Plan - Implement - Verify - Review - Fix - Score** cycle, with a maximum of 5 rounds.

---

## Phase 1: Plan

1. Understand the research question and identification strategy.
2. Identify required data sources, variables, and econometric methods.
3. Draft an analysis plan with specific Stata/Python commands to be used.
4. List all expected output files (datasets, tables, figures, logs).
5. Present the plan for approval before proceeding.

**Exit criterion**: Plan approved by user or team lead.

---

## Phase 2: Implement

1. Generate code files (`.do` for Stata, `.py` for Python).
2. Execute Stata via CLI (Git Bash):
   ```
   "D:\Stata18\StataMP-64.exe" -e do "script.do"
   ```
   Flag: 必须用 `-e`（自动退出），禁止用 `-b`（需手动确认）或 `/e`（Git Bash 路径冲突）
3. Parse the resulting `.log` file for errors and warnings.
4. Execute Python scripts:
   ```
   python "script.py"
   ```
5. Collect all outputs (tables, figures, datasets).

**Exit criterion**: Code runs without errors; all expected output files are generated.

---

## Phase 3: Verify

1. Check Stata `.log` files for errors, warnings, and unexpected messages.
2. Verify that all expected output files exist and are non-empty.
3. Cross-check Stata vs Python results: coefficient differences must be < 0.1%.
4. Validate table formatting against the standards in `econometrics-standards.md`.
5. Confirm that all required statistics (N, R-squared, clusters, dep var mean) are reported.

**Exit criterion**: All verification checks pass.

---

## Phase 4: Review

Invoke the relevant reviewer agent(s) based on the task:

| Reviewer               | Scope                                      |
|------------------------|--------------------------------------------|
| econometrics-reviewer  | Methods, identification, robustness        |
| code-reviewer          | Code quality, conventions, reproducibility |
| tables-reviewer        | Table formatting, labeling, completeness   |
| robustness-checker     | Missing robustness checks, sensitivity     |

Each reviewer assigns a score from 0 to 100 and provides specific findings.

**Exit criterion**: All relevant reviews completed; scores and findings collected.

---

## Phase 5: Fix

1. Address each review finding.
2. Re-run affected analyses.
3. Update output files (tables, figures, logs).
4. Document what was changed and why.

**Exit criterion**: All findings addressed; outputs regenerated.

---

## Phase 6: Score

Calculate the final quality score as the average of all reviewer scores.

| Score Range | Action                                        |
|-------------|-----------------------------------------------|
| >= 95       | Publication ready. Proceed to next task.      |
| >= 90       | Minor fixes needed. One more round (Phase 5). |
| >= 80       | Significant issues. Re-enter Phase 2.         |
| < 80        | Major redo required. Re-enter Phase 1.        |

**Exit criterion**: Score >= 95, or maximum iterations reached.

---

## Loop Control

- **Maximum iterations**: 5 rounds through the cycle.
- **Stagnation check**: If the score improves by less than 5 points between rounds, flag for human review.
- **Version preservation**: Always preserve ALL intermediate versions of code and output. Never overwrite without saving the prior version.

---

## Workflow Diagram

```
Plan --> Implement --> Verify --> Review --> Fix --> Score
  ^                                                   |
  |                                                   |
  +---------------------------------------------------+
                    (if score < 95, loop)
```

After 5 iterations or upon reaching score >= 95, the task is complete.
