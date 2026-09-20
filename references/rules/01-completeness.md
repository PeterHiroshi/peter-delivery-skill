# Completeness: did I build what was asked?

The only defect class no test can see. A missing feature has no red light, because the omission that dropped the feature dropped its test too.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 30. A test cannot see a feature that was never built — write the scope ledger first (Peter 2026-09-20)

Peter's own description of what the heavyweight process kept leaving behind:
「最后的结果也是会遗留 bug，这些 bug 可能不是稳定性上的，更多是功能上进行了剪裁，
这些剪裁不会被认为是 bug」. He is naming a defect class no suite can catch, and the
reason is structural: **the omission that drops a feature drops its test too.** A
missing feature has no red light. Every gate a testing or review pack owns —
coverage, diff review, mutation testing — runs downstream of the omission, over
what *was* built.

Correctness and completeness therefore need opposite instruments, and only one of
them is automatable:

| | The failure | The only detector | Cost |
| --- | --- | --- | --- |
| correctness | built it, behaves wrong | tsc / tests / one adversarial diff pass | high, automatable |
| stability | edges, concurrency, regressions | targeted tests + a live call | high |
| **completeness** | **never built it** | **an enumerated ledger, one verdict per line** | **10–20 min, not automatable** |

Corollary that decides where to spend: **more testing rigour returns nothing on
this class** and takes the budget from the one thing that would. Measured on
moodio-agent the day this rule was written — 771 test files, node-only vitest, no
jsdom / RTL / msw / storybook — the suite is structurally blind to every surface
where the cuts actually happen.

**The ledger.** A markdown table in the scratchpad, written BEFORE the code and
pasted into every round's hand-off:

| # | Item (behaviour Peter can see) | Source | Verdict |
| --- | --- | --- | --- |
| 1 | The import dialog accepts `.doc` | prototype screen 02 | done |
| 2 | The result page's meta row shows word count and updated-at | prototype screen 04 | **not-built** — stage B, needs the server's word-count definition |
| 3 | Undo a shot deletion | `07-create-assets.js` `renderShotDeletionUndo` | done |
| 4 | Four document-type cards, in the prototype's order | prototype screen 02 | done (not the registry's seven) |

Hard rules:

- Every item is **observable**: Peter judges yes/no without reading code.
  "Refactored the x module" is not an item.
- Every item **cites its source**: a prototype screen, a requirement sentence, a
  ticket line. **An item with no source may not exist** — that is rule 25's
  anti-drift gate made mechanical, in the same table.
- **No blanks.** `not-built` is a cut declared out loud. Cutting is not the
  offence; cutting silently is.
- Derive it from the **reference**, never from my implementation. Rule 22's seven
  cards against the prototype's four is exactly what reverse-derivation produces.
- For an **enumerable** set (option lists, locales, param matrices, model
  families) also land a derived-set test (import walk / registry read / glob) —
  machines can catch those cuts. **Narrative cuts — a whole screen, a whole
  interaction missing — only the ledger catches.**

The cost is already being paid: this table IS the numbered test-case list rule 24
requires. The ledger only pays it early, against the reference, instead of late,
against my memory of what I built.

### 3. One report → enumerate the whole class before fixing

Peter reports one instance. Fixing only that instance is what he calls
挤牙膏 (squeezing toothpaste), and it is the thing he complains about most.

| He reports | Enumerate first |
| --- | --- |
| one label wrong | every label on that surface, and where each string comes from |
| control missing on surface A | that control across **every** surface × every model/state |
| two things look different | diff **all** shared style constants, not the one he pointed at |
| one param wrong | the full rendered param matrix per model per surface |

Write the enumeration as a throwaway script and print a matrix. In the session
that produced this skill, doing that once collapsed three separate fixes into
one — and found a bug Peter had not reported.

**If you find yourself thinking "later I should audit the rest" — that audit is
the first action, not a follow-up.**

