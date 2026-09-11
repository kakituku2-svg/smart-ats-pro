(() => {
  'use strict';

  const VERSION = '5.2.0';
  const MARKER = 'TAIL_RISK_100 {';
  const ORDER_MARKER = 'ORDER_3_FORECAST {';

  const TAIL_RISK_BLOCK = `\n\nTAIL_RISK_100 {\n  purpose: "本線では薄いが、事前情報から具体的に説明でき、100円だけ残す価値がある高配当シナリオを切り捨てない";\n  classify_as: HIGH_PAYOUT_INSURANCE;\n  separate_from_main: true;\n  default_reference_stake_per_ticket: 100_JPY;\n  max_candidates: 3;\n  do_not_force_candidate: true;\n  trigger_if: [concrete_pre_race_causal_path_exists, probability_is_low_but_non_negligible, payout_impact_is_large, candidate_does_not_require_blind_box_or_total_spread];\n  priority_checks: [current_meeting_1st_or_2nd_despite_low_score, underrated_whole_line_survival, front_collapses_but_second_or_third_wheel_survives, pace_duel_promotes_solo_or_closer_to_1st_or_2nd, third_place_candidate_promotes_to_1st_or_2nd, strong_current_form_overrides_static_score_gap, cross_line_residual_exact_order];\n  reject_if: [odds_only_reason, popularity_only_reason, blind_box, total_spread, mutually_exclusive_tactics, no_causal_path];\n  output_each: [ticket, current_odds, causal_condition, rough_probability_band, why_100yen_is_worth_retaining];\n}\n`;

  const ORDER_3_BLOCK = `\n\nORDER_3_FORECAST {\n  purpose: "VALUE BETと着順予測を分離し、事前に説明可能な着順を第3候補までFreezeして検証する";\n  freeze_before_result: true;\n  never_rewrite_after_result: true;\n\n  A_VALUE_BET {\n    role: "最も買う価値が高い買い目";\n    output: [strategy, ticket_type, ticket, paper_stake, estimated_hit_probability, current_odds, market_implied_probability, EV, rationale];\n    allow_no_bet: true;\n    rule: "EV・資金効率・再現性の基準を満たさなければSKIP。着順3候補があっても無理に買わない";\n  }\n\n  B_MAIN_ORDER {\n    role: "第1候補：最も起こりやすい着順";\n    format: "1着→2着→3着";\n    include_confidence_or_probability: true;\n  }\n\n  C_SECONDARY_ORDER {\n    role: "第2候補：本線の一部崩れを含む有力着順";\n    format: "1着→2着→3着";\n    include_confidence_or_probability: true;\n    prioritize: [second_wheel_pass, front_survival, rival_line_self_power_survival, rival_line_second_wheel_survival, third_candidate_promotes_to_second, whole_line_survival, partial_line_collapse];\n  }\n\n  D_TERTIARY_ORDER {\n    role: "第3候補：B/Cとは異なる合理的な展開分岐";\n    format: "1着→2着→3着";\n    include_confidence_or_probability: true;\n    prioritize: [rival_line_whole_survival, front_runner_survival, second_wheel_reversal, solo_rider_promotion, third_candidate_promotes_to_first_or_second, alternate_line_intrusion];\n    reject: [same_scenario_simple_reordering_only, random_longshot, blind_box, result_hindsight];\n  }\n\n  separation_rules: [\n    "AとB/C/Dは一致してもよいが無理に一致させない",\n    "B/C/Dの3着順候補を全部買う前提にしない",\n    "結果後にB/C/Dを追加・変更して的中扱いにしない",\n    "3連単BETは完全一致でなければ不的中"\n  ];\n}\n\nORDER_3_AUDIT {\n  metrics: [value_bet_hit_and_ROI, first_place_match_rate, main_order_exact_rate, secondary_order_exact_rate, tertiary_order_exact_rate, any_of_3_exact_capture_rate, top3_set_match_rate, head_match_but_2nd_3rd_miss_count, pre_race_explainable_but_omitted_order_count];\n  evaluation: "AのROIとB/C/Dの着順捕捉率を別々に集計し、十分なサンプル後にウォークフォワード評価する";\n}`;

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.2.0 · ORDER 3';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI分析プロンプト · v5.2.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = 'VALUE BETと着順予測を分離し、着順は第1・第2・第3候補まで事前Freeze。番手差し、前残り、別線残存、ライン崩れ、単騎浮上、高配当保険まで同時監査します。';
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = output.value
      .replace(/v4\.9\.0/g, `v${VERSION}`)
      .replace(/v5\.0\.0/g, `v${VERSION}`)
      .replace(/v5\.1\.0/g, `v${VERSION}`)
      .replace(/THREE_PATTERN_FORECAST \{[\s\S]*?THREE_PATTERN_AUDIT \{[\s\S]*?\n\}/g, '');
    if (!value.includes(MARKER)) value += TAIL_RISK_BLOCK;
    if (!value.includes(ORDER_MARKER)) value += ORDER_3_BLOCK;
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
