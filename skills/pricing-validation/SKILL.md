---
name: pricing-validation
description: Rigorously validate and iterate a SaaS or product pricing and packaging plan against the canonical pricing and positioning literature (Monetizing Innovation, 7 Powers, Obviously Awesome, Influence, Building a StoryBrand). Use this whenever the user has pricing, tiers, packaging, price points, usage or generation limits, a value metric, or a monetization model to pressure-test, sanity-check, calibrate, stress-test, or "make sure the numbers and the strategy hold together" — even if they never say the word "validate." It runs a closed-loop audit: it first fills every spec gap (no empty cells), checks each pricing edge against a named framework, triggers web research for missing willingness-to-pay or competitor data, iterates with a correction loop until the plan converges to a stable fixed point, and surfaces genuine strategic forks for the user to decide rather than guessing. Reach for it the moment a conversation turns to "what should we charge / how should we package this."
---

# Pricing Validation

Validate and iterate a pricing and packaging plan until the numbers and the strategy hold together. Use this whenever someone has price points, tiers, packaging, usage limits, a value metric, or a monetization model to pressure-test, calibrate, or sanity-check.

## Why this skill exists

Pricing is a closed, interlocking system, not an open essay. In positioning or narrative work a missing nuance is a small sin and "complete" means covering the angles. In pricing the variables have to reconcile: price ↔ value metric ↔ limit ↔ cost ↔ margin ↔ competitor value-per-dollar ↔ tier consistency. A single missing variable invalidates the rest. You cannot judge a price without its limit, the limit without its unit cost, or the cost without the resulting margin.

The failure mode this prevents: delivering the strategic *argument* (premium vs not, abundance vs cap, the tier shape) while leaving the concrete *numbers* (the actual limits, the margin at the limit, which plan covers what) as "we'll get there." In pricing, the numbers are the deliverable. This process forces full specification, audits every edge against a framework, and iterates to a stable plan, so the gaps get caught here instead of by the customer or the founder.

## The lens (bibliography)

Reason in these frameworks; do not quote them at the user.

- **Monetizing Innovation** (Ramanujam & Tacke), the spine: willingness to pay, segmentation by WTP, the value metric, good-better-best packaging, leader/filler/killer features, the four packaging failures, the value story.
- **7 Powers** (Helmer): a price premium is the *realization* of brand power; price must cohere with the moat, not contradict it.
- **Obviously Awesome** (Dunford): value is judged against the real competitive alternative; price is a category signal.
- **Influence** (Cialdini): anchoring, the decoy / center-stage effect, loss aversion, charm and prestige pricing.
- **Building a StoryBrand** (Miller): the value story, every unit of price justified against the transformation.

## The process at a glance

0. **Spec gate**, fill every slot. No empty cells, or the audit cannot run.
1. **Sweep**, score every edge: PASS / FAIL / NEEDS-DATA / FORK.
2. **Resolve**, auto-correct objective FAILs, research NEEDS-DATA, surface FORKs to the user (never auto-pick).
3. **Re-sweep all edges**, any change can cascade and break a previously passing edge.
4. **Stop at the fixed point**, when a full sweep produces zero corrections and zero data-gaps and only user FORKs remain.

Output: the reconciled plan + a validation log + the open forks.

## Stage 0 — Spec completeness gate

The plan is not auditable until each tier has every slot filled. If a slot is empty, fill it (research if the gap is external data) before auditing, because in a closed system an empty slot makes the whole plan unverifiable.

