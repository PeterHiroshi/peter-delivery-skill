# moodio-landing

The `landing-page-v2` worktree uses the Next.js baseline `d5dd41e` (#108).
The older `b9a1073` baseline used Vite + vanilla TypeScript + GSAP and build-time
Sanity rendering; consult the branch section before choosing commands.
The marketing site (`www.moodio.art`) is separate from `moodio-agent`
(`app.moodio.art`). Remote org `JerryYang666`: one PR to main plus Lark hand-off.

## Symptom index

| Symptom / task | Route |
| --- | --- |
| Next.js foundation worktree, SSR or language redirects | Next.js foundation branch |
| Which checks prove content and rendering | Verification boundaries |
| Marketing metadata, locale route/sitemap consumers or public social profiles | Marketing SEO |
| CMS fetch failure or explicit offline preview | Sanity content |
| Lockfile, cached artwork, or encoded media paths | Asset and install traps |
| Figma source swaps, MCP access, media, shader or opaque exports | Figma MCP access |
| Browser testing explicitly requested | Browser via DevTools CLI |
| Native modal closes but focus returns to body | Native dialog lifecycle |
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

2026-10-30: source-mutation runners create and remove module copies inside
`src`/`scripts`, which TypeScript scans. Running one alongside `next build`
failed with TS6053 for a removed mutation file despite valid source. Run these
runners sequentially with typecheck/build; temporary-copy isolation does not
make compiler discovery independent.

## Sanity content

Project `26ufsyvn`, dataset `production`. The Vite baseline writes root-level
content HTML at build time. The Next.js branch uses server-side published reads
cached for 60 seconds and preserves blog/news/campaign/scenario URLs.
`SANITY_FIXTURE=studio/samples/all.ndjson` is an explicit offline preview, never
an automatic production fallback. On the Next.js branch, fixtures are noindex,
robots disallows crawling, and sitemaps are empty; use the same env for build,
start and HTTP tests. Check `/blog/`, both sitemaps and robots after deployment.

## Marketing SEO

2026-10-30: the new English homepage's early return skipped page JSON-LD, and
the native About route bypassed shared metadata/noindex and the CMS-only sitemap.
`src/lib/seo/marketing.ts` now owns native page metadata/graphs; the sitemap
includes native About once and excludes a shadow CMS About/timestamp. Content
sitemap stays CMS-only. `src/content/social.ts` is the shared owner-supplied
profile registry for Organization `sameAs` and the new footer. Reuse the safe
JSON-LD serializer and `metadataFor`, including preview/fixture noindex.

Known-good route: `npm run test:seo`, `npm run build`, then a production server
and `TEST_BASE_URL=http://127.0.0.1:<port> npm run test:http -- --mutations`.
Run separate servers with matching `VERCEL_ENV=preview` or explicit
`SANITY_FIXTURE` for preview/fixture checks. The HTTP harness now distinguishes
native English/About from legacy Chinese/CMS chrome; obsolete “no redesign” or
“About must 404” assertions must not hide SEO regressions. New marketing source
mutations: `npm run test:marketing-mutations`; legacy mutations stay active.

Google retired FAQ rich results in May 2026 (developers.google.com/search/updates).
Do not add stale FAQPage answers to the new homepage or promise that feature.
VideoObject needs the actual first-publication date, not a download/build date;
Peter confirmed it was unknown, so it remains deferred. Profile sharing queries
can be dropped while retaining account paths; preserve supplied short URLs and
do not turn copied social-share email fragments into company contact details.

2026-10-30 warm-up clarification: EN/Chinese now share the native landing;
Chinese About is `/zh-cn/about/`, with the active tab retained on language
switch. `MARKETING_ROUTES` is the four-route registry for metadata/graphs and
both sitemap consumers. Updating only the main sitemap leaked Chinese About
into the content-only sitemap; live HTTP caught it. Derive every native-route
exclusion from that registry and verify the actual XML. A valid `/zh-cn/` URL
alone does not prove a switch preserves the new UI.

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
For full-page comparison, set below-fold images eager and await image decoding
and `document.fonts.ready`; otherwise lazy images can appear blank in captures.
Use stable reduced-motion posters when comparing animated source artwork.

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

Later retries recovered quota-limited reads; the changed account/seat setting
was not observed, so do not invent a cause. MCP `download_assets` exposed the
VideoPaint poster but not the original movie. After inspecting the source
VideoPaint/hash via MCP, the original Figma node's Properties → download video
control supplied the actual MP4. Preserve provenance, transcode a web copy to
`public`, and verify the consumed local URL, duration, audio and Range response.

For decorative transparent groups, use `exportAsync({ format: 'PNG',
contentsOnly: true })`, not a screenshot flattened onto the page background.
The latter hid the Version 2 CTA gradient behind an opaque pale rectangle.
Inspect alpha and the composite render. The recruiting Pattern Grid shader
returned source but required `file://shader-runtime-index.json/`; runtime
resource access remained unresolved on this connection. Preserve source and
declare that visual gap rather than replacing the shader with a guessed effect.

2026-10-30 source replacement: `RGO3Dq5R0bkIxnwMZkb6TP`, frame `1:75`
is named “第一版” although its page is “version 2”. Its section bounds match
the old source while film/community images, Environment copy and layout, hero
SVG dimensions and decorative accents differ. Confirm the actual selected
frame and compare assets/copy, not just geometry. Matching hero/film hashes
prove the already downloaded movies can be reused across the files; matching
SHA-256 proves exact static asset reuse. Follow the returned design-context
artwork layout: applying raw ImagePaint transforms again shifted the provided
gradients. Compare the composite before adding extra transforms. A later
explicit MCP quota block left FAQ/Blog/footer rereads and transparent icon
export unverified; declare those boundaries rather than inferring access loss.

A later supplied screenshot omitted Work and About, but Peter's subsequent
written warm-up requirements retained Selected Work and a brief About while
moving detailed people/research to separate tabs. Reconcile content scope with
the latest explicit requirements before forcing screenshot page height. Missing
real film credits/testimonials and portraits remain declared gaps; never fill
them with invented content. Peter later clarified the reference header has no
Contact us; keep contact entries in the hero, FAQ and closing/footer, including
mobile navigation parity. The flattened language PNG's white matte can be
removed at render time with `filter: invert(1); mix-blend-mode: screen` on the
dark navigation, preserving the asset; verify its composite and fix the actual
locale renderer/navigation as well.

## Native dialog lifecycle

2026-10-30, Version 2: closing a conditionally rendered native `<dialog>` in a
passive `useEffect` cleanup restored focus to `body`; direct close while still
connected restored the trigger. `useLayoutEffect` cleanup closes before React
removes the DOM node and restores the prior body overflow. Verify Escape and
close-button dismissal through real browser input and read back the active
trigger; a disappearing modal alone does not prove focus restoration.
For a dialog opened from a mobile menu, keep its trigger visible underneath;
closing the menu first makes native focus return target a hidden button.
