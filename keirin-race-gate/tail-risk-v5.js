(() => {
  'use strict';

  const VERSION = '5.1.0';
  const MARKER = 'TAIL_RISK_100 {';
  const THREE_PATTERN_MARKER = 'THREE_PATTERN_FORECAST {';
  const TAIL_RISK_BLOCK = `\n\nTAIL_RISK_100 {\n  purpose: "本線では薄いが、事前情報から具体的に説明でき、100円だけ残す価値がある高配当シナリオを切り捨てない";\n  classify_as: HIGH_PAYOUT_INSURANCE;\n  separate_from_main: true;\n  default_reference_stake_per_ticket: 100_JPY;\n  max_candidates: 3;\n  do_not_force_candidate: true;\n\n  trigger_if: [\n    concrete_pre_race_causal_path_exists,\n    probability_is_low_but_non_negligible,\n    payout_impact_is_large,\n    candidate_does_not_require_blind_box_or_total_spread\n  ];\n\n  priority_checks: [\n    current_meeting_1st_or_2nd_despite_low_score,\n    underrated_whole_line_survival,\n    front_collapses_but_second_or_third_wheel_survives,\n    pace_duel_promotes_solo_or_closer_to_1st_or_2nd,\n    third_place_candidate_promotes_to_1st_or_2nd,\n    strong_current_form_overrides_static_score_gap,\n    cross_line_residual_exact_order\n  ];\n\n  odds_review: {\n    trifecta_50x_plus: PRIORITY_RECHECK;\n    trifecta_100x_plus: STRONG_RECHECK;\n    trifecta_200x_plus: MANDATORY_VALUE_RECHECK_IF_CAUSAL_PATH_EXISTS;\n    high_odds_alone_is_not_reason: true;\n  };\n\n  reject_if: [\n    odds_only_reason,\n    popularity_only_reason,\n    blind_box,\n    total_spread,\n    mutually_exclusive_tactics,\n    no_causal_path\n  ];\n\n  output_each: [ticket, current_odds, causal_condition, rough_probability_band, why_100yen_is_worth_retaining];\n  accounting: "100円は参考提案額。ユーザーが実購入を明示しない限り実収支へ算入しない";\n}\n\nRESULT_AUDIT_EXTENSION {\n  compare_tail_risk_100: true;\n  report_if_hit: [ticket, official_payout_per_100yen, causal_scenario_that_occurred];\n  report_if_missed: [was_pre_race_explainable, should_it_have_been_tail_risk_candidate];\n  daily_report_metrics: [tail_risk_candidates, tail_risk_hits, hypothetical_100yen_payout_separate_from_real_PnL];\n}`;

  const THREE_PATTERN_BLOCK = `\n\nTHREE_PATTERN_FORECAST {\n  purpose: "買う価値と着順予測を分離し、事前に説明可能な主要2シナリオまで固定して検証する";\n  freeze_before_result: true;\n  never_rewrite_after_result: true;\n\n  A_VALUE_BET {\n    role: "最も買う価値が高い買い目";\n    output: [strategy, ticket_type, ticket, paper_stake, estimated_hit_probability, current_odds, market_implied_probability, EV, rationale];\n    allow_no_bet: true;\n    rule: "EV・資金効率・再現性の基準を満たさなければSKIP。B/Cを出しても無理に買わない";\n  }\n\n  B_MAIN_ORDER {\n    role: "最も起こりやすい着順";\n    format: "1着→2着→3着";\n    max_patterns: 1;\n    include_confidence_or_probability: true;\n    determine_from: [line_structure, role, recent_form, current_meeting, race_shape, track, comments, matchup];\n  }\n\n  C_SECONDARY_ORDER {\n    role: "本線が一部崩れた時の第2有力着順";\n    format: "1着→2着→3着";\n    max_patterns: 1;\n    include_confidence_or_probability: true;\n    prioritize: [second_wheel_pass, front_survival, rival_line_self_power_survival, rival_line_second_wheel_survival, third_candidate_promotes_to_second, whole_line_survival, partial_line_collapse];\n    reject: [random_longshot, blind_box, result_hindsight];\n  }\n\n  separation_rules: [\n    "A/B/Cは一致してもよいが無理に一致させない",\n    "3パターン全部を買う前提にしない",\n    "結果後にB/Cを追加・変更して的中扱いにしない",\n    "頭だけ一致、または2着まで一致でも3連単BETは完全一致でなければ不的中"\n  ];\n}\n\nTHREE_PATTERN_AUDIT {\n  metrics: [\n    value_bet_hit_and_ROI,\n    first_place_match_rate,\n    main_order_exact_rate,\n    secondary_order_exact_rate,\n    main_or_secondary_exact_capture_rate,\n    top3_set_match_rate,\n    head_match_but_2nd_3rd_miss_count,\n    pre_race_explainable_but_omitted_order_count\n  ];\n  evaluation: "AのROIとB/Cの着順捕捉率を別々に集計し、十分なサンプル後にウォークフォワード評価する";\n}`;

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.1.0 · 3-PATTERN';

    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI分析プロンプト · v5.1.0';

    const lead = document.querySelector('.strict-lead');
    if (lead) {
      lead.textContent = '開催日・開催場・レース番号を選ぶだけで、VALUE BETと着順予測を分離し、MAIN ORDER・SECONDARY ORDERの2つの事前シナリオまでFreeze。従来の本線3連複、番手差し、2着浮上、別線残存、高配当保険も同時監査します。';
    }
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value) return;

    let value = output.value.replace(/v4\.9\.0/g, `v${VERSION}`).replace(/v5\.0\.0/g, `v${VERSION}`);
    if (!value.includes(MARKER)) value += TAIL_RISK_BLOCK;
    if (!value.includes(THREE_PATTERN_MARKER)) value += THREE_PATTERN_BLOCK;
    output.value = value;

    const count = document.getElementById('char-count');
    if (count) count.textContent = String(output.value.length);
  }

  document.addEventListener('DOMContentLoaded', () => {
    patchVersionUI();

    const form = document.getElementById('race-form');
    if (form) {
      form.addEventListener('submit', () => {
        setTimeout(() => {
          patchVersionUI();
          patchPrompt();
        }, 0);
        setTimeout(patchPrompt, 80);
      });
    }

    const output = document.getElementById('prompt-output');
    if (output) {
      const observer = new MutationObserver(() => patchPrompt());
      observer.observe(output, { attributes: true, childList: true, subtree: true });
    }

    const copy = document.getElementById('copy-button');
    const share = document.getElementById('share-button');
    const download = document.getElementById('download-button');
    [copy, share, download].forEach(btn => btn && btn.addEventListener('click', patchPrompt, true));
  });
})();
