# Task playbook

Concrete opening moves. The goal is that Peter states the task once and does not
have to steer.

## Bug fix

### 1. Reproduce and read the actual evidence

Read the failing owner's own evidence first — assertion diff, stack, the
screenshot he sent. Do not name a cause before seeing it. A cause is a
**hypothesis** until an operation that could have falsified it has run and did
not.

### 2. Enumerate the class before touching anything

The reported instance is a sample. Before any fix, produce the matrix:

- which surfaces render this?
- which models/states/locales reach it?
- where else does this same string/constant/condition appear?

A throwaway script printing a matrix is the fastest form. Delete it after.

This one step collapsed three fixes into one and found an unreported bug in the
session that produced this skill.

### 3. Trace to the first point where it became wrong

Fix it there. Guarding at the point of observation is defence in depth, never
the fix. A wrong value has an origin; find the correct→faulty transition.

### 4. Check every surface that renders it

Whenever one component is reached from more than one host, screen, or entry
point, verify the fix on **every** one. Suspect any condition keyed on a field
the hosts set differently — that is the classic "works here, not there" shape,
and it is easy to declare fixed after checking only the one Peter mentioned.

See `references/projects/` for a note on the repo at hand, if one exists.

### 5. Fix, pin, mutate

Write the regression test, then break the code and confirm **that** test fails.

### 6. Verify at the right layer

Renders → look at it. Logic → tests. Say which you did.

## Feature

1. **Scope** — restate what he asked for; flag ambiguity now, not after coding
2. **Design doc** — file, present, wait (`design-doc-before-coding`)
3. **Route** — see the routing table in `SKILL.md`
4. **Build** — derive over pass (`reuse-over-duplication.md`)
5. **Verify** — gates + visual if it renders
6. **Report** — verified / not verified, then ask before pushing

## UI task specifically

**Read the design source first.** If Peter names a file, read it before writing
code. If the path is not visible from the worktree, check the main checkout;
if still absent, **ask** — do not substitute screenshots silently.

If the design file exists but does not contain this screen, say so explicitly:

> I searched the prototype for DURATION / RESOLUTION / QUANTITY / "Video
> settings" — no hits, and none of its 56 uppercase section headings match. I
> think this panel is not in that file. Is there another source, or should I
> work from your screenshots?

That sentence, said early, would have prevented several rounds.

**"Read the design source" means RENDER it, not read its markup.** On
2026-09-15 (moodio-agent, Meegle 14294602 sub-02) I read the prototype's
dialog markup, its CSS rules and its CLAUDE.md "弹窗规范", built the dialog
in the app's own panel chrome, screenshotted MINE, and reported it as
verified. Peter: "你完成的和 moodio-ui 中的样式完全不一致呀". Serving the
prototype (`python3 -m http.server 8765` in moodio-ui, headless Chrome,
click `#import-text-button`, screenshot `#flow-dialog`, dump computed
styles) took four minutes and showed a 620px flow dialog with a
watercolor title bar and name-only cards — none of which the markup read
had made me build. For a UI task the prototype's screenshot sits BESIDE
mine in the report, with the measured numbers (width, radius, card size,
font sizes) in a two-column table; a description of the prototype from
its source is not a comparison.

Then: render the prototype → build → screenshot both → compare numbers →
fix differences → deliver.

## When Peter pushes back

1. **Check the facts first.** He is usually right, but not always, and agreeing
   without checking wastes his time. If he is wrong, say so with evidence.
2. **Do not just fix the instance.** Ask what class it belongs to and sweep it.
3. **Correct my own earlier claims explicitly.** Once, plainly, then move on.
   Twice in one session I told him something backwards about the registry; each
   correction was necessary and neither needed an apology.
4. **If it is a process complaint, change the mechanism, not the intention.**
   "I will be more careful" has failed every time. A gate that blocks the word
   "done" has not.

## Time discipline

Peter's benchmark: *"就这个 issue，你前后足足修了有 3 个小时，这个交给人工也不需要这么长时间."*

Where the time actually went:

- 7 rework rounds, all avoidable by looking once (~2h)
- environment thrashing without asking (~30min)
- configuring a review gate that never completed a run (~20min)

None was writing code. **Wasted time is almost always spent avoiding a
30-second question or a 3-minute screenshot.**

If something is taking long, say what is happening rather than going quiet:

> node_modules 坏了，我试了两种修法都不行。你想让我重装，还是你自己处理？
