---
description: Create this repo's task worktree for a bug/requirement — branch, .env, install, editor, in one step
argument-hint: <meegle url> [<meegle url> ...] — or <meegle url or id> <what the task is> [fix|feat], repeated
allowed-tools: Bash(bash ~/.claude/skills/peter-delivery/scripts/append-worktree.sh:*), Bash(bash /Users/mahao/.claude/skills/peter-delivery/scripts/append-worktree.sh:*), Bash(meegle workitem +batch-get:*)
---

Create the task worktree for: $ARGUMENTS

**Where the tasks come from.** Read the arguments first, then fall back to the
conversation — never invent one:

1. Links, ids or descriptions in the arguments → those are the tasks. Placeholder
   text (`<链接1>`, `<描述1>`, `...`) is not a task: say so in one line and stop.
   **Bare links are the normal case** — several Meegle links and nothing else. A
   link with no words of Peter's beside it gets its title and type from Meegle:
   collect the ids of every bare link and read them all in ONE call, from the
   target repo's directory (the CLI reports `AUTH_REQUIRED` from `/tmp`):

   ```bash
   meegle workitem +batch-get --project-key <space key> --work-item-ids <id>,<id>,... --format json \
     | jq -r '.results[].data.work_item_attribute | [.work_item_id, .work_item_type.key, .work_item_name] | @tsv'
   ```

   The space key is the URL's space segment (`ozn2tr` → Moodio 3.0,
   `6a7b389acc3b9c910ee856fe`; for any other space, `meegle url decode --url
   <link>` names it). Then per item: `--type` from its type (`issue`/缺陷 → `fix`,
   `story`/需求 → `feat`), `--task` = the title verbatim, `--slug` from the
   title's meaning. This read is the only Meegle call allowed here. An id the call
   returns under `errors`, or a failed call (`AUTH_REQUIRED` → `meegle auth login
   --device-code --host project.larksuite.com`): skip that item, run the rest,
   and name what was skipped and why in one line — never guess a slug for it.
   Words Peter did write beside a link win over the fetched title.
2. Arguments empty, or they point at something already on screen ("刚才那些",
   "全部 issue", "these") → the tasks are the work items **already in this
   conversation**, e.g. the ones a `meegle` CLI call just listed. Take every one
   of them, in the order listed: the item's URL or id, its title as `--task`
   (verbatim), and its type for `--type` (缺陷/bug → `fix`, 需求/story → `feat`).
   Do not shorten the list, do not pick "the important ones" — an item you skip is
   an item Peter thinks is being set up.
3. Neither → name in one line what is missing (the links) and stop. Do not
   search or list Meegle from inside this command (no MQL, no views, no "my
   todos") — finding the work items is its own step; only the by-id read in 1 is
   part of this one.

Already-created tasks cost nothing to include: the script reports an existing
worktree and creates nothing. Drop exact duplicates from the list, and if it is
more than 5 items, print the branch names you are about to create and get one
go-ahead first — each worktree opens a window and starts a session.

This is mechanical setup, not a task. **Run the script — one call per task — and
stop.** Do not explore the repo, do not read files, do not load the
peter-delivery skill, do not start the work in the new worktree.

```bash
bash ~/.claude/skills/peter-delivery/scripts/append-worktree.sh --type <fix|feat> --slug <kebab-case> [--id <meegle url or id>] [--repo <path>]
```

Fill in only these:

- `--type` — `fix` for a bug/缺陷, `feat` for a requirement/需求. Nothing in the
  input saying which: something broken → `fix`, otherwise `feat`.
- `--slug` — 3–5 English words, kebab-case, what the task is about. Translate if
  the input is Chinese. No id, no type word, no repo name.
- `--id` — the Meegle URL exactly as given (the script pulls the number out of it)
  or the bare id. Leave it off when there is none.
- `--task` — what Peter said the task is, **in his own words, verbatim** (Chinese
  stays Chinese); for a bare link, the Meegle title verbatim. It becomes the first
  prompt of the session that starts in the new window.

The new window starts working on its own: the script arms a one-shot VSCode task
that opens a terminal in the worktree and runs `/peter-delivery` with that first
prompt, which reads the requirement and stops at the scope ledger — it does not
write code. Add `--no-auto-start` when Peter only wants the worktree, and say in
the report that the window will just sit there.

**The session's own settings.** Model and effort are inherited, not set: the
terminal session and the VSCode one both read `~/.claude/settings.json`, so
passing nothing is what keeps them identical (thinking is part of effort — there
is no separate switch). The permission mode is taken from the extension's
`claudeCode.initialPermissionMode`, because a terminal session would not have it.
When Peter names any of them in his message ("用 sonnet 跑"、"effort 开到 max"、
"这次别 bypass"), pass `--model <m>`, `--effort <low|medium|high|xhigh|max>` or
`--permission-mode <m>` — per task, so different links can run differently.

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
