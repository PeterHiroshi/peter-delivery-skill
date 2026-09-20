# The rules

`SKILL.md` holds the 12 gates; this directory holds the rules behind them.
**Load one group, not all seven.** Rule numbers are stable — `SKILL.md`, the
project notes and past reports address rules by number, so a rule is never
renumbered when it moves file.

| File | Rules | Load when |
| --- | --- | --- |
| [`01-completeness.md`](01-completeness.md) | 30, 3, 19 | any task with a reference; any bug report |
| [`02-delivery-rhythm.md`](02-delivery-rhythm.md) | 31, 5, 22, 23, 24, 25 | starting any feature or prototype task |
| [`03-verification.md`](03-verification.md) | 1, 2, 7, 8, 9, 18b, 20, 27, 29 | before any completion claim; config / pipeline / route / provider changes |
| [`04-harness-and-measurement.md`](04-harness-and-measurement.md) | 12, 13, 26 | building a harness; any "it is slow" |
| [`05-asking-and-evidence.md`](05-asking-and-evidence.md) | 4, 11, 15, 16, 17 | a gap in what I know; a clarification; a supplied file; a deletion |
| [`06-git-and-integration.md`](06-git-and-integration.md) | 6, 21, 28 | committing, pushing, opening a PR, rebasing |
| [`07-code-craft.md`](07-code-craft.md) | 10, 14, 18a | props vs derivation; refs and latches; read-back after a rewrite |

Rule 32 (this skill must stay cheap) lives in `SKILL.md` itself, because it
constrains that page.

## The long-form gate table

Superseded by `SKILL.md`'s 12 gates, which each fold several of these rows.
Kept verbatim because every row names a specific trigger, and a trigger is the
part that changes behaviour.


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
| 24 | **Called the route on the running app** (rule 29) — tsc and the node suite cannot see a route that fails to load | any API route change |