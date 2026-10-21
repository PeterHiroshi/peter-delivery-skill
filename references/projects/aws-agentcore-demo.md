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
| First push of the repo started no workflow run | CI / GitHub |
| Every deploy job: "Not authorized to perform sts:AssumeRoleWithWebIdentity" | CI / GitHub |
| Amplify: random empty 429; pairing command says localhost:3000; bridge 401 "Basic" | Amplify |
| Session list / history shows `{"message": {"role": …` JSON | Amplify |
| Any AWS call: ExpiredToken (CLI and dev server) | Local dev |

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
- Peter runs his own `pnpm bridge start` in a terminal. Stop a bridge I started by the PID I
  recorded (`echo $!`), never `pkill -f "tsx src/cli.ts start"` — on 2026-10-21 that killed his
  bridge along with my repro. A test device of mine also competes for his runs (freshest poll wins).
  Any test of the CLI sets `ACDEMO_BRIDGE_HOME=<empty dir>` — without it `acdemo-bridge start` reads
  HIS `~/.acdemo-bridge` and runs as his device (2026-10-21, killed by SIGPIPE within a second).
- `icestonetech-admin` is temporary keys (session token) in `~/.aws/credentials`; when they expire
  every AWS call fails and only Peter can renew them — no other local profile reaches 014498621858.
  Restarting the dev server does not help. Say so and keep doing what needs no AWS (CI uses OIDC).

## Deploy
- `pnpm --filter @acdemo/infra bootstrap <steps>`; runtimes via `scripts/push-image.sh` +
  `deploy:runtime`; README "Deploy" has the order. Pipelines per module in `.github/workflows`
  (OIDC role `acdemo-github-deploy`, main only). Amplify step needs the first push + a GitHub token.

## CI / GitHub (measured 2026-10-20)
- The first push of a new repo's main starts NO path-filtered run (new main compared with itself).
  Every module workflow has `workflow_dispatch`; touching each `.yml` (their own path) or
  `gh workflow run <name>` starts them. Wait loops: `gh run list --commit` needs the FULL sha.
- New repos use GitHub's immutable OIDC subject `repo:PeterHiroshi@33413323/aws-agentcore-demo@1426863891:…`
  (`gh api repos/<o>/<r>/actions/oidc/customization/sub`); the trust in `infra/src/steps/iam.ts`
  uses it (design M15). `pnpm --filter X pack` fails on pnpm 9.3 — pack from the package dir.

## Amplify (app d2ojvwir8ax29n, `https://main.d2ojvwir8ax29n.amplifyapp.com`, basic auth)
- Credentials: Secrets Manager `acdemo/amplify-basic-auth` (`--region us-east-1` — the profile has
  no default region). Probe script pattern: curl `-u user:pass` every route; 401 unauthenticated.
- CloudFront answers an empty 429 to ~1 in 8 PARALLEL requests (sequential: none) → client and
  bridge retry 429. SSR `req.url` is `https://localhost:3000` → never derive public URLs from it.
  Basic auth takes `Authorization` → bridge uses `X-Acdemo-Device-Token` + `ACDEMO_BASIC_AUTH`
  (design M16). Harness Memory events are Strands JSON envelopes → `lib/memory-text.ts` (M17).
- Verifying shipped client code: the workbench is client-only (lazy chunk), so grepping the chunks
  `index.html` references finds nothing. Take the lazy chunk ids + hashes from the webpack runtime's
  `r.u` map (`webpack-*.js`) and grep those. GitHub runners queued 5–10 min on 2026-10-21: a wait
  loop needs ≥ 15 min.

