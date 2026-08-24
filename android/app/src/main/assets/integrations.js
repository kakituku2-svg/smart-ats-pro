(() => {
  'use strict';
  const pending=new Map();
  const $=(s,r=document)=>r.querySelector(s);
  const uid=()=>`int_${Date.now()}_${Math.random().toString(36).slice(2,7)}`;
  function cfg(){return window.SmartATSAccount?.get?.()||{};}
  function toast(msg){const t=$('#toast');if(!t)return;t.textContent=msg;t.classList.remove('hidden');clearTimeout(toast.t);toast.t=setTimeout(()=>t.classList.add('hidden'),2500);}
  function testSupabase(){
    const c=cfg();
    if(!window.AndroidBridge?.testSupabaseConnection)return Promise.reject(new Error('APK版で利用してください'));
    if(!c.cloudProjectUrl||!c.cloudAnonKey)return Promise.reject(new Error('Supabase URLと公開キーを先に設定してください'));
    const id=uid();return new Promise((resolve,reject)=>{pending.set(id,{resolve,reject});AndroidBridge.testSupabaseConnection(c.cloudProjectUrl,c.cloudAnonKey,id);setTimeout(()=>{if(pending.has(id)){pending.delete(id);reject(new Error('接続確認がタイムアウトしました'));}},25000);});
  }
  function gmailStatus(){try{return !!window.AndroidBridge?.isGmailInstalled?.();}catch(e){return false;}}
  function open(){
    const sheet=$('#sheet'),body=$('#sheetBody'),back=$('#sheetBackdrop'),c=cfg();
    $('#sheetTitle').textContent='連携診断';$('#sheetEyebrow').textContent='OPTIONAL CONNECTIONS';
    body.innerHTML=`<div class="form-stack"><div class="notice">ここで行うのは接続確認だけです。候補者・求人データを自動同期しません。</div><div class="section-card"><div class="section-head"><h3>Supabase</h3><span class="badge ${c.cloudProjectUrl&&c.cloudAnonKey?'blue':''}">${c.cloudProjectUrl?'設定あり':'未設定'}</span></div><p style="font-size:12px;color:var(--muted)">REST APIへ到達できるかだけ確認します。候補者データは送信しません。</p><button class="secondary-btn" id="testSupabase" style="margin-top:10px;width:100%">接続テスト</button><div id="supabaseResult"></div></div><div class="section-card"><div class="section-head"><h3>Gmail / メール</h3><span class="badge ${gmailStatus()?'ok':''}">${gmailStatus()?'Gmailアプリあり':'標準メール方式'}</span></div><p style="font-size:12px;color:var(--muted)">Gmail API未接続でも、AIで作った件名・本文を端末のメールアプリへ渡せます。</p></div><button class="secondary-btn" id="integrationClose">閉じる</button></div>`;
    back.classList.remove('hidden');sheet.classList.remove('hidden');
    $('#integrationClose',body).onclick=()=>window.SmartATS?.closeTopLayer?.();
    $('#testSupabase',body).onclick=async()=>{const box=$('#supabaseResult',body);box.innerHTML='<div class="notice" style="margin-top:10px">接続確認中…</div>';try{const msg=await testSupabase();box.innerHTML=`<div class="ai-success" style="margin-top:10px">${String(msg).replace(/[<>]/g,'')}</div>`;}catch(e){box.innerHTML=`<div class="ai-error" style="margin-top:10px">${String(e.message||e).replace(/[<>]/g,'')}</div>`;}};
  }
  function inject(){const main=$('#appMain');if(!main||$('#integrationDiagCard')||$('#screenTitle')?.textContent!=='その他')return;const screen=main.querySelector('.screen');if(!screen)return;const card=document.createElement('div');card.className='section-card';card.id='integrationDiagCard';card.innerHTML='<div class="section-head"><h3>連携診断</h3><span class="hint">任意</span></div><button class="menu-card" id="openIntegrationDiag"><span><b>Supabase / Gmailを確認</b><small>接続準備だけを安全にチェック</small></span><span class="chev">›</span></button>';screen.appendChild(card);$('#openIntegrationDiag',card).onclick=open;}
  new MutationObserver(inject).observe(document.body,{childList:true,subtree:true});
  window.SmartATSIntegrations={open,testSupabaseConnection:testSupabase,gmailStatus,_nativeResult(id,ok,payload){const p=pending.get(id);if(!p)return;pending.delete(id);ok?p.resolve(payload):p.reject(new Error(payload||'接続に失敗しました'));}};inject();
})();
