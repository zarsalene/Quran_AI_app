const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(__dirname,'..');
const read = file => fs.readFileSync(path.join(root,file),'utf8');

test('app shell links the mobile app, manifest, styles, and runtime',()=>{
  const html=read('index.html');
  assert.match(html,/name="viewport"/);
  assert.match(html,/rel="manifest" href="manifest\.webmanifest"/);
  assert.match(html,/href="styles\.css"/);
  assert.match(html,/src="app\.js"/);
});

test('the Quran verse and bundled recitation are attributed and available locally',()=>{
  const js=read('app.js');
  assert.match(js,/بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ/);
  assert.match(js,/Tanzil Project, Uthmani, Hafs/);
  assert.match(js,/cannot yet transcribe Arabic or assess pronunciation or Tajweed/);
  assert.match(js,/assets\/audio\/alafasy-001001\.mp3/);
  assert.match(js,/Mishary Rashid Alafasy/);
  assert.match(js,/Bundled for offline use/);
});

test('all five navigation destinations and three interface locales are present',()=>{
  const html=read('index.html'),js=read('app.js');
  for(const page of ['home','read','practice','learn','progress']) assert.match(html,new RegExp(`data-page="${page}"`));
  for(const locale of ['en','fr','ar']) assert.match(js,new RegExp(`^  ${locale}:`, 'm'));
});

test('recording persistence is opt-in and audio stays in local browser storage',()=>{
  const js=read('app.js');
  assert.match(js,/id="saveAudioCheck"/);
  assert.match(js,/indexedDB\.open\('iqra-private'/);
  assert.match(js,/Recordings are never uploaded by this prototype/);
});

test('recitation is a bundled audio file with source and rights attribution',()=>{
  const html=read('index.html'),js=read('app.js'),attribution=read('assets/audio/ATTRIBUTION.md');
  const audio=fs.statSync(path.join(root,'assets/audio/alafasy-001001.mp3'));
  assert.ok(audio.size>10000);
  assert.match(js,/assets\/audio\/alafasy-001001\.mp3/);
  assert.match(attribution,/Mishary Rashid Alafasy/);
  assert.doesNotMatch(html,/fonts\.googleapis\.com|fonts\.gstatic\.com/);
  assert.doesNotMatch(js,/cdn\.islamic\.network\/quran\/audio/);
});

test('service worker caches the app shell and recitation for offline reopening',()=>{
  const sw=read('sw.js');
  assert.match(sw,/caches\.open\(CACHE\)/);
  assert.match(sw,/cache\.addAll\(CORE\)/);
  assert.match(sw,/caches\.match\(event\.request\)/);
  assert.match(sw,/assets\/audio\/alafasy-001001\.mp3/);
});
