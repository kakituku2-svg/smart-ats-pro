(() => {
  'use strict';
  const $=(s,r=document)=>r.querySelector(s);
  let lastCandidateId='';
  document.addEventListener('click',e=>{const row=e.target.closest('[data-candidate-id]');if(row){lastCandidateId=row.dataset.candidateId||'';localStorage.setItem('smartATSPro.ai.lastCandidateId',lastCandidateId);window.SmartATSAI?.setCandidate?.(lastCandidateId);}} ,true);
  function selected(){return lastCandidateId||localStorage.getItem('smartATSPro.ai.lastCandidateId')||'';}
  function chooseAfterRender(fn){const id=selected();window.SmartATSAI?.setCandidate?.(id);window.SmartATSAI?.open?.();setTimeout(()=>window.SmartATSAI?.[fn]?.(id),0);}
  function inject(){const body=$('#sheetBody');if(!body||$('.candidate-ai-strip',body)||!$('#editCandidateBtn',body))return;const host=$('#editCandidateBtn',body)?.closest('.action-grid');if(!host)return;const box=document.createElement('div');box.className='candidate-ai-strip';box.innerHTML='<div class="title">Gemini AIアシスト</div><div class="candidate-ai-grid"><button data-cai="renderScout">AIスカウト</button><button data-cai="renderReply">AIメール返信</button><button data-cai="renderSummary">AI職務要約</button><button data-cai="renderQuestions">AI面接質問</button></div>';host.insertAdjacentElement('afterend',box);box.querySelectorAll('[data-cai]').forEach(b=>b.onclick=()=>chooseAfterRender(b.dataset.cai));}
  new MutationObserver(inject).observe(document.body,{childList:true,subtree:true});
  window.SmartATSWorkflow={get lastCandidateId(){return selected();},chooseAfterRender};
})();
