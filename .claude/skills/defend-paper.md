---
name: defend-paper
description: "Strategic counterweight to reviewer feedback — protects a paper's core economic logic from being diluted by outcome accumulation, excessive robustness, or technique-over-substance drift. Applies a four-layer narrative framework (fact, mechanism, decision, consequence) to reorganize results and cut what doesn't serve the main claim. Saves a defense brief locally. Use when: 'defend paper', 'respond to reviewers', 'too many results', 'paper is getting bloated', 'reviewers want more outcomes', 'refocus my paper', 'narrative discipline', 'what should I cut', '论文主线', '审稿意见回复', '砍结果', '重新梳理故事线', '论文瘦身'."
user_invocable: true
---

# /defend-paper — Narrative Defense & Result Discipline

## Why this skill exists

Reviewer feedback — whether from real referees, `/expert-review`, or `/adversarial-review` — tends to push papers in one direction: *more*. More robustness checks, more outcome variables, more heterogeneity cuts, more mechanism proxies. Each individual suggestion sounds reasonable, but the cumulative effect is a paper that proves everything weakly rather than one thing deeply.

The symptom is familiar: the paper becomes a laundry list of outcomes held together by "X is associated with all these things, therefore X matters." But that's backwards. Stacking results doesn't strengthen a contribution — it usually signals that the core proposition isn't natural enough to stand on its own, so it needs technique to compensate.

This skill is the counterweight. It reads the paper and any reviewer feedback, then applies a structural framework to answer: **What is the one story this paper should tell, and what needs to be cut or reorganized to tell it clearly?**

**When to use this vs other review skills:**
- `/review-paper` and `/expert-review` *generate* criticism. This skill *responds* to it strategically.
- `/adversarial-review` fixes code, tables, and econometrics. This skill fixes the narrative.
- `/write-section` drafts prose. This skill decides what the prose should say.

## Step 1: Gather Inputs

Ask the user for:

1. **Paper source** (required) — file path or directory (e.g., `v1/`).
2. **Reviewer feedback** (optional but very useful) — file paths to referee reports, `/expert-review` output, or the user's description of what reviewers are asking for. If no formal reports exist, ask the user to describe the pressure they're feeling: "What are reviewers pushing you to add?"
3. **Field** (optional, default: economics/finance).
4. **Language** (optional, default: match paper) — `EN` or `CN` for the defense brief.
5. **Output directory** (optional, default: `vN/output/reviews/`).

## Step 2: Diagnose the Paper's Current State

Read the paper carefully. Build a map of what's currently in it:

- What is the stated research question?
- What is the identification strategy?
- How many outcome variables are there? List them all.
- How many robustness/heterogeneity tables are there?
- What does the introduction claim as the contribution?
- Does the paper's structure match its claimed contribution, or has it drifted?

Then read the reviewer feedback (if provided) and categorize each suggestion:
- **Sharpening**: makes the core argument tighter (keep)
- **Deepening**: adds mechanism or boundary conditions that clarify *why* the result matters (keep)
- **Padding**: adds breadth without depth — more outcomes, more subsamples, more "also significant" results (resist)
- **Deflecting**: addresses a real concern but by adding volume rather than fixing the root issue (rethink)

The most important diagnostic question: **Can the paper's main claim be stated in one sentence that a non-specialist would find interesting?** If not, the paper has a narrative problem, and more results won't fix it.

## Step 3: Apply the Four-Layer Framework

Every result in the paper should fit into one of four layers in a causal chain. Results that don't fit any layer — even if statistically significant — are candidates for demotion or removal.

### Layer 1: Fact

The cleanest, most stable baseline relationship. This is the paper's empirical anchor — the one result that holds up across every reasonable specification, that even the skeptics wouldn't dispute as a statistical pattern.

Keep **exactly one** baseline result here. If you have three versions of the same regression with slightly different controls, pick the one that makes the identification clearest and move the rest to robustness.

### Layer 2: Mechanism

What does X actually change? Not "X is associated with Y" but "X alters a specific cognition, incentive, constraint, or resource for a specific type of agent." This is where the economic content lives.

Good mechanism evidence answers: *Through what channel does the fact in Layer 1 operate?* It names the cognitive process, the incentive shift, the information friction, or the resource constraint that X moves. It should feel like an explanation, not just another regression with a different dependent variable.

### Layer 3: Decision

Which real decision margin gets pushed? If the mechanism in Layer 2 is real, there should be a downstream decision that changes — a contract term, an investment choice, a risk allocation, a hiring decision, a pricing strategy.

This is where many papers go wrong: they skip from mechanism straight to a grab-bag of outcomes, never pausing to identify the specific decision boundary that their mechanism should affect. If you can't name the decision, your mechanism story is incomplete.

### Layer 4: Consequence

One result — the one closest to real economic allocation, contracting, or welfare — that shows the decision in Layer 3 has material downstream effects.

The test for whether a consequence belongs in the main text (rather than being demoted to "additional evidence" or cut entirely):

