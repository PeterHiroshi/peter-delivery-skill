# Derive, do not pass

Peter raised this three times in one session, which is his signal that it is
structural rather than incidental. It accounted for roughly **half** the bugs in
that session.

## The pattern

> Any state a host must supply is state some host will eventually fail to
> supply — and nothing fails loudly when it does.

Four instances, one session, same shape:

| Split thing | Consequence |
| --- | --- |
| `videoModelParams` was a **prop**, only the canvas node passed it | agent composer got `[]`; the multi-shot check was permanently false |
| three popovers each wrote their own radius/border/background | 2px / 4px / 6px, three border weights, three tokens |
| `node-composer` recomputed params (its own comment said *"mirrors chat-interface"*) | duplication was annotated and left in place |
| render gate used `mode` instead of `videoWorkflowActive` | the whole branch never ran on the agent surface |

The first and last are the *same bug* reached by two routes — I fixed one,
reported it fixed, and Peter found it still broken.

## The fix that actually works

Wrong: "make both hosts pass it."
Right: **delete the prop; let the component derive it.**

`ChatInput` was already computing `videoModeCapability`. It had everything
needed for `videoModelParams` and was being handed it anyway. After deriving it
internally and deleting the prop plus its single call site, **a third host
cannot get this wrong** — there is nothing to forget.

Convention → construction.

## The check, before adding any prop

**Can the component compute this from state it already holds?**

- **Yes** → derive it. Do not accept the prop.
- **No, genuinely host-specific** → pass it, *and* pin the branch count.

## Pinning legitimate divergence

Two differences in that panel are real, not drift:

- **QUANTITY, agent only** — `videoQuantity` tells Agent-2 how many cards to
  prepare; a canvas node generates one video and has no consumer. Rendering it
  there would be four buttons that do nothing.
- **Adaptive switch, node only** — Agent-2 sets `duration: "auto"` itself for
  tasks that need it; a manual toggle would contradict its own decision.

So the test allows **exactly two** `isNode` branches in that block and fails on a
third. Legitimate divergence stays; drift is caught.

```ts
const branches = chip.match(/isNode/g) ?? [];
expect(branches).toHaveLength(2);
```

Mutation-verify it: add a cosmetic `isNode` branch and confirm the test fails.

## Spotting it before Peter does

- a prop only one call site passes
- a comment saying "mirrors X" / "same as Y" — someone already noticed
- the same constant written in two files
- a `useMemo` in a host that the child could run itself

When one surface misbehaves and another does not, **suspect the input, not the
component**. The component is usually shared already; what differs is what each
host fed it.
