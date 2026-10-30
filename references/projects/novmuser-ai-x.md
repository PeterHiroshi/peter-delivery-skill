# Novmuser umbrella

## Symptom index

| Symptom | Read |
| --- | --- |
| PR ownership CI fails although a local follow-up check passed | [Use the full PR base](#ownership-ci-must-use-the-full-pr-base) |

## Ownership CI must use the full PR base

2026-10-30: [PR48](https://github.com/IcestoneTech/novmuser-ai-x/pull/48) passed a local ownership check for its final ignore/docs follow-up, but the PR job failed because the complete branch changed gated contracts/exporters without updating `docs/implementation-owners.md`. A per-task `docs/owners/` record did not satisfy the configured central artifact. Tests, build and artifact upload had passed; the whole job was still RED.

Read the repository's `.owner-dispatch.json` and actual workflow base. Update its `ci_artifact`, then run `bash scripts/owner-dispatch/owner-dispatch.sh ci --base <actual-PR-base-sha>` over the complete proposed branch before publication and after fixes. Retain per-task ownership/provenance too. A check against only the previous commit, or a push job's different base, does not prove the PR gate.

The fix was a central ownership cross-reference; policy and product bytes stayed unchanged. Require fresh fixed-head CI and keep the original failed run separate. Child repositories can configure different gates: inspect their actual configuration first.
