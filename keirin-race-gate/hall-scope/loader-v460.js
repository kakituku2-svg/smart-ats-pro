(async()=>{
  const status=document.getElementById('status'),bar=document.getElementById('bar');
  const fail=m=>{if(bar)bar.style.display='none';if(status)status.textContent=m||'読み込みに失敗しました。'};
  try{
    if(!('DecompressionStream' in window))throw new Error('ブラウザを最新版に更新してください。');
    const names=['app-v4.6.part1.txt','app-v4.6.part2.txt','app-v4.6.part3.txt','app-v4.6.part4.txt','app-v4.6.part5.txt','app-v4.6.part6.txt','app-v4.6.part7.txt','app-v4.6.part8.txt'];
    const parts=await Promise.all(names.map(async n=>{const r=await fetch('./'+n+'?v=4.6.0',{cache:'no-store'});if(!r.ok)throw new Error('アプリ本体を取得できませんでした。');return(await r.text()).trim()}));
    const bin=Uint8Array.from(atob(parts.join('')),c=>c.charCodeAt(0));
    const stream=new Blob([bin]).stream().pipeThrough(new DecompressionStream('gzip'));
    const html=await new Response(stream).text();
    document.open();document.write(html);document.close();
  }catch(e){console.error(e);fail(e&&e.message?e.message:'読み込みに失敗しました。')}
})();