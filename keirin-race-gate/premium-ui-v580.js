(() => {
  'use strict';

  const UI_VERSION = '5.8.0';
  const LOGIC_VERSION = '5.10.0';

  function q(sel, root=document){ return root.querySelector(sel); }
  function qa(sel, root=document){ return [...root.querySelectorAll(sel)]; }

  function applyBranding(){
    const badge=q('.paper-badge');
    if(badge) badge.innerHTML='<i></i>v5.8.0 · LIVE DATA / EV';
    const brandSmall=q('.brand-copy small');
    if(brandSmall) brandSmall.textContent='AI PREDICTION PROMPT APP';
    const title=q('.hero h1, .brand-title');
    if(title){
      title.innerHTML='KEIRIN<br><em>RACE GATE</em>';
      title.setAttribute('aria-label','KEIRIN RACE GATE');
    }
    const lead=q('.hero-lead');
    if(lead && !q('.premium-kicker')){
      const micro=document.createElement('div');
      micro.className='premium-kicker';
      micro.textContent='SPEED · DATA · INTELLIGENCE FOR A BRIGHTER WIN.';
      lead.insertAdjacentElement('afterend',micro);
    }
  }

  function addGeneratedSection(){
    if(q('.premium-generated')) return;
    const card=q('.composer-card');
    if(!card) return;
    const box=document.createElement('section');
    box.className='premium-generated';
    box.setAttribute('aria-label','生成される内容');
    box.innerHTML=`
      <h3>生成される内容</h3>
      <div class="premium-checks">
        <div><i>✓</i><span>レース展開の分析視点</span></div>
        <div><i>✓</i><span>3連複・3連単の買い目考察</span></div>
        <div><i>✓</i><span>オッズ・EVに基づく投資判断</span></div>
        <div><i>✓</i><span>AIに最適化された予想プロンプト</span></div>
      </div>
      <div class="premium-microcopy">MORE INSIGHT · A BRIGHTER TOMORROW.</div>`;
    card.insertAdjacentElement('afterend',box);
  }

  function addFeatureGrid(){
    if(q('.premium-feature-grid')) return;
    const gen=q('.premium-generated');
    if(!gen) return;
    const section=document.createElement('section');
    section.className='premium-feature-grid';
    section.setAttribute('aria-label','主な機能');
    section.innerHTML=`
      <article class="premium-feature"><span class="n">01</span><span class="icon" aria-hidden="true">▥</span><b>3連複・3連単</b><p>データに基づく買い目考察</p></article>
      <article class="premium-feature"><span class="n">02</span><span class="icon" aria-hidden="true">⌁</span><b>ライン・展開分析</b><p>選手・ライン・展開を多角的に分析</p></article>
      <article class="premium-feature"><span class="n">03</span><span class="icon" aria-hidden="true">⚖</span><b>フェアオッズ / EV / BUY・SKIP</b><p>期待値に基づく合理的な判断</p></article>`;
    gen.insertAdjacentElement('afterend',section);
  }

  // The prompt generator itself does not fabricate prediction results.
  // Decision cards render only when a future/connected result engine explicitly marks
  // #prompt-output with data-result-mode="live" and outputs [LIVE_RESULT] rows.
  function syncDecisionCards(){
    const out=q('#prompt-output');
    const result=q('.result-card');
    if(!out || !result) return;
    let holder=q('.premium-decision-list',result);
    const isLive=out.dataset && out.dataset.resultMode==='live';
    if(!isLive){ if(holder) holder.remove(); return; }
    const text=(out.value||out.textContent||'').trim();
    const lines=text.split(/\n+/).map(s=>s.trim()).filter(s=>/^\[LIVE_RESULT\]/.test(s));
    const matches=[];
    for(const line of lines){
      if(!/\b(BUY|SKIP)\b/i.test(line)) continue;
      if(!/(EV|オッズ|odds)/i.test(line)) continue;
      const status=/\bBUY\b/i.test(line)?'BUY':'SKIP';
      const ev=(line.match(/EV\s*[:=]?\s*([+\-]?\d+(?:\.\d+)?%?)/i)||[])[1]||'';
      const odds=(line.match(/(?:オッズ|odds)\s*[:=]?\s*(\d+(?:\.\d+)?)/i)||[])[1]||'';
      const combo=(line.match(/(?:3連単|3連複|2車単)[^\n]{0,40}/)||[])[0]||line.replace(/^\[LIVE_RESULT\]\s*/,'').slice(0,60);
      matches.push({status,ev,odds,combo});
      if(matches.length>=4) break;
    }
    if(!matches.length){ if(holder) holder.remove(); return; }
    if(!holder){ holder=document.createElement('div'); holder.className='premium-decision-list'; result.prepend(holder); }
    holder.innerHTML=matches.map(x=>`<div class="premium-decision ${x.status==='BUY'?'buy':'skip'}"><span class="tag">${x.status}</span><div><b>${escapeHtml(x.combo)}</b><div class="meta">${x.odds?`ODDS ${escapeHtml(x.odds)}`:''}</div></div><span class="ev">${x.ev?`EV ${escapeHtml(x.ev)}`:''}</span></div>`).join('');
  }

  function escapeHtml(s){ return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

  function enhanceSubmit(){
    const submit=q('button[type="submit"], #generate-button, .generate-button');
    if(!submit) return;
    if(!/AI予想プロンプトを生成/.test(submit.textContent||'')) submit.textContent='AI予想プロンプトを生成';
    submit.setAttribute('aria-label','AI予想プロンプトを生成');
  }

  function bottomNav(){
    if(q('.premium-bottom-nav')) return;
    const tabs=qa('.app-tab');
    if(!tabs.length) return;
    const nav=document.createElement('nav');
    nav.className='premium-bottom-nav';
    nav.setAttribute('aria-label','アプリナビゲーション');
    const labels=tabs.slice(0,2).map((tab,i)=>({label:i===0?'生成':'使い方',tab}));
    nav.innerHTML=labels.map((x,i)=>`<button type="button" data-pnav="${i}" class="${x.tab.getAttribute('aria-selected')==='true'?'active':''}">${x.label}</button>`).join('');
    document.body.append(nav);
    qa('button',nav).forEach(btn=>btn.addEventListener('click',()=>{
      const item=labels[Number(btn.dataset.pnav)];
      if(item?.tab){ item.tab.click(); window.scrollTo({top:0,behavior:'smooth'}); }
    }));
    const sync=()=>qa('button',nav).forEach((btn,i)=>btn.classList.toggle('active',labels[i].tab.getAttribute('aria-selected')==='true'));
    tabs.forEach(t=>t.addEventListener('click',()=>setTimeout(sync,0)));
  }

  function annotateVersion(){
    document.documentElement.dataset.uiVersion=UI_VERSION;
    document.documentElement.dataset.logicVersion=LOGIC_VERSION;
  }

  function run(){
    annotateVersion();
    applyBranding();
    enhanceSubmit();
    addGeneratedSection();
    addFeatureGrid();
    bottomNav();
    syncDecisionCards();
  }

  document.addEventListener('DOMContentLoaded',()=>{
    run();
    setTimeout(run,80); setTimeout(run,400); setTimeout(run,1200);
    const form=q('#race-form');
    if(form) form.addEventListener('submit',()=>{ setTimeout(syncDecisionCards,50); setTimeout(syncDecisionCards,500); });
    const out=q('#prompt-output');
    if(out) out.addEventListener('input',syncDecisionCards);
  });
  window.addEventListener('load',run);
})();
