# Copy to items.py next to report-build.py (or set UIREP_ITEMS) and fill in.
# Shot paths are relative to UIREP_SHOTS; boxes are x0,y0,x1,y1 in full-resolution pixels.
TITLE = 'Editing 剪辑器 · demo vs 当前 差异清单'
STORAGE_KEY = 'ui-diff-<task>-<date>'
INTRO = """<ul>
<li><b>Demo：</b>which file, which screen, viewport, how many states captured.</li>
<li><b>当前：</b>which commit, which server/port, which data, and the read-only proof (head revision before/after).</li>
<li>只列不一致的地方；不属于本页的差异未列入（说明是哪些）。</li>
<li>「影响面」：前端 / 需后端 / 共享组件 的含义。</li>
</ul>"""
# Example diff ledger: demo (Moodio 3.0 L+D standalone.html, Timeline tab) vs current Editing tab.
# Each item: id, region, title, demo, app, kind, impact, pairs=[(demo_shot, box, app_shot, box)], layout
# kind: 布局 / 视觉 / 交互 / 功能
# impact: 前端 / 需后端 / 共享组件（影响编辑器以外）
D = 'demo/'; A = 'app/'
FULL = '0,0,1440,900'

ITEMS = [
dict(id='A1', region='A 整体布局', title='编辑区顶部多出的一行状态/开关栏',
  demo='没有这一行。三栏面板直接从顶部导航下方开始（y=52）。面板开关在各自面板上（Media pool 的 «、Properties 的 »），Export 在时间线工具栏右端。',
  app='顶部导航下方还有 37px 一行：左侧 “✓ Saved” 保存状态；右侧 Media pool / Clip properties 两个开关、Export、导出任务图标。三栏从 y=93 开始。',
  kind='布局', impact='前端',
  note='若去掉这一行，“Saved / Saving / Could not save + Retry / Reload” 保存状态需要新位置——demo 没有画保存状态（见 Q1）。导出任务列表入口同理（I2）。',
  pairs=[(D+'d01-default.png','0,0,1440,110',A+'a01-default.png','0,0,1440,110')], layout='stack'),
dict(id='A2', region='A 整体布局', title='三栏宽度比例与面板外观',
  demo='Media pool 535px ｜ 播放器 514px ｜ Properties 375px；栏间距 4px；面板圆角 4px、1px 描边 rgba(0,0,0,.08)。',
  app='Media pool 400px ｜ 播放器 800px ｜ Clip properties 208px；栏间距 8px；面板圆角 8px。',
  kind='布局', impact='前端', note='',
  pairs=[(D+'d01-default.png',FULL,A+'a01-default.png',FULL)], layout='stack-half'),
]

APP_ONLY = [
 ('I1','顶部保存状态与 Retry / Reload 按钮','A1'),
]

QUESTIONS = [
 ('Q1','A1','去掉顶部行后，保存状态放在哪里？demo 没有画。'),
]
