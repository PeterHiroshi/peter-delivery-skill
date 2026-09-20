# Harnesses and measurement

A harness proves only what it mounts, over the data it is fed. And "it is slow" is a number, not a reading.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 12. A harness that feeds the component your own data verifies the code, not the product

On 2026-09-08 the onboarding guide v2 was screenshotted end to end through a
throwaway page that mounted the real player with `DEFAULT_GUIDE_CONFIG` from code.
Every beat matched the mockup. Peter then reviewed on the same dev server and saw
none of it — the app reads its script from the database, the dev database still held
the v1 script, and the migration that would have published v2 had never been run
there. Eight bug reports, all "the feature is missing", all explained by the harness
having bypassed the data path the product uses.

It is rule 7 again, one layer up: the component was right, the served value was
old. Before calling rendering verified, make the harness read what the product
reads (the DB, the API, the flag), and make the review environment carry the new
data — run the migration on dev, or say in the first line of the report that it
has not been run and what the reviewer will therefore see.

### 13. A harness only verifies the layers it actually mounts — prove it by reverting

On 2026-09-08 (Meegle 14588335) two defects were fixed in the same session. The
browser harness mounted `GenerationConfigBar` directly. Fix A lived there and was
genuinely verified. Fix B lived one level up in `chat-input.tsx`, which the harness
never mounted — so the run "passed" while observing nothing about it.

The tell was cheap and I nearly skipped it: **revert each fix separately and re-run.**
Reverting A brought its defect straight back (attribution proven). Reverting B changed
*nothing* — which is not a pass, it is the harness announcing it cannot see that code
at all. Without that step I would have reported both as verified.

- After a green harness run, revert each change alone. A result that does not move
  means the harness does not exercise it. Say so instead of counting it as verified.
- **Prove the probe touched the file before reading its run.** On 2026-09-10 (Meegle
  14620356) the revert probe used relative paths, the Bash cwd had drifted to the
  scratchpad after an earlier `cd $S && node …`, so `cp`/`python` failed, the "reverted"
  run executed the FIXED code and printed 8/8 PASS. Only a `grep -c REVERT-PROBE` line
  in the same command exposed it. Use absolute paths in every probe, print the
  mutation's evidence (grep count) in the same output as the run, and treat a probe
  that changes nothing as unexecuted, not as "the fix didn't matter".
  It struck again on 2026-09-10 (Meegle 14621810): one `cd $S && npm i
  puppeteer-core` moved the persistent shell's cwd to the scratchpad, and the
  very next `grep DATABASE_URL .env` + `require("pg")` failed with "no such
  file" / MODULE_NOT_FOUND — a fake environment problem. Never `cd` in the
  Bash tool; run scratchpad installs as `npm --prefix $S i …` or in a
  subshell `( cd $S && … )`, and keep every later path absolute.
- **Reset the harness state between checks.** Same session: earlier pans had pushed
  the prompt box above the container's clipped top, so the last check's wheel landed
  on the page outside the canvas and read as "0 events reached — fix broken". Two
  diagnostics later it was geometry. Each check starts from a known state, or it
  measures the checks before it.
- The same run also caught a wrong fix: the first attempt put a latch ref *inside* the
  component the popover unmounts, so it was recreated null on every open and could
  never fire. Static reading called it correct; the browser called it unchanged. A
  latch must outlive what it latches.

Related: rule 12 (harness bypassing the product's data path) and rule 2 (knowing what
the suite cannot see). This is the third variant — the harness mounts the wrong layer.

### 26. "It is slow" is a measurement, not a reading — and dev costs mimic defects (2026-09-18)

Meegle 14294602, the studio's document GET: 7-8 s, fired twice. Reading the
route suggested two indexed queries; the real breakdown only appeared when I
measured it, and three of the four components were invisible from the code I
was looking at.

| Component | Measured | Where it lived |
| --- | --- | --- |
| Turbopack compiling the route on first hit | 5.5 s | dev only — NOT a product defect |
| the admission gate in `proxy.ts` | 1.27 s / 4 queries | a file the route never mentions |
| the route's own two queries | 0.66 s | the code I was reading |
| a fresh pool connection | 3.3 s | `lib/db/index.ts`, no settings at all |

Before proposing any performance fix, produce that table:

1. **Separate the one-off from the per-request.** A dev server's first compile
   looks exactly like a slow endpoint. Hit it six times; #1 is the compiler.
2. **Count round-trips, don't time the code.** Patch the driver
   (`pg.Client.prototype.query`) in a scratch test with the real
   `DATABASE_URL` and print the statements. The count is the fix's target;
   the milliseconds are just the network. *Patching `Pool.prototype.query`
   AND `Client.prototype.query` double-counts — the pool delegates.*
3. **Look above the handler.** Middleware/proxy work is charged to every route
   and appears in none of them. Here it was two thirds of the bill.
4. **Say which numbers are the environment.** Peter must not optimise a
   Pacific crossing that production does not pay.

And the class of the duplicate itself, worth its own line: **a value read only
when the response lands does not belong in a fetch effect's dependency array.**
`selfId = mySessionId ?? "local"` flipped when the realtime room state arrived
and re-issued the GET. Scan the whole tree for the shape, not the one hook —
it was in two.
