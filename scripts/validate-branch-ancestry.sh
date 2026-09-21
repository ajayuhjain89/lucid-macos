#!/usr/bin/env bash
#
# validate-branch-ancestry.sh — Lucid permanent branch-flow guard.
#
# Portable Bash, compatible with macOS (Bash 3.2, the system /bin/bash) and the
# GitHub Ubuntu runners (Bash 5). No Bash-4+ features are used: no associative
# arrays, no `mapfile`, no `${var,,}` — everything works under Bash 3.2.
#
# Lucid has exactly five permanent branches:
#
#     logic  design  docs   ->  develop  ->  main
#
# The ONLY allowed permanent-branch flow is unidirectional:
#
#     logic   -> develop
#     design  -> develop
#     docs    -> develop
#     develop -> main
#
# Permanent category branches (logic/design/docs) are intentionally allowed to
# be many commits BEHIND develop/main. That is normal and expected. They must
# NEVER be synchronised from develop or main (no develop->category merge, no
# main->category merge, no back-merge of integration content).
#
# This script is the shared validator used by:
#   * .githooks/pre-push            (Mode 1: --transition, local ref movement)
#   * .github/workflows/branch-flow.yml (Mode 2: --pr, server-side PR gate)
#   * humans, for diagnostics       (Mode 3: --audit-history)
#
# ---------------------------------------------------------------------------
# HONEST LIMITATIONS (documented in docs/github_workflow.md):
#
#   * This validator reasons about GIT TOPOLOGY (ancestry / merge parents).
#     It CANNOT detect a cherry-pick: if develop has commit A and someone
#     cherry-picks it onto docs as A', A' is a brand-new object with no
#     ancestry link to A. Cherry-picking develop/main commits back into a
#     category branch as a synchronisation mechanism is forbidden by POLICY,
#     not by this script.
#
#   * PR mode inspects BASE..HEAD. It cannot reconstruct a category branch's
#     prior ref movements. If a category branch was fast-forwarded to develop
#     BEFORE a PR was opened, BASE..HEAD may not reveal that transition. That
#     is exactly why the local --transition pre-push guard exists.
#
# Reference resolution can be overridden for testing via environment:
#   LUCID_DEV_REF   (default: origin/develop, else develop)
#   LUCID_MAIN_REF  (default: origin/main,    else main)
#
set -u

# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------

PROG="validate-branch-ancestry.sh"

err()  { printf '%s\n' "$*" >&2; }
die()  { err "ERROR: $*"; exit 2; }

# Resolve a ref to a commit SHA, or print nothing on failure.
resolve() {
  git rev-parse --verify --quiet "$1^{commit}" 2>/dev/null
}

# Try origin/<name> first, then <name>. Prints the SHA that exists, or nothing.
resolve_branch() {
  _rb_name="$1"
  _rb_sha="$(resolve "origin/$_rb_name")"
  if [ -n "$_rb_sha" ]; then printf '%s\n' "$_rb_sha"; return 0; fi
  _rb_sha="$(resolve "$_rb_name")"
  if [ -n "$_rb_sha" ]; then printf '%s\n' "$_rb_sha"; return 0; fi
  return 1
}

# is_ancestor <maybe-ancestor> <descendant> -> exit 0 if ancestor
is_ancestor() {
  git merge-base --is-ancestor "$1" "$2" 2>/dev/null
}

# Is $1 one of the category branch names?
is_category_branch() {
  case "$1" in
    logic|design|docs) return 0 ;;
    *) return 1 ;;
  esac
}

