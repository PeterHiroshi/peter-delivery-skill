# Visual verification

The highest-leverage rule in this skill. It removes five of Peter's eight
complaints. In the session that produced it, **at least four of seven rework
rounds** were things I could have seen myself in one screenshot.

## When it is mandatory

Anything that changes what a user sees or can do:

- component render output, conditional rendering
- copy, labels, i18n
- layout, spacing, typography, colour
- enabling/disabling a control
- anything with a design spec

## Choosing the tool

Two paths exist. They are not interchangeable, and some repos restrict which
is allowed.

| Tool | Use for | Notes |
| --- | --- | --- |
| **gstack `/browse`** | headless screenshots of a running local server | fast, no interaction |
| **`chrome-devtools` MCP** | driving a real browser: click, fill, inspect DOM/console | `take_screenshot`, `navigate_page`, `click`, `list_pages`, `evaluate_script` |

**Check the repo's agent instructions first** — some restrict which browser
tooling is allowed. Read such a rule precisely: a prohibition naming one MCP
server (e.g. `claude-in-chrome`) does not cover a different one
(`chrome-devtools`). Do not over-apply a restriction into a blanket "I cannot
look", and do not ignore one either.

A headless screenshot cannot click. When the state that matters requires
interaction — open a popover, toggle a switch, attach a file — you need the
browser-driving tool.

For non-web UI (mobile, desktop, CLI output), the principle is unchanged even
though the tool differs: simulator screenshots, platform UI tests, or asking
Peter to look. *See it before claiming it.*

If starting a server or installing anything on his machine is involved, ask
first (trigger 3 of the ask rule).

## The loop

```
1. local server running (the repo's own dev command) — ask before starting one
2. navigate to the surface
3. put it in the state that matters (the data, the selection, the toggle, the
   panel actually open) — not the default state
4. screenshot
5. compare against the spec / his screenshot / the stated requirement
6. differences → fix them BEFORE reporting
7. deliver, stating what was checked and what was not
```

Step 3 is the one that gets skipped and is usually where the bug is. The
multi-shot bug only appears with: video workflow + a Kling model that declares
it + the toggle on + **on the agent surface**. A default screenshot shows
nothing.

## Enumerate states, not just the happy path

Pair with the whole-class rule. For a panel, the matrix is usually:

```
surfaces (agent / canvas node)
  × representative models (one per family, plus known edge cases)
  × relevant toggles (adaptive on/off, multi-shot on/off)
```

Cannot screenshot every cell. So:

1. compute the matrix in a throwaway script (fast, catches structural gaps)
2. screenshot the cells the script flags as different or risky

That combination found the provider-filtering bug nobody had reported.

## When you cannot look

Say it in these words:

> **Visual: not verified.** The dev server will not start here — <reason>. The
> logic is verified (tsc, N tests, lint). Do you want to look, or should I fix
> the environment first?

Never let a green test suite imply the UI is right. Peter has been burned by
exactly that.

## Cost

2–5 minutes per round. Against seven rework rounds and hours of his attention,
this is not a close call. Prefer taking the extra minutes over shipping a guess.

## What this does not cover

Real cross-browser rendering, animation timing, responsive breakpoints beyond
what is emulated. Those still need Peter or a real device. Say so rather than
implying full coverage.
