# Delivery rhythm: whose eyes, in what order

Peter is the only one who can accept a UI. Everything here exists to move his review earlier and make the work before it cheap.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 31. UI first behind a typed seam; the backend lands after Peter has accepted the interaction (Peter 2026-09-20)

Peter: 「大部分的剪裁都是前端功能，我需要等待很长时间后才能去验收，验收不合格又需要
等待很长时间……我希望能尽可能缩短这个反馈链路」. The pipeline had the
highest-variance, human-gated step last. Rule 22's session paid the full bill:
design doc → TDD → three browser runs → adversarial review → five-locale copy,
then he opened it and the replica was wrong. Everything downstream of the replica
had verified the wrong thing.

Three stages, one hand-off each, every one a runnable increment.

**A — interactive replica. Target: half a day. tsc green is the whole gate.**
Real components, real routes, real interaction state. Data arrives through a
**seam**: one module `lib/<feature>/<x>-source.ts` that exports the exact
signature the backend will implement and returns typed fixtures for now. Not msw,
not storybook — one file.
Not in stage A: persistence, migrations, permission edges, the locale sweep,
tests, review agents, a design doc.
Hand off three things: screenshots of the prototype beside mine for **every
screen the flow touches** (entry → dialog → result page → toast → the sidebar row
it creates), the scope ledger (rule 30), and the numbered test cases (rule 24).
**This round is the acceptance round.** Nothing below this line starts before he
accepts.

**B — wire the backend.** Replace the seam's implementation. The signature does
not move, so no UI code changes. NOW write the tests (the seam's contract, plus
the route called on the running app, rule 29), the migration, the locale sweep,
and one adversarial diff pass.

**C — harden.** Concurrency, caps, error codes. A risk gate appears only for
money / permissions / data loss / migrations.

**Why a seam and not just "keep the layers separate".** Rule 25 asked for three
homes and got a posture; a seam is a checkable artifact with a signature. It also
makes stage A non-throwaway — the same UI code enters B unchanged — and it gives
the interaction logic (ordering, which row is active, version actions, search) a
home that node-only vitest CAN test. That leaves only pixels for Peter's eyes,
which is the division rule 24 already asked for.

Stage A's work lands as its own local commit on the feature branch, so he can
review and revert it alone; B and C stack on top and the branch opens one PR
(Peter 2026-09-20).

### 5. Design doc before code — including before tests

Conversation consensus does not substitute. Write the design to a file, present
it, wait. This is a standing requirement from earlier work
(`design-doc-before-coding`), and it applies to TDD tests too.

**Proportionality:** a one-line fix does not need a document. Multi-file, new
abstractions, or anything touching a contract does. If unsure, write three
bullets and ask if that is enough.

**Exception — a task that references an existing prototype (rule 22):** the
prototype IS the design. Do not write a design doc, do not propose
alternatives, do not "improve" it. Replicate it 1:1 and hand the replica
over for review; the doc, if one is wanted at all, comes after acceptance.

### 22. Prototype tasks: replicate 1:1 FIRST, Peter reviews, THEN tests, THEN backend hardening (standing instruction, Peter 2026-09-15)

Meegle 14294602 sub-02: Peter pointed at `moodio-ui` for the interaction.
I read the prototype's markup, wrote a design doc, got it confirmed, did
TDD, three browser runs, an adversarial review round, five-locale copy —
hours of work — and then he opened it: "你完成的和 moodio-ui 中的样式完全
不一致呀". The dialog was the app's own panel chrome with descriptions the
prototype never had. Everything downstream of the replica (tests, review,
i18n guards) had verified the wrong thing, and the one deliverable he
actually asked for — a 1:1 copy of the prototype — was the part not done.
His words: "连我最初想要的 1:1 复刻原型这个任务都没有完成，更不要提后续的测试了".

The order for any task that names a prototype, mockup, or reference UI:

1. **Replicate fast.** Render the prototype (screenshot + computed styles),
   build the same thing in the app with the same geometry, copy and
   structure, screenshot mine beside it, hand BOTH over. Minutes to an
   hour, not a day. No design doc, no options, no tests yet, no review
   agents, no i18n sweep. tsc green is enough to hand over.
2. **Peter reviews the replica.** Fix what he points at. Repeat until he
   accepts. Nothing below this line starts before acceptance — every hour
   spent below it before acceptance is wasted when the replica is wrong.
3. **Then tests + polish**: the guard tests, the locale sweep, the failure
   cases, the harness runs.
4. **Then backend stability**: concurrency, caps, error codes, the review
   round, the DB checks.

