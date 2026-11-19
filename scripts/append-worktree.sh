#!/usr/bin/env bash
# Create a task worktree the way THIS repo already does it.
#
# Everything here is mechanical: the layout, the branch name, the .env copy, the
# install, the editor window. The caller supplies only what it cannot derive —
# the branch type, the tracker id, and a short English slug.
#
# The per-repo layout is detected once from the worktrees that already exist and
# then cached in $GIT_COMMON_DIR/peter-delivery-worktree.conf, so later runs do
# no guessing at all.

set -euo pipefail

usage() {
  cat <<'USAGE'
append-worktree.sh --type fix|feat|<other> --slug <kebab-case> [options]

  --type <t>     branch type segment (fix, feat, chore, pm, ...). Required.
  --slug <s>     3-5 English words, kebab-case, no tracker id. Required.
  --id <n>       tracker (Meegle) work item id, or a URL containing it.
  --from <ref>   base commit-ish for the new branch (default: repo default branch).
  --base <dir>   worktrees directory, overriding detection (absolute or repo-relative).
  --naming <n>   full (<base>/fix/<rest>, nested per type) | strip (<base>/<rest>)
                 | flat (<base>/fix-<rest>). Overrides detection and is pinned in
                 the repo's conf, so it only has to be said once.
  --repo <dir>   any path inside the target repo (default: $PWD).
  --task <text>  what the new session should work on, in Peter's own words.
                 Used for the first prompt; defaults to the slug and the link.
  --no-install   skip the background dependency install.
  --no-open      do not open the worktree in the editor.
  --no-auto-start  do not arm the first agent session in the new window.
  --runner <r>   agy | claude | codex (alias: --cli, --agent). Default: inferred
                 from --model if it names an Antigravity or Codex model, else from
                 the calling environment (Antigravity -> agy, Codex -> codex,
                 otherwise claude).
  --model <m>    model for that session.
                 - agy: full ID/display name from `agy models` or shorthand family
                   (argon, carbon, hydrogen, flash, orchestrator, orchestrator-argon,
                   opus-5.5, sonnet-5.5, gpt-oss; e.g. gemini-4-argon-medium,
                   gemini-4-carbon-high, gemini-4-hydrogen-xhigh, claude-opus-5-5-high).
                   Default: ~/.gemini/antigravity-cli/settings.json.
                 - claude: alias like opus/sonnet or full name. Default: ~/.claude/settings.json.
                 - codex: model name (e.g. gpt-5.4, o3). Default: ~/.codex/config.toml.
  --effort <l>   low | medium | high | xhigh | max. For agy family shorthands
                 (e.g. --model argon --effort high -> gemini-4-argon-high) and
                 passed as --effort to agy/claude or model_reasoning_effort to codex.
  --permission-mode <m>  permission preset (default: full).
                 full -> agy: --dangerously-skip-permissions,
                         claude: --permission-mode bypassPermissions,
                         codex: --dangerously-bypass-approvals-and-sandbox.
                 Override/opt-out: default | auto | accept-edits | plan | manual
                 (plus claude's dontAsk).
  --fetch        git fetch the base ref from origin before branching.
  --dry-run      print the plan, touch nothing.
USAGE
}

TYPE="" SLUG="" ID="" FROM="" BASE_OVERRIDE="" REPO="$PWD" TASK=""
DO_INSTALL=1 DO_OPEN=1 DO_FETCH=0 DRY_RUN=0 DO_AUTO_START=1
RUNNER="" MODEL="" EFFORT="" PERM_MODE="" NAMING_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --type) TYPE="${2:-}"; shift 2 ;;
    --slug) SLUG="${2:-}"; shift 2 ;;
    --id) ID="${2:-}"; shift 2 ;;
    --from) FROM="${2:-}"; shift 2 ;;
    --base) BASE_OVERRIDE="${2:-}"; shift 2 ;;
    --naming) NAMING_OVERRIDE="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --task) TASK="${2:-}"; shift 2 ;;
    --no-install) DO_INSTALL=0; shift ;;
    --no-auto-start) DO_AUTO_START=0; shift ;;
    --runner|--cli|--agent) RUNNER="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --effort) EFFORT="${2:-}"; shift 2 ;;
    --permission-mode) PERM_MODE="${2:-}"; shift 2 ;;
    --no-open) DO_OPEN=0; shift ;;
    --fetch) DO_FETCH=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "append-worktree: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

