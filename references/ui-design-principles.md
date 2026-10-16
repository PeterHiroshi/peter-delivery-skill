# UI design principles Peter has asked for, with the evidence

Peter reviews rendered UI, not diffs. These are the judgements he has made on my
UI more than once, phrased so I can apply them before he has to. They sit next to
`ui-ux-pro-max` (which supplies generic guidelines) — this file is the
project-independent part of what he considers "top UI/UX engineer" work.

## 1. A primary action gated on a fetch reads as a bug

2026-09-09, the asset Details panel's "Kling O3 / 3.0 adaptation" section: the
`New reference version` button was `disabled` until the rows had loaded (~400ms
against the dev RDS). Peter: "短时间不可用，会让用户误以为是 bug".

- Never disable the section's primary action because of a read that is in
  flight. Disable it for a REAL reason (a cap, no permission) and say the reason
  in a tooltip.
- Ask what is already known synchronously. The card row carried
  `elementCount`; that drives the status pill, the cap check and the next
  default name before the rows arrive. If a click beats the load, read the list
  in the save path, not by locking the button.
- Reserve the rows' space with exactly as many row-shaped placeholders as the
  known count, in the row's own box (same padding and font size), so nothing
  below moves when they land — measure the drift; 2px shows.

## 2. The feature the issue is about goes in the first viewport of its surface

Same section: the mockup put it under Aliases and Selected assets, below the
fold of a 560px panel. Peter twice: "有点儿靠下了". The "prerequisite first"
argument (its images come from Selected assets) lost — a novice reads
top-down and stops.

- Put the surface's primary task where the eye lands (after the identity
  fields, before secondary settings); make its prerequisites reachable from
  inside it (the picker lists them and says how to add more) instead of
  ordering the page by data dependency.
- Verify with geometry: the heading's offset inside the scroller and whether
  the action button's bottom is inside the scroller's box at the default
  height. "Moved one block up" is not evidence.

## 3. Copy the mockup; name things once

- Layout, spacing and wording come from the design file; "I improved it" is
  the thing Peter forbids (禁止自己随便设计). Deviate only with a numbered
  question, and record the answer in the design doc's §0 table.
- When two sources name one thing differently (issue: 元素; mockup: reference
  version), ask with both literal strings before the five-locale edit. Code
  and API names stay put.

## 4. Where the arrow points is the placement

An annotated screenshot's arrow is the spec for WHERE; the caption only names
the thing (2026-09-09: "增加入口" + an arrow at the picker's tab row meant a
tab, not a row inside a tab).

## 5. What to measure before saying "looks right"

| Claim | Measure |
| --- | --- |
| in view without scrolling | heading offset in the scroller, action button bottom ≤ scroller bottom, at the surface's default size |
| no flicker while loading | the action's `disabled` at t≈0 and after; count of placeholders vs rows; y-drift of the element below |
| visible at all | `getBoundingClientRect().height` of the tiles (a 2px collapse once passed every text assertion) |
| disabled for the right reason | the `title` on the disabled element, localized |

Every fix here: revert it alone and watch the number move back.

## Chat progress for end users vs. admins (math_ai, Peter 2026-10-16)

Peter on the first harness timeline (tool names, exit codes, sha prefixes, `adk2@2.12.0 · gpt-6.1-sol` in the chat bubble): "harness 感太强了". The rule he set:

- **End users (students, parents) get emotional value and plain language**: a few friendly steps they can follow ("读懂题目 → 我写了一小段程序来算 → 算出来了，正在核对 → 整理成答案"), reassuring wording on failure/retry, nothing that needs a programmer to decode. Optional "看看我是怎么算的" for a simplified narrative.
- **Never show the harness, model, sha, exit codes, token usage or tool names to users.** Those belong only in the admin console (session replay / 回扫用户 session), where the full technical timeline is wanted as-is.
- Same event stream, two renderers: keep one reducer, two presentations (`SolveJourney` for users, `AdminHarnessTimeline` for admins).
