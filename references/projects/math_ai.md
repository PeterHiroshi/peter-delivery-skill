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

## Model credentials are region-scoped — the registry card names are logical (2026-09-08)

- `config/i18n/regions.yaml` declares the real env vars per region (`INTL_KIMI_*`,
  `CN_KIMI_*` with legacy fallback to bare `KIMI_*`). Anything that does
  `os.getenv("KIMI_API_KEY")` is **empty on INTL** and only works locally / in CN.
  Codex found it via a prod symptom (`model registry cannot resolve kimi-k2.6` →
  `answer_contract_incomplete`, 5 of 7 solves in 24h); the fix was three call sites
  (registry, admin relay panel, equiv_gate Pass-2). When a bug is "env var not read",
  grep the bare name across `app/` — the reported site is never the only one.
- Test-order trap: `tests/api/conftest.py` `setdefault`s `INTL_KIMI_*` for the whole
  session at import, and `app.region.get_region` is `lru_cache`d. A test that sets a
  bare `KIMI_*` and expects it to win passes alone and fails in the full run once
  some earlier test left the region cached as INTL. Any registry/credential test must
  `delenv` the `CN_/INTL_` variants **and** clear both region caches.
- Running one test file alone can trip `env_guard` ("APP_ENV=development 却绑定了生产资源")
  at collection; the same test passes inside a larger file list. Reproduce with the
  list, not the single file, before calling anything broken.
- A worktree has no `.venv` / `node_modules`: use the main checkout's
  `backend/.venv/bin/python` (it imports `app` from the worktree cwd, verified via
  `app.__file__`) and symlink `frontend/node_modules`. `ruff`/`pyflakes` are not
  installed and CI runs no backend linter.
- Red-before-green needs care when the new test imports a new symbol: on the old
  code it errors at collection, which proves nothing. Make a temp copy without the
  import (or `-k` the new-symbol cases out) so the remaining cases fail on assertions.

## Squashed merge-backs break the prod history gate (2026-09-08, v1.0.4 burned)

- `check_tag_gates.sh` gate 4 requires every commit on `main` to be an ancestor of the
  tag. The `release: sync vX.Y.Z back to develop` PRs for v1.0.2 (#381) and v1.0.3
  (#385) were **squash-merged** (single-parent commits), so develop carried copies of
  main's content but none of its SHAs. Tag `v1.0.4` cut from develop failed
  `history:` and is burned (never move a tag).
- Detect before tagging: `git merge-base --is-ancestor origin/main origin/release/X.Y.Z`.
  A merge-back that "looks merged" is not enough — count parents
  (`git rev-list --parents -n1 <sha> | wc -w` = 3 for a real merge).
- Recovery per runbook: new `release/X.Y.(Z+1)` from the blocked release branch,
  `git merge --no-ff origin/main` (conflicts only in the three version files → take
  the release side), bump to the next patch, push, CI, tag. The next Promote Release
  merge-back must be merged with "Create a merge commit" or the same thing recurs.
- Do not run `scripts/release/bump_version.sh` with a local `uv` older than CI's:
  `uv lock` rewrote `uv.lock` from revision 3 to 1 (3.7k-line churn). Restore the
  lock and edit only the root package's `version` line.

## Prod forensics and local suite (LFX-451, 2026-09-08)

- **Read the prod session before reading code.** INTL prod Mongo is Atlas; the backend
  container has the creds: `ssh limfx-server-aws`, then
  `sudo docker exec backend /app/.venv/bin/python <script>` with
  `INTL_MONGODB_URL` / `INTL_MONGODB_DB_NAME` from its env. Collections:
  `adk_sessions_sessions` (state.artifacts[].steps, canonicalAnswer, `_v4.locked_parts`,
  `solveTracesByArtifactId` with the ModelIR), `adk_sessions_events` (user text, tool
  call args, model reply text). That dump settled all three LFX-451 root causes in one
  query — including the fact that the tool call carried no `locale` arg.
- `docker logs backend` only covers the current container; a redeploy since the incident
  means no logs. Do not plan on them.
- Jira skill works with system python3 too: `SSL_CERT_FILE=$(python3 -c 'import
  certifi;print(certifi.where())')`. The backend venv is not required.
- **Running the whole backend suite locally trips `env_guard`** ("Redis database 0 是生产库")
  because `backend/.env` points at Redis db 0 and `tests/conftest.py` lets `.env` override
  `os.environ`. In a worktree, edit the *copied* `.env` to `REDIS_DATABASE=2` (0/1 are prod
  per `config/production_bindings.yaml`); `REDIS_URL=` on the command line is overridden.
  Targeted file lists pass without this because they never import `app.db` at collection.
- `answer_lock_check` (v4 explain) used to accept a locked value only as the *suffix* of a
  math run. CJK conclusions pass because Chinese characters split runs; English sentences
  are one run, so any value not at the end was "missing" and the explainer's conclusion got
  replaced by the mechanical `(1) … (2) …` string. A rule that looks language-neutral can
  still be language-biased — test it with an English sentence, not only a Chinese one.
- zsh: `grep -rn X app --include=*.py` fails with "no matches found" — quote the glob
  (`--include='*.py'`). It cost several empty tool rounds in one session.
- vitest only collects `**/*.{test,spec}.*` under the project; a probe test written in the
  scratchpad is silently "No test files found". Put probes under `src/**/__tests__/` and
  delete them afterwards.

## Offline end-to-end check of the v4 delivery chain (LFX-451 D5, 2026-09-09)

You do not need a live solve to test explainer/prompt changes against a real problem.
Pull `modelir` + `execution` + `locked_parts` + `problemText` for a prod artifact
(`solveTracesByArtifactId[<id>].v4`, see the forensics note above), then rebuild the
outcome locally:

```python
recs = {f"arm{i}": {"final_status": "solved",
        "attempts": [{"attempt": 0, "modelir": modelir, "execution": execution}]} for i in range(2)}
outcome = V4Outcome("resolved", vote(recs), recs, 1)
r = build_step1_result(outcome, problem_text, output_language_directive(locale), "solution")
kept = _synchronize_final_answer_step(r.payload["steps"], r.payload["finalAnswer"], locale,
                                      locked=r.payload["_v4"]["locked_parts"])
solve_reply_text(r.payload["finalAnswer"], kept)
```

One real explainer call per run (kimi via the local `.env`, region CN). Run EN and ZH.
This is what proved the conclusion-rule + lock-check + bubble chain in ~40 s, where a
prod round trip is a deploy. Also the fast way to A/B a prompt rule: mutate
`explain.EXPLAIN_TASK` in the script, no file edit.

Traps met on the way:
- `render_answer_statement` must not crash when a locked value is a relation/set
  (`Eq(sym, (m>0)&(m<4))` → sympy TypeError); the first version took down
  `build_step1_result`'s try-block and silently produced the mechanical step.
- A modeler-invented `propositions` target (e.g. "second derivative > 0", label "1")
  became an answer part `{1}` and made every explainer conclusion fail the lock check.
  Structural test: the problem text must actually enumerate that label ((1) / ①).