die() { echo "append-worktree: $*" >&2; exit 2; }

# --- inputs ------------------------------------------------------------------

[ -n "$TYPE" ] || die "missing --type (fix | feat | ...)"
[ -n "$SLUG" ] || die "missing --slug: 3-5 English words in kebab-case, taken from what the task is about"

# A URL is accepted for --id. Two of them are not: one run makes one worktree,
# and quietly using the first link would ship half of what was asked.
ID_RAW="$ID"
if [ -n "$ID" ]; then
  ID_TOKENS="$(printf '%s' "$ID" | tr -s '[:space:]' '\n' | grep -cE '[0-9]{4,}' || true)"
  [ "${ID_TOKENS:-0}" -le 1 ] || die "--id got $ID_TOKENS tasks. One worktree per run: call this script once per link, each with its own --slug"

  # The id is a path segment, never the query — .../detail/14959916?ts=1758300000
  # would otherwise brand the branch with the timestamp.
  ID_PATH="${ID%%\#*}"; ID_PATH="${ID_PATH%%\?*}"
  ID="$(printf '%s' "$ID_PATH" | tr '/' '\n' | grep -xE '[0-9]{4,}' | tail -1 || true)"
  [ -n "$ID" ] || ID="$(printf '%s' "$ID_PATH" | grep -oE '[0-9]{4,}' | tail -1 || true)"
  [ -n "$ID" ] || die "--id had no work item number in it"
fi

# Normalise the slug the same way every time: lowercase, non-alphanumerics to
# dashes, no leading/trailing/duplicate dashes.
SLUG_RAW="$SLUG"
SLUG="$(printf '%s' "$SLUG" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
[ -n "$SLUG" ] || die "--slug became empty after normalisation; give ASCII words"
# Silently dropping CJK would leave a slug that does not say what the task is.
if printf '%s' "$SLUG_RAW" | LC_ALL=C grep -q '[^ -~]'; then
  echo "warning   --slug had non-ASCII characters; they were dropped, leaving '$SLUG'. Re-run with English words if that reads wrong." >&2
fi
TYPE="$(printf '%s' "$TYPE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+//g')"

case "${NAMING_OVERRIDE:-none}" in
  none|full|strip|flat) ;;
  *) die "--naming must be one of full, strip, flat" ;;
esac

case "${EFFORT:-none}" in
  none|low|medium|high|xhigh|max) ;;
  *) die "--effort must be one of low, medium, high, xhigh, max" ;;
esac

# --- runner & model resolution (agy / claude / codex) ------------------------

is_agy_model() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    gemini-*|argon*|carbon*|hydrogen*|flash*|orchestrator*|*opus-5-5*|*opus-5.5*|*opus\ 5.5*|*sonnet-5-5*|*sonnet-5.5*|*sonnet\ 5.5*|gpt-oss*)
      return 0 ;;
    *) return 1 ;;
  esac
}

is_codex_model() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    gpt-5*|o3*|o4*|codex*) return 0 ;;
    *) return 1 ;;
  esac
}

if [ -n "$RUNNER" ]; then
  case "$(printf '%s' "$RUNNER" | tr '[:upper:]' '[:lower:]')" in
    agy|antigravity) RUNNER="agy" ;;
    claude|claude-code) RUNNER="claude" ;;
    codex) RUNNER="codex" ;;
    *) die "--runner must be one of agy, claude, codex" ;;
  esac
elif [ -n "$MODEL" ] && is_agy_model "$MODEL"; then
  RUNNER="agy"
elif [ -n "$MODEL" ] && is_codex_model "$MODEL"; then
  RUNNER="codex"
elif [ -n "${ANTIGRAVITY_AGENT:-}${ANTIGRAVITY_CONVERSATION_ID:-}${AGY_ENABLE_HUB:-}" ]; then
  RUNNER="agy"
elif [ -n "${CODEX_SANDBOX:-}${CODEX_THREAD_ID:-}" ]; then
  RUNNER="codex"
else
  RUNNER="claude"
fi

