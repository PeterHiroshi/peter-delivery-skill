# Example (trimmed from the 2026-10-16 Editing tab spec).
# Final UI/UX spec for the Editing tab (editor UI optimization), built from Peter's
# decisions of 2026-10-16 (decisions-2026-10-16.json) over the R1 diff ledger.
# One source of truth: build.py renders spec.html (for review) and interactions.json
# (the acceptance oracle, replayed by replay.cjs) from this file.
#
# Targets are resolved by accessible role + name (aria-label / accessible text) at a
# 1440x900 viewport, light theme, English UI. A name listed here that does not exist in
# the current app is a name the build must provide.

def R(role, name, **kw):
    d = {"role": role, "name": name}
    d.update(kw)
    return d

def box(on, tol=2, **xywh):
    return {"assert": "box", "on": on, "tol": tol, **xywh}

def css(on, **props):
    return {"assert": "style", "on": on, "css": {k.replace('_', '-'): v for k, v in props.items()}}

def visible(on): return {"assert": "visible", "on": on}
def absent(on): return {"assert": "absent", "on": on}
def text(on, equals=None, contains=None):
    d = {"assert": "text", "on": on}
    if equals is not None: d["equals"] = equals
    if contains is not None: d["contains"] = contains
    return d
def order(axis, *names): return {"assert": "order", "axis": axis, "on": list(names)}
def click(on): return {"do": "click", "on": on}
def hover(on): return {"do": "hover", "on": on}
def key(k): return {"do": "key", "key": k}
def drag(on, dx=0, dy=0): return {"do": "drag", "on": on, "dx": dx, "dy": dy}
def typ(on, s): return {"do": "type", "on": on, "text": s}

POOL = R("region", "Media pool")
PLAYER = R("region", "Player")
PROPS = R("region", "Properties")
TL = R("region", "Timeline")
TOOLBAR = R("toolbar", "Timeline tools")
INK = "rgb(25, 24, 23)"
INK2 = "rgb(103, 102, 101)"
LINE08 = "rgba(0, 0, 0, 0.08)"
LINE16 = "rgba(0, 0, 0, 0.16)"
HOVER04 = "rgba(0, 0, 0, 0.04)"
PURPLE = "rgb(122, 92, 214)"
MONO = "JetBrains Mono"

# Pending confirmations: my proposal where his answers leave a placement open.
PENDING = [
 ("P1", "Q1 / A1", "保存状态（Saved / Saving… / Could not save）放进顶部导航栏左侧、集名下拉之后：「Untitled Project / 第 3 集 ▾ · ✓ Saved」，12px 灰字；失败时同位置出现「Retry save」、冲突时「Reload saved edit」文字按钮；「Agent is editing this timeline」「Preparing media…」也显示在这里。只在 Editing 标签显示，不改动导航栏其它元素的位置。"),
]

ITEMS = [
dict(id="A1", decision="adopt", title="去掉编辑区顶部状态/开关栏",
 final="三栏面板紧贴顶部导航下方（y=52）。Media pool / Properties 的开关回到各自面板（A5）；Export 进入时间线工具栏右端（E7），导出任务合并进 Export 按钮（F4）；保存状态移到顶部导航（P1）。",
 nums=[("面板顶边", "y = 52（导航高 48 + 间距 4）")],
 demo=("demo/d01-default.png", "0,0,1440,110"), cur=("app/a01-default.png", "0,0,1440,110"),
 entries=[
  dict(id="A1.panels-start-under-nav", given=["editing tab open"], steps=[], expect=[box(POOL, y=52), box(PLAYER, y=52), box(PROPS, y=52)]),
  dict(id="A1.no-editor-header-toggles", steps=[], expect=[absent(R("button", "Clip properties")), absent(R("button", "Export jobs"))]),
  dict(id="A1.save-status-in-top-nav", pending="P1", steps=[], expect=[visible(R("status", "Save status")), text(R("status", "Save status"), contains="Saved"), box(R("status", "Save status"), tol=24, y=16, h=16)]),
 ]),
dict(id="A2", decision="adopt", title="三栏默认宽度与面板外观",
 final="默认：Media pool = 160 侧栏 + 375 内容 = 535；Properties = 375；播放器占剩余宽度（1440 下 514）。栏间距 4；面板圆角 4、1px 描边 rgba(0,0,0,.08)、白底；播放器面板底色 #FAFAFA、描边 #E5E5E5。",
 nums=[("Media pool", "x 4, w 535"), ("播放器", "x 543, w 514"), ("Properties", "x 1061, w 375"), ("圆角 / 描边", "4px / 1px rgba(0,0,0,.08)")],
 demo=("demo/d01-default.png", "0,0,1440,900"), cur=("app/a01-default.png", "0,0,1440,900"),
 entries=[dict(id="A2.default-widths", steps=[], expect=[box(POOL, x=4, w=535), box(PLAYER, x=543, w=514, tol=4), box(PROPS, x=1061, w=375), css(POOL, border_radius="4px"), css(PLAYER, background_color="rgb(250, 250, 250)", border_radius="4px")])]),
dict(id="F1", decision="adopt", title="序列设置：锚定在芯片上的弹层",
 final="从芯片向上弹出、左对齐芯片：372 宽、内边距 14、1px 描边 .16、圆角 4、阴影；不加遮罩，点外部关闭。内容顺序：标题 13.5/500 → Aspect ratio 胶囊（46×30，选中黑底）+ Swap width / height → Match source size（整行 36 高）→ 来源名一行 → Frame rate（自绘下拉，项 31 高，当前项浅灰底 + ✓）→ Canvas resolution（同）→ Width ｜ Height（36 高）→ Cancel / Apply。帧率、分辨率预设保留当前（Q7），改帧率时的确认流程保留在弹层内。",
 nums=[("弹层", "372 宽，pad 14，r 4，border .16，shadow 0 24px 60px -28px rgba(0,0,0,.28)"), ("胶囊", "46×30，12.5px/500，r 4"), ("下拉项", "332×31，r 4，12.5px")],
 demo=("demo/d05-seq-settings.png", "428,186,808,660"), cur=("app/a05-seq-settings.png", "490,225,945,675"),
 entries=[
  dict(id="F1.popover-anchored", steps=[click(R("button", "Sequence settings", exact=False))], expect=[absent(R("dialog", "Sequence settings", modal=True)), visible(R("dialog", "Sequence settings")), box(R("dialog", "Sequence settings"), w=372, tol=4), {"assert": "above", "on": R("dialog", "Sequence settings"), "ref": R("button", "Sequence settings", exact=False)}, {"assert": "alignedLeft", "on": R("dialog", "Sequence settings"), "ref": R("button", "Sequence settings", exact=False), "tol": 2}]),
  dict(id="F1.custom-dropdown", steps=[click(R("button", "Sequence settings", exact=False)), click(R("combobox", "Frame rate"))], expect=[visible(R("listbox", "Frame rate")), {"assert": "attr", "on": R("option", "24 fps"), "attr": {"aria-selected": "true"}}, {"assert": "count", "on": R("option", "*", within="Frame rate"), "equals": 9, "note": "current presets kept (Q7)"}]),
  dict(id="F1.outside-closes", steps=[click(R("button", "Sequence settings", exact=False)), click(PLAYER)], expect=[absent(R("dialog", "Sequence settings"))]),
 ]),
]

# Decisions to keep as they are: guards so the build does not remove them.
KEEP_GUARDS = [
 dict(id="keep.A4.timeline-resize", ledger="A4", steps=[], expect=[visible(R("separator", "Resize timeline height", exact=False))]),
]
