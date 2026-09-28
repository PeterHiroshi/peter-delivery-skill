# moodio-landing

Vite + vanilla TypeScript + GSAP ScrollTrigger. Standalone static marketing site for
`https://www.moodio.art/`, deployed on Vercel, separate from the Next.js app repo
(`moodio-agent`, which serves `app.moodio.art`). Remote org is `JerryYang666`, so the
Lark hand-off applies (not the icestonetech flow).

## What the gates do NOT cover

There is **no test suite at all** — `package.json` has `dev`, `typecheck`, `build`,
`preview` and nothing else. `npm run build` is `tsc --noEmit && vite build`: it proves
the TypeScript compiles, and nothing about what renders, what a script does at
runtime, or whether a `public/` file is reachable.

So for anything user-visible or third-party, looking is the *only* coverage. What
worked (2026-09-07, verifying analytics tags):

- `npx vite preview --port 4173`, then drive a **separate** headless Chrome over the
  DevTools protocol. Peter usually has Chrome running against
  `~/.cache/chrome-devtools-mcp/chrome-profile`, and the MCP browser tools fail with
  "browser is already running for that profile". Do not kill his instance — launch
  your own with `--user-data-dir=<tmp>` and `--remote-debugging-port=9333`.
- Chrome rejects CDP websockets by origin: pass `"--remote-allow-origins=*"`
  **quoted**, or zsh globs the `*` and Chrome never starts.
- That setup proves the real things: `dataLayer` populated, `window.clarity` is a
  function, third-party containers returning 200, JSON-LD actually parsing, page still
  rendering (`document.body.scrollHeight`), plus a screenshot.

## Traps

- **`npm install` rewrites `package-lock.json` on macOS**, dropping Linux/WASM
  optional deps (`@emnapi/*`, ~23 lines). It is an artifact of the install platform,
  not a change — `git checkout package-lock.json` before committing.
- **`public/assets/` is not just assets.** `vite build` emits the hashed JS/CSS bundle
  into `/assets/` too. Anything that pattern-matches that path (robots.txt, cache
  headers, CDN rules) hits the bundle as well. See rule 11.
- **Vite decodes `%20` in `index.html`.** Source has
  `/hero%20video/hero%20mix%202.webm`; `dist/index.html` has literal spaces. Percent-
  encoded paths in robots.txt or config will not match what the page requests.
- `vercel.json` sets `cleanUrls: true`. Local `vite preview` serving a `.txt` at 200
  does **not** prove production does — the IndexNow key file must be `curl`ed against
  the deployed site.
- Nothing in `src/` has `alt` attributes or heading tags. All markup is built
  imperatively in `src/sections/*.ts`; `index.html` has only `#app` plus a `<noscript>`
  fallback. A spec describing "current alt values" is probably describing that
  fallback, not the rendered page — check before believing it.

## Sanity content pages (2026-09-28)

Blog / news / campaign / scenario come from Sanity project `26ufsyvn` and are
prerendered by `scripts/prerender.ts` into root-level `blog/ news/ campaign/
scenario/` (git-ignored) that `vite.config.ts` picks up as extra pages.

- `SANITY_FIXTURE=studio/samples/all.ndjson npm run prerender` renders offline.
  Use it when `*.apicdn.sanity.io` times out from this machine (it did for a whole
  session on 2026-09-24, then worked on 09-28 — network, not config).
- The default build **skips** content pages when Sanity is unreachable and exits 0.
  `PRERENDER_STRICT=1` is the only way to make the build prove the live dataset.
- Content routes to check after a deploy: `/blog/`, `/sitemap-content.xml`.

## Browser via the DevTools CLI (2026-09-24)

When the `chrome-devtools` MCP server times out at session start, the CLI still
works without a global install: `npx -y -p chrome-devtools-mcp@latest chrome-devtools <cmd>`
(wrap it in a script; zsh will not word-split a `$CMD` variable). Its daemon
launches Chrome **headless by default** — `chrome-devtools stop && chrome-devtools
start --headless false` when Peter wants to watch. Argument shapes differ per
command: `take_snapshot <pageId>`, `click <pageId> <uid>`, but
`evaluate_script "<fn>" --pageId <n>`. Each call re-spawns npx, ~5–30 s; batch
steps in one shell script and run it in the background. A visible Chrome window
will not resize below ~500 px, so real phone widths need device emulation.

## PR fan-out convention

**Overridden by Peter on 2026-09-28: one PR per task, not one per branch.** He
closed the fan-out for the Sanity change (#78–#90) and asked for a single PR
(#77). `CLAUDE.md` still says otherwise — ask before fanning out again, or fix
`CLAUDE.md`.

`CLAUDE.md` mandates it: every change opens a PR against `main` **and every other open
branch**, archive branches included, no filtering. That was 16 PRs on 2026-09-07.

- Enumerate bases mechanically: `git branch -r` minus own head, then `comm -23`
  against what `gh pr list --head <branch>` reports.
- `gh` throws transient `graphql: EOF` errors under this volume. Wrap **both** create
  and the verification listing in retries, and never treat an empty listing as
  "nothing exists" — see the "failed verification query" note under rule 9.
- PRs against non-`main` branches will show conflicts, because the head branches off
  `main` and carries commits those branches lack. That is expected and documented;
  note it in the PR body rather than skipping the branch.
