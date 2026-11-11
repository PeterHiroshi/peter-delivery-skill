# QA mode: natural simulated authors

Peter named this operating mode on 2026-11-11. It applies to Novmuser now and
to future agent products when he invokes "QA 模式". Run it through the existing
peter-delivery gates; it adds no thirteenth gate.

## Run loop

**Primary QA surface (Peter, 2026-11-11):** Use Computer Use to operate the
actual served product as a normal author. Give the product agent a small,
natural creative goal and let it generate and revise the manuscript itself;
do not prewrite most of the screenplay or dictate each scene, line or tool
step. Observe its source choices, edits, visible result, history, recovery and
state. Explain findings as needed; Peter's request to write less refers to
pre-authoring the test manuscript, not to hiding the QA reasoning. Synthetic
fixtures and code probes diagnose a witnessed failure, but do not substitute
for this real product experience or native agent choice. If identity, runtime,
or a bounded provider budget prevents a real turn, mark that journey held and
continue safe Computer Use paths; never describe a synthetic pass as the live
product result.

1. **Freeze scope before acting.** Record the user journey, product source,
   exact served revisions, account/work boundary, budget, and an observable
   scope ledger. Use an isolated worktree and disposable synthetic data. An
   inaccessible original sample stays inaccessible; never replace it with a
   fixture while claiming original acceptance.
2. **Speak like an author.** Scenario prompts express goals, not tool names,
   route flags, or "please use web search". Include a current external fact
   that requires reading, a saved-source/Wiki question, a no-tool control,
   denial/unavailable, cancellation/reload, and relevant write flows. Vary
   wording and context, and rotate genre, setting, characters, and author
   goals. Exercise the product's other real paths, such as materials, Wiki,
   review, history, and revision, rather than repeating one screenplay theme
   across cohorts. Freeze each exact prompt before a run. A tool may
   be proposed proactively; Policy/Gateway/Identity still decide access and
   explicit author consent still gates writes.
3. **Observe the actual consumption path.** Capture the author-visible result
   and the route, model/tool decision, policy outcome, source/read receipt,
   version, operation, and final state where each is consumed. Verify cited
   excerpts against the returned bytes. A fake Gateway or preselected tool
   call tests transport only; it cannot prove spontaneous model choice, real
   network reading, or citation quality. Preserve same-run test source and
   configuration with a hashed artifact; a result bundle alone cannot prove
   independent replay. Keep `offline`, `rendered`, and
   `live bounded` verdicts separate, following rules 12 and 13. For a
   no-tool answer, test paraphrases of fabricated read claims through visible
   text, history and replay. A deny regex catching one sentence does not prove
   truthfulness; a host-owned typed answer policy and verified read receipt
   must govern any positive read claim.
   For a new work, observe creation and the automatic opening agent turn as
   separate outcomes. If the turn fails, verify that the work and premise were
   saved, the author sees an accurate failure and explicit retry/edit path,
   reload preserves that state, and no duplicate work or automatic provider
   attempt occurs. Distinguish an intentionally closed QA gate from a real
   deployed service failure before filing a provider bug.
   For an uncertain chat retry, preserve the original request fingerprint with
   the same operation ID, including the sent scene focus after caret movement,
   work navigation, or reload. Confirm the exact request at the network
   boundary; a fresh terminal retry must use a new operation ID.
4. **Classify a new bug before dispatch.** Reproduce or pin a falsifiable
   counterexample, enumerate siblings by mechanism, deduplicate against open
   issues, and record expected versus actual behavior, exact input/revision,
   non-secret evidence, affected boundary, severity and owning repository.
   Use `jira-skill-distilled` for Jira search, creation, assignment and
   readback; do not create QA issues through a browser. Assign each QA issue
   to Jira account `peter.ma` and read the assignee back, so Peter receives
   the issue and its follow-up changes. If Jira is
   unavailable, keep a durable pending-assignment entry with the evidence and
   retry the write/readback; do not report it as assigned yet.
   Dispatch a worker in an isolated worktree with the old-red/new-green oracle.
   Do not auto-spawn from an unclassified failure or mark a ticket Done from a
   synthetic pass. Use the milestone batch rhythm for shared integration and
   one release lane for DEV acceptance.
5. **Close the loop.** Review the actual diff, run relevant static/route/browser
   checks, kill a targeted mutation, read the corrected value at its consumer,
   and bind CI/XP/DEV evidence to exact source and image digests. Update the
   tracker with both pass and open gaps. Rerun only affected scenarios on a
   corrected head; keep live-only claims open until actually observed.

## Budget and identity

The scenario manifest states allowed provider attempts and a hard spending
bound before any paid run. An HTTP-operation cap is not a provider-attempt or
currency cap. With a zero or unenforceable bound, continue offline and rendered
work without a paid call. Never use an exposed credential transcript, infer
authorization from a `404`, elevate a model-supplied identity or URL into a
trusted source, or bypass the product's Gateway/Policy/host verifier.

The QA report is concise: scenario and exact prompt, observed layer, result,
consumed receipts, defect dispatch, cleanup, and the claims still unverified.
