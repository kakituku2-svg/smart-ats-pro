(async()=>{
  const status=document.getElementById('status');
  const bar=document.getElementById('bar');
  const fail=(msg)=>{if(bar)bar.style.display='none';if(status)status.textContent=msg||'読み込みに失敗しました。'};
  try{
    if(!('DecompressionStream' in window)) throw new Error('ブラウザを最新版に更新してください。');
    const base='../settei-kanpa-ai/';
    const names=[
      'app-v4.2.part1.txt','app-v4.2.part2.txt','app-v4.2.part3.txt','app-v4.2.part4.txt','app-v4.2.part5.txt',
      'app-v4.2.part6a.txt','app-v4.2.part6b.txt','app-v4.2.part6c.txt','app-v4.2.part6d.txt'
    ];
    const parts=await Promise.all(names.map(async n=>{
      const r=await fetch(base+n+'?v=4.5.1',{cache:'no-store'});
      if(!r.ok) throw new Error('アプリ本体を取得できませんでした。');
      return (await r.text()).trim();
    }));
    const bin=Uint8Array.from(atob(parts.join('')),c=>c.charCodeAt(0));
    const stream=new Blob([bin]).stream().pipeThrough(new DecompressionStream('gzip'));
    let h=await new Response(stream).text();
    h=h
      .replaceAll('設定看破AI','HALL SCOPE')
      .replaceAll('STORE INTELLIGENCE / 店選び・イベント癖・台番予測','店・イベント・台を読む / HALL INTELLIGENCE')
      .replaceAll('PACHISLOT_RESEARCH_PROMPT_CONTROLLER','HALL_SCOPE_RESEARCH_CONTROLLER')
      .replaceAll('ATSUDai-4.2','HALLSCOPE-4.5.1')
      .replaceAll('v4.2','v4.5.1');
    h=h.replace('</head>','<link rel="stylesheet" href="./hall-scope-v451.css?v=4.5.1"></head>');
    h=h.replace('</body>','<script src="./hall-scope-v451.js?v=4.5.1"></script></body>');
    document.open();
    document.write(h);
    document.close();
  }catch(e){
    console.error(e);
    fail(e&&e.message?e.message:'読み込みに失敗しました。');
  }
})();
