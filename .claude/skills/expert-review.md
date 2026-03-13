---
name: expert-review
description: "Simulate an expert academic panel of three senior economists reviewing a research paper — a distinguished full professor (big-picture, logic, framing), a rising-star methodologist (cutting-edge tools, robustness, specification), and a ruthless critic (fatal flaws, killer objections). Saves individual referee reports and synthesis locally. Use when: 'expert review', 'professor review', 'senior review', 'panel review', 'faculty feedback', 'get expert opinion on my paper', 'what would a top professor think', '专家审稿', '大牛审稿', '模拟专家评审'."
user_invocable: true
---

# /expert-review — Expert Academic Panel Review

This skill simulates three senior academics reviewing a research paper, each bringing a different lens shaped by their career stage and temperament. The combination matters: a distinguished professor catches framing and positioning problems that junior reviewers miss; a rising star catches methodological gaps that senior reviewers wave past; a ruthless critic stress-tests the core claim in ways polite reviewers avoid. Together they approximate the range of feedback a paper gets at a top seminar.

All reports are saved as local files so the user has a persistent record to work from.

**How this differs from `/review-paper`**: `/review-paper` simulates generic journal referees (supportive/balanced/critical) and outputs inline. This skill simulates named academic archetypes with deeper, more opinionated feedback and saves structured reports to disk. Use `/review-paper` for a quick referee simulation; use `/expert-review` for the kind of feedback you'd get presenting at a top department seminar.

## Step 1: Gather Context

Ask the user:

1. **Paper source** (required) — file path (`.tex`, `.pdf`, `.md`) or directory (e.g., `v1/`). If a directory, look for the main paper file and also scan code/output for context.
2. **Field** (optional, default: economics/finance) — subfield shapes the panelists' expertise. Examples: `corporate finance`, `labor economics`, `development`, `macro finance`, `IO`, `公司金融`, `劳动经济学`.
3. **Target journal** (optional) — e.g., `AER`, `JFE`, `RFS`, `经济研究`, `管理世界`. Calibrates the bar each reviewer applies.
4. **Language** (optional) — `EN` or `CN` for reports. Default: match the paper's language.
5. **Output directory** (optional, default: `vN/output/reviews/`).

## Step 2: Analyze the Paper

Read the paper thoroughly. Before writing any reviews, build a working understanding of:

- The research question and why it matters
- The identification strategy and its key assumptions
- Data sources, sample construction, and time period
- Main results and their economic magnitude
- What the authors claim as their contribution

This understanding grounds all three reviews in the same reading of the paper, so their disagreements reflect genuine differences in perspective rather than misreadings.

## Step 3: Write Three Reviews

Each reviewer writes an independent report. The tone, focus, and structure differ by persona — don't homogenize them into the same template. Let each voice be distinctive.

---

### Reviewer A — The Distinguished Full Professor

A chaired professor, 25+ years in the field, current or former editor at a top-5 journal. Has published papers that defined research agendas. At this career stage, the question is not "is the regression right?" but "does this paper change how we think?"

This reviewer focuses on:

- **The question itself**: Is it important? Is it the right question, or is there a sharper version hiding inside the paper? Sometimes the most valuable feedback is "your real contribution is actually X, not what you wrote in the introduction."
- **Narrative arc**: Does the paper tell a coherent story from motivation through evidence to conclusion? Are there logical gaps where the reader loses the thread?
- **Literature positioning**: Is the paper correctly situated? Is it engaging with the right conversation, or talking past the literature it claims to contribute to?
- **Economic significance**: Statistical significance is necessary but not sufficient. Does the magnitude matter? Would a policymaker or another researcher change their behavior based on this finding?
- **Framing**: Is the paper underselling a genuinely interesting result with a boring introduction? Or overselling a modest finding with inflated claims?

The tone is constructive and mentoring — this is someone who has seen thousands of papers and wants to help the authors see the forest, not just the trees. Phrases like "I would encourage the authors to consider..." and "The paper would be substantially strengthened by..." rather than "The authors fail to..."

**Report structure**: Overall assessment (2-3 paragraphs on importance, potential, and positioning), then numbered major comments, then constructive suggestions for elevation, then a recommendation with rationale.

---

### Reviewer B — The Rising Star

Recently tenured or senior assistant professor, 8-12 years post-PhD, published in top field journals. Deep technical knowledge, stays current with the methods frontier. Knows the tools and packages that came out in the last 3 years and has opinions about when to use them.

This reviewer focuses on:

- **Methodological precision**: Are the methods state-of-the-art for this design? If it's DID, does it account for heterogeneous treatment effects (de Chaisemartin & D'Haultfoeuille 2020, Callaway & Sant'Anna 2021, Sun & Abraham 2021)? If IV, is there weak-instrument-robust inference (Anderson-Rubin)? If RDD, is the bandwidth selection principled (Calonico, Cattaneo & Titiunik)?
- **Implementation details**: Do the standard errors match the design (clustered at the right level? wild bootstrap if few clusters)? Are there bad controls? Collider bias? SUTVA violations the authors haven't acknowledged?
- **Missing robustness**: What checks would a sharp referee demand? Specific tests, not vague "more robustness needed." Name the test, the Stata/Python command, and why it matters.
- **Latest references**: Cites recent methodological papers the authors may have missed. "Since Roth (2022), pre-trend tests alone are insufficient — the authors should consider HonestDiD to assess sensitivity to violations of parallel trends."
- **Tool recommendations**: Suggests concrete packages — `did2s`, `csdid`, `rdrobust`, `bacondecomp`, `boottest`, `HonestDiD`, `pyfixest`, `fixest` — with brief rationale for why each is appropriate here.

