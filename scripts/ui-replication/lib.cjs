// Shared helpers for driving a reference demo and the current app in one headless Chrome.
// Start Chrome once: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --remote-debugging-port=9333 --user-data-dir=$UIREP_DIR/chrome-profile --allow-file-access-from-files
// npm i puppeteer-core (in a scratch dir) and run scripts from there.
const puppeteer = require('puppeteer-core');
// UIREP_DIR: working dir for shots (default cwd); UIREP_DEMO: absolute path of the reference HTML; UIREP_APP: substring of the app tab's URL
const S = process.env.UIREP_DIR || process.cwd();
const DEMO = process.env.UIREP_DEMO ? 'file://' + encodeURI(process.env.UIREP_DEMO) : null;
async function connect() {
  const browser = await puppeteer.connect({ browserURL: 'http://127.0.0.1:9333', defaultViewport: { width: 1440, height: 900 } });
  let pages = await browser.pages();
  let page = pages.find(p => p.url().startsWith('file://')) || pages[0];
  await page.bringToFront();
  await page.setViewport({ width: 1440, height: 900 });
  return { browser, page };
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
// click a visible element by its exact/partial text
async function clickText(page, text, opts = {}) {
  const r = await page.evaluate((text, sel, exact) => {
    const els = [...document.querySelectorAll(sel)].filter(e => { const b = e.getBoundingClientRect(); return b.width > 0 && b.height > 0 && getComputedStyle(e).visibility !== 'hidden'; });
    const m = els.filter(e => exact ? (e.innerText || '').trim() === text : (e.innerText || '').includes(text));
    m.sort((a, b) => (a.innerText||'').length - (b.innerText||'').length);
    const e = m[0]; if (!e) return null; const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2, tag: e.tagName, t: (e.innerText||'').slice(0,40) };
  }, text, opts.sel || 'button,a,[role=button],div,span', !!opts.exact);
  if (!r) throw new Error('not found: ' + text);
  await page.mouse.click(r.x, r.y);
  return r;
}
module.exports = { connect, sleep, clickText, S, DEMO };
// Reach the demo's DC logic instance through the React fiber of any rendered node.
async function demoLogicEval(page, fnSrc, arg) {
  return page.evaluate((fnSrc, arg) => {
    function findLogic() {
      const el = document.querySelector('body *');
      const all = document.querySelectorAll('body *');
      for (const n of all) {
        const k = Object.keys(n).find(k => k.startsWith('__reactFiber$'));
        if (!k) continue;
        let f = n[k];
        while (f) { if (f.stateNode && f.stateNode.logic && f.stateNode.logic.state && 'screen' in f.stateNode.logic.state) return f.stateNode.logic; f = f.return; }
      }
      return null;
    }
    const L = findLogic(); if (!L) return 'NO_LOGIC';
    return (new Function('L', 'arg', fnSrc))(L, arg);
  }, fnSrc, arg);
}
async function demoSet(page, patch) { return demoLogicEval(page, 'L.setState(arg); return true;', patch); }
async function demoGet(page, keys) { return demoLogicEval(page, 'const o={}; for (const k of arg) o[k]=L.state[k]; return o;', keys); }
// Click a visible button/element whose textContent (tooltip span included) starts with label
async function clickLabel(page, label, opts = {}) {
  const r = await page.evaluate((label, sel, nth) => {
    const els = [...document.querySelectorAll(sel)].filter(e => { const b = e.getBoundingClientRect(); const cs = getComputedStyle(e); return b.width > 0 && b.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; });
    const m = els.filter(e => (e.textContent || '').trim().replace(/\s+/g, ' ').startsWith(label));
    const e = m[nth || 0]; if (!e) return null; const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2, w: b.width, h: b.height, n: m.length };
  }, label, opts.sel || 'button', opts.nth || 0);
  if (!r) throw new Error('label not found: ' + label);
  if (opts.hover) await page.mouse.move(r.x, r.y); else await page.mouse.click(r.x, r.y);
  return r;
}
module.exports.demoSet = demoSet; module.exports.demoGet = demoGet; module.exports.demoLogicEval = demoLogicEval; module.exports.clickLabel = clickLabel;
async function demoSnapshot(page) { return demoLogicEval(page, 'return JSON.parse(JSON.stringify(L.state, (k, v) => typeof v === "function" ? undefined : v));'); }
async function demoRestore(page, base) {
  return demoLogicEval(page, 'const p = Object.assign({}, arg); for (const k of Object.keys(L.state)) if (!(k in arg)) p[k] = undefined; L.setState(p); return true;', base);
}
module.exports.demoSnapshot = demoSnapshot; module.exports.demoRestore = demoRestore;
async function connectApp() {
  const browser = await puppeteer.connect({ browserURL: 'http://127.0.0.1:9333', protocolTimeout: 900000 });
  const pages = await browser.pages();
  const page = pages.find(p => p.url().includes(process.env.UIREP_APP || 'localhost:3002'));
  await page.bringToFront();
  await page.setViewport({ width: 1440, height: 900 });
  return { browser, page };
}
async function listButtons(page, yMin = 0, yMax = 9999) {
  return page.evaluate((yMin, yMax) => [...document.querySelectorAll('button,[role=button],[role=tab],select,input')].filter(b => { const r = b.getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.y >= yMin && r.y <= yMax && getComputedStyle(b).visibility !== 'hidden'; }).map(b => { const r = b.getBoundingClientRect(); return [Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height), b.tagName.toLowerCase(), (b.getAttribute('aria-label') || b.title || b.placeholder || (b.innerText || '').trim()).replace(/\n/g, ' | ').slice(0, 50)].join(' '); }), yMin, yMax);
}
module.exports.connectApp = connectApp; module.exports.listButtons = listButtons;
async function clickAria(page, label, opts = {}) {
  const r = await page.evaluate((label, nth, prefix, sel) => {
    const els = [...document.querySelectorAll(sel || '[aria-label],[title]')].filter(e => { const b = e.getBoundingClientRect(); const cs = getComputedStyle(e); return b.width > 0 && b.height > 0 && b.x >= 0 && b.y >= 0 && b.y < innerHeight && cs.visibility !== 'hidden'; });
    const name = e => e.getAttribute('aria-label') || e.getAttribute('title') || (e.innerText || '').trim();
    const m = els.filter(e => prefix ? name(e).startsWith(label) : name(e) === label);
    const e = m[nth || 0]; if (!e) return null; const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2, n: m.length };
  }, label, opts.nth || 0, !!opts.prefix, opts.sel || null);
  if (!r) throw new Error('aria not found: ' + label);
  if (opts.hover) await page.mouse.move(r.x, r.y); else await page.mouse.click(r.x, r.y);
  return r;
}
async function appClean(page) {
  await page.evaluate(() => { for (const b of [...document.querySelectorAll('button')].filter(b => b.innerText.trim() === 'Necessary')) { let n = b; for (let i = 0; i < 6 && n.parentElement; i++) { n = n.parentElement; if (getComputedStyle(n).position === 'fixed') { n.remove(); break; } } } document.querySelectorAll('nextjs-portal').forEach(n => n.remove()); window.getSelection()?.removeAllRanges(); });
}
module.exports.clickAria = clickAria; module.exports.appClean = appClean;
