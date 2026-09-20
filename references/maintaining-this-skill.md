# Keeping this skill current — and keeping it CHEAP

This file is the record of what has actually cost Peter time. It is only worth what
gets written back into it.

**At the end of any task that produced a durable lesson, update this skill and push it.**
Not "if it feels noteworthy" — if the session contained any of the following, it goes in:

- a mistake I made that a rule here would have prevented (→ sharpen that rule with the
  new evidence, do not add a near-duplicate)
- a mistake no rule covers (→ new rule in **Non-negotiables**, with the date and the
  concrete failure; abstract rules without a scar do not change behaviour)
- a repo-specific trap, credential path, or environment quirk (→
  `references/projects/<repo>.md`, creating it if absent)
- a correction Peter made to my reasoning (→ wherever the wrong reasoning would recur)

Then commit and push to `origin` (`PeterHiroshi/peter-delivery-skill`). The repo is
Peter's, the push is expected, and it does not need separate approval the way a project
push does. Keep entries short and evidence-bearing: what happened, what it cost, what to
do instead. Delete rules that stop earning their place.

## Under rule 32's cap (2026-09-20)

Writing a lesson back is not free, and this file's instruction is what grew
`SKILL.md` to 68 KB and `references/projects/moodio-agent.md` to 114 KB of flat
append-only sections — about 52K tokens at the head of every task, the same order
of magnitude as the `ccl-skills` load Peter had just asked me to stop paying for.
So the write-back is now constrained:

- **Replace or sharpen.** A new lesson folds into the rule whose trigger it
  shares, or replaces one that has stopped earning its place. A near-duplicate
  rule is not a new rule — and a new rule that only restates an existing one with
  a fresh date is the pattern to refuse.
- **Twelve gates, hard cap.** A new gate in `SKILL.md` replaces one.
- **Rule detail goes to `references/rules/<group>.md`**, never to `SKILL.md`.
- **A project note gets an index row with every new section**, and its index is
  the only part read in full.
- When a rule is deleted, say so in the commit message with what replaced it.
