---
description: "Detect and remove AI-generated writing patterns to produce natural, human-like academic prose"
user_invocable: true
---

# /de-ai — AI Writing Pattern Removal

When the user invokes `/de-ai`, follow these steps:

## Step 1: Gather Information

Ask the user for:

1. **Language** (required) — `EN` (English) or `CN` (Chinese)
2. **Format** (optional) — `LaTeX` (default) or `Word`
3. **Text to process** (required) — the text to de-AI

## Step 2: AI Signature Detection

You are a senior reviewer for AER/QJE/JPE who has read thousands of human-written and AI-generated papers. Your task is to detect and eliminate telltale AI writing patterns.

### 2.1 Lexical Patterns (Word-Level)

**High-frequency AI vocabulary — flag and replace these words/phrases:**

General overused AI words:
- leverage, delve, tapestry, underscore, pivotal, nuanced, intricate
- foster, elucidate, comprehensive, multifaceted, holistic, paradigm, synergy
- landscape, realm, interplay, crucial, vital, cutting-edge, groundbreaking
- harness, navigate, facilitate, bolster, augment, streamline
- noteworthy, commendable, meticulous, indispensable, paramount
- shed light on, pave the way, at the forefront, game changer
- it is important to note, it is worth mentioning, in today's rapidly
- a testament to, serves as a reminder, the cornerstone of
- robust (when not referring to statistical robustness)

Economics-specific AI patterns:
- "comprehensive framework" → "framework"
- "robust evidence" (non-statistical context) → "evidence"
- "nuanced understanding" → "understanding" or "detailed understanding"
- "shed light on the mechanisms" → "identify the mechanisms" or "examine the mechanisms"
- "comprehensive empirical analysis" → "empirical analysis"
- "robust causal evidence" → "causal evidence"
- "rich dataset" → "detailed dataset" or describe the dataset directly
- "novel contribution" → state the contribution directly
- "growing body of literature" → "recent literature" or "literature on X"
- "fills an important gap" → state what is new directly

Supplementary blacklist:
- Additionally, Moreover, Furthermore (when used mechanically at paragraph starts)
- In conclusion, In summary (when formulaic)
- It is important to note that, It is worth noting that
- plays a crucial role, is of paramount importance
- First and foremost, Last but not least
- This serves as a reminder, This is a testament to

### 2.2 Structural Patterns

**Detect and fix these AI structural signatures:**

1. **Excessive dash usage** — AI overuses em-dashes for parenthetical remarks. Replace with commas, parentheses, or restructure.

2. **List format abuse** — AI defaults to bullet lists when continuous prose is more appropriate. Convert standalone bullet lists into flowing paragraphs.

3. **Mechanical connectors** — AI uses formulaic transitions:
   - "First and foremost" → "First" or start the point directly
   - "It is worth noting that" → delete or rephrase directly
   - "In light of the above" → delete or use a specific reference
   - "Moving forward" → delete
   - "Building upon this" → delete or be specific

4. **Rule of Three** — AI tends to provide exactly three examples/points/reasons. Vary the number based on content.

5. **Excessive bold/italic** — AI over-formats text. Remove formatting used purely for emphasis in running prose.

6. **"Not only...but also..."** — AI overuses this construction. Use simpler alternatives.

7. **Formulaic paragraph openings** — Every paragraph starting with a transition word. Let some paragraphs begin directly with content.

### 2.3 Tone Patterns

1. **Over-hedging** — Excessive qualifiers: "might potentially", "could possibly", "it seems that perhaps". Be direct.
2. **Generic positive conclusions** — "This study makes significant contributions..." Just state what was found.
3. **Filler phrases** — "In the realm of", "Within the context of", "It goes without saying". Delete.

## Step 3: Rewriting Rules

**Core principle: Replace flashy language with plain, precise words.**

| AI Pattern | Human Alternative |
|---|---|
| leverage | use |
| utilize | use |
| delve into | examine, study, analyze |
| underscore | show, highlight |
| pivotal | important, key |
| nuanced | detailed, subtle |
| intricate | complex |
| foster | encourage, promote |
| elucidate | explain, clarify |
| comprehensive | thorough, full |
| multifaceted | complex |
| facilitate | enable, help |
| bolster | support, strengthen |
| shed light on | explain, reveal, identify |
| pave the way | enable, allow |
| at the forefront | leading |
| a growing body of | recent, increasing |
| it is important to note | [delete — just state it] |
| furthermore / moreover | [delete or use "also", "and"] |
| in conclusion | [delete or just summarize] |

**Additional rewriting rules:**
- Convert bullet lists to connected prose paragraphs
- Remove mechanical transition words at paragraph openings
- Vary sentence length — mix short and long
- Add specific details where AI tends to be vague
- If the original text is already natural, KEEP IT and note that no changes are needed

## Step 4: Output

**For EN mode:**

```
### Part 1: Rewritten Text [LaTeX/Word]

[Rewritten text — or original if already natural]

### Part 2: Literal Translation [中文直译]

[Chinese translation of the rewritten text]

### Part 3: Change Log [修改日志]

| # | AI Pattern Detected | Original | Revised | Category |
|---|---|---|---|---|
| 1 | [pattern name] | [original phrase] | [revised phrase] | Lexical/Structural/Tone |
| 2 | ... | ... | ... | ... |
```

If no significant AI patterns are found:
```
### Part 1: Original Text (Preserved)

[Original text unchanged]

### Part 2: Detection Result

Detection passed — no significant AI patterns found. The text reads naturally.
```

**For CN mode:**

```
### Part 1: 重写文本

[重写后的文本——如果原文已足够自然则保留原文]

### Part 2: 修改日志

| # | 检测到的 AI 模式 | 原文 | 修改后 | 类别 |
|---|---|---|---|---|
| 1 | [模式名称] | [原文片段] | [修改后片段] | 词汇/结构/语气 |
```

**Chinese-specific AI patterns (for CN mode):**
- 值得注意的是 — mechanical emphasis
- 综上所述 — formulaic conclusion
- 不可或缺 — AI superlative
- 至关重要 — AI emphasis
- 日益重要 — AI filler
- 本研究旨在填补这一空白 — AI gap-filling cliche
- 这一研究为...提供了重要参考 — generic AI conclusion
- 在此背景下 — mechanical transition
- 具有重要的理论意义和实践价值 — generic AI value claim

## Step 5: Secondary Audit

After the initial rewrite, perform a self-audit:

**Ask yourself: "What would still make a careful reader suspect this was AI-generated?"**

1. Re-read the rewritten text from the perspective of a skeptical reviewer
2. Identify any remaining AI signatures (even subtle ones)
3. Briefly note remaining traces (if any)
4. If traces remain, revise again and produce the final version

```
### Secondary Audit [二次审计]

**Remaining traces:** [list any remaining concerns, or "None — text reads as naturally human-written"]
**Final revision:** [any additional changes, or "No further changes needed"]
```

---

> **Sources**: De-AI methodology adapted from [awesome-ai-research-writing](https://github.com/Leey21/awesome-ai-research-writing) (Leey21) and [humanizer](https://github.com/blader/humanizer) (blader), customized for economics research.
