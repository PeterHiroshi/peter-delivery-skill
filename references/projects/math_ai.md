# math_ai (`IcestoneTech/math_ai`)

Notes that cost time to learn. Read before working in this repo.

## Hand-off

- **No Lark message after a PR.** The hand-off is: `gh pr comment` automated
  review (CLAUDE.md step 3), the PR link commented on the Jira issues, and the
  chat notification to Linc. Then stop and wait — Linc merges. (Peter, 2026-09-06.)
- Repo docs (`docs/plans`, completion reports) are **Chinese** here — Peter's
  explicit override of the global "repo artifacts in English" rule. Commit
  messages and PR bodies stay English (Linc's convention).
- CLAUDE.md is strict and real: never push/commit to `develop`; merging to
  `develop` deploys to production; a multi-sub-task epic needs
  `docs/completion-reports/<EPIC>-completion-report.md` committed **before** the
  final PR, referencing the exact commit.
- `develop` has no branch protection on GitHub — the rule is process-only.

## Environment traps

- A hook blocks edits in the main checkout while worktrees exist: edit in the
  worktree, merge from the main checkout. `git merge` run inside the worktree
  is a no-op self-merge.
- `backend/.env` is untracked and lives only in the main checkout. A detached
  temp worktree (bisect, running develop's tests) fails at import with
  "[REGION] DB URL env not set" until you copy `.env` in; remove the worktree
  afterwards so the copy goes with it.
- The shell is **zsh**: an unquoted `$var` does not word-split. Pass file lists
  to pytest as an array (`"${files[@]}"`), or six paths become one argument.
- Jira via `~/.claude/skills/jira-skill-distilled` needs the backend venv
  python (`backend/.venv/bin/python`): system `python3` has no CA bundle and
  fails with `CERTIFICATE_VERIFY_FAILED`.
- The shared fake Mongo (`backend/tests/_fakes/mongo.py`) and `MockDatabase`
  (`app/db.py`) are both narrower than real Mongo. Known past blind spots, now
  fixed but instructive: `find_one` returned a live reference, `$inc` was not
  implemented, nested-array matching did not work, `find_one` rejected a
  projection. A test that passes against the fake proves nothing about a
  query shape the fake cannot express — verify money/reconciliation queries
  against a real instance once.
- The effect-trial worker is supervised
  (`app/workers/effect_worker_supervisor.py`): it restarts on a content
  fingerprint change **only while no trial is queued/running**. A worker
  started before a code change silently runs old code until then.

## Baseline honesty

- "These failures pre-existed on the branch" is not the same as "they fail on
  develop". Check develop itself (temp detached worktree + `.env` copy) before
  calling anything a baseline. On 2026-09-06, 13 "baseline" failures were all
  green on develop.
