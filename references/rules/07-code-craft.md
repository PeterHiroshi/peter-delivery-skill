# Code craft: the shapes that produced repeat bugs

Three mistakes that each cost several rounds because each attempt looked correct.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 10. Prefer deriving over passing

Before adding a prop/param a host must supply, ask: **can the component compute
this itself from state it already has?**

- Derivable → derive it. Do not accept the prop.
- Genuinely host-specific → pass it, and add a test pinning the allowed number
  of per-host branches so drift fails loudly.

Rationale and the concrete case in
[`references/reuse-over-duplication.md`](references/reuse-over-duplication.md).
This one rule accounts for roughly half the bugs in the session that produced
this skill.

### 14. A latch must outlive what it latches — and a value guard beats a lifecycle guard

Meegle 14588335 took FOUR attempts because three of them guarded an effect with a
latch that reset at exactly the wrong moment:

1. latched a derived boolean that a mode change flipped false→true
2. latched a different boolean that a data-load flipped false→true
3. latched an identity — correct value, but the ref lived in a component the host
   mounts `key={node.id}`, so selecting a node rebuilt it as null

Each fix looked right, passed its tests, and Peter came back with the same bug.

Two rules came out of it:

- **Before trusting a ref/latch, ask what remounts the component that holds it.**
  Grep for `key=` on its ancestors. A ref in a `key`-ed subtree is per-instance
  memory, not per-entity memory, and the two look identical until the key changes.
- **Prefer guarding on the VALUE over guarding on the EVENT.** "Don't overwrite a
  value that is already set" needs no memory at all, so no lifecycle can defeat it.
  The final fix was one line — `if (params.aspect_ratio != null) return;` — after
  three attempts at remembering *when* to skip.

The other half: an independent review (`/codex`) found both the remount and a
second bug I had shipped — a heal-on-read that discarded a value the user could
legitimately choose, because I never checked whether the UI offered it as a real
option. **When you "clean up" a value as invalid, first check whether the product
lets the user pick it.**

### 18a. A value read back after a mechanical rewrite cannot tell "original" from "synthesized"

On 2026-09-09 (LFX-451) the reply bubble showed `Final answer: Final answer: (1) 0 (2) 1`.
The fix kept the explainer's human sentence *only if* the conclusion step already stated
every locked value; otherwise the step was overwritten with the mechanical
`Final answer: …` line. The helper that fetched "the human-readable sentence" ran **after**
that overwrite, re-read the conclusion step, found every locked value in it (of course —
the machine line contains them all) and returned the machine line as the sentence. Peter
saw it within minutes of running the branch.

- If a mutation can replace X with a synthesized value that satisfies the same predicate
  as a genuine X, then "read X back and re-check the predicate" is not a detector. Capture
  the decision at the point of mutation (return it, tag it) and pass it forward.
- The offline harness that validated the fix used a case where the sentence *passed*, so
  the rewrite branch was never exercised. Test the branch where the guard fails, not only
  the one where it succeeds.
