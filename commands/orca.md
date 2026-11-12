---
description: Coordinate a peter-delivery task through Orca's event-driven workers and Codex worktrees
argument-hint: <delivery objective or current task>
---

Use `peter-delivery` as the delivery contract for: $ARGUMENTS

Load `~/.claude/skills/peter-delivery/skills/peter-delivery-orca/SKILL.md`
from the installed peter-delivery checkout and the
version-matched Orca CLI skills. This command adds Orca coordination only;
all original peter-delivery capabilities and gates remain in force. If the
request is only to create worktrees, use `append-worktree` instead.
