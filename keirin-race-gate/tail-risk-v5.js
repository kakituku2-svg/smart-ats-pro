(() => {
  'use strict';

  // Preserve and execute the previous live engine first.
  document.write('<script src="./tail-risk-v5-base.js?rev=5.8.0-base"><\\/script>');

  const VERSION = '5.12.0';
  const AUDIT_BLOCK = `

DUAL_WHEEL_REVERSAL_AUDIT_V512 {
  preserve_existing_logic: true;
  rule: "番手×番手＋前残りの同一3人集合では番手同士の1・2着逆転を独立した因果で両方向監査する";
  no_blind_reverse: true;
  trio_fallback: true;
}

HEAD_RISE_REBUILD_V512 {
  trigger: "本線または次点TRIOの選手に現実的な1着経路がある";
  mandatory: true;
  rule: "HEADへ昇格した選手が出た時、元TRIOの残り2人を自動継承しない。残り2席を全リセットしてゼロベース再構築する";
  rebuild_from: [front_plus_second, second_plus_third, front_only, second_only, cross_line_rear, solo_or_closer];
}

HEAD_RISE_SOLO_AXIS_SURVIVAL_AUDIT_V512 {
  archetype: "2026-09-14 Omiya12R 7-5-3 type";
  purpose: "頭昇格は読めたが、単騎/追込浮上と元軸の2・3着残存を同一3人集合へ接続できず外す弱点を修正する";
  mandatory_tests: [
    head_rise_plus_original_axis_plus_third_candidate,
    head_rise_plus_solo_or_closer_plus_original_axis,
    head_rise_plus_rival_second_wheel_plus_original_axis
  ];
  original_axis_rule: "元軸を勝つ/飛ぶの二値で扱わず、1着を失っても2・3着に残るPARTIAL SURVIVALを別評価する";
  solo_rule: "単騎/追込が当開催好走、高3連対率、末脚良好、展開待ち可能のいずれかを満たす時は候補名だけで終わらせず3人集合へ接続する";
  promote_if: "HEAD候補の成立根拠、単騎/追込の浮上根拠、元軸PLACE残存根拠のうち2つ以上が強く、同時成立に因果矛盾がない";
}

CANDIDATE_TO_COMBINATION_COMPLETENESS_V512 {
  rule: "個別に正しい選手名を挙げただけでは捕捉成功としない。候補同士が同時成立できる3人集合まで生成・比較する";
  require_combination_link: true;
  minimum_audits: [HEAD_x_AXIS_x_THIRD, HEAD_x_SOLO_x_AXIS, HEAD_x_RIVAL_SECOND_x_AXIS];
  no_credit_for_name_only: true;
}

AXIS_PARTIAL_SURVIVAL_V512 {
  trigger_if: [axis_failure_score_15_plus, strong_head_rise_candidate];
  rule: "完全軸飛びTAIL-RISKと、元軸がHEADを譲って2・3着だけ残る崩壊シナリオを分離する";
  mandatory_trio_recheck: true;
}

COLLAPSE_THIRD_SURVIVOR_V512 {
  rule: "崩壊骨格で2人が因果的に残るなら3人目を早期固定しない";
  compare_third_from: [original_axis_survival, rival_second_or_third, original_line_rear, solo_or_closer];
  allow_max_three_trios_if_independent_causal_support: true;
  no_box: true;
  no_full_flow: true;
}

OUTPUT_AUDIT_V512 {
  required_before_final_ticket: [
    "HEAD-RISE後に残り2席を全リセットしたか",
    "単騎/追込候補を実際のTRIOへ接続したか",
    "元軸の2・3着PARTIAL SURVIVALを検査したか",
    "HEAD×SOLO/追込×元軸を検査したか",
    "崩壊時の3人目を複数系統から比較したか",
    "候補名だけ当たって買い目集合に無い状態を成功扱いしていないか",
    "集合確信度が順序確信度より高い場合3連複へ退避したか"
  ];
}

FEATURE_FLAGS_V512 {
  add: [DUAL_WHEEL_REVERSAL_AUDIT, HEAD_RISE_FULL_REBUILD, HEAD_RISE_SOLO_AXIS_SURVIVAL, CANDIDATE_TO_COMBINATION_COMPLETENESS, AXIS_PARTIAL_SURVIVAL, COLLAPSE_THIRD_SURVIVOR];
}`;

  function stripAudit(value) {
    const markers = [
      'DUAL_WHEEL_REVERSAL_AUDIT_V511 {',
      'DUAL_WHEEL_REVERSAL_AUDIT_V512 {',
      'HEAD_RISE_REBUILD_V512 {'
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
    value = value.replace(/v5\.(?:8|9|10|11)\.0/g, VERSION);
    value += AUDIT_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(value.length);
  }

  function patchUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.12.0 · HEAD-RISE REBUILD / EV';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.12.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '3人集合→頭昇格→残り2席全再構築→単騎/元軸残存→価格・EVまで監査します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.12.0 · HEAD-RISE / SOLO / AXIS SURVIVAL AUDIT · 20歳以上 / 予想支援ツール';
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