**1:1 means the same options in the same order, too.** After the restyle
Peter asked why the dialog had seven cards when the prototype has four. I
had derived the list from the repo's document-type registry and then asked
him whether to trim it — deriving from the codebase what the reference
already states, and turning my deviation into a question for him. When a
reference exists, every enumerable thing on the screen (options, order,
labels, icons, copy) comes from the reference; the codebase supplies only
what the reference cannot (ids, routes). A deviation is a defect to fix,
not a question to ask.

**And 1:1 covers every screen the flow touches, not the first one.** Third
round, same day: the dialog now matched, and Peter opened the RESULT —
the imported page still had the app's own header (section label, small
serif title), no meta row, the app's editor typography, opened in compare
view; and the chooser refused `.doc`, which the prototype accepts. I had
compared the one screen he first complained about and stopped. Before
handing a replica over, walk the prototype's flow end to end (entry →
dialog → result page → toast → the sidebar row it creates) and measure
every screen; the format list and copy are part of the screen.

This inverts my default (design → tests → build → verify → report). The
default optimises for not shipping bugs; for a prototype task the bug
that matters is "not what he asked for", and only his eyes find it. The
same applies to any task where the acceptance criterion is visual and the
reference exists: the reference is the spec, the replica is the first
deliverable, everything else waits.

### 23. `ccl-skills` is DISABLED, not merely opt-in — recall one by name for a genuine risk gate (Peter 2026-09-15, 2026-09-19, switched off 2026-09-20)

The pack (product-rd-workflow, web-react-dev, multi-agent-delegation, code-review,
testing-strategy…) was loaded through its hooks four times in one session; its
gates pushed the work toward design docs, delegation charters and coverage sweeps
while the replica was still wrong. Peter: "ccl-skills 要慎用，这个 skills 会花费
大量 token 和时间……特别是上述这种任务，简直就是浪费时间". Again on 2026-09-19 —
"ccl-skills 太慢了，以后慎用" — mid-task, watching a forced `defect-diagnosis` load
land in the middle of a one-file bug fix.

Measured on 2026-09-20, which is why it is now off rather than discouraged:

| | |
| --- | --- |
| SKILL.md bodies | **1.00 MB** across 33 skills |
| all markdown | **9.25 MB / 598 files** |
| one owner | product-rd-workflow 75 KB ≈ 21K tokens; skill-extraction-workflow 114 KB |
| a typical delivery's routing | 5 owners (product-rd → worktree-isolation → testing-strategy → code-review → defect-diagnosis) ≈ **70K tokens of process prose before the first line of code is read** |
| hook surface | every Edit/Write, every Bash, every UserPromptSubmit, every Stop, SubagentStart/Stop, Compact |
| opt-out switch | **none** — `hooks/skill-loading.py` has no env or config escape; disabling the plugin is the only lever |

So `enabledPlugins["ccl-skills@ccl-skills"]` is `false` in
`~/.claude/settings.json`. **Settings are read at session start** (rule 7): the
session that flips it still has the hooks registered, and only the next one is
clean.

- Never invoke a `ccl-skills:*` skill on my own initiative — not for routing, not
  for review, not because a hook's text suggests it.
- Recall one **by name** for a genuine backend risk gate (money, permissions, data
  loss, migrations, a cross-repo contract): say "this is a risk class, I am
  loading feature-risk-router", re-enable if needed, load **that one**, and do not
  follow its routing into further loads or dispatches.
- If a hook checkpoint ever blocks an edit, load the one it names, once, continue,
  and say in the report that the load was forced — so a slow turn is not read as
  my choice.
- The hook checkpoint fires on the first source EDIT, so if the plugin is ever back
  on, finish the reading and the diagnosis BEFORE touching a file: by then the load
  buys nothing and can be answered in one pass.

**The honest accounting, and the reason this is not trading stability for speed.**
Rule 22's session ran the full ccl process and the deliverable was still wrong; the
canvas overlay class (rule 3) was closed by an independent review, not by a ccl
gate. The pack was never delivering the guarantee it was being paid for. What
replaces it costs a small fraction:

1. the repo's own gates — tsc, the whole suite, scoped eslint (the hardest of them);
2. **one** adversarial diff pass (a single subagent with a numbered checklist, or
   `/codex`) — Peter's review is the one that matters for UI;
3. mutation-checking every new assertion (rule 5 of the done table);
4. calling a changed route on the running app (rule 29);
5. the scope ledger (rule 30) for the half neither testing nor review ever covered.

