import os, sys, json, html
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.environ.get('UIREP_SHOTS', os.path.join(HERE, '..', 'shots'))
# items module: UIREP_ITEMS (default items.py next to this file); copy items.example.py to start
sys.path.insert(0, HERE)
import importlib
M = importlib.import_module(os.environ.get('UIREP_ITEMS', 'items'))

os.makedirs(os.path.join(HERE, 'img'), exist_ok=True)

def crop(rel, box, name):
    x0, y0, x1, y1 = map(int, box.split(','))
    im = Image.open(os.path.join(SHOTS, rel)).convert('RGB')
    x1, y1 = min(x1, im.width), min(y1, im.height)
    out = im.crop((x0, y0, x1, y1))
    out.save(os.path.join(HERE, 'img', name), optimize=True)
    return 'img/' + name, out.width

def esc(s): return html.escape(s or '')

cards = []
for it in M.ITEMS:
    figs = []
    for k, (ds, db, as_, ab) in enumerate(it['pairs']):
        d, dw = crop(ds, db, f"{it['id']}-{k}-demo.png")
        a, aw = crop(as_, ab, f"{it['id']}-{k}-app.png")
        cls = {'pair': 'pair', 'stack': 'stack', 'stack-half': 'pair'}[it['layout']]
        figs.append(f'''<div class="figs {cls}">
  <figure><figcaption class="tag demo">Demo</figcaption><a href="{d}" target="_blank"><img src="{d}" style="max-width:{dw}px" loading="lazy"></a></figure>
  <figure><figcaption class="tag app">当前</figcaption><a href="{a}" target="_blank"><img src="{a}" style="max-width:{aw}px" loading="lazy"></a></figure>
</div>''')
    if not figs:
        figs.append('<p class="nofig">（无单独截图：差异为尺寸/交互，见描述）</p>')
    note = f'<p class="note"><b>备注</b> {esc(it["note"])}</p>' if it.get('note') else ''
    cards.append(f'''<section class="card" id="{it['id']}" data-id="{it['id']}">
  <header><span class="id">{it['id']}</span><h3>{esc(it['title'])}</h3>
    <span class="chip">{esc(it['kind'])}</span><span class="chip {'warn' if it['impact']!='前端' else ''}">{esc(it['impact'])}</span></header>
  <div class="cmp"><div><h4>Demo</h4><p>{esc(it['demo'])}</p></div><div><h4>当前</h4><p>{esc(it['app'])}</p></div></div>
  {note}
  {''.join(figs)}
  <div class="decide">
    <label><input type="radio" name="d-{it['id']}" value="adopt"> 按 demo 改</label>
    <label><input type="radio" name="d-{it['id']}" value="keep"> 保留现状</label>
    <label><input type="radio" name="d-{it['id']}" value="partial"> 部分采纳</label>
    <label><input type="radio" name="d-{it['id']}" value="later"> 以后再说</label>
    <textarea placeholder="补充说明（可选）" data-note="{it['id']}"></textarea>
  </div>
</section>''')

regions = []
for it in M.ITEMS:
    if it['region'] not in regions: regions.append(it['region'])
toc = ''.join(f'<li><a href="#{[i for i in M.ITEMS if i["region"]==r][0]["id"]}">{esc(r)}</a> <span>{sum(1 for i in M.ITEMS if i["region"]==r)}</span></li>' for r in regions)

body = []
cur = None
for it, c in zip(M.ITEMS, cards):
    if it['region'] != cur:
        cur = it['region']; body.append(f'<h2 class="region">{esc(cur)}</h2>')
    body.append(c)

