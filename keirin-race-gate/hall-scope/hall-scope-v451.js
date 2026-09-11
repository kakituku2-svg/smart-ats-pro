(()=>{
  try{
    const nav=document.querySelector('.bottom-nav');
    if(!nav)return;
    const all=[...nav.querySelectorAll('.tab[data-mode]')];
    const by=m=>all.find(b=>b.dataset.mode===m);
    const area=by('area'),store=by('store'),event=by('event'),live=by('live'),ledger=by('ledger'),counter=by('counter');
    if(!(area&&store&&event&&live&&ledger&&counter))return;
    area.querySelector('span:last-child').textContent='ホーム';
    store.querySelector('span:last-child').textContent='店比較';
    nav.appendChild(live);
    [event,ledger,counter].forEach(b=>b.style.display='none');
    const hist=document.createElement('button');
    hist.className='tab';hist.type='button';
    hist.innerHTML='<span class="nav-icon">▤</span><span>履歴</span>';
    const more=document.createElement('button');
    more.className='tab';more.type='button';
    more.innerHTML='<span class="nav-icon">•••</span><span>その他</span>';
    nav.append(hist,more);
    const back=document.createElement('div');back.className='hs-back';
    const sheet=document.createElement('section');sheet.className='hs-sheet';
    sheet.innerHTML='<div class="hs-title"><b>その他の機能</b><button class="hs-close">×</button></div><div class="hs-grid"><button class="hs-act" data-go="event">≋<br>イベント・癖</button><button class="hs-act" data-go="ledger">▦<br>収支</button><button class="hs-act" data-go="counter">＋1<br>小役</button><button class="hs-act" id="hsDisplay">☀<br>表示</button></div>';
    document.body.append(back,sheet);
    const close=()=>{back.classList.remove('open');sheet.classList.remove('open')};
    more.onclick=()=>{back.classList.add('open');sheet.classList.add('open')};
    back.onclick=close;
    sheet.querySelector('.hs-close').onclick=close;
    sheet.querySelectorAll('[data-go]').forEach(b=>b.onclick=()=>{
      by(b.dataset.go)?.click();close();
      setTimeout(()=>{[area,store,live,hist].forEach(x=>x.classList.remove('active'));more.classList.add('active')},0);
    });
    [area,store,live].forEach(b=>b.addEventListener('click',()=>{hist.classList.remove('active');more.classList.remove('active')}));
    hist.onclick=()=>{area.click();setTimeout(()=>{area.classList.remove('active');more.classList.remove('active');hist.classList.add('active');document.querySelector('.hist')?.scrollIntoView({behavior:'smooth',block:'start'})},0)};
    const t=document.getElementById('modeTitle'),n=document.getElementById('modeNote');
    if(t&&n){
      const r=document.createElement('div');r.className='hs-mode';t.parentNode.insertBefore(r,t);r.append(t);
      const q=document.createElement('button');q.className='hs-info';q.textContent='?';r.append(q);
      q.onclick=()=>{n.classList.toggle('hs-open');q.textContent=n.classList.contains('hs-open')?'×':'?'};
    }
    const vis=document.getElementById('visibilityBtn');
    const display=document.getElementById('hsDisplay');
    if(vis&&display)display.onclick=()=>vis.click();
    document.title='HALL SCOPE v4.5.1 — HALL INTELLIGENCE';
    document.querySelectorAll('.version-pill').forEach(x=>x.textContent='v4.5.1');
    const foot=document.querySelector('.foot');
    if(foot)foot.textContent=foot.textContent.replace('HALL VISIBILITY','HALL INTELLIGENCE');
  }catch(e){console.error(e)}
})();
