# Establishing project context

Peter works across ~90 repositories — Python (41), JS/TS (44), Java (29), Go,
C++, mobile. Assumptions carried from the last project are a reliable source of
wasted time.

**Do this before writing code in a repo you have not touched recently.** It
costs a few minutes and repeatedly prevents hours.

## The seven questions

### 1. What are the gates, and what do they NOT cover?

Find the real commands — `package.json` scripts, `Makefile`, `pom.xml`, `tox.ini`,
`.github/workflows/`, `CONTRIBUTING.md`, agent instruction files.

Then the question that matters: **what class of defect do these gates not
observe?** (See non-negotiable #2.) Write the answer down; it decides what you
must verify by hand.

### 2. Which package manager, and is the lockfile authoritative?

`package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `poetry.lock` /
`requirements.txt` / `go.sum` / `pom.xml`. **Using the wrong one produces a
subtly broken dependency tree that shadows a working install** and yields errors
that look like code bugs (unresolvable modules, phantom duplicate-package type
errors, a bundler that cannot find its own framework).

Also check whether the lockfile is actually in sync — a clean-install command
(`npm ci`, `poetry install --sync`) failing on a fresh checkout is a
**pre-existing repo condition**, not something you caused. Verify against an
untouched baseline before saying so.

### 3. Is this a worktree, submodule, or monorepo package?

Any of these changes what is visible from where you stand:

- **Worktree** — ignored paths (`scratch/`, `docs-local/`, design assets) exist
  in the main checkout but **not** in the worktree. A file Peter references may
  be invisible rather than missing. Check the main checkout before concluding.
- **Monorepo** — the framework may resolve only from the repo root, so
  package-local builds fail for structural reasons.
- **Submodule** — the change may need committing in two places.

### 4. Where does configuration and truth live?

Constants in code, a database, environment variables, or a remote service? This
decides whether the client can compute something locally or must fetch it, and
whether a value is per-user or identical for everyone.

A registry that is a module-level constant needs no network round trip — and a
fetch that returns build-time-constant data is pure latency.

### 5. What is the i18n / copy contract?

Which locales are active, where keys live, and **what happens when one is
missing** — a silent English fallback means a missing translation is invisible
until a user sees it.

Before adding a key, search for an existing one; before reusing a key, check its
value is semantically right for the new place, not merely renderable.

### 6. What must this change NOT touch?

Most repos have load-bearing areas: a shared validator, a pricing formula, a
schema, an auth boundary. Agent instruction files usually name them. State
explicitly in the PR that you did not touch them — reviewers check.

### 7. What are the local conventions?

Commit message style, branch naming, whether lint auto-fix is repo-wide
(dangerous) or scoped, migration conventions, whether docs must be a specific
language. Read the agent instructions file first; it usually answers several of
these at once.

## Where to look, in order

1. `CLAUDE.md` / `AGENTS.md` / `.cursorrules` — written for exactly this purpose
2. `README.md` / `CONTRIBUTING.md`
3. `.github/workflows/` — the gates that actually block a merge
4. Test config — the blind spot
5. `git log --oneline -20` — what recently changed and how commits are written

## Recording what you learn

When you discover something costly and non-obvious — a dependency trap, a
"looks like a bug but is pre-existing", a load-bearing invariant — write it to
memory so the next session does not rediscover it. Prefer a note that names the
**symptom** as well as the cause; the symptom is what you will hit next time.

## The transferable failures

These recur across stacks; only the surface changes:

| Pattern | Looks like |
| --- | --- |
| Wrong package manager | unresolvable imports, phantom type errors, bundler cannot find its framework |
| Ignored path invisible from a worktree | "the file you referenced does not exist" |
| Silent i18n fallback | English text in a non-English UI, no error anywhere |
| Config resolved differently client vs server | client shows options the server rejects |
| Lockfile out of sync | clean-install fails on a fresh checkout |
| Two surfaces, one component, different inputs | a control works on one screen and not another |
