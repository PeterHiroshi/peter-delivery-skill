# moodio-agent — hard-won specifics

Complements `CLAUDE.md` (read that first). This holds what cost time to learn
and is not written down there.

## Environment traps

### Worktrees: the design prototype is invisible

There are ~14 active worktrees under `.work/worktrees/`. A hook blocks direct
edits to the main checkout.

**`scratch/` is gitignored**, so anything there — including the design prototype
`scratch/demos/Moodio 3.0 Standalone (1).html` — **does not exist inside a
worktree**. I once concluded a design file was missing when it was simply not
visible from where I was standing.

When Peter references a path that is not there: look in the main checkout at
`/Users/mahao/Develop/projs/moodio/moodio-agent/`, and if still not found,
**ask** (trigger 1 of the ask rule).

### npm, never pnpm

`package-lock.json` is the lockfile. Running `pnpm install` in a worktree
produces a partial `node_modules` (77 entries vs ~650) plus a stray
`pnpm-lock.yaml`, and that partial tree **shadows** the root install. Symptoms:
`Can't resolve '@tiptap/pm/state'`, phantom duplicate-package tsc errors,
Turbopack "Could not find the Next.js package".

Also: `npm ci` fails because `package-lock.json` is out of sync with
`package.json` (missing esbuild platform binaries) — pre-existing on main. Use
`npm install`.

**Do not symlink a worktree's `node_modules` to the root.** Turbopack treats the
worktree as a hermetic root and will not follow it, and a subsequent `npm
install` writes *through* the link and pollutes the main checkout.

Before improvising an environment fix: **ask** (trigger 3).

### Stray files in commits

`git add -A` in a worktree has twice swept in a 13k-line `pnpm-lock.yaml`. Check
`git status --short` before staging.

## Testing reality

- Node-only vitest, **no jsdom/RTL** (`CLAUDE.md:20`). Render bugs have no
  automated home. See `testing-that-earns-its-keep.md`.
- `__tests__/generation-rules/` is a **named CI job**, deliberately redundant
  with the full suite so a broken rule fails a check named for it. Exact CI
  command:
  ```
  npx vitest run __tests__/generation-rules __tests__/kie-kling-frames.test.ts
  ```
- Pre-existing lint errors exist (two `setState`-in-effect in
  `node-composer.tsx`). Verify against the untouched baseline before calling
  anything pre-existing — Peter will ask for evidence.
- `next build` can surface what tsc misses. Worth running before a PR.

## The composer: two surfaces, one component

Both render through `ChatInput` → `GenerationConfigBar` → `VideoModeParams`:

- **agent** — chat panel, `variant="agent"`
- **node** — canvas generation node, `variant="node"`

**A bug reported on one surface must be checked on both.** This is the single
most productive habit in this repo.

### The mode/generationType trap

The agent composer selects video through **`generationType`**, leaving
`menuState.mode` at its default. A strict `menuState.mode === "video"` check is
**always false** on the agent surface.

Use `videoWorkflowActive`, which covers both. `chat-input.tsx` documents this
trap in a comment near line 529 — and I still wrote the strict check.

### Legitimate divergence (only two)

- **QUANTITY** — agent only; `videoQuantity` is consumed solely by Agent-2
- **Adaptive duration switch** — node only; Agent-2 sets `duration: "auto"`
  itself

A test pins exactly two `isNode` branches. A third is drift.

## Video model registry

`lib/video/models.ts` (~4.3k lines) is a **module-level constant** — no DB, no
per-user data, identical for everyone, changes only on deploy.

- The client can import it directly. `GET /api/video/models` used to be fetched
  on every panel mount by components that **already imported the same module**.
- **Provider variants disable params.** `kling-v3-pro` runs on KIE (drops
  `negative_prompt`, `cfg_scale`); its FAL variant drops `multi_shots` instead.
  `getEffectiveParams` resolves this via a lazy `require("./provider-config")`
  that **a browser bundle cannot satisfy**, silently falling back to unfiltered
  params. Import `provider-config` for its registration side effect on any
  client path that needs the real list.
