const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.join(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');

test('landing page contains real Rattil identity and direct release links', () => {
  const html = read('index.html');
  assert.match(html, /lang="en"/);
  assert.match(html, /rattil_mark_green\.svg/);
  assert.match(html, /rel="icon"/);
  assert.match(html, /name="description"/);
  assert.match(html, /property="og:title"/);
  assert.match(html, /property="og:image" content="https:\/\/raw\.githubusercontent\.com\/zarsalene\/Quran_AI_app\/main\/assets\/brand\/rattil_icon\.svg"/);
  assert.equal((html.match(/releases\/latest\/download\/Rattil\.apk/g) || []).length, 4);
  assert.match(html, /privacy\.html/);
  assert.match(html, /https:\/\/github\.com\/zarsalene\/Quran_AI_app/);
});

test('all three locales render complete localized feature and CTA content, with RTL Arabic', () => {
  const locale = { en: 'Your journey with the Quran starts here.', fr: 'Votre chemin avec le Coran commence ici.', ar: 'رحلتك مع القرآن تبدأ من هنا.' };
  const app = read('app.js');
  for (const [code, headline] of Object.entries(locale)) {
    assert.match(app, new RegExp(`\\n  ${code}: \\{`));
    assert.ok(app.includes(headline));
  }
  for (const key of ['Read the Quran', 'Listen and follow along', 'Practise with the voice teacher', 'Memorize with Hifz', 'See your progress']) assert.ok(app.includes(key));
  assert.match(app, /document\.documentElement\.dir = lang === 'ar' \? 'rtl' : 'ltr'/);
  assert.match(app, /rattil-site-language/);
  assert.match(read('styles.css'), /html\[dir="rtl"\]/);
});

test('language selector changes rendered copy, document direction, and all download targets', () => {
  const html = read('index.html');
  const elements = new Map();
  const byId = id => { if (!elements.has(id)) elements.set(id, { id, dataset: {}, attrs: {}, setAttribute(k, v) { this.attrs[k] = v; } }); return elements.get(id); };
  const translated = [...html.matchAll(/<[^>]*data-i18n="([^"]+)"[^>]*>/g)].map(([, key]) => ({ dataset: { i18n: key }, textContent: '' }));
  const downloads = [...html.matchAll(/<a\b[^>]*data-download[^>]*>/g)].map(() => ({ href: '', attrs: {}, setAttribute(k, v) { this.attrs[k] = v; } }));
  const language = byId('language');
  const listeners = {};
  const document = {
    documentElement: { lang: '', dir: '' },
    querySelector(selector) {
      if (selector === '#language') return language;
      if (selector === '#year') return byId('year');
      if (selector === '#feature-grid') return byId('feature-grid');
      if (selector === '#values-list') return byId('values-list');
      if (selector === '#install-steps') return byId('install-steps');
      if (selector === '.footer-links a:nth-child(2)') return byId('repo');
      if (selector === '.desktop-nav') return byId('desktop-nav');
      throw new Error(`Unexpected selector: ${selector}`);
    },
    querySelectorAll(selector) { return selector === '[data-i18n]' ? translated : selector === '[data-download]' ? downloads : []; },
  };
  language.addEventListener = (name, fn) => { listeners[name] = fn; };
  const storage = new Map();
  const context = { document, navigator: { languages: ['en-US'] }, localStorage: { getItem: key => storage.get(key) || null, setItem: (key, value) => storage.set(key, value) }, console };
  vm.runInNewContext(read('app.js'), context);
  assert.equal(document.documentElement.lang, 'en');
  language.value = 'ar';
  listeners.change();
  assert.equal(document.documentElement.lang, 'ar');
  assert.equal(document.documentElement.dir, 'rtl');
  assert.ok(byId('feature-grid').innerHTML.includes('اقرأ القرآن'));
  assert.equal(downloads.length, 4);
  for (const link of downloads) {
    assert.equal(link.href, 'https://github.com/zarsalene/Quran_AI_app/releases/latest/download/Rattil.apk');
    assert.equal(link.attrs.download, 'Rattil.apk');
  }
  assert.equal(storage.get('rattil-site-language'), 'ar');
});

test('every download control is wired to the requested latest APK asset', () => {
  const html = read('index.html'), js = read('app.js');
  assert.equal((html.match(/data-download/g) || []).length, 4);
  assert.match(html, /releases\/latest\/download\/Rattil\.apk/);
  assert.match(js, /const APK_URL = 'https:\/\/github\.com\/zarsalene\/Quran_AI_app\/releases\/latest\/download\/Rattil\.apk'/);
  assert.match(js, /el\.setAttribute\('download','Rattil\.apk'\)/);
});

test('privacy policy covers local voice processing, website storage, and external hosts', () => {
  const html = read('privacy.html'), js = read('privacy.js');
  assert.match(html, /id="policy-content"/);
  for (const term of ['local storage', 'microphone', 'IP address', 'GitHub', 'analytics']) assert.ok(js.toLowerCase().includes(term.toLowerCase()));
  for (const code of ['en', 'fr', 'ar']) assert.match(js, new RegExp(`^  ${code}:`, 'm'));
  assert.match(html, /href="styles\.css"/);
});

test('static hosting includes responsive styles, visible keyboard focus, and local brand fonts', () => {
  const css = read('styles.css');
  assert.match(css, /@media\(max-width:650px\)/);
  assert.match(css, /focus-visible/);
  assert.match(css, /prefers-reduced-motion/);
  assert.match(css, /assets\/fonts\/IBMPlexSansArabic-Regular\.ttf/);
  for (const file of ['assets/brand/rattil_mark_green.svg', 'assets/brand/rattil_mark_white.svg', 'assets/brand/rattil_icon.svg', 'assets/fonts/IBMPlexSansArabic-Regular.ttf', 'assets/fonts/AmiriQuran-Regular.ttf']) {
    assert.ok(fs.statSync(path.join(root, file)).size > 0, `${file} should exist`);
  }
  assert.doesNotMatch(read('index.html'), /fonts\.googleapis\.com|fonts\.gstatic\.com/);
});
