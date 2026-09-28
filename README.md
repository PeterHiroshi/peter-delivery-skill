# peter-delivery

A Claude Code skill: the delivery contract for working with Peter.

Distilled from real sessions on `moodio-agent`. Every rule exists because
breaking it cost time — the evidence for each is in `references/failure-modes.md`.

## Install

```bash
git clone <this repo> ~/.claude/skills/peter-delivery

# the sub-commands (one symlink each) — a command file must live under
# ~/.claude/commands/, so the repo keeps the original and links it in
mkdir -p ~/.claude/commands/peter-delivery
ln -s ~/.claude/skills/peter-delivery/commands/append-worktree.md \
      ~/.claude/commands/peter-delivery/append-worktree.md
```

Claude Code picks up `~/.claude/skills/*/SKILL.md` automatically, and the
subdirectory under `~/.claude/commands/` is what names the command
`/peter-delivery:append-worktree`.

## Sub-commands

| Command | What it does |
| --- | --- |
| `/peter-delivery:append-worktree <meegle url> [<meegle url> ...]` | One worktree per link (bare links get their title and type from one `meegle workitem +batch-get`; words beside a link win). Creates the task worktree the way the current repo already does it: layout and branch/directory naming detected from the worktrees that exist, ignored `.env` files copied, `npm install` started in the background, editor opened. `scripts/append-worktree.sh --help` for the flags. |

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
