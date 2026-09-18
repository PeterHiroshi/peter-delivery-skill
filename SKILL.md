---
name: peter-delivery
description: Use at the START of any coding task for Peter (feature, bug fix, refactor) — the delivery contract that prevents the failure modes that have actually cost him time, and the routing to the right heavyweight skill. Invoke before writing code, not after.
---

# Delivery contract (Peter)

Peter uses me to get his time back. Every rule here exists because breaking it
already cost him hours — each is traced to a specific session in
[`references/failure-modes.md`](references/failure-modes.md).

This does not replace the installed packs (`superpowers`, `karpathy-skills`,
`ccl-skills`, `ui-ux-pro-max`); it closes the gaps that let me fail *while
following them*. See "This skill does not replace the packs" below.

**The measure of success is not "the task is done". It is "Peter did not have
to find my bugs for me."**

## The two failure modes to design against

Both are documented with evidence in
[`references/failure-modes.md`](references/failure-modes.md). Read it once if
you have not; it is the *why* behind everything below.

1. **Substituting available evidence for required evidence.** Every instance is the
   same shape: I check the thing I *can* check and report on the thing I *cannot*.
   - tsc/vitest green, reported as "done", when the criterion was visual (2026-09-04)
   - a dozen sampled keys, reported as "all keys present" (2026-09-07)
   - a file written, reported as "applied", without reading it back from the process
     that consumes it (2026-09-07)
   - a run's green badge, reported as "deployed", when every deploy job had skipped
     (2026-09-07)
2. **Filling an information gap with my own assumption instead of asking — or testing.**
   Treating "I did not find it" as "it does not exist"; stating a platform limitation
   from memory and building a plan on it (2026-09-07: `workflow_dispatch` — Peter
   challenged it, a two-minute probe showed I was wrong).

## Non-negotiables

These are not defaults to weigh. They are gates.

### 1. Never say "完成 / done"

Say what is verified and what is not:

> Logic verified (tsc, 462 tests, lint). **Visual: not verified** — I could not
> reach the panel in a browser. Do you want to look, or should I get the dev
> server up first?

Peter's single largest time sink is acting on a "done" that meant "the checks I
happen to be able to run are green." Never use one signal to stand in for
another.

### 2. Know what the test suite CANNOT see — then cover that gap yourself

Before trusting a green run, answer: **does this suite observe the kind of
defect I could be shipping?** Every stack has a blind spot, and it is usually
exactly where the acceptance criterion lives.

| If the criterion is | The suite usually cannot see it unless |
| --- | --- |
| what renders / copy / layout | it mounts components (jsdom/RTL, Vue Test Utils, XCTest UI…) |
| an HTTP contract | it exercises the route, not just the handler function |
| a query result | it runs against a real schema, not a mock |
| a build artifact | the build itself runs in CI |
| concurrency / ordering | it forces the interleaving |

Check the config, not your memory: `vitest.config`, `jest.config`, `conftest.py`,
`pom.xml` surefire config, `go test` tags. A project stating "no jsdom, test pure
logic not components" is telling you render bugs have **no automated home** —
then looking is not optional, it is the only coverage.

For anything that renders, see
[`references/visual-verification.md`](references/visual-verification.md). If
genuinely blocked, say so in those words and let Peter decide.

### 3. One report → enumerate the whole class before fixing

Peter reports one instance. Fixing only that instance is what he calls
挤牙膏 (squeezing toothpaste), and it is the thing he complains about most.

| He reports | Enumerate first |
| --- | --- |
| one label wrong | every label on that surface, and where each string comes from |
| control missing on surface A | that control across **every** surface × every model/state |
| two things look different | diff **all** shared style constants, not the one he pointed at |
| one param wrong | the full rendered param matrix per model per surface |

Write the enumeration as a throwaway script and print a matrix. In the session
that produced this skill, doing that once collapsed three separate fixes into
one — and found a bug Peter had not reported.

**If you find yourself thinking "later I should audit the rest" — that audit is
the first action, not a follow-up.**

**Enumerate by MECHANISM, not by the reported string.** On 2026-09-10 (math_ai,
LFX-453) Peter sent one screenshot: a Chinese subtitle "1 个产物 · 共 2 步" on the
English sidebar. `grep 产物` found exactly one site and would have been the whole
fix. Naming the mechanism first — *the backend synthesizes user-facing text, the
client renders it verbatim* — and scanning for THAT (an AST walk over every
`content=` / `title=` / `preview=` slot in `backend/app`) found 13 more sites in
the same class, plus an account-page map keyed by Chinese literals that was
missing four of the backend's labels. Peter's own words on this class: 「这不是特别
案例了已经」. The steps that work:

1. Say in one sentence what the defective *mechanism* is (not what the string is).
2. Write the throwaway scanner for the mechanism; print every hit with a verdict
   (fix / prompt-not-display / allowlist-with-reason / follow-up ticket).
3. Turn the scanner into a committed guard test so the class cannot regrow, and
   mutation-test the guard on the original defect's shape.

**A hand-written list of the class is itself an instance of the toothpaste
pattern.** On 2026-09-14 (moodio-agent, Meegle 14665233) the guard test pinned
"the six files the canvas mounts under a node" by name. Two overlays in the
same class lived in files mounted BY those six (a duration chip in
`components/video/`, a multi-shot editor in `components/chat/`) and kept the
bug; the independent review found them, not me. The guard now walks the import
graph from the two mount roots and allowlists exceptions WITH reasons. When the
class is "everything reachable from X", derive the set in the test (import
walk, registry read, glob) — a name list is the enumeration frozen at the
moment I stopped looking.