- **Never mutate enum values** — admin pricing formulas are free text over raw
  values (`resolution == '1080p' ? 1.5 : 1`) and Kling's `mode` picks the FAL
  endpoint. Localize display only, via `useVideoParamLabels`.
- Multi-shot: only `kling-o3-reference` and `kling-v3-pro` declare
  `multi_shots`. The v2.6 family has none — absence there is correct.

## The mode engine boundary

`lib/generation/*` — containers, product modes, admission, input probe, and the
**shared client/server entrance validator**. A UI task must not touch it. Say so
explicitly in the PR; Peter checks.

## i18n

Five locales: `en`, `zh-CN`, `zh-TW`, `ja`, `ko`. Missing keys fall back to
English silently, so a missing translation is invisible until a user sees it.

- **Edit message JSON line-by-line, never rewrite the whole file.** A
  round-trip through `json.dump` reflows formatting and once silently deleted an
  unrelated blank line. Verify with `git diff --stat` — the count should be
  exactly what you added.
- **Check whether a key already exists before adding one.** `multi_shots` was
  already translated in all five locales; `video.durationLabel` /
  `.aspectRatio` / `.resolution` / `.audio` already existed as the short section
  names.
- **Reuse the semantically right key, not any key that renders.** Borrowing
  `menu.imageQuantity` put "Amount" — the image chips' wording — on a video
  panel section that should read QUANTITY.
- `__tests__/generation-rules/i18n-mode-copy.test.ts` enforces key parity and
  that Chinese catalogs are not English placeholders.

## Meegle

CLI is `meegle` (not `meegle-cli`). Space `ozn2tr` = `6a7b389acc3b9c910ee856fe`
("Moodio 3.0"). Bugs are `issue`; template `1553817` (普通缺陷). The
`FeishuProjectMcp` MCP tools return `UserDisabled` — use the CLI.

Field keys: `field_06d87b` links to Features, `field_a54610` repro steps,
`field_e5d9b7` expected, `field_a5a12e` actual, `field_cf2c88` environment.

## Files that defeat grep (2026-09-07)

`components/ui/mention-textbox/MentionTextbox.tsx` contains non-UTF-8 bytes, so
`file` reports it as `data` and **plain `grep` returns nothing and exits
silently** — no error, no match. That cost a wrong conclusion ("this file has no
suggestion implementation, it must live elsewhere") until `head -c` showed the
imports were right there.

- Use `grep -a` on any file where a confident grep comes back empty.
- Read it with `python3 -c "open(p,'rb').read().decode('utf-8','replace')"`.
- Edit it in **bytes** (`open(p,'rb')` / `replace` / `open(p,'wb')`), never a
  whole-file text rewrite, or the odd bytes are destroyed. Check `file <path>`
  still reports `data` and `git diff --stat` shows only your lines.

This is the concrete form of "a search that misses is not proof of absence."

## The generation mode engine: measure, never reason about caps

Three times in one session I predicted a mode's behaviour from the model name
and was wrong; each time a throwaway vitest that printed a matrix corrected me
in under a minute.

- **Kling v2.6 has ONE frame slot** (KIE disables the end frame), so a single
  image fills it. **Kling v3 has first + last**, so it takes two. Predicting
  "v2.6 refuses, v3 deadlocks" was backwards.
- A fresh `@entity` mention contributes the entity's **first image only** (the
  default pick), not every published image. A prediction computed over all of
  them greys out things the UI correctly allows.
- An element is counted per FAMILY, not per model: `familyElementDelivery`
  returns slot / flatten / none, and only the flatten families tear it into
  images.

Write the probe (`__tests__/zz*.test.ts`, `writeFileSync` to `/tmp` because
vitest swallows console.log on pass) and delete it after. State the matrix, not
the intuition — and when the browser disagrees with the prediction, check the
prediction first.