# Resolve Antigravity (agy) model aliases, display names, and family + effort
# combinations to canonical slug IDs from `agy models`.
resolve_agy_model() {
  local raw="${1:-}" eff="${2:-}" norm
  [ -n "$raw" ] || return 0
  norm="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]()]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  case "$norm" in
    argon|gemini-4-argon)
      case "$eff" in
        low) echo "gemini-4-argon-low" ;;
        high|xhigh|max) echo "gemini-4-argon-high" ;;
        *) echo "gemini-4-argon-medium" ;;
      esac ;;
    argon-low|gemini-4-argon-low) echo "gemini-4-argon-low" ;;
    argon-medium|gemini-4-argon-medium) echo "gemini-4-argon-medium" ;;
    argon-high|gemini-4-argon-high) echo "gemini-4-argon-high" ;;

    carbon|gemini-4-carbon)
      case "$eff" in
        low) echo "gemini-4-carbon-low" ;;
        high|xhigh|max) echo "gemini-4-carbon-high" ;;
        *) echo "gemini-4-carbon-medium" ;;
      esac ;;
    carbon-low|gemini-4-carbon-low) echo "gemini-4-carbon-low" ;;
    carbon-medium|gemini-4-carbon-medium) echo "gemini-4-carbon-medium" ;;
    carbon-high|gemini-4-carbon-high) echo "gemini-4-carbon-high" ;;

    hydrogen|gemini-4-hydrogen)
      case "$eff" in
        low) echo "gemini-4-hydrogen-low" ;;
        medium) echo "gemini-4-hydrogen-medium" ;;
        xhigh|max) echo "gemini-4-hydrogen-xhigh" ;;
        *) echo "gemini-4-hydrogen-high" ;;
      esac ;;
    hydrogen-low|gemini-4-hydrogen-low) echo "gemini-4-hydrogen-low" ;;
    hydrogen-medium|gemini-4-hydrogen-medium) echo "gemini-4-hydrogen-medium" ;;
    hydrogen-high|gemini-4-hydrogen-high) echo "gemini-4-hydrogen-high" ;;
    hydrogen-xhigh|gemini-4-hydrogen-xhigh) echo "gemini-4-hydrogen-xhigh" ;;

    flash|gemini-3.8-flash|gemini-3-8-flash)
      case "$eff" in
        low) echo "gemini-3.8-flash-low" ;;
        medium) echo "gemini-3.8-flash-medium" ;;
        *) echo "gemini-3.8-flash-high" ;;
      esac ;;
    flash-low|gemini-3.8-flash-low|gemini-3-8-flash-low) echo "gemini-3.8-flash-low" ;;
    flash-medium|gemini-3.8-flash-medium|gemini-3-8-flash-medium) echo "gemini-3.8-flash-medium" ;;
    flash-high|gemini-3.8-flash-high|gemini-3-8-flash-high) echo "gemini-3.8-flash-high" ;;

    orchestrator|orchestrator-carbon|gemini-pro-orchestrator) echo "gemini-pro-orchestrator" ;;
    orchestrator-argon|gemini-pro-orchestrator-argon) echo "gemini-pro-orchestrator-argon" ;;

    opus|opus-5.5|opus-5-5|claude-opus-5.5|claude-opus-5-5)
      case "$eff" in
        low) echo "claude-opus-5-5-low" ;;
        medium) echo "claude-opus-5-5-medium" ;;
        *) echo "claude-opus-5-5-high" ;;
      esac ;;
    opus-low|opus-5.5-low|opus-5-5-low|claude-opus-5.5-low|claude-opus-5-5-low) echo "claude-opus-5-5-low" ;;
    opus-medium|opus-5.5-medium|opus-5-5-medium|claude-opus-5.5-medium|claude-opus-5-5-medium) echo "claude-opus-5-5-medium" ;;
    opus-high|opus-5.5-high|opus-5-5-high|claude-opus-5.5-high|claude-opus-5-5-high) echo "claude-opus-5-5-high" ;;

    sonnet|sonnet-5.5|sonnet-5-5|claude-sonnet-5.5|claude-sonnet-5-5)
      case "$eff" in
        low) echo "claude-sonnet-5-5-low" ;;
        medium) echo "claude-sonnet-5-5-medium" ;;
        *) echo "claude-sonnet-5-5-high" ;;
      esac ;;
    sonnet-low|sonnet-5.5-low|sonnet-5-5-low|claude-sonnet-5.5-low|claude-sonnet-5-5-low) echo "claude-sonnet-5-5-low" ;;
    sonnet-medium|sonnet-5.5-medium|sonnet-5-5-medium|claude-sonnet-5.5-medium|claude-sonnet-5-5-medium) echo "claude-sonnet-5-5-medium" ;;
    sonnet-high|sonnet-5.5-high|sonnet-5-5-high|claude-sonnet-5.5-high|claude-sonnet-5-5-high) echo "claude-sonnet-5-5-high" ;;

    gpt-oss|gpt-oss-120b|gpt-oss-120b-medium) echo "gpt-oss-120b-medium" ;;
    *) echo "$raw" ;;
  esac
}

