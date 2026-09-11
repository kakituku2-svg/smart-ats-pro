(() => {
  'use strict';

  const VERSION = '5.3.0';
  const MARKER = 'TAIL_RISK_100 {';
  const ORDER_MARKER = 'ORDER_3_FORECAST {';
  const ROBUST_MARKER = 'ROBUST_FORECAST_GUARD {';

  const TAIL_RISK_BLOCK = `\n\nTAIL_RISK_100 {\n  purpose: "本線では薄いが、事前情報から具体的に説明でき、100円だけ残す価値がある高配当シナリオを切り捨てない";\n  classify_as: HIGH_PAYOUT_INSURANCE;\n  separate_from_main: true;\n  default_reference_stake_per_ticket: 100_JPY;\n  max_candidates: 3;\n  do_not_force_candidate: true;\n  trigger_if: [concrete_pre_race_causal_path_exists, probability_is_low_but_non_negligible, payout_impact_is_large, candidate_does_not_require_blind_box_or_total_spread];\n  priority_checks: [current_meeting_1st_or_2nd_despite_low_score, underrated_whole_line_survival, front_collapses_but_second_or_third_wheel_survives, pace_duel_promotes_solo_or_closer_to_1st_or_2nd, third_place_candidate_promotes_to_1st_or_2nd, strong_current_form_overrides_static_score_gap, cross_line_residual_exact_order];\n  reject_if: [odds_only_reason, popularity_only_reason, blind_box, total_spread, mutually_exclusive_tactics, no_causal_path];\n  output_each: [ticket, current_odds, causal_condition, rough_probability_band, why_100yen_is_worth_retaining];\n}\n`;

  const ORDER_3_BLOCK = `\n\nORDER_3_FORECAST {\n  purpose: "VALUE BETと着順予測を分離し、事前に説明可能な着順を第3候補までFreezeして検証する";\n  freeze_before_result: true;\n  never_rewrite_after_result: true;\n\n  A_VALUE_BET {\n    role: "最も買う価値が高い買い目";\n    output: [strategy, ticket_type, ticket, paper_stake, estimated_hit_probability, current_odds, market_implied_probability, EV, rationale];\n    allow_no_bet: true;\n    rule: "EV・資金効率・再現性の基準を満たさなければSKIP。着順3候補があっても無理に買わない";\n  }\n\n  B_MAIN_ORDER { role: "第1候補：最も起こりやすい着順"; format: "1着→2着→3着"; include_absolute_probability: true; }\n  C_SECONDARY_ORDER { role: "第2候補：本線の一部崩れを含む有力着順"; format: "1着→2着→3着"; include_absolute_probability: true; prioritize: [second_wheel_pass, front_survival, rival_line_self_power_survival, rival_line_second_wheel_survival, third_candidate_promotes_to_second, whole_line_survival, partial_line_collapse]; }\n  D_TERTIARY_ORDER { role: "第3候補：B/Cとは異なる合理的な展開分岐"; format: "1着→2着→3着"; include_absolute_probability: true; prioritize: [rival_line_whole_survival, front_runner_survival, second_wheel_reversal, solo_rider_promotion, third_candidate_promotes_to_first_or_second, alternate_line_intrusion]; reject: [same_scenario_simple_reordering_only, random_longshot, blind_box, result_hindsight]; }\n\n  separation_rules: [\n    "AとB/C/Dは一致してもよいが無理に一致させない",\n    "B/C/Dの3着順候補を全部買う前提にしない",\n    "結果後にB/C/Dを追加・変更して的中扱いにしない",\n    "3連単BETは完全一致でなければ不的中"\n  ];\n}\n\nORDER_3_AUDIT {\n  metrics: [value_bet_hit_and_ROI, first_place_match_rate, main_order_exact_rate, secondary_order_exact_rate, tertiary_order_exact_rate, any_of_3_exact_capture_rate, top3_set_match_rate, head_match_but_2nd_3rd_miss_count, pre_race_explainable_but_omitted_order_count];\n  evaluation: "AのROIとB/C/Dの着順捕捉率を別々に集計し、十分なサンプル後にウォークフォワード評価する";\n}`;

  const ROBUST_FORECAST_BLOCK = `\n\nROBUST_FORECAST_GUARD {\n  purpose: "候補数を増やして見かけの的中率を上げるのではなく、独立した展開分岐・確率校正・市場品質まで監査する";\n\n  DATA_QUALITY_GATE {\n    require: [odds_capture_time, race_card_freshness, lineup_confirmation, scratch_or_change_check, market_liquidity_check];\n    stale_or_thin_market: "PREVIEW_ONLY_OR_SKIP";\n    never_invent_missing_odds: true;\n    output: [data_quality_grade, missing_items, odds_age_minutes];\n  }\n\n  SCENARIO_DIVERSITY {\n    B_C_D_must_be_unique: true;\n    reject_cosmetic_reordering: true;\n    require_each: [trigger, pace_path, line_state, winner_reason, second_reason, third_reason, failure_condition];\n    diversity_dimensions: [winner_changes, surviving_line_changes, second_wheel_pass, front_survival, alternate_line_intrusion, solo_promotion, third_candidate_promotion];\n    output_diversity_score_0_to_100: true;\n  }\n\n  PROBABILITY_DISCIPLINE {\n    probabilities_are_absolute_not_normalized_within_top3: true;\n    require: [P_B, P_C, P_D, P_OTHER];\n    equation: "P_B + P_C + P_D + P_OTHER = 100%";\n    if_top3_total_too_high_without_evidence: "LOWER_CONFIDENCE";\n    calibration_bins: [0_5,5_10,10_20,20_35,35_plus];\n  }\n\n  LINE_FAILURE_MATRIX {\n    inspect_before_freeze: [main_line_full_survival, main_front_only, main_second_wheel_only, main_line_full_collapse, rival_line_full_survival, rival_front_plus_second, solo_intrusion];\n    rule: "強い本線だけでなく、どの部位が残る/消えるかを分解してB/C/Dへ反映する";\n  }\n\n  BET_SCENARIO_CONSISTENCY {\n    compare: [A_VALUE_BET, B_MAIN_ORDER, C_SECONDARY_ORDER, D_TERTIARY_ORDER];\n    if_value_bet_depends_on_low_ranked_scenario: "explicitly_explain_price_edge";\n    if_main_scenario_is_not_bet: "explicitly_explain_why_odds_or_ticket_efficiency_is_insufficient";\n    avoid_double_counting_correlated_tickets: true;\n  }\n\n  MARKET_MOVEMENT_AUDIT {\n    retain_freeze_odds: true;\n    compare_with_final_official_payout_or_closing_proxy: true;\n    metric: "closing_line_value_or_price_drift";\n    rule: "的中とは別に、Freeze時点で市場より良い価格を取れていたか検証する";\n  }\n\n  POST_RACE_ERROR_ATTRIBUTION {\n    classify_miss_as_one_primary_cause: [winner_read_error, line_survival_error, order_error, third_place_intrusion_error, market_value_error, stale_data_error, tactical_comment_overweight, random_race_noise];\n    secondary_cause_optional: true;\n    no_rule_change_from_single_case: true;\n  }\n\n  OUTPUT_ADDITIONS {\n    show: [data_quality_grade, scenario_diversity_score, P_B, P_C, P_D, P_OTHER, line_failure_matrix_summary, A_vs_BCD_consistency_note, freeze_odds_age];\n  }\n}`;

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.3.0 · ROBUST 3';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI分析プロンプト · v5.3.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = 'VALUE BET＋着順3候補を事前Freeze。候補の重複排除、絶対確率とOTHER残余、ライン崩壊表、データ品質、オッズ鮮度、買い目との整合、結果後の誤差原因まで監査します。';
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = output.value
      .replace(/v4\.9\.0/g, `v${VERSION}`)
      .replace(/v5\.0\.0/g, `v${VERSION}`)
      .replace(/v5\.1\.0/g, `v${VERSION}`)
      .replace(/v5\.2\.0/g, `v${VERSION}`)
      .replace(/THREE_PATTERN_FORECAST \{[\s\S]*?THREE_PATTERN_AUDIT \{[\s\S]*?\n\}/g, '');
    if (!value.includes(MARKER)) value += TAIL_RISK_BLOCK;
    if (!value.includes(ORDER_MARKER)) value += ORDER_3_BLOCK;
    if (!value.includes(ROBUST_MARKER)) value += ROBUST_FORECAST_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(output.value.length);
  }

  document.addEventListener('DOMContentLoaded', () => {
    patchVersionUI();
    const form = document.getElementById('race-form');
    if (form) form.addEventListener('submit', () => { setTimeout(() => { patchVersionUI(); patchPrompt(); }, 0); setTimeout(patchPrompt, 80); });
    const output = document.getElementById('prompt-output');
    if (output) new MutationObserver(() => patchPrompt()).observe(output, { attributes: true, childList: true, subtree: true });
    ['copy-button','share-button','download-button'].forEach(id => { const btn=document.getElementById(id); if(btn) btn.addEventListener('click', patchPrompt, true); });
  });
})();
