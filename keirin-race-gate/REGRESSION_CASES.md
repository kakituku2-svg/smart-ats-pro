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
