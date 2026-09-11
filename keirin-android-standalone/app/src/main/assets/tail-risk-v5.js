(() => {
  'use strict';

  const VERSION = '5.7.0';
  const FORECAST_BLOCK = `

DATA_FRESHNESS_GATE_V57 {
  purpose: "古いページや結果確定後の情報を混入させず、発走前の最新公開情報で予想する";
  immutable_target: [race_date, venue, race_no];
  capture_before_analysis: [current_JST_time, scheduled_start_time_if_available, source_name, source_updated_time_if_available];
  source_priority: [WINTICKET_CURRENT_CARD_AND_ODDS, KEIRIN_JP_OFFICIAL, official_velodrome, other_verifiable_pre_race_sources];
  required_current_checks: [scratches, lineup, rider_comments, current_meeting_results, weather_and_wind, current_odds];
  recency_windows: { micro_form: LAST_1_TO_2_RACES_HIGHEST_WEIGHT; supporting_form: LAST_3_TO_6; stable_base: ABOUT_LAST_20; };
  if_source_is_stale_or_timestamp_unknown: MARK_UNCERTAINTY_AND_REDUCE_CONFIDENCE;
  if_target_has_started_or_finished: "予想を捏造せず、事前予想対象外と明記する";
  never_use: [result, payout, post_race_article, post_result_update, knowledge_of_finish_order];
}

RACE_VALUE_SELECTION_V57 {
  purpose: "買い目作成前に、そのレース自体を買う価値があるか採点する";
  score_0_to_100_from: [first_place_clarity, first_second_relation_clarity, top3_pool_clarity, lineup_clarity, scenario_branch_count, recent_form_readability, current_odds_value, data_freshness];
  grade: { S: "80-100"; A: "70-79"; B: "60-69"; C: "50-59"; SKIP: "0-49"; };
  buying_policy: "A以上を中心。Bは明確な価格優位がある時だけ。C以下は原則見送り";
  do_not_force_bet: true;
  output: [score, grade, one_sentence_reason];
}

HEAD_PLACE_SEPARATION_V57 {
  purpose: "勝てる選手と、2・3着に残る選手を完全に分けて評価する";
  HEAD_SCORE_inputs: [rating_score, win_rate, self_power, B_count, H_count, nige, makuri, sashi, current_form, line_advantage, likely_control];
  PLACE_SCORE_inputs: [top3_rate, top2_rate, recent_second_third_finishes, second_or_third_wheel_position, front_strength, energy_saving, inside_path, tracking_stability, scenario_fit];
  required_per_rider: [HEAD_SCORE_band, PLACE_SCORE_band, win_probability_band, top3_probability_band];
  low_win_high_top3_rule: "勝率が低くても3連対率が高く、直近2・3着、強い先行の番手・3番手、脚温存経路がある選手は3連複候補へ昇格";
  strong_rival_rule: "別線自力は頭だけでなく、本線の後ろで3着に残る経路も評価";
  third_wheel_rule: "3車ライン3番手を自動3着にも自動消しにもせず、別線自力・単騎・残存型とPLACE_SCOREで比較";
}

PROBABILITY_PRICE_EV_V57 {
  purpose: "最頻結果と最も買う価値が高い買い目を分離する";
  strict_order: [scenario_probability_model, top3_set_probability, exact_order_probability, current_odds_check, fair_odds, minimum_acceptable_odds, EV, BUY_OR_SKIP];
  fair_odds_formula: "1 / model_probability";
  minimum_acceptable_odds: { confidence_A: "fair_odds * 1.10_to_1.15"; confidence_B: "fair_odds * 1.20_to_1.30"; confidence_C: "fair_odds * 1.35_or_more"; };
  ev_formula: "model_probability * current_decimal_odds";
  ev_guide: { skip: "below_1.10"; candidate: "1.10-1.19"; strong: "1.20-1.39"; high: "1.40_plus"; };
  probability_precision: "不確実なら単一点でなく範囲を使い、見かけの精密さを作らない";
  if_current_odds_unavailable_or_market_thin: "PREVIEW扱い。BUYを確定せず、信頼度とEVを割り引く";
  do_not_promote_to_main_only_for_high_odds: true;
  output_for_each_final_ticket: [model_probability_or_range, fair_odds_or_range, minimum_acceptable_odds, current_odds, market_implied_probability, EV_or_range, BUY_OR_SKIP];
}

APP_MODE_FORECAST_ONLY {
  purpose: "このアプリは指定された1レースについて、その場でWeb調査して予想・買い目を返すためのもの";
  execute_now: true;
  single_race_scope: true;
  use_only_pre_race_information: true;
  do_not_wait_for_result: true;
  do_not_schedule_followup: true;
  do_not_start_backtest: true;
  do_not_create_dataset: true;
  do_not_tell_user_to_freeze_or_verify_later: true;
  forbidden_output_topics: [FINAL_FREEZE, post_race_reconciliation, later_settlement, daily_report, walk_forward_dataset, checkpoint_progress, future_verification_instruction];
  if_target_race_already_finished: "結果を予想として扱わず、既に終了済みと明記する";
  first_response_rule: "前置きや工程説明から始めず、取得できた事前情報に基づくレース分析と予想をすぐ提示する";
}

TRIO_FIRST_ENGINE {
  purpose: "1着固定から組み立てる前に、3着以内に残る3人集合を独立評価し、3連複の再現性を高める";
  order_of_reasoning: [top3_survival_probability_by_rider, viable_three_rider_sets, exact_order_expansion];
  score_each_rider_for: [win, second, third, top3];
  build_3_to_6_live_trios_before_exact_order: true;
  retain_only_scenario_backed_trios: true;
  inspect: [main_line_survival, front_plus_second_wheel, second_plus_third_wheel, rival_whole_line, cross_line_residual, solo_intrusion, current_meeting_form_pair, low_win_high_top3_profile];
  reject: [blind_box, popularity_copy, score_rank_only, mutually_exclusive_survival];
  output: "最終的には推奨3連複だけに絞り、候補生成過程を冗長に列挙しない";
}

AXIS_FAILURE_SCORE {
  purpose: "通常軸が3着外へ飛ぶ危険度を独立評価する";
  scale: 0_TO_100;
  estimate_from: [axis_current_meeting_quality, recent_3_5_meets, expected_position, line_protection, pace_pressure, bank_fit, rival_line_strength, comment_signal, style_composition, start_and_finish_risk];
  never_derive_from_odds_alone: true;
  guide: { low: "0-14", watch: "15-24", material: "25-39", high: "40+" };
  if_15_plus: "軸なし3連複を最低1回再検査";
  if_25_plus: "本線評価を再点検し、A+等の強評価を自動維持しない";
  output: [score, short_reason];
}

MARKET_GAP_SCORE {
  purpose: "起こりやすさと買う価値を分離し、市場が過小評価している買い目を探す";
  compare: [model_estimated_probability, current_market_implied_probability, current_odds, scenario_quality, data_quality];
  scale: MINUS_100_TO_PLUS_100;
  positive_means: "モデル側が市場より高く評価";
  rules: [do_not_invent_probability_precision, show_probability_as_range_when_uncertain, no_value_claim_without_current_odds, odds_are_post_model_check_not_primary_forecast];
  output_for_recommended_tickets: [estimated_probability_or_range, current_odds, implied_probability_if_calculable, market_gap_score, value_label];
}

CURRENT_FORM_VALUE_OVERRIDE {
  purpose: "静的な競走得点より、当開催の実走内容が強い人気薄を見落とさない";
  upgrade_if_supported_by: [current_meeting_1st_or_2nd, strong_finish, successful_long_sprint_or_makuri, good_positioning, line_role_fit, recent_improvement, comment_consistency];
  downgrade_if: [result_only_without_content, lucky_incident_only, tiny_sample_without_support];
  rule: "低得点という理由だけで高配当候補から除外しない";
}

COMMENT_TO_TACTICS {
  purpose: "直近コメントを展開予測へ具体的につなげる";
  required: [quote_or_paraphrase_current_public_comment_if_available, explain_tactical_implication, compare_with_recent_race_behavior];
  historical_pattern_if_accessible: "同選手の過去の似たコメントとその後の走りが確認できる場合のみ、件数と一致度を添えて補助材料にする";
  never: [invent_old_comments, claim_deterministic_behavior_from_one_comment, overrule_strong_form_with_one_negative_comment];
}

TAIL_RISK_100_V56 {
  purpose: "本線とは別に、軸飛び世界で説明可能な高配当を100円参考枠で残す";
  mandatory_axis_out_scenario_check: true;
  rebuild_without_main_axis: true;
  trio_first: true;
  max_trio_candidates: 3;
  max_trifecta_candidates: 3;
  reference_stake_each: 100_JPY;
  trio_priority: [100_plus_odds, 50_to_100_with_strong_causal_path];
  trifecta_priority: [100_plus_odds, 200_plus_odds];
  candidate_sources: [current_meeting_top2_low_score, underrated_whole_line_survival, front_collapse_second_third_survive, pace_duel_solo_closer_rise, third_candidate_to_first_or_second, cross_line_residual];
  trifecta_only_if_exact_order_has_causal_edge: true;
  reject: [odds_only, popularity_only, blind_box, total_spread, random_permutation];
  if_none: "高配当保険なし";
}

PORTFOLIO_DECISION_V56 {
  purpose: "的中率最大化ではなく、長期の総合収支を改善するため券種と強弱を選ぶ";
  separate: [MOST_LIKELY_OUTCOME, BEST_VALUE_TICKET];
  main_trio_first: true;
  trifecta_only_where_order_edge_exists: true;
  do_not_force_fixed_budget_ratio: true;
  stake_strength_inputs: [forecast_confidence, market_gap, axis_failure_score, scenario_overlap, odds_quality];
  avoid_correlated_overbetting: true;
  if_value_is_poor: "本命でも見送り・薄めを許可";
}

DIRECT_OUTPUT_CONTRACT_V57 {
  language: JAPANESE;
  start_immediately_with_analysis: true;
  no_process_preamble: true;
  no_future_work_statement: true;
  no_freeze_statement: true;
  no_backtest_statement: true;
  no_result_reconciliation_statement: true;
  concise_but_evidence_rich: true;
  output_order: [
    "1. データ時点・対象レース照合・主要ソース",
    "2. 勝負度：0〜100点とS/A/B/C/SKIP",
    "3. 結論：最も起こりやすい結果と最も買う価値が高い目を分離",
    "4. 選手別の直近3〜5場所＋当開催内容（着順ではなく何が良い/悪いかまで）",
    "5. ライン・脚質人数構成、HEAD順位、PLACE順位",
    "6. 直近コメントと展開への影響。確認できれば似たコメント時の過去挙動も補助表示",
    "7. 想定展開：最頻・逆転・妙味・踏み合い崩れ・軸飛び",
    "8. TRIO-FIRSTで残す3人集合と3連複",
    "9. 順序根拠が強い2車単・3連単",
    "10. 確率・フェア・最低許容・現在オッズ・EV・MARKET GAP付き最終推奨3〜6点",
    "11. AXIS FAILURE SCORE",
    "12. 高配当保険100円：3連複優先、必要時のみ3連単"
  ];
  final_ticket_table_columns: [区分, 券種, 買い目, 想定確率帯, フェアオッズ, 最低許容, 現在オッズ, EV, MARKET_GAP, BUY_SKIP, 狙う展開, 金額];
  stake_rule: "100円単位。予算不明なら相対配分。本線を含めても価格不適正なら見送り。無理に予算を使い切らない";
  do_not_output: ["検証します", "フリーズします", "結果後に照合します", "後ほど確認します", "データセットへ保存します", "チェックポイントまで蓄積します"];
  closing_rule: "予想と買い目を提示したら終了。ユーザーが求めていない検証計画や運用説明を追加しない";
}

EXECUTE_FORECAST_NOW_V57: "TARGETの最新事前公開情報を調査し、DIRECT_OUTPUT_CONTRACT_V57の順で直ちに予想と買い目を返す。";`;

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.7.0 · LIVE DATA / EV';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.7.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '開催日・開催場・Rを選ぶだけ。最新の事前データを確認し、3人集合→着順→価格→EV→軸飛び高配当の順で分析するAI用プロンプトを生成します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.7.0 · 20歳以上 / 予想支援ツール';
    const androidLink = document.querySelector('.android-download-button');
    if (androidLink) androidLink.setAttribute('href', './downloads/KEIRIN-RACE-GATE-Android-Standalone-v5.7.0.apk');
  }

  function stripLegacyInjected(value) {
    const startMarkers = [
      'TAIL_RISK_100 {',
      'AXIS_FAILURE_TAIL_RISK {',
      'ORDER_3_FORECAST {',
      'ROBUST_FORECAST_GUARD {',
      'WALK_FORWARD_DATASET {',
      'OUTPUT_TAIL_RISK_INSURANCE {',
      'APP_MODE_FORECAST_ONLY {'
    ];
    let cut = value.length;
    startMarkers.forEach(marker => {
      const i = value.indexOf(marker);
      if (i >= 0 && i < cut) cut = i;
    });
    if (cut < value.length) value = value.slice(0, cut).trimEnd();
    return value;
  }

  function sanitizeBasePrompt(value) {
    value = value
      .replace(/v4\.9\.0/g, `v${VERSION}`)
      .replace(/v5\.[0-6]\.0/g, `v${VERSION}`)
      .replace(/freeze_rule:\s*USE_ONLY_INFORMATION_AVAILABLE_BEFORE_TARGET_RACE_RESULT;/g, 'pre_race_only_rule: USE_ONLY_INFORMATION_AVAILABLE_BEFORE_TARGET_RACE_RESULT;')
      .replace(/FINAL_PRE_RACE_AUDIT \{/g, 'PRE_OUTPUT_QUALITY_AUDIT {')
      .replace(/EXECUTE_NOW:\s*Research TARGET and return the forecast using OUTPUT_CONTRACT\.;?/g, '');
    return stripLegacyInjected(value);
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = sanitizeBasePrompt(output.value);
    value += FORECAST_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(output.value.length);
  }

  function selfTest(value) {
    const forbidden = [
      'WALK_FORWARD_DATASET {',
      'ORDER_3_AUDIT {',
      'freeze_before_result: true',
      'never_rewrite_after_result: true',
      'POST_RACE_ERROR_ATTRIBUTION',
      '結果後に候補を追加・変更しない'
    ];
    return forbidden.filter(x => value.includes(x));
  }

  document.addEventListener('DOMContentLoaded', () => {
    patchVersionUI();
    const form = document.getElementById('race-form');
    if (form) form.addEventListener('submit', () => {
      setTimeout(() => {
        patchVersionUI();
        patchPrompt();
        const out = document.getElementById('prompt-output');
        if (out) {
          const bad = selfTest(out.value);
          if (bad.length) console.error('v5.7 prompt guard failed:', bad);
        }
      }, 0);
      setTimeout(patchPrompt, 80);
    });
    ['copy-button','share-button','download-button'].forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', patchPrompt, true);
    });
  });
})();
