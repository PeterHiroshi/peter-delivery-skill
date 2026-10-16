import sys, json, re, base64, gzip, os, html
src, out = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()
def block(kind):
    m = re.search(r'<script type="__bundler/%s">(.*?)</script>' % re.escape(kind), t, re.S)
    return m.group(1) if m else None
manifest = json.loads(block('manifest'))
template = json.loads(block('template'))
page_order = json.loads(block('page_order') or '[]')
ext = json.loads(block('ext_resources') or '[]')
os.makedirs(out + '/assets', exist_ok=True)
names = {}
extmap = {'text/javascript':'js','application/javascript':'js','text/css':'css','text/html':'html','image/png':'png','image/jpeg':'jpg','image/svg+xml':'svg','image/webp':'webp','video/mp4':'mp4','font/woff2':'woff2','audio/mpeg':'mp3','application/json':'json','image/gif':'gif'}
for uuid, e in manifest.items():
    b = base64.b64decode(e['data'])
    if e.get('compressed'): b = gzip.decompress(b)
    ext_ = extmap.get(e['mime'], 'bin')
    fn = f"{uuid}.{ext_}"
    open(f"{out}/assets/{fn}", 'wb').write(b)
    names[uuid] = (fn, e['mime'], len(b), uuid in page_order)
for uuid,(fn,_,_,_) in names.items():
    template = template.replace(uuid, 'assets/' + fn)
open(out + '/index.html', 'w', encoding='utf-8').write(template)
json.dump({'ext': ext, 'page_order': page_order, 'assets': {u: {'file':v[0],'mime':v[1],'size':v[2],'page':v[3]} for u,v in names.items()}}, open(out + '/manifest.json','w'), indent=1)
for u,v in sorted(names.items(), key=lambda x:-x[1][2]): print(v[0], v[1], v[2], 'PAGE' if v[3] else '')
print('template', len(template)); print('ext', ext)
