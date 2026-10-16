// probe(page, specs): each spec {name, text|starts|sel|point, up, nth, within:[x0,y0,x1,y1]}
async function probe(page, specs) {
  return page.evaluate((specs) => {
    const vis = e => { const b = e.getBoundingClientRect(); const cs = getComputedStyle(e); return b.width > 0 && b.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
    const inBox = (e, w) => { if (!w) return true; const b = e.getBoundingClientRect(); return b.x >= w[0] && b.y >= w[1] && b.x + b.width <= w[2] + 1 && b.y + b.height <= w[3] + 1; };
    const out = {};
    for (const s of specs) {
      let el = null;
      if (s.point) el = document.elementFromPoint(s.point[0], s.point[1]);
      else {
        const all = [...document.querySelectorAll(s.sel || '*')].filter(e => vis(e) && inBox(e, s.within));
        let m = all;
        if (s.text) m = all.filter(e => (e.textContent || '').trim().replace(/\s+/g, ' ') === s.text);
        if (s.starts) m = all.filter(e => (e.textContent || '').trim().replace(/\s+/g, ' ').startsWith(s.starts));
        m.sort((a, b) => (a.textContent || '').length - (b.textContent || '').length || a.getBoundingClientRect().width * a.getBoundingClientRect().height - b.getBoundingClientRect().width * b.getBoundingClientRect().height);
        el = m[s.nth || 0] || null;
      }
      for (let i = 0; el && i < (s.up || 0); i++) el = el.parentElement;
      if (el && s.upTo) { let e = el; while (e && e !== document.body) { const r = e.getBoundingClientRect(); if (r.width >= (s.upTo.minW || 0) && r.height >= (s.upTo.minH || 0) && (!s.upTo.tag || e.tagName.toLowerCase() === s.upTo.tag)) break; e = e.parentElement; } el = e; }
      if (!el) { out[s.name] = null; continue; }
      const b = el.getBoundingClientRect(); const c = getComputedStyle(el);
      const bd = ['Top', 'Right', 'Bottom', 'Left'].map(k => c['border' + k + 'Width'] === '0px' ? '0' : c['border' + k + 'Width'] + ' ' + c['border' + k + 'Color']);
      out[s.name] = { tag: el.tagName.toLowerCase(), box: [Math.round(b.x), Math.round(b.y), Math.round(b.width), Math.round(b.height)],
        bg: c.backgroundColor, bgImg: c.backgroundImage === 'none' ? undefined : c.backgroundImage.slice(0, 120), color: c.color, font: `${c.fontSize}/${c.fontWeight} ${c.fontFamily.split(',')[0].replace(/"/g, '')}`, lh: c.lineHeight,
        ls: c.letterSpacing === 'normal' ? undefined : c.letterSpacing, tt: c.textTransform === 'none' ? undefined : c.textTransform,
        border: bd.every(x => x === bd[0]) ? bd[0] : bd.join(' | '), radius: c.borderRadius, pad: c.padding, gap: c.gap === 'normal' ? undefined : c.gap,
        grid: c.gridTemplateColumns === 'none' ? undefined : c.gridTemplateColumns, shadow: c.boxShadow === 'none' ? undefined : c.boxShadow.slice(0, 100), cursor: c.cursor === 'auto' ? undefined : c.cursor,
        opacity: c.opacity === '1' ? undefined : c.opacity, outline: c.outlineStyle === 'none' ? undefined : `${c.outlineWidth} ${c.outlineStyle} ${c.outlineColor}`, txt: (el.innerText || '').trim().replace(/\s+/g, ' ').slice(0, 40) };
    }
    return out;
  }, specs);
}
module.exports = { probe };
