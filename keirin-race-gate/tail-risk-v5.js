(() => {
  'use strict';

  const VERSION = '5.0.0';
  const MARKER = 'TAIL_RISK_100 {';
  const TAIL_RISK_BLOCK = `\n\nTAIL_RISK_100 {\n  purpose: "本線では薄いが、事前情報から具体的に説明でき、100円だけ残す価値がある高配当シナリオを切り捨てない";\n  classify_as: HIGH_PAYOUT_INSURANCE;\n  separate_from_main: true;\n  default_reference_stake_per_ticket: 100_JPY;\n  max_candidates: 3;\n  do_not_force_candidate: true;\n\n  trigger_if: [\n    concrete_pre_race_causal_path_exists,\n    probability_is_low_but_non_negligible,\n    payout_impact_is_large,\n    candidate_does_not_require_blind_box_or_total_spread\n  ];\n\n  priority_checks: [\n    current_meeting_1st_or_2nd_despite_low_score,\n    underrated_whole_line_survival,\n    front_collapses_but_second_or_third_wheel_survives,\n    pace_duel_promotes_solo_or_closer_to_1st_or_2nd,\n    third_place_candidate_promotes_to_1st_or_2nd,\n    strong_current_form_overrides_static_score_gap,\n    cross_line_residual_exact_order\n  ];\n\n  odds_review: {\n    trifecta_50x_plus: PRIORITY_RECHECK;\n    trifecta_100x_plus: STRONG_RECHECK;\n    trifecta_200x_plus: MANDATORY_VALUE_RECHECK_IF_CAUSAL_PATH_EXISTS;\n    high_odds_alone_is_not_reason: true;\n  };\n\n  reject_if: [\n    odds_only_reason,\n    popularity_only_reason,\n    blind_box,\n    total_spread,\n    mutually_exclusive_tactics,\n    no_causal_path\n  ];\n\n  output_each: [ticket, current_odds, causal_condition, rough_probability_band, why_100yen_is_worth_retaining];\n  accounting: "100円は参考提案額。ユーザーが実購入を明示しない限り実収支へ算入しない";\n}\n\nRESULT_AUDIT_EXTENSION {\n  compare_tail_risk_100: true;\n  report_if_hit: [ticket, official_payout_per_100yen, causal_scenario_that_occurred];\n  report_if_missed: [was_pre_race_explainable, should_it_have_been_tail_risk_candidate];\n  daily_report_metrics: [tail_risk_candidates, tail_risk_hits, hypothetical_100yen_payout_separate_from_real_PnL];\n}`;

  function patchVersionUI() {
    const badge = document.querySelector('.paper-badge');
    if (badge) badge.innerHTML = '<i></i>v5.0.0 iOS';

    const toolbar = document.querySelector('.prompt-toolbar span');
    if (toolbar) toolbar.innerHTML = '<i></i>AI分析プロンプト · v5.0.0';

    const lead = document.querySelector('.strict-lead');
    if (lead && !lead.textContent.includes('高配当保険')) {
      lead.textContent = '開催日・開催場・レース番号を選ぶだけで、本線3連複を厚めにしつつ、番手差し・2着浮上・選手背景・別線のライン丸ごと残存・軸候補と3着残存候補の共存に加え、100円だけ残す価値がある高配当保険まで監査する実戦予想プロンプトを作成します。';
    }
  }

  function patchPrompt() {
    const output = document.getElementById('prompt-output');
    if (!output || !output.value || output.value.includes(MARKER)) return;

    output.value = output.value.replace(/v4\.9\.0/g, `v${VERSION}`) + TAIL_RISK_BLOCK;

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
