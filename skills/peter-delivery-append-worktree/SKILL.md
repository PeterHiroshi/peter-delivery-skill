---
name: peter-delivery-append-worktree
description: Create one or more Peter-delivery task worktrees from Meegle links or task descriptions, using each repo's existing layout, then open the worktree with an Antigravity (agy), Claude Code, or Codex startup task and optional model/effort selection.
---

# Append a task worktree

Use this skill when Peter asks for `append-worktree`, `/peter-delivery-append-worktree`,
a new task worktree, or `/peter-delivery:append-worktree`. This is setup only;
do not start implementing the feature in the current checkout.

1. Identify every task in the request or immediately preceding conversation.
   Keep one worktree per task; do not silently select or combine items. For a
   bare Meegle link, read its title and type if the Meegle tool is available.
   Use `fix` for an issue/bug and `feat` for a story/requirement. Preserve the
   user's task wording as the `--task` prompt. If type or title cannot be
   recovered, ask only for the missing fact.
2. Make a 3–5 word English kebab-case slug from each task. Run once per task:

   ```bash
   bash ~/.codex/skills/peter-delivery/scripts/append-worktree.sh \
     --type <fix|feat> --slug <task-slug> \
     [--id <meegle-url-or-id>] [--task <original-task-wording>] [--repo <repo-path>] \
     [--runner <agy|claude|codex>] [--model <model-or-alias>] [--effort <low|medium|high|xhigh|max>] \
     [--permission-mode <mode>]
   ```

   Pass `--no-auto-start` if Peter wants only a worktree, and `--no-open` if
   Peter does not want a VS Code window. If the script cannot detect a worktree
   directory, ask for `--base`; do not invent one.

3. **Runner & Model selection (`agy` / `claude` / `codex`):**
   - **Default runner:** automatically inferred from `--model` when an
     Antigravity or Codex model is passed, or from the current environment
     (Antigravity session → `agy`, Codex session → `codex`, otherwise `claude`).
     Pass `--runner agy` (or `claude` / `codex`) when Peter explicitly names the
     CLI/agent.
   - **Antigravity (`agy`) models (`--model`):**
     - Supports any model ID or display name from `agy models`, or shorthand
       aliases (paired with `--effort <low|medium|high|xhigh>` when applicable):
       - `argon` → `gemini-4-argon-{low|medium|high}` (default `medium`)
       - `carbon` → `gemini-4-carbon-{low|medium|high}` (default `medium`)
       - `hydrogen` → `gemini-4-hydrogen-{low|medium|high|xhigh}` (default `high`)
       - `flash` / `gemini-3.8-flash` → `gemini-3.8-flash-{low|medium|high}` (default `high`)
       - `orchestrator` / `orchestrator-carbon` → `gemini-pro-orchestrator`
       - `orchestrator-argon` → `gemini-pro-orchestrator-argon`
       - `opus-5.5` / `claude-opus-5-5` (or `opus` under `agy`) → `claude-opus-5-5-{low|medium|high}` (default `high`)
       - `sonnet-5.5` / `claude-sonnet-5-5` (or `sonnet` under `agy`) → `claude-sonnet-5-5-{low|medium|high}` (default `high`)
       - `gpt-oss` / `gpt-oss-120b` → `gpt-oss-120b-medium`
     - When `--model` is omitted under `agy`, `agy` uses the default model in
       `~/.gemini/antigravity-cli/settings.json`.
     - The one-shot `.vscode/tasks.json` task defaults to full permissions across
       all runners (`agy --dangerously-skip-permissions`,
       `claude --permission-mode bypassPermissions`,
       `codex --dangerously-bypass-approvals-and-sandbox`) so sessions do not
       pause for manual tool approval prompts; pass `--permission-mode default`
       (or `auto`, `accept-edits`, `plan`, `manual`) to opt out or narrow
       permissions.
     - Under `agy`, the terminal runs
       `agy --dangerously-skip-permissions [--model ...] [--effort ...] -i "$P"`
       with parent `ANTIGRAVITY_*` / `CLAUDE_*` session variables scrubbed so a
       fresh top-level session starts in the new worktree.

4. Report the script's branch, worktree, runner/model, install, editor, and
   auto-start lines. Stop after setup. The new session invokes `/peter-delivery`
   (or `$peter-delivery` in Codex) and stops at the scope ledger before
   implementation.
