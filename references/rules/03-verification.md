# Verification: reading the evidence that decides the claim

Every rule here is one shape — I checked the thing I *could* check and reported on the thing I could not.

> Part of the `peter-delivery` contract. Rule numbers are stable — repo notes and
> `SKILL.md`'s gate table address rules by number, so they are never renumbered.

### 1. Never say "完成 / done"

Say what is verified and what is not:

> Logic verified (tsc, 462 tests, lint). **Visual: not verified** — I could not
> reach the panel in a browser. Do you want to look, or should I get the dev
> server up first?

Peter's single largest time sink is acting on a "done" that meant "the checks I
happen to be able to run are green." Never use one signal to stand in for
another.

### 2. Know what the test suite CANNOT see — then cover that gap yourself

Before trusting a green run, answer: **does this suite observe the kind of
defect I could be shipping?** Every stack has a blind spot, and it is usually
exactly where the acceptance criterion lives.

| If the criterion is | The suite usually cannot see it unless |
| --- | --- |
| what renders / copy / layout | it mounts components (jsdom/RTL, Vue Test Utils, XCTest UI…) |
| an HTTP contract | it exercises the route, not just the handler function |
| a query result | it runs against a real schema, not a mock |
| a build artifact | the build itself runs in CI |
| concurrency / ordering | it forces the interleaving |

Check the config, not your memory: `vitest.config`, `jest.config`, `conftest.py`,
`pom.xml` surefire config, `go test` tags. A project stating "no jsdom, test pure
logic not components" is telling you render bugs have **no automated home** —
then looking is not optional, it is the only coverage.

For anything that renders, see
[`references/visual-verification.md`](references/visual-verification.md). If
genuinely blocked, say so in those words and let Peter decide.

### 7. A config change is not live until the thing that reads it has re-read it

Writing a value is not applying it. Every layer has its own moment of reading, and
the gap between "the file says X" and "the running process sees X" is where a fix
looks done and isn't.

| Layer | Applies the change when |
| --- | --- |
| Docker `--env-file` | the container is **created** — `docker restart` re-runs the process with the *old* env; you must `rm` + `run` |
| GitHub Actions env vars | the next run starts; an in-flight run keeps the old values |
| A pipeline's own YAML | the run that starts *after* the merge — **re-running an old run executes the old file** |
| CORS / allow-lists in an env file | same as the process that read them (see Docker above) |

Verify at the layer that consumes it, never at the layer you wrote:
`docker exec <c> printenv KEY`, not `grep KEY .env`. On 2026-09-07 a restart was
declared as the fix for a missing key; the container had been *created* before the
edit, so the key never arrived and production kept failing for another twenty minutes.

### 8. A green run that did nothing is worse than a red one

Before reporting a pipeline as successful, ask **what it actually did**, not what it
concluded. Skipped is not passed.

- On 2026-09-07 a `Deploy` run finished **green with all four CD jobs skipped** — it
  built everything and deployed nothing. A tag would have reported a successful
  release over an untouched production.
- The cause was a GitHub rule worth remembering: a job whose upstream carries an `if:`
  with a status function is **skipped** unless it states its own `if:`. Silent, green.
- The reverse also happens: `v1.0.0` deployed everything correctly and went **red** on a
  verification step that lacked an IAM permission. The merge-back was gated on
  `conclusion == success`, so a fully successful release never reached `main`.

Read the per-job results, not the run's badge. When a run is red, establish whether
the *deliverable* failed or only the *check* did — they need opposite responses.

### 9. Enumerating a sample and reporting it as complete

"I checked the keys and they're all there" after comparing a dozen hand-picked ones is
a false statement, and Peter will find the missing one. On 2026-09-07 that pattern
missed `QUICK_ROUTER_API_KEY` — absent on all three hosts, with production v4 throwing
`RuntimeError` every time it was needed. Peter asked "did you really check them all?"
and the answer was no.

Diff the **whole set** mechanically (`comm -23 <(keys a) <(keys b)`), and say which
method you used. If you sampled, say you sampled.

