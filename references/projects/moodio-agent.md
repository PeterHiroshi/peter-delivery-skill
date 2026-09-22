# moodio-agent — hard-won specifics

Complements `CLAUDE.md` (read that first). This holds what cost time to learn
and is not written down there.

## Index — grep the heading, read that section only

This file is append-only and long. **Do not read it whole** (rule 32). Find the
symptom below, then `grep -n "^## <heading>"` and read from there to the next
`^## `. A new section here gets a row here in the same commit.

**Environment & dev server**

- `Environment traps`
- `Testing reality` — incl. running the `*-postgres` suites locally (CI runs them, local skips them)
- `Files that defeat grep (2026-09-07)`
- `The remote DB is slow enough to fake a bug (2026-09-07)`
- Other sessions kill every `next dev` — and the toast race (2026-09-14, Meegle 14653304 round 2)
- `The minted token dies after 2 h, and :3000 is shared with Peter (2026-09-15, cloud-doc editor)`
- `Performance constants for the dev environment (2026-09-18, Meegle 14294602)`
- `Next 16 refuses a second dev server in the same directory (2026-09-20)`
- `An unauthenticated probe never reaches a route (2026-09-21, Meegle 14956503)`
- `Recording API fixtures from a running dev server (2026-09-22, moodio-agent-flash)`

**Getting a real browser / session on this app**

- `Verifying rendered UI without a login (2026-09-08)`
- `Driving the Desktop canvas through chrome-devtools MCP (2026-09-09)`
- `Browser verification with a REAL session on dev (2026-09-10, Meegle 14441990)`
- `A real OTP login in headless Chrome, no Peter needed (2026-09-10)`
- `Selecting a canvas node from the browser: real click, not synthetic (2026-09-10)`
- `Verifying a Safari-only bug for real (2026-09-10, Meegle 14354221)`
- `Canvas video tiles: harness and the rest-state play badge (2026-09-11, Meegle 14652790)`
- `Wangsu gateway + admin replay acceptance without Peter (2026-09-11, Meegle 14661162)`
- A login-free REAL session: mint the access JWT from `.env` (2026-09-11)
- A revert probe's `count == 1` assert can silently skip the mutation
- `Verifying a canvas lightbox: the harness beats fighting selection (2026-09-14, Meegle 14333608)`
- `el.click()` cannot see outside-press dismissal (2026-09-14, Meegle 14333608)
- `A source guard cannot see DOM structure (2026-09-14, Meegle 14665402)`
- `Measure the bug screenshot instead of squinting at it (2026-09-20)`

- `Reusing a pipeline inherits its vocabulary (2026-09-20, Meegle 14732749)`
**The composer, canvas and overlays**

- `The composer: two surfaces, one component`
- `The mode engine boundary`
- `Two views of the script, one chip mark (2026-09-08)`
- `The prototype's Composer is not in the prototype (2026-09-08)`
- `A wrapper around a percentage-padding box collapses it (2026-09-08)`
- `Three corrections on one dialog: the unit of selection came from the wrong source (2026-09-09)`
- `Wheel events have no capture: a native stopper freezes a trackpad pan (2026-09-10)`
- `Chat panel width: two hosts, one stored number (2026-09-11, Meegle 14585981)`
- `Overlays on the moving canvas layer (2026-09-14, Meegle 14665233)`
- `Node composer notices and the false "prompt changed elsewhere" (2026-09-14, Meegle 14737690)`
- `Capture frames menu (2026-09-14, Meegle 14452515, PR #634)`
- `Upload placeholders on the canvas: one status word, three tiles (2026-09-14, Meegle 14742436)`
- `Reorder strips: the end gap has no drop target (2026-09-20, Meegle 14744969)`
- `Unit frames on the grid: who places member cells (2026-09-22, Meegle 14993494)`
- `A signed media URL changes on every response (2026-09-21, Meegle 14980874)`
- `A dblclick under a container capture never arrives (2026-09-21, Meegle 14989382)`

**Generation, models and providers**

- `Video model registry`
- `The generation mode engine: measure, never reason about caps`
- `Measure a proposed fix against the whole catalog BEFORE coding (2026-09-08)`
- `The fastest route to "why did this generation fail" (2026-09-08)`
- `Where a Kling element is delivered, and what proves it (2026-09-09)`
- `The first real Kling element run: parsing was right, the clip was wrong (2026-09-09)`
- `"Only X may be selected" hides "X and Y are delivered differently" (2026-09-09)`
- `Video extension / prompt templates (2026-09-10, Meegle 14620855)`

**i18n, copy and specs**

- `i18n`
- `An annotated screenshot's arrow is the spec, not its caption (2026-09-09)`
- `Wording: the mockup's, unless the issue overrides it — and ask which (2026-09-09)`
- `A missing i18n value renders the KEY, and only a screenshot shows it (2026-09-09)`

**Data, routes and caches**

- `tsc cannot see a server module in the client bundle (2026-09-08)`
- `A module-level client cache keyed by one id is stale for every other key (2026-09-09)`
- `A route's imports are load-bearing (2026-09-18)`
- `Only the script PAGE fetches the script — every other surface reads a null (2026-09-19)`

**Process on this repo**

- `Meegle`
- `PR mechanics on this repo (2026-09-09, PR #591)`
- `Onboarding guide admin: "not verified" is not a disclosure, it is a gap (2026-09-08)`
- `"Not my change" is a verdict, not the end of the search (2026-09-08)`
- `A question framed on my model of the problem gets an answer to my model (2026-09-08)`
- `Meegle 14653304 (2026-09-11): completion toast, worktree dev server, Meegle attachments`
- `Script studio import + driving the chat composer (2026-09-15, Meegle 14294602 sub-02)`
- `Long-lived feature branches here take main by MERGE, not rebase (2026-09-19)`

---
## Environment traps

### Worktrees: the design prototype is invisible

There are ~14 active worktrees under `.work/worktrees/`. A hook blocks direct
edits to the main checkout.

