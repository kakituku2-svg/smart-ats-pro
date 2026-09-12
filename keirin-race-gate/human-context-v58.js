(() => {
  'use strict';

  const VERSION = '5.8.1';
  const MARKER = 'HUMAN_CONTEXT_STAKES_V58 {';
  const HUMAN_BLOCK = `

HUMAN_CONTEXT_STAKES_V58 {
  purpose: "公開根拠のある人的背景を、能力・ライン・直近状態・脚質・オッズとは別の事前特徴量として展開確率へ反映する";
  mandatory_before_forecast_if_public: [
    home_bank_or_local_race,
    same_prefecture_or_region,
    mentor_student,
    senior_junior,
    same_class_or_cohort,
    same_training_group_or_team,
    past_coordination_count,
    past_coordination_roles,
    past_coordination_finish_patterns,
    role_declaration_in_current_comments,
    advancement_condition,
    semifinal_or_final_incentive,
    class_change_or_return_context,
    milestone_or_special_local_context
  ];
  evidence_priority: [
    official_profile,
    official_or_verified_rider_comment,
    official_race_card,
    specialist_pre_race_article,
    verifiable_past_coordination_record
  ];
  never_infer_without_public_evidence: [
    friendship,
    favoritism,
    collusion,
    private_relationship,
    hidden_intent,
    result_based_story
  ];
  use_as: "能力を無条件で上書きする材料ではなく、仕掛け時期・役割遂行・番手差し・前残り・3番手残存・着拾い優先度・ライン残存率を補正する特徴量";
  if_background_conflicts_with_form_or_ability: "人的背景だけで逆転させず、当開催内容・脚質・位置取り・相手関係との整合を優先し重みを下げる";
  required_per_verified_factor: [source_or_basis, affected_riders, tactical_effect, probability_adjustment_direction, confidence];
}

HUMAN_ROLE_UPGRADE_AUDIT_V58 {
  purpose: "人的背景や役割関係がある時、番手・3番手を従属候補のまま固定しない";
  mandatory_tests: [
    second_wheel_to_first,
    third_wheel_to_second,
    third_wheel_to_first_if_saved_energy_and_path_exists,
    front_survives_after_second_wheel_pass,
    front_plus_second_wheel_survival,
    second_plus_third_wheel_survival,
    whole_line_survival,
    rival_line_member_intrusion
  ];
  key_rule: "前の自力が強いという理由だけで番手の1着昇格を落とさず、番手が強いという理由だけで前残りを消さない";
  three_rider_line_rule: "3車ラインでは前-番手、番手-3番手、前-3番手、3人全残りを別々に検査する";
  exact_order_rule: "同じ上位3人集合でも人的役割と脚温存差から1着・2着の逆転候補を必ず検査する";
}

PAST_COORDINATION_AUDIT_V58 {
  trigger: "同県・同地区・師弟・同期・同門・過去連携が公開確認できる場合";
  inspect: [coordination_count, front_back_roles, who_initiated, who_passed, front_survival_after_pass, third_wheel_survival, line_bundle_survival];
  no_sample_no_claim: true;
  small_sample_rule: "少数例は補助材料に留め、断定的な確率補正をしない";
  recent_role_match_weight: "過去連携でも今日と役割・脚質・相手構成が近いケースを優先";
}

ADVANCEMENT_AND_INCENTIVE_CONTEXT_V58 {
  inspect_if_applicable: [advancement_requirement, semifinal_or_final_stage, local_feature_race, class_change, return_from_absence, milestone_context];
  translate_to_tactics: [need_to_win, need_to_place, willingness_to_lead, willingness_to_sacrifice_position, likely_early_commitment, likely_place_preservation];
  never_assume_must_win_means_will_win: true;
  lower_exact_order_confidence_if_incentives_create_multiple_live_paths: true;
}

HUMAN_CONTEXT_SCENARIO_MATRIX_V58 {
  must_compare: [
    ability_only_baseline,
    verified_human_context_adjusted_baseline,
    second_wheel_promotion,
    third_wheel_promotion,
    front_survival_after_pass,
    whole_line_survival,
    partial_line_survival,
    rival_line_intrusion
  ];
  apply_to: [HEAD_SCORE, PLACE_SCORE, TRIO_FIRST, AXIS_FAILURE_SCORE, MARKET_GAP, exact_order_expansion];
  no_double_counting: "同じ人的根拠をライン補正・コメント補正・過去連携補正で重複加点しない";
  uncertainty_rule: "根拠が曖昧ならUNKNOWNとして確率を動かさない";
}

HUMAN_CONTEXT_OUTPUT_V58 {
  required_section: "人的背景・役割監査";
  show_only_verified_or_explicitly_unknown: true;
  output: [verified_factor, public_basis, tactical_effect, affected_scenario, confidence, what_would_invalidate_it];
  scenario_requirement: "最頻・逆転・妙味・崩れ・軸飛びの各シナリオ作成前に人的背景監査を完了する";
  final_ticket_rule: "人的背景だけを根拠にBUYへ昇格させず、能力・状態・展開・価格と整合した時だけ最終券へ反映する";
}`;

  function patchVisibleVersionText() {
    const selectors = ['.paper-badge', '.prompt-toolbar span', '.strict-lead', 'footer small'];
    document.querySelectorAll(selectors.join(',')).forEach(el => {
      if (!el) return;
      el.innerHTML = el.innerHTML
        .replace(/v5\.7\.0/g, 'v5.8.1')
        .replace(/v5\.8\.0/g, 'v5.8.1');
    });
  }

  function patchUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.8.1 · HUMAN CONTEXT / EV';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.8.1';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '開催日・開催場・Rを選ぶだけ。最新の事前データに加え、公開根拠のある人的背景・過去連携・役割事情まで検査して予想します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.8.1 · HUMAN CONTEXT · 20歳以上 / 予想支援ツール';
    patchVisibleVersionText();
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = output.value;
    const idx = value.indexOf(MARKER);
    if (idx >= 0) value = value.slice(0, idx).trimEnd();
    value = value.replace(/v5\.7\.0/g, 'v5.8.1').replace(/v5\.8\.0/g, 'v5.8.1');
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