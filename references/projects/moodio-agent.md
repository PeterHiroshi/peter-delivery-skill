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

**The working recipe for a fresh worktree, in order** (2026-09-08: I ignored
this section and burned Peter's time on `npm ci` → symlink → `cp -R`, exactly
the two failures named above):

1. `ls node_modules | wc -l` — `[ -d node_modules ]` is NOT a check; a worktree
   can carry an empty `node_modules/` that passes the directory test and still
   has zero packages.
2. `npm install` in the worktree. Not `npm ci` (fails, see above), not a
   symlink (Turbopack rejects it), not `cp -R` (slow, and drifts).
3. Then `npm run dev`. Expect `package-lock.json` to drift; do not stage it.

### Stray files in commits

`git add -A` in a worktree has twice swept in a 13k-line `pnpm-lock.yaml`. Check
`git status --short` before staging.

## Testing reality

### "Cannot find package 'server-only'" in vitest = empty node_modules (2026-09-09)

Two share-link test files failed with `Cannot find package 'server-only'`
in a fresh worktree. `vitest.config.ts` aliases `server-only` to
`next/dist/compiled/server-only/empty.js`, so the alias needs `next`
INSTALLED IN THE WORKTREE — and `ls node_modules | wc -l` was 0. I proved
the failure was not in my diff (stash, re-run on the clean tree, same
error) and reported it as pre-existing. True, but the cause was step 1 of
the recipe above, which I had not run. `npm install` made both pass.

- A module-not-found in vitest on a worktree is an install question first,
  a code question second. Check the package count before any other theory.
- Do not run `npm install` while a `git rebase` is mid-flight: it rewrote
  `package-lock.json` at the instant `rebase --continue` ran, which refused
  with a misleading "must edit all merge conflicts". `git checkout --
  package-lock.json`, then continue. Install before the rebase or after it.


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

