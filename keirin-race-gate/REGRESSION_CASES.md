# KEIRIN RACE GATE — Regression Cases

These cases are regression fixtures for logic QA only. They must never be used as direct predictive evidence for a new race.

## 2026-09-08 いわき平 2R
- Confirmed result: **2-7-6**
- Regression lesson: do not cut a low-rated follower/tail only because of low individual score or win rate.
- Required audit: if the front/self-powered rider creates the race, explicitly test whether the second wheel or line tail can conserve energy and survive into 3rd.
- Required audit: strong front + second wheel + low-rated follower must remain a trio candidate when a causal survival path exists.

## 2026-09-08 大垣 12R
- Confirmed result: **3-1-7**
- Regression lesson: correctly identifying the winner candidate is not enough when the 2nd/3rd-place set is wrong.
- Required audit: score head selection and top-3-set selection separately.
- Required audit: even when the winning self-powered rider is correctly rated, test cross-line chasers/markers for 2nd/3rd-place residual survival.
- Required audit: do not merge evidence or results from a different race into this case.

## Race identity invariant
Every race datum must be keyed by **date + venue + race number** before being used. User corrections apply only to the exact keyed race. Cross-race result transfer is forbidden.


## 2026-09-08 西武園 2R
- Confirmed result: **4-7-6**
- Regression lesson: do not treat an extreme longshot third-place finisher as automatically unpredictable when a verified human-context signal can justify re-opening a place-finish path.
- Required audit: separate raw ability from the practical value of finishing 1st, 2nd, or 3rd for each rider.
- Required audit: check publicly verifiable background such as class/grade status, term points, promotion/demotion or registration-review context, supplemental entry, final-day context, home/same-prefecture context, announced retirement/last run, and public training-partner information.
- Guardrail: background is a bounded adjustment only. Never invent private motivation, financial need, family circumstances, collusion, or a "must try harder" narrative.
- Guardrail: supplemental entry, local status, or same-prefecture relationships never create automatic ability upgrades.


## 2026-09-08 西武園 4R
- Confirmed result: **5-7-4**
- Regression lesson: the model correctly rated 5 as the main winner and 7 as a strong top-3 survivor, while 4 was already recognized as a 2nd/3rd-place candidate, but the trio **4-5-7** was never generated.
- Failure type: **candidate-to-ticket conversion miss**, not a pure rider-identification miss.
- Required audit: after ranking top-3 survival candidates, fix each major axis and enumerate every unordered pair among the remaining top-5 candidates.
- Required audit: if axis + high-survival candidate + overlooked place candidate can coexist under one causal race path, compare and retain that trio even when the overlooked rider ranks only 4th or 5th overall.
- Girls/no-fixed-line rule: because riders are not bound to a fixed line, evaluate coexistence of position-taking, following, and saved-energy riders more broadly than in a standard men's line race.
- Guardrail: do not generate every combination blindly. A trio must have a causal coexistence path; popularity alone cannot be the reason it is dropped.