RESOLVED_MODEL="$MODEL"
if [ "$RUNNER" = "agy" ] && [ -n "$MODEL" ]; then
  RESOLVED_MODEL="$(resolve_agy_model "$MODEL" "$EFFORT")"
fi

[ -n "$PERM_MODE" ] || PERM_MODE="full"

RUNNER_ARGS=""
PERM_LABEL=""
case "$RUNNER" in
  agy)
    [ -n "$RESOLVED_MODEL" ] && RUNNER_ARGS="$RUNNER_ARGS --model $RESOLVED_MODEL"
    [ -n "$EFFORT" ] && RUNNER_ARGS="$RUNNER_ARGS --effort $EFFORT"
    case "$PERM_MODE" in
      full|bypassPermissions|bypass|dangerously-skip-permissions|dangerously-bypass-approvals-and-sandbox)
        RUNNER_ARGS="$RUNNER_ARGS --dangerously-skip-permissions"
        PERM_LABEL="full (--dangerously-skip-permissions)" ;;
      default|none|manual)
        PERM_LABEL="default" ;;
      acceptEdits|accept-edits)
        RUNNER_ARGS="$RUNNER_ARGS --mode accept-edits"
        PERM_LABEL="accept-edits" ;;
      auto|full-auto)
        RUNNER_ARGS="$RUNNER_ARGS --mode auto"
        PERM_LABEL="auto" ;;
      plan)
        RUNNER_ARGS="$RUNNER_ARGS --mode plan"
        PERM_LABEL="plan" ;;
      *)
        die "--permission-mode '$PERM_MODE' is not supported for agy (use full|auto|accept-edits|plan|default)" ;;
    esac
    ;;
  codex)
    [ -n "$RESOLVED_MODEL" ] && RUNNER_ARGS="$RUNNER_ARGS -m $RESOLVED_MODEL"
    [ -n "$EFFORT" ] && RUNNER_ARGS="$RUNNER_ARGS -c model_reasoning_effort=\\\"$EFFORT\\\""
    case "$PERM_MODE" in
      full|bypassPermissions|bypass|dangerously-skip-permissions|dangerously-bypass-approvals-and-sandbox)
        RUNNER_ARGS="$RUNNER_ARGS --dangerously-bypass-approvals-and-sandbox"
        PERM_LABEL="full (--dangerously-bypass-approvals-and-sandbox)" ;;
      default|none)
        PERM_LABEL="default" ;;
      manual)
        RUNNER_ARGS="$RUNNER_ARGS -a on-request"
        PERM_LABEL="manual (-a on-request)" ;;
      auto|full-auto)
        RUNNER_ARGS="$RUNNER_ARGS --approve-for-me"
        PERM_LABEL="auto (--approve-for-me)" ;;
      acceptEdits|accept-edits)
        RUNNER_ARGS="$RUNNER_ARGS -a never -s workspace-write"
        PERM_LABEL="workspace-write (-a never -s workspace-write)" ;;
      plan)
        RUNNER_ARGS="$RUNNER_ARGS -s read-only -a on-request"
        PERM_LABEL="plan (-s read-only -a on-request)" ;;
      *)
        die "--permission-mode '$PERM_MODE' is not supported for codex (use full|auto|accept-edits|plan|manual|default)" ;;
    esac
    ;;
  claude)
    [ -n "$RESOLVED_MODEL" ] && RUNNER_ARGS="$RUNNER_ARGS --model $RESOLVED_MODEL"
    [ -n "$EFFORT" ] && RUNNER_ARGS="$RUNNER_ARGS --effort $EFFORT"
    case "$PERM_MODE" in
      full|bypassPermissions|bypass|dangerously-skip-permissions|dangerously-bypass-approvals-and-sandbox)
        RUNNER_ARGS="$RUNNER_ARGS --permission-mode bypassPermissions"
        PERM_LABEL="full (bypassPermissions)" ;;
      default|none)
        PERM_LABEL="default" ;;
      acceptEdits|accept-edits)
        RUNNER_ARGS="$RUNNER_ARGS --permission-mode acceptEdits"
        PERM_LABEL="acceptEdits" ;;
      auto|full-auto)
        RUNNER_ARGS="$RUNNER_ARGS --permission-mode auto"
        PERM_LABEL="auto" ;;
      manual|dontAsk|plan)
        RUNNER_ARGS="$RUNNER_ARGS --permission-mode $PERM_MODE"
        PERM_LABEL="$PERM_MODE" ;;
      *)
        die "--permission-mode '$PERM_MODE' is not supported for claude (use full|bypassPermissions|auto|acceptEdits|dontAsk|plan|manual|default)" ;;
    esac
    ;;