Related trap from the same session: paginated APIs. `gh api .../variables` returns 10
by default; two variables that existed were reported as missing because they sat on
page 2. Any "X is missing" claim from a list endpoint needs `--paginate` before it is
worth saying out loud.

**A failed verification query is not a negative result.** On 2026-09-07, fanning out
16 PRs, six `gh pr create` calls hit `Post "https://api.github.com/graphql": EOF`.
The `gh pr list` run to check what actually existed hit the *same* transient error,
printed nothing, and the `comm -23` diff built on it duly reported all 16 bases as
missing — one step from creating 10 duplicate PRs. Ten of them existed.

The shape to recognize: **the error path and the empty result look identical once the
output reaches a pipe.** `cmd | sort > f` swallows the failure; `wc -l` then says 0,
and 0 reads as "none exist" rather than "I did not find out."

- Check for the error string before treating output as data. Retry the *check*, not
  just the action.
- The mechanical whole-set diff of rule 9 is only as good as the set it diffs. A
  correct `comm` over a silently-empty input produces a confidently wrong answer.
- After any batch operation, re-query and assert the **count** matches what was
  intended (`16 PRs / 16 bases`, no duplicates) — not just that the last call succeeded.

### 18b. A feature that ends in a provider call is verified at the provider's request body

On 2026-09-09 (Meegle 14583294) the Kling reference-version entrance was "done" three
times over at the UI — dialog, Details section, picker tab, guide bar, all screenshotted
and mutation-tested — and Peter asked the only question that mattered: does the picked
version reach the model provider as its `elements` parameter, "否则一切都是徒劳". The
dev database held four generations with `kling_elements` ever, none from a library
element: the path had never run. Tracing it end to end found a soft link — on the chat
surface the attachment reached the agent as a text line and nothing forced it into the
staged generation.

- For any feature whose value is a call to an external system, the deliverable is the
  request body that system receives. Write the test that drives the production path from
  the surface's first server-side shape to the mocked network call, per provider, and
  mutate each link.
- Query what the system has recorded (`select params from …generations where …`) before
  reasoning from code. Zero or four rows is the answer to "has this ever run".
- Anywhere an LLM sits between the user's choice and the request, ask what ENFORCES the
  choice. "The prompt tells it to" is not enforcement.

### 20. "Reasoned from code, not seen" is the line that names where the guard test goes

