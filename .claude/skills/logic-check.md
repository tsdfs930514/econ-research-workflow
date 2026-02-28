---
description: "Final-pass logic check for paper drafts — catches only critical errors, not style preferences"
user_invocable: true
---

# /logic-check — Paper Logic Check

When the user invokes `/logic-check`, follow these steps:

## Step 1: Gather Information

Ask the user for:

1. **Language** (required) — `CN` (Chinese) or `EN` (English)
2. **Text to check** (required) — the paper text (can be a single section or the full paper)

## Step 2: Review Philosophy

**High tolerance preset:** Assume the text has already gone through multiple rounds of revision. This is a final-pass red-line check, not a comprehensive edit.

**Error-only principle:** Only speak up when you encounter a problem that would:
- Confuse a reader
- Undermine the paper's credibility
- Create a logical contradiction
- Cause a reviewer to question the paper's rigor

**No optimization:** Do NOT comment on:
- Style preferences ("I would phrase this differently...")
- Minor word choices that do not affect meaning
- Paragraph ordering that is acceptable though not optimal
- Citation formatting (unless clearly broken)
- Writing quality — this is NOT a polish step (use `/polish` for that)

## Step 3: Review Dimensions

### 3.1 Fatal Logic Contradictions

- Statements in one section that directly contradict statements in another
- Claims about results that do not match what was actually found
- Hypotheses stated in the introduction that are not tested or are tested differently than described
- Conclusions not supported by the results presented

### 3.2 Terminology Consistency

- Core concepts that change names without explanation (e.g., "treatment group" in one place, "experimental group" in another — referring to the same thing)
- Abbreviations defined one way but used differently
- Variable names that shift (e.g., "income" → "earnings" when referring to the same variable)

### 3.3 Severe Language Errors

Only flag language issues that cause genuine ambiguity or misunderstanding:
- Sentences whose meaning is unclear due to grammar
- Dangling modifiers that create the wrong meaning
- Double negatives that obscure the intended point
- NOT: minor grammar issues, typos, or style preferences

### 3.4 Economics-Specific Checks

**Variable name / table number consistency:**
- Variable names in the text match those in tables
- Table/figure numbers referenced in the text exist and match content
- "Table 3 shows..." actually refers to the content of Table 3

**Significance description vs. table data:**
- Text says "significant at the 1% level" but table shows ** (5%) → flag
- Text says "insignificant" but table shows *** → flag
- Sign of coefficients described in text matches tables

**Causal language appropriateness:**
- Causal language ("X causes Y", "the effect of X on Y") when the method only supports correlation → flag
- "Impact" or "effect" language in descriptive/OLS regressions without an identification strategy → flag
- If the paper uses a valid identification strategy (DID, IV, RDD), causal language is appropriate

**Sample description consistency:**
- N (observations) mentioned in text matches table headers
- Sample period mentioned in text matches data description
- Subgroup descriptions are consistent between text and tables

## Step 4: Output

**If no issues found:**

```
[检测通过，无实质性问题]

The text has been reviewed for logic contradictions, terminology consistency,
severe language errors, and economics-specific issues. No problems requiring
attention were found.
```

**If issues found:**

```
### Issues Found [发现的问题]

**1. [Issue category]: [Brief description]**
- Location: [where in the text]
- Problem: [what is wrong]
- Suggestion: [how to fix]

**2. [Issue category]: [Brief description]**
- Location: [where in the text]
- Problem: [what is wrong]
- Suggestion: [how to fix]
```

Keep each issue brief — 2-3 lines maximum. This is a red-line check, not a detailed review.

Issue categories:
- Logic Contradiction / 逻辑矛盾
- Terminology Inconsistency / 术语不一致
- Severe Language Error / 严重语病
- Variable/Table Inconsistency / 变量/表格不一致
- Significance Mismatch / 显著性描述不匹配
- Inappropriate Causal Language / 因果表述不当
- Sample Description Inconsistency / 样本描述不一致

---

> **Sources**: Logic check methodology adapted from [awesome-ai-research-writing](https://github.com/Leey21/awesome-ai-research-writing) (Leey21), customized for economics research with additional econometrics-specific checks.