## The remote DB is slow enough to fake a bug (2026-09-07)

Uploading a file through the canvas asset picker took **10–15 seconds** end to
end against the dev RDS: presign → S3 PUT → confirm → create asset → wire →
toast. I checked the result after ~4 seconds, saw no toast and no wire, and
reported a "silent refusal" defect. Waiting the full time showed the toast
firing correctly and the video correctly left unwired.

- Before calling an async UI path broken, **poll until the terminal artifact
  appears** (the canvas card, the toast, the row), not once after a fixed wait.
- Watch toasts with a `MutationObserver` installed BEFORE the action; a toast
  that came and went is invisible to a later DOM query, which is the other way
  this looks like a silent failure.
- Distinguish "did not happen" from "has not happened yet." Peter's report
  named the upload tab specifically, and picking from the library worked — that
  asymmetry was a timing difference, not a code-path difference.

Related trap on the same canvas: state left over from BEFORE a fix does not
disappear. A video wired into an image node under the old code is still wired
after the fix, still renders as an unused input, and reads exactly like the bug
recurring. Check when the offending row was written before treating a
reproduction as current.

## Two views of the script, one chip mark (2026-09-08)

`ScriptReader` (read view) and `ScriptLineEditor` (TipTap) draw the SAME
`cs-entity` mark and are deliberately pixel-identical, and `CollabDocBody`
swaps one for the other on a line click. So "the control stopped working" on
a script surface is very often **not** a dead handler — it is the other view.

- The reader's chips are `EntityHoverCard` popover triggers.
- The editor's are ProseMirror decorations / mention nodes with **no React
  tree**, so they cannot host a popover and had no click at all.
- A chip nested in the reader's `<p onClick>` fired BOTH: opened the card and
  started an edit session, which unmounted the trigger. That was Meegle
  14558542.

**Check which view is mounted before believing a click is lost.** The tell in
a screenshot: the kind toolbar (场景标题/动作描述/角色…) and 保存 are the
editor; a caret sitting *inside* a highlight is the editor too.

### Measuring it in the browser

`document.querySelector('.ProseMirror')` is a **bad** editor probe on this
page — the cover/logline fields are ProseMirror too, so it is truthy before
any edit starts. I read that as "the editor mounted" and briefly believed my
own fix had failed. Use instead:

- `chip.closest('.ProseMirror')` — is THIS chip in an editor?
- the ProseMirror **count** (1 = idle chrome, 2 = script body editing)
- `document.body.innerText.includes('场景标题')` for the kind toolbar

Same session, same shape: a synthetic `Escape` on `document` does not reach
the editor's ProseMirror keymap, so it looked like my card had swallowed the
editor's "done" key. Dispatch on the editor element. **When a browser probe
disagrees with the code, suspect the probe first.**

### Seeding a script to test entity chips

Dev accounts here have workstations with entities but **empty scripts**, so
no chips render. Seed one:
`PATCH /api/workstation/<id>/script` with `{content, contentDoc:null,
baseContentUpdatedAt:null}` whose text contains the entity names verbatim —
the read view's live name matcher makes the chips. Routes are plural
(`/entities`, `/episodes`); `/entity` and `/episode` 404 into `[]`, which
reads as "no data" rather than "wrong URL".

### npm install rewrites package-lock.json

`npm install` in a fresh worktree drifted `package-lock.json` by 473 lines
that had nothing to do with the change. `git checkout -- package-lock.json`
before staging — this is the concrete form of the "stray files in commits"
trap above.

## Verifying rendered UI without a login (2026-09-08)

The chrome-devtools MCP profile is usually locked by another session's Chrome,
and there is no dev login short of OTP against the shared RDS. What worked for
the onboarding-guide v2 pass, end to end, with screenshots of every beat:

- Launch a private headless Chrome (`--headless=new --user-data-dir=<scratch>
  --remote-debugging-port=9333 "--remote-allow-origins=*"`) and drive it with
  `puppeteer-core` installed in the scratchpad.
