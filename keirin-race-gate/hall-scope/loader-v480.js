(async()=>{
  const status=document.getElementById('status'),bar=document.getElementById('bar');
  const fail=m=>{if(bar)bar.style.display='none';if(status)status.textContent=m||'読み込みに失敗しました。';};
  try{
    if(!('DecompressionStream' in window))throw new Error('ブラウザを最新版に更新してください。');
    const files=['./app-v4.8.part1.txt?v=4.8.0','./app-v4.8.part2.txt?v=4.8.0','./app-v4.8.part3.txt?v=4.8.0','./app-v4.8.part4.txt?v=4.8.0','./app-v4.8.part5.txt?v=4.8.0','./app-v4.8.part6.txt?v=4.8.0','./app-v4.8.part7.txt?v=4.8.0','./app-v4.8.part8.txt?v=4.8.0'];
    const texts=await Promise.all(files.map(async f=>{const r=await fetch(f,{cache:'no-store'});if(!r.ok)throw new Error('アプリ本体を取得できませんでした。');return (await r.text()).trim();}));
    const bin=Uint8Array.from(atob(texts.join('')),c=>c.charCodeAt(0));
    const stream=new Blob([bin]).stream().pipeThrough(new DecompressionStream('gzip'));
    const html=await new Response(stream).text();
    if(!html.includes('HALL_SCOPE_V48_PACHINKO_EVENT_ENGINE'))throw new Error('アプリ本体の検証に失敗しました。');
    document.open();document.write(html);document.close();
  }catch(e){console.error(e);fail(e&&e.message?e.message:'読み込みに失敗しました。')}
})();