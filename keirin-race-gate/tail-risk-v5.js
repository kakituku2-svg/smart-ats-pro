(() => {
  'use strict';

  const VERSION = '5.5.0';
  const BLOCKS = [
`\n\nTAIL_RISK_100 {
  purpose: "本線では薄いが、事前情報から具体的に説明でき、100円だけ残す価値がある高配当シナリオを切り捨てない";
  classify_as: HIGH_PAYOUT_INSURANCE;
  separate_from_main: true;
  default_reference_stake_per_ticket: 100_JPY;
  max_candidates: 3;
  do_not_force_candidate: true;
  trigger_if: [concrete_pre_race_causal_path_exists, probability_is_low_but_non_negligible, payout_impact_is_large, candidate_does_not_require_blind_box_or_total_spread];
  priority_checks: [current_meeting_1st_or_2nd_despite_low_score, underrated_whole_line_survival, front_collapses_but_second_or_third_wheel_survives, pace_duel_promotes_solo_or_closer_to_1st_or_2nd, third_place_candidate_promotes_to_1st_or_2nd, strong_current_form_overrides_static_score_gap, cross_line_residual_exact_order];
  reject_if: [odds_only_reason, popularity_only_reason, blind_box, total_spread, mutually_exclusive_tactics, no_causal_path];
  output_each: [ticket, current_odds, causal_condition, rough_probability_band, why_100yen_is_worth_retaining];
}`,
`\n\nAXIS_FAILURE_TAIL_RISK {
  purpose: "通常本線の軸が3着外へ飛ぶ世界を毎回独立検査し、まず3連複で残る3人集合を拾う";
  mandatory_check_every_race: true;
  rebuild_without_main_axis: true;
  question: "本線軸が完全に飛ぶなら、事前情報だけで最も説明可能な上位3人集合は何か";

  RE_RANK_WITHOUT_AXIS {
    use: [current_meeting_1st_2nd_quality, recent_3_5_meets, line_survival, low_score_but_live_form, front_collapse_then_second_third_wheel_survival, rival_whole_line_survival, pace_duel_beneficiary, solo_or_closer_rise, third_candidate_to_first_or_second, bank_fit, rider_comments, odds_value];
    do_not_anchor_to_original_favorite: true;
    do_not_require_any_original_main_member: true;
  }

  TRIO_FIRST {
    priority: HIGHEST_WITHIN_TAIL_RISK;
    rule: "順序を当てに行く前に、軸なしの3人集合を3連複で作る";
    max_candidates: 3;
    reference_stake_each: 100_JPY;
    prefer_if: [trio_odds_100_plus, trio_odds_50_to_100_with_strong_causal_path, current_meeting_form_supports_all_3, line_or_pace_path_supports_all_3];
    especially_recheck_if: [100_plus, 200_plus, low_score_current_meeting_top2_pair, underrated_line_plus_live_cross_line_rider];
    reject_if: [odds_only, popularity_fade_only, blind_box, total_spread, no_joint_survival_path];
    output_each: [trio_ticket, current_odds, axis_failure_trigger, why_these_3_survive, why_100yen_is_worth_retaining];
  }

  TRIFECTA_SECOND {
    add_only_if_order_has_causal_edge: true;
    max_candidates: 3;
    reference_stake_each: 100_JPY;
    inspect_orders: [line_front_expends_and_second_wheel_passes, third_candidate_promotes_to_second, whole_line_or_partial_line_survival, solo_or_closer_promotes_to_head, cross_line_residual_order];
    prefer_if_odds: [100_plus, 200_plus];
    never_generate_from_trio_by_random_permutation: true;
    output_each: [trifecta_ticket, current_odds, exact_order_trigger, why_100yen_is_worth_retaining];
  }

  if_no_valid_case: "高配当保険なし";
  accounting: "100円は参考提案額。ユーザーが購入を明示しない限り実収支に入れない";
}`,
`\n\nORDER_3_FORECAST {
  purpose: "VALUE BETと着順予測を分離し、事前に説明可能な着順を第3候補までFreezeして検証する";
  freeze_before_result: true;
  never_rewrite_after_result: true;
  A_VALUE_BET { role: "最も買う価値が高い買い目"; output: [strategy, ticket_type, ticket, paper_stake, estimated_hit_probability, current_odds, market_implied_probability, EV, rationale]; allow_no_bet: true; }
  B_MAIN_ORDER { role: "第1候補：最も起こりやすい着順"; format: "1着→2着→3着"; include_absolute_probability: true; }
  C_SECONDARY_ORDER { role: "第2候補：本線の一部崩れを含む有力着順"; format: "1着→2着→3着"; include_absolute_probability: true; prioritize: [second_wheel_pass, front_survival, rival_line_survival, third_candidate_promotes_to_second, partial_line_collapse]; }
  D_TERTIARY_ORDER { role: "第3候補：B/Cとは異なる合理的な展開分岐"; format: "1着→2着→3着"; include_absolute_probability: true; prioritize: [rival_line_whole_survival, second_wheel_reversal, solo_rider_promotion, third_candidate_promotes_to_first_or_second, alternate_line_intrusion, axis_failure_tail_risk_order]; reject: [same_scenario_simple_reordering_only, random_longshot, blind_box, result_hindsight]; }
  separation_rules: ["AとB/C/Dは一致してもよいが無理に一致させない", "B/C/Dを全部買う前提にしない", "結果後に候補を追加・変更しない", "3連単BETは完全一致でなければ不的中"];
}

ORDER_3_AUDIT {
  metrics: [value_bet_hit_and_ROI, first_place_match_rate, main_order_exact_rate, secondary_order_exact_rate, tertiary_order_exact_rate, any_of_3_exact_capture_rate, top3_set_match_rate, axis_failure_count, axis_failure_trio_capture_rate, tail_risk_trio_hit_rate, tail_risk_trifecta_hit_rate, pre_race_explainable_but_omitted_order_count];
}`,
`\n\nROBUST_FORECAST_GUARD {
  purpose: "候補数を増やして見かけの的中率を上げず、独立した展開分岐・確率校正・市場品質まで監査する";
  DATA_QUALITY_GATE { require: [odds_capture_time, race_card_freshness, lineup_confirmation, scratch_or_change_check, market_liquidity_check]; stale_or_thin_market: "PREVIEW_ONLY_OR_SKIP"; never_invent_missing_odds: true; }
  SCENARIO_DIVERSITY { B_C_D_must_be_unique: true; reject_cosmetic_reordering: true; require_each: [trigger, pace_path, line_state, winner_reason, second_reason, third_reason, failure_condition]; }
  PROBABILITY_DISCIPLINE { probabilities_are_absolute_not_normalized_within_top3: true; require: [P_B, P_C, P_D, P_OTHER]; equation: "P_B + P_C + P_D + P_OTHER = 100%"; }
  LINE_FAILURE_MATRIX { inspect_before_freeze: [main_line_full_survival, main_front_only, main_second_wheel_only, main_line_full_collapse, rival_line_full_survival, rival_front_plus_second, solo_intrusion, main_axis_outside_top3]; rule: "本線軸が飛ぶケースまで分解し、TAIL-RISK 3連複へ接続する"; }
  BET_SCENARIO_CONSISTENCY { compare: [A_VALUE_BET, B_MAIN_ORDER, C_SECONDARY_ORDER, D_TERTIARY_ORDER, AXIS_FAILURE_TAIL_RISK]; avoid_double_counting_correlated_tickets: true; }
  POST_RACE_ERROR_ATTRIBUTION { classify_miss_as_one_primary_cause: [winner_read_error, axis_failure_not_modeled, line_survival_error, order_error, third_place_intrusion_error, market_value_error, stale_data_error, tactical_comment_overweight, random_race_noise]; no_rule_change_from_single_case: true; }
}`,
`\n\nWALK_FORWARD_DATASET {
  purpose: "FINAL FREEZEを改変不能な学習用データセットとして蓄積し、100/300/500件単位で前向き検証する";
  append_only: true;
  never_backfill_prediction_fields_after_result: true;
  one_row_per_freeze: true;
  ROW_SCHEMA {
    identity: [freeze_id, race_date, venue, race_no, class, start_time, freeze_time];
    market: [ticket_type, ticket, stake, freeze_odds, odds_capture_time, odds_age_minutes, market_implied_probability, EV, data_quality_grade];
    model: [strategy, estimated_hit_probability, B_order, P_B, C_order, P_C, D_order, P_D, P_OTHER, line_failure_matrix_summary, axis_failure_scenario, tail_risk_trio_tickets, tail_risk_trifecta_tickets];
    outcome_after_settlement_only: [official_order, official_payout, paper_return, pnl, bet_hit, B_exact, C_exact, D_exact, any3_exact, top3_set_match, axis_finished_outside_top3, axis_failure_trio_exact_set_hit, tail_risk_trio_return_per_100, tail_risk_trifecta_return_per_100, primary_error_cause];
  }
  CHECKPOINTS { milestones: [100,300,500]; before_100: "探索期。原則ルール変更せず記録"; at_100: "初回診断"; at_300: "継続/縮小候補を判定"; at_500: "主要ルールの昇格/廃止候補を判断"; }
  WALK_FORWARD { chronological_only: true; no_random_shuffle: true; rule_change_applies_only_to_future_rows: true; }
  REPORT_METRICS { betting: [bets, investment, hits, hit_rate, payout, pnl, return_rate, profit_ROI]; forecast: [first_place_match_rate, any3_exact_rate, top3_set_match_rate, axis_failure_trio_capture_rate, tail_risk_trio_hit_rate, tail_risk_trifecta_hit_rate, tail_risk_virtual_return_per_100]; }
}`,
`\n\nOUTPUT_TAIL_RISK_INSURANCE {
  title: "■ 軸飛び高配当保険（100円参考枠）";
  always_report_check_result: true;
  order: [axis_failure_scenario, tail_risk_trio, tail_risk_trifecta_if_valid];
  trio_columns: [買い目, 取得時オッズ, 成立条件, 100円残す理由];
  trifecta_columns: [買い目, 取得時オッズ, 順序成立条件, 100円残す理由];
  trio_priority_over_trifecta: true;
  if_none: "高配当保険なし";
}`
  ];

  const MARKERS = ['TAIL_RISK_100 {','AXIS_FAILURE_TAIL_RISK {','ORDER_3_FORECAST {','ROBUST_FORECAST_GUARD {','WALK_FORWARD_DATASET {','OUTPUT_TAIL_RISK_INSURANCE {'];

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.5.0 · AXIS-FAIL TRIO';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI分析プロンプト · v5.5.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '本線＋着順3候補に加え、軸が飛ぶ世界を毎回独立検査。まず高配当3連複を100円参考枠で拾い、順序根拠がある時だけ3連単を追加します。';
  }

  function stripOldInjectedBlocks(value) {
    const patterns = [
      /TAIL_RISK_100 \{[\s\S]*?\n\}/g,
      /AXIS_FAILURE_TAIL_RISK \{[\s\S]*?\n\}/g,
      /ORDER_3_FORECAST \{[\s\S]*?ORDER_3_AUDIT \{[\s\S]*?\n\}/g,
      /ROBUST_FORECAST_GUARD \{[\s\S]*?\n\}/g,
      /WALK_FORWARD_DATASET \{[\s\S]*?\n\}/g,
      /OUTPUT_TAIL_RISK_INSURANCE \{[\s\S]*?\n\}/g
    ];
    patterns.forEach(p => { value = value.replace(p, ''); });
    return value;
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = output.value
      .replace(/v4\.9\.0/g, `v${VERSION}`)
      .replace(/v5\.[0-4]\.0/g, `v${VERSION}`)
      .replace(/THREE_PATTERN_FORECAST \{[\s\S]*?THREE_PATTERN_AUDIT \{[\s\S]*?\n\}/g, '');
    value = stripOldInjectedBlocks(value);
    value += BLOCKS.join('');
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(output.value.length);
  }

  document.addEventListener('DOMContentLoaded', () => {
    patchVersionUI();
    const form = document.getElementById('race-form');
    if (form) form.addEventListener('submit', () => {
      setTimeout(() => { patchVersionUI(); patchPrompt(); }, 0);
      setTimeout(patchPrompt, 80);
    });
    ['copy-button','share-button','download-button'].forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', patchPrompt, true);
    });
  });
})();
