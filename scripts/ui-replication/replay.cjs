// Replay interactions.json against a running editor.
// usage: node replay.cjs <interactions.json> <fixture.json> <out.json> [idRegex]
// fixture.json: { "url": "...", "cdp": "http://127.0.0.1:9333", "vars": { "videoClip": "...", ... }, "reloadEvery": 12 }
// Needs puppeteer-core resolvable from the cwd (run it from a dir with node_modules/puppeteer-core).
const fs = require('fs');
const puppeteer = require(require.resolve('puppeteer-core', { paths: [process.cwd()] }));
const [file, fixFile, outFile, only] = process.argv.slice(2);
const spec = JSON.parse(fs.readFileSync(file, 'utf8'));
const fx = JSON.parse(fs.readFileSync(fixFile, 'utf8'));
const sleep = ms => new Promise(r => setTimeout(r, ms));

function fill(t) {
  if (!t || typeof t !== 'object') return t;
  const missing = [];
  const s = JSON.stringify(t).replace(/\{(\w+)\}/g, (m, k) => { if (k in (fx.vars || {})) return fx.vars[k]; missing.push(k); return m; });
  return { value: JSON.parse(s), missing };
}

// Runs in the page: resolve {role,name,exact,within,modal} to visible elements.
const RESOLVER = `
window.__rp = (() => {
  const ROLE = { button: 'button,[role=button],summary', textbox: 'input:not([type]),input[type=text],textarea,[role=textbox]', searchbox: 'input[type=search],[role=searchbox],input[placeholder]',
    slider: 'input[type=range],[role=slider]', spinbutton: 'input[type=number],[role=spinbutton]', checkbox: 'input[type=checkbox],[role=checkbox]', radio: 'input[type=radio],[role=radio]',
    combobox: 'select,[role=combobox]', region: 'section[aria-label],aside[aria-label],[role=region]', navigation: 'nav,[role=navigation]', toolbar: '[role=toolbar]',
    heading: 'h1,h2,h3,h4,h5,h6,[role=heading]', menu: '[role=menu]', menuitem: '[role=menuitem]', menuitemradio: '[role=menuitemradio]', listbox: '[role=listbox]', option: '[role=option]',
    tab: '[role=tab]', dialog: '[role=dialog],dialog', status: '[role=status],output', tooltip: '[role=tooltip]', timer: '[role=timer]', separator: '[role=separator]', group: '[role=group],fieldset',
    listitem: 'li,[role=listitem]', row: '[role=row],tr', img: 'img,[role=img]', paragraph: 'p', text: 'span,div,p,label,td,li,button' };
  const vis = e => { const b = e.getBoundingClientRect(); const c = getComputedStyle(e); return b.width > 0 && b.height > 0 && b.bottom > 0 && b.right > 0 && b.top < innerHeight && b.left < innerWidth && c.visibility !== 'hidden' && c.display !== 'none' && c.opacity !== '0'; };
  const name = e => { const l = e.getAttribute('aria-label'); if (l) return l.trim();
    const lb = e.getAttribute('aria-labelledby'); if (lb) return lb.split(/\\s+/).map(id => (document.getElementById(id) || {}).innerText || '').join(' ').trim();
    if (e.title) return e.title.trim(); if (e.placeholder) return e.placeholder.trim(); if (e.alt) return e.alt.trim(); return (e.innerText || e.textContent || '').trim().replace(/\\s+/g, ' '); };
  const match = (n, want, exact) => want === '*' || (exact === false ? n.includes(want) : n === want);
  function find(t, scope) {
    let root = [document];
    if (t.within) { root = [...document.querySelectorAll('[aria-label]')].filter(e => match(e.getAttribute('aria-label').trim(), t.within, true) && vis(e)); if (!root.length) root = [...document.querySelectorAll('*')].filter(e => vis(e) && e.children.length && name(e) === t.within); if (!root.length) return { err: 'scope not found: ' + t.within }; }
    const sel = ROLE[t.role] || '*'; const out = [];
    for (const r of root) for (const e of r.querySelectorAll(sel)) {
      if (!vis(e)) continue; const n = name(e);
      if (t.role === 'text' && e.children.length && [...e.children].some(c => name(c) === n)) continue;
      if (!match(n, t.name, t.exact)) continue;
      if (t.modal === true && e.getAttribute('aria-modal') !== 'true') continue;
      out.push(e);
    }
    return { els: out };
  }
  return { find, name, vis };
})();`;

