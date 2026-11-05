---
name: peter-delivery
description: Use at the START of any coding task for Peter (feature, bug fix, refactor) — the delivery contract that prevents the failure modes that have actually cost him time, plus the delivery rhythm and the gate table. Invoke before writing code, not after.
---


# Delivery contract (Peter)

Peter uses me to get his time back. **The measure of success is not "the task is
done". It is "Peter did not have to find my bugs for me" — and did not have to make
a decision I could have made.**

Rules live in [`references/rules/`](references/rules/) — **load the one group the task
needs**. This page is the always-on contract. Staying short is rule 32.

## Decide, don't ask (Peter 2026-11-04 09:54, 19:22)

- The bots know the project better than he does. **Decide scope, priority, splitting,
  approach and acceptance yourself**; do not ask him to decide or sign off.
- **Keep DEV simple.** DEV / local / reversible changes need no per-item yes.
- **Merge** = green CI + Codex review with no open P0/P1 + real-Chrome gate PASS for
  anything user-visible. No human sign-off.
- **Still need Peter's explicit yes:** prod, IAM / AWS account config, releases to
  `main`, runtime redeploys outside DEV, force-push, secret rotation.

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
| 2 | **Never say 完成 / done** — say what is verified and what is not | always | r1 · 03 |
| 3 | **Self-review + Codex review of the actual diff + tsc / tests / scoped lint green, re-run right before reporting** | always | r2, r28 · 03, 06 |
| 4 | **Real-Chrome first-content gate PASS** (`real-chrome-gate.sh <TICKET> [script]`, report linked) — or, for non-novmuser repos, looked at the render | anything that renders or changes a chat/agent path | r24, r19 · 02 |
| 5 | **Enumerated the whole class by MECHANISM**, set derived inside the test | any bug report | r3 · 01 |
| 6 | **Mutation-tested every new assertion** | new tests | r27 · 03 |
| 7 | **Read the value back where it is CONSUMED** | effect lands in another layer | r7, r8, r9, r18b · 03 |
| 8 | **Called the changed route on the running app** (QA backend 8299) | any API route change | r29 · 03 |
| 9 | **Listed what I did NOT verify**; each "reasoned, not seen" line becomes a guard test | always | r20 · 03 |
| 10 | **Decided instead of asking** (section above); asked only for the yes-list items; re-read the original requirement after any clarification | always | r4, r16, r17, r11 · 05 |
| 11 | **Took the repo note's known-good route first**; two failures → switch class of evidence | sub-task the notes cover | r15, r26 · 05, 04 |
| 12 | **Git: gitflow `fix/`/`feat/` off develop, commit by pathspec, rebase-merge only pinned to the reviewed head sha (`gh pr merge --rebase --match-head-commit <sha>`), never squash, never force-push without Peter's yes, PR link on the Jira item, migrations single-head** | any commit / PR / merge | r6, r21, r28, r33 · 06 |

## The delivery rhythm: A → B → C (rule 31)

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

**Codex-first** (coding, QA, review): `codex exec` / `codex exec review` on the Mac mini,
model **gpt-5.6-terra** — `xhigh` for complex logic, lower effort for conflicts and
incremental re-reviews. Bots orchestrate and verify; they save their own tokens. If Codex
quota runs out, the bot codes/reviews itself (label it **self-reviewed**). Always pass
Codex these hard rules: no secrets in output, no AWS/prod/IAM changes, ports, cleanup.
CLI `codex exec` cannot use native Codex computer use (that needs the ChatGPT/Codex desktop
app session); for browser checks from `codex exec`, use Playwright with `channel:'chrome'`,
`headless:false` via the real-Chrome gate.

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
| Real-Chrome gate (hard) | `~/novmuser-qa/bin/real-chrome-gate.sh <TICKET> [script.mjs] [--keep]` → `codex-runs/<TICKET>-<ts>/REPORT.md`, exit≠0 on failure |
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
- Keep this skill current: a durable lesson ends with an edit here (under rule 32) and a push
  to `PeterHiroshi/peter-delivery-skill`.
