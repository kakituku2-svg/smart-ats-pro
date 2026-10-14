/* AI制作工房 — 図解スタジオ / independent image per page. No tracking, no embedded API keys. */
(function () {
  'use strict';
  const CREATIVE_STUDIO_VERSION = '2.6.0';
  const $ = (id) => document.getElementById(id);
  const PRESETS = [
    {id:'navy',name:'ネイビー・プロ',desc:'法人向け提案',bg:'#0e1a2d',paper:'#152940',ink:'#f6fbff',accent:'#52d5d4',accent2:'#f4c36d',layout:'cards'},
    {id:'ivory',name:'アイボリー',desc:'シンプル・上品',bg:'#faf6ef',paper:'#ffffff',ink:'#262e34',accent:'#b87754',accent2:'#d9b77b',layout:'editorial'},
    {id:'mint',name:'ミント・データ',desc:'図解・分析',bg:'#edf9f8',paper:'#ffffff',ink:'#123f45',accent:'#158f88',accent2:'#f1b04d',layout:'cards'},
    {id:'midnight',name:'ミッドナイト',desc:'インパクト重視',bg:'#070915',paper:'#15182b',ink:'#ffffff',accent:'#b58cff',accent2:'#59cdf1',layout:'poster'},
    {id:'coral',name:'コーラル',desc:'SNS・発信',bg:'#fff0ec',paper:'#ffffff',ink:'#4b2e38',accent:'#ef6b69',accent2:'#ffb25f',layout:'split'},
    {id:'forest',name:'フォレスト',desc:'教育・自然',bg:'#edf2e9',paper:'#ffffff',ink:'#213f36',accent:'#358365',accent2:'#e5a95b',layout:'editorial'},
    {id:'blueprint',name:'ブループリント',desc:'研究・技術',bg:'#0f3a66',paper:'#174c79',ink:'#f7fbff',accent:'#6fe0ef',accent2:'#ffdc80',layout:'split'},
    {id:'mono',name:'モノクロ',desc:'読みやすさ重視',bg:'#f5f5f3',paper:'#ffffff',ink:'#202020',accent:'#252525',accent2:'#777777',layout:'editorial'}
  ];
  const MAX_PAGES = 5;
  const STORAGE = 'ai_kobo_creative_studio_v260';
  const enc = new TextEncoder();
  const state = {preset:'navy',format:'landscape',pages:[],index:0,history:[],images:{},busy:false};
  const preset = () => PRESETS.find(p=>p.id===state.preset)||PRESETS[0];
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const pad = (n) => String(n).padStart(2,'0');
  const text = (v,max=600) => String(v||'').replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/g,'').slice(0,max).trim();
  const page = (o={}) => ({kicker:text(o.kicker||'KEY INSIGHT',38),title:text(o.title||'新しいページ',100),body:text(o.body||'',680),footer:text(o.footer||'AI制作工房',60)});
  const status = (message,bad=false) => { $('status').textContent=message;$('status').classList.toggle('warn',bad); };
  function dimensions(){return state.format==='portrait'?[1080,1440]:[1600,900];}
  function escapeXML(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
  function snapshot(){state.history.push({preset:state.preset,format:state.format,pages:clone(state.pages),index:state.index});if(state.history.length>30)state.history.shift();$('undoBtn').disabled=!state.history.length;}
  function restore(){const last=state.history.pop();if(!last)return;state.preset=last.preset;state.format=last.format;state.pages=last.pages;state.index=Math.min(last.index,state.pages.length-1);state.images={};$('format').value=state.format;buildGallery();renderAll();$('undoBtn').disabled=!state.history.length;status('直前の状態に戻しました');}
  function buildGallery(){
    const host=$('designGallery');host.replaceChildren();
    PRESETS.forEach(p=>{
      const btn=document.createElement('button');btn.type='button';btn.className='design-item'+(p.id===state.preset?' chosen':'');btn.setAttribute('aria-pressed',p.id===state.preset?'true':'false');
      const art=document.createElement('div');art.className='design-art';art.style.cssText='background:'+p.bg+';color:'+p.ink+';border-color:'+p.accent;
      const bar=document.createElement('div');bar.className='design-bar';bar.style.background=p.accent;
      const head=document.createElement('div');head.className='design-head';head.style.background=p.ink;
      const blocks=document.createElement('div');blocks.className='design-blocks';
      [0,1,2].forEach((_,i)=>{const b=document.createElement('span');b.style.background=i===2?p.accent2:p.paper;blocks.append(b);});
      art.append(bar,head,blocks);
      const label=document.createElement('strong');label.textContent=p.name;const desc=document.createElement('small');desc.textContent=p.desc;
      btn.append(art,label,desc);btn.onclick=()=>{if(state.preset===p.id)return;snapshot();state.preset=p.id;buildGallery();renderPreview();status('デザイン「'+p.name+'」を適用しました');};host.append(btn);
    });
  }
  function splitContent(raw,count){
    const lines=raw.split(/\r?\n/).map(s=>s.trim()).filter(Boolean);
    const sentences=(lines.length>1?lines:raw.split(/(?<=[。！？!?])\s*/)).map(s=>s.trim()).filter(Boolean);
    const chunks=[];for(let i=0;i<count;i++){const begin=Math.floor(i*sentences.length/count),end=Math.floor((i+1)*sentences.length/count);chunks.push(sentences.slice(begin,end));}
    return chunks.map((part,i)=>{
      const first=text(part[0]||'主なポイント',110),heading=first.replace(/^[-・●\d.)\s]+/,'').slice(0,34)||'主なポイント';
      const rest=part.slice(1);const bullets=(rest.length?rest:[first]).map(s=>'・'+s.replace(/^[-・●\d.)\s]+/,'').slice(0,85));
      return page({kicker:i===0?'OVERVIEW':i===count-1?'TAKEAWAY':'KEY POINT '+pad(i+1),title:i===0?(text(lines[0]||heading,56)):(i===count-1?'まとめ：'+heading:heading),body:bullets.join('\n'),footer:'出典・数値は元の資料で要確認'});
    });
  }
  function localGenerate(){
    const src=$('source').value.trim();if(!src){status('元になる文章を入力してください',true);return;}
    const count=Math.max(1,Math.min(MAX_PAGES,Number($('pageCount').value)||4));
    snapshot();state.pages=splitContent(src,count);state.index=0;state.images={};renderAll();status(count+'ページを構成しました。各ページを編集してから書き出せます。');
  }
  async function aiGenerate(){
    const key=$('apiKey').value.trim(),src=$('source').value.trim();
    if(!src){status('元になる文章を入力してください',true);return;}
    if(!key){status('AI構成にはGemini APIキーが必要です。キーなしの場合はローカル構成を利用してください。',true);return;}
    if(!confirm('入力した文章をGoogle Gemini APIに送信して構成を作ります。続行しますか？'))return;
    const count=Math.max(1,Math.min(MAX_PAGES,Number($('pageCount').value)||4));
    $('aiBtn').disabled=true;status('Geminiで各ページの構成を作成しています…');
    try {
      const req={contents:[{role:'user',parts:[{text:'あなたは日本語のスライド編集者です。以下の文章のみを根拠に、厳密に'+count+'ページの図解スライドを構成してください。架空のデータや出典を作らない。各ページはタイトルと最大5項目の短い本文を持ち、前後の情報を重複させない。タイトルは32字以内、bodyは各行を「・」で始め、最大5行。出力JSONは {"pages":[{"kicker":"...","title":"...","body":"...","footer":"..."}]} のみ。\n\n元の文章:\n'+src}]}],generationConfig:{temperature:0.45,responseMimeType:'application/json'}};
      const res=await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',{method:'POST',headers:{'Content-Type':'application/json','x-goog-api-key':key},body:JSON.stringify(req)});
      if(!res.ok){const error=await res.text();throw Error('API '+res.status+'：'+error.slice(0,160));}
      const data=await res.json(),s=data.candidates?.[0]?.content?.parts?.map(p=>p.text||'').join('')||'';
      const parsed=JSON.parse(s),arr=parsed.pages;
      if(!Array.isArray(arr)||arr.length!==count)throw Error('AIから'+count+'ページの構造化データを取得できませんでした');
      snapshot();state.pages=arr.map(page);state.index=0;state.images={};renderAll();status('AI構成を反映しました。画像は端末内のCanvasで描画されます。');
    }catch(err){status('AI構成に失敗：'+String(err.message||err),true);}
    finally{$('aiBtn').disabled=false;}
  }
  async function generatePageIllustration(){
    const i=state.index,p=state.pages[i],key=$('apiKey').value.trim;
    if(!p){status('先にページを作成してください',true);return;}
    if(!key){status('画像AIにはGemini APIキーが必要です',true);return;}
    if(!confirm('現在のページの見出しと本文をGemini画像生成APIに送信して、挿絵を1枚作成します。画像生成には料金が発生する場合があります。続行しますか？'))return;
    const btn=$('generateImageBtn');btn.disabled=true;status('P'+(i+1)+'の挿絵をGeminiで生成中…');
    try{
      const prompt='Create one high-quality professional editorial illustration for a Japanese presentation slide. Visualize this topic: '+p.title+'. Context: '+p.body+'. NO text, NO letters, NO numbers, NO logos, NO typography, NO watermark added by prompt. Compose as a clean standalone image with one unified scene, not a collage or presentation slide. Leave visual space around the subject. Style: '+preset().name+'.';
      const payload={contents:[{role:'user',parts:[{text:prompt}]}],generationConfig:{responseModalities:['IMAGE'],responseFormat:{image:{aspectRatio:state.format==='portrait'?'3:4':'16:9'}}}};
      const res=await fetch('https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-image:generateContent',{method:'POST',headers:{'Content-Type':'application/json','x-goog-api-key':key},body:JSON.stringify(payload)});
      if(!res.ok)throw Error('API '+res.status+'：'+(await res.text()).slice(0,150));
      const data=await res.json(),part=data.candidates?.[0]?.content?.parts?.find(x=>x.inlineData?.data);
      if(!part)throw Error('画像データが返されませんでした');
      const mime=part.inlineData.mimeType||'image/png';if(!/^image\/(png|jpeg|webp)$/i.test(mime))throw Error('未対応の画像形式');
      const binary=atob(part.inlineData.data);if(binary.length>16*1024*1024)throw Error('画像サイズが大きすぎます');
      const bytes=Uint8Array.from(binary,c=>c.charCodeAt(0));
      const url=URL.createObjectURL(new Blob([bytes],{type:mime}));const img=new Image();
      await new Promise((resolve,reject)=>{img.onload=resolve;img.onerror=()=>reject(Error('画像読み込みに失敗'));img.src=url;});
      URL.revokeObjectURL(url);
      state.images[i]=img;
      if(state.index===i)renderPreview();
      status('P'+(i+1)+'の挿絵を生成・配置しました。文字は引き続き編集できます。');
    }catch(e){status('画像AIの処理に失敗：'+String(e.message||e),true);}
    finally{btn.disabled=false;}
  }
  function renderTabs(){
    const host=$('pageTabs');host.replaceChildren();
    state.pages.forEach((p,i)=>{const b=document.createElement('button');b.type='button';b.className='page-tab'+(state.index===i?' active':'');b.textContent='P'+pad(i+1)+' '+p.title.slice(0,10);b.setAttribute('aria-current',state.index===i?'page':'false');b.onclick=()=>{state.index=i;renderTabs();renderEditor();renderPreview();};host.append(b);});
    $('counter').textContent=state.pages.length+' / '+MAX_PAGES+'ページ';
  }
  function renderEditor(){const p=state.pages[state.index];$('editor').hidden=!p;$('empty').hidden=!!p;if(!p)return;['kicker','title','body','footer'].forEach(k=>{$('edit_'+k).value=p[k]||'';});}
  function syncEditor(){
    if(!state.pages.length)return;
    const p=state.pages[state.index];['kicker','title','body','footer'].forEach(k=>{p[k]=text($('edit_'+k).value,k==='body'?680:k==='title'?100:60);});
    renderTabs();schedulePreview();
  }
  let raf=0;function schedulePreview(){if(raf)cancelAnimationFrame(raf);raf=requestAnimationFrame(()=>{raf=0;renderPreview();});}
  function rounded(ctx,x,y,w,h,r){ctx.beginPath();ctx.roundRect(x,y,w,h,r);}
  function wrap(ctx,str,width){const lines=[];let row='';for(const ch of String(str)){if(ch==='\n'){lines.push(row);row='';continue;}if(ctx.measureText(row+ch).width>width&&row){lines.push(row);row=ch;}else row+=ch;}if(row)lines.push(row);return lines;}
  function fit(ctx,s,maxWidth,maxLines,start){for(let size=start;size>=20;size-=2){ctx.font='bold '+size+'px "Noto Sans JP", sans-serif';if(wrap(ctx,s,maxWidth).length<=maxLines)return size;}return 20;}
  function paintSlide(canvas,p,index,total,img){
    const [W,H]=dimensions();canvas.width=W;canvas.height=H;
    const ctx=canvas.getContext('2d',{alpha:false});const scale=W/1000,ht=H/scale;
    ctx.setTransform(scale,0,0,scale,0,0);const d=preset(),portrait=state.format==='portrait',errors=[];
    ctx.fillStyle=d.bg;ctx.fillRect(0,0,1000,ht);
    ctx.globalAlpha=.1;ctx.fillStyle=d.accent;ctx.beginPath();ctx.arc(960,75,250,0,2*Math.PI);ctx.fill();ctx.globalAlpha=1;
    ctx.fillStyle=d.accent;ctx.fillRect(65,62,74,8);
    if(d.layout==='editorial'){ctx.globalAlpha=.55;ctx.fillRect(65,132,870,2);ctx.globalAlpha=1;}
    if(d.layout==='split'){ctx.globalAlpha=.2;ctx.fillRect(0,0,19,ht);ctx.fillStyle=d.accent2;ctx.fillRect(19,0,10,ht);ctx.globalAlpha=1;}
    if(d.layout==='poster'){ctx.globalAlpha=.11;ctx.fillStyle=d.accent2;ctx.font='bold 260px sans-serif';ctx.textAlign='right';ctx.fillText(pad(index+1),980,Math.min(ht-65,405));ctx.textAlign='left';ctx.globalAlpha=1;}

    ctx.fillStyle=d.ink;ctx.font='600 17px sans-serif';ctx.fillText(p.kicker||'KEY POINT',65,112);
    ctx.textAlign='right';ctx.globalAlpha=.7;ctx.font='600 18px sans-serif';ctx.fillText(pad(index+1)+' / '+pad(total),935,110);ctx.textAlign='left';ctx.globalAlpha=1;
    const titleY=portrait?195:177, titleW=870,titleSize=fit(ctx,p.title,titleW,portrait?4:2,portrait?72:62);
    ctx.font='bold '+titleSize+'px "Noto Sans JP",sans-serif';ctx.fillStyle=d.ink;
    const titleLines=wrap(ctx,p.title,titleW),titleStep=titleSize*1.34;
    titleLines.slice(0,portrait?4:2).forEach((line,i)=>ctx.fillText(line,65,titleY+i*titleStep));
    if(titleLines.length>(portrait?4:2))errors.push('タイトルが長すぎます');
    const titleBottom=titleY+Math.min(titleLines.length,portrait?4:2)*titleStep;
    const contentY=Math.max(portrait?375:285,titleBottom+23),padB=portrait?(img?400:180):105,available=ht-contentY-padB;
    if(available<120)errors.push('本文表示領域が不足');
    const colW=portrait?870:(img?520:870),textMax=colW-100;
    rounded(ctx,65,contentY,colW,Math.max(120,available),24);ctx.fillStyle=d.paper;ctx.fill();
    const bulletLines=p.body.split(/\n/).map(s=>s.trim()).filter(Boolean);
    const font=portrait?38:30,rowGap=portrait?14:8,top=contentY+45,limitY=contentY+available-22;let cursorY=top;
    ctx.fillStyle=d.ink;ctx.font='500 '+font+'px "Noto Sans JP",sans-serif';
    bulletLines.forEach((b,i)=>{
      const clean=b.replace(/^[・●•\-]\s*/,'');const sub=wrap(ctx,clean,textMax-20);
      ctx.fillStyle=d.accent;rounded(ctx,94,cursorY-5,11,11,5);ctx.fill();
      ctx.fillStyle=d.ink;
      sub.forEach((line,j)=>{if(cursorY+font>limitY){errors.push('本文が表示領域を超えています');return;}ctx.fillText(line,121,cursorY+font-6);cursorY+=font*1.4;});
      cursorY+=rowGap;
    });
    if(!bulletLines.length)errors.push('本文が未入力です');
    if(!portrait){
      if(img){const boxX=colW+83,boxW=935-boxX;rounded(ctx,boxX,contentY,boxW,available,24);ctx.save();ctx.clip();const iw=img.naturalWidth||img.width,ih=img.naturalHeight||img.height;const s=Math.max(boxW/iw,available/ih),dw=iw*s,dh=ih*s;ctx.drawImage(img,boxX+(boxW-dw)/2,contentY+(available-dh)/2,dw,dh);ctx.restore();}
      else if(d.layout!=='editorial'){ctx.globalAlpha=.65;ctx.strokeStyle=d.accent;ctx.lineWidth=2;ctx.beginPath();ctx.arc(866,contentY+available*.55,44,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=1;}
    }else if(img){
      const iy=contentY+available+22,ih=Math.min(250,ht-iy-90);if(ih>60){rounded(ctx,65,iy,870,ih,22);ctx.save();ctx.clip();const iw=img.naturalWidth||img.width, iH=img.naturalHeight||img.height,sc=Math.max(870/iw,ih/iH),dw=iw*sc,dh=iH*sc;ctx.drawImage(img,65+(870-dw)/2,iy+(ih-dh)/2,dw,dh);ctx.restore();}
    }
    ctx.fillStyle=d.ink;ctx.globalAlpha=.58;ctx.font='18px "Noto Sans JP",sans-serif';ctx.fillText(p.footer||'',65,ht-38);ctx.globalAlpha=1;
    if(!p.title.trim())errors.push('タイトルが未入力');
    if(p.body.length>600)errors.push('本文が長すぎます');
    return [...new Set(errors)];
  }
  function renderPreview(){const p=state.pages[state.index];if(!p)return;const errors=paintSlide($('preview'),p,state.index,state.pages.length,state.images[state.index]);const qa=$('qa');qa.textContent=errors.length?'品質チェック：'+errors.join('・'):'品質チェック：文字量・入力の基本検査 OK';qa.classList.toggle('warn',!!errors.length);}
  function renderAll(){$('preview').hidden=!state.pages.length;renderTabs();renderEditor();renderPreview();$('downloadBtn').disabled=!state.pages.length;$('zipBtn').disabled=!state.pages.length;$('jsonBtn').disabled=!state.pages.length;}
  function qualityScan(){
    const problems=[];const seen=new Set();for(let i=0;i<state.pages.length;i++){
      const p=state.pages[i];if(seen.has(p.title.trim()))problems.push('P'+(i+1)+'：タイトル重複');seen.add(p.title.trim());
      const c=document.createElement('canvas'),err=paintSlide(c,p,i,state.pages.length,state.images[i]);err.forEach(e=>problems.push('P'+(i+1)+'：'+e));
    }return problems;
  }
  async function canvasToPNG(i){const c=document.createElement('canvas');paintSlide(c,state.pages[i],i,state.pages.length,state.images[i]);return await new Promise((resolve,reject)=>c.toBlob(b=>b?resolve(b):reject(Error('PNG生成に失敗')),'image/png'));}
  function download(blob,name){const u=URL.createObjectURL(blob),a=document.createElement('a');a.href=u;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),30000);}
  async function downloadOne(){if(!state.pages.length)return;try{const i=state.index;const blob=await canvasToPNG(i);download(blob,'AI-Kobo-P'+pad(i+1)+'.png');status('P'+(i+1)+'を独立したPNGとして書き出しました');}catch(e){status(String(e),true);}}
  const crcTable=Array.from({length:256},(_,i)=>{let c=i;for(let j=0;j<8;j++)c=c&1?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
  function crc32(bytes){let c=0xffffffff;for(const b of bytes)c=crcTable[(c^b)&255]^(c>>>8);return (c^0xffffffff)>>>0;}
  function u16(a,n,v){a[n]=v&255;a[n+1]=(v>>>8)&255;}
  function u32(a,n,v){u16(a,n,v&65535);u16(a,n+2,(v>>>16)&65535);}
  function zipStore(files){
    const local=[],central=[];let offset=0;
    for(const f of files){
      const name=enc.encode(f.name),body=f.bytes,crc=crc32(body);
      const hdr=new Uint8Array(30+name.length);u32(hdr,0,0x04034b50);u16(hdr,4,20);u16(hdr,6,0x0800);u16(hdr,8,0);u32(hdr,14,crc);u32(hdr,18,body.length);u32(hdr,22,body.length);u16(hdr,26,name.length);hdr.set(name,30);local.push(hdr,body);
      const cen=new Uint8Array(46+name.length);u32(cen,0,0x02014b50);u16(cen,4,20);u16(cen,6,20);u16(cen,8,0x0800);u32(cen,16,crc);u32(cen,20,body.length);u32(cen,24,body.length);u16(cen,28,name.length);u32(cen,42,offset);cen.set(name,46);central.push(cen);offset+=hdr.length+body.length;
    }
    const cenLength=central.reduce((s,b)=>s+b.length,0),end=new Uint8Array(22);u32(end,0,0x06054b50);u16(end,8,files.length);u16(end,10,files.length);u32(end,12,cenLength);u32(end,16,offset);return new Blob([...local,...central,end],{type:'application/zip'});
  }
  async function downloadZIP(){
    if(state.busy||!state.pages.length)return;
    const problems=qualityScan();
    if(problems.length&&!confirm('品質チェックで以下が見つかりました。\n'+problems.slice(0,8).join('\n')+'\n\nこのまま出力しますか？'))return;
    state.busy=true;$('zipBtn').disabled=true;
    try{
      const files=[];
      for(let i=0;i<state.pages.length;i++){status('PNG '+(i+1)+' / '+state.pages.length+' を描画中…');const blob=await canvasToPNG(i);files.push({name:'slide-'+pad(i+1)+'.png',bytes:new Uint8Array(await blob.arrayBuffer())});}
      const manifest={app:'AI制作工房 図解スタジオ',version:CREATIVE_STUDIO_VERSION,format:state.format,preset:state.preset,oneImagePerPage:true,pages:state.pages};
      files.push({name:'project.json',bytes:enc.encode(JSON.stringify(manifest,null,2))});
      download(zipStore(files),'AI-Kobo-Slides-'+state.pages.length+'pages.zip');
      status(state.pages.length+'枚の独立画像と編集データをZIPへ保存しました');
    }catch(e){status('ZIPの作成に失敗：'+String(e.message||e),true);}
    finally{state.busy=false;$('zipBtn').disabled=false;}
  }
  function project(){return {version:CREATIVE_STUDIO_VERSION,preset:state.preset,format:state.format,pages:state.pages,source:$('source').value};}
  function saveProject(){if(!state.pages.length){status('先にページを作成してください',true);return;}try{localStorage.setItem(STORAGE,JSON.stringify(project()));status('この端末に保存しました。APIキーと画像素材は保存しません。');}catch(e){status('保存に失敗：端末の空き容量を確認してください',true);}}
  function applyProject(obj){if(!obj||!Array.isArray(obj.pages)||!obj.pages.length)throw Error('ページデータがありません');if(obj.pages.length>MAX_PAGES)throw Error('Lite版の上限は5ページです');snapshot();state.pages=obj.pages.map(page);state.preset=PRESETS.some(x=>x.id===obj.preset)?obj.preset:'navy';state.format=obj.format==='portrait'?'portrait':'landscape';state.index=0;state.images={};$('format').value=state.format;$('pageCount').value=String(state.pages.length);$('source').value=text(obj.source,20000);buildGallery();renderAll();}
  function downloadProject(){download(new Blob([JSON.stringify(project(),null,2)],{type:'application/json'}),'AI-Kobo-Project.json');status('編集可能なプロジェクトJSONを保存しました');}
  async function loadImage(file){if(!file)return;if(file.size>12*1024*1024){status('画像は12MB以内にしてください',true);return;}if(!file.type.startsWith('image/')){status('画像ファイルを選択してください',true);return;}const url=URL.createObjectURL(file),image=new Image();image.onload=()=>{URL.revokeObjectURL(url);state.images[state.index]=image;renderPreview();status('現在のページに写真を配置しました');};image.onerror=()=>{URL.revokeObjectURL(url);status('画像の読み込みに失敗しました',true);};image.src=url;}
  function wire(){
    $('localBtn').onclick=localGenerate;$('aiBtn').onclick=aiGenerate;$('generateImageBtn').onclick=generatePageIllustration;$('undoBtn').onclick=restore;$('downloadBtn').onclick=downloadOne;$('zipBtn').onclick=downloadZIP;$('saveBtn').onclick=saveProject;$('jsonBtn').onclick=downloadProject;
    $('format').onchange=()=>{snapshot();state.format=$('format').value;renderPreview();};
    ['kicker','title','body','footer'].forEach(k=>{const el=$('edit_'+k);el.addEventListener('focus',()=>{if(state.pages.length)snapshot();},{passive:true});el.addEventListener('input',syncEditor);});
    $('pageImage').onchange=e=>{loadImage(e.target.files?.[0]);e.target.value='';};
    $('clearImageBtn').onclick=()=>{delete state.images[state.index];renderPreview();};
    $('importBtn').onclick=()=>$('importFile').click();
    $('importFile').onchange=async(e)=>{try{const f=e.target.files?.[0];if(!f)return;if(f.size>1024*1024)throw Error('JSONは1MB以内にしてください');applyProject(JSON.parse(await f.text()));status('プロジェクトを読み込みました');}catch(err){status('読み込み失敗：'+String(err.message||err),true);}e.target.value='';};
    $('restoreBtn').onclick=()=>{try{const raw=localStorage.getItem(STORAGE);if(!raw)throw Error('保存されたプロジェクトがありません');applyProject(JSON.parse(raw));status('保存プロジェクトを復元しました');}catch(e){status(String(e.message||e),true);}};
    $('checkBtn').onclick=()=>{const problems=qualityScan();status(problems.length?problems.join(' ／ '):'全ページの基本検査 OK（事実関係・出典は別途確認してください）',!!problems.length);};
    $('sampleBtn').onclick=()=>{$('source').value='店舗の売上改善提案\n現状：平日夕方の来客が少ない。\nターゲット：仕事帰りの近隣住民。\n施策1：夕方限定セットメニューを導入する。\n施策2：LINE登録特典で再来店を促進する。\n施策3：SNS告知のクリエイティブを統一する。\nKPI：時間帯別客数、客単価、再来店率。\n注意：売上増加率は実測データから計算する。';$('pageCount').value='4';localGenerate();};
  }
  buildGallery();wire();renderAll();status('文章を入力し、デザインを選んで構成を作成してください。');
  window.CREATIVE_STUDIO_VERSION=CREATIVE_STUDIO_VERSION;
})();