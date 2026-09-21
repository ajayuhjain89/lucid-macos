#!/usr/bin/env bash
#
# install-git-guards.sh — opt-in installer for Lucid's local Git guards.
#
# Points this repository's local core.hooksPath at the tracked .githooks/
# directory so the pre-push branch-flow guard runs. The change is REPOSITORY
# LOCAL only (git config --local); global Git configuration is never touched.
#
# The installer is intentionally explicit and non-destructive: if a hooksPath
# or a legacy .git/hooks/pre-push is already configured to something else, it
# refuses to silently overwrite and tells you exactly what to do.
#
set -eu

HOOKS_DIR=".githooks"
TARGET_HOOK="$HOOKS_DIR/pre-push"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "install-git-guards: not inside a Git repository." >&2
  exit 1
fi
cd "$REPO_ROOT"

if [ ! -f "$TARGET_HOOK" ]; then
  echo "install-git-guards: $TARGET_HOOK not found in this repo." >&2
  exit 1
fi

echo "install-git-guards: repository = $REPO_ROOT"

# 1) Inspect any existing local hooksPath.
CURRENT_LOCAL="$(git config --local --get core.hooksPath 2>/dev/null || true)"
CURRENT_GLOBAL="$(git config --global --get core.hooksPath 2>/dev/null || true)"

if [ -n "$CURRENT_GLOBAL" ]; then
  echo "install-git-guards: note — a GLOBAL core.hooksPath is set: '$CURRENT_GLOBAL'." >&2
  echo "                    We will NOT modify global config. Setting a repo-local" >&2
  echo "                    core.hooksPath overrides it for THIS repo only." >&2
fi

if [ -n "$CURRENT_LOCAL" ] && [ "$CURRENT_LOCAL" != "$HOOKS_DIR" ]; then
  echo "install-git-guards: REFUSING to overwrite an existing local core.hooksPath." >&2
  echo "                    current: '$CURRENT_LOCAL'" >&2
  echo "                    desired: '$HOOKS_DIR'" >&2
  echo "                    Resolve manually, then re-run, or set it yourself:" >&2
  echo "                        git config --local core.hooksPath $HOOKS_DIR" >&2
  exit 1
fi

# 2) Warn about a legacy .git/hooks/pre-push that would be bypassed once
#    hooksPath is redirected (we do not delete the user's file).
LEGACY="$(git rev-parse --git-path hooks/pre-push 2>/dev/null || true)"
if [ -n "$LEGACY" ] && [ -f "$LEGACY" ]; then
  echo "install-git-guards: note — a legacy hook exists at $LEGACY." >&2
  echo "                    It will be bypassed once core.hooksPath -> $HOOKS_DIR." >&2
  echo "                    Left in place; remove it yourself if it is obsolete." >&2
fi

# 3) Make the tracked hook executable.
chmod +x "$TARGET_HOOK" 2>/dev/null || true

# 4) Configure repository-local hooksPath (idempotent).
if [ "$CURRENT_LOCAL" = "$HOOKS_DIR" ]; then
  echo "install-git-guards: core.hooksPath already = $HOOKS_DIR (no change)."
else
  git config --local core.hooksPath "$HOOKS_DIR"
  echo "install-git-guards: set local core.hooksPath = $HOOKS_DIR"
fi

echo ""
echo "install-git-guards: done. Verify with:"
echo "    git config --local --get core.hooksPath   # expect: $HOOKS_DIR"
echo ""
echo "The pre-push guard now blocks pushes that would introduce develop/main"
echo "ancestry into a permanent category branch (logic/design/docs)."