esac

git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || die "$REPO is not a git repository"

# The main checkout — worktrees are registered against it, and it is where the
# ignored .env files live.
MAIN="$(git -C "$REPO" worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
COMMON_DIR="$(cd "$MAIN" && git rev-parse --path-format=absolute --git-common-dir)"
CONF="$COMMON_DIR/peter-delivery-worktree.conf"

# --- layout: read the cached answer, else learn it from existing worktrees ----

BASE_DIR="" NAMING="" ID_IN_BRANCH=""
# shellcheck source=/dev/null
[ -f "$CONF" ] && . "$CONF"

# Every registered worktree except the main checkout, as "path<TAB>branch".
existing_worktrees() {
  git -C "$MAIN" worktree list --porcelain | awk -v main="$MAIN" '
    /^worktree /{ path = substr($0, 10); branch = "" }
    /^branch /   { branch = substr($0, 8); sub("refs/heads/", "", branch) }
    /^$/         { if (path != main && path != "") print path "\t" branch; path = "" }
    END          { if (path != main && path != "") print path "\t" branch }'
}

if [ -n "$BASE_OVERRIDE" ]; then
  case "$BASE_OVERRIDE" in /*) BASE_DIR="$BASE_OVERRIDE" ;; *) BASE_DIR="$MAIN/$BASE_OVERRIDE" ;; esac
fi
[ -n "$NAMING_OVERRIDE" ] && NAMING="$NAMING_OVERRIDE"

# One pass over the existing worktrees answers both questions at once, because
# they are not independent: under a nested layout the directory that holds a
# worktree is part of the BRANCH name, not part of the layout.
#
#   full  -> <base>/fix/meegle-123-x   (path keeps the whole branch)
#   strip -> <base>/meegle-123-x       (leading type segment dropped)
#   flat  -> <base>/fix-meegle-123-x   (slashes become dashes)
#
# A single-segment branch (main, gh-pages) looks the same under all three, so it
# votes on the base directory only.
DETECTED="$(existing_worktrees | awk -F'\t' '
  $2 != "" {
    path = $1; branch = $2
    name = path; sub(/.*\//, "", name)
    parent = path; sub(/\/[^\/]*$/, "", parent)
    suffix = "/" branch

    if (branch ~ /(^|\/)meegle-[0-9]+/) meegle = 1

    if (branch !~ /\//) { vote(parent, ""); next }

    if (length(path) > length(suffix) && substr(path, length(path) - length(suffix) + 1) == suffix) {
      vote(substr(path, 1, length(path) - length(suffix)), "full"); next
    }
    strip = branch; sub(/^[^\/]+\//, "", strip)
    flat  = branch; gsub(/\//, "-", flat)
    if (name == strip) { vote(parent, "strip"); next }
    if (name == flat)  { vote(parent, "flat");  next }
    vote(parent, "")
  }
  function vote(base, rule) {
    bases[base]++
    if (bases[base] > topbase) { topbase = bases[base]; base_win = base }
    if (rule == "") return
    pairs[base "\t" rule]++
    if (pairs[base "\t" rule] > toppair) { toppair = pairs[base "\t" rule]; pair_win = base "\t" rule }
  }
  END {
    if (pair_win != "") print pair_win "\t" (meegle ? 1 : 0)
    else if (base_win != "") print base_win "\tstrip\t" (meegle ? 1 : 0)
  }' || true)"

SAMPLES=0
if [ -n "$DETECTED" ]; then
  SAMPLES=1
  [ -n "$BASE_DIR" ] || BASE_DIR="$(printf '%s' "$DETECTED" | cut -f1)"
  [ -n "$NAMING" ]   || NAMING="$(printf '%s' "$DETECTED" | cut -f2)"
  [ -n "$ID_IN_BRANCH" ] || ID_IN_BRANCH="$(printf '%s' "$DETECTED" | cut -f3)"
fi

if [ -z "$BASE_DIR" ]; then
  # No worktrees to learn from: only take a layout that is already on disk.
  for candidate in "$MAIN/.work/worktrees" "$MAIN/worktrees" "$MAIN/../$(basename "$MAIN")-worktrees"; do
    [ -d "$candidate" ] && { BASE_DIR="$candidate"; break; }
  done
fi

[ -n "$BASE_DIR" ] || die "no worktree layout found in this repo. Re-run with --base <dir> (ask Peter where worktrees go; do not invent one)"
[ -n "$NAMING" ] || NAMING="strip"
[ -n "$ID_IN_BRANCH" ] || ID_IN_BRANCH=0

# --- names -------------------------------------------------------------------

if [ -n "$ID" ] && [ "$ID_IN_BRANCH" = "1" ]; then
  BRANCH="$TYPE/meegle-$ID-$SLUG"
elif [ -n "$ID" ]; then
  BRANCH="$TYPE/$ID-$SLUG"
else
  BRANCH="$TYPE/$SLUG"
fi

case "$NAMING" in
  full)  DIR_NAME="$BRANCH" ;;
  flat)  DIR_NAME="$(printf '%s' "$BRANCH" | tr '/' '-')" ;;
  *)     DIR_NAME="${BRANCH#*/}" ;;