**Enumerate by MECHANISM, not by the reported string.** On 2026-09-10 (math_ai,
LFX-453) Peter sent one screenshot: a Chinese subtitle "1 个产物 · 共 2 步" on the
English sidebar. `grep 产物` found exactly one site and would have been the whole
fix. Naming the mechanism first — *the backend synthesizes user-facing text, the
client renders it verbatim* — and scanning for THAT (an AST walk over every
`content=` / `title=` / `preview=` slot in `backend/app`) found 13 more sites in
the same class, plus an account-page map keyed by Chinese literals that was
missing four of the backend's labels. Peter's own words on this class: 「这不是特别
案例了已经」. The steps that work:

1. Say in one sentence what the defective *mechanism* is (not what the string is).
2. Write the throwaway scanner for the mechanism; print every hit with a verdict
   (fix / prompt-not-display / allowlist-with-reason / follow-up ticket).
3. Turn the scanner into a committed guard test so the class cannot regrow, and
   mutation-test the guard on the original defect's shape.

**A hand-written list of the class is itself an instance of the toothpaste
pattern.** On 2026-09-14 (moodio-agent, Meegle 14665233) the guard test pinned
"the six files the canvas mounts under a node" by name. Two overlays in the
same class lived in files mounted BY those six (a duration chip in
`components/video/`, a multi-shot editor in `components/chat/`) and kept the
bug; the independent review found them, not me. The guard now walks the import
graph from the two mount roots and allowlists exceptions WITH reasons. When the
class is "everything reachable from X", derive the set in the test (import
walk, registry read, glob) — a name list is the enumeration frozen at the
moment I stopped looking.

i18n corollary that decided the fix shape: **text composed on a GET endpoint can
never follow the UI language** — the backend has no locale on that request.
Either send structured data (counts, keys) and let the client localize, or route
through the config-driven catalog (`region.localized_message` in math_ai). A
frontend map keyed by the backend's Chinese sentence is the same defect wearing a
translation table.

### 19. Verify the SURFACE the change touched, not the change — write the sweep before the run

Meegle 14583294, 2026-09-09, three passes in one day, and Peter found a defect after
each: the Create-page button opened no dialog (a second desktop key I never opened);
the three-column form overflowed (my harness was 560px wide, the real panel 460); a
hint rendered as a raw i18n key (a `{param}` I never passed, in a locale I never
looked at); a version with no video showed a video tile in its hover flyout (the
sibling element that renders the same row); a node lost its attached card once the
video landed (the completion path that REBUILDS the metadata). Every one was on the
surface my change touched and outside the path my verification walked. Peter's words:
"有很多问题之前都没有及时发现，现在只能打回来再重新搞".

The pattern is one omission repeated: I verified the code I wrote, at the size I
built it, in the locale I read, on the model I picked, through the path I coded.
Before the browser run, enumerate the dimensions the changed surface has and sweep
them — that enumeration is the test-case register the `ccl-skills:testing-strategy`
skill asks for, and it is written BEFORE the harness, not after Peter's screenshot:

- **width**: the real container's width (measure it in Peter's screenshot or the
  layout code), not the harness default;
- **locale**: all five, asserting the rendered strings from the catalog and that no
  `namespace.key` text appears; every `{param}` key needs a values object (now a
  static test, `i18n-params-are-passed.test.ts`);
- **row/data shape**: every combination the rules allow (images / video / audio /
  legacy both), on EVERY element that renders the row — the row, its meta, its
  flyout, its edit form;
- **model family**: every family the gate covers, off the registry, including the
  ones that take nothing (Kling 2.6);
- **write paths**: every builder that rewrites the data the UI reads (completion
  converters, reruns, spawns, PATCH allow-lists) — grep the field name across
  lib/ and app/ and read each hit;
- **cross-tab / second key**: any cache keyed by an id the page can have more
  than one of.

Then write the register with a verdict column (`pass` / `pass-browser` / `blocked`
/ `live-only` / `gap`) and hand THAT over. A green run over the path I coded is not
a verification of the feature; it is a verification of my typing.