**A new worktree goes under its branch type** (Peter, 2026-09-20):
`.work/worktrees/fix/meegle-<id>-<slug>`, `.work/worktrees/feat/...` — no longer
flat in the root. The older flat directories stay where they are; nothing is
moved. `/peter-delivery:append-worktree` is pinned to this (`NAMING=full` in
`.git/peter-delivery-worktree.conf`, which is local to the clone). If that file
is lost the script falls back to voting on the directories that exist, and the
flat majority would win — re-pin with `--naming full` once.

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

### Local green ≠ CI green: the `*-postgres.test.ts` suites skip without a DB (2026-09-22, PR #778)

CI runs `npx vitest run` with `CANVAS_GENERATION_TEST_DATABASE_URL` set (a
postgres service), so every `__tests__/*-postgres.test.ts` suite RUNS there and
SKIPS locally (`describe.skipIf(!connectionString)`). PR #778 reported "all
tests pass" locally while CI failed 6 of them: the suite builds its own schema
by hand and lacked a column the PR added. Run them locally the CI way:

```
docker run -d --rm --name pg-test -e POSTGRES_USER=canvas_test \
  -e POSTGRES_PASSWORD=canvas_test -e POSTGRES_DB=canvas_test \
  -p 55432:5432 postgres:16-alpine
CANVAS_GENERATION_TEST_DATABASE_URL=postgresql://canvas_test:canvas_test@127.0.0.1:55432/canvas_test \
  npx vitest run --exclude '**/llm-integration*'
```

- A schema change must also land in every postgres suite's hand-built DDL —
  apply the migration file itself (`readFileSync("migrations/NNNN_…sql")`),
  as the deletion suite does, rather than retyping columns.
- To test a module whose inserts/`execute` go through `@/lib/db`, mock it with
  a Proxy onto a real drizzle instance (`__tests__/entity-group-zones-postgres.test.ts`)
  — the older `adapter.select/update/transaction` mock lacks insert/delete/execute.
