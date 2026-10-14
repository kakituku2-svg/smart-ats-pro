/* Browser smoke test for AI制作工房 図解スタジオ. No real API key or network inference calls. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { execFileSync } = require('node:child_process');
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({headless:true,args:['--no-sandbox']});
  const page = await browser.newPage({viewport:{width:1280,height:850},acceptDownloads:true});
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('dialog', d => d.accept());
  await page.goto('http://127.0.0.1:8765/keirin-race-gate/ai-seisaku-kobo/creative-studio.html',{waitUntil:'load'});
  await page.waitForFunction(() => Boolean(window.CREATIVE_STUDIO_VERSION));
  assert.equal(await page.locator('.design-item').count(),8,'8 presets exist');
  assert.match(await page.locator('#status').textContent(),/文章を入力/);
  await page.locator('#sampleBtn').click();
  assert.equal(await page.locator('.page-tab').count(),4,'4 independent pages');
  assert.equal(await page.locator('#preview').getAttribute('width'),'1600');
  assert.ok(await page.locator('#preview').isVisible());
  await page.locator('.design-item').nth(3).click();
  assert.ok((await page.locator('.design-item').nth(3).getAttribute('class')).includes('chosen'));
  await page.locator('.page-tab').nth(1).click();
  await page.locator('#edit_title').fill('ページ2の編集テスト');
  assert.match(await page.locator('.page-tab').nth(1).textContent(),/ページ2/);
  const single = page.waitForEvent('download');
  await page.locator('#downloadBtn').click();
  const png = await single;
  assert.equal(png.suggestedFilename(),'AI-Kobo-P02.png');
  const bytes = fs.readFileSync(await png.path());
  assert.equal(bytes.subarray(0,8).toString('hex'),'89504e470d0a1a0a','PNG magic number');
  const zipped = page.waitForEvent('download');
  await page.locator('#zipBtn').click();
  const zip = await zipped;
  const listing = execFileSync('unzip',['-Z','-1',await zip.path()],{encoding:'utf8'}).trim().split(/\r?\n/);
  assert.equal(listing.filter(x=>x.endsWith('.png')).length,4,'one image per page');
  assert.ok(listing.includes('project.json'),'include editable data');
  await page.locator('#apiKey').fill('SENSITIVE_FAKE_KEY_DO_NOT_STORE');
  await page.locator('#saveBtn').click();
  const stored=await page.evaluate(()=>localStorage.getItem('ai_kobo_creative_studio_v260'));
  assert.ok(stored.includes('ページ2の編集テスト'));
  assert.ok(!stored.includes('SENSITIVE_FAKE_KEY_DO_NOT_STORE'),'do not persist API key');
  // Mock the external Gemini endpoint to exercise AI structure, image creation and localized edit without charges.
  await page.evaluate(() => {
    const original = window.fetch.bind(window);
    const c=document.createElement('canvas');c.width=8;c.height=8;
    const x=c.getContext('2d');x.fillStyle='#abcabc';x.fillRect(0,0,8,8);
    const base64=c.toDataURL('image/png').split(',')[1];
    window.fetch=async(url,opts)=>{
      if(String(url).includes('generativelanguage.googleapis.com')){
        let response;
        if(String(url).includes('flash-image')){
          response={candidates:[{content:{parts:[{inlineData:{mimeType:'image/png',data:base64}}]}}]};
        }else{
          const n=4;
          response={candidates:[{content:{parts:[{text:JSON.stringify({pages:Array.from({length:n},(_,i)=>({kicker:'AI',title:'AIページ'+(i+1),body:'・要点を確認する',footer:'出典は要確認'}))})}]}}]};
        }
        return new Response(JSON.stringify(response),{status:200,headers:{'Content-Type':'application/json'}});
      }
      return original(url,opts);
    };
  });
  await page.locator('#aiBtn').click();
  await page.waitForFunction(() => document.querySelector('#status').textContent.includes('AI構成を反映しました'));
  assert.equal(await page.locator('.page-tab').count(),4);
  await page.locator('#generateImageBtn').click();
  await page.waitForFunction(() => document.querySelector('#status').textContent.includes('挿絵を生成・配置しました'));
  await page.locator('#imageEditInstruction').fill('人物の服を青に変更');
  await page.locator('#editImageBtn').click();
  await page.waitForFunction(() => document.querySelector('#status').textContent.includes('挿絵を修正しました'));
  assert.equal(await page.locator('#edit_title').inputValue(),'AIページ1','text is unchanged after image edit');
  await page.locator('#format').selectOption('portrait');
  assert.equal(await page.locator('#preview').getAttribute('width'),'1080');
  assert.equal(await page.locator('#preview').getAttribute('height'),'1440');
  await page.setViewportSize({width:390,height:844});
  assert.ok(await page.locator('#preview').isVisible(),'mobile portrait preview');
  assert.deepEqual(errors,[], 'no uncaught JS errors');
  await browser.close();
  console.log('CREATIVE_STUDIO_SMOKE_PASS: presets, pages, edit, PNG, ZIP, key privacy, mocked AI edit, portrait, mobile');
})().catch(e=>{console.error(e);process.exit(1);});