Per tier:
- Persona (one sentence, the buyer you can name)
- Price
- Value metric + the actual limit (the unit AND the number)
- What is included (the features / leaders)
- Upgrade trigger (the felt reason to move up)
- Cost at typical usage
- Cost at the limit, and at the worst case (e.g. the expensive model or path)
- Margin: typical / at-limit / worst-case
- Value-per-dollar vs the alternative the buyer actually compares to
- Fence (what stops a buyer getting this tier's value more cheaply by gaming)

Plan-level:
- Pricing strategy (skim / penetration / neutral) + justification
- Acquisition front door (free / trial / freemium / demo)
- Anchor tier + target tier
- Discount levers (annual, founders, etc.)
- The one-sentence value story
- Internal reconciliation (ladder ratios, anti-split math, limit gradient)

If an existing pricing or cost doc exists, ingest it fully first. It is both the cost model and the completeness checklist: every element it enumerates, your plan must address.

## The edges

Each edge has a framework and an objective pass criterion. Detailed guidance, with what good and bad look like and how to correct, is in `references/edges.md`. Read it when running a full validation.

**A — Demand & willingness to pay** (Monetizing Innovation)
- **A1 WTP grounding:** every price traces to evidence (research, a competitor's validated price, your own funnel). Fail if any number is invented. Research if WTP evidence is missing.
- **A2 Segmentation:** tiers split by need / WTP, not demographics; each tier maps to one nameable, distinct persona.

**B — Packaging & value metric** (Monetizing Innovation)
- **B1 Value metric:** the metered unit aligns with value received, scales with the customer's success, is cost-defensible, is understandable, and is not brand-corrosive.
- **B2 Leader / Filler / Killer:** category-defining leaders sit in the entry tier (no leader buried above it); killer features that repel a persona are fenced away from it; every upgrade is pulled by a felt leader.
- **B3 The four failures cleared:** feature shock (too much, confusing), minivation (underpriced innovation), hidden gem (a leader buried in the wrong tier), undead (a thing nobody wants).
- **B4 Fence integrity:** the cheaper-by-gaming path (e.g. an agency buying N entry seats instead of the multi-brand tier) must not beat the honest path.

**C — Psychology & positioning coherence** (Cialdini + Dunford + Helmer + StoryBrand)
- **C1 Anchor & decoy:** there is a clear high anchor and an honest target; ratios create the right pull; no fabricated "most popular."
- **C2 Price-as-signal:** the entry price signals the intended category (e.g. partner, not toy); price coheres with the premium / moat / positioning rather than contradicting it.
- **C3 Pricing strategy** chosen and justified (skim / penetration / neutral) against brand power, capital plan, and motion, not defaulted.
- **C4 Value story:** one sentence, anchored on the real alternative, that survives a skeptical buyer.

**D — Economic reality** (the cost model)
- **D1 Margin closes** at typical, at the limit, and at the worst case (e.g. all-premium), with and without any temporary subsidy; margin ≥ the declared floor in each.
- **D2 Internal reconciliation:** every number coheres across tiers, ladder ratios, anti-split, per-unit consistency, the limit gradient. No two cells contradict.

**E — Competitive & experience** (Dunford + behavioral)
- **E1 Value-per-dollar:** at each tier you win the value-per-dollar comparison on your axis vs the alternative the buyer actually weighs, and the claim survives a single counter-example. Research the competitor's real offering if you are asserting without data. Compare like-for-like (convert usage units), not headline-vs-headline.
- **E2 Customer feeling:** walk each touchpoint, seeing the page, hitting the limit, the upsell moment, the entry experience, the multi-brand / agency experience, and confirm none produces anxiety, a stripped-down feeling, or a sense of being manipulated.

## The iteration loop and its correction criterion

Score each edge, then act by type:

- **FAIL (objective)** — the math does not close, a slot is empty, two cells contradict, or a framework rule is clearly violated with an unambiguous fix. Correct it, and log the change.
- **NEEDS-DATA** — the edge cannot be judged without external evidence. Trigger research (below), fill the gap, re-judge.
- **FORK (judgment)** — a genuine strategic tradeoff with no objectively right answer (premium vs accessible, how generous the limit is, capture WTP now vs buy adoption). Surface it to the user as a decision, mark the edge PENDING-DECISION, and never silently pick a side.

After *any* change, re-run the whole sweep. Fixing one edge often breaks another (raising a price fixes minivation but can break anti-split or value-per-dollar). This cascade is exactly why a single pass is not enough.

**Stop at the fixed point:** a full sweep that produces zero corrections and zero data-gaps, with only user FORKs left open. That stability is the signal the plan is internally sound.

**Oscillation guard:** if fixing A breaks B and fixing B breaks A across more than ~5 sweeps, stop. Oscillation means a real tradeoff is being papered over, surface it as a fork for the user instead of churning.

## When and how to research

An edge that cannot pass on internal evidence fires a targeted web search. Keep the question specific. Typical triggers:

- A1 / E1: a competitor's current price points, what each tier includes, and how their usage units convert (so you compare like-for-like, not a big headline number against a small one).
- WTP benchmarks for the category; typical good-better-best ratios; anchor norms.
- Cost benchmarks if no internal cost model exists.

Cite what is research-backed vs assumed. Mark assumptions as "to validate post-launch" and name the metric that will validate them.

## Output format

1. **The reconciled plan** — the filled slot table, all cells populated and cross-consistent.
2. **The validation log** — per edge: verdict, the evidence, what changed across iterations, and research-backed vs assumed.
3. **The open forks** — the strategic decisions only the user can make, each with the options and your recommendation.

## Anti-patterns (the reasons this skill exists)

- **Essay-mode in a spreadsheet problem.** Delivering the strategic shape without the reconciled numbers. The numbers are the deliverable.
- **"We will get there later."** In a closed system a deferred number is a present gap that makes the plan unverifiable. Fill it now.
- **Ignoring the existing cost or pricing doc.** Ingest it fully first; it is the cost model and the completeness checklist.
- **Auto-resolving a strategic fork.** Premium-vs-accessible and similar are the user's calls. Surface, recommend, but do not decide for them.
- **One-question-at-a-time on an interlocking system.** Lay the whole reconciled model down, then iterate it as a whole. Decomposing it fabricates gaps.
