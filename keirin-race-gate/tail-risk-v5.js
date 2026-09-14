(() => {
  'use strict';

  // Preserve and execute the previous live engine first.
  // This keeps every v5.8 forecast rule intact, then adds the v5.11 audit layer below.
  document.write('<script src="./tail-risk-v5-base.js?rev=5.8.0-base"><\\/script>');

  const VERSION = '5.11.0';
  const MARKER = 'DUAL_WHEEL_REVERSAL_AUDIT_V511 {';
  const DUAL_BLOCK = `

DUAL_WHEEL_REVERSAL_AUDIT_V511 {
  purpose: "既存の高配当シナリオ生成能力を残しつつ、本線番手＋別線番手＋前残りの同一3人集合で、番手同士の1・2着順を一方向に固定して取りこぼす弱点を修正する";
  trigger_if: [
    two_second_wheels_in_same_live_trio,
    main_second_wheel_plus_rival_second_wheel_plus_front_survivor,
    pace_duel_or_front_overcommitment,
    cross_line_back_only_survival,
    tail_risk_exact_order,
    trifecta_odds_100_plus
  ];
  preserve_existing_longshot_logic: true;
  mandatory_order_tests: [main_second_over_rival_second, rival_second_over_main_second];
  compare_on: [
    front_strength,
    front_expected_workload,
    second_wheel_saved_energy,
    second_wheel_self_power_capacity,
    second_wheel_sashi_extension,
    launch_timing,
    expected_position,
    line_length,
    current_meeting_form,
    recent_3_5_meets,
    bank_fit,
    straight_length,
    comment_role,
    market_price_after_model
  ];
  strong_front_rule: "より強い自力選手の番手は位置と脚温存の恩恵を受けやすい。別線番手を頭にした穴を作った場合でも、本線番手がその番手を逆転する順序を必ず独立検査する";
  rival_second_rule: "別線番手に自力含み・差脚・当開催上昇がある場合は、逆側の頭も独立シナリオとして残す";
  exact_order_rule: "4-3-7のような番手×番手＋前残りを因果付きで生成した時、3-4-7のような番手同士逆転を必ず監査する。単なる数字の裏返しは禁止";
  causal_path_required_each_direction: true;
  no_blind_reverse: true;
  no_full_permutation: true;
  high_odds_force_check: "100倍以上の3連単候補では省略禁止";
  trio_fallback: "3人集合への確信が順序確信より高い場合、その集合の3連複を最低1候補残す";
  price_rule: "両順序の事前確率が近く市場価格も近い場合、一方向だけを過度に優先しない。EV基準を満たす側だけBUYとし、もう一方は着順候補として保持可能";
  feature_flag: DUAL_WHEEL_REVERSAL_AUDIT;
}

DUAL_WHEEL_OUTPUT_AUDIT_V511 {
  required_questions_before_final_ticket: [
    "番手×番手＋前残りの3人集合が生きているか",
    "その場合、番手A→番手Bと番手B→番手Aを両方検査したか",
    "両方向それぞれに独立した展開根拠があるか",
    "強い前を持つ番手の脚温存優位を比較したか",
    "順序より集合の確信度が高いなら3連複へ退避したか",
    "100倍以上の穴順序でDUAL_WHEEL監査を省略していないか"
  ];
  if_fail: "3連単の確信度を下げ、3連複またはPREVIEWへ寄せる";
}

FEATURE_FLAGS_V511 {
  add: [DUAL_WHEEL_REVERSAL_AUDIT];
}`;

  function stripOldDual(value) {
    const markers = [
      'DUAL_WHEEL_REVERSAL_AUDIT_V511 {',
      'DUAL_WHEEL_OUTPUT_AUDIT_V511 {'
    ];
    let cut = value.length;
    markers.forEach(marker => {
      const i = value.indexOf(marker);
      if (i >= 0 && i < cut) cut = i;
    });
    return cut < value.length ? value.slice(0, cut).trimEnd() : value;
  }

  function patchPromptV511() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;
    let value = stripOldDual(output.value);
    value = value
      .replace(/v5\.8\.0/g, VERSION)
      .replace(/v5\.10\.0/g, VERSION);
    if (!value.includes(MARKER)) value += DUAL_BLOCK;
    output.value = value;
    const count = document.getElementById('char-count');
    if (count) count.textContent = String(value.length);
  }

  function patchUIV511() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.11.0 · DUAL WHEEL / EV';
    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI予想プロンプト · v5.11.0';
    const lead = document.querySelector('.strict-lead');
    if (lead) lead.textContent = '最新事前データから3人集合→番手同士逆転監査→着順→価格→EV→崩壊時残存まで評価します。';
    const footer = document.querySelector('footer small');
    if (footer) footer.textContent = 'v5.11.0 · DUAL WHEEL REVERSAL AUDIT · 20歳以上 / 予想支援ツール';
  }

  function install() {
    patchUIV511();
    patchPromptV511();

    const form = document.getElementById('race-form');
    if (form) {
      form.addEventListener('submit', () => {
        setTimeout(patchPromptV511, 20);
        setTimeout(patchPromptV511, 120);
        setTimeout(patchPromptV511, 500);
      });
    }

    ['copy-button', 'share-button', 'download-button', 'select-all-button'].forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', patchPromptV511, true);
    });

    setTimeout(patchUIV511, 250);
    setTimeout(patchPromptV511, 800);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install);
  } else {
    install();
  }
})();