esac
WORKTREE="$BASE_DIR/$DIR_NAME"

# --- base ref ----------------------------------------------------------------

if [ -z "$FROM" ]; then
  FROM="$(git -C "$MAIN" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
  [ -n "$FROM" ] || FROM="$(git -C "$MAIN" branch --list main master --format='%(refname:short)' | head -1 || true)"
  [ -n "$FROM" ] || FROM="HEAD"
fi
if [ "$DO_FETCH" = "1" ] && [ "$DRY_RUN" = "0" ]; then
  git -C "$MAIN" fetch --quiet origin "$FROM" 2>/dev/null && FROM="origin/$FROM"
fi
git -C "$MAIN" rev-parse --verify --quiet "$FROM^{commit}" >/dev/null || die "base ref '$FROM' does not resolve"
FROM_SHA="$(git -C "$MAIN" rev-parse --short "$FROM^{commit}")"

# --- report the plan ---------------------------------------------------------

echo "repo      $MAIN"
echo "layout    $BASE_DIR  (naming: $NAMING, id-in-branch: $ID_IN_BRANCH)"
echo "branch    $BRANCH"
echo "worktree  $WORKTREE"
echo "base      $FROM ($FROM_SHA)"
echo "runner    $RUNNER${RESOLVED_MODEL:+ (model: $RESOLVED_MODEL)}${EFFORT:+ (effort: $EFFORT)}${PERM_LABEL:+ (permissions: $PERM_LABEL)}"

if [ "$DRY_RUN" = "1" ]; then echo "dry-run   nothing created"; exit 0; fi

# Already there? Reuse it and continue so missing .env / install / tasks.json can be armed.
EXISTING_WORKTREE=0
if git -C "$MAIN" worktree list --porcelain | grep -qxF "worktree $WORKTREE"; then
  echo "status    already exists — reusing it"
  EXISTING_WORKTREE=1
else
  CHECKED_OUT_AT="$(existing_worktrees | awk -F'\t' -v b="$BRANCH" '$2 == b { print $1; exit }' || true)"
  if [ -n "$CHECKED_OUT_AT" ]; then
    echo "status    branch already checked out at $CHECKED_OUT_AT — use that worktree, nothing created"
    exit 0
  fi
  [ -e "$WORKTREE" ] && die "$WORKTREE exists but is not a registered worktree; remove it or pass --base"
