---
description: Create this repo's task worktree for a bug/requirement — branch, .env, install, editor, in one step
argument-hint: <meegle url or id> <what it is, in a few words> [fix|feat]
allowed-tools: Bash(bash ~/.claude/skills/peter-delivery/scripts/append-worktree.sh:*), Bash(bash /Users/mahao/.claude/skills/peter-delivery/scripts/append-worktree.sh:*)
---

Create the task worktree for: $ARGUMENTS

This is mechanical setup, not a task. **Run one command and stop.** Do not explore
the repo, do not read files, do not load the peter-delivery skill, do not start
the work in the new worktree.

```bash
bash ~/.claude/skills/peter-delivery/scripts/append-worktree.sh --type <fix|feat> --slug <kebab-case> [--id <meegle url or id>] [--repo <path>]
```

Fill in only these three:

- `--type` — `fix` for a bug/缺陷, `feat` for a requirement/需求. Nothing in the
  input saying which: something broken → `fix`, otherwise `feat`.
- `--slug` — 3–5 English words, kebab-case, what the task is about. Translate if
  the input is Chinese. No id, no type word, no repo name.
- `--id` — the Meegle URL exactly as given (the script pulls the number out of it)
  or the bare id. Leave it off when there is none.

Add `--repo <path>` when the working directory is not the target repo. Pass
nothing else: the worktrees directory, the directory-vs-branch naming, the base
branch, the `.env` copy, the background `npm install` and opening the editor all
come from how that repo already does it.

**Several links in one go**: one call per link, all in the same message so they
run together, each with its own `--slug` (and `--type`, which can differ). The
script refuses an `--id` holding two links rather than quietly building one
worktree — never merge them, never drop one. Each worktree opens its own editor
window; add `--no-open` to every call if Peter said not to open them.

Then print the script's own output lines — all of them, one block per worktree —
and nothing else.

If it exits 2, report its one line and what is missing — usually a slug, or
`--base <dir>` because the repo has no worktrees yet to learn the layout from.
Ask Peter for that directory; do not retry with a guessed one.