async function resolve(page, t) {
  return page.evaluateHandle((t) => { const r = window.__rp.find(t); return r.err ? r.err : r.els; }, t);
}
async function boxes(page, t) {
  return page.evaluate((t) => { const r = window.__rp.find(t); if (r.err) return { err: r.err }; return { list: r.els.map(e => { const b = e.getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: b.height, text: (e.innerText || '').trim(), attrs: Object.fromEntries([...e.attributes].map(a => [a.name, a.value])), css: (() => { const c = getComputedStyle(e); const o = {}; for (const k of ['background-color', 'border-radius', 'font-family', 'font-size', 'text-transform', 'letter-spacing', 'height', 'width', 'cursor', 'padding', 'aspect-ratio']) o[k] = c.getPropertyValue(k); return o; })(), scrollW: e.scrollWidth, clientW: e.clientWidth }; }) }; }, t);
}
const desc = t => `${t.role}:${t.name}${t.within ? ' in ' + t.within : ''}`;

let acted = false;
async function step(page, s) {
  if (s.do === 'key') { acted = true; const parts = s.key.split('+'); const k = parts.pop(); for (const m of parts) await page.keyboard.down(m === 'Mod' ? 'Meta' : m); await page.keyboard.press(k === '?' ? 'Slash' : k); for (const m of parts.reverse()) await page.keyboard.up(m === 'Mod' ? 'Meta' : m); await sleep(300); return; }
  const r = await boxes(page, s.on); if (r.err) throw new Error(r.err); if (!r.list.length) throw new Error('step target not found: ' + desc(s.on));
  const b = r.list[0]; const x = b.x + b.w / 2, y = b.y + b.h / 2; acted = true;
  if (s.do === 'click') await page.mouse.click(x, y);
  else if (s.do === 'rightclick') await page.mouse.click(x, y, { button: 'right' });
  else if (s.do === 'hover') { await page.mouse.move(x, y); await sleep(700); }
  else if (s.do === 'drag') { await page.mouse.move(x, y); await page.mouse.down(); for (let i = 1; i <= 8; i++) { await page.mouse.move(x + (s.dx || 0) * i / 8, y + (s.dy || 0) * i / 8); await sleep(30); } await page.mouse.up(); }
  else if (s.do === 'type') { await page.mouse.click(x, y); await page.keyboard.type(s.text, { delay: 20 }); }
  await sleep(450);
}

