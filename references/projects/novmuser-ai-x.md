# Novmuser umbrella

## Symptom index

| Symptom | Read |
| --- | --- |
| PR ownership CI fails although a local follow-up check passed | [Use the full PR base](#ownership-ci-must-use-the-full-pr-base) |
| Adding a second tool operation breaks legacy reads or ignores host callback time | [Preserve read evaluation order](#preserve-read-evaluation-order) |
| PostgreSQL tests skip or the existing venv has stale first-party artifacts | [Use an exact scratch PostgreSQL environment](#use-an-exact-scratch-postgresql-environment) |
| Account-scoped browser keys still consume or overwrite legacy data | [Separate old and new key domains](#separate-old-and-new-key-domains) |
| A rejected session triggers reconnect saves, or a body error hides a received denial | [Classify session responses before recovery](#classify-session-responses-before-recovery) |

## Ownership CI must use the full PR base

2026-10-30: [PR48](https://github.com/IcestoneTech/novmuser-ai-x/pull/48) passed a local ownership check for its final ignore/docs follow-up, but the PR job failed because the complete branch changed gated contracts/exporters without updating `docs/implementation-owners.md`. A per-task `docs/owners/` record did not satisfy the configured central artifact. Tests, build and artifact upload had passed; the whole job was still RED.

Read the repository's `.owner-dispatch.json` and actual workflow base. Update its `ci_artifact`, then run `bash scripts/owner-dispatch/owner-dispatch.sh ci --base <actual-PR-base-sha>` over the complete proposed branch before publication and after fixes. Retain per-task ownership/provenance too. A check against only the previous commit, or a push job's different base, does not prove the PR gate.

The fix was a central ownership cross-reference; policy and product bytes stayed unchanged. Require fresh fixed-head CI and keep the original failed run separate. Child repositories can configure different gates: inspect their actual configuration first.

## Preserve read evaluation order

2026-10-30: tools candidate `409910fd` passed 680 tests but hoisted legacy `sessions.open` lookup and `path.model_dump()` before the broker lease and deadline. Installed old/new controls showed lease-dependent descriptors/serializers breaking, and 300 ms callbacks under a 100 ms budget making a business call only on the new candidate. The candidate was held before publication.

When extending the fixed operation set, preserve legacy attribute lookup and argument evaluation at their original consumption sites inside the lease/session/budget. Test property-backed duck ports and serializers, including refusal to call after elapsed synchronous work; ordinary methods cannot observe that ordering. Synchronous Python callbacks are not preemptible, so this is not a hard wall-clock bound.

Keep timeout fault delays beyond the test threshold: a 200 ms broker delay passed a 500 ms assertion for a 20 ms budget. A broker-entry-only budget mutant exposed the gap; 120 ms caught it while the original path took about 22 ms. Preserve the failing candidate evidence and bind corrected source and installed-wheel checks to a new exact revision.

## Use an exact scratch PostgreSQL environment

2026-10-30: [backend PR166 follow-up](https://github.com/IcestoneTech/novmuser-ai-x-backend/pull/166#issuecomment-6512213195) ran the four changed scheduler functions on exact `23a6997`: seven local PostgreSQL 16.2 variants passed, zero skipped, seven memory variants deselected. The existing venv had contracts 0.5.0/skills 0.2.2 instead of locked 0.5.3/0.2.5. Use a Git archive, private offline frozen environment and marker-aware closure/vendor checks; do not reuse that venv as-is.

The known local tool was cached ARM64 `pgserver==0.1.4`. Its bundled initdb/postgres/pg_ctl binaries can run directly; importing the helper can touch a shared macOS platformdirs lock and search processes. Allocate new mode-0700 PGDATA/socket paths, explicit synthetic Unix DSN and no TCP listener. An exact Unix-socket sandbox was validated with Unix-positive, TCP-negative and real C/libpq controls; env-i alone is not network enforcement, and Python DNS guards are not comprehensive C-level DNS proof. This is a QA route, not a production PostgreSQL version decision.

Collect explicit PostgreSQL node IDs before execution and compare each to its PASS entry. Capture the owned child PID, UID, start identity and PGDATA before stopping it; verify zero test schemas, process/PID/socket disappearance and unchanged source. Archive small evidence before removing only the new scratch copies; preserve shared caches and existing services. Never reuse ambient DSNs or repurpose HOME. A rejected retry must not overwrite old evidence: gate output on successful directory creation by that invocation and create result files exclusively. Seven local cases do not prove RDS/S3/native or whole-task acceptance.

## Separate old and new key domains

2026-10-30: local frontend candidate `5a3af8e` passed 69 helper tests, but `oldPrefix + account-v1:JSON(account,work)` still overlapped `oldPrefix + legacyWorkId`. The pinned work ID was an unrestricted string. An independent synthetic probe read a colliding old resume as the new account and overwrote its old bytes; no real-user occurrence was established.

Put the new discriminator **before** every legacy fixed prefix, and keep the account/work tuple unambiguous. Do not assume all historical IDs are UUIDs without producer evidence. Exercise old-versus-new collisions, normal new-account writes, stale writes/removals and unchanged legacy bytes. Follow-up `b2294c7` passed seven collision regressions and 76 helper tests; its independent resume probe preserved old bytes while normal new writes worked. Full auth/caller/browser acceptance remains separate.

Keep each rerun in a new evidence directory with exclusive outputs. A mutation rerun overwrote eight prior raw logs and their index; record that loss explicitly, preserve existing reviews and bind new claims only to the new bytes. Do not reconstruct missing raw logs or label later results as the old run.

## Classify session responses before recovery

2026-10-30: local frontend candidate `57652e7` published network recovery before classifying canonical session denials. The synchronous reconnect listener could dispatch a second dirty-save PUT while the credential still appeared admitted. Five actual probe regressions failed with two PUTs instead of one; the local correction passed those five plus approved and generic-ACL recovery controls. This is synthetic route/component evidence, not native or full-auth acceptance.

Classify current-owner 401 and validated waitlist profiles before publishing effectful recovery or retrying a declared JSON 503. Route owned probe failures to the session handler; a catch that merely swallows the failure cannot expire the session. Preserve successful unread streams and generic-ACL recovery, and settle definite old-account create responses before suppressing stale UI effects.

HTTP status and body availability are separate: empty/malformed 401 must not disappear behind JSON parsing, and a truncated 401/403/422 must retain known status and owner provenance without confirming recovery. Test the resulting session state, request counts and old-owner isolation; error-name assertions alone do not see these effects.
