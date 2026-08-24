(() => {
  'use strict';
  const DATA_KEY='smartATSPro.data', MAX=10*1024*1024;
  const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
  const esc=v=>String(v??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
  function state(){try{return JSON.parse(localStorage.getItem(DATA_KEY)||'{"candidates":[]}');}catch(e){return {candidates:[]};}}
  function enabled(){return window.SmartATSAccount?.get?.().resumeOriginals==='local_vault';}
  function saveEnabled(v){const c=window.SmartATSAccount?.get?.()||{};window.SmartATSAccount?.save?.({...c,resumeOriginals:v?'local_vault':'off'});}
  function hasBridge(){return !!window.AndroidBridge?.saveEncryptedDocument;}
  function list(cid){if(!cid||!hasBridge())return [];try{return JSON.parse(AndroidBridge.listCandidateDocuments(cid)||'[]');}catch(e){return [];}}
  function toast(m){const t=$('#toast');if(!t)return;t.textContent=m;t.classList.remove('hidden');clearTimeout(toast.t);toast.t=setTimeout(()=>t.classList.add('hidden'),2200);}
  function readFile(file){return new Promise((res,rej)=>{if(!file)return rej(new Error('ファイルを選択してください'));if(file.size>MAX)return rej(new Error('10MB以下のファイルを選択してください'));const type=file.type==='image/jpg'?'image/jpeg':file.type;if(!['application/pdf','image/png','image/jpeg'].includes(type))return rej(new Error('PDF / PNG / JPEGのみ対応しています'));const fr=new FileReader();fr.onload=()=>res({name:file.name,mimeType:type,base64:String(fr.result).split(',')[1]||''});fr.onerror=()=>rej(new Error('ファイルを読み込めませんでした'));fr.readAsDataURL(file);});}
  function docsHtml(ds){return ds.length?ds.map(d=>`<div class="vault-row"><div class="vault-meta"><b>${esc(d.name||'document')}</b><small>${esc(d.mimeType||'')} ・ ${Math.round((d.size||0)/1024)}KB</small></div><div class="vault-actions"><button class="danger-text" data-delete-doc="${esc(d.id)}">削除</button></div></div>`).join(''):'<div class="empty" style="padding:14px"><strong>保存原本はありません</strong>必要な候補者だけ保存できます。</div>';}
  function open(selected=''){
    const s=state(),cid=selected||s.candidates[0]?.id||'',docs=list(cid),sheet=$('#sheet'),body=$('#sheetBody'),back=$('#sheetBackdrop');
    $('#sheetTitle').textContent='履歴書・職務経歴書 保管庫';$('#sheetEyebrow').textContent='ENCRYPTED LOCAL VAULT';
    body.innerHTML=`<div class="form-stack"><div class="notice">原本保存は任意です。OFFでもGemini解析とATS本体は使えます。保存時はAndroid KeystoreのAES-GCM鍵で暗号化してアプリ専用領域へ保管します。</div><label class="toggle-row"><span><b>この端末に原本を保存</b><small>必要な時だけON</small></span><input type="checkbox" id="vaultEnabled" ${enabled()?'checked':''}></label><label>候補者<select id="vaultCandidate"><option value="">候補者を選択</option>${s.candidates.map(c=>`<option value="${esc(c.id)}" ${c.id===cid?'selected':''}>${esc(c.name)}</option>`).join('')}</select></label>${enabled()?`<div class="vault-file"><input type="file" id="vaultFile" accept="application/pdf,image/png,image/jpeg,.pdf,.png,.jpg,.jpeg"><div style="font-size:10px;color:var(--muted);margin-top:5px">PDF / PNG / JPEG・10MB以下。保存だけではGeminiへ送りません。</div></div><button class="primary-btn" id="vaultSave" ${!cid||!hasBridge()?'disabled':''}>暗号化して保存</button>`:'<div class="vault-warning">原本保存はOFFです。</div>'}<div class="section-subtitle">保存原本</div><div class="vault-card" id="vaultDocs">${docsHtml(docs)}</div><button class="secondary-btn" id="vaultClose">閉じる</button></div>`;
    back.classList.remove('hidden');sheet.classList.remove('hidden');sheet.scrollTop=0;
    $('#vaultEnabled',body).onchange=e=>{saveEnabled(e.target.checked);open(cid);};$('#vaultCandidate',body).onchange=e=>open(e.target.value);$('#vaultClose',body).onclick=()=>window.SmartATS?.closeTopLayer?.();
    $('#vaultSave',body)?.addEventListener('click',async()=>{try{const f=await readFile($('#vaultFile',body).files[0]);const r=JSON.parse(AndroidBridge.saveEncryptedDocument(cid,f.name,f.mimeType,f.base64)||'{}');if(r.error)throw new Error(r.error);toast('原本を暗号化して保存しました');open(cid);}catch(e){toast(e.message||'保存に失敗しました');}});
    $$('[data-delete-doc]',body).forEach(b=>b.onclick=()=>{if(!confirm('この原本を削除しますか？'))return;toast(AndroidBridge.deleteEncryptedDocument(b.dataset.deleteDoc)?'原本を削除しました':'削除できませんでした');open(cid);});
  }
  function purgeCandidateDocs(cid){if(!hasBridge()||!cid)return;for(const d of list(cid)){try{AndroidBridge.deleteEncryptedDocument(d.id);}catch(e){}}}
  let beforeIds=new Set(state().candidates.map(c=>c.id));
  function scheduleRemovedCandidateCleanup(){setTimeout(()=>{const after=new Set(state().candidates.map(c=>c.id));for(const id of beforeIds)if(!after.has(id))purgeCandidateDocs(id);beforeIds=after;},80);}
  document.addEventListener('click',e=>{if(e.target.closest('#deleteCandidateBtn')||e.target.closest('[data-action="clear-all"]')||e.target.closest('[data-action="reset-demo"]')||e.target.closest('#restoreBtn'))scheduleRemovedCandidateCleanup();});
  function inject(){const main=$('#appMain');if(!main||$('#vaultCard')||$('#screenTitle')?.textContent!=='その他')return;const screen=main.querySelector('.screen');if(!screen)return;const card=document.createElement('div');card.className='section-card';card.id='vaultCard';card.innerHTML=`<div class="section-head"><h3>書類原本</h3><span class="hint">任意・端末暗号化</span></div><button class="menu-card" id="openVault"><span><b>履歴書・職務経歴書 保管庫</b><small>${enabled()?'暗号化保存 ON':'保存OFF（解析のみ利用可）'}</small></span><span class="chev">›</span></button>`;screen.appendChild(card);$('#openVault',card).onclick=()=>open();}
  new MutationObserver(inject).observe(document.body,{childList:true,subtree:true});
  window.SmartATSVault={open,list,enabled,purgeCandidateDocs,scheduleRemovedCandidateCleanup};inject();
})();
