# Milestone delivery for bug backlogs

Source: Peter's direct request in novmuser-ai-x-team, 2026-11-10, following repeated
deployment/status handoffs that delayed closure. This sharpens delivery rhythm and
verification reuse; it adds no approval gate. Existing CI, independent review,
pinned rebase merge and environment boundaries remain in force.

## One release ledger, four milestones

Track ticket, implementation owner, reviewer, acceptance criterion, dependencies,
reviewed SHA, release SHA/digest, configuration identity, evidence and next action.
Each ticket keeps one implementation owner; one release owner serializes shared DEV
changes. Independent work must use separate executable lanes: Forge and Forge-mini own different
ready tickets, isolated worktrees and bounded processes; overlap implementation,
CI/builds and read-only checks wherever dependencies permit. Use actual teammate
work threads for named bots and bounded Codex workers for independent code/checks.
Do not substitute native helper names for actual teammates. Default to two active
independent lanes within supported capacity; add workers only for distinct work,
never duplicate the same investigation or paid call. XP navigation/review happens
at focused checkpoints rather than holding the other implementation lane idle.
Only shared mutable resources (the same branch/file, DEV deployment, test fixture,
port or migration head) and true dependencies serialize. A single active turn does
not prove a worker is running: record thread/process/job identifiers and fresh
start evidence; queued work stays queued. If room dispatch serializes bot turns,
use supported independent work threads/workers; if that cannot run concurrently,
report the specific runtime limit and keep available CI/build workers progressing.
Never claim a policy edit increased runtime concurrency.

| Milestone | Exit evidence |
| --- | --- |
| M1 Fix-ready | Each included ticket has its required fix, focused unit/integration checks and peer review of the candidate SHA; unknown-root-cause tickets remain investigation work. |
| M2 Integrated | Eligible PRs pass their required CI and review, merge by rebase pinned to reviewed SHA; inspect integration conflicts and validate the final combined revision. Freeze the release manifest with included/excluded tickets and frontend/backend compatibility. |
| M3 DEV available | Reuse a suitable published immutable artifact; deploy each affected service once for this batch, in compatibility order. Read back actual container digest/revision and required configuration at consumption. A created change set or green publish is not a deployment. |
| M4 Accepted | On that deployment, run one shared smoke plus the union of ticket-specific acceptance cases; peer independently checks material evidence. Update and read back each Jira status; link shared evidence in Notion. Close only tickets whose own criteria passed. |

Group compatible ready fixes by service and dependency; do not wait for the entire
backlog. Default batch: 2–4 ready tickets or the already-ready set at a release
boundary. A blocker with no executable step moves to a later batch; critical fixes
may ship alone. Do not rebuild or roll back a deployment already in flight merely
to satisfy batching. Reuse that environment for compatible acceptance cases when
the deployment manifest includes their fixes. Closed tickets are not rerun without
a relevant new risk.

## Minimize time and paid work

- Investigate with existing evidence first. Narrow file reads, queries and tests to
  the affected mechanism; reuse the existing worktree, dependencies and successful
  artifacts. Do not repeatedly rescan the entire backlog or all historical comments
  when only new information is needed.
- Run cheap deterministic unit/contract tests and synthetic failures before a real
  model/provider request. Deduplicate overlapping acceptance cases across tickets.
  Mock success is never presented as a real service acceptance.
- Before a slow build, full suite, model call or deployment, name the question it
  answers, the expected exit evidence, and a bounded attempt/time/cost limit in the
  release ledger. Start with one real provider probe per distinct required path;
  repeat only for a new hypothesis or a documented repeatability criterion.
- Keep required PR checks. Run the necessary combined release checks once on the
  frozen revision; do not repeat the same suite locally, through a helper and by
  the peer without a distinct verification purpose. Peer review verifies actual
  diff and evidence and selectively reproduces risky assertions.
- Evidence reuse requires matching relevant code, dependencies, artifact, config,
  environment and test inputs. Changes invalidate affected evidence; a release
  without relevant changes does not justify rerunning every closed ticket.
- After two failed attempts at the same sub-goal, switch evidence route and record
  the blocker. Do not vary commands indefinitely or repeat expensive model calls.
- Real Chrome remains suspended this phase; use the approved API/curl scope.
  Do not weaken permission, data integrity or migration acceptance to save time.
  No new paid resources or wider production/IAM authority is implied.

## Keep moving across asynchronous boundaries

Complete all currently executable steps in one turn. Check an external job once;
never shell-poll, sleep-loop or rebuild merely because it is still running.
While it runs, do other independent ready work if the execution environment permits.

Before ending at a real wait, record the exact job/change-set ID, current state,
owner and next command/acceptance criterion. On a user-started turn, use the
existing event continuation or one wait_until for the observable completion
condition; deduplicate against existing monitors. Bot/routine-started work that
cannot register a wait returns a concrete handoff to the release owner.
A teammate assignment must be actually submitted; a plain promise is not a handoff.
Do not create periodic short-interval polling or duplicate delivery automations.
Pause a temporary monitor once its goal is met and verify it is disabled.
Keep standing intake/reconciliation automations.

Update Jira at actual investigation start, material blockers and milestone exits;
Notion holds shared release evidence. Report milestone results and real blockers,
not every status lookup. Track elapsed build/deploy/acceptance time, paid-call
count, rework and tickets accepted so the next batch addresses the actual bottleneck.
