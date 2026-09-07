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