async function check(page, a) {
  const one = async (t) => { const r = await boxes(page, t); if (r.err) return { fail: r.err }; if (!r.list.length) return { fail: 'not found: ' + desc(t) }; return { b: r.list[0], list: r.list }; };
  switch (a.assert) {
    case 'visible': { const r = await one(a.on); return r.fail || null; }
    case 'absent': { const r = await boxes(page, a.on); if (r.err) return null; return r.list.length ? `present: ${desc(a.on)}` : null; }
    case 'box': { const r = await one(a.on); if (r.fail) return r.fail; const bad = []; for (const k of ['x', 'y', 'w', 'h']) if (k in a && Math.abs(r.b[k] - a[k]) > a.tol) bad.push(`${k}=${Math.round(r.b[k])} want ${a[k]}±${a.tol}`); return bad.length ? bad.join(', ') : null; }
    case 'style': { const r = await one(a.on); if (r.fail) return r.fail; const bad = Object.entries(a.css).filter(([k, v]) => !(r.b.css[k] || '').replace(/"/g, '').startsWith(v)).map(([k, v]) => `${k}=${r.b.css[k]} want ${v}`); return bad.length ? bad.join(', ') : null; }
    case 'text': { const r = await one(a.on); if (r.fail) return r.fail; if ('equals' in a && r.b.text !== a.equals) return `text="${r.b.text.slice(0, 60)}" want "${a.equals}"`; if ('contains' in a && !r.list.some(x => x.text.includes(a.contains))) return `no text containing "${a.contains}"`; return null; }
    case 'notText': { const r = await one(a.on); if (r.fail) return r.fail; return r.b.text.includes(a.contains) ? `contains "${a.contains}"` : null; }
    case 'order': { const pos = []; for (const t of a.on) { const r = await one(t); if (r.fail) return r.fail; pos.push(a.axis === 'x' ? r.b.x : r.b.y); } for (let i = 1; i < pos.length; i++) if (pos[i] < pos[i - 1]) return `out of order at ${desc(a.on[i])}`; return null; }
    case 'count': { const r = await boxes(page, a.on); if (r.err) return r.err; const n = r.list.length; if ('equals' in a && n !== a.equals) return `count=${n} want ${a.equals}`; if ('min' in a && n < a.min) return `count=${n} want ≥${a.min}`; return null; }
    case 'attr': { const r = await one(a.on); if (r.fail) return r.fail; const bad = Object.entries(a.attr).filter(([k, v]) => r.b.attrs[k] !== v); return bad.length ? bad.map(([k, v]) => `${k}=${r.b.attrs[k]} want ${v}`).join(', ') : null; }
    case 'sameValue': { const r = await one(a.on), q = await one(a.ref); if (r.fail || q.fail) return r.fail || q.fail; return r.b.attrs[a.attr] === q.b.attrs[a.attr] ? null : `${a.attr} ${r.b.attrs[a.attr]} vs ${q.b.attrs[a.attr]}`; }
    case 'inside': case 'notInside': case 'below': case 'above': case 'sameRow': case 'alignedLeft': case 'adjacentBelow': {
      const r = await one(a.on), q = await one(a.ref); if (r.fail || q.fail) return r.fail || q.fail; const b = r.b, c = q.b, tol = a.tol ?? 2;
      const inside = b.x >= c.x - tol && b.y >= c.y - tol && b.x + b.w <= c.x + c.w + tol && b.y + b.h <= c.y + c.h + tol;
      const ok = { inside, notInside: !inside, below: b.y >= c.y + c.h - tol, above: b.y + b.h <= c.y + tol, sameRow: Math.abs((b.y + b.h / 2) - (c.y + c.h / 2)) <= 6, alignedLeft: Math.abs(b.x - c.x) <= tol, adjacentBelow: Math.abs(b.y - (c.y + c.h)) <= tol }[a.assert];
      return ok ? null : `${a.assert} failed (${Math.round(b.x)},${Math.round(b.y)},${Math.round(b.w)}x${Math.round(b.h)} vs ${Math.round(c.x)},${Math.round(c.y)},${Math.round(c.w)}x${Math.round(c.h)})`; }
    case 'zoomFits': { const r = await one(a.on); if (r.fail) return r.fail; return r.b.scrollW <= r.b.clientW + 1 ? null : `overflows ${r.b.scrollW} > ${r.b.clientW}`; }
  }
  return 'unknown assert ' + a.assert;
}

(async () => {
  const browser = await puppeteer.connect({ browserURL: fx.cdp || 'http://127.0.0.1:9333', protocolTimeout: 900000 });
  const page = (await browser.pages()).find(p => p.url().startsWith(fx.url.split('?')[0])) || await browser.newPage();
  await page.bringToFront(); await page.setViewport({ width: 1440, height: 900 });
  if (fx.cookies) await browser.setCookie(...fx.cookies);
  const load = async () => { await page.goto(fx.url, { waitUntil: 'domcontentloaded', timeout: 600000 }); await sleep(fx.settleMs || 20000); if (!page.url().startsWith(fx.url.split('?')[0])) throw new Error('landed on ' + page.url() + ' (auth?)'); await page.evaluate(fx.cleanJs || '0'); };
  const cur = page.url(); if (cur.startsWith(fx.url.split('?')[0]) === false || cur.includes('/auth/')) await load();
  const results = []; let since = 0;
  for (const e0 of spec.entries) {
    if (only && !new RegExp(only).test(e0.id)) continue;
    const f = fill(e0); const e = f.value;
    const lack = (e.needs || []).filter(n => !(fx.flags || []).includes(n));
    if (lack.length) { results.push({ id: e.id, decision: e.decision, status: 'SKIP', why: 'fixture lacks ' + lack.join(', ') }); console.log('SKIP', e.id); continue; }
    if (f.missing.length) { results.push({ id: e.id, decision: e.decision, status: 'SKIP', why: 'fixture lacks ' + [...new Set(f.missing)].join(', ') }); console.log('SKIP', e.id); continue; }
    if (since >= (fx.reloadEvery || 12)) { await load(); since = 0; }
    await page.evaluate(RESOLVER);
    for (let i = 0; i < 2; i++) { await page.keyboard.press('Escape'); await sleep(120); }
    let status = 'PASS', why = []; acted = false;
    try { for (const s of e.steps || []) await step(page, s); } catch (err) { status = 'FAIL'; why.push('step: ' + err.message); }
    if (status === 'PASS') for (const a of e.expect) { const w = await check(page, a); if (w) { status = 'FAIL'; why.push(w); } }
    results.push({ id: e.id, decision: e.decision, ledger: e.ledger, status, why });
    console.log(status, e.id, why.join(' | ').slice(0, 160));
    if (acted) { await load(); since = 0; }
  }
  fs.writeFileSync(outFile, JSON.stringify(results, null, 1));
  const c = {}; for (const r of results) { const k = `${r.decision}:${r.status}`; c[k] = (c[k] || 0) + 1; } console.log(JSON.stringify(c));
  browser.disconnect();
})().catch(e => { console.error(e); process.exit(1); });
