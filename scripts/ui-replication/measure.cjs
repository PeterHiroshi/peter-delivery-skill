// node measure.cjs demo|app  x,y[:label] ...  → ancestor chain boxes with bg/border/radius at each point
const h = require('./lib.cjs');
(async () => {
  const [which, ...pts] = process.argv.slice(2);
  const { browser, page } = which === 'demo' ? await h.connect() : await h.connectApp();
  for (const pt of pts) {
    const [xy, label] = pt.split(':'); const [x, y] = xy.split(',').map(Number);
    const chain = await page.evaluate((x, y) => {
      let e = document.elementFromPoint(x, y); const out = [];
      while (e && e !== document.body && out.length < 14) {
        const cs = getComputedStyle(e); const b = e.getBoundingClientRect();
        const bg = cs.backgroundColor; const bd = cs.borderTopWidth !== '0px' || cs.borderLeftWidth !== '0px' ? `${cs.borderTopWidth} ${cs.borderTopColor}` : '';
        if ((bg && bg !== 'rgba(0, 0, 0, 0)') || bd || cs.borderRadius !== '0px' || out.length === 0)
          out.push(`${e.tagName.toLowerCase()} [${Math.round(b.x)},${Math.round(b.y)} ${Math.round(b.width)}x${Math.round(b.height)}] bg=${bg} bd=${bd} r=${cs.borderRadius} font=${cs.fontSize}/${cs.fontWeight} ${cs.fontFamily.split(',')[0]} color=${cs.color} ls=${cs.letterSpacing} tt=${cs.textTransform} txt=${(e.innerText||'').trim().slice(0,24).replace(/\n/g,'|')}`);
        e = e.parentElement;
      }
      return out;
    }, x, y);
    console.log(`## ${label || xy}`); console.log(chain.join('\n'));
  }
  browser.disconnect();
})().catch(e => { console.error(e); process.exit(1); });
