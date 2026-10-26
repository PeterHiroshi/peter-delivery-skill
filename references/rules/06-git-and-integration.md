# Git, publishing and integration

Committing, pushing, handing off, rebasing, and sharing a worktree with another session.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 6. Push and PR need their own approval, every time

Commit locally, then ask. `/goal` and "autonomously" cover doing the work, not
publishing it. Approval for one push does not carry to the next.
A request to change something ("全部使用最新的git action命令版本") is the same: it covers the
edit, not the push. On 2026-10-20 I pushed four repos' CI changes (one of them a `main` that
deploys) on that request alone — wrong; commit, show the diff summary, ask.
An approved deploy plan ("push main, let CI run") covers the pushes it names. A fix found while
watching that CI is a NEW push — the same day I pushed five fix commits to a fresh repo's
deploying `main` under the plan's approval. Commit the fix, ask, then push.

**One standing exception** (Peter, 2026-09-20): **this skill's own repo**
(`~/.claude/skills/peter-delivery`) — commit and push it without asking. It is
his own tooling, nobody reviews it, and asking each time was pure friction. It
does not extend to any product repo, and it does not make PRs automatic
anywhere. Note the repo has other sessions in it (rule 28): push what you
committed, and read `git log origin/main..HEAD` first — someone else's commit
riding along is worth a line in the report.

**The moment `gh pr create` prints a URL, the PR is not delivered yet — the
hand-off text is part of it, and it is written in the SAME reply, unprompted.**
Where the organisation below requires Lark, every final PR hand-off must have
an explicit **Lark message** section: a self-contained, copyable English message
with the actual PR link inside. This applies to existing and updated PRs too.
Do not substitute a generic English closing line, rely on an earlier reply, or
omit the message for brevity. Check that it is present before ending the reply.

Waiting to be asked has cost Peter a round trip more than once (2026-09-08, PR
#580). Which hand-off depends on the remote's organisation, so read it rather
than guessing from the directory name:

```bash
git remote get-url origin   # decide by the ORG in this, not the folder
```

| Remote org | Hand-off, written unprompted with the PR link |
| --- | --- |
| `JerryYang666/*` (moodio-agent, moodio-landing) | A Lark message: English, 1–3 sentences, pasteable — **and the PR link filed on the tracker item** (below) |
| `IcestoneTech/*` (e.g. `math_ai`) | **No Lark text.** The `gh pr comment` review, the PR link on Jira, and the chat notification to Linc |
| anything else | Ask which hand-off applies, once, and record the answer in `references/projects/<repo>.md` |

**The tracker item is the source record; file the PR link on it, unprompted.**
Every org above already says so in its own words — Jira for `IcestoneTech/*`,
and for a Meegle-tracked task (moodio-agent):

```bash
meegle comment add --project-key ozn2tr --work-item-id <id> --content '<markdown>'
meegle comment list --project-key ozn2tr --work-item-id <id>   # read it back
```

In Chinese, since it is read in Meegle: the PR link as `[#<n> <title>](<url>)`,
branch and commit count, the CI verdict, the root cause in two sentences, what
the fix does, where the design doc lives, and the numbered browser cases with
未验证 stated plainly. Peter, 2026-09-20: 「comment PR链接进入 meegle 源记录中，
以后也要自动进行这一步」 — a PR that lives only in a chat reply and on GitHub
leaves the issue with no trace of how it was resolved. The CLI token lasts ~2 h,
so `meegle auth status` belongs at the START of the PR round, not after it.

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

### 28. A worktree can have another session in it (2026-09-18)

`git status` changed under me twice mid-session: another Claude was editing
shot routes in the same worktree. Consequences, all of which bit or nearly bit:

- **Stage paths explicitly.** Never `git add -A`, never `git add .`.
- **Explicit staging is not enough — `git commit` commits the whole INDEX.**
  2026-09-18, same worktree: I staged my three files by name and committed,
  and the commit carried four files another session had left staged
  (`ghostUnitId` work it was mid-way through). Read `git diff --cached
  --name-only` right before committing and confirm it is exactly your list,
  or commit by pathspec (`git commit -F msg -- <paths>`). Recovering it means
  `git reset --soft HEAD^`, `git restore --staged <theirs>`, commit, then
  `git add <theirs>` to put their index state back — and note that in zsh an
  unquoted `$VAR` holding several paths does NOT word-split, so a pathspec
  built that way fails as one long filename.
- **A test that fails after your change is not necessarily yours.** Prove it:
  intersect the failing test's file reads with `git show --name-only HEAD`. An
  empty intersection plus "their file is dirty against HEAD" is the proof.
- Re-run the gates right before reporting — a green run from ten minutes ago
  was over a different tree.
- **Mutating a shared file can erase a peer's write.** "cp file → edit one
  line → run tests → cp back" overwrites anything another session wrote to
  that file inside the window (2026-10-19, five sessions on one branch).
  Message the peers before mutating a file they work in, or compare its mtime
  just before restoring and abort the restore if it moved.

### 33. CI runs warning-free: every action on its latest release, verified (Peter 2026-10-20)

Peter: 「Node.js 20 is deprecated. 作为完美主义者，现在git action中会有很多这种warning，请全部使用最新的git action命令版本」.
math_ai, limfx-harness, limfx-skills and limfx-tools still pinned Node 20 actions (checkout@v4,
setup-uv@v5, ssh-agent@v0.9.0, setup-qemu@v3 …); every run carried deprecation annotations.

Whenever I add or touch a workflow — and once in each repo I start working in:
- **Pin from a query, not from memory.** `gh api repos/<owner>/<repo>/releases/latest`, then the
  `runs.using` of that tag's `action.yml` must be the current Node runtime (node24 as of 2026-10).
  Use the floating major tag only when it resolves to that release
  (`gh api repos/<o>/<r>/commits/vN`); some actions publish exact tags only (astral-sh/setup-uv
  since v8 → `@v10.3.0`). A composite/docker action has no Node runtime — still take its latest.
- **Read the breaking notes of every major crossed, against the inputs we pass.** 2026-10-20:
  setup-uv v6 stopped auto-activating the venv (harmless only because every step uses `uv run`),
  download-artifact v5 changed by-ID paths and v8 fails on hash mismatch, setup-node v5 caches
  automatically, configure-aws-credentials v5 tightened boolean inputs.
- **`actionlint` clean** (it runs shellcheck on `run:` blocks). A finding that is not mine or not
  fixable — an unknown-but-valid key such as `concurrency.queue` — is named in the commit
  message, not left silent.
- **The next run's annotations are the evidence**: zero warnings, "Post Run" cache/agent lines
  included. Version bumps without reading a run afterwards are not done.
- **A commit has several workflow runs — read all of them.** `gh run list --commit <sha>`, wait for
  every one, then the annotations of every check run (`gh api repos/<r>/commits/<sha>/check-runs`
  → `check-runs/<id>/annotations`). 2026-10-20 I watched the first run of a commit (the submodule
  check), saw green and reported "CI 全部通过" while the Deploy/test run had failed.