On 2026-09-10 (Meegle 14589462, PR #602) the fix closed the asset picker at
upload hand-over. I read that the Camera/Voice tabs call `onUpload` and THEN
`onClose`, saw that a toggle would reopen the picker, and made the upload
handler's close idempotent — then wrote in the report "the upload-then-close
order was checked by reading code, not in a browser". Copilot's first pass
found that `onClose` reaches the host's `onOpenChange`, which was STILL the
toggle. I had made one side of a double call idempotent and left the other.

- A double-call is fixed only when BOTH callers land on the same idempotent
  path. Grep for every site that reaches the state (`onOpenChange=`,
  `onClose=`, the setter itself), not just the one I am editing.
- The sentence "checked by reading, not verified" in my own report is not a
  disclaimer — it is the address of the missing guard test. Write that test
  BEFORE `gh pr create`; the bot will otherwise write it for me as a finding.
  Here it was a 60-line source pin (`setIsAssetPickerOpen((v) => !v)` must
  not exist; dismiss and upload share `closeAssetPicker`), mutation-checked.
- Run the test suite BEFORE the push, not in parallel with it. Same session:
  `vitest` and `git push` went out in one message, the suite failed on a
  source-proximity pin (`handleAssetPickerUpload[\s\S]{0,400}wire…`) my
  comments had pushed past 400 chars, and the branch was already on origin.
  In this repo, long explanations go in a docblock ABOVE the identifier a
  pin anchors on; body comments count toward the window.

### 27. A surviving mutation is an answer, not a gap to paper over (2026-09-18)

**Restore by copy, never by `git checkout`, and only after a checkpoint commit
(2026-10-08, moodio-agent).** The mutation loop restored each mutated file with
`git checkout -- <file>` while the real change was still uncommitted: the first
mutation wiped the rewrite of two files, and a second session's unstaged hunks
in a shared file would have gone the same way. Commit first (gate 12), then `cp`
the file aside and copy it back. A pattern that matches zero times after a
restore is the symptom that the file is no longer what you think it is.

Same session: three mutations of the GET de-duplicator, two caught, one
survived (removing `.clone()` for the first caller). The tempting move is to
invent an assertion that fails. The honest one is to work out whether the line
is observable at all — it was not, because every joiner attaches before the
entry is dropped — and write that reasoning where the line is, so the next
reader does not delete it as dead.

Report it as "one assertion survived its mutation and here is why no test can
tell", never as silence.

### 29. tsc and the node suite resolve a module graph the ROUTE BUNDLER refuses (2026-09-18)

Meegle 14294602. A shot's text edit answered `{"error":"Failed to update
shot"}` on Peter's dev server minutes after I reported "tsc, eslint, 7737
tests green". The change itself was right; the route no longer LOADED. Its
response now enriched a row with the shared `enrichDesktopAsset`, which
imports `@/lib/storage/s3` → `lib/image/compress` → `sharp`, a native module.
Pulling that graph into a workstation route stops Next from loading the route
at all — every request fails BEFORE the handler runs. tsc and vitest both
resolve the same graph happily, so every check I had was green over a route
that could not serve a single request.

- **A changed API route is verified by calling it on the running app**, not by
  typecheck plus unit tests. Both are blind to bundling, route runtime and
  native modules.
- **Run it BOTH ways when it fails**: import the handler in a node test and
  call it (in-process), and fetch the same URL against the dev server. 200 in
  process + 500 live means module loading, not logic — that comparison is what
  located this in minutes after an hour of reading code.
- **A request that should fail validation is the cheapest probe**: send a body
  the handler rejects early. A 400 means the handler ran; an empty 500 means it
  never did.
- Two of my own probes produced false trails first: a plain `Request` instead
  of `NextRequest` (undefined `.cookies`), and vitest's `test.env` placeholder
  `DATABASE_URL` overriding the real one. Print what the probe actually used
  (host, class) before believing its failure.
- The guard for this class is an **import rule**, not a behaviour test: name
  the modules a route may not import, and say why in the test. Nothing else
  can see it.

Before reporting a route change: `curl`/fetch it live, or say in the report
that the route was never called.

### Guard tests: the fixture must be the defect, verbatim

**A guard test's self-test must use the defect's VERBATIM shape, not a paraphrase.**
On 2026-09-10 (LFX-453) the AST guard's own fixture inlined the leaking
expression as `Item(preview=f"…" if a else "")`; the real defect was
`preview = f"…" if a else ""` then `Item(preview=preview)`. The fixture passed,
the scanner ignored `ast.Name`, and the guard was green over the exact bug it
was written for. Independent review (Codex lane, four challenge rounds) found
that, then that my fix kept only the *last* assignment (a later `preview = ""`
untainted it), then that my "skip dicts with a `role` key" prompt exemption also
skipped the API's own history messages, which carry a role. Three rounds on one
test. The rules: paste the original defect's lines into the fixture unchanged;
taint conservatively (any assignment, any branch); scope an exemption by the
exact shape of the thing exempted (bare `{role, content}`), not by one key it
shares with the data you protect. And the behavioural test that asserts the
*output* (`preview == ""`) is what actually caught the bug in the probes — keep
both, and say which one moved.

The same review also found a `||` that kept a stale count when an empty array
was authoritative (`session.artifacts?.length || s.artifactsCount`), and a live
update computing `stepsCount` from the active artifact while the reload path
summed all artifacts. **A field the client patches locally must be derived by
the same rule the server uses on reload** — put that rule in one helper and
test it against the server's semantics.

Mutation testing (#5) is cheap and has repeatedly caught my own vacuous
assertions — including one that passed because it matched a string inside a
comment. Break the code, confirm the specific test fails, restore. See
[`references/testing-that-earns-its-keep.md`](references/testing-that-earns-its-keep.md).
