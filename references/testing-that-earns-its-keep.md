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

**Check whether the repo's suite actually reaches the row you need.** A project
whose config states "no jsdom, test pure logic not components" has no automated
home for rows 2–4 — those are covered by looking, and that must be stated rather
than implied.

## Source-scan tests

Some repos use them for invariants no pure function exposes — "which surface
renders", "which validator is called". They are legitimate, and two cautions
apply:

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

## Running the gates

Use the commands the repo actually defines — `package.json` scripts, `Makefile`,
`tox.ini`, `pom.xml`, and especially `.github/workflows/`, which shows what
truly blocks a merge. Do not invent commands, and do not assume the last
project's commands apply here.

Two habits that transfer:

- **Scope the linter to files you touched.** A repo-wide auto-fix will reformat
  hundreds of files you did not touch and bury your change.
- **Run the build, not just the typechecker.** They catch different things.

**Report counts, not "all green."** Peter reads numbers, and they show movement:
"462 passed, up from 409" says the gate grew; "all green" hides it. If a named
CI job covers your area, run that exact command so the local result and CI mean
the same thing.