i18n corollary that decided the fix shape: **text composed on a GET endpoint can
never follow the UI language** — the backend has no locale on that request.
Either send structured data (counts, keys) and let the client localize, or route
through the config-driven catalog (`region.localized_message` in math_ai). A
frontend map keyed by the backend's Chinese sentence is the same defect wearing a
translation table.

### 4. Ask when the answer lives with Peter, not in the code

Stop and ask — do not assume — when:

1. A path/file/reference he gave does not exist on my side
2. A search **misses** and the conclusion depends on whether the thing exists
3. Fixing the environment means changing his machine (installs, deletes, config)
4. He relays third-party feedback whose original text I cannot see

**A real-world format that Peter already has a sample of is asked for, not
inferred.** On 2026-09-16 (Meegle 14294602-07, 中式/美式剧本版式) I started
deriving the two screenplay layouts from the prototype's CSS and my own
knowledge. Peter: "中文和英文版式我这里有具体的样例，你需要向我索要而不是自己去
推测". Typography, document templates, production sheets, export layouts —
anything that mirrors a document type people actually use — has a house
sample on his side. Ask for it first, name what it must show (every element
kind, margins, casing, punctuation), and build from the sample.

**A claim about what a function does is verified at THAT function, not at its
sibling.** On 2026-09-11 (LFX-453, PR #397) I told Peter and wrote in a code
comment that "the backend canonicalises short/long locale codes", having read
`_canonical_locale` being used by `resolve_output_locale`. The route I was
relying on called `set_request_locale`, which did an exact match and dropped
`en` silently. Copilot caught it. Before writing "X handles Y" in a comment, a
reply, or a PR body, open X's body — the one on the call path — and quote the
line that does it; a neighbouring helper with the right name is not evidence.

**"I did not find it" ≠ "it does not exist."** Report the search, not a verdict:

> I searched that 15MB file for DURATION / RESOLUTION / QUANTITY and got no
> hits. Am I searching wrong, or is this panel in a different file?

A wrong assumption here poisons every downstream decision and *causes* the
toothpaste pattern — reasoning from a false premise produces an endless stream
of small corrections.

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

### 6. Push and PR need their own approval, every time

Commit locally, then ask. `/goal` and "autonomously" cover doing the work, not
publishing it. Approval for one push does not carry to the next.

**The moment `gh pr create` prints a URL, the PR is not delivered yet — the
hand-off text is part of it, and it is written in the SAME reply, unprompted.**
Waiting to be asked has cost Peter a round trip more than once (2026-09-08, PR
#580). Which hand-off depends on the remote's organisation, so read it rather
than guessing from the directory name:

```bash
git remote get-url origin   # decide by the ORG in this, not the folder
```

| Remote org | Hand-off, written unprompted with the PR link |
| --- | --- |
| `JerryYang666/*` (moodio-agent, moodio-landing) | A Lark message: English, 1–3 sentences, pasteable |
| `IcestoneTech/*` (e.g. `math_ai`) | **No Lark text.** The `gh pr comment` review, the PR link on Jira, and the chat notification to Linc |
| anything else | Ask which hand-off applies, once, and record the answer in `references/projects/<repo>.md` |

**Peter may merge before the bot answers.** On 2026-09-10 he merged two hotfix PRs
sixteen minutes after they opened; the Copilot review, my fixes and three pushes all
landed on merged branches and reached nothing. Before pushing any post-review fix,
read `gh pr view <n> --json state,mergedAt`; if merged, the fix is a new PR off the
target branch, and Jira moves the moment the merge is seen (🔒 rule), not when I
finish polishing.

**Then wait for the CI review bots and act on what they say** (standing
instruction, Peter 2026-09-08). Any repo whose pipeline runs an automated
reviewer — Copilot on GitHub, or the equivalent elsewhere — has not finished
reviewing when `gh pr create` returns. Poll for the review, read every comment,
fix what is right, and reply on each thread saying what changed or why it was
declined. Do not wait to be asked, and do not treat the bot's verdict as
advisory noise.

```bash
gh pr view <n> --json reviews --jq '.reviews[].body'
gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate \
  --jq '.[] | "[\(.user.login)] \(.path):\(.line // .original_line)\n\(.body)\n---"'
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/replies -f body="..."
```

On PR #581 Copilot found two stale comments in one pass. One of them was not
just wording: the module header advertised a `⌘/Ctrl + drag to zoom` mode that
the canvas never constructed, so the branch was reachable from tests alone.
**A comment that contradicts the code is often dead code wearing a
description** — check which of the two is wrong before editing the comment.

Write it for a teammate scrolling a channel deciding whether it concerns them:
what changed, why they should care, anything they must act on (migration, flag,
blocking decision), and the link. **Two or three plain sentences — a colleague's
chat message, not a release note.** Lead with the thing people actually noticed;
extra fixes are "plus two smaller fixes in the same area", not a second paragraph
of equal weight. No em-dash-stitched clauses, no "comprehensive"/"robust", no
error strings unless a teammate must recognise them. Read it aloud: if it sounds
like a summary of a summary, cut it again. Anti-patterns and a worked example in
[`references/deliverable-formats.md`](references/deliverable-formats.md).

### 7. A config change is not live until the thing that reads it has re-read it

Writing a value is not applying it. Every layer has its own moment of reading, and
the gap between "the file says X" and "the running process sees X" is where a fix
looks done and isn't.

| Layer | Applies the change when |
| --- | --- |
| Docker `--env-file` | the container is **created** — `docker restart` re-runs the process with the *old* env; you must `rm` + `run` |
| GitHub Actions env vars | the next run starts; an in-flight run keeps the old values |
| A pipeline's own YAML | the run that starts *after* the merge — **re-running an old run executes the old file** |
| CORS / allow-lists in an env file | same as the process that read them (see Docker above) |

Verify at the layer that consumes it, never at the layer you wrote:
`docker exec <c> printenv KEY`, not `grep KEY .env`. On 2026-09-07 a restart was
declared as the fix for a missing key; the container had been *created* before the
edit, so the key never arrived and production kept failing for another twenty minutes.

### 8. A green run that did nothing is worse than a red one

Before reporting a pipeline as successful, ask **what it actually did**, not what it
concluded. Skipped is not passed.

- On 2026-09-07 a `Deploy` run finished **green with all four CD jobs skipped** — it
  built everything and deployed nothing. A tag would have reported a successful
  release over an untouched production.
- The cause was a GitHub rule worth remembering: a job whose upstream carries an `if:`
  with a status function is **skipped** unless it states its own `if:`. Silent, green.
- The reverse also happens: `v1.0.0` deployed everything correctly and went **red** on a
  verification step that lacked an IAM permission. The merge-back was gated on
  `conclusion == success`, so a fully successful release never reached `main`.

Read the per-job results, not the run's badge. When a run is red, establish whether
the *deliverable* failed or only the *check* did — they need opposite responses.

### 9. Enumerating a sample and reporting it as complete

"I checked the keys and they're all there" after comparing a dozen hand-picked ones is
a false statement, and Peter will find the missing one. On 2026-09-07 that pattern
missed `QUICK_ROUTER_API_KEY` — absent on all three hosts, with production v4 throwing
`RuntimeError` every time it was needed. Peter asked "did you really check them all?"
and the answer was no.

Diff the **whole set** mechanically (`comm -23 <(keys a) <(keys b)`), and say which
method you used. If you sampled, say you sampled.

Related trap from the same session: paginated APIs. `gh api .../variables` returns 10
by default; two variables that existed were reported as missing because they sat on
page 2. Any "X is missing" claim from a list endpoint needs `--paginate` before it is
worth saying out loud.

**A failed verification query is not a negative result.** On 2026-09-07, fanning out
16 PRs, six `gh pr create` calls hit `Post "https://api.github.com/graphql": EOF`.
The `gh pr list` run to check what actually existed hit the *same* transient error,
printed nothing, and the `comm -23` diff built on it duly reported all 16 bases as
missing — one step from creating 10 duplicate PRs. Ten of them existed.

The shape to recognize: **the error path and the empty result look identical once the
output reaches a pipe.** `cmd | sort > f` swallows the failure; `wc -l` then says 0,
and 0 reads as "none exist" rather than "I did not find out."

- Check for the error string before treating output as data. Retry the *check*, not
  just the action.
- The mechanical whole-set diff of rule 9 is only as good as the set it diffs. A
  correct `comm` over a silently-empty input produces a confidently wrong answer.
- After any batch operation, re-query and assert the **count** matches what was
  intended (`16 PRs / 16 bases`, no duplicates) — not just that the last call succeeded.

### 10. Prefer deriving over passing

Before adding a prop/param a host must supply, ask: **can the component compute
this itself from state it already has?**

- Derivable → derive it. Do not accept the prop.
- Genuinely host-specific → pass it, and add a test pinning the allowed number
  of per-host branches so drift fails loudly.

Rationale and the concrete case in
[`references/reuse-over-duplication.md`](references/reuse-over-duplication.md).
This one rule accounts for roughly half the bugs in the session that produced
this skill.

### 11. A file supplied by the requester still has to be checked against this repo

Copying an attachment verbatim feels safe — it is the requester's own file, and
changing it looks like overstepping. But a config file's *semantics* depend on the
directory layout it lands in, and the person who wrote it does not necessarily know
yours.

On 2026-09-07 the `robots.txt` attached to a Moodio SEO requirement carried
`Disallow: /assets/`, plainly meaning "do not index the brand logos." In that repo
`vite build` also emits the hashed `index-*.js` / `index-*.css` bundle into
`/assets/`. Shipping it as supplied would have told Googlebot not to fetch the code
that renders a client-side site — silently defeating the very requirement the file
came from. Nothing would have failed; the site would just have stopped ranking.

Before copying any supplied config into place, ask **what does this path/key/pattern
actually match in this repo?** — then verify with the tool that consumes it
(`urllib.robotparser` over the built file, not the source), the same way rule 7
demands. When a deviation is warranted: do not change it unilaterally, present the
options with the evidence, and once decided, record the deviation *at the source
file* so the difference does not later read as a copy error.

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

### 14. A latch must outlive what it latches — and a value guard beats a lifecycle guard

Meegle 14588335 took FOUR attempts because three of them guarded an effect with a
latch that reset at exactly the wrong moment:

1. latched a derived boolean that a mode change flipped false→true
2. latched a different boolean that a data-load flipped false→true
3. latched an identity — correct value, but the ref lived in a component the host
   mounts `key={node.id}`, so selecting a node rebuilt it as null

Each fix looked right, passed its tests, and Peter came back with the same bug.

Two rules came out of it:

- **Before trusting a ref/latch, ask what remounts the component that holds it.**
  Grep for `key=` on its ancestors. A ref in a `key`-ed subtree is per-instance
  memory, not per-entity memory, and the two look identical until the key changes.
- **Prefer guarding on the VALUE over guarding on the EVENT.** "Don't overwrite a
  value that is already set" needs no memory at all, so no lifecycle can defeat it.
  The final fix was one line — `if (params.aspect_ratio != null) return;` — after
  three attempts at remembering *when* to skip.

The other half: an independent review (`/codex`) found both the remount and a
second bug I had shipped — a heal-on-read that discarded a value the user could
legitimately choose, because I never checked whether the UI offered it as a real
option. **When you "clean up" a value as invalid, first check whether the product
lets the user pick it.**

### 15. Take the known-good path first, and cap the improvised one

The notes in `references/projects/<repo>.md` are a record of routes that ALREADY
WORKED. Reading them is not the same as taking them. On 2026-09-08 (Meegle
14588335) the repo note said, in order: the MCP browser profile is usually locked,
launch a private headless Chrome, drive it with puppeteer-core. I read that, then
still spent a stretch trying the MCP tool, then copying a Chrome profile, then
hand-decrypting its cookie store with Keychain + openssl — three dead ends the note
had already ruled out, before doing exactly what it said.

**Before starting any sub-task that has a note, name the route from the note and
take it. Improvise only after it has actually failed here, today.**

It happened again on 2026-09-08 (Meegle 14552800), on a sub-task as ordinary as
"get the dev server up". `references/projects/moodio-agent.md` already said, in
one section: `npm ci` fails on this repo (lockfile out of sync, pre-existing on
main) so use `npm install`; and **do not symlink a worktree's `node_modules`**
because Turbopack will not follow it. I ran `npm ci` (failed), then symlinked
(Turbopack panicked: "Symlink [project]/node_modules is invalid, it points out
of the filesystem root"), then fell back to a full `cp -R` of 647 packages. Both
dead ends were spelled out in the note I had already read. Peter was waiting the
whole time.

The trigger to catch: **the moment a sub-task is "environment setup" in a repo
that has a note, open the note's environment section FIRST and follow it
literally.** Reading it earlier in the session does not count — the routes only
help if they are taken at the moment of use.

The same session shows the reverse failure — improvising when the cheap
authoritative source was one query away:

| What I did | What settled it | Cost |
| --- | --- | --- |
| Read routing code, ran 2000 weighted-shuffle draws to prove KIE was primary | One `console.log` of the resolved order, and the raw dev-server log | Two confident, opposite, WRONG conclusions |
| Inferred the failure cause from the `error` column | `select params, error from video_generations` — the params were right there | Three rounds of guessing |
| Reasoned about which provider KIE-vs-Volcengine ran | The stdout Peter already had open | An entire exchange |

The pattern: **when the system already records the answer, query it before
reasoning about it.** A DB row, a stdout log, a `console.log` in the live path.
Reading code tells you what SHOULD happen; those tell you what DID.

A third instance, 2026-09-14 (moodio-agent, Meegle 14452515): selecting a
canvas node from a puppeteer script failed **six** times in a row (synthetic
pointer sequence, `page.mouse`, relaxed selectors, readiness gates, a locale
reset) while the repo note's 2026-09-10 entry — "prefer the MCP `click` by
uid for selection on any canvas" — sat unread at the moment of use. Four of
the PR's acceptance criteria shipped as "not verified" because of it.

Practical cap, per sub-task:

- **Two failed attempts at the same sub-goal → stop and switch class of evidence.**
  Not a third variation of the same approach. Move from reading to measuring, or
  from measuring to asking Peter for the artifact he can see and I cannot.
- **Say which route you are taking and why** ("the repo note's headless-Chrome
  recipe", "querying the generations table"), so a wrong choice is visible to
  Peter immediately instead of after the third dead end.

Related: rule 4 (ask rather than assume) names WHEN to ask; this names when to stop
improvising and reach for the evidence that already exists.

### 16. A clarifying answer resolves the question I ASKED — re-read the source after it

On 2026-09-08 (Meegle 14552800) the ticket said "鼠标模式下缩放支持：command+鼠标
中键". I offered Peter two readings and he answered "鼠标中键就是鼠标滚轮,它可以点击,
采用第二种". I heard "option 2 of your list" and built ⌘ + middle-button **drag** =
zoom. He had actually said, in the first half of the same sentence, that 中键 IS the
scroll wheel — the requirement was ⌘ + **wheel scroll**. I shipped the wrong feature,
he tested it, and the real bug (`metaKey` missing from the wheel handler's zoom
condition, so ⌘ + two-finger scroll panned on a Mac trackpad) stayed unfixed.

- After any clarification, **re-read the original requirement text with the answer in
  hand** and check the whole answer, not the part that selects between my options.
  Peter's answers often carry the reasoning that makes my options wrong.
- An answer that restates a term ("X 就是 Y") is a correction of my framing, not a
  vote. Treat it as the more authoritative half of the sentence.

### 17. Never delete working code on the strength of my own badly-framed question

Same session, immediately after. Having built the wrong gesture, I asked "middle-drag
pan — keep or remove?" and Peter said 移除. I deleted the whole feature. But
requirement **1** of that same ticket is "支持鼠标中键移动画布" — middle-drag pan was
explicitly asked for. My question had silently bundled it with the wrong ⌘ + drag zoom
I had just built, so his answer was about my mistake, not about the requirement. He
came back with 「中键拖动功能怎么又没了,拆东墙补西墙呀你是」.

- Before deleting anything, check the deletion against the **written requirement**, not
  against the last thing said in chat. If they disagree, say so and ask — do not let my
  own confused question authorize destroying a requirement.
- When my question was ambiguous, the answer inherits the ambiguity. Narrow the
  question and re-ask rather than acting on it.
- Recovery: the files were never committed, but the full text survived inside a
  `/tmp` review packet, which is where I restored them from. Uncommitted work that
  matters should be committed before any restructuring, not held in the worktree.
- It happened again on 2026-09-10 (Meegle 14441990), by my own hand and with no
  question involved: a revert probe ended with `git checkout -- <file>` to "restore
  the probe", which restored the file to HEAD and discarded 60 lines of my own
  uncommitted edits in it (plus Peter's). **Commit locally BEFORE the first revert
  probe**, and restore a probe by reversing the exact edit (the same
  assert-count-then-replace script that applied it), never by `git checkout`.
- Two more from the same day's wrap-up. (a) `git add <deleted-path> && git commit
  --amend` failed on the pathspec and the `&&` chain silently skipped the amend; I
  read "ok" from the script and moved on with the OLD commit in place. After any
  amend/commit, read `git show --stat HEAD` — the command's exit is not the commit's
  content. (b) `git checkout -- <file>` restores to HEAD, and HEAD was my own earlier
  commit, so a "revert" left that commit's 3-line addition in the file and in the
  next amend. Reverting my own work means `git checkout <base>...` (the branch base),
  and a final `git diff <base>...HEAD --stat` must list only the files the change
  needs.

### 18. A value read back after a mechanical rewrite cannot tell "original" from "synthesized"

On 2026-09-09 (LFX-451) the reply bubble showed `Final answer: Final answer: (1) 0 (2) 1`.
The fix kept the explainer's human sentence *only if* the conclusion step already stated
every locked value; otherwise the step was overwritten with the mechanical
`Final answer: …` line. The helper that fetched "the human-readable sentence" ran **after**
that overwrite, re-read the conclusion step, found every locked value in it (of course —
the machine line contains them all) and returned the machine line as the sentence. Peter
saw it within minutes of running the branch.

- If a mutation can replace X with a synthesized value that satisfies the same predicate
  as a genuine X, then "read X back and re-check the predicate" is not a detector. Capture
  the decision at the point of mutation (return it, tag it) and pass it forward.
- The offline harness that validated the fix used a case where the sentence *passed*, so
  the rewrite branch was never exercised. Test the branch where the guard fails, not only
  the one where it succeeds.

### 18. A feature that ends in a provider call is verified at the provider's request body

On 2026-09-09 (Meegle 14583294) the Kling reference-version entrance was "done" three
times over at the UI — dialog, Details section, picker tab, guide bar, all screenshotted
and mutation-tested — and Peter asked the only question that mattered: does the picked
version reach the model provider as its `elements` parameter, "否则一切都是徒劳". The
dev database held four generations with `kling_elements` ever, none from a library
element: the path had never run. Tracing it end to end found a soft link — on the chat
surface the attachment reached the agent as a text line and nothing forced it into the
staged generation.

- For any feature whose value is a call to an external system, the deliverable is the
  request body that system receives. Write the test that drives the production path from
  the surface's first server-side shape to the mocked network call, per provider, and
  mutate each link.
- Query what the system has recorded (`select params from …generations where …`) before
  reasoning from code. Zero or four rows is the answer to "has this ever run".
- Anywhere an LLM sits between the user's choice and the request, ask what ENFORCES the
  choice. "The prompt tells it to" is not enforcement.

### 19. Verify the SURFACE the change touched, not the change — write the sweep before the run

Meegle 14583294, 2026-09-09, three passes in one day, and Peter found a defect after
each: the Create-page button opened no dialog (a second desktop key I never opened);
the three-column form overflowed (my harness was 560px wide, the real panel 460); a
hint rendered as a raw i18n key (a `{param}` I never passed, in a locale I never
looked at); a version with no video showed a video tile in its hover flyout (the
sibling element that renders the same row); a node lost its attached card once the
video landed (the completion path that REBUILDS the metadata). Every one was on the
surface my change touched and outside the path my verification walked. Peter's words:
"有很多问题之前都没有及时发现，现在只能打回来再重新搞".

The pattern is one omission repeated: I verified the code I wrote, at the size I
built it, in the locale I read, on the model I picked, through the path I coded.
Before the browser run, enumerate the dimensions the changed surface has and sweep
them — that enumeration is the test-case register the `ccl-skills:testing-strategy`
skill asks for, and it is written BEFORE the harness, not after Peter's screenshot:

- **width**: the real container's width (measure it in Peter's screenshot or the
  layout code), not the harness default;
- **locale**: all five, asserting the rendered strings from the catalog and that no
  `namespace.key` text appears; every `{param}` key needs a values object (now a
  static test, `i18n-params-are-passed.test.ts`);
- **row/data shape**: every combination the rules allow (images / video / audio /
  legacy both), on EVERY element that renders the row — the row, its meta, its
  flyout, its edit form;
- **model family**: every family the gate covers, off the registry, including the
  ones that take nothing (Kling 2.6);
- **write paths**: every builder that rewrites the data the UI reads (completion
  converters, reruns, spawns, PATCH allow-lists) — grep the field name across
  lib/ and app/ and read each hit;
- **cross-tab / second key**: any cache keyed by an id the page can have more
  than one of.

Then write the register with a verdict column (`pass` / `pass-browser` / `blocked`
/ `live-only` / `gap`) and hand THAT over. A green run over the path I coded is not
a verification of the feature; it is a verification of my typing.

### 20. "Reasoned from code, not seen" is the line that names where the guard test goes

On 2026-09-10 (Meegle 14589462, PR #602) the fix closed the asset picker at
upload hand-over. I read that the Camera/Voice tabs call `onUpload` and THEN
`onClose`, saw that a toggle would reopen the picker, and made the upload
handler's close idempotent — then wrote in the report "the upload-then-close
order was checked by reading code, not in a browser". Copilot's first pass
found that `onClose` reaches the host's `onOpenChange`, which was STILL the
toggle. I had made one side of a double call idempotent and left the other.

- A double-call is fixed only when BOTH callers land on the same idempotent
  path. Grep for every site that reaches the state (`onOpenChange=`,
  `onClose=`, the setter itself), not just the one I am editing.
- The sentence "checked by reading, not verified" in my own report is not a
  disclaimer — it is the address of the missing guard test. Write that test
  BEFORE `gh pr create`; the bot will otherwise write it for me as a finding.
  Here it was a 60-line source pin (`setIsAssetPickerOpen((v) => !v)` must
  not exist; dismiss and upload share `closeAssetPicker`), mutation-checked.
- Run the test suite BEFORE the push, not in parallel with it. Same session:
  `vitest` and `git push` went out in one message, the suite failed on a
  source-proximity pin (`handleAssetPickerUpload[\s\S]{0,400}wire…`) my
  comments had pushed past 400 chars, and the branch was already on origin.
  In this repo, long explanations go in a docblock ABOVE the identifier a
  pin anchors on; body comments count toward the window.

### 21. A rebase or conflict resolution must have NO side effects — prove it, every time

Standing instruction from Peter (2026-09-14, Meegle 14661162): whenever a
branch is rebased onto or merged with its target, the result must carry
BOTH sides' behaviour intact — nothing from the target lost, nothing from
the branch lost — and this holds whether or not he says so. "Rebase onto
main" always means "rebase and prove nothing changed but the base".

The proof is mechanical, not a feeling that the conflict markers were
resolved sensibly:

1. Before: `git diff <old-base>..<old-head> > before.patch`.
2. Rebase / merge. Resolve conflicts by reading BOTH sides' intent; never
   resolve by taking "ours" or "theirs" wholesale.
3. After: `git diff <new-base>..<new-head> > after.patch`, then
   `diff <(grep -v '^index \|^@@' before.patch) <(grep -v '^index \|^@@' after.patch)`.
   The delta must be empty, or every remaining line must be explained by a
   deliberate accommodation of the target's change — list those lines in
   the report.
4. A clean textual merge is not a clean semantic merge. Run the full gates
   (tsc, the whole suite, any project scripts) on the rebased tree, and
   grep the target's incoming diff for the mechanism the branch generalised
   (a new special case the branch's abstraction should now cover, a renamed
   function the target still calls by the old name).
5. Report: incoming commits, overlapping files, the delta result, the
   gates — and say "rebased onto <sha>" with the sha, not "rebased".

Never `--force` over a remote branch someone else may have pulled without
saying so; never use `git checkout --ours/--theirs` on a file that both
sides changed; never let `npm install`'s lockfile drift ride along with a
rebase.

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

### 23. `ccl-skills` are opt-in, not the default (Peter 2026-09-15)

Same session. The `ccl-skills` pack (product-rd-workflow, web-react-dev,
multi-agent-delegation, code-review, testing-strategy…) was loaded through
its hooks four times; each load is thousands of tokens of process text,
and its gates pushed the work toward design docs, delegation charters and
coverage sweeps while the replica was still wrong. Peter: "ccl-skills 要
慎用，这个 skills 会花费大量 token 和时间……特别是上述这种任务，简直就是浪费时间".

- Do not invoke any `ccl-skills:*` skill on my own initiative. Not for
  routing, not for review, not because a hook's text suggests it.
- If a hook checkpoint BLOCKS an edit until a ccl skill is loaded, load the
  one it names, once, and continue; do not follow that skill's routing
  into further ccl loads or dispatches. Say in the report that the load
  was forced.
- Use them only when Peter asks by name, or for a genuine backend risk
  gate (money, permissions, data loss, migrations) — and say so first.
- The review that matters for UI work is Peter's; for backend work a single
  focused adversarial pass (a subagent with the diff and a numbered
  checklist) is enough and costs a fraction.

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

### 27. A surviving mutation is an answer, not a gap to paper over (2026-09-18)

Same session: three mutations of the GET de-duplicator, two caught, one
survived (removing `.clone()` for the first caller). The tempting move is to
invent an assertion that fails. The honest one is to work out whether the line
is observable at all — it was not, because every joiner attaches before the
entry is dropped — and write that reasoning where the line is, so the next
reader does not delete it as dead.

Report it as "one assertion survived its mutation and here is why no test can
tell", never as silence.

### 28. A worktree can have another session in it (2026-09-18)

`git status` changed under me twice mid-session: another Claude was editing
shot routes in the same worktree. Consequences, all of which bit or nearly bit:

- **Stage paths explicitly.** Never `git add -A`, never `git add .`.
- **A test that fails after your change is not necessarily yours.** Prove it:
  intersect the failing test's file reads with `git show --name-only HEAD`. An
  empty intersection plus "their file is dirty against HEAD" is the proof.
- Re-run the gates right before reporting — a green run from ten minutes ago
  was over a different tree.

## Definition of done

Report per line. **Any ❌ or ⚠️ means the answer is not "done."**

| # | Check | Applies when |
| --- | --- | --- |
| 1 | tsc / relevant tests / lint green | always |
| 2 | **Looked at the rendered result** | anything that renders |
| 3 | **Read the design source; said so if absent** | UI with a spec |
| 4 | **Enumerated the whole class, not one instance** | any bug report |
| 5 | New assertions mutation-tested | new tests added |
| 6 | **Explicitly listed what I did NOT verify** | always |
| 7 | Design doc confirmed before code | non-trivial change |
| 8 | **Read the value back where it is consumed**, not where I wrote it | any config / env / infra change |
| 9 | **Checked what the run did, job by job** — green ≠ deployed, skipped ≠ passed | any pipeline change |
| 10 | **Re-queried and asserted the count matches** — and did not read a failed query as an empty result | any batch / fan-out operation |
| 11 | **Checked what a supplied file's patterns match in THIS repo** | copying a requester's config in |
| 12 | **Harness reads the product's data path, and the review env carries the new data** | any verification that mounts a component with in-code data |
| 13a | **Checked what remounts the component holding a ref/latch** (`key=` on ancestors) | any fix using a ref to remember |
| 13b | **Guarded on the value, not the event**, where a value guard is possible | any "only do this once" effect |
| 14 | **Named the known-good route from the repo note and took it first**; improvised only after it failed today | any sub-task the notes already cover |
| 15 | **Queried the recorded answer (DB row / live log / a `console.log`) before reasoning from code** | any "why did this fail at runtime" question |
| 16 | **Wrote the hand-off text (Lark, or the org's equivalent) in the same reply as the PR link** — decided from `git remote get-url origin` | every PR created |
| 16b | **Waited for the CI review bot, fixed what it got right, and replied on each thread** | any repo whose pipeline runs an automated reviewer |
| 17 | **Re-read the original requirement text after a clarifying answer**, checking the whole answer and not just the part choosing between my options | any clarification received |
| 18 | **Checked a deletion against the written requirement**, not against my own possibly-mis-framed question | removing any working behaviour |
| 19 | **Captured a guard's decision at the mutation site instead of re-reading the mutated value** | any "keep original unless…" logic |
| 13 | **Reverted each fix alone and saw its defect return** — a result that does not move means the harness never exercised it | any browser/harness verification |
| 19 | **Asserted the provider's request body through the production path**, per provider, and asked what enforces the user's choice across any LLM hop | any feature that ends in an external call |
| 20 | **Wrote the test-case register with the sweep dimensions (width × locale × data shape × model family × write paths × second key) BEFORE the browser run**, and handed the register over with verdicts | any UI or rules change |
| 21 | **Proved the rebase/merge had no side effects**: before/after patch delta empty or every line explained, full gates on the rebased tree, target's incoming diff grepped for the branch's mechanism — whether or not Peter asked | any rebase, merge, or conflict resolution |
| 22 | **Handed Peter a numbered test-case list; no browser/devtools/headless run unless he asked or approved my ask** (rule 24) | any UI round |
| 23 | **Kept backend, interaction logic and prototype markup in separate homes** (rule 25) — pure logic testable without the component, server free of UI notions | any prototype replica |

**A guard test's self-test must use the defect's VERBATIM shape, not a paraphrase.**
On 2026-09-10 (LFX-453) the AST guard's own fixture inlined the leaking
expression as `Item(preview=f"…" if a else "")`; the real defect was
`preview = f"…" if a else ""` then `Item(preview=preview)`. The fixture passed,
the scanner ignored `ast.Name`, and the guard was green over the exact bug it
was written for. Independent review (Codex lane, four challenge rounds) found
that, then that my fix kept only the *last* assignment (a later `preview = ""`
untainted it), then that my "skip dicts with a `role` key" prompt exemption also
skipped the API's own history messages, which carry a role. Three rounds on one
test. The rules: paste the original defect's lines into the fixture unchanged;
taint conservatively (any assignment, any branch); scope an exemption by the
exact shape of the thing exempted (bare `{role, content}`), not by one key it
shares with the data you protect. And the behavioural test that asserts the
*output* (`preview == ""`) is what actually caught the bug in the probes — keep
both, and say which one moved.

The same review also found a `||` that kept a stale count when an empty array
was authoritative (`session.artifacts?.length || s.artifactsCount`), and a live
update computing `stepsCount` from the active artifact while the reload path
summed all artifacts. **A field the client patches locally must be derived by
the same rule the server uses on reload** — put that rule in one helper and
test it against the server's semantics.

Mutation testing (#5) is cheap and has repeatedly caught my own vacuous
assertions — including one that passed because it matched a string inside a
comment. Break the code, confirm the specific test fails, restore. See
[`references/testing-that-earns-its-keep.md`](references/testing-that-earns-its-keep.md).

## This skill does not replace the packs — it closes their gaps

Peter has `superpowers`, `karpathy-skills`, `ccl-skills`, `ui-ux-pro-max` and
others installed. **Two of the rules above already exist there, and I violated
them anyway.** That is the honest starting point:

| Existing skill | Says | Why I still failed |
| --- | --- | --- |
| `superpowers:verification-before-completion` | "no completion claims without fresh verification evidence" | I *did* run every command I had. **Its gap: it assumes a command exists that proves the claim.** For a render bug in a node-only repo, none does — so the iron law was satisfied and the bug shipped anyway |
| `karpathy-guidelines` §1 | "Don't assume. If uncertain, ask." | Generic. **Gap: it does not name the trigger that fires most** — a search that misses being read as proof of absence |
| `superpowers:systematic-debugging` | root cause before fixes | Good, and it scopes to *one* bug. **Gap: nothing tells me to enumerate the whole class** the reported bug belongs to |

So the rules here are deliberately narrower than the packs': they name the
**specific** trigger, in the **specific** repo, with the evidence of what
happened when it was missed. A general principle I already agreed with did not
stop me; a concrete trigger has a chance.

**Use the packs.** `verification-before-completion` before any completion claim,
`systematic-debugging` on any bug, `andrej-karpathy-skills:karpathy-guidelines`
while writing. This
skill adds what they cannot know: which criterion has no command, which repo
hides its design file, and which two surfaces must both be checked.

## Routing: which heavyweight skill, if any

Peter's read is correct — `ccl-skills` has broad coverage but its review gates
still miss UI defects. That is a **category mismatch**, not a skill defect.

Always in play, regardless of task:

- `superpowers:verification-before-completion` — before any completion claim
- `andrej-karpathy-skills:karpathy-guidelines` — while writing code (simplicity,
  surface assumptions)
- `superpowers:systematic-debugging` — the moment there is a bug

NOT in play by default: anything under `ccl-skills:*` (rule 23). The old
line "`ccl-skills:code-review` after changing code" is withdrawn; a focused
adversarial subagent pass on the diff replaces it for backend work, and
Peter's own review replaces it for UI work.

**Invoke these by their plugin-qualified names**, exactly as listed. A bare
`karpathy-guidelines` is not resolvable; the Skill tool needs the
`<plugin>:<skill>` form.

Then by task shape:

| Task | Route |
| --- | --- |
| **References a prototype / mockup / existing UI** | Rule 22: render it, replicate 1:1, hand both screenshots over, WAIT. Tests, i18n, reviews and backend hardening only after Peter accepts the replica. No design doc, no ccl-skills |
| **UI / interaction / visual** | This contract + **look at it**. `ui-ux-pro-max` for design *choices* (palette, type, a11y), then [`references/ui-design-principles.md`](references/ui-design-principles.md) for the judgements Peter has already made (no action gated on a fetch, primary task in the first viewport, geometry as evidence). **Skip `code-review`** — it reads a diff and cannot see a render |
| Bug, cause unknown | `systematic-debugging` |
| Pure logic, backend, data flow | Small design note (three bullets) → build → tests → one adversarial subagent pass on the diff. `ccl-skills:product-rd-workflow` only if Peter asks (rule 23) |
| Money / permissions / data loss / migrations | Say the risk out loud, design note first, adversarial pass in **challenge** mode; `ccl-skills:feature-risk-router` only if Peter asks |
| Needs test layer decided | Decide it in the design note; `ccl-skills:testing-strategy` only if Peter asks |
| Multi-step feature | `superpowers:writing-plans` → `executing-plans` |

**Category check before invoking anything heavy:** does this tool observe the
thing that decides success? `code-review` reads diffs. `ui-ux-pro-max` supplies
design knowledge. Neither watches a component render. Running them on a render
bug is how "the full process ran and bugs still shipped" happens.

**Do not spend more time configuring a gate than the gate can return.** In the
session that produced this skill I burned time on `review_gate.sh` plan schemas
and never got a single run to completion because HEAD kept moving. If a gate is
not returning value, say so and move on.

## Opening moves

Concrete first actions for a bug fix, a feature, or a UI task — plus how to
respond when Peter pushes back — are in
[`references/task-playbook.md`](references/task-playbook.md). Read it when
starting a task, not when stuck.

## Project context

Peter works across ~90 repos in many stacks. **Assumptions carried from the last
project are a reliable source of wasted time.**

Before coding in a repo you have not touched recently, run the seven questions in
[`references/project-onboarding.md`](references/project-onboarding.md) — what the
gates do *not* cover, which package manager is authoritative, whether you are in
a worktree where ignored paths are invisible, where truth lives, the i18n
contract, what must not be touched, and local conventions.

Accumulated notes for specific repos live in `references/projects/`. Read the one
for the repo at hand if it exists; add to it when you learn something costly.

**Reading it is not taking it.** Those notes are routes that already worked, and
the cost of re-deriving one is measured in this session's dead ends, not in
theory. Before each sub-task (get a browser up, find why a run failed, verify a
render), name the route the note gives and take that first — see rule 15. If no
note covers it, that sub-task is the one worth writing up afterwards.

## Keep this skill current (standing instruction, Peter 2026-09-07)

This file is the record of what has actually cost Peter time. It is only worth what
gets written back into it.

**At the end of any task that produced a durable lesson, update this skill and push it.**
Not "if it feels noteworthy" — if the session contained any of the following, it goes in:

- a mistake I made that a rule here would have prevented (→ sharpen that rule with the
  new evidence, do not add a near-duplicate)
- a mistake no rule covers (→ new rule in **Non-negotiables**, with the date and the
  concrete failure; abstract rules without a scar do not change behaviour)
- a repo-specific trap, credential path, or environment quirk (→
  `references/projects/<repo>.md`, creating it if absent)
- a correction Peter made to my reasoning (→ wherever the wrong reasoning would recur)

Then commit and push to `origin` (`PeterHiroshi/peter-delivery-skill`). The repo is
Peter's, the push is expected, and it does not need separate approval the way a project
push does. Keep entries short and evidence-bearing: what happened, what it cost, what to
do instead. Delete rules that stop earning their place.

## Working style

- **Reply in Peter's language** (usually Chinese). **Repo artifacts in English** —
  docs, comments, commits, PRs. Chinese only in scratchpad. (`docs-must-be-english`)
- He is technical and reads diffs. Do not soften findings or pad with process
  narration.
- When he pushes back, check the facts first. If he is wrong, say so with
  evidence — he corrects course on evidence, and agreeing to be agreeable wastes
  his time.
- Correcting my own earlier claim is required, not optional. State it plainly
  once and move on.
- Do not re-litigate a decision he has made.
