# moodio-landing

The main-checkout baseline `b9a1073` uses Vite + vanilla TypeScript + GSAP and
build-time Sanity content rendering. Task 15654343 migrates it to Next.js in a
separate worktree; consult the branch section below before choosing commands.
The marketing site (`www.moodio.art`) is separate from `moodio-agent`
(`app.moodio.art`). Remote org `JerryYang666`: one PR to main plus Lark hand-off.

## Symptom index

| Symptom / task | Route |
| --- | --- |
| Next.js foundation worktree, SSR or language redirects | Next.js foundation branch |
| Which checks prove content and rendering | Verification boundaries |
| CMS fetch failure or explicit offline preview | Sanity content |
| Lockfile, cached artwork, or encoded media paths | Asset and install traps |
| Figma MCP cannot read the Version 2 design | Figma MCP access |
| Browser testing explicitly requested | Browser via DevTools CLI |
| PR targets | Git hand-off |

## Next.js foundation branch

Task 15654343 (2026-10-28): branch
`feat/15654343-nextjs-landing-foundation`, worktree
`.work/worktrees/15654343-nextjs-landing-foundation`. These commands apply to
that branch; production/main migration has not been verified yet. Final scope is
framework/SSR/SEO/CVE only (native child 15660747): keep the old homepage and
content chrome, no new navigation/sections/tabs or generated placeholders.

- Node.js 24, `npm ci`, `npm run build`; `npm run start -- --port 4173`, then
  `npm run test:http -- --mutations`. These HTTP checks do not open a browser.
- With `src/app`, use **`src/proxy.ts`**, not root `proxy.ts`. The misplaced
  file produced a green build while language redirects did nothing and every
  response used `html lang=en`. Check real redirects and returned HTML language.
- The worktree's initial install left Inter's package directory but no font
  files. Inspect the actual package files; a fresh `npm ci` restored them. Do
  not try alternate CSS imports before checking the installed artifact.
- CLI compilers/preflight must load the same `.env` mode as Next. `@next/env`
  is CJS: use default import `nextEnv` and `nextEnv.loadEnvConfig` outside Next
  under Node/tsx; its named import failed under Node 24 ESM. Bootstrap before
  importing modules that capture environment variables.
- Homepage legacy builders compile to inert locale markup before dev/build;
  Next returns that markup in SSR and the client attaches enhancements in place.
  Recompile legacy sources with `npm run prepare:home` during development.

## Verification boundaries

The baseline already has `test:seo` and an opt-in browser suite; the old claim
that this repo has no tests is obsolete. Its default build validates live Sanity
and fails on content errors. `tsc` and builds still do not prove browser layout,
media behavior or third-party tracking. Hand Peter numbered interaction cases
unless he explicitly requests/approves browser automation (rule 24). Repeated inert
Happy DOM mutation runs must await `happyDOM.close()` between cases; synchronous
loops retaining windows exhausted the default 4GB heap.

## Sanity content

Project `26ufsyvn`, dataset `production`. The Vite baseline writes root-level
content HTML at build time. The Next.js branch uses server-side published reads
cached for 60 seconds and preserves blog/news/campaign/scenario URLs.
`SANITY_FIXTURE=studio/samples/all.ndjson` is an explicit offline preview, never
an automatic production fallback. On the Next.js branch, fixtures are noindex,
robots disallows crawling, and sitemaps are empty; use the same env for build,
start and HTTP tests. Check `/blog/`, both sitemaps and robots after deployment.

## Asset and install traps

- `npm install` can drop platform-specific optional lock entries on macOS.
  Review drift mechanically; never discard deliberate dependency changes.
- On Vite, `/assets/` mixes artwork with emitted JS/CSS. On Next, framework
  bundles live under `/_next/`; only content-hashed `/optimized/` artwork gets
  the custom immutable header. Do not cache unhashed public artwork forever.
- Vite decodes `%20` paths in built HTML. Compare requested URLs, not just the
  source spelling. Production IndexNow availability must be checked at its
  deployed `.txt` URL; a local 200 does not prove Vercel routing/settings.

## Browser via DevTools CLI

Only after Peter asks/approves: if the MCP server times out, the CLI worked via
`npx -y -p chrome-devtools-mcp@latest chrome-devtools <cmd>`. It starts headless;
use `stop` then `start --headless false` when he wants to watch. `take_snapshot`
takes pageId; `evaluate_script` takes the function and `--pageId`. Do not kill
Peter's Chrome or reuse its locked profile. Real phone widths require emulation.

## Git hand-off

Current `CLAUDE.md` and Peter's 2026-09-28 instruction require **one PR per task,
against main**. The old fan-out to every branch is retired. Product push/PR need
separate approval. Include the English Lark text in the PR-link reply and file
the link on the Meegle task, following `06-git-and-integration.md`.
If `gh` stalls in the macOS keyring, use the GitHub connector for PR/status/review
APIs; SSH `git fetch/push` worked. Do not block a PR on repairing CLI credentials.

## Figma MCP access

2026-10-30: Moodio.art reads initially returned “no edit access” although
Peter could view the original file. A later retry succeeded for session,
metadata, screenshot and 13 design-context subtrees. `whoami` still listed
only Peter's Starter / View team; which access setting changed is unknown.
Do not infer that upgrading or edit access fixed it. Peter requires the
original file through MCP, not a copy.

Further reads then explicitly hit the View-seat tool-call limit (the error
named the file's Professional plan). Treat access and quota as separate
failures. Preserve returned code and download temporary assets immediately;
cache metadata and filter it locally instead of rereading the entire page.
Version 2 is node `4527:10114`, 1441 × 8856. Its parent `2256:2326` is a page,
so design context needs the child frame; dot grids make full-frame responses
sparse, requiring targeted content subtrees.
See https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/.
