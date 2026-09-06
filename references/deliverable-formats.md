# Deliverable formats

## Reporting status

Never "完成 / done". Report per line, so Peter can see the gap without asking:

```
已验证：
- typecheck 干净
- generation-rules 门禁 462 通过（起点 409）
- 全量 4587 通过
- 0 lint error（node-composer 的 2 个 setState 是既有的，baseline 有 4 个）

未验证：
- 视觉：没在浏览器里看过。dev server 起不来（worktree 的 node_modules 不完整）
- 跨浏览器 / 响应式断点

要我先修环境再看，还是你直接验收？
```

Rules:

- Numbers, not adjectives. "462 通过（起点 409）" shows movement; "全绿" hides it.
- "Pre-existing" needs evidence — compare against the untouched baseline, or say
  the origin is unverified.
- **The unverified list is the important half.** Lead with verified, but never
  omit the gap.

## Commit messages

The repo has `generating-commit-messages` (`.claude/skills/`). Essentials:

- Behaviour before implementation. What was broken → what happens now → why.
- Self-contained: the reader was not in this conversation.
- No Claude/AI/session attribution beyond the configured `Co-Authored-By`.
- Note behaviour deliberately unchanged, so a reviewer does not assume it moved.

## Pull requests

Use `raising-pull-requests` (`.claude/skills/`). Before opening:

1. Confirm the base and that the branch actually has commits it lacks
2. Read the whole diff — describe the diff, not the commit list
3. Run the strongest validation the repo defines (tests, typecheck, lint, build)
4. Scan for secrets, debug leftovers, binaries, `git diff --check`
5. `gh pr list --head <branch>` — never duplicate
6. **Get Peter's approval to push** — every time

Structure: Summary / Changes / Why / Testing / Notes. `Testing` must be true —
never claim browser verification that did not happen. `Notes` must state
migrations, flags, and anything intentionally unchanged.

## Lark message

**After an approved PR, unprompted — except for icestonetech projects.** English
regardless of conversation language. 1–3 sentences, pasteable, with the link.

**Not for `IcestoneTech/*` repos** (e.g. `math_ai`). Peter said so on 2026-09-06
after PR #374 there: the hand-off is already the `gh pr comment` automated
review, the PR link commented on the Jira issues, and the chat notification to
Linc. Decide by the git remote's organisation, not the directory name. See
[`projects/math_ai.md`](projects/math_ai.md).

Written for a teammate scrolling a channel deciding whether it concerns them —
not for a reviewer reading the diff.

```
PR #557 — the video settings panel in the Agent and canvas composers now shows
each setting's name above its control instead of a row of bare values whose
names lived only in hover tooltips. Frontend only — no migration, no feature
flag, and no change to the generation mode engine or the shared validator.

https://github.com/JerryYang666/moodio-agent/pull/557
```

Include: what changed, why anyone should care, the link, anything the team must
act on (migration, blocking decision). Exclude: implementation detail already in
the PR body.

## Language

- **Chat replies** — Peter's language (usually Chinese)
- **Everything landing in the repo** — English: docs, comments, commits, PR
  bodies, Lark messages
- **Scratchpad** — Chinese fine

Peter writing Chinese prompts is not a signal that deliverables should be
Chinese. (`docs-must-be-english`)

## Design docs

Before non-trivial code, and before TDD tests. Cover:

- decisions and rationale
- type/interface shapes, and **each caller's actual data shape**
- state matrix for multi-step or multi-table writes, including partial failure
- open questions
- what counts as verified

Present it and wait. Conversation consensus does not substitute.
(`design-doc-before-coding`)
