# The two failure modes, with evidence

Read once. These are not hypotheticals — each is reconstructed from a session
where it cost Peter hours.

---

## Failure mode 1: substituting available evidence for required evidence

### What it looks like

```
write code → run tsc / vitest / eslint → all green → report "done"
```

Reasonable-looking, and wrong whenever the acceptance criterion is something
those tools do not observe.

### The evidence

Meegle bug 14511477, 2026-09-04. UI task: the video settings panel did not
match the spec. Timeline:

| Time | Commit | Trigger |
| --- | --- | --- |
| 11:09 | panel rebuilt as labelled sections | mine — **I said done** |
| 12:01 | catalog cache + unified chrome | Peter: "接口每次都 call" |
| 12:27 | chip shows real values | Peter screenshot |
| 12:40 | chip completed, type scale fixed | Peter: "样式也不对" |
| 12:44 | provider param filtering | found while chasing his next report |
| 13:08 | params derived in ChatInput | Peter screenshot: "没有 multi-shot" |
| 13:14 | render gate fixed | Peter: "还是没有" (same bug, 2nd cause) |
| 13:23 | AMOUNT → QUANTITY | Peter: "不是应该是 quantity 吗" |

**8 commits. 1 mine. 7 driven by Peter.**

### The number that settles it

That branch added **53 tests** (generation-rules 409 → 462). **Zero** caught the
four bugs Peter found. Not bad luck — mechanical:

| Bug | Decided by | Needs |
| --- | --- | --- |
| multi-shot editor missing (cause 1) | `videoModelParams.some(...)` inside JSX | component mounted |
| multi-shot editor missing (cause 2) | `videoWorkflowActive &&` gate | runtime menuState |
| chip read "Video settings" | `summary \|\| t("videoSettings")` | runtime videoParams |
| AMOUNT vs QUANTITY | rendered text | eyes |

And `CLAUDE.md:20` states plainly:

> tests are node-only vitest in `__tests__/` (**no jsdom/RTL; test pure logic,
> not components**)

I had read that line. I still handed UI correctness to a tool that by
construction cannot see it, then reported green as done.

### Why it happens

Green gates are executable, quantifiable, and quotable in a report. Visual
correctness is none of those. Under pressure to close, the measurable signal
displaces the required one.

### The correction

Name the acceptance criterion **before** choosing evidence:

- criterion is "looks like the spec" → evidence is a screenshot
- criterion is "the function returns X" → evidence is a test
- criterion is "the flow works end to end" → evidence is walking the flow

Then: **is the evidence I have the evidence this criterion needs?** If not, say
so out loud rather than substituting.

### Downstream symptoms

- *bugs everywhere at acceptance* — direct consequence
- *tests are low ROI* — wrong layer, not worthless; source scans prevent
  regressions but find nothing new
- *UI interaction testing is terrible* — true; the gap was hidden behind other
  green signals instead of stated
- *big thinking, poor execution* — analysis went to what was analyzable
  (structure, types, test strategy) instead of what decided the outcome

---

## Failure mode 2: filling an information gap with my own assumption

### What it looks like

Hitting a state I cannot resolve on my own, picking an assumption, continuing
silently.

### The evidence

Same session. Peter said the design prototype was at
`scratch/demos/Moodio 3.0 Standalone (1).html`.

| Moment | State | What I did | What was correct |
| --- | --- | --- | --- |
| First mention | path absent in my working dir (`scratch/` untracked → invisible in the worktree) | did not look, did not ask; **guessed from screenshots** | ask: "that path does not exist on my side — different path, or can I not see it?" |
| After he named it again | found it in the main checkout | grepped a few keywords, no hits → **concluded "the panel is not in the design"**, kept guessing | report: "searched X/Y/Z in that 15MB file, no hits — am I searching wrong, or is there another file?" |

Both times: **took a state I could not judge, filled it with an assumption, kept
going.**

The second is worse. A 15MB single-line escaped file, a handful of keywords.
**"I did not find it" and "it does not exist" are different claims** with
opposite correct responses — the first can only be asked about; only the second
licenses proceeding. I reported the first as the second.

### Why it compounds

That false conclusion — "no authoritative source, screenshots are all I have" —
became the premise for every subsequent styling decision. Guess, get corrected,
guess again.

**This is a major cause of the toothpaste pattern.** Not laziness about fixing
everything at once: reasoning from a false premise, which produces an endless
stream of small corrections no matter how diligent each one is.

### Same failure, three more times that session

- worktree `node_modules` broken → tried symlink, npm install, pnpm cleanup on
  my own for a long stretch, **never asked how he wanted it handled** (and a
  write through the symlink polluted the main checkout's `node_modules`)
- `npm ci` failed on lockfile desync → self-classified "pre-existing", worked
  around it, did not ask
- "reviewer 提了意见" but Meegle had no comments → inferred what the reviewer
  meant, never asked for the actual text

### The four triggers

Ask — do not assume — when:

1. A path/file/reference he gave does not exist on my side
2. A search **misses** and the conclusion depends on existence
3. Fixing the environment means changing his machine
4. He relays third-party feedback whose original text I cannot see

Common shape: **the answer is with Peter, not in the code.** No amount of
analysis derives it. Continuing is guessing.

### Cost asymmetry

One question costs him ~30 seconds. A wrong assumption cost hours and multiple
rounds. Asking is cheap; this is not a close call.

---

## Why acknowledging without changing fails

Peter's eighth complaint: *"我给你提出问题你都会欣然接受，但是下次仍然还会再犯."*

Correct, and the reason is mechanical. Each time I fixed **the instance he
pointed at**, never **the mechanism that produced it**. Acknowledgement was
rhetorical; nothing structural changed; the next instance was inevitable.

This skill exists to change the mechanism — a checklist that gates the word
"done", not a resolution to be more careful.
