# Several agents on one repo (Forge, Codex, Claude Code)

Load when more than one agent works the same repo for Peter: Forge (the Grok Bot
teammate, which reaches Peter's Mac remotely and can launch cloud agents), the
local Codex (desktop app or `codex` CLI), and Claude Code. Standing instruction,
Peter 2026-10-25.

## C1. peter-delivery is every agent's default contract

Every agent works under this skill on every coding task, whether or not Peter
names it. Peter should never have to say "use peter-delivery" again.

## C2. One branch and one worktree have one owner

- Before you create or touch a worktree, read the coordination file. It lives in
  the repo's worktree base (for example `.worktrees/COORDINATION.md` or
  `.work/worktrees/COORDINATION.md`), and that directory must be git-ignored.
  Then claim the work with one row: agent, ticket, branch, worktree path, state,
  and last update (with a timezone).
- Never commit, check out, rebase, reset, or clean in a worktree another agent
  owns, and never push to its branch. Release your row when the PR merges or the
  work is dropped.
- Measure whether a worktree is in use before claiming it. Check
  `git worktree list`, the last commit time, `git status`, and the `cwd` of
  recent Codex sessions in `~/.codex/sessions/`. A dirty tree, or a session there
  in the last 24h, means it is taken. Ask Peter. Do not assume it is abandoned
  (failure mode 2).
- A cloud agent pushes to its remote branch. Never check that branch out in a
  local worktree while the cloud agent is still running.

## C3. Hand-offs go through artifacts, not memory

Hand work over through the coordination row, the design doc and ledger in the
repo, and the PR. Never rely on another agent's chat history. A hand-off states
what is verified and what is not (gates 2 and 9), per check.

**Scar (2026-10-24/25, novmuser-ai-x-frontend PR #4).** A cloud agent reported
"typecheck, lint, test, build all green". The repo's own
`scripts/owner-dispatch` gate was not in that list, and CI went red on it. The
agent relaying a report checks it against the repo's CI job list. "All checks"
means the checks CI runs, not the ones the reporter remembered.

## C4. The author does not certify its own diff

The agent that wrote a change does not run the adversarial review on it. The
other agent does: `codex exec review --base <base>` from the worktree, or a
scoped `codex exec` per area when the diff is large. If the review cannot be
obtained (quota, timeout), report it as ⚠️ not obtained. Never report it as
done (see the moodio-agent note).

## C5. Approvals belong to one repo

Each repo's `AGENTS.md` and its project note decide who approves pushes and
merges. A standing approval in one repo does not carry over to another (for
example, novmuser-ai-x allows feature-branch pushes, but math_ai needs Linc to
approve every merge to develop). Ask once per repo.

## C6. Lessons come back here, from any agent

Whichever agent learns a lesson writes it back here under rule 32. Run
`git pull --rebase` first, because more than one agent edits this repo. Commit
by pathspec and push to `PeterHiroshi/peter-delivery-skill`.
`~/.codex/skills/peter-delivery` is a separate, non-git copy that drifts.
Refresh it from this repo only with Peter's OK, because it may hold edits made
by Codex.

## C7. Language

Chat with Peter is in Chinese. Repo artifacts are in English. The coordination
file is in English, so every agent parses it the same way.
