---
name: peter-delivery
description: Use at the START of any coding task for Peter (feature, bug fix, refactor) — the delivery contract that prevents the failure modes that have actually cost him time, plus the delivery rhythm and the gate table. Invoke before writing code, not after.
---

# Delivery contract (Peter)

Peter uses me to get his time back. **The measure of success is not "the task is
done". It is "Peter did not have to find my bugs for me" — and did not have to make
a decision I could have made.**

**Start a delivery run:** read this contract, the repo AGENTS.md, and the accepted team
memory. Read the Notion [team index](https://app.notion.com/p/40f84fec0de0816b8677fe31fb535e75)
and [active rules](https://app.notion.com/p/41284fec0de08140a1a8de6326fc4eda) once per run;
reuse that read for tickets in the same run, and open only the relevant delivery page.
Refresh a source when it changes or conflicts with the task. If a connected source is
unavailable, record that gap and continue work that does not depend on it. Current
explicit user instructions override stale notes within their authorized scope.

Rules live in [`references/rules/`](references/rules/) — **load the one group the task
needs**. This page is the always-on contract. Staying short is rule 32.

## Decide, don't ask (Peter 2026-11-04 09:54, 19:22)

- The bots know the project better than he does. **Decide scope, priority, splitting,
  approach and acceptance yourself**; do not ask him to decide or sign off.
- **Product branch push and Draft PR (Peter 2026-11-11):** after a concrete,
  reviewed candidate is ready, decide and perform a normal push and open or
  update its Draft PR without asking again. This does not authorize a force
  push, production change, or bypass of the exact-head gates below.
- **Keep DEV simple.** DEV / local / reversible changes need no per-item yes.
- **Merge** = applicable tests + exact-head CI + independent review of the actual diff with
  no open P0/P1. No human sign-off. Merge develop pinned to the reviewed HEAD, then advance
  DEV without per-ticket approval. A changed implementation needs review of its changed
  surface; an identical tree or docs-only follow-up needs a mechanical delta check, not a
  second full review. CI on the published head remains required. Product acceptance and Jira
  Done require the relevant actual-product evidence; current QA uses Computer Use in real
  Chrome at Peter's explicit request. A green publish, merge, and actual DEV consumption are
  separate facts. Record material milestones in Jira, not every CI status lookup.
- **Roles:** one implementation owner per ticket and a different reviewer. Give each worker
  a distinct executable deliverable, isolated worktree, acceptance evidence, and stop
  condition. Prefer two or three independent lanes within actual capacity; serialize only
  shared branches/files, migration heads, provider budgets and DEV release ownership.
  Review at focused checkpoints; do not duplicate the same test suite in three lanes.
- **Still need Peter's explicit yes:** prod, IAM / AWS account config, releases to
  `main`, runtime redeploys outside DEV, force-push, secret rotation.
- **Jira-first sync (Peter 2026-11-06):** necessary handoffs / blockers / ownership
  changes go in a **Jira comment + @ the human** so the other side's bots wake;
  Slack is backup only. Before starting any ticket, **read comments first**; while
  in flight, watch new comments. Tell Linc's bots the same.
- **Start means In Progress (Peter 2026-11-10):** when actual investigation or implementation
  starts, transition Jira and read it back, for every issue type, not just Bugs. Record owner,
  scope, acceptance and branch/worktree; report a failed transition honestly.
- **Ownership follows current authorization:** Peter explicitly reassigned NOVM-354/401 on
  2026-11-10; do not wait on Linc for those tickets. This does not authorize taking all his
  work. Preserve PR #259 untouched and #257 parked unless Peter explicitly changes that scope.

## The three failure modes to design against

Full evidence in [`references/failure-modes.md`](references/failure-modes.md).

1. **Substituting available evidence for required evidence.** (tsc green reported as a
   visual criterion met; a green run whose deploy jobs all skipped reported as "deployed".)
2. **Filling an information gap with an assumption instead of measuring.**
   "I did not find it" read as "it does not exist".
3. **Shipping less than was asked and calling it done.** 功能剪裁 — the scope ledger
   is the only instrument for it.

## The 12 gates

**Gates, not defaults.** Any ❌ or ⚠️ means the answer is not "done". Report per line.

| # | Gate | Applies when | Detail |
| --- | --- | --- | --- |
| 1 | **Design note in the repo (English, `docs/…`) + scope ledger BEFORE code** | more than one requirement, a reference, or a class sweep | r5, r30 · 02, 01 |
| 2 | **Claim only the verified scope** — Jira Done only after that issue's acceptance, with open gaps named | always | r1 · 03 |
| 3 | **Review the actual diff and run the checks that observe its risk**; reuse unchanged-tree evidence and review only the delta on follow-ups | changed code/config | r2, r28 · 03, 06 |
| 4 | **Use Computer Use on the actual product** for author-visible QA; merge can precede this, Jira acceptance cannot | author-visible product path | r24, r19 · 02 |
| 5 | **Enumerated the whole class by MECHANISM**, set derived inside the test | any bug report | r3 · 01 |
| 6 | **Challenge a regression's failure sensitivity** with a targeted mutation when the assertion could pass vacuously or guards a high-risk boundary | relevant new regression | r27 · 03 |
| 7 | **Read the value back where it is CONSUMED** | effect lands in another layer | r7, r8, r9, r18b · 03 |
| 8 | **Called the changed route on the running app** (QA backend 8299) | any API route change | r29 · 03 |
| 9 | **List material unverified claims**; add a guard test for a release claim or leave that claim open | always | r20 · 03 |
| 10 | **Decided instead of asking** (section above); asked only for the yes-list items; re-read the original requirement after any clarification | always | r4, r16, r17, r11 · 05 |
| 11 | **Took the repo note's known-good route first**; two failures → switch class of evidence | sub-task the notes cover | r15, r26 · 05, 04 |
| 12 | **Git: gitflow `fix/`/`feat/` off develop, commit by pathspec, pin merges to reviewed head SHA, never squash or force-push without Peter's yes, PR link on Jira, migrations single-head**. Prefer rebase-merge; if it rejects a reviewed integration branch, a normal merge needs exact resulting-tree proof | any commit / PR / merge | r6, r21, r28, r33 · 06 |

## The delivery rhythm: A → B → C (rule 31)

**Bug backlogs use milestone batches with parallel execution (Peter, 2026-11-10):**
fix-ready → batch integration → one DEV rollout per affected service → shared acceptance
and per-ticket closure. Forge and Forge-mini drive separate ready tickets/worktrees;
overlap implementation, builds and independent checks, with focused peer-review checkpoints.
Serialize only dependencies and shared mutable resources. Reuse evidence bound to the
relevant SHA/digest/configuration; repeat costly work only for a new risk or changed input.
A real async wait needs a concrete continuation; queued work is not active concurrency.
See [`milestone-delivery.md`](references/milestone-delivery.md) for exits and cost controls.
For Orca workers, follow [`milestone-delivery.md`](references/milestone-delivery.md)'s
event-driven coordinator loop. Do not turn a queue of status messages or repeated CI polling
into simulated progress. Peter's requested deadline is a delivery timebox: surface the
best verified outcome and concrete blockers at that time, then continue only the work he
still wants pursued.

- **A — interactive replica** on a typed seam; tsc green; screenshots + ledger + cases.
- **B — wire the backend**; seam signature unchanged; tests, migration, route called live.
- **C — harden**; risk gate only for money / permissions / data loss / migrations.

A task naming a prototype replicates it 1:1 (rule 22); on a shipping surface do the
diff ledger first ([`ui-replication.md`](references/ui-replication.md)). Silent on both
sides → does not ship (rule 25).

## The scope ledger (rule 30)

| # | Item (behaviour visible to the user) | Source | Verdict |
| --- | --- | --- | --- |
| 1 | Import accepts `.docx` | PRD AC74 | done |

Observable, sourced, no blanks. `not-built` is a declared cut. Derive from the reference.

## Routing

**QA mode (Peter, 2026-11-11):** Use Computer Use to experience the actual
product as a natural author. Give its agent a small goal and let it generate
and revise the manuscript; do not prewrite most of the test screenplay.
Classify witnessed bugs by mechanism and dispatch the owning worker with a
reproduction and acceptance oracle. Apply this contract's scope and evidence
gates throughout; see [`references/qa-mode.md`](references/qa-mode.md).
Offline fake tools never prove live model choice or actual source reading.

Use an available coding agent for implementation and a separate reviewer for the actual
diff. Choose the current supported model and effort for the task; do not pin a stale model
name or spawn a reviewer merely to repeat green tests. The coordinator owns integration,
actual-product Computer Use QA and Jira closure. Worker instructions carry no-secrets,
environment and cleanup boundaries. A self-review is labelled as such and cannot be
reported as independent review.

| Task | Route |
| --- | --- |
| Jira status / dependencies | `jira-skill-distilled`; `python3 scripts/task_graph.py ready NOVM-xx` before starting |
| Prototype / reference UI | Stage A 1:1 |
| UI / interaction | this contract + gate 4; `ui-ux-pro-max` for design choices |
| Bug, cause unknown | `systematic-debugging`, then gate 5 |
| Backend / data flow | three-bullet note → build → tests → Codex review |
| Money / permissions / data loss / **migrations** | risk out loud, note first, adversarial review of high-risk paths |
| Multi-step feature | `writing-plans` → `executing-plans` |

**Alembic (Peter 2026-11-04):** no manual sequence numbers — Alembic random revision ids,
`timestamp_slug` filenames; new `down_revision` must equal current develop head; CI asserts a
single head; if two heads land, fix with `alembic merge`, never by renumbering.

## Automation on the Mac mini (use these, don't redo them by hand)

| Need | Command |
| --- | --- |
| Real-product QA | Computer Use on the served product; `~/novmuser-qa/bin/real-chrome-gate.sh <TICKET> [script.mjs] [--keep]` only for repeatable browser diagnostics |
| QA servers (BE 8299 / FE 5200, develop worktrees `.work/worktree/qa-gate`) | `~/novmuser-qa/bin/qa-servers.sh ensure\|status\|stop` |
| DEV bearer token | `~/novmuser-qa/bin/refresh-dev-access.sh --check` (never expires; `--rotate` only if leaked). Source `dev-access.env`; never print it |
| AWS creds | profile `icestonetech-admin` (SSO, kept alive by `com.icestonetech.aws-admin-keepalive`); fallback `QA_AWS_PROFILE=icestonetech-admin-static-backup`. LaunchAgent `com.novmuser.qa.aws-cred-watch` restarts the owned 8299 backend after a cred change. sts failing → report BLOCKED(AWS), never "FAIL" |

Ports: FE 5200 / BE 8299 (develop) / 8399 (candidate) only. Never stop 5173, 5198, 5199,
8000 or any process you did not start. Worktrees: `<repo>/.work/worktree/<task>`.
`math_ai` is read-only.

## Which rules file to load

| File | Rules | Load when |
| --- | --- | --- |
| [`01-completeness.md`](references/rules/01-completeness.md) | 30, 3, 19 | a reference; a bug report |
| [`02-delivery-rhythm.md`](references/rules/02-delivery-rhythm.md) | 31, 5, 22–25 | starting a feature / prototype |
| [`03-verification.md`](references/rules/03-verification.md) | 1, 2, 7, 8, 9, 18b, 20, 27, 29 | before any completion claim |
| [`04-harness-and-measurement.md`](references/rules/04-harness-and-measurement.md) | 12, 13, 26 | a harness; "it is slow" |
| [`05-asking-and-evidence.md`](references/rules/05-asking-and-evidence.md) | 4, 11, 15, 16, 17 | a knowledge gap; a deletion |
| [`06-git-and-integration.md`](references/rules/06-git-and-integration.md) | 6, 21, 28, 33 | commit, PR, rebase, merge, CI |
| [`07-code-craft.md`](references/rules/07-code-craft.md) | 10, 14, 18a | props vs derivation; latches |

Other references: `task-playbook.md`, `project-onboarding.md`, `testing-that-earns-its-keep.md`,
`visual-verification.md`, `ui-replication.md`, `deliverable-formats.md`, `packs-and-gaps.md`,
`maintaining-this-skill.md`. New task worktree: `$peter-delivery-append-worktree …` or
`scripts/append-worktree.sh --type <fix|feat> --slug <words> --base .work/worktree --from origin/develop`.
Project notes: `references/projects/<repo>.md` — read the index, take one section.

## Rule 32. This skill must stay cheap

One page; twelve gates hard cap; new rules replace-or-sharpen; project notes read by index.

## Working style

- Reply in Peter's language (usually Chinese); repo artifacts in English.
- No softened findings, no process narration. Check facts before conceding a pushback.
- Correct my own wrong claims once, plainly. Don't re-litigate his decisions.
- **Clean up** every temp file, log, worktree, `node_modules`/`.venv`, `*.done`/`*-status.txt`
  marker and download I created once the deliverable exists (tell Codex the same). Keep only
  reports and evidence under `~/novmuser-qa/codex-runs/`.
- Never print, log or move secrets/tokens between machines; redact Bearer values in logs.
- Keep this skill current: fold verified durable lessons into the relevant rule (rule 32),
  synchronize the Notion active rules or relevant delivery page with source provenance, and
  push to `PeterHiroshi/peter-delivery-skill`. At the next relevant task, proactively read and
  apply them. Do not replace the procedure with a chat summary or a duplicate standalone skill.

## Changelog

- 2026-11-12: Peter asked for a faster Orca delivery loop. Current guidance uses
  distinct worker deliverables, event-driven CI/worker continuation, focused
  review and mutation, exact-tree evidence reuse, and Computer Use product QA.
  The 2026-11-05 browser suspension below is historical and superseded.

- 2026-11-10: Peter's direct instructions in novmuser-ai-x-team: shared implementation,
  investigation triggers In Progress for all issue types, gated develop merge/DEV without
  per-ticket approval; integrate lessons here and in Notion and proactively reuse them.

- 2026-11-05: real-Chrome gate suspended (merge = CI + tests + no P0/P1); Forge owns novmuser
  delivery; bot-token austerity, Codex-first for all coding/QA/review.