fi

# --- create ------------------------------------------------------------------

if [ "$EXISTING_WORKTREE" = "0" ]; then
  mkdir -p "$BASE_DIR"
  if git -C "$MAIN" show-ref --quiet --verify "refs/heads/$BRANCH"; then
    add_output="$(git -C "$MAIN" worktree add "$WORKTREE" "$BRANCH" 2>&1)" \
      || { echo "$add_output" >&2; die "git worktree add failed"; }
    echo "status    created on the EXISTING branch $BRANCH"
  else
    add_output="$(git -C "$MAIN" worktree add -b "$BRANCH" "$WORKTREE" "$FROM" 2>&1)" \
      || { echo "$add_output" >&2; die "git worktree add failed"; }
    echo "status    created"
  fi
fi

# Persist what we learned, so the next run in this repo decides nothing. The
# naming answers are only worth caching when real worktrees taught them —
# otherwise they are this script's defaults and must stay open to re-detection.
if [ "$SAMPLES" -gt 0 ] || [ -n "$NAMING_OVERRIDE" ]; then
  printf 'BASE_DIR=%q\nNAMING=%q\nID_IN_BRANCH=%q\n' "$BASE_DIR" "$NAMING" "$ID_IN_BRANCH" > "$CONF"
else
  printf 'BASE_DIR=%q\n' "$BASE_DIR" > "$CONF"
fi

# --- ignored local config the worktree cannot inherit ------------------------

COPIED=""
while IFS= read -r envfile; do
  [ -f "$MAIN/$envfile" ] || continue
  git -C "$MAIN" check-ignore -q "$envfile" || continue   # tracked files come with the checkout
  cp "$MAIN/$envfile" "$WORKTREE/$envfile"
  COPIED="$COPIED $envfile"
done <<'ENVFILES'
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
ENVFILES
echo "env      ${COPIED:- none found}"

# --- dependencies ------------------------------------------------------------

INSTALL_LOG=""
if [ "$DO_INSTALL" = "1" ] && [ -f "$WORKTREE/package.json" ]; then
  # Check .package-lock.json so an empty node_modules/ or a SIGHUP-interrupted install is restarted.
  if [ ! -f "$WORKTREE/node_modules/.package-lock.json" ]; then
    INSTALL_LOG="$BASE_DIR/npm-install-${ID:-$SLUG}.log"
    # npm, never pnpm; npm install, never npm ci (see the moodio-agent note).
    # Start in a new session so closing the caller's shell does not SIGHUP npm install.
    python3 -c 'import subprocess, sys; subprocess.Popen(["npm", "install"], cwd=sys.argv[1], stdin=subprocess.DEVNULL, stdout=open(sys.argv[2], "w"), stderr=subprocess.STDOUT, start_new_session=True)' "$WORKTREE" "$INSTALL_LOG"
    echo "install   npm install started in the background -> $INSTALL_LOG"
  else
    echo "install   node_modules already populated"
  fi
elif [ -f "$WORKTREE/package.json" ]; then
  echo "install   skipped (--no-install); run 'npm install' before the dev server"
else
  echo "install   no package.json; install nothing"
fi

