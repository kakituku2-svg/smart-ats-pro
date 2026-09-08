# Shared Prediction Logic — Human Context / Stakes Layer

Version: 1.0
Date: 2026-09-08

## Purpose
Use publicly verifiable human/context incentives as a bounded secondary layer in race prediction systems. This layer must never replace ability, form, lineup/pace, or market evidence.

## Common principles
- Public evidence only.
- Score the value of finishing 1st, 2nd, and 3rd separately.
- Motivation is not ability.
- A background signal can re-open a plausible path; it cannot create one from nothing.
- Default maximum adjustment: one qualitative tier.
- If evidence is unavailable or speculative, adjustment = zero.
- Never infer family finances, private debt, private emotions, secret agreements, collusion, or "must try harder" narratives.
- Historical regression cases are QA fixtures only, never direct predictive evidence.

## Keirin
Inspect when public/derivable:
- Grade/class status and promotion/demotion context
- Term score / end-of-term point importance
- Forced-retirement / registration-review risk when supported by official rules/data
- Special promotion/advancement conditions
- Supplemental entry
- Final-day / last-chance context
- Local / same-prefecture line context
- Publicly listed training partners
- Explicit return from injury/long absence
- Announced retirement / last run
- Advancement/elimination pressure

Application:
- Do not add the same adjustment to 1st/2nd/3rd.
- A point-preservation context usually re-opens 2nd/3rd survival before 1st-place strength.
- Supplemental entry is a review trigger, not an automatic boost.
- Same-prefecture/training relationships are tactical context only, never evidence of collusion.

## Horse racing
Apply the same bounded principle to publicly verifiable human/race context, adapted to racing:
- Official jockey/trainer comments
- Publicly stated target-race / preparation intent
- Class/eligibility and advancement conditions
- Return from layoff/injury only when officially/publicly stated
- Jockey change/booking context as a tactical signal, not hidden intent
- Race placement within a campaign when supported by public statements
- Equipment/tactics changes that are publicly declared

Do not infer:
- Stable "inside information"
- Secret target races
- Owner financial pressure
- Hidden instructions
- Collusion or deliberate non-competition

## Output requirement
For each participant/rider:
- background_signal: NONE / LOW / MEDIUM / HIGH
- verified_reason
- target_finish_most_valuable: 1st / 2nd / 3rd / none
- confidence_in_signal
- bounded_adjustment_applied