- Real SQL is the only instrument for a read-time data conversion or a
  relative (`pos + dx`) update race: `Promise.all([heal(), heal(), heal()])`
  against the container proved the advisory lock (mutant: no lock → double move).

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
- The repo's own `generating-commit-messages` skill text forbids Co-Authored-By,
  but practice disagrees: on 2026-09-14 ALL of the last 10 commits on `main`
  carried the trailer (squash merges keep it). Match practice — keep the
  trailer, do not rewrite pushed history over it. PR bodies end with the
  `🤖 Generated with Claude Code` line (#626, #634).

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

## A source guard cannot see DOM structure (2026-09-14, Meegle 14665402)

The rename entrance itself was small — `enableRename` beside `enableManage` on
`asset-picker-unified-tree.tsx`, one prop on `destination-picker-modal.tsx`.
What cost the time was four rounds of the SAME hollow-guard shape in one test
file, each found by a reviewer rather than by me:

1. `key: "rename"` counts stayed identical when the branch that builds the menu
   was flipped to `: false` — the row is still *written*, just unreachable.
2. `expect(picker).toMatch(/enableRename\b/)` passes on `enableRename={false}`.
3. Action-key counts cannot see WHICH branch selects them: flipping a level's
   selector to `!enableManage` hands a destination row the full menu, Delete
   included, with every count unchanged.
4. The worst one. Told to fix a click-away bug, I replaced `TreeRenameRow`'s
   400 ms blur window with `rowRef.current?.contains(event.relatedTarget)`,
   wrote three mutants, killed all three — and the fix was broken. The ⋮
   trigger is a **sibling** of `TreeRenameRow`, and `{!renaming && manage && …}`
   unmounts it the moment renaming starts, so focus restoration can never land
   inside the row: the absorption never fires and the first blur commits and
   closes the editor. I had shipped the bug the window existed to prevent.

The rule: **a source guard proves a name exists and which text selects it; it
can never prove the DOM case it targets can occur.** Before writing a guard
about focus, containment, or event bubbling, read the JSX that renders the two
elements and establish their real relationship (`{cond && <X/>}` next to
`{cond ? <Y/> : …}` means sibling, and means unmounted). My three mutants all
edited the discrimination's text, so they tested my typing, not the mechanism.

Also from this session, the ask-vs-assume trap in its purest form: I claimed in
a commit message, a PR body, a design doc and a report to Peter that "no surface
mounts the filesystem-history provider, so dialog renames are not undoable."
The grep behind it searched `LibraryFilesystemProvider`, which does not exist —
the real name is `LibraryFilesystemHistoryProvider`, mounted on four route
layouts. Copilot caught it. A zero-hit grep is not proof of absence; grep the
EXPORTED name from the module (`grep "^export function" <file>`) before turning
a miss into a positive claim.

- `review_gate.sh` shapes that cost time: the plan's `evidence` rows are
  `{id, result}` objects only, `self_review` rows are
  `{concern, conclusion, evidence_refs}` keyed on the ids from
  `--print-required-concerns --stage <stage>` (build = correctness, safety,
  failure_paths, tests_evidence, compatibility, claim_strength), and a widened
  `--diff-file` packet must BEGIN byte-for-byte with `git diff base...HEAD` —
  appending an uncommitted diff into the middle returns `invalid_input`.
  Two runs in a row can return `invalid_model_output`; that is reviewer-side and
  is never "no findings".
- `meegle comment add` (not `create`); `--project-key` is required.

## Node composer notices and the false "prompt changed elsewhere" (2026-09-14, Meegle 14737690)

- **`.cs-composer-stroke` is only on the WORLD node composer.** The image /
  video node composer's card has no such class; select its host with
  `div[role="presentation"][style*="will-change"]` (NodeComposerHost) and
  the editor with `… .ProseMirror`. Three driver runs timed out on the
  wrong selector while `.cs-node-ring-selected` = 1 said selection worked —
  read the diag counts before blaming the click.
- A CDP `page.mouse.click` on the node's `选中此节点即可打开创作框` hint
  selects a draft node on `/desktop/<id>` first try; `page.keyboard.type`
  reaches the editor once `pm.contains(document.activeElement)` is true
  (click at x+20 of the ProseMirror rect, then `.focus()` as fallback).
- **Why the conflict notice shows while typing alone**: `handleGeneratorCommit`
  applies the patch via `applyRemoteEvent` BEFORE the PATCH; the draft's
  base advances only in `acknowledgeNodePromptSave`; `decideNodePromptDraft`
  compares draft vs the echoed node vs the old base → `conflict: true` for
  the request's length (measured 2.7–3.5 s, once 15 s, on dev). Own save +
  continued typing = false conflict. The fix on this ticket only moved the
  notice (canvas top-center slot); the detector is unchanged.
- The canvas's top-center slot (`topCenterSlotStyle`) is now ONE
  `flex-col` container: connect hint | zone pill, then the conflict notice.
  Add further top notices as children of that column, not as a second
  positioned slot (a test pins exactly one `style={topCenterSlotStyle}`).
- Port 3000 was retaken by another worktree's session within minutes of my
  kill, and my server died during a run (`fetch failed` mid-probe → the
  throwaway desktop was NOT deleted). Next `npm run dev` auto-bound :3001.
  Keep a `cleanup.cjs` that lists `probe-<ticket>-*` desktops and deletes
  them, and run it after every failed probe; do not assume the driver's
  own `finally` reached the server.
- A python patch that asserts an occurrence count and aborts leaves the
  driver UNCHANGED, and the next run silently exercises the old script —
  the only tell was the old selector still in the error text. Print the
  replaced count and `node --check` in the same command as the run.

## Capture frames menu (2026-09-14, Meegle 14452515, PR #634)

- **Gates on the MERGED tree without touching the branch**: `MT=$(git
  merge-tree --write-tree origin/main HEAD)`, `MC=$(git commit-tree $MT -p HEAD
  -p origin/main -m scratch)`, `git worktree add --detach .work/worktrees/zz-x
  $MC`, then `npm install` THERE before tsc/vitest. Without the install the
  scratch resolves `node_modules` upward to the main checkout, which lacked
  `@anthropic-ai/sdk` → 8 tsc errors + 26 suites failing to load, identical on
  `origin/main` alone. The control run (same env, base only) is what proved it
  was environment; the install (651 pkgs, ~10 s) is what proved the merge green.
  `git worktree remove --force` afterwards.
- **`review_gate.sh --base origin/main` alone built a >200 KB packet** once
  main had moved (it read as two-dot). Pass `--diff-file <(git diff
  origin/main...HEAD)` together with `--base`; the three-dot packet was ~90 KB.
- **`git add -A` swept `package-lock.json` (−23 lines of npm-install drift)
  into the first commit** even though I had "restored" the worktree copy. Check
  `git diff main...HEAD --stat` for a lockfile row before the push; fix with a
  `git checkout main -- package-lock.json` commit, never by rewriting.
- **Canvas selection from a script on a standalone desktop: six attempts, one
  success.** Fresh headless profile starts in Hand tool (pan) with the cookie
  banner up; click the tool toggle by its label (`Hand tool (pan)` /
  `Select tool`), not `V`. The synthetic pointer sequence raised the bar once
  (First frame verified end to end: node at `left+width+16`, one DB row); the
  same sequence, `page.mouse`, and a relaxed selector all failed afterwards
  with the hit element correctly the card's `<video>`. I never tried the
  note's own MCP `click`-by-uid route (2026-09-10 entry above) — rule 15
  broken again. Next time: two attempts, then MCP click or an `app/auth`
  harness. `[data-asset-card]` has no `data-selected`; the bar's presence is
  the signal.
- **`NEXT_LOCALE` set by one run persists in the profile** and made a later
  "en" run render zh-CN, so the English label probe found nothing. Reset the
  cookie at the top of every run.
- **A reused i18n key rendered a false claim.** `video.frameCaptureSuccess`
  ("saved to My Frame Captures") was the dialog's toast too; on the canvas
  nothing is filed there. Only the browser toast text showed it. New key
  `desktop.captureFramesSaved`, both canvas call sites; Library keeps its own.
- The `desktop` namespace's parity is NOT machine-enforced
  (`i18n-mode-copy.test.ts` covers `video` only) — diff the five catalogs'
  key sets yourself.
- DesktopCanvas.tsx carries 45 pre-existing `react-hooks/refs` lint errors on
  main; my first "baseline" compare measured the current file twice because
  `git show "$BASE:path"` lost its colon in the shell and the `cp` of a
  missing file was silent. Print the baseline's byte count and a grep that
  distinguishes the two files in the same output.

## Other sessions kill every `next dev` — and the toast race (2026-09-14, Meegle 14653304 round 2)

- **My dev server died twice mid-run** with a clean `[?25h` in its log while
  another worktree's `next dev` survived: another Claude session was applying
  the same "kill the :3000 holder" rule with `pkill -f "next dev"`, which
  matches every worktree's server, on any port. With three worktrees active
  at once the tug-of-war never ends. What held: start the server through a
  symlink to `node_modules/next/dist/bin/next` whose name does not contain
  "next dev" (`node $SCRATCH/moodio-<ticket>-server dev -p 3001`), and say in
  the report that verification ran on :3001 because :3000 was contended.
- **A soft navigation off a canvas takes 20–32 s here** (`/`, `/teams`,
  `/create`, `/library` all measured), and a short agent reply lands in
  16–25 s — so "send, then leave the page, then wait for the completion toast"
  loses the race more often than not, and the toast is then CORRECTLY
  suppressed (the chat was still on screen). Ask for five images with a
  150-word paragraph each (reply ≈ 45–85 s) and leave immediately after the
  POST is accepted. Log `[PROBE monitor]` with startCount / currentCount /
  pathname / visibility from the provider's poll to tell "race lost" from
  "bug"; the first run without it cost twenty minutes of theorising.
- The in-place variants do not work as a harness: collapsing the panel right
  after a send gets re-expanded by the agent's own card selection
  (`moodio-asset-selected` is a TO_CHAT event), and New chat is blocked while
  the stream runs. Say "not browser-verified" for those.
- `net::ERR_NETWORK_CHANGED` mid-run (Peter's VPN / Wi-Fi) turns a soft
  navigation into a hard one and wipes the provider's monitor state. Retry;
  it is not the code.
- Cross-page `open-chat-in-panel` dispatch is a side effect: the DEPARTING
  page's panel host hears it (navigation resolves seconds later), switches
  its conversation and persists it into its own slot. Dispatch only when the
  current page shares the destination's scope key. Found by reading the
  app-wide slot before/after in the harness — record every slot the flow can
  touch, not just the one the feature writes.

## Upload placeholders on the canvas: one status word, three tiles (2026-09-14, Meegle 14742436)

`uploadFilesToDesktop` (DesktopDetailPage) writes the ephemeral
`__uploading_*` placeholder as `status: "processing"` for image and
video (so the in-flight guards fire) and `status: "uploading"` for
audio. The image tile captions it via `uploadInFlight`; the video tile
captioned every pending state `videoGenerating` — hence "生成中" on a
dropped file. Fix was `uploadInFlight(asset)` choosing the caption in
`VideoAsset.tsx` and skipping `FakeProgressBar`. The audio tile shows NO
caption while uploading (its "uploading" status is neither processing nor
failed) — noted, not changed.

- An `app/auth/<x>` harness whose fixtures call `new Date()` at module
  scope trips a hydration-mismatch console error (Next's "1 Issue" badge in
  the screenshot) on the OLD code too; read the captured console text
  before attributing the badge to the change. Two 401s from `/api/auth/me`
  are the same baseline noise.
- A revert probe's "expect N" for the restored count must be derived from
  `grep -c` on the fixed file BEFORE the probe, not from memory (I wrote
  "expect 4", the file had 3; the 0→3 pair was still the evidence).

## Script studio import + driving the chat composer (2026-09-15, Meegle 14294602 sub-02)

- **A source-edit hook checkpoint blocks the first `Write`** in a session
  until the owning implementation skill is loaded (`ccl-skills:web-react-dev`
  for React work). It is not a permission denial: load the skill, retry the
  same write. One of two parallel writes went through, the other bounced.
- **TipTap composers ignore a synthetic `execCommand("insertText")` from
  `page.evaluate` on this build** (the chat panel's composer, not the script
  paper): `innerText` stayed empty, the send button sent nothing, and no
  `llm_turns` row appeared — silent. `page.mouse.click(editor)` +
  `page.keyboard.type(text)` (real CDP key events) works. Assert the editor's
  text BEFORE clicking send, and confirm the turn in `llm_turns` after.
- **After a fresh navigation the canvas chat panel opens on the history list**,
  not a composer. Click `button[aria-label="新对话"]` first; then
  `button[aria-label="发送"]` exists and the composer is the `.ProseMirror`
  found by walking up from that button.
- **Import a file through puppeteer**: arm `page.waitForFileChooser()` BEFORE
  the click that calls `input.click()`, then `chooser.accept([abs path])`.
  Toasts are `[role=alert|status]` nodes — install the MutationObserver spy
  once per page load (a navigation drops it).
- **The studio's import fixtures**: a minimal real DOCX is three zip entries
  (`[Content_Types].xml`, `_rels/.rels`, `word/document.xml`) — mammoth reads
  it; a PNG renamed `.docx` fails as PARSE_FAILED, an empty `.txt` as EMPTY.
  Peter's dev workstation `d9c0370c…` / episode `c0273ead…` was empty (no
  docs, no script) and is the clean target; delete the docs and PATCH the
  script back to "" with its CURRENT `contentUpdatedAt` (null → 409).
- **`npx eslint --fix` on `components/chat/chat-interface.tsx` reformats ~300
  lines you did not touch** (32 drift hunks around 2 real ones). Reapply the
  real edits on a `git checkout HEAD -- <file>` copy without `--fix` before
  staging, and count hunks (`git diff --staged -U0 | grep -c '^@@'`).
- `MAX_DOCUMENT_CHARS` (writings sections) is 200k, `MAX_SCRIPT_CHARS` 500k,
  `MAX_TEXT_CHUNK_LENGTH` (chat persistent context) 20k — three caps, three
  destinations; the design doc first said 500k for sections and was wrong.
- **`baseContentUpdatedAt: null` means "this row was NEVER written", not
  "skip the check"** (`lib/workstation/script-concurrency.ts`
  `contentUpdatedAtMatches`; `undefined` is the skip). Every created
  document/script row carries a stamp from insert, so a PATCH with `null`
  against an existing row is a guaranteed 409. The independent reviewer
  caught this in my 409-DOCUMENT_TYPE_EXISTS branch; I had written `null`
  as "no baseline". GET the row for its stamp, or omit the key.
- `/api/parse-document` has three consumers (chat persistent context, the
  Script studio import, `CreateTableWizard`); a status-code change on that
  route reaches all three — grep `parse-document` before changing it.

### Rendering the moodio-ui prototype for a side-by-side (2026-09-15)

`/Users/mahao/Develop/projs/moodio/moodio-ui` is a static page; `file://`
blocks its model calls but the UI renders. Serve it (`python3 -m
http.server 8765`, cwd moodio-ui, detached), open
`http://127.0.0.1:8765/Moodio-UI-Refined-Storyboard.html` in a second
headless Chrome (`--remote-debugging-port=9334`, separate profile dir), wait
`networkidle0` + ~1.5 s (loader.js concatenates `src/*.js`), then trigger
the dialog from its id (`#import-text-button` → `#flow-dialog`,
`data-kind` names the header art) and dump `getComputedStyle` of the
dialog, header, cards and footer button. The prototype's dialog language
(`.flow-dialog`): 620 wide, 12px radius, header 18/22 with an 18px bold
title over `assets/dialog-bg-*.jpg`, body 20/22, two-column 284×56 cards
(icon tile 32px radius 7 on `#f4f3f1`, 14px bold name, NO description),
13px `#696764` note, footer 14/22 with a 36px outline 取消. In the app this
is `StudioDialog chrome="flow" headerArt=…`; the header art is copied to
`public/assets/`.

## The minted token dies after 2 h, and :3000 is shared with Peter (2026-09-15, cloud-doc editor)

- `mint.js` signs a 2 h access token. Every browser run after that hits
  the login page and every wait (`剧本` tab, `导入文档`) times out looking
  exactly like a slow server. Forty minutes went to that. **Before EVERY
  browser run**: `curl -b moodio_access_token=$(cat token.txt) /api/auth/me`
  must be 200, or re-mint. Bake the check into `drive.js`.
- The :3000 server in this worktree is the one Peter reviews on; his
  traffic (a different workstation, Grammarly hydration warnings in the
  log) shares it, the dev RDS adds 1.3–4 s per request, and the studio's
  script load can lose a race to the episode-scope reset and sit on its
  spinner — a reload fixes it. `drive.js openStudio` now retries three
  times. Don't kill his server to "own" the log; read the browser side.
- Opening a document pane from the writings bar takes up to 90 s here.
  Wait on `.studio-cdoc [contenteditable]`, not `.ProseMirror` (the class
  IS "tiptap ProseMirror cdoc-body", the earlier waits simply expired).
- Rule 22 corollary: when the replica compiles and mounts, hand it over.
  Peter reviews faster on :3000 than a headless tour completes on this
  server; my extra hour of verification delivered nothing he could see.

### A bug handed to a new session while the delivery session keeps committing (2026-09-16)

Meegle 14294602: the line-handle drag bug was moved to a fresh session
while the original session went on landing subtasks on the SAME branch
and worktree. Two new commits arrived between my first read of
`CollabDocBody.tsx` and my second — the function I had just read had
been refactored under me (`moveLine` → `applyLocalEdit`), and a `git
status` that was clean at start says nothing about the next minute.

- Before the first edit on a handed-off bug, `git log -3` again and
  `git worktree list`; if the delivery session is still active on that
  branch, `git worktree add -b fix/<ticket>-<bug> ../<dir> HEAD` and work
  there. One commit on the side branch; the delivery session or Peter
  merges it. Say in the report where the commit is.
- `npm install` in the new worktree took under two minutes here (npm
  cache warm) and drifted `package-lock.json` as usual — `git checkout
  -- package-lock.json` before staging.
- Never `cd $W && …` in the Bash tool for the persistent shell; use
  `git -C $W`, `python3 - "$W/file"`, or a subshell — the tool resets
  cwd afterwards but a mid-command `cd` still shifts every relative path
  in that command.

## Performance constants for the dev environment (2026-09-18, Meegle 14294602)

The dev database is `…us-east-2.rds.amazonaws.com`. From Peter's machine:

| | |
| --- | --- |
| one SQL round-trip (`select 1`) | **~330 ms** |
| a fresh pool connection (TCP + TLS + auth) | **~3 340 ms** |
| ten fresh connections in parallel | ~2 630 ms |
| Turbopack compiling an API route on its first hit | ~5.5 s |

So in this repo **query COUNT is the only thing that matters** for API
latency, and any "this endpoint is slow" report is answered by counting
statements, not by reading code. The recipe that worked, in full:

1. Mint a token (the `mint.js` recipe above) and `curl` the endpoint six
   times — hit #1 is the compiler, the rest are the real number.
2. Write a throwaway `__tests__/zz-perf-probe.test.ts`, set
   `process.env.DATABASE_URL` from `.env` at the top (vitest.config injects a
   placeholder), patch `pg.Client.prototype.query` to count, then `await
   import()` the real modules and call the route's chain. Delete it after.
   Patching `Pool.prototype.query` too **double-counts** — the pool delegates
   to the client.
3. Remember `proxy.ts`. `enforceAdmission` runs on EVERY authenticated
   request and cost 4 queries before this fix; it appears in no route's code.

`lib/db/index.ts` had no pool settings at all until 2026-09-18 (`max`,
`idleTimeoutMillis`, `keepAlive`, `connectionTimeoutMillis` are now written
down). The old 10 s idle default threw connections away between bursts, so
every page load paid the 3.3 s connect.

### The studio's fetch hooks re-requested on a late-settling identity

`useWorkstationDocument` / `useWorkstationScript` listed `selfId`
(`mySessionId ?? "local"`) in the dependency array of the effect that issues
their GET, though the id is only read once the response lands. `mySessionId`
is null until the realtime room state arrives (`:8081` IS running in dev), so
every script and document was fetched twice. Fixed; `__tests__/fetch-effect-
deps.test.ts` derives every fetch effect from the source and fails if one
names a session identity again. Check that guard before adding a fetch hook.

### This worktree is shared with other Claude sessions

On 2026-09-18 another session was editing shot routes in
`meegle-14294602-…` while I worked in it. `git status` changed three times
mid-session and a test of theirs went red mid-edit. Stage paths explicitly,
and when a test fails, intersect its file reads with `git show --name-only
HEAD` before believing it is yours.

## A route's imports are load-bearing (2026-09-18)

`@/lib/storage/s3` imports `lib/image/compress`, which imports `sharp`. A
route that pulls that graph in fails to LOAD on the dev server — every request
to it answers 500 before the handler runs, with an empty body. The desktop
asset routes carry it and are fine, so the failure reads as "my new code
broke", not "my new import did".

- Handing a TEXT asset row to the client needs no URL resolution: use
  `lib/desktop/enrich-text-asset.ts` (no runtime imports), not
  `enrichDesktopAsset`.
- To tell a loading failure from a logic failure, call the handler in a vitest
  file (`const { PATCH } = await import("@/app/api/.../route")`, build a
  **`NextRequest`** — a plain `Request` has no `.cookies`) and fetch the same
  URL on :3000 in the same run. Mint a cookie with `jose`:
  `new SignJWT({ userId }).setProtectedHeader({ alg: "HS256" })…sign(new
  TextEncoder().encode(JWT_ACCESS_SECRET))`, sent as `moodio_access_token`.
- vitest sets `DATABASE_URL` to a localhost placeholder (`vitest.config.ts`
  `test.env`), so a probe that wants the real database must OVERWRITE it, not
  default it — otherwise every query fails with "The server does not support
  SSL connections" and it looks like the code.

## Long-lived feature branches here take main by MERGE, not rebase (2026-09-19)

`feat/meegle-14294602-moodio-script-module-optimization` is an integration
branch: 232 non-merge commits plus **43 merge commits**, because its sub-PRs
(#705–#715) are merged INTO it rather than into main, and it already carries
its own `Merge origin/main` commit from a previous integration.

"Rebase onto main" on a branch shaped like this is not the cheap operation it
sounds like. Measured, not guessed:

| Route | Result |
| --- | --- |
| `git merge-tree --write-tree HEAD origin/main` | clean, zero conflicts |
| `git rebase --onto origin/main <base>` | conflicts at commit **1 of 232**, and drops all 43 merge resolutions |
| `git rebase --rebase-merges --onto origin/main <base>` | conflicts replaying the branch's own earlier `Merge origin/main` |

Both rebase routes also need a force-push of ~275 rewritten commits on a
branch that is already on origin. The merge needs none. Probe with
`merge-tree` and a throwaway `git worktree add --detach` before choosing —
the probe costs two minutes and settles it with evidence instead of a feeling
about history shape.

The rule-21 proof is especially clean for a merge: `diff(before.patch,
after.patch)` where `after = git diff origin/main..<merge commit>` should be
**exactly 0 lines**, because main's changes now sit in both the base and the
head and cancel out. A non-zero delta on a merge means something was lost.

Also from that session:

- **Migration collisions are resolved once, at the integration that creates
  them.** This branch's 0092–0096 were renumbered past main in the FIRST
  integration, so the second needed no renumbering at all. Check with
  `comm -23`/`comm -13` over both sides' file lists plus `cut -c1-4 | uniq -d`
  for duplicate numbers — and check whether a duplicate already lives on main
  (0042 and 0078 both do) before treating it as yours to fix.
- **A dropped migration leaves stale prose behind.** `lib/db/schema.ts` still
  said `character_bios` was "retired by migration 0086" — that migration had
  been dropped during the previous integration precisely because main had
  claimed 0086, so the comment pointed at unrelated pricing SQL. Grep every
  migration number the branch ever used after a renumbering, not just the
  files.
- **The canvas overlay guard's ROOTS are `node-composer.tsx` and
  `CanvasAssetCard.tsx` only.** Overlays mounted directly by
  `DesktopCanvas.tsx` — the floating action bar above a selected asset, whose
  position is computed from `camera.zoom` — are outside its walk. Main's
  `ImageVariantPicker` landed there with a bare HeroUI `<Popover>` and the
  guard stayed green on both branches. Rule 21 step 4 ("grep the target's
  incoming diff for the mechanism the branch generalised") is what surfaced
  it; nothing automated would have.
- **zsh does not word-split an unquoted `$VAR` of paths.** `npx eslint --format
  json $FILES > out.json 2>/dev/null` wrote a 0-byte file because eslint got
  one argument that was the whole string. The empty output then read as "no
  lint findings" — rule 9's failed-query trap, in a shell instead of an API.
  Pass the paths literally, and never send a comparison run's stderr to
  `/dev/null`.

## Only the script PAGE fetches the script — every other surface reads a null (2026-09-19)

`useWorkstationScript()` is mounted by exactly one component,
`ScriptPaperPane`. Nothing else in the studio fetches the episode's script.
So `storeApi.getState().scriptContent` is `null` on any studio layout whose
pages do not include 剧本 — and the studio remembers its pages per episode
(`ws-studio-layout:<ws>:<episode>`), so that is an ordinary state, not an
edge case.

Every consumer that reads it synchronously is a bug waiting for that layout.
Two were live:

- **定位剧本 on a 分镜表 row** did nothing until the page was reloaded. The
  handler opened the script page and then read the store in the same tick;
  no ids matched, so it toasted "the passage is gone". The reload restored a
  layout that already had the script page, so the text was there first.
  Peter reported it as 「定位剧本会不生效，但是刷新页面后就可以了」.
- **The import modal's overwrite guard** waived its confirmation checkbox
  (and enabled Apply) for an "empty" script. An in-flight import job reopens
  that modal on studio mount, on whatever pages were remembered — so with
  the script page closed, an import replaced a full script with no prompt.

The tell in both: an empty store and an empty script are the same value, and
the code that had it right was 1200 lines away in the same file — the
canvas's 定位剧本, which waits via `whenScriptLoaded` and says so in a
comment. **When two call sites reach one function and only one is reported
broken, diff the call sites before reading the function.**

The fix shape that holds: put the wait inside the function every surface
calls, not at the call sites, and make "we have not read it yet" a value the
type system carries (`{ status: "wait" }`, `loaded: false`) rather than an
absence that reads as an answer. Both are pure modules under `lib/workstation/`
with node tests, which is the only layer this repo's suite can see.

Grep for the class before assuming it is closed:
`grep -rn "getState()\.scriptContent\|state?\.scriptContent" components hooks lib`.
The remaining hits are inside ScriptPaperPane's own subtree (the 版式 switch,
the paper's save) plus the versions panel's `current()`, which still reports
an unloaded script as `""` in its top row — cosmetic, unfixed, worth a look
if the compare view ever shows a blank "current".

---
## Reorder strips: the end gap has no drop target (2026-09-20, Meegle 14744969)

Every drag-to-reorder strip here hung `dragover`/`drop` on each TILE and split
the tile at its own midpoint. Interior gaps are covered twice (one half-tile per
neighbour); the gap at the END is covered once, by the last tile's far half, and
the space past the strip belongs to the container. A release there reached no
reorder target, bubbled to `data-composer-box` (`onDragOver preventDefault` +
`handleDrop`), which found no asset MIME and no files and returned silently.

- **Any "drag to X only fails at the edge" report here is a drop-TARGET coverage
  question, not an index question.** The order arithmetic was correct in all
  seven strips; it was simply unreachable.
- The fix pattern: the CONTAINER owns dragover/drop, items stamp
  `data-reorder-index`, and a pure resolver
  (`lib/dnd/reorder-geometry.ts#resolveInsertIndex`) turns the pointer into a gap.
  One resolver drives the indicator AND the drop, so they cannot disagree — the
  old canvas path had no `onDragLeave` and kept promising an end insert the
  release could not deliver.
- `chat-input.tsx` held two hand-written copies of `useReorderDrag`, which is why
  one bug hit 画布节点 and agent at once. They are gone; one mechanism remains.
- Guard the container handlers on `dragIndex !== null`, or a file / library-asset
  drag over the strip stops reaching the surrounding drop zones.

**A surviving mutant can mean "delete the code".** Mutation-testing the resolver
found a `if (main >= last.mainEnd) return last.index + 1;` guard that no test
could kill — because the loop below already fell through to the same answer. It
was dead code, not a test gap. A second survivor (sorting a line by index rather
than by position) WAS a gap, and the test that killed it pins a real contract:
geometry follows layout order, not index numbering.

---
## Measure the bug screenshot instead of squinting at it (2026-09-20)

A Meegle report that is a screenshot of a transient state (a drag, a hover) can
be read numerically. Per-box mean RGB via PIL settled #14744969 in one call:

- tile 1's mean was ~65 % of tile 0's → it carried `opacity-50`, so it was the
  DRAGGED tile;
- the floating box had the same mean → Chrome's translucent drag image, not a
  fourth tile;
- the space between them was flat background → the strip had three items.

Then tile pitch (80px tile + 8px `gap-2`, divided by the screenshot's DPR and the
page zoom, both recoverable by matching the composer's known 560px width) put the
cursor ~378 CSS px from the strip's left edge against a 256px strip inside a
~482px container: released inside the container, past every tile. Root cause
proven with no browser, which is what rule 24 requires here.

Brighten with `ImageEnhance.Brightness` to tell "empty" from "dark", and compare
box MEANS rather than judging absolute darkness.

**Do not `cp` a HEAD baseline tree into the worktree.** Writing HEAD copies to the
scratchpad and then `cp -r $S/components $S/hooks .` overwrote every edited file
with its HEAD version and destroyed an hour of uncommitted work — `git status`
simply went back to clean, with nothing to recover. Inspect a baseline where it
sits (`git show HEAD:<file> | diff - <file>`); never copy a directory into the repo.

## Next 16 refuses a second dev server in the same directory (2026-09-20)

`next dev -p 3100` in a worktree that already has one running exits with
"Another next dev server is already running" and names the PID — it keys on
the DIRECTORY, not the port. So there is no way to stand up a throwaway
server beside Peter's while he is testing the same worktree. Plan for it:
do the live route checks BEFORE handing the branch over, or accept that the
remaining evidence has to come from a different class (running the Lambda's
`main.py` directly, reading the spawn contract).

Two things that do work:

- **Pass dev-only env vars inline rather than editing `.env`.** Next does
  not override a value already in `process.env`, so
  `AUDIO_PROCESS_LOCAL_RUNNER=… npx next dev` configures the runner without
  touching a file Peter's running server would reload from.
- **`:3000` may belong to another worktree.** The "always :3000, kill the
  holder" note is about MY own stray servers. Check
  `lsof -p <pid> -a -d cwd` first: evicting another task's session, or
  Peter's, is not mine to do.

## Reusing a pipeline inherits its vocabulary (2026-09-20, Meegle 14732749)

The silent-video node was built as a `video-edit` with `operation: "mute"`
so it would inherit the pending node, the manifest settle, the board poll,
the reap and the undo entry. All of that worked first time. What came with
it and should not have:

- the tile's caption said **"正在修剪…"** on a node nobody trimmed
- all six failure keys were `desktop.trimClip*` — "修剪失败" for a mute
- `startAsyncLambdaJob`'s label was the literal `"VideoEdit:trim"`, so
  CloudWatch named the wrong derivation
- `videoEditProvenanceOf` gated on `operation === "trim"`, which made the
  new node **invisible to the board's poll** until the guard was widened —
  the one of the four that is a functional bug, not a wording one

The habit worth keeping: after routing a second thing through an existing
pipeline, grep that pipeline for its own noun (`trim`, `upload`, `denoise`)
and check every hit for whether it is the mechanism or just the old name.
Only the guard broke a test; the three wording leaks were invisible to tsc
and to every existing test.

Also from that session: **"success: true" from a render is not evidence.**
What proved the mute path copied the picture instead of re-encoding it was
`ffmpeg -i <f> -map 0:v -f md5 -` on the source and the output coming back
identical, with `ffprobe -select_streams a` showing zero audio streams.

## An unauthenticated probe never reaches a route (2026-09-21, Meegle 14956503)

`proxy.ts` answers `{"error":"Unauthorized"}` 401 to EVERY unauthenticated
`/api/*` request — an existing route, a missing one and a wrong method alike —
so a curl without a session proves nothing for rule 29. Probe with a minted
token (`A login-free REAL session`) and look for an answer only the handler
can give: a 404 `resource_unavailable` from `authorizeWorkstation` on a nil
workstation id, a 400 from body validation, a 405 for a method the route file
does not export. Two tell-tales that the probe hit ANOTHER worktree's server
(the port holder changed mid-session, again): a route you just added answers
405 (the dynamic sibling `[id]/route.ts` matched it instead), and a field you
just added is missing from a read. Check the holder's cwd before believing
either.


## A dblclick under a container capture never arrives (2026-09-21, Meegle 14989382)

"Double-click a zone sometimes does not enter it, a refresh fixes it" was
the TOOL, not a race. Every canvas opens on Hand (`useState<CanvasMode>("move")`
in `DesktopDetailPage`, never persisted). With Select, the zone body yields
its press to the marquee, and the marquee does `setPointerCapture` on the
CONTAINER. Capture retargets the click/dblclick that follow onto the
capturing element, so the body's `onDoubleClick` never ran. With Hand, the
zones layer captures on the body itself, so it worked. The refresh "fixed"
it only by putting Hand back in the user's hand.

- A "sometimes, refresh fixes it" canvas report: first list the
  non-persisted UI state a refresh resets (tool, focus stack, selection),
  then ask Peter for the one-line repro across it. "Press V, double-click;
  press H, double-click" confirmed the cause in 30 s.
- Any double-click inside the canvas must be read from PRESSES
  (`components/desktop/assets/use-double-press.ts`, which now returns true on
  the completing press). pointerdown always goes to the pressed element; only
  the events after it are redirected. Asset cards had already hit this.
- The guard that pinned the literal `onDoubleClick={() => onZoneEnter?.(zone.id)}`
  stayed green for two months while Select was dead. A synthetic
  `dispatchEvent(new MouseEvent("dblclick"))` in a harness would also pass,
  because it bypasses capture. Only real presses in a real browser, per
  tool, observe this.

## A signed media URL changes on every response (2026-09-21, Meegle 14980874)

- `getSignedVideoUrl` signs with a `Date.now()` expiry (30 min), so EVERY
  enriched response carries a different string for the same file:
  `fetchDetail` (replaces all assets; fired by any generation settling, WS
  reconnect, the 10 s poll fallback, uploads) and `mergeAsset` on PATCH /
  batch-move echoes. Anything keyed on the raw URL (a `<video src>`, a
  `useVideoPlaybackIntent` key, a cache) sees a "new" value on every refresh.
  `ReleasableVideo`'s ref depends on `src`, so a mounted element releases +
  reloads, and `autoPlay` restarts it: "paused video plays again by itself".
- Identify the file by the URL PATH, not `metadata.videoId` (chat-placed tiles
  have none; enrichment takes it from the generation) and not the host (CN
  viewers read the CN domain, broadcasts may carry the origin). The fix pins
  the source per mounted element (`lib/desktop/video-tile-playback.ts`) and
  re-pins on `error` when a fresher signature exists.
- A version restore swaps `videoId` in place under a mounted element, and
  `ReleasableVideo`'s release calls `pause()` first: an `autoPlay` gated on an
  onPause-derived flag leaves the restored clip frozen on frame 0. Tried,
  dropped.
- Video nodes are 180 px tall with a fixed box (no resize): a 9:16 node is
  ~101 px wide and drops under the transport's 96 px gate below ~95% zoom.

## Recording API fixtures from a running dev server (2026-09-22, moodio-agent-flash)

The pure-frontend fork (`moodio-agent-flash`, `docs/design-frontend-extraction.md`
there) replays recorded `/api/*` traffic through MSW. Recording it cost four
detours; take these routes first:

- **Peter's `:3000` server can be stale.** It answered 500 (Next's HTML error
  page: `Module not found: '@anthropic-ai/sdk'`) on every route importing the
  LLM client because his `node_modules` predated the dependency. Do not fix
  his checkout; record from a fresh detached worktree of upstream
  (`git worktree add --detach .work/worktrees/tmp/<name> main`, `npm install`,
  copy `.env`, `npx next dev -p 3002`). Tell him his server is stale.
- **The retrieval service (`NEXT_PUBLIC_FLASK_URL`) only allows the `:3000`
  origin (CORS).** From any other port the browser never sees a response, so
  nothing records. `RECORD_NO_CORS=1` in flash's `scripts/mock/record.ts`
  launches Chrome with `--disable-web-security` for recording only.
- **MSW under React StrictMode:** `worker.start()` runs twice on the dev
  double-mount and throws "cannot configure an already enabled network".
  Memoize the start promise at module level.
- **zsh does not word-split `$T` holding `npx tsx script.ts`**; a chain of
  `$T …` silently fails with "no such file". Use a shell function.

The mint-a-JWT route (section above) works unchanged; the dev user with the
richest data is `peter8icestone@gmail.com` (37 projects, admin).

## Unit frames on the grid: who places member cells (2026-09-22, Meegle 14993494)

A generation unit's frame is a scene zone. `planShotGrid` owns its top-left,
and its member cells are fixed offsets from that corner. Before you reason
about "members off their cells", know what actually reads those cells:

- **Planned-cell seeding** (`seedUnitTextNodesTx`, `resolveMemberCellTx`) runs
  only when a unit is created, when a member first gets text (the entry's heal
  pass), or when one member's node is made on demand. Joining an existing unit
  on the canvas is a drag (`joinShotGroup` via `resolveUnitDrop`), and the node
  stays where it was dropped.
- **`workspaceShift`** measures the frame's work against the PLANNED block, not
  the member nodes. After any change that moves contents relative to the frame,
  the top edge needs the "work below block + gap" ceiling, or the grid pushes
  the work back outside history.
- **`arrangeZones` applies `contentShift` to every direct asset of the frame,
  member text nodes included.** `ShotGridZoneUpdate.contentShift` documents the
  opposite. This is pre-existing and was reported, not fixed.
- The resize model that holds: the size is the user's, and the place is the
  grid's. A left/top drag commits anchored (`anchorZoneResize`: write the size
  only, and move the contents by the drag-start delta). The limits equal what
  the grid would restore (`unitFrameResizeLimits`).