# Is $1 a recognised temporary branch name?
# hotfix/* is included: even an urgent fix must fold into a category branch and
# flow forward (category -> develop -> main). There is NO direct path to main
# other than develop.
is_temp_branch() {
  case "$1" in
    experiment/*|prototype/*|migration/*|refactor/*|hotfix/*) return 0 ;;
    *) return 1 ;;
  esac
}

short() { git rev-parse --short "$1" 2>/dev/null || printf '%s' "$1"; }

# --------------------------------------------------------------------------
# Resolve the forbidden upstream references (develop / main)
# --------------------------------------------------------------------------

DEV_REF="${LUCID_DEV_REF:-}"
MAIN_REF="${LUCID_MAIN_REF:-}"

resolve_upstreams() {
  if [ -z "$DEV_REF" ];  then DEV_REF="$(resolve_branch develop || true)"; fi
  if [ -z "$MAIN_REF" ]; then MAIN_REF="$(resolve_branch main    || true)"; fi
  # It is not fatal for one to be missing (e.g. a fresh clone), but we warn:
  if [ -z "$DEV_REF" ] && [ -z "$MAIN_REF" ]; then
    err "WARNING: could not resolve develop or main; ancestry checks are limited."
  fi
}

# Emit the standard human explanation of the branch-flow rule for a category
# branch, naming the offending commit(s).
explain_category_violation() {
  _ecv_branch="$1"; shift
  err ""
  err "  Lucid branch-flow violation detected."
  err ""
  err "  You are attempting to introduce integration ancestry into permanent"
  err "  category branch \`$_ecv_branch\`."
  err ""
  err "  Allowed direction:"
  err "      $_ecv_branch -> develop -> main"
  err ""
  err "  Forbidden:"
  err "      develop -> $_ecv_branch"
  err "      main    -> $_ecv_branch"
  err ""
  err "  Category branches are intentionally allowed to remain behind develop"
  err "  and main. Do NOT synchronise \`$_ecv_branch\` from develop or main."
  err ""
  if [ "$#" -gt 0 ]; then
    err "  Offending commit(s):"
    for _c in "$@"; do
      err "      $(short "$_c")  $(git log -1 --format='%s' "$_c" 2>/dev/null)"
    done
    err ""
  fi
}

# ==========================================================================
# MODE 1 — TRANSITION
#
#   --transition --branch <logic|design|docs> --old <sha> --new <sha>
#
# Validates an actual category ref movement OLD -> NEW. Only commits newly
# introduced by the movement (OLD..NEW) are examined; historical ancestry
# already present in OLD never causes a failure. A movement is forbidden if it
# newly introduces any commit that is contained in develop or main (i.e. a
# backward merge, a fast-forward onto an integration branch, or a contaminated
# temporary-branch merge).
# ==========================================================================

mode_transition() {
  _t_branch=""; _t_old=""; _t_new=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --branch) _t_branch="$2"; shift 2 ;;
      --old)    _t_old="$2";    shift 2 ;;
      --new)    _t_new="$2";    shift 2 ;;
      *) die "unknown --transition argument: $1" ;;
    esac
  done

  [ -n "$_t_branch" ] || die "--transition requires --branch"
  [ -n "$_t_new" ]    || die "--transition requires --new"

  if ! is_category_branch "$_t_branch"; then
    # Only category branches are guarded in transition mode. Movements of
    # develop/main are governed by PR review + protections, not this hook.
    echo "[$PROG] transition: '$_t_branch' is not a guarded category branch; skipping."
    return 0
  fi

  resolve_upstreams

  _t_new_sha="$(resolve "$_t_new")" || die "cannot resolve --new '$_t_new'"

  # New-branch creation (all-zero old) — examine the whole branch tip's unique
  # commits relative to the integration branches instead of a range.
  _zero='0000000000000000000000000000000000000000'
  if [ -z "$_t_old" ] || [ "$_t_old" = "$_zero" ]; then
    _t_range="$_t_new_sha"
    _t_old_sha=""
  else
    _t_old_sha="$(resolve "$_t_old")" || die "cannot resolve --old '$_t_old'"
    _t_range="$_t_old_sha..$_t_new_sha"
  fi

  # Collect commits introduced by this movement.
  _t_commits="$(git rev-list "$_t_range" 2>/dev/null || true)"
  if [ -z "$_t_commits" ]; then
    echo "[$PROG] transition: no new commits ($_t_range); allowed."
    return 0
  fi

  _t_bad=""
  for _c in $_t_commits; do
    _tainted=0
    if [ -n "$DEV_REF" ]  && is_ancestor "$_c" "$DEV_REF";  then _tainted=1; fi
    if [ -n "$MAIN_REF" ] && is_ancestor "$_c" "$MAIN_REF"; then _tainted=1; fi
    # On branch creation there is no OLD baseline; a category branch newly
    # created from develop/main would be entirely tainted, which is correct.
    if [ "$_tainted" = "1" ]; then
      _t_bad="$_t_bad $_c"
    fi
  done

  if [ -n "$_t_bad" ]; then
    explain_category_violation "$_t_branch" $_t_bad
    err "[$PROG] transition FAILED for '$_t_branch'."
    return 1
  fi

  echo "[$PROG] transition OK: '$_t_branch' introduces no develop/main ancestry."
  return 0
}

# ==========================================================================
# MODE 2 — PR
#
#   --pr --head <sha/ref> --base <sha/ref> \
#        --head-branch <branch> --base-branch <branch>
#
# Validates a pull request. Two layers:
#   (a) direction: the source->target pair must be an allowed permanent flow
#       (or a documented temporary-branch intake into a category branch);
#   (b) ancestry: for a HEAD that must stay "ahead only" of integration
#       branches, reject any merge commit unique to the PR (BASE..HEAD) whose
#       parent pulls in develop/main content newer than the fork point.
# ==========================================================================

# Given a HEAD branch, echo the space-separated set of refs whose content must
# NOT flow backward into it.
forbidden_refs_for_head() {
  _fr_head="$1"
  if is_category_branch "$_fr_head"; then
    printf '%s %s' "$DEV_REF" "$MAIN_REF"
  elif [ "$_fr_head" = "develop" ]; then
    printf '%s' "$MAIN_REF"
  elif is_temp_branch "$_fr_head"; then
    # A temp branch folded into a category branch must also be clean.
    printf '%s %s' "$DEV_REF" "$MAIN_REF"
  else
    printf ''
  fi
}

check_pr_direction() {
  _d_head="$1"; _d_base="$2"
  case "$_d_base" in
    develop)
      is_category_branch "$_d_head" && return 0
      return 1 ;;
    main)
      # develop is the ONLY branch that may merge into main.
      [ "$_d_head" = "develop" ] && return 0
      return 1 ;;
    logic|design|docs)
      is_temp_branch "$_d_head" && return 0
      return 1 ;;
    *)
      return 1 ;;
  esac
}

print_allowed_directions() {
  err "  Allowed PR directions:"
  err "      logic   -> develop"
  err "      design  -> develop"
  err "      docs    -> develop"
  err "      develop -> main   (the ONLY path into main)"
  err "      experiment/* | prototype/* | migration/* | refactor/* | hotfix/*  -> logic | design | docs"
}

mode_pr() {
  _p_head=""; _p_base=""; _p_head_branch=""; _p_base_branch=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --head)        _p_head="$2";        shift 2 ;;
      --base)        _p_base="$2";        shift 2 ;;
      --head-branch) _p_head_branch="$2"; shift 2 ;;
      --base-branch) _p_base_branch="$2"; shift 2 ;;
      *) die "unknown --pr argument: $1" ;;
    esac
  done

  [ -n "$_p_head_branch" ] || die "--pr requires --head-branch"
  [ -n "$_p_base_branch" ] || die "--pr requires --base-branch"

  resolve_upstreams

  echo "[$PROG] PR: $_p_head_branch -> $_p_base_branch"

  # ---- Layer (a): direction -------------------------------------------------
  if ! check_pr_direction "$_p_head_branch" "$_p_base_branch"; then
    err ""
    err "  Disallowed PR direction: '$_p_head_branch' -> '$_p_base_branch'."
    err ""
    print_allowed_directions
    err ""
    err "  Never allowed: develop->category, main->category, category->main,"
    err "  or category->category. Being behind is normal; do not 'sync' backward."
    err ""
    return 1
  fi
  echo "[$PROG] direction OK."

  # ---- Layer (b): ancestry --------------------------------------------------
  # Resolve endpoints. Prefer explicit --head/--base SHAs; fall back to branch
  # names so the workflow can pass either.
  _p_head_sha="$_p_head"; [ -n "$_p_head_sha" ] || _p_head_sha="$_p_head_branch"
  _p_base_sha="$_p_base"; [ -n "$_p_base_sha" ] || _p_base_sha="$_p_base_branch"
  _p_head_sha="$(resolve "$_p_head_sha")" || die "cannot resolve head '$_p_head'"
  _p_base_sha="$(resolve "$_p_base_sha")" || die "cannot resolve base '$_p_base'"

  _forbidden="$(forbidden_refs_for_head "$_p_head_branch")"
  if [ -z "$_forbidden" ]; then
    echo "[$PROG] ancestry: no forbidden upstreams for '$_p_head_branch'; direction check suffices."
    return 0
  fi

  _mb="$(git merge-base "$_p_base_sha" "$_p_head_sha" 2>/dev/null || true)"

  # Inspect every merge commit unique to the PR (BASE..HEAD). A backward merge
  # is one whose parent pulls in forbidden-ref content newer than the fork.
  _merges="$(git rev-list --merges "$_p_base_sha..$_p_head_sha" 2>/dev/null || true)"
  _bad=""
  for _m in $_merges; do
    # Parents of this merge commit.
    _parents="$(git rev-list --parents -n 1 "$_m" 2>/dev/null | cut -d' ' -f2-)"
    for _par in $_parents; do
      for _fb in $_forbidden; do
        [ -n "$_fb" ] || continue
        if is_ancestor "$_par" "$_fb"; then
          # Ignore shared history at/behind the fork point.
          if [ -n "$_mb" ] && is_ancestor "$_par" "$_mb"; then
            continue
          fi
          _bad="$_bad $_m"
          break 2
        fi
      done
    done
  done

  if [ -n "$_bad" ]; then
    err ""
    err "  Lucid branch-flow violation: PR '$_p_head_branch' -> '$_p_base_branch'"
    err "  contains backward integration merge(s) pulling develop/main content"
    err "  into '$_p_head_branch'. Category/integration branches must only move"
    err "  FORWARD. Do not merge develop or main backward."
    err ""
    err "  Offending merge commit(s):"
    for _m in $_bad; do
      err "      $(short "$_m")  $(git log -1 --format='%s' "$_m" 2>/dev/null)"
    done
    err ""
    return 1
  fi

  echo "[$PROG] ancestry OK: no backward integration merges in $_p_base_branch..$_p_head_branch."
  return 0
}

# ==========================================================================
# MODE 3 — AUDIT
#
#   --audit-history
#
# Manual diagnostics over the active permanent refs. Reports whether any
# category branch improperly contains the develop or main tip as an ancestor,
# and whether the two known v1.0.2-incident commits are reachable from any
# permanent ref. Intentionally cheap: it does not walk whole history.
# ==========================================================================

mode_audit() {
  resolve_upstreams
  _rc=0

  echo "== Lucid branch-flow audit =="
  echo "develop tip: ${DEV_REF:-<unresolved>}"
  echo "main tip:    ${MAIN_REF:-<unresolved>}"
  echo ""

  for _cat in logic design docs; do
    _cat_sha="$(resolve_branch "$_cat" || true)"
    if [ -z "$_cat_sha" ]; then
      echo "  $_cat: <not found>"
      continue
    fi
    _flag="OK (behind is normal)"
    if [ -n "$DEV_REF" ] && is_ancestor "$DEV_REF" "$_cat_sha"; then
      _flag="VIOLATION: contains develop tip"; _rc=1
    fi
    if [ -n "$MAIN_REF" ] && is_ancestor "$MAIN_REF" "$_cat_sha"; then
      _flag="VIOLATION: contains main tip"; _rc=1
    fi
    _behind_dev="?"
    if [ -n "$DEV_REF" ]; then
      _behind_dev="$(git rev-list --count "$_cat_sha..$DEV_REF" 2>/dev/null || echo '?')"
    fi
    echo "  $_cat: $(short "$_cat_sha")  behind develop by ${_behind_dev}  -> $_flag"
  done

  echo ""
  echo "-- known v1.0.2-incident commits (must be unreachable from permanent refs) --"
  for _bad in 34259a5f04ef5e7d33d58e97e3c2f3ab23ced581 \
              43c0cc0d71edabed162029ae2fa7acaa1c08b1ab; do
    if ! git cat-file -e "$_bad" 2>/dev/null; then
      echo "  $_bad: absent from object store — OK"
      continue
    fi
    _br="$(git branch -a --contains "$_bad" 2>/dev/null | tr -d ' *' | tr '\n' ',' )"
    _tg="$(git tag --contains "$_bad" 2>/dev/null | tr '\n' ',')"
    if [ -n "$_br" ] || [ -n "$_tg" ]; then
      echo "  $_bad: REACHABLE branches=[$_br] tags=[$_tg] — VIOLATION"; _rc=1
    else
      echo "  $_bad: present as loose object but unreachable (0 branches, 0 tags) — OK"
    fi
  done

  echo ""
  if [ "$_rc" = "0" ]; then
    echo "AUDIT RESULT: clean."
  else
    echo "AUDIT RESULT: violations found (see above)."
  fi
  return "$_rc"
}

# --------------------------------------------------------------------------
# Dispatch
# --------------------------------------------------------------------------

usage() {
  cat >&2 <<EOF
$PROG — Lucid permanent branch-flow guard

Usage:
  $PROG --transition --branch <logic|design|docs> --old <sha> --new <sha>
  $PROG --pr --head <sha> --base <sha> --head-branch <b> --base-branch <b>
  $PROG --audit-history

Environment overrides (mainly for tests):
  LUCID_DEV_REF   reference used as 'develop' (default origin/develop|develop)
  LUCID_MAIN_REF  reference used as 'main'    (default origin/main|main)
EOF
}

main() {
  [ "$#" -ge 1 ] || { usage; exit 2; }
  _cmd="$1"; shift
  case "$_cmd" in
    --transition)     mode_transition "$@" ;;
    --pr)             mode_pr "$@" ;;
    --audit-history)  mode_audit "$@" ;;
    -h|--help)        usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
}

main "$@"
