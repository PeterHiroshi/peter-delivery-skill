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
- **Running the backend suite locally trips `env_guard`** ("Redis database 0 是生产库")
  because `backend/.env` points at Redis db 0 and `tests/conftest.py` lets `.env` override
  `os.environ`; `REDIS_URL=` on the command line is overridden. Anything that imports
  `app.main` (most of `tests/api`, `tests/services`) fails at collection. **Cheapest route
  (2026-09-10, no worktree, `.env` untouched):** a `-p` plugin in the scratchpad that wraps
  `dotenv.load_dotenv` — call the real one with an explicit `dotenv_path=<abs backend/.env>`
  (the wrapper changes the caller frame, so the default path search finds nothing), then set
  `REDIS_DATABASE=15` and pop `REDIS_URL`. Run
  `PYTHONPATH=$S V4_OFFLINE=1 backend/.venv/bin/python -m pytest -p envguard_testdb …` from
  `backend/`. Real Redis use in tests (rare) lands on db 15, never on 0/1.
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
- **Before proposing to loosen a gate, grep the tests for the gate's name.** Plan A for the
  graph gate ("trust the explainer's intent again") would have broken
  `test_direct_answer_cannot_invent_graph_for_non_visual_problem`, a deliberate product
  decision pinned in code. Reading that test first turned the plan into
  "intent AND ModelIR has a curve/relation" (`v4/figure.py`) — same benefit, no regression.

## Browser verification without a backend (hotfix 1.0.9 / LFX-453, 2026-09-10)

The local backend cannot run (its `.env` is bound to real DBs and prod Redis), and dev
serves `develop`, not the branch. For a UI change whose input is one API response, the
route that worked first time:

1. `node mock_api.js` on **8002** (the `API_BASE` fallback for `localhost`, see
   `frontend/src/api/resolveApiBase.ts`) answering only the endpoint under test with the
   patched backend's exact shape, plus `/api/auth/me`; everything else 404 is fine.
2. `VITE_API_BASE_URL=http://localhost:8002 npx vite --port 5199 --strictPort` in
   `frontend/` (the `dev` script runs type generation first; plain `vite` skips it).
3. The chrome-devtools MCP profile is locked ("browser is already running") — do not fight
   it. `npm --prefix $S i puppeteer-core@23`, launch `/Applications/Google Chrome.app/…`
   headless with `userDataDir: $S/chrome-profile`, and seed auth in
   `evaluateOnNewDocument`: `auth_token`, `auth_user` (JSON with `id/email/role`), and
   `i18n_lang` (`en-US` / `zh-CN`). `/dashboard` then renders the sidebar from the mock.
