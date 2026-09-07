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

## Release pipeline (LFX-344, live since 2026-09-07)

`develop` → **dev**. `release/x.y.z` deploys **nothing**. Tag `vX.Y.Z` → **prod**.
One `deploy.yml`; release flow in `prepare-release` / `prepare-hotfix` /
`promote-release`. Runbook: `docs/runbooks/release.md`.

- **A workflow must be *registered* before `workflow_dispatch` works, and registration
  needs it on the default branch (or a push event that fires it).** A dispatch-only
  workflow that lives on `develop` returns **404**, not a permission error. Once
  registered, "Use workflow from" can select any branch — so this is a one-time cost per
  new dispatch-only workflow, not a per-change one.
- `main` was a 2-commit shell 1715 commits behind `develop` until 2026-09-07. Now it is
  the release record, moved only by `promote-release` (or a hand fast-forward when a run
  goes red). A local hook blocks Claude from pushing to `main` — hand Peter the command.
- `promote-release` is gated on `conclusion == 'success'`. A release that deploys fine but
  fails a *verification* step leaves `main` and `develop` without it, silently.
- **Never re-run a pre-cutover `Deploy Backend` / `Deploy Frontend` run** from the Actions
  UI: a re-run executes the old workflow file and deploys `develop` to production.

## Infra traps

- **INTL AWS creds need `amplify:GetJob`**, not just `StartDeployment`/`GetApp`/`GetBranch`
  — the deploy polls the job instead of trusting `start-deployment`'s 200. Admin profile
  for IAM work is `icestonetech-admin` (account `014498621858`); the CI user is
  `limfx-backend-ci-ecr-push`, policy `frontend-s3-amplify-deploy`. Verify a grant with
  `aws iam simulate-principal-policy`, not by re-reading the JSON.
- **`gh api` list endpoints paginate at 10.** `environments/<env>/variables` with 13 vars
  reports 10 and looks like two are missing. Always `--paginate ...?per_page=100` before
  claiming anything is absent.
- **The CN host rate-limits SSH.** Repeated `sshpass` connections start returning
  `Connection closed` / `Permission denied`; back off ~10s and retry rather than
  concluding the host is down. Batch work into one connection or write to a remote file
  and fetch it. `scp` failing while a following `ssh` "succeeds" means the script was
  never uploaded — check before trusting the run.
- **My network cannot reach `limfx.cn` / `.tech` from here.** A timeout on the CN site
  proves nothing; verify from inside the host (`curl 127.0.0.1:8002/health`) and ask Peter
  for the browser check. `limfx.ai` is reachable.
- The CN site moved `limfx.tech` → **`limfx.cn`** (2026-09). Support address is
  `support@limfx.cn`, and it appears in the **published** privacy policy and terms — a
  change there needs the mailbox to exist first.
- CN frontend does **not** get `VITE_API_BASE_URL` injected: it derives the API base from
  `window.location.hostname`, so it is same-origin and CORS never fires. That is why a
  stale `CORS_ORIGINS` (still `limfx.tech` weeks after the move) caused no visible
  breakage. INTL bakes the base in at build time, so its bundle is region-specific.
- `backend/Dockerfile:42` bakes `ENV APP_ENV="prod"`. An env file that omits `APP_ENV`
  therefore runs in production mode with `env_guard` **fully disabled**. The deploy passes
  `-e APP_ENV` explicitly; a manual `docker run` must too.
- `create_async_redis_client` resolves the Redis db two different ways (TLS-without-verify
  reads the URL path; everything else goes through `from_url`, where `?db=` wins).
  `resolve_redis_database()` in `redis_utils` is the single rule — never re-parse a Redis
  URL by hand.