# --- the first session in the new window -------------------------------------
#
# VSCode has no way to be told "open this folder and run this prompt": the CLI
# has no --command, and the Claude extension registers no URI handler. The one
# hook that exists is a task with runOn: folderOpen, which VSCode runs in the
# integrated terminal the first time the folder is opened — after the user has
# allowed automatic tasks for it (or set task.allowAutomaticTasks to "on").
#
# The prompt lives in its own file so nothing has to be escaped into JSON, and
# the task consumes both files before starting the agent: this arms the FIRST
# open of a new worktree and leaves nothing behind in git status afterwards.
#
# The env scrub is what makes the session a fresh top-level session instead of
# attaching to the parent window's Antigravity LS/conversation or Claude child
# session markers.
if [ "$DO_AUTO_START" = "1" ] && [ ! -e "$WORKTREE/.vscode/tasks.json" ]; then
  mkdir -p "$WORKTREE/.vscode"
  ENTRY_CMD="/peter-delivery"
  [ "$RUNNER" = "codex" ] && ENTRY_CMD="\$peter-delivery"
  {
    echo "$ENTRY_CMD"
    echo
    echo "Task: ${TASK:-$(printf '%s' "$SLUG" | tr '-' ' ')}"
    [ -n "$ID_RAW" ] && echo "Meegle: $ID_RAW"
    echo "Branch: $BRANCH"
    echo "Worktree: $WORKTREE"
    [ -n "$INSTALL_LOG" ] && echo "Note: npm install is still running in the background ($INSTALL_LOG)."
    echo
    echo "First round only: read the requirement (pull the Meegle item if there is a link),"
    echo "find the code it touches, then write the scope ledger and three design bullets and"
    echo "STOP for Peter. Do not write code, do not commit, do not start the dev server."
  } > "$WORKTREE/.vscode/claude-task-prompt.txt"

  ENV_SCRUB="-u ANTIGRAVITY_AGENT -u ANTIGRAVITY_CONVERSATION_ID -u ANTIGRAVITY_TRAJECTORY_ID -u ANTIGRAVITY_LS_ADDRESS -u ANTIGRAVITY_CSRF_TOKEN -u ANTIGRAVITY_PROJECT_ID -u ANTIGRAVITY_SOURCE_METADATA -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_CODE_SESSION_ATTENDED -u CLAUDE_CODE_EXECPATH -u CLAUDECODE -u CLAUDE_PID -u CLAUDE_EFFORT"
  case "$RUNNER" in
    agy)
      EXEC_CMD="exec env $ENV_SCRUB agy${RUNNER_ARGS} -i \\\"\$P\\\""
      DISPLAY_CMD="agy${RUNNER_ARGS} -i \"<task prompt>\""
      ;;
    codex)
      EXEC_CMD="exec env $ENV_SCRUB codex${RUNNER_ARGS} \\\"\$P\\\""
      DISPLAY_CMD="codex${RUNNER_ARGS} \"<task prompt>\""
      ;;
    *)
      EXEC_CMD="exec env $ENV_SCRUB CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude${RUNNER_ARGS} \\\"\$P\\\""
      DISPLAY_CMD="claude${RUNNER_ARGS} \"<task prompt>\""
      ;;
  esac

  cat > "$WORKTREE/.vscode/tasks.json" <<TASKS
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "peter-delivery: start this task",
      "type": "shell",
      "command": "P=\"\$(cat .vscode/claude-task-prompt.txt)\"; rm -f .vscode/claude-task-prompt.txt .vscode/tasks.json; rmdir .vscode 2>/dev/null; $EXEC_CMD",
      "presentation": { "reveal": "always", "panel": "dedicated", "focus": true },
      "runOptions": { "runOn": "folderOpen" },
      "problemMatcher": []
    }
  ]
}
TASKS

  # Keep the trigger out of git status. A local exclude, not the repo's
  # .gitignore: this is one tool's scratch file, it lives for one window open,
  # and no repo should carry a line about it. info/exclude sits in the common
  # dir, so it covers the main checkout and every worktree at once.
  EXCLUDE="$COMMON_DIR/info/exclude"
  if ! grep -qxF '.vscode/claude-task-prompt.txt' "$EXCLUDE" 2>/dev/null; then
    mkdir -p "$(dirname "$EXCLUDE")"
    {
      echo ""
      echo "# one-shot session trigger written by peter-delivery append-worktree"
      echo ".vscode/claude-task-prompt.txt"
      echo ".vscode/tasks.json"
    } >> "$EXCLUDE"
  fi

  echo "auto-start armed: the window's first terminal runs: $DISPLAY_CMD"
  echo "          (one-shot: both files are git-excluded and delete themselves on run;"
  echo "           needs task.allowAutomaticTasks=\"on\", else one 'Allow Automatic Tasks in Folder')"
elif [ "$DO_AUTO_START" = "1" ]; then
  echo "auto-start not armed: .vscode/tasks.json already exists, left untouched"
else
  echo "auto-start off"
fi

# --- editor ------------------------------------------------------------------

if [ "$DO_OPEN" = "1" ] && command -v code >/dev/null 2>&1; then
  code "$WORKTREE" >/dev/null 2>&1 && echo "editor    opened in VS Code"
else
  echo "editor    not opened"
fi

echo "cd        cd $WORKTREE"
