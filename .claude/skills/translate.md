---
description: "Translate academic economics papers between Chinese and English with journal-specific conventions"
user_invocable: true
---

# /translate — Academic Paper Translation

When the user invokes `/translate`, follow these steps:

## Step 1: Gather Information

Ask the user for:

1. **Translation direction** (required) — one of:
   - `CN→EN` — Chinese to English
   - `EN→CN` — English to Chinese
2. **Target journal** (optional) — e.g., AER, QJE, JPE, Econometrica, REStud, 经济研究, 管理世界, 经济学季刊
3. **Format** (optional) — `LaTeX` (default) or `Word`
4. **Text to translate** (required) — the source text

## Step 2: Economics Terminology & Journal Style

### Terminology Table

Apply the following terminology consistently in all translations:

| English | Chinese |
|---|---|
| Difference-in-Differences (DID) | 双重差分 |
| Instrumental Variables (IV) | 工具变量 |
| Regression Discontinuity Design (RDD) | 断点回归设计 |
| Two-Stage Least Squares (2SLS) | 两阶段最小二乘法 |
| Fixed Effects (FE) | 固定效应 |
| Random Effects (RE) | 随机效应 |
| Generalized Method of Moments (GMM) | 广义矩估计 |
| Propensity Score Matching (PSM) | 倾向得分匹配 |
| Synthetic Control Method (SCM) | 合成控制法 |
| Synthetic DID (SDID) | 合成双重差分 |
| LASSO | LASSO（最小绝对收缩和选择算子） |
| Treatment effect | 处理效应 |
| Average Treatment Effect (ATE) | 平均处理效应 |
| Average Treatment Effect on the Treated (ATT) | 处理组平均处理效应 |
| Local Average Treatment Effect (LATE) | 局部平均处理效应 |
| Intention-to-Treat (ITT) | 意向处理效应 |
| Parallel trends assumption | 平行趋势假设 |
| Event study | 事件研究 |
| Robustness check | 稳健性检验 |
| Heterogeneity analysis | 异质性分析 |
| Mechanism analysis | 机制分析 |
| Endogeneity | 内生性 |
| Exogenous variation | 外生变异 |
| Identification strategy | 识别策略 |
| Causal inference | 因果推断 |
| Standard errors clustered at... | 在...层面聚类的标准误 |
| First stage | 第一阶段 |
| Reduced form | 简约式 |
| Exclusion restriction | 排他性约束 |
| Selection bias | 选择偏差 |
| Omitted variable bias | 遗漏变量偏差 |
| Placebo test | 安慰剂检验 |
| Wild cluster bootstrap | 野蛮聚类自助法 |

If the paper consistently uses an alternative term, follow the paper's convention.

### Journal Style Matching

Adjust tone and conventions based on the target journal:

**English Journals:**
- **AER**: Concise, direct prose; active voice; accessible to broad audience
- **QJE**: Engaging prose; emphasize big-picture contribution early
- **JPE**: Balanced formality; clear exposition
- **Econometrica**: Formal, mathematical; precise notation
- **REStud**: Technical but accessible; clear logical structure

**Chinese Journals:**
- **经济研究**: Formal academic Chinese; use "本文" throughout; rigorous methodology
- **管理世界**: Policy-oriented; emphasize practical implications
- **经济学季刊**: Methodology-focused; technical depth

## Step 3: CN→EN Mode (Chinese to English)

**Approach:** Apply the standards of a senior reviewer for leading economics journals.

### LaTeX Awareness

- Escape special characters: `%` → `\%`, `_` → `\_`, `&` → `\&`
- Preserve all math environments (`$...$`, `$$...$$`, `\begin{equation}...\end{equation}`) — do not translate content inside math
- Preserve LaTeX commands (`\cite{}`, `\ref{}`, `\label{}`, `\textbf{}`, `\textit{}`, etc.)
- Preserve table and figure environments entirely
- If format is `Word`, output plain text without LaTeX commands

### Translation Principles

- Translate meaning, not word-by-word — restructure sentences for natural English flow
- Use present tense to describe methods and conclusions ("This paper examines..." not "This paper examined...")
- Use formal academic register throughout:
  - No contractions: `it's` → `it is`, `don't` → `do not`
  - Avoid possessive forms with method names: `DID's results` → `the results of DID`
- Maintain paragraph structure from original
- Preserve all numerical values, variable names, and statistical results exactly
- Preserve all citation keys and cross-references

### Output Format

```
### Part 1: Translation [LaTeX]

[Translated English text with LaTeX formatting preserved]

### Part 2: Back-Translation Comparison [中文回译]

| Original Chinese | English Translation | Back-Translation |
|---|---|---|
| [key sentence 1] | [translation] | [back-translation to Chinese] |
| [key sentence 2] | [translation] | [back-translation to Chinese] |
| ... | ... | ... |
```

Select 5-10 key sentences (especially those containing technical claims, causal statements, or quantitative results) for the back-translation table.

### Self-Review Protocol

After completing the translation, verify:
- [ ] Natural, idiomatic English for economics journals
- [ ] Technical terms correct and consistent with the terminology table
- [ ] No ambiguities introduced by translation
- [ ] Logical flow reads smoothly

If issues are found, revise and note changes in Part 2.

## Step 4: EN→CN Mode (English to Chinese)

**Approach:** Apply strict literal translation standards used by professional academic translators.

### LaTeX Cleaning

- Remove citation commands: `\cite{xxx}` → delete entirely
- Remove reference commands: `\ref{xxx}`, `\label{xxx}` → delete
- Remove LaTeX formatting commands but preserve their content: `\textbf{word}` → word
- Convert math formulas to natural language where appropriate: `$\beta$` → β, `$p < 0.01$` → 在1%水平上显著
- Keep complex equations as-is if they are essential to understanding

### Translation Principles

- Strict literal translation — preserve original sentence structure
- Do not reorganize, paraphrase, or add interpretive content
- Use standard Chinese academic terminology throughout
- All punctuation uses Chinese full-width characters (，。；：""（）)
- Numbers, variable names, and abbreviations remain in half-width
- Translate "we" as "本文" (not "我们") following Chinese journal convention

### Output Format

```
### Part 1: Translation [中文译文]

[Translated Chinese text — pure text paragraphs, no LaTeX]
```

---

> **Sources**: Translation methodology adapted from [awesome-ai-research-writing](https://github.com/Leey21/awesome-ai-research-writing) (Leey21), customized for economics research.
