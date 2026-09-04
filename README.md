# peter-delivery

A Claude Code skill: the delivery contract for working with Peter.

Distilled from real sessions on `moodio-agent`. Every rule exists because
breaking it cost time — the evidence for each is in `references/failure-modes.md`.

## Install

```bash
git clone <this repo> ~/.claude/skills/peter-delivery
```

Claude Code picks up `~/.claude/skills/*/SKILL.md` automatically.

## What it is

Not a replacement for the installed packs (`superpowers`, `karpathy-skills`,
`ccl-skills`, `ui-ux-pro-max`) — it routes to them, and it starts from an
uncomfortable fact: **two of its rules already existed in those packs and were
violated anyway.**

`superpowers:verification-before-completion` says never claim completion without
fresh evidence. I ran every command I had — but for a render bug in a node-only
repo, *no command proves the claim*, so the rule was satisfied and the bug
shipped. `karpathy-guidelines` says don't assume, ask — but it does not name the
trigger that actually fires: a search that misses, read as proof of absence.

General principles I already agreed with did not stop me. This skill is
deliberately narrower: the specific trigger, in the specific repo, with the
evidence of what happened when it was missed.

## Contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | The contract: non-negotiables, definition of done, routing |
| `references/failure-modes.md` | The two root causes, with session evidence |
| `references/visual-verification.md` | Looking at what renders — the highest-leverage rule |
| `references/reuse-over-duplication.md` | Derive over pass; ~half of one session's bugs |
| `references/testing-that-earns-its-keep.md` | Regression pins vs discovery; mutation testing |
| `references/task-playbook.md` | Opening moves per task type |
| `references/deliverable-formats.md` | Status reports, commits, PRs, Lark messages |
| `references/moodio-agent.md` | Repo-specific traps |

## The one-line version

Green gates are not the deliverable. Look at what renders, enumerate the whole
class before fixing one instance, ask when the answer lives with Peter, and
never say "done" — say what is verified and what is not.
