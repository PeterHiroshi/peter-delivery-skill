# aws-agentcore-demo (`~/Develop/projs/ai-projs/aws-agentcore-demo`, GitHub `PeterHiroshi/aws-agentcore-demo`)

AgentCore all-services demo: Next.js chat on Amplify, harnesses adk2 / pi / managed Harness on
AgentCore Runtime, local Codex via `harness/bridge`. Design + measured facts M1–M14 + ledger:
`docs/design-agentcore-mvp.md`. Account 014498621858 (`icestonetech-admin`), us-east-1, prefix `acdemo`.

## Symptom index

| Symptom / need | Section |
| --- | --- |
| Bedrock Claude "use case details have not been submitted" | Models |
| Harness returns 200 with zero stream events | Models |
| Presigned Runtime WebSocket 403 "signature does not match" | AgentCore traps |
| Policy denial not detected; Gateway 400 "Unsupported protocol version" | AgentCore traps |
| Evaluate: "no span documents" / "no spans with supported scope" | AgentCore traps |
| Runtime shell command gets `&&` as an argument | AgentCore traps |
| pi "Provider is not configured: amazon-bedrock" in Runtime | pi |
| Dev server 500 on every route after an install or build | Local dev |
| A smoke message with `$500` arrives as `00` | Local dev |
| zsh loop variables misbehave (`GID`, `set -- $x`) | Local dev |
| Deploy order, what each pipeline does | Deploy |

## Models
- Claude on Bedrock is blocked for this account until the Anthropic use-case form is submitted
  (Peter's action); default `us.moonshotai.kimi-k3` via `ACDEMO_MODEL_ID`. Probe with
  `converse_stream` + a tool, not `converse` alone (M1).
- Managed Harness + Kimi K3 + built-in code interpreter/browser → empty stream, no error anywhere.
  Bisect with a throwaway probe Harness (create minimal, add one config block per update) — two
  failed invokes of the full config told nothing (M2). Harness uses Nova Pro.

## AgentCore traps (all measured 2026-10-20)
- WS presign: keep SigV4's default path escaping (ARN encoded twice). Browser `Origin` is fine.
- Gateway: set `supportedVersions`; a denial is JSON-RPC `-32002 "Tool Execution Denied"`
  (ADK raises McpError → `on_tool_error_callback`); permits need a condition (scope to `client_id`).
- `Evaluate`: only spans whose scope is on a fixed framework list; sessions from before
  Transaction Search (account switched 2026-10-20, M12) have no spans; built-in evaluator ARNs are
  region-less; online eval config = one service each.
- `InvokeAgentRuntimeCommand` has no shell → `sh -c`. Harness backing runtime ARN is under
  `environment.agentCoreRuntimeEnvironment`. Registry formats: design M7.
- Live-view URL can't be checked with curl (501 for any GET) — browser only.

## pi
- pi 1.3's Bedrock auth check ignores Runtime (instance-metadata) credentials → answer it via
  `createModels({authContext})`; prompt lives in the leading system message; bundle with
  `setBedrockProviderModule`.

## Local dev
- `pnpm install` by another session or `next build` breaks the running dev server: `rm -rf
  apps/web/.next`, restart with `AWS_PROFILE=icestonetech-admin pnpm dev`.
- pnpm script shell expands `$` in args — run `../node_modules/.bin/tsx src/smoke/chat.ts` directly.
- zsh: `GID` is read-only; `set -- $spec` does not word-split.

## Deploy
- `pnpm --filter @acdemo/infra bootstrap <steps>`; runtimes via `scripts/push-image.sh` +
  `deploy:runtime`; README "Deploy" has the order. Pipelines per module in `.github/workflows`
  (OIDC role `acdemo-github-deploy`, main only). Amplify step needs the first push + a GitHub token.
