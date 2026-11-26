---
name: peter-delivery-orca
description: Run Peter's delivery contract through Orca worktrees and supervised workers across Codex, Antigravity, and Claude, with independent cross-agent review. Use when a delivery task uses Orca sessions or Peter asks to optimize Orca coordination; not for worktree setup alone.
---

# Peter delivery on Orca

This is an adapter, not a second delivery policy. First read the installed root
`SKILL.md` (`~/.gemini/config/skills/peter-delivery/SKILL.md`,
`~/.codex/skills/peter-delivery/SKILL.md`, `~/.claude/skills/peter-delivery/SKILL.md`,
or the source checkout's root `SKILL.md`) and relevant references. When the
active session runs in Antigravity (`ANTIGRAVITY_AGENT=1`), also load
`/peter-delivery-antigravity`. Root scope, authorization, QA, review, CI, Jira,
merge and DEV gates remain authoritative. User instructions take precedence. For
mechanical worktree setup alone, use `/peter-delivery-append-worktree`
(Antigravity), `$peter-delivery-append-worktree` (Codex),
`/peter-delivery:append-worktree` (Claude), or `scripts/append-worktree.sh`.

## Start from the outcome

1. State the user-visible acceptance result and the deadline. Read only the
   current, assigned Sprint issues and their comments when that is the scope.
   Give every issue one owner and one next action. Keep a short scoreboard of
   accepted, in progress and blocked outcomes; PRs and dispatched workers are
   evidence, not completed outcomes.
2. Make the smallest executable dependency graph. Dispatch distinct deliverables
   in owned worktrees: implementation, independent adversarial review, actual
   product acceptance. Give each worker its exact input SHA/configuration, one
   acceptance oracle, evidence location, dependency, and stop condition. Start
   only workers that can act now. Serialize shared branches, migrations, paid
   budgets and the DEV release lane. Do not spawn a worker to poll CI or merely
   forward messages.
   Before parallel work crosses repositories, freeze the producer/consumer
   identity and scope in one example that both owners can validate. Include
   whether an anchor names saved content or an unadopted candidate, the exact
   version and operation, and who may apply a choice. A field-name match is not
   enough; stop the combined acceptance claim when these meanings differ.
3. Prefer one focused implementation and one reviewer per independent change.
   Review the actual diff. Reuse exact-tree evidence; review only changed code
   after a follow-up. Run checks that observe the risk. Do not repeat a full
   suite because a different worker already ran it at the same immutable tree.
   When a parallel PR merges and advances `develop`, its sibling owner integrates
   that exact base normally, then rebinds focused checks, delta review and CI to
   the resulting head. Earlier CI proves only the earlier base.

## Keep the feedback loop short

- **Serial topics and next-task confirmation (Peter, 2026-11-13).** For Peter's
  current Jira queue, keep one active product topic and one implementation
  owner; the coordinator reviews, integrates and accepts that topic. After its
  full goal and Jira Done are verified, proactively select the best next issue
  and explain the reason and acceptance scope. Wait for Peter's confirmation
  before starting it or moving it to In Progress. Continue the already
  authorized active topic without asking again. Before final source freeze,
  reconcile both the issue description and all current scope-changing comments
  against the ledger; do not close from an earlier, smaller ledger.

- **Jira ownership tags (Peter, 2026-11-15).** Use Jira labels as the shared
  reservation source: `owner-peter` for Peter and `owner-orca` for this agent.
  New automatic pickup excludes both labels with
  `(labels IS EMPTY OR labels NOT IN ("owner-peter", "owner-orca"))`; resume only
  the known active issue owned by this run. Preserve existing assignees and
  unrelated labels. Before work, add `owner-orca` using an additive label update
  and read it back. Re-read reservations before work and publication. If Peter
  reserves an active issue, stop duplicate edits and hand off its branch/evidence;
  `owner-peter` takes precedence if both labels appear. Never clear Peter's tag
  to make an issue eligible. A local queue mirrors Jira, not the other way around.

- **Remote freshness (Peter, 2026-11-15).** Refresh relevant remote refs at task
  start, after a long wait or an external merge, and before commit, push, merge
  or deployment. Use `git pull --ff-only` for a clean tracking checkout. The sole
  task writer integrates latest `develop` normally into a feature branch after
  preserving pending edits; the coordinator may fetch without changing files in
  that lane. Record remote SHA and actual DEV consumption separately. Rebind
  delta review and CI if the integrated tree changes; reuse identical-tree evidence.

- **Progress reports always include a percentage (Peter, 2026-11-13).** For one
  active issue, state its estimated end-to-end completion, for example
  `NOVM-72: about 80%`, with the verified change and remaining acceptance gap.
  Explain the basis when first reporting or when it changes; tests, PRs and CI
  are evidence, not a completion denominator. For a backlog, use accepted issues
  over the explicit total (`3/6 accepted, 50%`), and show active-issue estimates
  separately. Reserve 100% for full user-visible acceptance and Jira Done
  readback. If new evidence reopens work, revise the estimate and say why.

- Name the product-acceptance owner and the next executable integration step
  when assigning implementation. A default-off seam, Draft PR or merged source
  is a dependency milestone; keep the issue moving through DEV consumption and
  real product acceptance without opening unrelated feature work.
- Before each push, run the cheap deterministic CI preflight that applies to
  the changed surface: generated-file drift when generated files are affected,
  contract/ownership checks when those records change, and a focused
  old-red/new-green regression for a bug fix. For a changed guarded agent path,
  include one ordinary creative control and one adversarial output-channel
  control. A docs-only follow-up can use a mechanical delta check. Let hosted
  exact-head CI cover environment-specific suites; do not repeatedly run a
  full local suite known to fail for an unchanged host limitation.
- Before a DEV rollout, run local integration checks for the changed paths and
  their actual risk boundary. For a cross-service author-visible flow, freeze
  the exact source SHAs and artifacts of the participating services, then
  exercise that flow across those same versions. Include its transport and
  saved-state readback, an ordinary creative control when an agent is involved,
  and old-red/new-green failure control for a bug fix. Use actual built services
  where available; a mocked provider or synthetic source may replace only the
  external call it names. Record environment-only gaps and resolve them with
  reviewed DEV acceptance. Single-repository tests and green CI do not replace
  local integration for a changed cross-service path. Batch reviewed,
  CI-qualified changes into one rollout per service instead of redeploying
  after each PR.
- A reproducible P0/P1 becomes the current author's next action. Send the
  minimal failing input, visible/storage consequence and exact files to that
  author, fence merge and DEV, then review only the repair delta and rerun the
  exact-head CI. Do not create a second writer on the same worktree or replace
  the fix with another default-off side branch. If a settled Dispatch is reused,
  confirm its terminal owns the worktree before starting any new worker there.
- Count completion by the issue's user-visible oracle and Jira readback. When
  reporting a deadline, show the remaining acceptance gap for each In Progress
  issue; keep a held To Do separate from an unresolved bug. Do not count workers,
  PRs, tests or green publication as closed issues.
- **Review handoff & closure: `@peter.ma` on Jira + Done + worktree cleanup (Peter, 2026-11-19).**
  Sync routine progress/percentages to the Orca workspace board (`orca worktree set`).
  Whenever an issue is ready for Peter to review or accept, post a Jira comment with a
  native `@peter.ma` mention stating the verified build/evidence and what to check.
  Once verified accepted, transition Jira to `Done` and read it back, then remove the
  local Orca/Git worktree (after landing/pushing commits and releasing finished workers)
  to free disk space. Propagate these rules to child sessions that manage worktrees or sub-tasks.

## Use the installed Orca protocol

Read `orca skills get orca-cli` and `orca skills get orchestration` before using
Orca. For a larger task graph, read the version-matched coordinator-loop guide
through `orca skills get orchestration --reference references/coordinator-loop.md`.
Prefer `orca orchestration worker-start` for supervised tasks and
`orca worktree create` for a full handoff. Record Run, Task, Dispatch, worktree
and branch identifiers at creation; treat a started worker and a queued worker
as different states. Do not infer success from an accepted terminal input.

For `moodio-agent`, copy the same host's main checkout `.env` to the root of
each new worktree as a setup step, before running the app or QA. With native
Orca creation, make this explicit in the worker brief; with `append-worktree.sh`,
verify the copy it already makes. See the
[Moodio worktree instructions](../../references/projects/moodio-agent.md#copy-env-into-new-worktrees).

After dispatch, yield for Orca's event wake. Do not repeatedly call
`orca orchestration check`, poll CI in a loop, or send terminal keystrokes as
task steering. `check` consumes mail and can hide a wake. Use
`orca orchestration send --to dispatch:<id>` for a correction or follow-up.
If startup or delivery is uncertain, inspect that terminal once before retrying;
never create a duplicate worker to resolve silence. A worker's completion must
include its actual outcome, exact evidence, unresolved risk and resource cleanup.
If it exited without `worker_done`, recover the existing dispatch; do not count
an escalation as a finished task.
When `worker-start` fails at `agent-update-prompt`, read that terminal's rendered
screen before acting. If it is only the Codex update menu, choose its skip
option, confirm the agent is idle and no task input ran, then release the failed
Dispatch and retry the **same Task** with `--retry-of`, the same worktree and
agent. Record both Dispatch IDs. Do not start a fresh Task, install an update,
or resend the task to a prompt whose state is unknown. This recovery has twice
prevented a blocked startup from turning into duplicate source work.

## Agent harnesses and product boundaries

- Codex (`--agent codex`), Antigravity (`--agent antigravity`), or Claude
  (`--agent claude`) may implement in its owned Orca worktree; a separate
  reviewer checks the immutable candidate. Keep the review independent of the
  author (cross-family pairing — e.g. Codex author + Antigravity reviewer, or
  Antigravity author + `codex exec review --base <base>` — is preferred). Do not
  silently change model, effort or permission settings when creating sessions;
  note that in `orca`, passing `--effort` requires passing `--model`.
- **Antigravity inside Orca (`ANTIGRAVITY_AGENT=1`):** after `orca orchestration
  worker-start`, yield by ending the Antigravity turn cleanly so Orca's event
  wake delivers completion. Never schedule an Antigravity `schedule` cron/timer
  to run `orca orchestration check` (which consumes Orca mail and hides wakes),
  and keep Gate 1 design docs and `.work/qa/<task>/` evidence inside the owned
  worktree rather than Antigravity's private `brain/<conversation-id>/` folder.
- Use Computer Use to experience author-visible behavior in the real product.
  In QA, give the product agent a small goal and let it generate and revise;
  avoid writing its screenplay for it. A synthetic fixture proves only its
  stated boundary. Match the fixture's admitted harness and scope to the actual
  UI request before diagnosing a pre-admission error as a product defect. Record
  the consumed build, operation and visible result.
- Use the prescribed Jira skill/API, not a browser, for issue writes. Read back
  transitions, assignee and comments. Treat CI green, merged source, published
  artifact, DEV consumption and Jira acceptance as five separate facts.
- When local secret scanning passes but CI fails, inspect the exact redacted
  finding and CI ref scope before changing product code. A repository-wide scan
  can include a closed PR's stale remote branch. Remove only an owned,
  superseded ref after verifying it is closed and linked to its replacement;
  rerun the exact CI gate. Do not add a broad secret-scan exemption.

## Deadline and recovery

At the deadline, report the verified scoreboard and the shortest remaining
critical path. In the last five minutes, stop expanding scope: read back actual
product and Jira state, collect outstanding worker outcomes, and name blockers.
Continue authorized work after the checkpoint only if the user still wants it.
Give the user a concise update whenever a material gate changes; avoid status
chatter that does not change the next action.

Do not install a Codex hook that consumes Orca mail, blocks normal tools or
duplicates the delivery gates. A hook is useful only after a measured repeated
failure, with an opt-in, nonblocking check and a demonstrated rollback path.
