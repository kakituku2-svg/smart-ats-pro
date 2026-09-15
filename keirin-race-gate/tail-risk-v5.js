(() => {
  'use strict';

  // Preserve and execute the previous live engine first.
  document.write('<script src="./tail-risk-v5-base.js?rev=5.8.0-base"><\/script>');

  const VERSION = '5.13.0';
  const AUDIT_BLOCK = `

DUAL_WHEEL_REVERSAL_AUDIT_V513 {
  preserve_existing_logic: true;
  rule: "番手×番手＋前残りの同一3人集合では番手同士の1・2着逆転を独立した因果で両方向監査する";
  no_blind_reverse: true;
  trio_fallback: true;
}

HEAD_RISE_REBUILD_V513 {
  trigger: "本線または次点TRIOの選手に現実的な1着経路がある";
  mandatory: true;
  rule: "HEADへ昇格した選手が出た時、元TRIOの残り2人を自動継承しない。残り2席を全リセットしてゼロベース再構築する";
  rebuild_from: [front_plus_second, second_plus_third, front_only, second_only, cross_line_rear, solo_or_closer];
}

HEAD_RISE_SOLO_AXIS_SURVIVAL_AUDIT_V513 {
  archetype: "2026-09-14 Omiya12R 7-5-3 type";
  mandatory_tests: [head_rise_plus_original_axis_plus_third_candidate, head_rise_plus_solo_or_closer_plus_original_axis, head_rise_plus_rival_second_wheel_plus_original_axis];
  original_axis_rule: "元軸を勝つ/飛ぶの二値で扱わず、1着を失っても2・3着に残るPARTIAL SURVIVALを別評価する";
}

CANDIDATE_TO_COMBINATION_COMPLETENESS_V513 {
  rule: "個別に正しい選手名を挙げただけでは捕捉成功としない。候補同士が同時成立できる3人集合まで生成・比較する";
  require_combination_link: true;
  minimum_audits: [HEAD_x_AXIS_x_THIRD, HEAD_x_SOLO_x_AXIS, HEAD_x_RIVAL_SECOND_x_AXIS];
  no_credit_for_name_only: true;
}

AXIS_PARTIAL_SURVIVAL_V513 {
  trigger_if: [axis_failure_score_15_plus, strong_head_rise_candidate];
  rule: "完全軸飛びTAIL-RISKと、元軸がHEADを譲って2・3着だけ残る崩壊シナリオを分離する";
  mandatory_trio_recheck: true;
}

COLLAPSE_THIRD_SURVIVOR_V513 {
  rule: "崩壊骨格で2人が因果的に残るなら3人目を早期固定しない";
  compare_third_from: [original_axis_survival, rival_second_or_third, original_line_rear, solo_or_closer];
  allow_max_three_trios_if_independent_causal_support: true;
  no_box: true;
  no_full_flow: true;
}

COMMENT_HISTORY_MATCH_V513 {
  mandatory: true;
  lookback_target: "各選手の直近5レース前後。公開取得できる範囲のみ使用し、不足時はCOMMENT_HISTORY_INSUFFICIENTと明示";
  compare_fields: [pre_race_comment, actual_tactic, attack_timing, position, line_role, finish, late_speed_or_survival];
  rule: "今回コメントを単独評価せず、同一選手が過去に類似コメントを残した時の実際の戦法・仕掛け・位置・着順を照合する";
  comment_habit: "自力/前で/何でも/任せる/状態普通/重い等の語句が、その選手では実際にどの行動へ結びつくか個人別に学習して評価する";
  no_fabrication: true;
}

EMOTION_BEHAVIOR_BENEFIT_TRANSFER_V513 {
  mandatory: true;
  factors: [must_win_pressure, local_or_home, first_win_or_final_pressure, qualification, role_responsibility, fatigue, recovery, confidence, recent_result_emotion];
  causal_chain: "感情・状況・コメント → 想定行動変化 → 仕掛け時期/位置取り/脚消耗 → 本人HEAD/PLACE変化 → 番手/3番手/別線/単騎への利益移転";
  rule: "人的要因は本人への単純加点減点にしない。必ず利益移転先まで追跡する";
  weak_comment_guard: "強い番手・高PLACE選手を弱気コメント1件だけで大幅に切らない";
}

RECENT_FIVE_RACE_TACTICAL_FORM_V513 {
  mandatory: true;
  rule: "直近5走前後は着順だけでなく、逃げ/先行/捲り/差し、仕掛け時期、前残り、番手差し、末脚、展開利、脚消耗を評価する";
  current_meet_override: true;
  separate_scores: [HEAD, SECOND, THIRD, TOP3];
}

STYLE_COMPOSITION_COMPATIBILITY_V513 {
  mandatory: true;
  inspect: [number_of_front_runners, number_of_makuri_types, number_of_closers, line_lengths, competing_leaders, solo_count, rear_depth];
  rule: "今回の脚質人数比・ライン長・先行競合数を数え、選手の直近/類似構成での得手不得手へ接続する";
  benefit_transfer_required: true;
}

MARKET_DISAGREEMENT_AUDIT_V513 {
  mandatory_when: "市場上位評価の選手を本線/次点TRIOから薄くする時";
  rule: "人気を予測根拠にはしないが、市場高評価を否定する場合は能力・直近内容・脚質相性・コメント履歴を再監査し、切る根拠を明示できなければ再昇格する";
  preserve_market_gap_score: true;
}

OUTPUT_AUDIT_V513 {
  required_before_final_ticket: [
    "直近5走前後の着順だけでなく戦法・仕掛け・末脚を確認したか",
    "今回コメントと過去の類似コメント時の実際の走りを照合したか",
    "感情/人的要因を行動変化と利益移転先まで接続したか",
    "脚質人数比・ライン長・先行競合との相性を確認したか",
    "市場上位選手を薄くする場合にMARKET DISAGREEMENT AUDITを通したか",
    "HEAD-RISE後に残り2席を全リセットしたか",
    "単騎/追込候補を実際のTRIOへ接続したか",
    "元軸の2・3着PARTIAL SURVIVALを検査したか",
    "候補名だけ当たって買い目集合に無い状態を成功扱いしていないか",
    "集合確信度が順序確信度より高い場合3連複へ退避したか"
  ];
}

FEATURE_FLAGS_V513 {
  add: [COMMENT_HISTORY_MATCH, EMOTION_BEHAVIOR_BENEFIT_TRANSFER, RECENT_FIVE_RACE_TACTICAL_FORM, STYLE_COMPOSITION_COMPATIBILITY, MARKET_DISAGREEMENT_AUDIT, DUAL_WHEEL_REVERSAL_AUDIT, HEAD_RISE_FULL_REBUILD, HEAD_RISE_SOLO_AXIS_SURVIVAL, CANDIDATE_TO_COMBINATION_COMPLETENESS, AXIS_PARTIAL_SURVIVAL, COLLAPSE_THIRD_SURVIVOR];
}`;

  function stripAudit(value) {
    const markers = [
      'DUAL_WHEEL_REVERSAL_AUDIT_V511 {',
      'DUAL_WHEEL_REVERSAL_AUDIT_V512 {',
      'DUAL_WHEEL_REVERSAL_AUDIT_V513 {',
      'HEAD_RISE_REBUILD_V512 {',
      'HEAD_RISE_REBUILD_V513 {'
    ];
    let cut = value.length;
    markers.forEach(marker => {
      const i = value.indexOf(marker);
      if (i >= 0 && i < cut) cut = i;
    });
    return cut < value.length ? value.slice(0, cut).trimEnd() : value;
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = stripAudit(output.value);
    value = value.replace(/v5\.(?:8|9|10|11|12)\.0/g, VERSION);
    value += AUDIT_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(value.length);
  }

  function patchUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.13.0 · COMMENT HISTORY / HUMAN FACTOR';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.13.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '直近5走→コメント履歴→感情/行動→脚質構成→利益移転→3人集合まで監査します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.13.0 · COMMENT HISTORY / HUMAN FACTOR / HEAD-RISE · 20歳以上 / 予想支援ツール';
  }

  function install() {
    patchUI();
    patchPrompt();
    const form = document.getElementById('race-form');
    if (form) form.addEventListener('submit', () => {
      setTimeout(patchPrompt, 20);
      setTimeout(patchPrompt, 120);
      setTimeout(patchPrompt, 500);
    });
    ['copy-button', 'share-button', 'download-button', 'select-all-button'].forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', patchPrompt, true);
    });
    setTimeout(patchUI, 250);
    setTimeout(patchPrompt, 800);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', install);
  else install();
})();
