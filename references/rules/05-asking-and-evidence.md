# Where the answer comes from: Peter, the note, the recorded data — or my assumption

The second failure mode: filling an information gap with my own assumption instead of asking, or measuring.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

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

**The same trap wearing a review's clothes (2026-09-20, moodio-agent PR #744).** A
PR gave every asset card one fixed cover box, to line a row up. `git log -S` on the
construct it replaced showed the board had HAD a fixed box until PR #718 took it
out, on this reason in its commit message: *"a marked picture was cropped to the
category's shape"*. The PR was reinstating, against a new shape, the very complaint
a previous round had been asked to fix — and neither its description nor the code
said so. **Before judging a changed value, `git log -S '<the exact construct>'` the
line it replaces.** For a UI value the written requirement often exists nowhere but
in the commit message that put it there. Peter then chose a third way (the fixed box
AND the whole picture, `object-fit: contain`) that neither round had offered — which
is what the history made askable.

**And wearing an adversarial review's clothes (2026-09-22, moodio-agent Meegle
14993494).** Peter had asked twice for a unit frame to resize from all four corners
"like a zone". A review pass reported that moving the left/top edges would make a
later-seeded member overlap the moved ones by 60–160 px. I cut the frame to one
corner and asked him to confirm. His reply: 「为什么没有和已有的"区域"节点一样的自由缩放
方式（4个角支持拖拽）」. Tracing the finding's trigger took five minutes and shrank it.
Planned-cell seeding runs only when a member first gets text, or when one node is made
on demand; joining a unit on the canvas keeps the dropped position. It was the same
class as a user moving nodes by hand. **A finding is a hypothesis about severity.
Before it removes something the requirement names, grep who calls the code path and
from which user flow, then fix inside the requirement.** A finding that proves the
requirement truly impossible goes to Peter with that evidence. A plausible one does
not justify a cut.
