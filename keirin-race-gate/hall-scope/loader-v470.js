(async()=>{
  const status=document.getElementById('status'),bar=document.getElementById('bar');
  const fail=m=>{if(bar)bar.style.display='none';if(status)status.textContent=m||'読み込みに失敗しました。'};
  try{
    if(!('DecompressionStream' in window))throw new Error('ブラウザを最新版に更新してください。');
    const r=await fetch('./app-v4.7.html.gz.b64?v=4.7.0',{cache:'no-store'});
    if(!r.ok)throw new Error('アプリ本体を取得できませんでした。');
    const b64=(await r.text()).trim();
    const bin=Uint8Array.from(atob(b64),c=>c.charCodeAt(0));
    const stream=new Blob([bin]).stream().pipeThrough(new DecompressionStream('gzip'));
    const html=await new Response(stream).text();
    document.open();document.write(html);document.close();
  }catch(e){console.error(e);fail(e&&e.message?e.message:'読み込みに失敗しました。')}
})();