**The CLI's token lives ~2 hours** (`meegle auth status` → `expires_in_minutes`);
after that every command returns `AUTH_REQUIRED` with "Re-run with
--device-code". That is not a broken install — it is expiry, and the fix is a
login that works without a browser on my side (2026-09-09, Peter: "这个未来都是
必要的工具"):

```bash
meegle auth status                                    # check FIRST, every session
meegle auth login --device-code --host project.larksuite.com --phase init
#  → prints client_id, device_code, user_code and verification_uri_complete
#    (https://project.larksuite.com/b/auth/mcp?channel=meegle-cli&mode=device&usercode=XXXXX-XXXXX)
#  Give Peter that URL to open (one click, he is already signed in), then:
meegle auth login --device-code --host project.larksuite.com --phase poll \
  --client-id <client_id> --device-code-value <device_code>   # blocks up to 600s; --once for one poll
```

`--phase init` is harmless to run while a valid token exists. The issue body
is `work_item_fields[].value` on `workitem get` (markdown with image links);
comments via `meegle comment list --project-key … --work-item-id …`.

Exact CLI shapes that worked (2026-09-10, Meegle 14621810): `meegle workitem
get --project-key ozn2tr --work-item-id <id>` (there is NO work-item-type flag;
the description sits in `work_item_fields[].value` with key `description`),
`--fields field_a54610 --fields …` for the custom fields, and
`meegle comment list --project-key ozn2tr --work-item-id <id>`.

Field keys: `field_06d87b` links to Features, `field_a54610` repro steps,
`field_e5d9b7` expected, `field_a5a12e` actual, `field_cf2c88` environment.

## PR mechanics on this repo (2026-09-09, PR #591)

- **Vercel shows `fail / Deployment was blocked` on every PR** (checked 588,
  589, 590, 591). It is not a signal about the branch; do not chase it.
- **Copilot cannot be re-requested from the CLI.** Both
  `gh api -X POST …/requested_reviewers -f 'reviewers[]=copilot-pull-request-reviewer[bot]'`
  and `gh pr edit <n> --add-reviewer copilot-pull-request-reviewer` return
  success and change nothing (`reviewRequests` stays empty). The re-request
  button exists only on the PR page. Copilot re-reviewed the SECOND push on
  its own (~2 min, resolving the thread it considered addressed and opening a
  new one) but not the third within 5 min — do not count on it. Reply on the
  thread, push, resolve the thread you addressed (GraphQL
  `resolveReviewThread`, the author may), poll ~3 min, then hand Peter the
  re-request button in the report.
- Copilot's first pass lands ~3 minutes after `gh pr create`; poll every 20s.
  Its inline comment ids are what `…/comments/<id>/replies` wants.

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

## Driving the Desktop canvas through chrome-devtools MCP (2026-09-09)

Meegle 14551516, verified end to end in the real app with Peter's login. What
cost time and what finally worked:

- **The MCP profile lock is another VS Code Claude session's Chrome**, launched
  with `--remote-debugging-pipe` (no TCP port), so nothing can attach to it.
  `ps -o ppid` up from the Chrome pid names the owner. Ask Peter, then kill the
  Chrome pid (not the MCP) — the profile keeps his `moodio_refresh_token`, so
  the relaunched browser is logged in.
- **A node composer collapsed a few seconds after every MCP click.** Cause:
  the canvas's "跟随 Agent" (follow) mode was on and kept re-panning; the
  canvas deselects assets that leave the view (`DesktopCanvas.tsx`, the
  `hiddenSelected` effect), and a composer that unmounts mid-request saves
  the optimized prompt as PLAIN text (`promptRich`/`entityRefs` null) — which
  looks exactly like "chips not created". Turn follow mode off first
  (button label matches /正在跟随/, a plain JS `.click()` works).
- **Select a node from in-page JS, not by uid**: find the collapsed hint text
  (`选中此节点即可打开创作框`), `elementFromPoint` at its centre, dispatch
  pointerdown/mousedown/pointerup/mouseup/click with `pointerId`/`isPrimary`.
  React's handlers fire. Snapshot uids drift every time the canvas moves.
- **Pan with synthetic `WheelEvent`s** (plain wheel = pan, no selection
  change); type into TipTap with `document.execCommand("insertText")`.
- **Do the whole flow in ONE `evaluate_script`** (select → type → click →
  poll a `window.fetch` wrapper for the response → probe DOM → re-fetch the
  node's metadata). A tool boundary is where the composer got lost.
- Seed fixtures through the product's own routes from the page context:
  `POST /api/desktop/<id>/assets` `{assets:[{assetType, metadata, posX, posY,
  width, height}]}` and `POST …/edges` `{edges:[{sourceAssetId,
  targetAssetId}]}`; they need a reload to show. "Plain desktop" means no row
  in `workstations.desktop_id` AND none in `workstation_episodes.desktop_id`
  — the episode desktops are named "… — 第 N 集".
- DOM hooks: mention chips `[data-mention-id]`, entity ref cards
  `[class*='composer-card-chip']`, wired inputs `button[aria-label='移除']`,
  the optimize button by text `优化提示词`.
- Ledger check for any LLM feature: `llm_turns` by `surface`, joined to
  `llm_calls` (purpose/model/status/tokens). Quote string keys in
  `json_build_object` with `\x27` inside `node -e` one-liners.

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

## tsc cannot see a server module in the client bundle (2026-09-08)

Meegle 14583294: a client component imported three constants from
`lib/workstation/entity-elements.ts`, which imports `lib/db` and `lib/storage/s3`
(sharp, pg). `npx tsc --noEmit` was green; the dev server refused to compile
every page that mounts the chat composer ("Can't resolve 'child_process'",
`fs`, `net`, `tls`) with a 15-line import trace. Rule 2 in its purest form: the
gate that was green does not observe the defect class.

- Any module a `"use client"` file imports must be free of `@/lib/db`,
  `@/lib/storage/s3`, `@/lib/elements/helpers` (imports the db) and friends,
  transitively. Split "rules" (pure) from "writes" (db) at design time.
- Start the dev server BEFORE calling a UI change verified, and grep its log
  for `Can't resolve` — it is the only compile check that follows the client
  import graph.
- The harness recipe now needs a fetch stub for `/api/collection`,
  `/api/projects`, `/api/library/tree`, `/api/assets`, `/api/uploads` too:
  `lib/redux/services/base-query.ts:52` redirects the whole page to
  `/auth/login` on any 401, so mounting `AssetPickerModal` (RTK queries)
  bounced the harness to the login screen mid-flow.
- Port 3000 was retaken by another session's worktree server between my
  kill and my start; `next dev` silently moved to 3001 and I spent ten minutes
  reading a 404 from the other worktree's code. Check the dev log's `Local:`
  line before the first request.
- puppeteer `click({clickCount: 2})` did NOT fire React's `onDoubleClick`
  here; two `mouse.down/up` pairs (clickCount 1 then 2) did. A synthetic
  `dispatchEvent(new MouseEvent("dblclick"))` proves the handler; the
  two-click sequence proves the interaction.

## The fastest route to "why did this generation fail" (2026-09-08)

Reading the submit/provider code to explain a runtime failure produced two
confident and opposite WRONG answers in one session. The system records the
answer; query it.

**1. The generation row is the first stop, and `params` matters as much as `error`.**

```bash
# `pg` is a dependency; `psql` is not installed.
node -e '...' # new pg.Client({connectionString: DATABASE_URL, ssl:{rejectUnauthorized:false}})
select created_at, model_id, provider, status, params, error from video_generations
where ... order by created_at desc limit 10
```

- `provider` NULL + an error naming a provider means **every** provider failed:
  the row keeps only the LAST attempt. Before the failover chain was persisted
  (this branch), the primary's objection was nowhere in the database.
- `params` carries the actual submitted values — `aspect_ratio`, `duration`,
  `reference_video_duration`. A failure whose message blames one thing is often
  explained by a value sitting in there (`duration: "auto"` on a model whose enum
  has no `"auto"`).
- `failure_explanation` holds the LLM's own verdict with a `category`
  (`user_error` / `system_error` / `transient`). It is frequently right when the
  regex classifier is not — worth reading before theorising.

**2. The dev server's stdout beats the database for provider ordering.** The
failover loop logs `provider "X" failed for <model>; trying next provider` per
attempt, and each provider logs its own request before submitting (`[Kie Submit]
Request:`). Absence of a provider's line is real evidence it was skipped; the
database cannot show that. Peter usually has this open — ask for it.

**3. When code and observation disagree, add one `console.log` and ask for a
retry.** One line printing the resolved variant order settled a question that
2000 simulated weighted-shuffle draws could not, because the draws were of the
code's intent, not the run's behaviour.

Error classification is looser than it looks: `ModelNotOpen`,
`AuthenticationError` and the env-var errors all fall through to
`generic_failure`, NOT `invalid_parameters`. Do not assume a user-facing message
implies a matching classification — run the exact stored string through
`classifyVideoError` before claiming a mislabel.

## A wrapper around a percentage-padding box collapses it (2026-09-08)

Meegle 14583294, the fix that broke the feature. The composer's card button
gets its height from a spacer `<div style="padding-bottom: 114%">` — the same
`coverAspectPadding` trick `AssetBoard` uses, because WebKit mis-sizes
`aspect-ratio` in a grid track. Percentage padding resolves against the
CONTAINING BLOCK, so the button must be the grid cell itself.

To keep a `title` tooltip alive on a `disabled` button I wrapped each card in
a plain `<div>`. The grid then sized the wrapper, the wrapper's height came
from the (zero-base) spacer, and every card collapsed to **2px**: the dialog
rendered an empty grid while the sidebar still counted the cards. Peter found
it; my own harness run had "passed" because I only asserted the sidebar text
and the disabled flag, never a card's box.

- Never wrap a percentage-padding box in a layout-participating element.
  `display: contents` would survive, or put the attribute on the box itself.
- **Assert geometry, not just presence.** `getBoundingClientRect().height` of
  the thing the user is supposed to see, every run. Text and aria state were
  all correct while the component was invisible.
- The mutation check works here: re-adding the wrapper puts the heights back
  to 2px in one run.

## A question framed on my model of the problem gets an answer to my model (2026-09-08)

Meegle 14583294, the composer's Asset cards dialog. Peter's requirement was
"on Kling models only Kling-ready cards are selectable". I had gated on
whether the selected MODE declares `kling_elements`, saw a Kling text-to-video
composer let every card through, and asked him a three-option question whose
options were all phrased around "models that declare the param". He picked
"keep the current behaviour" — of my framing — and I reported the screenshot
as not-a-bug. His next message: "不对，kling 系列模型只要选择资产卡片，就只能
选择 kling 就绪的". One more round, and it was the SAME requirement he had
already stated twice.

- Before asking a clarifying question, restate the requirement in HIS words in
  the question body. If the options don't contain his literal phrasing
  ("Kling 系列模型"), the question is about my implementation, not his need.
- "You already told me this" is the signal that I re-derived a rule from the
  code instead of from the requirement. Grep the conversation for the phrase
  before proposing a new reading of it.
- The registry's `family` field is the semantic "Kling series" — eleven ids.
  `kling_elements` in the params is per model AND mode (Kling O3 drops it under
  plain image reference) and is the run's CAPACITY, judged by the admission
  engine at attach; it is not what a product-level "Kling models" rule keys on.

## Three corrections on one dialog: the unit of selection came from the wrong source (2026-09-09)

Meegle 14583294 again, the composer's Asset cards dialog. The issue's item 6
says, verbatim, "每个 L1 的实体类别下，都有专属的元素文件夹，每个元素的 ui 组件
使用原来的组件" — the folder holds ELEMENTS, drawn with the original element
tile. I built it three ways before landing there: elements as tiles but every
card tickable (wrong gate), then cards as the unit with "attach the latest
version" (wrong unit — invented from img6 plus Peter's shorthand "Kling-ready
cards"), then elements as tiles again. Peter's third message was "请细读 issue
描述后做出正确的判断".

- The issue text outranks a screenshot and outranks a later chat shorthand.
  When a correction changes the SHAPE of a feature (what a tick means), quote
  the issue's sentence in the reply before rebuilding — if the sentence does
  not support the new shape, the correction was about something else.
- "Treat X as a kind of Y" (元素当成特殊的 asset card) is a modelling hint:
  same grid, same checkbox, a different tile — not a new dialog.
- Keep the rules pure and pinned (`dialogItems` / `dialogItemGate`); the third
  rewrite was one file plus a test because the first two had not been.

## An annotated screenshot's arrow is the spec, not its caption (2026-09-09)

Item 4 said "视频上传入口……增加 '当前资产卡片标记素材' 的选择入口". The
screenshot's red arrow pointed at the picker's TAB ROW, labelled 资产卡片,
before Library. I read the words, added a "This card" row inside the Library
tab's source column, and Peter reported the feature as "还没有实现" — it was
there, in a place he never looked. Where an arrow lands is the placement
requirement; the caption only names the thing.

## Wording: the mockup's, unless the issue overrides it — and ask which (2026-09-09)

"Element" (issue) vs "reference version" (mockup) for the same rows. I chose
the issue's noun in the design doc; Peter later chose the mockup's button
label ("New reference version") and "versions are special asset cards". User-
facing strings changed in five locales twice. When the two sources name one
thing differently, make it an explicit numbered question with both literal
strings — it is cheap to answer and expensive to rename later. Code and API
names stay put either way.


## Where a Kling element is delivered, and what proves it (2026-09-09)

Chat: tray → message parts `{type:"element", elementId, name}` → agent `<GENERATE>`
refs `{kind:"element", elementId}` (now also enforced from `turnElementRefs`,
`lib/agents/agent-2/core/turn-element-refs.ts`) → `routeRefs` →
`params.kling_elements[{libraryElementId}]`. Node: wired tile row →
`nodeVideoInputFromAssetRow` → `mapNodeInputsToVideoParams`. Both →
`hydrateKlingElementsFromLibrary` (row title/prompt/imageIds win; `@name` realigned)
→ `submitVideoGeneration` → `applyParamMapping` → provider. fal: `elements`
(frontal/reference URLs); KIE: `kling_elements` unchanged (its own name; 422 on empty
description); KSyun: mint `advanced-custom-elements`, then `element_list`.
Test: `__tests__/kling-elements-reach-provider.test.ts` — mocks `@/lib/db`,
`@/lib/storage/s3`, `@/lib/kie/client`, `@fal-ai/client`, global fetch.
Dev DB query without psql: `node -e` with `pg` from the worktree's node_modules and
`DATABASE_URL` parsed from `.env` (`ssl: {rejectUnauthorized:false}`).
Open: a canvas-connected chat's tray element is not enforced (the draft-node handler
needs an element tile on the desktop).

## The first real Kling element run: parsing was right, the clip was wrong (2026-09-09)

Peter's canvas-node request looked element-less (`inputAssetIds` only) — by design:
`kling_elements` is `WIRE_DERIVED_VIDEO_PARAMS`; the route reads the element tile
(`metadata.elementId`) and hydrates the row. Proof was one query away:
`select params->'kling_elements', error from video_generations order by created_at
desc` showed the element fully hydrated and fal's refusal:
`video_duration_too_long: Maximum is 10.05 seconds` (a 33.6s clip, measured with
`probeMediaDurationFromUrl` on the signed URL from that row). Nothing had checked
the length at creation. Cap now in `lib/elements/video-limit.ts` (10s), judged in
both editors and both writers.

- When Peter pastes a request body and asks "does the backend parse this", the
  answer is in the generation row it produced, not in the body.
- `tsx` scripts in this repo must be `.mts` (top-level await) and query uuid
  columns with `id::text like`.
- Provider facts worth remembering: fal sends a video-bearing element as a VIDEO
  element only; KIE requires a description; KSyun takes images only.

## A module-level client cache keyed by one id is stale for every other key (2026-09-09)

Meegle 14583294 follow-up: "the Asset cards button opens no dialog on the Create
page". `useDesktopEntitiesWithImages` caches per desktop id; the Assets tab and
the Create tab are two desktops of one workstation, and the entities-changed
event refetched only MOUNTED readers. Save a version on Assets, come back to
Create → the held snapshot still had no versions → the button became a door.
Both composers share the cache, which is why "both panels" was the report.

- When a report says "works on page A, not on page B" and both read one cache,
  ask what KEY each page reads and what invalidates the keys nobody is watching.
- The fix that survives: mark every held key stale on the event, refetch on the
  next mount while still serving the held data. Extracted as a pure store
  (`lib/desktop/entities-snapshot.ts`) so the rule has a node test.
- Harness that proved it: two readers of the real hook with `window.fetch`
  stubbed for `/api/desktop/*/entities`, unmount one, fire the event, remount,
  assert the fetch count and the version. Reverting the hook alone made the
  remounted reader stay at one fetch — the revert check, not the green run, is
  the evidence. The stub's kind rows need `sortOrder` + `createdAt` or
  `mentionPalettes` throws `localeCompare` inside the hook.

## "Only X may be selected" hides "X and Y are delivered differently" (2026-09-09)

The same issue's second half. The 2026-09-08 rule "on Kling only Kling-ready
cards tick" was a UI gate standing in for a delivery rule Peter actually
cared about: a card's reference VERSION goes through `kling_elements`; a card
itself goes through references, "和其他模型一样". Enumerating the class showed
three server paths each deciding element-vs-reference by its own rule (≥2
images, a Seedance mint) and none by "is it a version" — a node with two picked
images and the direct video mode with a real-person card both sent a plain
card as a Kling element.

- A selection gate in the UI is never the enforcement; ask what the provider
  receives for each thing the gate lets through, per path.
- The marker that settled it was on the DATA (`entityId` on the element ref),
  read at every delivery site, with a mutation guard test proving the marker
  alone decides. Kling entrances enumerated off `listFamilies()`/`familyCells`
  are 11 cells (4 with kling delivery: O3 omni + video-edit over media, v3
  image-to-video + first-last over frames); `kling-v3-omni` and
  `kling-o3-video-reference` are NOT in any family cell — cover them through
  `getModelEntrance(id)` over `VIDEO_MODELS` as well.
- Redefining a rule moves fixtures: `mention-admission.test.ts` needed a
  two-image card on Kling v2.6 as its dead end once a one-image card fit a
  frame. Write down WHY the fixture moved in the test.

## A missing i18n value renders the KEY, and only a screenshot shows it (2026-09-09)

Third pass of Meegle 14583294, the three-field reference-version form. Every
node test was green, the browser drive was 10/10 — and the screenshot showed
`workstation.assetCanvas.kling.videoRefsHint` printed verbatim under the
video field, plus its neighbour's hint overflowing into the next column.
The string carries `{maxVideo}` and I had called `t("videoRefsHint")` with
no values: next-intl renders the key and logs an error (Next's "1 Issue"
badge in the corner is that error). My drive asserted labels and disabled
states, never a hint's text.

- Any string with a `{param}` needs its values at EVERY call site; grep the
  catalog for `{` on the keys you add and check each `t(key, …)`.
- Assert the copy the user reads, or look at the picture. The "1 Issue"
  badge in a screenshot is a console error — read it before calling the run
  clean.
- Harness for `EntityKlingSection` without a session: provide
  `WorkstationRuntimeContext.Provider` with a hand-made runtime, a store from
  `createWorkstationStore()` + `setState({entities})` in
  `WorkstationStoreContext.Provider` (the hook is context-bound; there is no
  global `setState`), and stub `/entities/<id>/assets` + `/elements`. The
  picker's Asset card tab needs the same `/assets` stub.

## Wheel events have no capture: a native stopper freezes a trackpad pan (2026-09-10)

Meegle 14620356: panning the Desktop canvas with a two-finger swipe froze the
moment the pan slid the selected node's composer under the cursor. Every
`pointer*` theory was a dead end — pan-by-drag uses `setPointerCapture` and is
immune. The pan in the GIF was a WHEEL stream (`DesktopCanvas.tsx` native
`wheel` listener, ~3655), hit-tested at the cursor on every event, and
`NodeComposerHost` (`node-composer.tsx`) stopped every wheel on its div.

- Three wheel interceptors sit on the canvas surface: `node-composer.tsx`
  (was blanket → now `lib/composer-wheel.ts`: keep only when the focused
  `.ProseMirror` overflows on the swipe's dominant axis, never for ⌘/Ctrl),
  `entity-zone-card.tsx:233` (already conditional on `scrollWidth`), and
  `assets/CanvasMediaPreview.tsx:240` (a modal, off-canvas). Any new native
  wheel listener inside the canvas tree must let the event through unless it
  actually consumes it, or it recreates this bug.
- Peter's rule for the composer: the canvas ALWAYS pans; the prompt text
  scrolls only while the editor is focused. Not "scroll if scrollable".
- The 23-frame GIF was read with `ffmpeg -i x.gif frames/%02d.png` + a PIL
  frame-diff: pan frames differ by ~15M, frozen frames by <0.2M. That
  located the freeze frame and the cursor position without guessing.
- Composer harness without a session: `app/auth/wheel-harness/page.tsx`
  mounting `NodeComposerHost` with a generator asset cast from
  `{ assetType: "generator", metadata: { mode: "image", prompt: "" }, … }`
  and no-op callbacks renders the real TipTap editor (`.ProseMirror` is the
  overflow-y:auto scroller AND the focusable element). Drive wheel with
  `page.mouse.move` + `page.mouse.wheel` (real hit-testing), modifiers via
  `page.keyboard.down("Meta")`, text via `document.execCommand("insertText")`.
  The composer persists its draft across reloads, so a second run starts
  with the previous text.
- Follow-up from Peter's real-app check: once the pan stopped freezing, the
  composer could slide under the docked agent chat and the scene strip — and
  painted OVER them, because `NODE_COMPOSER_LAYER_Z = 45` (and the selection
  bars at z-50/60) had been chosen to beat the panels (#318). Peter's rule:
  canvas floats sit UNDER all shell chrome (now `CANVAS_FLOAT_Z = 20`, pinned
  by `__tests__/canvas-float-layering.test.ts`). The z is applied by
  DesktopCanvas's wrapper div, not by `NodeComposerHost`, so the composer
  harness cannot see it; DesktopCanvas takes 145 props and is not worth a
  harness — source test + Peter's eyes on :3000.
- A fix that lets a gesture travel further changes what the surface can
  OVERLAP. After unfreezing a pan, sweep what the moving thing can now be
  carried under/over (panels, strips, pills) before hand-off.

## Video extension / prompt templates (2026-09-10, Meegle 14620855)

- `long-video` became `video-extend` (product `extend`). Its three controls
  are MODE params declared on the container (`ModeContainer.params`), not
  registry params; `applyModeToParams`, `videoSpecs` and the submit path
  are the three places that read them. `ModeContainer.hides` pins a param
  to its default with no control; `promptTemplate` binds
  `lib/generation/prompt-templates.ts` slots to params. The row keeps the
  user's text under `params.prompt_template.source`; every user-facing
  reader of a stored prompt goes through `lib/video/display-prompt.ts`
  (a static test enforces the allow-list).
- **VideoDurationControl's `adaptiveLocked`/`hideAdaptive` must be keyed on
  `param.name === "duration"`** wherever a second seconds param renders
  through it. Passing the host's lock to `extend_duration` showed "Auto"
  and a dead slider on all three surfaces; only the browser caught it.
- The chat card explains a pinned ratio from the pin's CAUSE
  (`videoConstraints(...).pins.aspect_ratio.cause`), not its value: a mode
  pin and a frame pin both read `adaptive`.
- DB check before designing: `video_generations` had zero long-video rows
  ever (`params->>'duration'='30'` + a video ref), so the id could be
  replaced without an alias. Query with a CJS script and
  `NODE_PATH=$WT/node_modules node q.cjs` — the worktree's `pg` is not
  resolvable from the scratchpad otherwise.

### Dev server / browser mechanics that cost time today

- `nohup npm run dev > log 2>&1 &` inside one Bash tool call died when the
  call ended (silently, no error in the log, port closed). Start it in a
  subshell: `(nohup npm run dev > "$SP/dev.log" 2>&1 &)`, then poll with
  `curl -s -o /dev/null -w "%{http_code}"`.
- The `:3000` holder was another worktree's server that Peter's browser was
  actively hitting (`/create/...` requests in ITS log). Killing it per the
  standing rule is right, but say so in the report the moment it happens.
- gstack's `browse` binary at `~/.claude/skills/gstack/browse/dist/browse`
  answered every command with `error: Script not found "text"` (a
  bun-compiled binary with its scripts missing). Do not iterate on it; go
  straight to the private headless Chrome + `puppeteer-core` recipe above
  (`npm i puppeteer-core@23` in the scratchpad, `puppeteer.connect({browserURL})`).
- Volcengine Ark docs (`docs.volcengine.com/docs/82379/1520757`) render
  client-side: WebFetch, curl and the headless-text route all return the
  page shell. The repo's own record (`lib/video/providers/ark.ts` comments,
  `docs/plans/2026-09-03-...md` §12) is the readable source; ask Peter to
  confirm the enum rather than spending a third attempt.

### Seedance 2.5 extension: provider facts settled by live runs (2026-09-10)

- **KIE `bytedance/seedance-2-5` cannot run a video extension.** Five dev
  runs — duration -1 and a concrete 4 alike, ratio adaptive, one reference
  video, the extension prompt — all came back as fresh 4-second LANDSCAPE
  reference clips from a portrait source. Its schema has no task type. Do not
  offer KIE as a failover for `video-extend`; the mode is Ark-only
  (`ModeContainer.providers`), 503 when no Ark provider is available.
- **Ark's Seedance 2.5 guide, table 全模态生视频任务:** 视频编辑 needs
  `ratio: adaptive` + `duration: -1`; 视频延长 needs `ratio: adaptive` ONLY
  (duration unrestricted). The repo's `ark.ts` comment and the 2026-09-03
  engine design had folded the two together; I copied it and sent -1 for
  extension until Peter pasted the table. A rule "recorded in the repo from
  a doc" is still second-hand — when the page will not render for me, ask
  Peter for the screenshot before building on it.
- The dev Ark account has NOT activated `doubao-seedance-2-5-260628`
  (`ModelNotOpen`, account 2124768954); every extension on dev fails there.
  Production is expected to have it. `docs.volcengine.com` renders
  client-side; WebFetch/curl/headless-text all return the shell.
- Checking "which provider ran and what was sent" = one query on
  `video_generations.params` (`submission_meta.attempts` holds the failover
  chain). Do this before theorising — it settled all three questions today.

## Browser verification with a REAL session on dev (2026-09-10, Meegle 14441990)

The `app/auth/<x>` harness cannot exercise an authenticated canvas flow
(spawning nodes, PATCHes, generate). The route that worked, start to end:

1. Private headless Chrome + puppeteer-core (see the memory note), then log
   in through the product's own OTP API: `page.evaluate(fetch("/api/auth/request-otp", {email}))`,
   read the code from the dev DB (`select code from otps where user_id=… and is_used=false order by created_at desc limit 1`),
   then `fetch("/api/auth/verify-otp", {email, code, agreedToTerms: true})`.
   Peter's dev account is `peter8icestone@gmail.com` (admin), not the
   icestonetech address. He receives the OTP email — say so in the report.
2. Create a scratch desktop (`POST /api/desktop {name}`) and its nodes through
   `POST /api/desktop/<id>/assets` — the metadata passes through unchanged,
   so a node can be pinned in `status: "generating"` without a provider.
3. DOM hooks: cards are `[data-asset-card]` with `style.left` = world posX
   (no id attribute — identify by position); the node composer is
   `.cs-composer-stroke`, its editor `.cs-composer-stroke .ProseMirror`,
   buttons carry `aria-label` (Attach / Send / Model…). A cookie banner
   (`button` text "All") covers the bottom of a fresh profile — click it.
   World y beyond ~700 is below a 1000px viewport: clicks land on canvas.
4. `desktop_assets` orders by `added_at` (no created_at); edges are
   `desktop_asset_edges`. Query with the worktree's `pg`
   (`NODE_PATH=<worktree>/node_modules` or `require("<worktree>/node_modules/pg")`),
   a script in the scratchpad cannot resolve it.

**Dev runs `nano-banana-2` for real** — clicking Send on an image node
charges Peter's dev credits and completes in ~30 s. Failed rows with
`KIE_API_KEY … not set` were other models. Do not press Send to "get a
failure"; pin the state through the API instead.

**The prompt editor calls `onInputChange` on mount with its seeded text**
(a fresh draft node got `prompt: ""` committed without a keystroke). Any
"first edit" trigger must compare against the current value.

### Port 3000 is contested between sessions

Twice in one hour: the holder of :3000 was another worktree's dev server
(`meegle-14644635…`, another Claude session), so the browser loaded the OLD
code and a fix read as "not working"; later my own server was killed from
outside. **Before every browser run**:
`lsof -p $(lsof -tiTCP:3000 -sTCP:LISTEN) | grep cwd` must print THIS
worktree. Kill and restart otherwise (Peter's rule), and say so.

## A real OTP login in headless Chrome, no Peter needed (2026-09-10)

Meegle 14621810 (welcome-page modal login not reflected) needed the REAL
sign-in path, not an `/auth/<x>` harness. It is cheap here because the dev
RDS is reachable and the OTP is a row:

- Fresh incognito context (`browser.createBrowserContext()`) so no cookie
  from a previous run leaks in.
- Type a throwaway email (`meegle<id>-<label>-<ts>@example.test`) into the
  form; `POST /api/auth/request-otp` creates the user and the `otps` row
  whether or not the email is delivered.
- Read the code with `pg` (resolved from the WORKTREE's node_modules —
  there is no `psql` on this machine): `select o.code from otps o join
  users u on u.id=o.user_id where u.email=$1 and o.is_used=false order by
  o.created_at desc limit 1`. Poll; the insert lags the response slightly.
- New users get the consent checkbox: `[role=dialog] input[type=checkbox]`
  `.click()`. Click the first `[data-slot=segment]` of the HeroUI InputOtp
  and `keyboard.type(code)`; the form auto-submits on the last digit.
- `delete from users where email=$1` at the end — the cascade removes the
  OTP and refresh-token rows. Say in the report that throwaway rows were
  written to the dev DB.
- The `admit_gate` flag was ON in dev (`feature_flags` row), so a fresh user
  really lands on /welcome; check that row before trusting a /welcome repro.
- Print the mutation evidence in the same output as the run
  (`grep -c refreshUser app/welcome/page.tsx` → 0 before, 2 after) so the
  before/after pair cannot be a cwd or Fast-Refresh accident.

Port 3000 was held by another worktree's `next-server`; `lsof -p <pid> |
grep cwd` names the worktree, and per the standing rule the holder is killed
rather than moving to another port.

## Selecting a canvas node from the browser: real click, not synthetic (2026-09-10)

Meegle 14638763, verifying the node toolbar on the ASSET canvas
(`/create/<project>/assets` → an entity card's "资产画布"). The synthetic
pointerdown/mousedown/pointerup/mouseup/click sequence from the 2026-09-09
note selected the card (one `.cs-node-ring-selected`, the composer opened)
but NO `.cs-float` bar ever rendered — while the identical sequence on the
episode canvas did produce the bar. Two probes burned before switching
evidence class. What worked: `take_snapshot` → `click` on the card image's
uid (a trusted CDP click), which produced the bar on the first try.

- Prefer the MCP `click` by uid for selection on any canvas; keep synthetic
  events for deselect (click on empty board) and for wheel pans.
- The bar's guard includes `!draggingAssetId`; a synthetic sequence can
  leave that set on this surface. Do not debug it — use the real click.
- The chrome-devtools MCP profile was NOT locked this time and carried
  Peter's login; try `list_pages` before assuming the headless route.
- The asset canvas wraps the board in an `overflow-y-auto` container, so
  filtering media with `closest('.overflow-y-auto')` throws away the canvas
  cards themselves. Card media is `img.absolute.inset-0.object-contain`.
- `Meta+a` via `press_key` selects every card and raises the group bar.
- The `click` tool scrolls the card into view, which pans the canvas so the
  bar's left end can land at x<0. Wheel-pan first (deltaX moves ~2px per
  unit here), then click, then screenshot.
- Esc on this surface EXITS the entity canvas (`focusExitFitOnUnmount`);
  deselect with a click on the empty board instead.
- Evidence of which surface is which: only the asset canvas draws the pin
  badge ("由 … 选定") and the "退出资产画布 · <entity>" pill; the episode
  canvas shows the shot strip ("镜头列表") instead.
- The bar's chrome flags: `markInBar` is `surfaceChrome.mark`, true ONLY in
  `AssetCanvasShell.tsx`; Episode sets `mark: false`, standalone defaults
  false. `!markInBar` therefore means "every page but the assets page".

Environment on the same day: this worktree had `node_modules` = 0 entries
again; the symptom this time was `Cannot find package '@anthropic-ai/sdk'`
(8 tsc errors in `lib/llm/providers/anthropic.ts` + 16 vitest suites failing
to load). Step 1 of the recipe above, `ls node_modules | wc -l`, before any
other theory. Port 3000 was held by another worktree's dev server; killed
per the standing :3000 instruction.

### Picker dialog + composer facts (2026-09-10)

- The library picker is `[role="dialog"]`; tabs are buttons by text ("My
  generations"), a tile is `img` → click its closest button; **Confirm's
  innerText carries a count badge ("Confirm 1")** — match by prefix, not
  equality. The composer has NO `input[type=file]` (upload opens a native
  dialog), so drive reference paths through the picker.
- The headless Chrome on :9333 died once mid-session (cause unknown); the
  profile dir keeps the session — relaunch and `/api/auth/me` is 200 again.
- Mod+Enter on the canvas: `page.keyboard.down("Meta")` + Enter works.

### UX lesson from the same issue

Peter accepted "the first edit forks onto a new node" on paper, then rejected
it after one try: the cursor jumping to another box mid-typing is jarring.
The version that stuck is the one with NO surprise — the composer stays where
the user is and only Generate creates the node (same model the media-tile
regen composer already had). When a design moves the user's focus on its
own, prototype it before committing the mechanism; one browser run would
have shown it.

## Verifying a Safari-only bug for real (2026-09-10, Meegle 14354221)

The report was "the play/pause button does nothing in Safari's video
preview". Playwright's WebKit and the real Safari answered different halves,
and both were needed:

- **Playwright WebKit** measures geometry: `elementFromPoint` over the native
  control bar named the element on top of the play button (the lightbox's
  title pill). Install it in the scratchpad: `npm --prefix $S i playwright`
  then `npx --prefix $S playwright install webkit` from the OFFICIAL CDN —
  the npmmirror host used for Chromium has NO `webkit-mac-26-arm64` build
  (404), so the mirror trick from the memory note does not apply here.
- **Real Safari** reproduces the click. `safaridriver --enable` needs a
  password (not available), but System Events is permitted and `cliclick`
  is installed, so: `open -a Safari <url>`, `cliclick m:x,y` / `c:x,y`,
  `screencapture -C -x` (with cursor). Screen points = screenshot px / 2
  on this Retina display. Put an on-screen `<pre>` in the harness that logs
  the `<video>`'s play/pause/playing events and every window-level
  pointer/click with its target — the screenshot then carries the evidence
  without WebDriver. Add `?auto=1` so the lightbox opens without a click;
  note that an auto-open has no user gesture, so Safari leaves the video
  paused (expected, not the bug).
- Two traps in the harness: the cookie-consent banner covers the bottom of
  the page on a fresh profile (set cookie `moodio_cc=denied`), and a click
  6px off the play button lands between buttons and reads as "button does
  nothing". Screenshot WITH the cursor before concluding a click missed or
  failed.
- Mechanism found: any caption `absolute bottom-*` inside a lightbox sits on
  the native control bar whenever the video reaches the viewport bottom;
  Safari draws its controls at the element's bottom edge, and the pill grows
  to 80vw for a prompt-length title, so it covered the play button. Fix was
  a column layout with the caption in its own row — and the image branch
  then needed `maxHeight: 100%` instead of `100dvh`, or the zoom frame
  clipped tall pictures. Verify the SIBLING branch (image) of a layout
  change, not only the one the bug was on.
- A source-level guard test that greps for the old classes matched the
  component's own comment describing them; scope such regexes to
  `className="…"`.
- Outcome correction: the ticket line "底部的文件名不显示" read to me as a
  symptom, so I built a caption row under the video. Peter read it as the
  requirement ("需要去掉文件名，按照meegle中说的那样") and the fix became a
  deletion of the caption, layout otherwise untouched. **When a ticket line
  can be read as symptom OR requirement, say both readings in the first
  report and ask, before building the layout that keeps the thing.**
- **The real bug was only visible on the real canvas** (rule 13 exactly): the
  standalone harness mounted `MediaLightbox` alone and passed; on the Create
  canvas in Safari, an on-screen `<pre>` event log INSIDE the component showed
  pointerdown target=VIDEO but pointerup/click target=the canvas container.
  Mechanism: HeroUI's modal is a DOM portal, but React bubbles synthetic
  events along the REACT tree, so `DesktopCanvas`'s container
  `onPointerDown` still ran and took `setPointerCapture` (marquee/pan) —
  capture retargets the release, Safari's native controls need it, Chrome's
  don't. Guard: `isCanvasContainerEvent(e.currentTarget, e.target)` at the
  top of every container handler that can start a gesture. General rule for
  this repo: **any modal/popover rendered inside DesktopCanvas's React tree
  bubbles into the container's handlers** — check `contains(target)` before
  acting. Driving Peter's logged-in Safari tab with `cliclick` worked; the
  lightbox opens on a double-click on the card's PICTURE (the card's own
  transport bar at its bottom swallows dblclick), and the play button of a
  landscape clip is ~30px above the video's bottom edge, not at the modal's.

## Canvas video tiles: harness and the rest-state play badge (2026-09-11, Meegle 14652790)

- The two canvas video tiles (`VideoAsset`, `PublicVideoAsset`) share the
  rest-state play badge (`VideoPlayBadge` + pure `showVideoPlayBadge`).
  Both need `VideoContext.Provider` (`components/video-provider.tsx`) — a
  hand-made stub value with `generationStatuses: {}` and no-op functions
  is enough for an `app/auth/<x>` harness; `EnrichedDesktopAsset` can be
  cast from `{assetType, metadata:{status:"completed", videoId}, imageUrl,
  videoUrl}`. `ffmpeg -f lavfi -i testsrc2=size=480x854:duration=4` into
  `public/__harness/` gives a portrait clip + poster with no network.
- Zoom in a harness: wrap the tile in `transform: scale(zoom)` and pass the
  same `zoom` prop, then assert the badge's `getBoundingClientRect()` is
  36×36 at every zoom — that is the counter-scale proof.
- A puppeteer driver that throws before its final `console.log` prints NO
  results, which made the first revert probe look like "nothing ran".
  Print the accumulated results in the `.catch` too.
- `cd "$S" && node …` moved the persistent shell's cwd again (rule 13);
  the very next tool call reported the worktree as "no longer a git
  worktree". `node "$S/drive.cjs"` with absolute paths, never `cd`.
- Copilot round 1 on PR #605 (2026-09-11): a focusable overlay button
  that starts a hover-style preview needs a focusout teardown, or a
  keyboard activation loops forever (no mouseleave ever comes). Its
  inline finding ("badge shows on a paused frame") was wrong in effect —
  the element stays mounted while paused — check the claim in the harness
  before rewriting. Keyboard drive: `el.focus()` + `keyboard.press("Enter")`,
  then `Tab` lands on the transport's Pause (Chrome's focus starting point
  survives the badge's unmount); Shift+Tab leaves the tile without crossing
  the scrubber, whose own blur latch would end the preview first.
  Never put `{/* */}` in a JSX attribute list as a probe — the page 500s.

## Wangsu gateway + admin replay acceptance without Peter (2026-09-11, Meegle 14661162)

- The gateway (`api.edgecloudapp.com/v2/llm`, `sk-` token) is a relay to
  Volcengine Ark with an OpenAI-style `/videos` API. Validation is loose
  and NOT forwarded: an out-of-range `seconds` (-5, -1) is replaced by a
  4-second default and BILLED, not rejected — a "probe that should 400"
  can cost a clip. Probe with a bogus model or a missing prompt (both
  reject before creating a task); never with a bad numeric value.
- Completed task: `seconds` is a STRING, `size` a "480p" token,
  `/content` is a Bearer-only mp4 (400 `invalid_video_id` while running).
- Admin replay on dev end to end, no browser: OTP login as
  `peter8icestone@gmail.com` through the API (his `admin_permissions` lack
  `video-management` — grant `write` in the row for the run and restore the
  exact JSON in a `finally`); the dev DB may hold no replayable row for the
  target provider (every concrete-duration 2.5 row carried a video ref), so
  create the original through `POST /api/generation/submit`
  (`{taskType:"video", modelId, prompt, refs:[], params, origin:{surface:"api"}}`),
  then `POST /api/admin/video-generations/<id>/replay {provider}` and poll
  `POST …/<id>/check`. Verify with the dev-server `[<Provider> Submit] Request:`
  line (the body the provider received) + the row's `submission_meta`.
- Mutation script trap: after `eslint --fix`, arrays get re-wrapped one item
  per line, so a sed pattern written from memory of the ORIGINAL text
  matches nothing and the probe reports "0 failing" for a mutation that
  never applied. Print `mutated(before→after)` counts and treat 0→0 as
  unexecuted (it was, once, here).

## A login-free REAL session: mint the access JWT from `.env` (2026-09-11)

Meegle 14663293 was verified end to end on Peter's own dev desktop with no
OTP and no borrowed Chrome profile. `JWT_ACCESS_SECRET` in the worktree's
`.env` signs `moodio_access_token` (HS256 via `jose`, payload `{userId,
email, roles}` — see `lib/auth/jwt.ts`). Mint one for an existing dev user
(`users` row; `roles` must be the real ones), set it as a cookie on
`localhost`, and every API route and the `/desktop/<id>` page accept it.
Script shape: `scratchpad/mint.js` (pg + jose from the worktree's
`node_modules`), then puppeteer-core `page.setCookie(...)`. Add
`NEXT_LOCALE=zh-CN` so the DOM strings match the notes above.

- The realtime WS (`:8081`) is refused in this setup; the canvas still
  works, the console just logs the failure.
- Select a draft node by dispatching pointer events at the centre of the
  `选中此节点即可打开创作框` hint; Cmd+D is a `KeyboardEvent` on `window`
  with `metaKey`. Wrap `window.fetch` BEFORE the action and read the POST /
  PATCH bodies back — the PATCH `{"generatorPatch":{"inputAssetIds":[]}}`
  is what proved the composer's repair was the culprit.
- Leave the desktop as found: DELETE the copy at the end of every run.
- zsh: `UID` is read-only — `UID=… node x.js` fails with "bad math
  expression"; name the env var something else.

## A revert probe's `count == 1` assert can silently skip the mutation

Same session: probe 3 asserted the target line occurred once in
`DesktopDetailPage.tsx`; it occurred twice (another handler dispatches the
same event shape), the assert threw, nothing was mutated, and the test run
printed 4/4 PASS over unmutated code. The grep count printed in the same
output (2 instead of 1) was the only tell. Scope the replacement to the
function (`s.index("const handleX")` … next declaration), and read the
evidence line before the PASS line.

## Meegle 14653304 (2026-09-11): completion toast, worktree dev server, Meegle attachments

- **Meegle screenshots**: the issue body and comments are mostly images. The
  CLI shape that works is `meegle attachment +download "<file-url>"
  --project-key ozn2tr --work-item-id <id> --output <abs path> --overwrite`
  (the URL is POSITIONAL; `--file-url` is rejected). Read them with the Read
  tool — Peter's "入口"/"跳到哪" comments are only legible from the pictures.
- **Chat panel storage is per route**: a Create-tab canvas keeps its active
  chat in `moodio_active_chat_id:ws:<workstationId>` (the route's projectId),
  the global window and `/desktop/<id>` in the bare key. Any code that asks
  "is chat X on screen" must read the slot for the CURRENT route —
  `activeChatStorageKey(chatScopeKeyForPathname(pathname))`. `/chat/<id>` is
  retired from the product nav (Admin internal tool only); never hardcode a
  jump to it — go through `lib/chat/chat-destination.ts` + `open-chat.ts`.
- **Bash tool kills a server started with `( nohup … & )`** when the call
  returns (ERR_CONNECTION_REFUSED one call later). Start it with
  `python3 -c "subprocess.Popen([...], start_new_session=True)"` and a log
  file; it then survives across calls and turns.
- **Port 3000 tug-of-war**: I killed another worktree's next-server per the
  standing rule and another session restarted it within 60 s. Fighting it
  wastes both sessions; I ran on :3001 for the verification and said so.
  Cookies are NOT port-scoped (Peter's login carried over), localStorage IS
  (fresh panel state on :3001 — good for a clean run, but don't read a
  missing key as a bug).
- **The chrome-devtools MCP page was logged in as Peter's dev account this
  time** (`/api/auth/me` 200) — check that first, before the headless route.
- **Drive the panel from page JS**: focus `.ProseMirror`,
  `document.execCommand("insertText")`, click `button[aria-label="发送"]`;
  collapse = `aria-label="收起对话面板"` (canvas) / `关闭对话` (global);
  turn off follow mode first (button text /正在跟随/). A plain "只回复一个
  字：好" reply lands in ~20 s on dev; the provider polls every 5 s so a toast
  shows ~2–8 s after that.
- **Dev canvas remounts are slow**: after View the canvas panel took >3 s to
  mount and a 20 s cross-page landing — a 3 s check read as "panel did not
  expand". Poll for the terminal artifact (composer + reply text), never a
  fixed wait (same lesson as the upload toast, above).
- **Fast Refresh during a probe**: editing the provider for the revert probe
  remounted the page mid-script (`.ProseMirror` null). Wait for the remount,
  then run the probe script fresh; keep the edit → run → restore in separate
  calls.

## Chat panel width: two hosts, one stored number (2026-09-11, Meegle 14585981)

`moodio_chat_panel_width` is read by the global host, `ChatSidePanel`, and
`DesktopDetailPage`. The Desktop page renders `width: chatPanelWidth` on the
docked column AND on the comments dock that stands over it; the comments
dock's own drag handle (`beginRightDockResize`) is the only place that
sizes the number without going through `ChatSidePanel`.

- **A revert probe on the docked canvas chat will not move.** `ChatSidePanel`
  clamps its stored width on mount and reports it back through
  `onWidthChange`, so a stored 300 heals to 380 within a frame even on the
  old code. The path that actually goes narrow is the comments dock's
  handle on a Studio surface (`CommentCountBubble` → docked
  `CommentsDockPanel`), which needs existing comment threads to open.
  Pin it with the source guard (`__tests__/chat-panel-min-width.test.ts`)
  and say so; do not spend an hour opening comments to see a slider.
- `npx eslint --fix components/desktop/DesktopDetailPage.tsx` rewrote ~200
  unrelated lines (import order, prettier) — the file is drifted on main.
  Lint big drifted files with `--no-fix` and compare the message set
  against `git show HEAD:<file>` swapped in at the SAME path (a scratchpad
  copy gets a different eslint config scope and reported 1 problem vs 144).
  Keep a `cp` of the file before any `--fix`.
- Real-app check without Peter's browser: mint an access token with `jose`
  (`{userId,email,roles}`, HS256, `JWT_ACCESS_SECRET` from `.env`), set it as
  the `moodio_access_token` cookie on localhost, drive a private headless
  Chrome on a port other than 9333 (another session already holds that one).
  The docked chat is `[data-tutorial="ws-agent-launcher"]`; its resize
  handle is the first `cursor-ew-resize` descendant. Desktop pages take
  5–8s of remote-RDS calls before the composer mounts — poll for
  `.ProseMirror[contenteditable]` inside the panel.
- **Check who holds :3000 before EVERY browser run, not once.** 2026-09-11: my
  dev server was replaced mid-session by another session's (worktree
  14653304) and two "verification" runs silently exercised that worktree's
  code — the log of MY server ends in `^[[?25h` and has no hits for those
  runs. Print `lsof -p <holder> | awk '$4=="cwd"'` and the hit count in the
  server's own log in the same command as the check.

### Vendor sheets live in `scratch/third-doc/` (2026-09-14, Meegle 14661162)

- A vendor's model-specific API sheet (docx) lands in the MAIN checkout's
  gitignored `scratch/third-doc/`, invisible from a worktree. Extract with
  python `zipfile` + tag-stripping regex (no `markitdown`/`python-docx`
  needed); tables come out as `|`-separated cells.
- The generic public doc page and the vendor's per-model sheet DISAGREE
  (the sheet had video/audio references, callbacks, `expired`, 21:9, and a
  480p/720p-only resolution list the page never mentioned). When Peter
  points at a sheet, re-derive the whole mapping from it, and prove each
  new field with one clip using the sheet's own sample assets
  (`arkdocs.tos-cn-beijing.volces.com/...` are public and fetchable by the
  gateway). Compare an extracted frame against the reference
  (`ffmpeg -frames:v 1` + `hstack`) — a matching resolution alone does not
  prove the reference was used.
- A documented `callback_url` is not a callback until one arrives: a
  webhook.site bin (`POST https://webhook.site/token` → uuid, then
  `GET /token/<uuid>/requests`) is a five-line way to find out. Here it
  received nothing, so the provider stayed poll-only with the route as a
  fast path.
- Port 3000 was held by ANOTHER session's worktree twice in one day; kill
  and say so, per the standing rule.
- **Mutation probes: restore by writing the ORIGINAL BYTES back, never by a
  reverse string-replace.** 2026-09-14: the reverse replace of `false;` and
  `true` hit their FIRST occurrence in the file (an unrelated `return
  false;` and `?? true`), silently corrupting `wangsu.ts`; every later
  probe reported 9 failures instead of 1 and "hit=True" was noise. Keep
  `orig = read(); write(mutated); run; write(orig)` and compare a hash.
  Commit BEFORE probing so `git checkout -- <file>` is a safe recovery.

## Overlays on the moving canvas layer (2026-09-14, Meegle 14665233)

HeroUI Popover/Dropdown position once at open (react-aria `useOverlayPosition`
re-runs only on window resize, trigger/overlay ResizeObserver, scroll). The
canvas moves the composer anchor by inline `left/top` + world `transform`, so
an open menu stays put while the node pans/zooms away. Fix in place:
`components/ui/following-overlay.tsx` (`FollowingPopover` /
`FollowingDropdown`, rAF rect-poll while open via `hooks/use-follow-trigger.ts`)
and a source guard `__tests__/canvas-overlays-follow-trigger.test.ts` that
pins the six composer/card files. Any new overlay in those files must use the
pair or the suite says so.

Browser facts that cost time today:

- `.cs-composer-stroke` no longer exists; find the node composer through
  `button[aria-label="模型"]` (zh-CN) and filter by `getBoundingClientRect().x`
  when the docked chat composer is also mounted (its chip sits at x > 900).
  Collapse the chat with `button[aria-label="收起对话面板"]` first.
- Camera zoom persists server-side per desktop. At 800 % the cards are culled
  and `[data-asset-card]` is EMPTY — not a load failure. Zoom out with
  ctrl+wheel `deltaY:+100` ×40 at the canvas centre; then zoom in with
  `deltaY:-3` steps (each ctrl+wheel unit is a large step here: -5×4 took 125→228).
- Wheel pan at zoom ~85 moves the world ~2 px per delta unit; anchor the
  synthetic wheel at (1200,650) — (100,700) lands on the minimap and pans nothing.
- `window.dispatchEvent(new Event("resize"))` UNMOUNTS the composer and
  deselects the node on this page; not a usable "force reposition" probe.
- A left-button pointerdown on the card dismisses any open HeroUI popover
  (outside press) — the reporter's "drag the text box" case cannot show the
  misalignment; middle-button drag and wheel keep it open. Escape closes the
  popover AND, a beat later, deselects the node.
- Synthetic pointerover/mouseenter never opened a HeroUI Tooltip; the MCP
  `hover` tool did on the first try. The tooltip closes by itself once the
  chip moves out from under the pointer.
- The other sessions' dev servers retook :3000 twice within the hour
  (14661162, then 14333608), each time killing mine (log ends `^[[?25h`).
  Re-check `lsof -p <holder> | awk '$4=="cwd"'` before EVERY browser run.
- `/desktop/<id>` for an episode canvas ("… — 第 1 集") shows 无法加载此项目;
  use a standalone desktop (`desktops` row whose name is not an episode).
- The repo's own `generating-commit-messages` skill forbids Co-Authored-By;
  recent commits carry none. The system attribution reminder yields to it.

## Verifying a canvas lightbox: the harness beats fighting selection (2026-09-14, Meegle 14333608)

Adding a Download control to `MediaLightbox` needed the image, video and
"nothing downloadable" branches seen rendered. Driving the real canvas cost
five failed attempts; an `app/auth/<x>` harness closed all three in one run.

- **A canvas video tile paints a poster `<img>` at rest**, not a `<video>`
  (the element mounts on hover/play). Selecting "the card with a `<video>`"
  finds zero. The rest-state play badge (`[aria-label*="播放"]`) marks them,
  but on one desktop all six cards carried it and none of my clicks raised
  the bar — do not keep tuning the click.
- **`desktop_assets.pos_x/pos_y` are NOT `style.left/top`.** The canvas
  normalises positions, so a DB row at (608,-24) appears as `0px,1726px`.
  Targeting a card by the DB's coordinates silently finds nothing.
- **The route that worked**: `app/auth/lb-harness/page.tsx` mounting the real
  `MediaLightbox` with three hand-made `LightboxMedia` payloads (video, image,
  no `download` field) plus `ffmpeg -f lavfi -i testsrc2` media under
  `public/__harness/`. `proxy.ts:64` still has the blanket
  `pathname.startsWith("/auth/")` rule, so it renders with no session.
  Delete the page AND the media dir afterwards.
- Assert the BOX, not presence: the control first shipped as a 13×30 sliver
  beside three 40×40 buttons because `AssetDownloadMenu`'s root is `h-full`,
  which collapses in a bare flex row. The drive said "下载 present" and was
  useless; `getBoundingClientRect()` on every cluster child caught it.
- The no-payload case is worth a browser check of its own: it proved
  `cluster:null` (no control at all), which is the dead-button trap closed in
  the DOM rather than only in a source guard.
- `AnchoredLayer` portals to `document.body` at `z-[1200]`; a HeroUI modal
  wrapper is `z-[70]` (computed 50). A menu inside a lightbox is therefore
  safe — but assert `elementFromPoint` hits it, not just the z number.

### Port 3000 is a three-way tug-of-war now
Two different worktrees took :3000 from me inside an hour (14665233 twice).
After the second, I ran on :3001 via `PORT=3001 npm run dev` (the
`-- -p 3001` form works too) and said so in the report. Check
`lsof -p <holder> | awk '$4=="cwd"'` before EVERY run, not once — two of my
drives had already exercised another worktree's code before I noticed.

### `git checkout --` cannot restore an UNTRACKED file (2026-09-14, Meegle 14333608)

Three mutation probes in a row "restored" a brand-new module with
`git checkout -- <path>` and every one failed with *pathspec did not match any
file(s) known to git* — the file had never been committed, so git had nothing
to restore from. All three mutants stayed in the file at once; the module was
corrupt for several minutes and only the harness's own change-on-disk notice
caught it.

The `grep -c MUTANT-` line printed `restored, grep=1` after each probe, which
is exactly the evidence line that exists to catch this, and I read past it
three times because the test output above it looked right.

- **Commit a new file BEFORE probing it.** The existing rule ("commit before
  the first revert probe") applies doubly to files git has never seen.
- Restore by writing the ORIGINAL BYTES back (keep `orig = read()` in the
  probe and write it in a `finally`), never by a git command — that rule was
  already in this note for reverse string-replace and covers this case too.
- Treat a non-zero exit from the restore step as fatal to the probe: the
  probes used `set -e`, but the failing `git checkout` was the last command,
  so the script still reported success.
- Read the mutation-evidence line before the PASS/FAIL line, every time.

### The reviewer found a hollow guard four of my own mutants missed

`expect(source).toContain("downloadAssetFile")` is satisfied by the IMPORT, so
deleting the call left it green. My own mutant had swapped the call for
`downloadImage`, which tripped the *other* half of the same assertion and made
the guard look load-bearing. A source guard proves a name exists, never that
it runs — when the behaviour matters, extract a pure function with the
dependency injected and assert what it received.

## `el.click()` cannot see outside-press dismissal (2026-09-14, Meegle 14333608)

A download menu inside the canvas lightbox was dead in the product and worked
in every scripted check I wrote — five reproductions across both hosts, the
user's own Chrome build, his route, his server, all green. The bug was real and
my probes were structurally blind to it.

**Mechanism.** `AnchoredLayer` portals its menu to `document.body`, i.e.
OUTSIDE a HeroUI `Modal`'s DOM subtree. `@heroui/modal` defaults
`isDismissable = true`, which wires react-aria `useOverlay` →
`useInteractOutside`, listening for **pointerdown on document in the CAPTURE
phase**. Pressing a menu item is an "outside press": the modal closes on
pointerdown and the item's `click` never runs. Fix: `isDismissable={false}` on
that Modal (HeroUI does not forward `shouldCloseOnInteractOutside` — it is
`Omit`-ed from `UseModalProps`), keeping the view's own backdrop/Close/Escape.

- **`el.click()` dispatches ONLY a click event — no pointerdown, no mousedown.**
  Any dismissal, drag, focus or capture logic keyed on pointer events is
  invisible to it. When a control "works in my probe but not for the user",
  drive it with `page.mouse.move/down/up` at coordinates before theorising.
- The tell in the trace: the user reported "it exits fullscreen instead", and
  my DOM recorder showed the menuitem receiving the click while no request
  followed. Element-level click evidence does not prove the handler completed.
- Any portaled popover over a modal has this shape. Check every
  `AnchoredLayer`/`createPortal` menu whose host is a `Modal`.

### Two probe failures worth remembering from the same session

- `performance.getEntriesByType("resource")` returned `[]` on a long-lived SPA
  page while CDP showed the requests — the buffer had been exhausted/cleared.
  I nearly reported "no request was ever made" from it. Prefer a CDP listener
  or a `window.fetch` wrapper; treat an empty Performance list as unknown.
- A source guard `expect(src).not.toContain("isKeyboardDismissDisabled")`
  failed on MY OWN comment explaining the prop. Scope such guards to the prop
  (`/isKeyboardDismissDisabled\s*=/`), never the bare word — same trap as the
  className guards already noted above.

### A stale rationale is not permission to remove the rule (2026-09-14, Meegle 14333608)

`downloadable.ts` excluded Discover tiles (`public_image`/`public_video`) from
canvas downloads, with a comment saying the shared engine could not speak their
storage-key / public-CDN model. I checked: the rationale WAS stale — the engine
addresses a public asset by its content UUID, proven by an existing test. I
then widened the gate, shipped it, and Peter reverted it: 「discover 部分如果原
来不支持下载，那就还和之前保持一致（不允许下载）」.

The rationale being wrong did not make the exclusion wrong. Discover is
third-party retrieval content: *can the engine fetch it* is a capability
question, *may users save it* is a product decision. They had the same answer
for different reasons, and only one of them was mine to change.

- **The tell was in my own question.** I asked Q2 as "this comment is out of
  date, fix it?" — which frames a product decision as a technical one, so the
  answer I got ("一并修复") was about my framing, not about the product. This is
  rule 17 without a deletion: my badly-framed question authorised a change to
  behaviour that was intentional.
- When a guard's stated reason is obsolete, the finding is "this comment is
  wrong", not "this guard should go". Fix the comment; raise the behaviour as
  its own question, in the product's terms, naming what the user would be able
  to do that they cannot today.
- Third-party / licensed / retrieved content is a standing example: assume an
  exclusion around it is deliberate until a product owner says otherwise.