- `proxy.ts` treats every path under `/auth/` as public. A throwaway
  `app/auth/<x>/page.tsx` that mounts the real component with in-code config
  renders with all providers and no session. Delete it before committing.
- Locale is the `NEXT_LOCALE` cookie; dark mode is `localStorage.theme`
  (next-themes with `attribute: "class"` — setting `.dark` by hand is undone).
- Start the dev server detached with a log file. `npm run dev | head -200`
  killed the server with SIGPIPE halfway through a run.
- No repo edits while a browser run is in flight: Fast Refresh remounts the
  component and a scripted flow restarts from the top, which looks like a bug.
- A worktree can pass tsc/vitest with an empty `node_modules` (Node resolves
  up to the main checkout); Turbopack cannot. `npm install` there, then
  `git checkout package-lock.json`.

Also: `npm run dev` in a worktree re-adds the "This is NOT the Next.js you
know" block to CLAUDE.md; that diff is expected noise.

## Measure a proposed fix against the whole catalog BEFORE coding (2026-09-08)

Meegle 14583245: the adaptive-duration switch was dead on a canvas node dragged
out of a video asset. Root cause was a three-valued field the UI shows as two —
`videoGenerationMode` is `""` for a node whose mode was never picked, which
`locateModel` resolves to the model's default for DISPLAY while every
mode-keyed decision reads the raw `""` as "no mode".

Peter approved a plan (option A) that a ten-line script then proved wrong, in
two separate ways:

- Sending the displayed mode as `modeId` on submit regressed **11 of 14**
  visible models — a fresh node could no longer run plain text-to-video, because
  attaching a mode attaches a mask and `applyMask` only intersects.
- Resolving the mode on the display side ALONE made the client lie about
  billing: the switch would work, the user picks 7s, and the server (still
  receiving a null mode id) coerces to `"auto"` and bills adaptive. A dead
  control is an annoyance; a control that silently changes billing is a money
  bug.
- The obvious fallback (seed the default mode at node creation) regressed
  **14 of 17** — the same narrowing, moved earlier.

What actually worked was letting auto-flow persist the mode it had ALREADY
decided was correct, gated on that mode being `selectable` for the current
inputs: 44 write cases, **0** admission regressions, measured the same way.

Lessons that generalize past this repo:

- In a model/mode/capability matrix, **never reason about a fix from one
  model.** Write the throwaway script that runs every model x every input shape
  and prints the diverging rows. Each of the three rejected variants looked
  correct in prose and died in under a minute of enumeration.
- When a control's state also PREDICTS a server decision (billing, admission),
  the client and server must be judged with the same inputs. Ask "what does the
  server see for this exact node?" before changing what the client shows.
- A sentinel like `""` that one code path resolves and another reads raw is the
  defect, not the symptom. Grep every consumer; here only 3 of ~10 call sites
  resolved it, and `lib/desktop/node-inputs.ts` had already documented the rule
  ("resolve the mode the way every other surface does") that the others missed.
- `nextModeAfterChange` returns `null` for two opposite reasons — "stay, this is
  legal" and "nothing legal exists". Overloaded returns like this are where a
  plausible fix quietly hardens a broken state.

Mutation testing earned its keep again: a test asserting the omni relaxation
stays off for `video-edit` passed for the wrong reason (the product check
already excluded it, so the clause under test never ran). Two mutants survived
before the assertions were re-aimed at the clauses that actually decide. One
clause (`pins.duration === undefined` on an omni container) is currently
unreachable — no container is both omni and duration-pinning — so no test can
kill it; say that rather than writing a test that pretends to cover it.

## Onboarding guide admin: "not verified" is not a disclosure, it is a gap (2026-09-08)

