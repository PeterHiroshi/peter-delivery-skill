# Novmuser umbrella

## Symptom index

| Symptom | Read |
| --- | --- |
| PR ownership CI fails although a local follow-up check passed | [Use the full PR base](#ownership-ci-must-use-the-full-pr-base) |
| Adding a second tool operation breaks legacy reads or ignores host callback time | [Preserve read evaluation order](#preserve-read-evaluation-order) |

## Ownership CI must use the full PR base

2026-10-30: [PR48](https://github.com/IcestoneTech/novmuser-ai-x/pull/48) passed a local ownership check for its final ignore/docs follow-up, but the PR job failed because the complete branch changed gated contracts/exporters without updating `docs/implementation-owners.md`. A per-task `docs/owners/` record did not satisfy the configured central artifact. Tests, build and artifact upload had passed; the whole job was still RED.

Read the repository's `.owner-dispatch.json` and actual workflow base. Update its `ci_artifact`, then run `bash scripts/owner-dispatch/owner-dispatch.sh ci --base <actual-PR-base-sha>` over the complete proposed branch before publication and after fixes. Retain per-task ownership/provenance too. A check against only the previous commit, or a push job's different base, does not prove the PR gate.

The fix was a central ownership cross-reference; policy and product bytes stayed unchanged. Require fresh fixed-head CI and keep the original failed run separate. Child repositories can configure different gates: inspect their actual configuration first.

## Preserve read evaluation order

2026-10-30: tools candidate `409910fd` passed 680 tests but hoisted legacy `sessions.open` lookup and `path.model_dump()` before the broker lease and deadline. Installed old/new controls showed lease-dependent descriptors/serializers breaking, and 300 ms callbacks under a 100 ms budget making a business call only on the new candidate. The candidate was held before publication.

When extending the fixed operation set, preserve legacy attribute lookup and argument evaluation at their original consumption sites inside the lease/session/budget. Test property-backed duck ports and serializers, including refusal to call after elapsed synchronous work; ordinary methods cannot observe that ordering. Synchronous Python callbacks are not preemptible, so this is not a hard wall-clock bound.

Keep timeout fault delays beyond the test threshold: a 200 ms broker delay passed a 500 ms assertion for a 20 ms budget. A broker-entry-only budget mutant exposed the gap; 120 ms caught it while the original path took about 22 ms. Preserve the failing candidate evidence and bind corrected source and installed-wheel checks to a new exact revision.
