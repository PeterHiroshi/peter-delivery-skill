---
name: peter-delivery-orca
description: Run Peter's delivery contract through Orca worktrees and supervised workers, with Codex implementation and independent review. Use when a delivery task uses Orca sessions or Peter asks to optimize Orca coordination; not for worktree setup alone.
---

# Peter delivery on Orca

This is an adapter, not a second delivery policy. First read the installed
`~/.codex/skills/peter-delivery/SKILL.md` and the relevant references, or the
same repo's root `SKILL.md` when working from its source checkout. Its scope,
authorization, QA, review, CI, Jira, merge and DEV gates remain authoritative.
User instructions take precedence. For mechanical worktree setup alone, use
the installed `/peter-delivery:append-worktree` command or the root skill's
`scripts/append-worktree.sh`; use `$peter-delivery-append-worktree` in Codex
when that separate entry point is installed.

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

## Use the installed Orca protocol

Read `orca skills get orca-cli` and `orca skills get orchestration` before using
Orca. For a larger task graph, read the version-matched coordinator-loop guide
through `orca skills get orchestration --reference references/coordinator-loop.md`.
Prefer `orca orchestration worker-start` for supervised tasks and
`orca worktree create` for a full handoff. Record Run, Task, Dispatch, worktree
and branch identifiers at creation; treat a started worker and a queued worker
as different states. Do not infer success from an accepted terminal input.

After dispatch, yield for Orca's event wake. Do not repeatedly call
`orca orchestration check`, poll CI in a loop, or send terminal keystrokes as
task steering. `check` consumes mail and can hide a wake. Use
`orca orchestration send --to dispatch:<id>` for a correction or follow-up.
If startup or delivery is uncertain, inspect that terminal once before retrying;
never create a duplicate worker to resolve silence. A worker's completion must
include its actual outcome, exact evidence, unresolved risk and resource cleanup.
If it exited without `worker_done`, recover the existing dispatch; do not count
an escalation as a finished task.

## Codex and product boundaries

- Codex may implement in its owned Orca worktree; a separate reviewer checks
  the immutable candidate. Keep the review independent of the author. Do not
  silently change model, effort or permission settings when creating sessions.
- Use Computer Use to experience author-visible behavior in the real product.
  In QA, give the product agent a small goal and let it generate and revise;
  avoid writing its screenplay for it. A synthetic fixture proves only its
  stated boundary. Record the consumed build, operation and visible result.
- Use the prescribed Jira skill/API, not a browser, for issue writes. Read back
  transitions, assignee and comments. Treat CI green, merged source, published
  artifact, DEV consumption and Jira acceptance as five separate facts.

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
