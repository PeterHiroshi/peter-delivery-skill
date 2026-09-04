# Testing that earns its keep

Peter's complaint: *"code review 或者是测试非常费时间，但是仍然会遗漏大量问题，ROI 非常低."*

He is right about the outcome. The cause is that tests were written at a layer
that could not observe the defects being shipped.

## The distinction that matters

| Kind | Answers | Value |
| --- | --- | --- |
| **Regression pin** | "does the known bug come back?" | after the fact — real, but zero help finding what is broken now |
| **Discovery** | "is something wrong I do not know about?" | during the work — this is what was missing |

53 tests were added in one session. Almost all were regression pins. **Zero**
found any of the four live bugs. Pins are worth keeping — they are just not
evidence that the change is correct.

**Discovery does not come from writing more tests. It comes from enumerating and
looking.**

## Mutation testing is non-negotiable for new assertions

A green test proves nothing until you have seen it fail for the right reason.

```
1. write the test, watch it pass
2. break the specific behaviour it claims to cover
3. confirm THAT test fails
4. restore
```

This caught a vacuous assertion of my own that would otherwise have shipped:

```ts
expect(bar).toContain('layout="panel"');   // also matches the string in a COMMENT
expect(bar).toMatch(/^\s+layout="panel"$/m); // line-anchored — actually fails when deleted
```

Version one stayed green with the real prop deleted. I only found it by
mutating. Assume every new assertion is vacuous until proven otherwise.

## Choosing the layer

| Defect shape | Layer that sees it |
| --- | --- |
| pure function wrong | unit test |
| **render condition false** | **mounted component (jsdom/RTL) or a browser** |
| **wrong copy** | **browser / snapshot** |
| **layout** | **browser** |
| two modules disagree | integration test |
| route accepts what UI forbids | route handler test |
| structural invariant | source scan |

**`moodio-agent` is node-only with no jsdom (`CLAUDE.md:20`), so rows 2–4 have
no automated home in that repo today.** Until that changes, they are covered by
looking, and that must be stated rather than implied.

## Source-scan tests

The repo uses them (`__tests__/generation-rules/*`) for invariants no pure
function exposes — "which surface renders", "which validator is called". They
are legitimate, and two cautions apply:

- **They match text, so they match comments too.** Anchor patterns; mutate to
  confirm.
- **They pin structure, not behaviour.** A scan proving a call exists does not
  prove its result is acted on.

## On code review gates

`ccl-skills:code-review` is a code-correctness instrument. It reads a diff. It
**cannot see a render**. Running it on a UI task is a category error — that is
why "the process ran fully and bugs still shipped."

Also: in that session I spent more time on `review_gate.sh` plan schemas
(`evidence` needs `{id, result}`, `self_review` needs five stage concerns) than
the gate could plausibly return, and never completed a run because HEAD kept
moving.

**If a gate is costing more than it returns, say so and move on.** Peter would
rather have the honest signal than the ceremony.

## What to run in `moodio-agent`

```bash
npx tsc --noEmit                                       # typecheck gate
npx vitest run --exclude '**/llm-integration*'         # full suite
npx vitest run __tests__/generation-rules \
              __tests__/kie-kling-frames.test.ts       # generation-rules CI job
npx eslint <only the paths you touched>                # never repo-wide --fix
npx next build                                         # catches what tsc does not
```

Report counts, not "all green" — Peter reads numbers and they show movement
(409 → 462 tests means the gate grew, not just passed).