The admin page (`app/(dashboard)/admin/onboarding-guide/page.tsx`) needs a
session, so the no-login harness cannot render it. I added a derived-content
note for the Editor scene, reported it as "not verified, tsc only", and moved
on. Peter opened the admin and there was no Editor scene at all: the page
groups nodes by `stage` nodes, but the tutorial enters the editor through the
`edit-tab` hotspot, so the scene never existed. The note could never show.
One extra review round for Peter.

What to do instead: any page-level logic I cannot render gets **extracted into
a pure function and tested against the shipped config** (now
`lib/onboarding-guide/admin-scenes.ts` + its test). "Tsc only" on view logic
that decides *whether something appears* is no evidence — the types were fine
and the scene was still missing. Before writing "not verified", ask whether a
15-line extraction would make it verifiable; it usually would.

Also from the same day: port 3000 was retaken by another session's worktree
twice, and after killing it Next refused to start because `.next/dev/lock`
still named my dead server — `rm .next/dev/lock` and restart. The RDS host
also failed DNS for a few minutes (`ENOTFOUND` in the dev log); it cleared on
its own, so re-check before concluding the DB is down.

## "Not my change" is a verdict, not the end of the search (2026-09-08)

While fixing 14583245, Peter asked why the agent panel had no Adaptive
switch. I traced `hideAdaptive={!isNode}`, confirmed it predated my commit,
explained it, and stopped. He came back: the aspect-ratio `adaptive` option was
missing too. It is the SAME flag, in the same file, twelve lines away —
`hideAdaptive` both skips the duration switch and filters `"auto"`/`"adaptive"`
out of every enum dropdown.

Establishing that a symptom is not your regression answers the blame question,
not the scope question. When a flag or condition explains one reported symptom,
enumerate every consumer of that flag before replying — this is rule 3 applied
to a shared flag rather than to a UI surface, and it is easy to skip precisely
because the "is it mine?" answer feels like a conclusion.

Also worth keeping: before pushing, check whether the base branch moved under
you and whether it touched YOUR files. Here `main` had gained a large Agent-mode
PR that also modified `chat-input.tsx`. `git merge-tree` said no textual
conflict, but the honest check was merging into a scratch worktree and re-running
tsc plus the full suite there (436 files / 5536 tests) — and re-verifying the
SEMANTIC premise, that `videoWorkflowActive` still covers the agent composer, so
the fix reaches that panel too. A clean merge is not the same as a still-correct
change.

## The prototype's Composer is not in the prototype (2026-09-08)

Meegle 14583294: the issue's screenshots mixed three sources — the mockup
`Standalone (2).html` (the asset Details panel's `Kling O3 / 3.0 adaptation`
block, search `klSetList` / `klPick`), a real build (`Omni reference`,
`Type a message…`), and a designer drawing of a composer "Asset cards" dialog
that exists in **no** file. The mockup's Composer is a `<dc-import
name="Composer">` whose template is not embedded; grepping the file for
composer copy (`Make a card Kling-ready`, `ASSET TYPE`) returns 0 and that is
not proof the dialog was never designed — say which screenshot has no source
and design from the screenshot, flagged.

Also from that session:

- A local branch `feat/kling-element-entry-points` (2026-09-04, never pushed)
  holds a spec + plan for the same feature and two liftable files
  (`components/chat/element-tile.tsx`, `lib/video/element-support.ts`). Check
  `git branch -a` for `feat/*` siblings before designing from scratch.
- `lib/elements/hydrate.ts` admits a `libraryElementId` only when
  `projects.userId === userId` (5 sites). Workstation collaborators cannot
  generate with any library element, minted ones included — a 400 at submit.
- Every `element_details` rewrite goes through `buildElementDetails`, which
  drops unknown keys (`hydrate.ts:541,614`, `elements/[id]/route.ts:315`).
  A tag stored there must be carried explicitly at each writer.
- `meegle` CLI: `workitem get --project-key 6a7b389acc3b9c910ee856fe
  --work-item-id <id>`; attachments via `attachment +download "<url>"
  --project-key … --work-item-id … --output <path>` (positional URL, not
  `--file-url`). Comments: `comment list`.