app_only = ''.join(f'''<tr data-id="{i}"><td class="id">{i}</td><td>{esc(t)}</td><td>{esc(rel)}</td>
<td class="opts"><label><input type="radio" name="d-{i}" value="keep"> 保留</label><label><input type="radio" name="d-{i}" value="move"> 保留但挪位置</label><label><input type="radio" name="d-{i}" value="remove"> 去掉</label><input class="inline-note" placeholder="说明" data-note="{i}"></td></tr>''' for i, t, rel in M.APP_ONLY)
qs = ''.join(f'''<tr data-id="{q}"><td class="id">{q}</td><td>{esc(rel)}</td><td>{esc(t)}</td><td><textarea placeholder="你的答复" data-note="{q}"></textarea></td></tr>''' for q, rel, t in M.QUESTIONS)

ids = [i['id'] for i in M.ITEMS] + [i for i, _, _ in M.APP_ONLY] + [q for q, _, _ in M.QUESTIONS]

page = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(M.TITLE)}</title>
<style>
:root{{--bg:#f6f5f4;--panel:#fff;--tx:#191817;--tx2:#676665;--line:rgba(0,0,0,.1);--demo:#b4232c;--app:#1f5fbf;--warn:#a35a00;--hl:#efe9ff}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151515;--panel:#1f1f1f;--tx:#eceae6;--tx2:#a5a3a0;--line:rgba(255,255,255,.12);--demo:#ff7b82;--app:#7fb0ff;--warn:#ffb35c;--hl:#2c2640}}}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--tx);font:14px/1.6 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}}
.top{{position:sticky;top:0;z-index:5;background:var(--panel);border-bottom:1px solid var(--line);padding:10px 16px;display:flex;gap:12px;align-items:center;flex-wrap:wrap}}
.top b{{font-size:15px}} .top .prog{{color:var(--tx2)}} .top button{{border:1px solid var(--line);background:var(--tx);color:var(--panel);border-radius:6px;padding:6px 12px;cursor:pointer}}
main{{max-width:1500px;margin:0 auto;padding:16px}}
.intro{{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px 16px}} .intro li{{margin:2px 0}}
.toc{{display:flex;gap:8px;flex-wrap:wrap;padding:0;list-style:none}} .toc li{{background:var(--panel);border:1px solid var(--line);border-radius:999px;padding:2px 10px}} .toc span{{color:var(--tx2)}}
h2.region{{margin:28px 0 8px;font-size:18px}}
.card{{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px 16px;margin:10px 0}}
.card.done{{border-left:4px solid #3a8f5c}}
.card header{{display:flex;gap:8px;align-items:center;flex-wrap:wrap}} .card h3{{margin:0;font-size:15px}}
.id{{font:600 12px ui-monospace,Menlo,monospace;background:var(--hl);padding:1px 6px;border-radius:4px}}
.chip{{font-size:11px;border:1px solid var(--line);border-radius:999px;padding:0 8px;color:var(--tx2)}} .chip.warn{{color:var(--warn);border-color:var(--warn)}}
.cmp{{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:6px}} .cmp h4{{margin:4px 0 0;font-size:12px}} .cmp div:first-child h4{{color:var(--demo)}} .cmp div:last-child h4{{color:var(--app)}} .cmp p{{margin:2px 0}}
.note{{margin:6px 0;color:var(--tx2)}}
.figs{{display:flex;gap:12px;margin:8px 0;align-items:flex-start;overflow-x:auto}} .figs.stack{{flex-direction:column}}
.figs.pair figure{{flex:1 1 0;min-width:0}} figure{{margin:0}} figure img{{width:100%;height:auto;border:1px solid var(--line);border-radius:4px;display:block}}
.tag{{font:600 11px ui-monospace,Menlo,monospace}} .tag.demo{{color:var(--demo)}} .tag.app{{color:var(--app)}}
.nofig{{color:var(--tx2);font-size:12px}}
.decide{{display:flex;gap:14px;align-items:center;flex-wrap:wrap;border-top:1px dashed var(--line);padding-top:8px;margin-top:6px}}
.decide textarea{{flex:1 1 260px;min-height:32px;background:var(--bg);color:var(--tx);border:1px solid var(--line);border-radius:6px;padding:4px 8px}}
table{{width:100%;border-collapse:collapse;background:var(--panel);border:1px solid var(--line);border-radius:8px}} td{{border-top:1px solid var(--line);padding:6px 8px;vertical-align:top}}
td textarea,.inline-note{{width:100%;background:var(--bg);color:var(--tx);border:1px solid var(--line);border-radius:6px;padding:4px 8px}} td.opts label{{margin-right:10px;white-space:nowrap}}
#out{{width:100%;min-height:120px;margin-top:8px;display:none;font:12px ui-monospace,Menlo,monospace}}
@media (max-width:900px){{.cmp{{grid-template-columns:1fr}} .figs{{flex-direction:column}}}}
</style></head><body>
<div class="top"><b>{esc(M.TITLE)}</b><span class="prog" id="prog"></span><button id="exp">导出决策 JSON</button><textarea id="out" readonly></textarea></div>
<main>
<div class="intro">
<p><b>怎么用：</b>每条选一个决定（按 demo 改 / 保留现状 / 部分采纳 / 以后再说），需要时写一句说明；选择自动保存在本浏览器里。全部看完点右上「导出决策 JSON」，把文本整段发给我。</p>
{M.INTRO}
<ul class="toc">{toc}<li><a href="#app-only">仅当前有</a> <span>{len(M.APP_ONLY)}</span></li><li><a href="#questions">问题</a> <span>{len(M.QUESTIONS)}</span></li></ul>
</div>
{''.join(body)}
<h2 class="region" id="app-only">I 当前有、demo 没有（默认保留，请确认）</h2>
<table><tbody>{app_only}</tbody></table>
<h2 class="region" id="questions">Q demo 与需求都没说清的地方</h2>
<table><tbody>{qs}</tbody></table>
<p style="color:var(--tx2);margin:24px 0">证据截图在同目录 img/（点图看原尺寸），原始全屏截图在 ../shots/。</p>
</main>
<script>
const IDS = {json.dumps(ids)};
const KEY = {json.dumps(M.STORAGE_KEY)};
let st = {{}}; try {{ st = JSON.parse(localStorage.getItem(KEY) || '{{}}'); }} catch (e) {{}}
const save = () => {{ try {{ localStorage.setItem(KEY, JSON.stringify(st)); }} catch (e) {{}} prog(); }};
function prog() {{ const n = IDS.filter(i => st[i] && (st[i].d || st[i].note)).length; document.getElementById('prog').textContent = '已处理 ' + n + ' / ' + IDS.length;
  document.querySelectorAll('.card').forEach(c => c.classList.toggle('done', !!(st[c.dataset.id] && st[c.dataset.id].d))); }}
document.querySelectorAll('input[type=radio]').forEach(r => {{ const id = r.name.slice(2); if (st[id] && st[id].d === r.value) r.checked = true;
  r.addEventListener('change', () => {{ st[id] = Object.assign({{}}, st[id], {{ d: r.value }}); save(); }}); }});
document.querySelectorAll('[data-note]').forEach(t => {{ const id = t.dataset.note; if (st[id] && st[id].note) t.value = st[id].note;
  t.addEventListener('input', () => {{ st[id] = Object.assign({{}}, st[id], {{ note: t.value }}); save(); }}); }});
document.getElementById('exp').onclick = async () => {{ const out = {{}}; IDS.forEach(i => {{ if (st[i]) out[i] = st[i]; }});
  const txt = JSON.stringify(out, null, 1); const ta = document.getElementById('out'); ta.style.display = 'block'; ta.value = txt; ta.select();
  try {{ await navigator.clipboard.writeText(txt); document.getElementById('exp').textContent = '已复制到剪贴板'; }} catch (e) {{ document.execCommand && document.execCommand('copy'); }} }};
prog();
</script></body></html>'''
open(os.path.join(HERE, 'index.html'), 'w', encoding='utf-8').write(page)
print('ok', len(M.ITEMS), 'items;', len(os.listdir(os.path.join(HERE, 'img'))), 'images')
