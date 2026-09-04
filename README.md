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

Not generic process — `ccl-skills` and `superpowers` already cover that, and
this skill routes to them where they fit. This is the part they cannot know:
who Peter is, how he works, which mistakes I actually make, and what "done"
has to mean before I am allowed to say it.

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
