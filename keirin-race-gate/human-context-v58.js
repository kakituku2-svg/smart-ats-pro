(() => {
  'use strict';

  const VERSION = '5.10.0';
  const MARKER = 'HUMAN_CONTEXT_STAKES_V510 {';
  const HUMAN_BLOCK = `

HUMAN_CONTEXT_STAKES_V510 {
  purpose: "公開根拠のある人的背景を、能力・ライン・直近状態・脚質・オッズとは別の事前特徴量として展開確率へ反映する";
  mandatory_before_forecast_if_public: [home_bank_or_local_race, same_prefecture_or_region, mentor_student, senior_junior, same_class_or_cohort, same_training_group_or_team, past_coordination_count, past_coordination_roles, past_coordination_finish_patterns, role_declaration_in_current_comments, advancement_condition, semifinal_or_final_incentive, class_change_or_return_context, milestone_or_special_local_context];
  evidence_priority: [official_profile, official_or_verified_rider_comment, official_race_card, specialist_pre_race_article, verifiable_past_coordination_record];
  never_infer_without_public_evidence: [friendship, favoritism, collusion, private_relationship, hidden_intent, result_based_story];
  use_as: "能力を無条件で上書きする材料ではなく、仕掛け時期・役割遂行・番手差し・前残り・3番手残存・着拾い優先度・ライン残存率を補正する特徴量";
  if_background_conflicts_with_form_or_ability: "人的背景だけで逆転させず、当開催内容・脚質・位置取り・相手関係との整合を優先し重みを下げる";
  required_per_verified_factor: [source_or_basis, affected_riders, tactical_effect, probability_adjustment_direction, confidence];
}

HUMAN_FACTOR_TO_BENEFICIARY_V510 {
  purpose: "人的要因を本人の上方評価だけで終わらせず、行動変化と利益移転先まで追う";
  transform_chain: [human_context, likely_behavior_change, energy_use_or_position_change, beneficiary, harmed_rider, trio_impact];
  mandatory_questions: [
    "この感情・立場で本人は通常より早く踏むか",
    "位置取りを優先するか",
    "ライン責任で長く踏むか",
    "その結果本人が消耗した時に誰が最も得をするか"
  ];
  key_rule: "勝ちたい・地元・決勝・悔しさ等を理由に本人だけを機械的に上げない。番手・3番手・別線番手・単騎への利益移転を必ず評価する";
}

HUMAN_ROLE_UPGRADE_AUDIT_V510 {
  purpose: "人的背景や役割関係がある時、番手・3番手を従属候補のまま固定しない";
  mandatory_tests: [second_wheel_to_first, third_wheel_to_second, third_wheel_to_first_if_saved_energy_and_path_exists, front_survives_after_second_wheel_pass, front_plus_second_wheel_survival, second_plus_third_wheel_survival, whole_line_survival, rival_line_member_intrusion];
  key_rule: "前の自力が強いという理由だけで番手の1着昇格を落とさず、番手が強いという理由だけで前残りを消さない";
  three_rider_line_rule: "3車ラインでは前-番手、番手-3番手、前-3番手、3人全残りを別々に検査する";
  exact_order_rule: "同じ上位3人集合でも人的役割と脚温存差から1着・2着の逆転候補を必ず検査する";
}

PAST_COORDINATION_AUDIT_V510 {
  trigger: "同県・同地区・師弟・同期・同門・過去連携が公開確認できる場合";
  inspect: [coordination_count, front_back_roles, who_initiated, who_passed, front_survival_after_pass, third_wheel_survival, line_bundle_survival];
  no_sample_no_claim: true;
  small_sample_rule: "少数例は補助材料に留め、断定的な確率補正をしない";
  recent_role_match_weight: "過去連携でも今日と役割・脚質・相手構成が近いケースを優先";
}

ADVANCEMENT_AND_INCENTIVE_CONTEXT_V510 {
  inspect_if_applicable: [advancement_requirement, semifinal_or_final_stage, local_feature_race, class_change, return_from_absence, milestone_context];
  translate_to_tactics: [need_to_win, need_to_place, willingness_to_lead, willingness_to_sacrifice_position, likely_early_commitment, likely_place_preservation];
  never_assume_must_win_means_will_win: true;
  lower_exact_order_confidence_if_incentives_create_multiple_live_paths: true;
}

HUMAN_CONTEXT_SCENARIO_MATRIX_V510 {
  must_compare: [ability_only_baseline, verified_human_context_adjusted_baseline, second_wheel_promotion, third_wheel_promotion, front_survival_after_pass, whole_line_survival, partial_line_survival, rival_line_intrusion, beneficiary_after_front_overcommitment];
  apply_to: [HEAD_SCORE, PLACE_SCORE, TRIO_FIRST, AXIS_FAILURE_SCORE, MARKET_GAP, exact_order_expansion];
  no_double_counting: "同じ人的根拠をライン補正・コメント補正・過去連携補正で重複加点しない";
  uncertainty_rule: "根拠が曖昧ならUNKNOWNとして確率を動かさない";
}

SELF_AUDIT_LOGIC_V510 {
  purpose: "最頻結果と価格優位を分離したまま、集合・順序・崩壊時残存者をセルフ監査する";
  mandatory_pre_ticket_checks: [
    most_likely_outcome,
    best_value_ticket,
    second_wheel_promotion,
    leader_survival_after_pass,
    third_place_intrusion,
    partial_line_survival,
    whole_line_survival,
    rival_line_intrusion,
    solo_intrusion,
    human_context_consistency,
    current_odds_freshness,
    secondary_trio_head_promotion,
    collapse_third_survivor_reselection
  ];
  key_rule_1: "最頻着順と最も買う価値が高い券を分離する。最頻が低配当なら無理に買わない";
  key_rule_2: "番手差しを評価する時は前残りも同時検査し、前残りを評価する時は番手差しも同時検査する";
  key_rule_3: "3車ラインの3番手を自動残ししない。本線前+番手が残り、3着だけ別線・単騎へ差し替わる世界を必ず検査する";
  key_rule_4: "3着侵入候補は得点順だけで決めず、位置、脚温存、当開催内容、単騎の自由度、別線番手の残存力を比較する";
  key_rule_5: "A=VALUE BETとB/C/D=着順候補を分離し、AがC/D依存なら価格優位を説明する";
  key_rule_6: "次点TRIOに別線自力・捲り型・好調選手がいる場合、その選手の1着昇格を最低1シナリオ検査する";
}

THIRD_PLACE_INTRUSION_AUDIT_V510 {
  purpose: "1・2着読みが合っていても3着差し替わりで3連単を落とす弱点を事前に検査する";
  mandatory_candidates: [main_line_third_wheel, rival_front, rival_second_wheel, solo_rider, low_win_high_top3_profile, current_meeting_improver];
  compare_on: [top3_rate, energy_saved, likely_position, current_meeting_content, bank_fit, line_pressure, finishing_style];
  force_question: "本線1・2着を維持したまま、3着だけ別選手へ差し替わる最有力候補は誰か";
  trifecta_rule: "3着候補の優位差が小さい場合は3連単を厚くせず、2車単または3連複へ券種ダウンする";
}

COLLAPSE_THIRD_SURVIVOR_AUDIT_V510 {
  purpose: "崩壊シナリオの骨格は読めても3人目残存者を固定し過ぎる弱点を修正する";
  trigger_if: [axis_failure, front_collapse, pace_duel, multiple_aggressive_self_power_riders, two_survivors_have_clear_causal_path];
  first_step: "崩壊時に残る根拠が強い2人だけを核として仮固定する";
  never_lock_third_early: true;
  third_survivor_families: [
    NORMAL_AXIS_SOLO_SURVIVAL,
    RIVAL_SECOND_OR_THIRD_WHEEL,
    ORIGINAL_LINE_SECOND_OR_THIRD_WHEEL_AFTER_FRONT_COLLAPSE,
    SOLO_OR_CLOSER_INTRUSION
  ];
  minimum_comparison: "候補が存在する限り3人目を最低3候補比較する";
  compare_on: [PLACE_SCORE, current_meeting_content, recent_3_5_meets, saved_energy, expected_position, line_role, pace_benefit, human_context_benefit, bank_fit, market_gap_after_model];
  same_two_core_variants: "同じ2人を核に3人目だけ違う3連複を最大3点まで許可。ただし各候補に独立した因果根拠が必要";
  normal_axis_single_survival: "前崩れで通常軸だけが3着に残る形を、軸飛びシナリオとは別に必ず検査する";
  back_only_cross_line_rule: "複数の自力型が人的要因から積極化する場合、各ラインの前が消耗し番手・3番手だけが横断残存する集合を独立検査する";
  reject: [blind_rotation, odds_only, popularity_only, full_box, random_third_candidate];
}

TAIL_RISK_THIRD_SURVIVOR_V510 {
  purpose: "高配当保険で2人まで読めている時、3人目の固定ミスで万車券を逃さない";
  sequence: [identify_collapse_cause, lock_two_causal_survivors, rebuild_third_pool, compare_third_candidates, price_check, select_max_three_trios, exact_order_only_if_supported];
  priority: "まず3連複集合を拾う。順序根拠が弱ければ3連単へ無理に展開しない";
  reference_stake: 100_JPY_each_if_recommended;
}

BET_SCENARIO_CONSISTENCY_V510 {
  audit: [A_value_bet_vs_B_main, correlated_ticket_overlap, price_efficiency, scenario_dependency];
  if_A_uses_secondary_scenario: "最頻ではなく価格差を買う理由を明記";
  if_B_is_not_bet: "オッズ不足・券種効率不足・3着不確実性などの理由を明記";
  avoid_double_investment: true;
}

HUMAN_CONTEXT_OUTPUT_V510 {
  required_section: "人的背景・役割監査";
  show_only_verified_or_explicitly_unknown: true;
  output: [verified_factor, public_basis, tactical_effect, beneficiary, affected_scenario, confidence, what_would_invalidate_it];
  scenario_requirement: "最頻・逆転・妙味・崩れ・軸飛びの各シナリオ作成前に人的背景監査を完了する";
  final_ticket_rule: "人的背景だけを根拠にBUYへ昇格させず、能力・状態・展開・価格と整合した時だけ最終券へ反映する";
}

OUTPUT_SELF_CHECK_V510 {
  before_final_answer: [
    "最頻結果とVALUE BETを分離したか",
    "番手1着昇格を検査したか",
    "前残りを検査したか",
    "3着差し替わり候補を最低1名検査したか",
    "次点TRIOの頭昇格を検査したか",
    "崩壊時に2人を核として3人目を最低3候補比較したか",
    "通常軸だけが単独残存する形を検査したか",
    "後位横断残存を検査したか",
    "人的背景に公開根拠があるか",
    "人的要因の利益移転先まで確認したか",
    "現在オッズが十分新しいか",
    "価格不適正ならSKIPできているか"
  ];
  if_any_fail: "BUYを弱めるかPREVIEW/SKIPへ落とす";
}`;

  function patchVisibleVersionText() {
    const selectors = ['.paper-badge', '.prompt-toolbar span', '.strict-lead', 'footer small'];
    document.querySelectorAll(selectors.join(',')).forEach(el => {
      if (!el) return;
      el.innerHTML = el.innerHTML
        .replace(/v5\.7\.0/g, 'v5.10.0')
        .replace(/v5\.8\.0/g, 'v5.10.0')
        .replace(/v5\.8\.1/g, 'v5.10.0')
        .replace(/v5\.9\.0/g, 'v5.10.0');
    });
  }

  function patchUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.10.0 · HUMAN CONTEXT / COLLAPSE AUDIT';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.10.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '最新事前データと人的背景を使い、TRIO-FIRST、番手昇格、前残り、3着侵入、崩壊時の第三残存者再選抜、価格優位までセルフ監査します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.10.0 · HUMAN CONTEXT / COLLAPSE AUDIT · 20歳以上 / 予想支援ツール';
    patchVisibleVersionText();
  }

  function stripOlderHumanBlocks(value) {
    const markers = ['HUMAN_CONTEXT_STAKES_V510 {', 'HUMAN_CONTEXT_STAKES_V58 {'];
    let cut = value.length;
    markers.forEach(marker => {
      const idx = value.indexOf(marker);
      if (idx >= 0 && idx < cut) cut = idx;
    });
    return cut < value.length ? value.slice(0, cut).trimEnd() : value;
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = stripOlderHumanBlocks(output.value);
    value = value
      .replace(/v5\.7\.0/g, 'v5.10.0')
      .replace(/v5\.8\.0/g, 'v5.10.0')
      .replace(/v5\.8\.1/g, 'v5.10.0')
      .replace(/v5\.9\.0/g, 'v5.10.0');
    value += HUMAN_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(value.length);
  }

  function runPatch() {
    patchUI();
    patchPrompt();
  }

  document.addEventListener('DOMContentLoaded', () => {
    runPatch();
    setTimeout(runPatch, 50);
    setTimeout(runPatch, 300);
    setTimeout(runPatch, 1200);
    const form = document.getElementById('race-form');
    if (form) form.addEventListener('submit', () => {
      setTimeout(runPatch, 20);
      setTimeout(runPatch, 140);
      setTimeout(runPatch, 500);
    });
    ['copy-button','share-button','download-button'].forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', runPatch, true);
    });
  });

  window.addEventListener('load', runPatch);
  const observer = new MutationObserver(() => runPatch());
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();