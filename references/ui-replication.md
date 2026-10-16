# Replicating a reference UI onto a product that already exists

Run both, list every difference, let Peter decide once, pin his decisions as an
interaction spec, and only then build. Rule 22 (replicate 1:1 first) still holds
for a NEW surface. This file covers the other case: a whole-product demo set against
a screen that already ships, where not every difference is wanted.

## Why (2026-10-16, moodio-agent, Editing tab vs `Moodio 3.0 L+D standalone.html`)

Peter's instruction, verbatim, because it is the whole method:
「先主动运行一次这个html中的UI/UX交互，产出UI/UX报告，我来review，从而让我明确知道你看到的和我希望的是一致的；
review成功的报告你可以进一步生成交互json代码（精细化的），作为你未来交付时可以直接去验证的证据」
and 「demo中不是每个UI都是要变的……你需要根据你的运行来列出来和当前UI/UX不一致的，然后我去逐个验收并做取舍；
只有完成1后你才能再去产出最终的UI/UX报告以及交互json，否则又会出现之前“挤牙膏”式的修改」.

Two failure modes this prevents: building 1:1 things he would have rejected (the
demo is a product vision, not a change list), and discovering the differences one
review round at a time (挤牙膏). First run's R1 (2026-10-16): ~85 captured states →
48 differences, 14 "current has, demo doesn't", 9 questions, in one hand-off.
Whether it ended the toothpaste rounds is decided by his review, not by me.

## The four rounds

**R1 — run both, hand over the diff ledger. No code, no spec.**

- *Render, don't read* (task-playbook "UI task"). Read the reference's source only
  to ENUMERATE states: every menu, popover, selection, hover, empty state, tab,
  theme, and every group the source defines but hides (`display:none` — the demo's
  Mark/In/Out buttons: a decision, not an omission). Then drive each state for real
  and capture the current product in the same state.
- *Measure*, so a difference is a number: box, background, border, radius, font,
  colour, letter-spacing along the ancestor chain at a point (`measure.cjs`).
- A ledger item: id, region, title, **demo behaviour**, **current behaviour**, kind
  (layout / visual / interaction / feature), impact (frontend / needs backend /
  shared component beyond this page), demo|current crops, note. Differences only.
- Two extra sections: **current has, demo doesn't** (default keep; a removal needs
  his word, rule 17) and **questions** where demo and requirement are both silent
  (rule 25: a gap is a question, never a feature).
- Every sentence that says "needs confirming" is a run I have not done yet. Do it
  before the hand-off (2026-10-16: three items were wrong until re-run — the
  current pool also had an "Add N" bar, tooltips matched, selection had no grips).
- Hand-off: a local HTML in the scratchpad (`report-build.py`): per item the two
  crops side by side and radios *adopt / keep / partial / later* + a note, saved in
  localStorage, exported as one JSON he pastes back. One pass, all decisions.

**R2 — his decisions → final UI/UX spec + interaction JSON. Still no code. WAIT.**

- The spec holds only adopted items, as observable behaviour with the measured
  numbers.
- The interaction JSON is the acceptance oracle. One entry per adopted state:

  ```json
  { "id": "F4-export-popover", "ledger": "F4",
    "demo": { "shot": "d10-export.png", "steps": ["click role=button name='Export timeline'"] },
    "target": { "route": "/create/:ws/episodes/:ep?surface=editing", "pre": ["timeline has ≥1 clip"] },
    "steps": [ { "do": "click", "on": { "role": "button", "name": "Export" } } ],
    "expect": [ { "on": { "role": "dialog" }, "visible": true,
                  "box": { "anchor": "above:Export", "w": 310, "tol": 8 },
                  "text": ["Format", "Resolution", "Range"] } ],
    "shot": "expected/F4.png" }
  ```

  Targets by accessible role + name (or a test id), never coordinates —
  coordinates belong to R1 exploration scripts only.

**R3 — build (rule 31 stage A) against the JSON**, then replay every entry on the
running app as the self-check before the hand-off; report pass / fail per entry.
A failing entry is a defect, not a question.

**R4 — B / C as usual.**

## Tooling (`scripts/ui-replication/`)

- `unpack.py <standalone.html> <out>` — a design-tool "Bundled Page"
  (`__bundler/manifest` + `__bundler/template` script tags, gzip+base64 assets) →
  `index.html` + `assets/`. Read it to enumerate; RUN the original over `file://`
  (its own unpacker works) in Chrome with `--allow-file-access-from-files`.
- `lib.cjs` — one persistent headless Chrome (`--remote-debugging-port=9333`),
  `puppeteer.connect` per script, `bringToFront` the tab being driven (a background
  tab is throttled: 30–60 s per step instead of 2). For a "dc" runtime demo, all UI
  state lives in one logic object reachable through any node's React fiber
  (`stateNode.logic`): snapshot `logic.state` once at the base state and restore it
  before every step — a clean state per capture without the 8 s reload.
- `measure.cjs demo|app x,y:label …` — the ancestor-chain style dump.
- `pair.py` (side by side) / `stack.py` (wide strips) crops; `report-build.py` +
  `items.example.py` build the R1 page. `puppeteer-core` installs into the
  scratchpad in 11 s and drives the system Chrome; no download.

## Discipline while capturing the current product

- Its own dev server on its own port from a detached sibling worktree (never
  Peter's :3000); the diff-report request covers this capture — say so in the
  hand-off, since rule 24 otherwise asks first.
- Read-only on his real data: record the draft's head revision before and after
  and report both; open settings views but not views that write (moodio: the
  export *jobs* list acknowledges the unread badge; the *settings* view does not);
  remove a cookie banner from the DOM instead of clicking it (a click records a
  consent); prefer a draft whose shape resembles the demo's (a 42-track stress
  draft made every timeline crop unreadable).