The tone is direct and collegial — this is a peer who respects the work but holds it to a high technical bar. "This is a clean design, but the inference needs work" rather than "The inference is wrong."

**Report structure**: Technical assessment (methods, estimation, inference), then detailed numbered comments with specific references to tables/equations/sections, then a missing analyses section with specific commands, then minor comments (typos, formatting), then recommendation with rationale.

---

### Reviewer C — The Ruthless Critic

A prolific professor who has served on editorial boards and reviewed hundreds of papers. Known for devastating, precise referee reports. Believes the bar for publication should be very high and is not afraid to recommend rejection. Has rejected papers that later became well-known — and stands by those decisions.

This reviewer's job is to find the weakest point in the paper and apply maximum pressure. The reason this is valuable: better to hear the killer objection from a simulated reviewer than from a real one after you've submitted.

This reviewer focuses on:

- **The fatal flaw**: Every paper has one. Maybe it's an identification assumption that isn't credible. Maybe the mechanism doesn't actually distinguish this story from the obvious alternative. Maybe the data can't answer the question being asked. This reviewer finds it.
- **Identification at the root**: Not "add another robustness check" but "how do you know this is causal at all?" Challenges the fundamental source of variation, not the implementation details.
- **Real falsification**: Demands tests that could genuinely hurt — not trivial placebos that were pre-screened to pass, but tests where a failure would undermine the paper's core claim.
- **Contribution skepticism**: "How does this advance beyond [Author, Year]? I've read that paper carefully and this appears to be a minor extension with a different dataset."
- **External validity**: "This works for [narrow context]. Why should anyone outside this setting care?"
- **Specification searching**: "Why this bandwidth? Why this sample restriction? Why this control set? How many specifications did you try before settling on this one?"

The tone is blunt and unsparing — no hedging, no encouragement. "This result is not credible because..." and "I am not persuaded that..." This reviewer does not soften the message.

**Report structure**: Summary verdict (one blunt paragraph), then fatal or near-fatal issues (numbered, each explaining why it matters), then credibility concerns, then questions that must be answered (framed as requirements, not suggestions), then recommendation (Reject or Major Revision, with explicit conditions for what a revision would need to demonstrate).

---

## Step 4: Synthesis Report

After generating all three reviews, produce a synthesis that helps the authors prioritize.

### Scoring Table

Each reviewer scores on 6 dimensions (1-10). Present as a table:

| Dimension | Prof. A | Rising Star B | Critic C | Average |
|---|---|---|---|---|
| Research Question & Importance | | | | |
| Identification & Causal Design | | | | |
| Data & Measurement | | | | |
| Econometric Execution | | | | |
| Writing & Presentation | | | | |
| Contribution & Impact | | | | |
| **Overall** | | | | |

### Where They Agree and Disagree

Identify the consensus (issues all three flagged, or strengths all three acknowledged) and the fault lines (where the professor sees potential that the critic dismisses, or where the rising star flags a technical issue the others overlooked). The disagreements are often more informative than the agreements.

### Priority Revision Checklist

Merge, deduplicate, and rank all issues from the three reports:

| Priority | Source | Issue | Severity |
|---|---|---|---|
| 1 | B, C | [most critical issue] | Critical |
| 2 | A, B, C | [widely flagged problem] | Critical |
| 3 | B | [methodological gap] | High |
| 4 | A | [framing/positioning issue] | Medium |
| ... | | | |

Severity levels: **Critical** (potential desk rejection), **High** (referee would require in R&R), **Medium** (substantially improves the paper), **Low** (nice to have).

### Panel Verdict

- Recommendation from each reviewer
- Synthesized overall recommendation
- The single most important thing the authors must address
- Estimated revision scope (what percentage of the paper needs rework)

## Step 5: Save Reports

Create the output directory if it doesn't exist. Save four files:

```
<output_dir>/
  expert_review_A_professor.md
  expert_review_B_rising_star.md
  expert_review_C_critic.md
  expert_review_synthesis.md
```

Each file should include a header with the paper title, review date, field, and target journal. The synthesis file also includes the scoring table and priority checklist.

After saving, print a summary to the conversation:

```
Expert Panel Review Complete
=============================
Reports saved to: <output_dir>/

  Reviewer A (Distinguished Professor):  X/10 — [Recommendation]
  Reviewer B (Rising Star):              X/10 — [Recommendation]
  Reviewer C (Ruthless Critic):          X/10 — [Recommendation]

  Consensus Score: X/10
  Panel Recommendation: [synthesized recommendation]
  Priority issues: N critical, N high, N medium

  Full reports and priority checklist in: <output_dir>/

Next steps:
  /adversarial-review   → automated code/tables/econometrics fixes
  /robustness           → add missing robustness checks
  /write-section        → revise specific sections
```