4. Assert from the DOM (`.session-item .session-title / .session-preview`) and screenshot
   both locales. This is a rule-12 harness (my data, not the product's DB): say so.

Other traps from the same session:
- `jira_request(method, path, data)` takes paths **relative to `/rest/api/3`** and returns
  `(data, err)`; `templates.adf_builder.adf` wants `(type, text)` tuples, not strings.
  Search: `GET /search/jql?jql=…&fields=…`. Bug issue type id is in `jira-config.json`.
- `cd backend && …` in the Bash tool moved the persistent cwd again; the next relative
  `.venv/bin/python` failed. Absolute paths, subshells only.

## Independent review route that worked (LFX-453, 2026-09-10)

`ccl-skills:code-review` gate, challenge mode, no plan file, one round per candidate:

```bash
export CODE_REVIEW_SKILL_DIR=<expanded ccl-skills code-review dir from the session skill list>
bash $CODE_REVIEW_SKILL_DIR/scripts/review_gate.sh --mode challenge --stage build \
  --cwd "$PWD" --base origin/<target-branch> --implementer-family anthropic \
  --challenge-budget 1 --challenge-index 1 --focus "<what to break>" --timeout 900 --total-timeout 1500 > out.json
```

Claude is excluded by family; the Codex lane reviewed (~3–5 min per round). Every
amend voids the verdict, so run it once per candidate and read `status`,
`candidate_sha256`, `findings[*].failure_path`. "Evidence gap / packet excludes X"
findings are input defects of a packet-bounded reviewer, not code defects: verify X
yourself and move on. `contracts/shared-types.ts` and `proof_types.py` are generated
from `contracts/api-spec.yaml` by `scripts/generate-proof-contracts.sh` — a spec edit
is not complete until that has been rerun and the diff is only your field. A field the
server always emits goes in the schema's `required` list, or codegen makes it
`int | None` in Python and the reviewer flags the nullability mismatch.

Copilot on this repo is not automatic on hotfix PRs into `release/x.y.z` (it was on
#394 into `develop`): request `copilot-pull-request-reviewer` with `gh pr edit --add-reviewer`
right after `gh pr create`, and again after each fix push. It answers in ~10 min. **Check `gh pr view <n> --json state,mergedAt,headRefOid` BEFORE acting on any bot
review or pushing a review fix.** On 2026-09-10 Peter merged #397 and #398 himself
sixteen minutes after they opened, before Copilot had answered. Every Copilot pass
after that was on the merged head (its `commit_id` never moved); I misread the repeats
as a request/push race and pushed three fix commits to already-merged branches — none
reached `release/1.0.9`. A repeated finding whose `commit_id` does not move is first an
"is this PR still open?" question. Fixes to a merged PR are a new branch off the target
and a new PR; the old branch is dead.

## Email campaign forensics on the AWS box (LFX-455, 2026-09-11)

Peter reported "3 hours, 89 sent, frozen". What settled it in ~40 minutes, in order:

1. `ssh limfx-server-aws`, `sudo docker ps` — prod containers are `backend`,
   `email_campaign_send`, `email_campaign_ingest`, `redis`; `*_dev` siblings run
   `develop`. Image tags are commit SHAs, so "is my fix deployed" is one glance.
2. **Run Python inside the container with `docker exec -i`** (heredoc on stdin).
   Without `-i` the script gets no stdin, prints nothing, and `2>/dev/null` hides
   even that — two silent empty rounds before I noticed. Use `python -u` too.
3. Mongo from the container: `AsyncIOMotorClient(os.environ["INTL_MONGODB_URL"])`,
   db `INTL_MONGODB_DB_NAME`. Collections `admin_email_campaigns`,
   `admin_email_campaign_recipients`, `admin_email_delivery_state`.
4. arq queue from the `redis` container: `redis-cli ZCARD email_campaign_send:queue`,
   `ZRANGE … 0 5` (member ids say what is queued: `cron:resume_due_campaigns:<ms>`
   vs `email-resume:<cid>:<minute>`), `ZRANK` for where a job sits, `--scan
   --pattern 'arq:in-progress:*'` for what is running. The worker log's
   `recording health: … queued=N` line is the same number.
5. Container log timestamps are UTC+8; the host `date -u` is UTC. Convert before
   lining up log lines with Mongo timestamps.
6. **Time the suspect call, do not reason about it.** `find_one` by `_id` on a
   1.76 MB campaign document (`csvRows` embedded) = 17.7 s from Atlas; with a
   projection 0.01 s. That single number explained the 1607 s cron. And SES: DATA
   → 250 in 0.18 s, then QUIT unanswered until the read timeout (60 s default) —
   `aiosmtplib.send()` swallows it. A probe with connect/login/NOOP/QUIT alone is
   instant, so probe the *exact* sequence the code runs (DATA then QUIT).
7. Safe end-to-end SMTP probe: `success@simulator.amazonses.com` (delivered to no
   one). Three sends with the no-QUIT path: 0.2 s each.
8. The 60 s per email also hits `send_plain_text_email` — registration, reset and
   magic-link mail — so an SMTP finding is never only a campaign finding.

## Unblocking the send worker (LFX-456, 2026-09-13)

- Purging `cron:*` members from `email_campaign_send:queue` (plus `arq:job:cron:*`
  keys) is enough: the queued `email-resume:*` job runs as soon as the crons ahead
  of it are gone. One `ZREM`/`DEL` per member through `docker exec` is ~0.5 s each
  — 2,800 members took 20 minutes. Batch them (`ZREM key m1 m2 …` in one call).
- **Do not restart the worker at the end of the purge without checking
  `arq:in-progress:*` first.** The resume job had already started sending
  (6011 → 7303) while the purge was still draining; my scripted `docker restart`
  killed that pass mid-flight, the lease (`LEASE_SECONDS=300`) stayed held by the
  dead token, and the next pass had to wait for the cron after lease expiry.
  Restart only if the in-progress key is a cron, never a `run_campaign`.
- Extra `email-resume:*` jobs are harmless: each returns `running` in 0.15 s
  against a held lease (the dedup is the lease, not the job id).
