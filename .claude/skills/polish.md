---
description: "Polish academic economics papers — English/Chinese polish, refinement, condensing, and expanding"
user_invocable: true
---

# /polish — Academic Paper Polishing

When the user invokes `/polish`, follow these steps:

## Step 1: Gather Information

Ask the user for:

1. **Mode** (required) — one of:
   - `english` — English paper deep polish
   - `chinese` — Chinese paper polish
   - `refine` — Chinese draft refinement/rewrite (中转中)
   - `condense` — Minor condensing (reduce ~5-15 words)
   - `expand` — Minor expanding (add ~5-15 words)
2. **Target journal** (optional) — e.g., AER, QJE, JPE, Econometrica, REStud, 经济研究, 管理世界, 经济学季刊
3. **Format** (optional) — `LaTeX` (default) or `Word`
4. **Text to process** (required) — the source text

**Mode selection guide:**

| Mode | When to use |
|---|---|
| `english` | English text needing grammar/style improvement |
| `chinese` | Chinese text with minor style issues |
| `refine` | Rough Chinese draft needing structural rewrite |
| `condense` | Reduce length by ~5-15 words |
| `expand` | Increase length by ~5-15 words |

## Step 2: Mode-Specific Processing

### Mode: `english` — English Paper Deep Polish

**Approach:** Apply the standards of a senior editor for top economics journals with native-level English.

**Principles:**
- Sentence structure optimization — vary sentence length, improve flow
- Zero-error policy — eliminate all grammar, spelling, punctuation errors
- Formal academic register throughout:
  - No contractions: `it's` → `it is`, `don't` → `do not`, `can't` → `cannot`
  - Avoid possessive with method names: `METHOD's performance` → `the performance of METHOD`
  - Avoid anthropomorphizing: `The model thinks` → `The model predicts`
- Preserve all LaTeX commands (`\cite{}`, `\ref{}`, `\label{}`, `\textbf{}`, etc.)
- Preserve all mathematical notation, variable names, and numerical values
- Do not change the meaning or add new content
- Maintain the author's academic voice — polish, do not rewrite

**Output:**
```
### Part 1: Polished Text [LaTeX]

[Polished English text]

<!-- Chinese translation helps the author verify meaning preservation -->
### Part 2: Literal Translation [中文直译]

[Chinese literal translation — helps author verify meaning is preserved]

### Part 3: Change Log [修改日志]

| # | Original | Revised | Reason |
|---|----------|---------|--------|
| 1 | [original phrase] | [revised phrase] | [why] |
| 2 | ... | ... | ... |
```

---

### Mode: `chinese` — Chinese Paper Polish

**Approach:** Apply editorial standards of 经济研究/管理世界 for academic Chinese writing.

**Core Principle: "Respect the original, exercise restraint" (尊重原著，克制修改)**

Only intervene when you detect:
- Colloquial or informal expressions inappropriate for academic writing
- Grammatical errors
- Logical breaks or discontinuities
- Ambiguous phrasing that could confuse readers

If a passage is already well-written, leave it unchanged and note this.

**Word Adaptation:**
- Pure clean text output (no LaTeX commands)
- Chinese full-width punctuation throughout (，。；：""（）！？)
- Numbers and variable names in half-width

**Output:**
```
### Part 1: Polished Text [润色文本]

[Polished Chinese text]

### Part 2: Review Comments [审查意见]

[Specific comments on changes made and why,
 or "原文质量良好，仅做微调" if minimal changes]
```

---

### Mode: `refine` — Chinese Draft Refinement (中转中)

**Approach:** Restructure rough notes into polished academic Chinese, as an experienced researcher would.

**Principles:**
- Reconstruct fragmented or stream-of-consciousness text into proper academic paragraph structure. May reorganize paragraphs and upgrade vocabulary, but preserve all substantive arguments.
- "One paragraph, one point" principle (一段一观点)
- Reorganize logic: group related ideas, build clear argument chains
- Upgrade vocabulary from colloquial to academic
- Preserve all substantive content — do not add or remove arguments
- Word adaptation (same as `chinese` mode)

**Output:**
```
### Part 1: Refined Text [重写文本]

[Refined academic Chinese text]

### Part 2: Restructuring Notes [重构思路]

[Explain the logical reorganization:
 - How paragraphs were restructured
 - What was merged or separated
 - Key vocabulary upgrades]
```

---

### Mode: `condense` — Minor Condensing

**Approach:** Compress text without information loss.

**Target:** Reduce by approximately 5-15 words (for a typical paragraph).

**Techniques:**
- Syntactic compression: convert clauses to phrases where possible
- Remove redundant modifiers and filler words
- Eliminate repetitive phrasing
- Combine short choppy sentences

**Constraints:**
- Preserve ALL core information — no content deletion
- Preserve all LaTeX commands and math
- Preserve all numerical values and variable names
- The condensed version must convey exactly the same meaning

**Output:**
```
### Part 1: Condensed Text [LaTeX]

[Condensed text]

<!-- Chinese translation helps the author verify meaning preservation -->
### Part 2: Literal Translation [中文直译]

[Chinese translation of condensed text]

### Part 3: Change Log [修改日志]

| # | Removed/Compressed | Reason |
|---|-------------------|--------|
| 1 | [what was removed/compressed] | [why it is safe to remove] |
```

---

### Mode: `expand` — Minor Expanding

**Approach:** Make implicit reasoning explicit to improve clarity.

**Target:** Add approximately 5-15 words (for a typical paragraph).

**Techniques:**
- Make implicit conclusions or causal links explicit
- Add necessary transition words or connective phrases
- Clarify ambiguous pronoun references
- Spell out abbreviated reasoning

**Constraints:**
- No padding or filler — every added word must serve a purpose
- No hallucination — do not add claims not supported by the original text
- Preserve all LaTeX commands and math
- Preserve all numerical values and variable names

**Output:**
```
### Part 1: Expanded Text [LaTeX]

[Expanded text]

<!-- Chinese translation helps the author verify meaning preservation -->
### Part 2: Literal Translation [中文直译]

[Chinese translation of expanded text]

### Part 3: Change Log [修改日志]

| # | Added | Reason |
|---|-------|--------|
| 1 | [what was added] | [why it improves clarity] |
```

## Step 3: Journal Style Guide

Adjust tone and conventions based on the target journal:

**Chinese Journals:**
- **经济研究** (Economic Research Journal): Formal academic Chinese; "本文" throughout; rigorous methodology
- **管理世界** (Management World): Policy-oriented; emphasize practical implications; management perspectives
- **经济学季刊** (China Economic Quarterly): Methodology-focused; technical depth; econometric rigor

**English Journals:**
- **AER**: Concise, direct; accessible to broad audience; active voice
- **QJE**: Engaging prose; emphasize big-picture contribution
- **JPE**: Balanced formality; clear exposition
- **Econometrica**: Mathematical precision; formal notation
- **REStud**: Technical but accessible; clear logical structure

---

> **Sources**: Polishing methodology adapted from [awesome-ai-research-writing](https://github.com/Leey21/awesome-ai-research-writing) (Leey21), customized for economics research.