**Non-trivial consequences** — at least one of:
- Changes contract terms: financing costs, loan spreads, maturity, covenants, insurance pricing, supplier credit
- Changes resource allocation: capex, R&D direction, project initiation/termination, M&A, inventory, capacity, geographic reallocation
- Changes risk-bearing: leverage, cash policy, hedging, customer/supplier concentration, product-line risk exposure
- Changes welfare distribution: identifies who bears costs and who captures gains

**Should be demoted to mechanism/channel evidence** (not presented as main consequences):
- Media coverage, attention, search volume
- Generic disclosure changes
- Mild or short-lived market reactions
- Small, scattered accounting ratio movements
- Perception proxies that can't be mapped to real decisions

These aren't useless — they can support the mechanism layer — but they answer "the channel might be here" rather than "this is why the paper matters."

## Step 4: Choose a Narrative Route

Based on what the four-layer analysis reveals, recommend one of two routes:

### Route A: Constraint Transmission (preferred when strong real consequences exist)

The paper's story becomes:

> X doesn't universally affect everything. It changes a specific constraint or judgment for a specific type of agent. Only in high-friction, high-irreversibility, or high-information-asymmetry settings does this change transmit to real decision margins. The economic importance of X is therefore in resource allocation, not in a string of surface-level indicators.

This route works when:
- At least one Layer 4 consequence passes the "non-trivial" test above
- The heterogeneity analysis can define boundary conditions (not just "find significant subsamples")
- The average effect can be modest — that's fine, because the story is about *where* and *when* it matters

The power of this route: it turns heterogeneity analysis from "significance fishing" into "boundary condition definition." The depth jumps immediately because you're answering *when does X start having real costs?* instead of *does X affect yet another variable?*

### Route B: Surface Response vs Real Adjustment (preferred when real consequences are weak)

If the data genuinely can't support a strong real-margin outcome, don't fake it. The honest and often more interesting version:

> X triggers visible organizational/market responses, but these responses do not systematically translate to real decision changes. This suggests X's primary effect is performative or symbolic rather than substantive, and its economic impact has clear boundaries.

This route works when:
- Perception/disclosure/attention proxies are strong and robust
- But real allocation outcomes (capex, financing, contracts) are weak or null
- The paper can frame the disconnect as a finding, not a failure

This is not a consolation prize. Done well, it contributes by showing the literature has overestimated X's real effects, distinguishing "performative adaptation" from "substantive adjustment," and identifying the friction conditions needed for real transmission.

## Step 5: Draft the Defense Brief

Produce a structured defense brief with these sections:

### 1. One-Sentence Core Claim

The paper's main argument in one sentence. This should be specific enough that a reader knows what the paper is about and interesting enough that they'd want to read it. Test: if this sentence is boring, the paper has a narrative problem.

### 2. Four-Layer Map

Place every current result into the framework:

| Layer | Result | Current Location | Recommendation |
|-------|--------|-----------------|----------------|
| Fact | [baseline result] | Table 2 | Keep as main |
| Mechanism | [channel evidence] | Table 4 | Keep, sharpen framing |
| Decision | [decision margin] | Table 6, Col 3 | Elevate to main |
| Consequence | [real outcome] | Table 7 | Keep as payoff |
| *Unplaced* | [outcome X] | Table 5 | Demote to appendix |
| *Unplaced* | [outcome Y] | Table 8 | Cut |

### 3. Recommended Narrative Route

Route A or B, with a 2-3 paragraph explanation of why, referencing specific results.

### 4. What to Cut, Keep, and Reorganize

Three concrete lists:

**Keep in main text** (with rationale for each):
- [Result] — serves Layer [N] because [reason]

**Demote to appendix** (with rationale):
- [Result] — statistically significant but doesn't advance the causal chain; available for referees who ask

**Cut entirely** (with rationale):
- [Result] — doesn't fit any layer and doesn't serve as robustness for anything that does

### 5. Reviewer Response Strategy

For each piece of reviewer feedback that was categorized as "padding" or "deflecting":
- What the reviewer asked for
- Why adding it would dilute the paper
- What to offer instead (e.g., "move existing Table 5 to appendix and reference it" rather than running 3 new regressions)

The goal is not to ignore reviewers but to respond strategically: address the underlying concern without adding volume.

### 6. Heterogeneity Discipline

If heterogeneity analysis exists, evaluate whether each cut defines a boundary condition (good) or just finds another significant subsample (bad). Recommend keeping only heterogeneity that answers: "Under what conditions does the mechanism in Layer 2 actually transmit to Layers 3-4?"

## Step 6: Save and Summarize

Save the defense brief to:

```
<output_dir>/defend_paper_brief.md
```

Include a header with paper title, date, and field. Then print a summary:

```
Defense Brief Complete
======================
Saved to: <output_dir>/defend_paper_brief.md

Core claim: [one sentence]
Narrative route: [A or B]

Results map:
  Keep in main text:    N results
  Demote to appendix:   N results
  Cut:                  N results

Key recommendations:
  1. [most important structural change]
  2. [second most important]
  3. [third most important]

Reviewer responses drafted for N "padding" suggestions.

Next steps:
  /write-section    → rewrite introduction around the new core claim
  /make-table       → reorganize tables to match the four-layer structure
  /expert-review    → re-evaluate after restructuring
```