**Do not spend more time configuring a gate than the gate can return.** In the
session that produced this skill I burned time on `review_gate.sh` plan schemas and
never got a single run to completion because HEAD kept moving. If a gate is not
returning value, say so and move on.

**Do not build a second lightweight process pack instead.** This skill already is
one. A second copy splits the source of truth and doubles the maintenance; the
only part of ccl-skills worth reproducing is the part that is not prose — a hook,
which is deterministic and costs nothing until it fires.

### 24. No headless-browser verification on Peter's dev server — hand him the test cases (Peter 2026-09-15)

Same session, one step later. After the cloud-doc editor replica I spent
two-plus hours driving it through headless Chrome on the shared `:3000`
(1–4 s per request, 60–90 s to open one pane, minted token expiring
unnoticed, waits on the wrong selector) and still did not reach the
interaction that crashed for Peter within ten seconds of clicking. Peter:
"目前先不要用无头浏览器去验证，相反可以将 test case 交给我，我去真实交互中去
测试，从而提升研发时间".

- For UI work in this repo: run tsc + scoped eslint + node tests, then STOP
  and hand Peter a numbered test-case list. Do not open a browser.
- Peter's second message on this (same day): "只有我要求你使用 devtools 或是
  无头浏览器测试时你再去做，你也可以向我申请这种操作，总之不要擅自去做这种重的
  测试任务". So: ANY heavy browser-driven testing — headless Chrome +
  puppeteer, the chrome-devtools MCP, gstack `/browse`/`/qa` — needs either
  his explicit request or my explicit ask ("这个缺陷我需要开浏览器复现，
  可以吗？") answered yes. Never on my own initiative, not even "just a
  quick screenshot". Applies to all his repos, not only moodio-agent.
- The list is the deliverable of the round, not an afterthought. Per case:
  the exact steps, the expected result stated as what he sees, and the
  prototype screen it mirrors. Group by feature; put the risky/unverified
  cases first and mark them so.
- Say in one line what the automated checks did NOT cover so he knows where
  to look hardest.
- This does not lift rule 2. It moves the visual verification to Peter by
  his choice — the report still says "browser: not verified by me".
- The headless route (`references/projects/moodio-agent.md`) stays on
  record for when he asks for it or when a defect needs a repro he cannot
  give.

### 25. Layer UI, interaction and backend so the prototype replica can be reshaped (Peter 2026-09-16)

Meegle 14294602, subtask 05 review. Peter, confirming the bios-in-outline
design: "你一定要把 UI 和 UX 隔离开，未来 UI 可能还会发生变化，另外一定要隔离
后端逻辑，后端逻辑相对变化少，但是 UI/UX 部分可能还会发生较大的变化，你先按照
原型去快速复刻，从而可以留下充足的时间进行后续的调整".

- Three layers, three homes: **backend** (save cores, routes, agent
  context — changes rarely, keep it free of any UI notion), **interaction
  logic** (what a click does: ordering, search, which row is active,
  version actions — pure modules under `lib/` and hooks, unit-tested),
  **UI** (the markup + CSS that copies the prototype — expected to be
  reshaped, so nothing else may depend on its structure).
- Replicate the prototype fast and 1:1 first (rule 22); the time saved is
  for the reshaping rounds that follow. A component that mixes fetches,
  state and prototype markup is the thing that makes those rounds slow.
- Concretely for a studio surface: pure logic in `lib/workstation/<x>.ts`,
  state + handlers in a hook or the surface, markup in the component;
  the server never learns a class name or a layout decision.
- And nothing the prototype or the requirement does not say (Peter, same
  day, on the document scaffolds I had seeded: "上来不需要给定默认的模版，
  原型和需求中都没有规定，你不要自己发散需求"). Where both are silent the
  default is the empty / minimal behaviour; a gap worth filling is an open
  question in the report, not a feature in the commit.
- **Small "helpful" additions count as drift too.** Same story, 2026-09-16
  (storyboard block): a 剧本 / 文档 kind tag on the chat's writing cards
  that the story never asked for ("使用户能区分剧本生成结果" was already met
  by the phase labels), and Peter: "你现在已经开始漂移了，没有的功能为什么要
  随便加". Before committing any element, name the prototype screen or the
  requirement sentence it comes from; if neither exists, it does not ship.
  When he says something is not in the prototype, check `git log
  --diff-filter=A` first: a thing that predates the branch is removed on
  his word without argument, and a thing that IS in the prototype (the
  分镜表's 「撤销删除」, `07-create-assets.js` `renderShotDeletionUndo`) is
  defended with the file and line, not conceded.
