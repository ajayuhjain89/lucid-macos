#!/usr/bin/env bash
#
# test-branch-flow-policy.sh — regression suite for the Lucid branch-flow guard.
#
# Every scenario is built in a throwaway synthetic Git repository under a temp
# directory. The REAL Lucid repository is never touched. The validator under
# test is scripts/validate-branch-ancestry.sh, resolved relative to this file.
#
# Run:  bash tests/test-branch-flow-policy.sh
# Exit: 0 if every scenario matches its expected result, 1 otherwise.
#
# Portable Bash (macOS Bash 3.2 and Ubuntu Bash 5). No Bash-4+ features.
#
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-branch-ancestry.sh"

if [ ! -f "$VALIDATOR" ]; then
  echo "cannot find validator at $VALIDATOR" >&2
  exit 2
fi

PASS_COUNT=0
FAIL_COUNT=0
ROWS=""

# Deterministic environment for synthetic repos.
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_EDITOR=true
export LUCID_DEV_REF=develop
export LUCID_MAIN_REF=main

# ---- helpers --------------------------------------------------------------

mkbase() {
  # Create a fresh repo with main + develop + logic/design/docs all rooted at
  # a common initial commit. Echo nothing; caller is already cd'd into $1.
  git -c init.defaultBranch=main init -q .
  git config commit.gpgsign false
  echo root > README.md
  git add README.md
  git commit -qm "root"
  git branch develop
  git branch logic
  git branch design
  git branch docs
}

commit_on() {
  # commit_on <branch> <file> <message>
  git checkout -q "$1"
  printf '%s\n' "$3" > "$2"
  git add "$2"
  git commit -qm "$3"
}

validate() { bash "$VALIDATOR" "$@"; }

# run_case <name> <expected PASS|FAIL> <scenario-fn>
# The scenario function runs in its own temp dir + subshell and its final
# command's exit status is the validator result being tested.
run_case() {
  _name="$1"; _expected="$2"; _fn="$3"
  _dir="$(mktemp -d 2>/dev/null || mktemp -d -t lucidbf)"
  if ( cd "$_dir" && "$_fn" ) >"$_dir/.log" 2>&1; then
    _actual="PASS"
  else
    _actual="FAIL"
  fi
  if [ "$_actual" = "$_expected" ]; then
    _mark="ok  "
    PASS_COUNT=$((PASS_COUNT+1))
  else
    _mark="FAIL"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
  ROWS="$ROWS
$(printf '%-4s | %-58s | %-8s | %-8s' "$_mark" "$_name" "$_expected" "$_actual")"
  if [ "$_actual" != "$_expected" ]; then
    echo "---- unexpected result for: $_name ----" >&2
    sed 's/^/    /' "$_dir/.log" >&2
    echo "----------------------------------------" >&2
  fi
  rm -rf "$_dir"
}

# ---- scenarios ------------------------------------------------------------

t01_logic_direct() {            # valid logic direct commit -> PASS
  mkbase
  OLD="$(git rev-parse logic)"
  commit_on logic logic.txt "logic feature"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t02_docs_direct() {             # valid docs direct commit -> PASS
  mkbase
  OLD="$(git rev-parse docs)"
  commit_on docs docs.txt "docs update"
  NEW="$(git rev-parse docs)"
  validate --transition --branch docs --old "$OLD" --new "$NEW"
}

t03_design_direct() {           # valid design direct commit -> PASS
  mkbase
  OLD="$(git rev-parse design)"
  commit_on design design.txt "design polish"
  NEW="$(git rev-parse design)"
  validate --transition --branch design --old "$OLD" --new "$NEW"
}

t04_develop_into_logic() {      # develop -> logic merge -> FAIL
  mkbase
  commit_on develop dev.txt "develop work"
  OLD="$(git rev-parse logic)"
  git checkout -q logic
  git merge -q --no-ff develop -m "BAD: develop into logic"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t05_develop_into_docs() {       # develop -> docs merge -> FAIL
  mkbase
  commit_on develop dev.txt "develop work"
  OLD="$(git rev-parse docs)"
  git checkout -q docs
  git merge -q --no-ff develop -m "BAD: develop into docs"
  NEW="$(git rev-parse docs)"
  validate --transition --branch docs --old "$OLD" --new "$NEW"
}

t06_develop_into_design() {     # develop -> design merge -> FAIL
  mkbase
  commit_on develop dev.txt "develop work"
  OLD="$(git rev-parse design)"
  git checkout -q design
  git merge -q --no-ff develop -m "BAD: develop into design"
  NEW="$(git rev-parse design)"
  validate --transition --branch design --old "$OLD" --new "$NEW"
}

t07_main_into_logic() {         # main -> logic merge -> FAIL
  mkbase
  commit_on main main.txt "main work"
  OLD="$(git rev-parse logic)"
  git checkout -q logic
  git merge -q --no-ff main -m "BAD: main into logic"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t08_main_into_docs() {          # main -> docs merge -> FAIL
  mkbase
  commit_on main main.txt "main work"
  OLD="$(git rev-parse docs)"
  git checkout -q docs
  git merge -q --no-ff main -m "BAD: main into docs"
  NEW="$(git rev-parse docs)"
  validate --transition --branch docs --old "$OLD" --new "$NEW"
}

t09_main_into_design() {        # main -> design merge -> FAIL
  mkbase
  commit_on main main.txt "main work"
  OLD="$(git rev-parse design)"
  git checkout -q design
  git merge -q --no-ff main -m "BAD: main into design"
  NEW="$(git rev-parse design)"
  validate --transition --branch design --old "$OLD" --new "$NEW"
}

t10_legit_temp_into_logic() {   # clean temp branch -> logic -> PASS
  mkbase
  commit_on logic logic.txt "logic base"
  git checkout -q -b experiment/spike logic
  echo spike > spike.txt; git add spike.txt; git commit -qm "spike work"
  OLD="$(git rev-parse logic)"
  git checkout -q logic
  git merge -q --no-ff experiment/spike -m "merge clean temp into logic"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t11_contaminated_temp_into_logic() {  # temp tainted by develop -> logic -> FAIL
  mkbase
  commit_on develop dev.txt "develop work"
  git checkout -q -b experiment/bad logic
  git merge -q --no-ff develop -m "temp pulls develop (contamination)"
  echo x > x.txt; git add x.txt; git commit -qm "temp work"
  OLD="$(git rev-parse logic)"
  git checkout -q logic
  git merge -q --no-ff experiment/bad -m "merge contaminated temp into logic"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t12_historical_violation_baseline() { # bad ancestry in OLD, clean NEW -> PASS
  mkbase
  commit_on develop dev.txt "develop work"
  git checkout -q logic
  git merge -q --no-ff develop -m "historical bad merge (pre-baseline)"
  OLD="$(git rev-parse logic)"           # baseline already contains the taint
  echo clean > clean.txt; git add clean.txt; git commit -qm "clean logic work"
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t13_ff_integration_ancestry() { # logic fast-forwarded onto develop -> FAIL
  mkbase
  commit_on develop dev.txt "develop work"
  OLD="$(git rev-parse logic)"
  git checkout -q logic
  git merge -q --ff-only develop           # logic now == develop tip
  NEW="$(git rev-parse logic)"
  validate --transition --branch logic --old "$OLD" --new "$NEW"
}

t14_pr_logic_develop() {        # logic -> develop PR -> PASS
  mkbase
  commit_on logic logic.txt "logic feature"
  H="$(git rev-parse logic)"; B="$(git rev-parse develop)"
  validate --pr --head "$H" --base "$B" --head-branch logic --base-branch develop
}

t15_pr_design_develop() {       # design -> develop PR -> PASS
  mkbase
  commit_on design design.txt "design work"
  H="$(git rev-parse design)"; B="$(git rev-parse develop)"
  validate --pr --head "$H" --base "$B" --head-branch design --base-branch develop
}

t16_pr_docs_develop() {         # docs -> develop PR -> PASS
  mkbase
  commit_on docs docs.txt "docs work"
  H="$(git rev-parse docs)"; B="$(git rev-parse develop)"
  validate --pr --head "$H" --base "$B" --head-branch docs --base-branch develop
}

t17_pr_develop_main() {         # develop -> main PR -> PASS
  mkbase
  commit_on logic logic.txt "logic feature"
  git checkout -q develop
  git merge -q --no-ff logic -m "Merge logic into develop"
  H="$(git rev-parse develop)"; B="$(git rev-parse main)"
  validate --pr --head "$H" --base "$B" --head-branch develop --base-branch main
}

t18_pr_develop_docs() {         # develop -> docs PR -> FAIL (direction)
  mkbase
  H="$(git rev-parse develop)"; B="$(git rev-parse docs)"
  validate --pr --head "$H" --base "$B" --head-branch develop --base-branch docs
}

t19_pr_main_logic() {           # main -> logic PR -> FAIL (direction)
  mkbase
  H="$(git rev-parse main)"; B="$(git rev-parse logic)"
  validate --pr --head "$H" --base "$B" --head-branch main --base-branch logic
}

t20_pr_logic_main() {           # logic -> main PR -> FAIL (direction)
  mkbase
  H="$(git rev-parse logic)"; B="$(git rev-parse main)"
  validate --pr --head "$H" --base "$B" --head-branch logic --base-branch main
}

t21_cherrypick_limitation() {
  # Cherry-pick limitation demonstration. develop has A; docs gets A' via
  # cherry-pick. We SHOW the boundary rather than pretend detection exists:
  #   * A and A' have different SHAs
  #   * A is NOT an ancestor of docs (no topological link)
  #   * therefore the transition guard does NOT flag the cherry-pick (PASS)
  # This scenario "passes" by confirming the documented limitation holds.
  mkbase
  commit_on develop feature.txt "A: shared feature"
  A="$(git rev-parse develop)"
  OLD="$(git rev-parse docs)"
  git checkout -q docs
  git cherry-pick -q "$A"                    # creates A'
  APRIME="$(git rev-parse docs)"
  NEW="$APRIME"

  # Assertion 1: different objects.
  if [ "$A" = "$APRIME" ]; then
    echo "cherry-pick produced identical SHA — unexpected" >&2
    return 1
  fi
  # Assertion 2: no ancestry link from A into docs.
  if git merge-base --is-ancestor "$A" docs 2>/dev/null; then
    echo "A unexpectedly reachable from docs" >&2
    return 1
  fi
  # Assertion 3: transition guard cannot see the content sync -> reports PASS.
  if validate --transition --branch docs --old "$OLD" --new "$NEW" >/dev/null 2>&1; then
    echo "documented limitation confirmed: ancestry cannot prove cherry-pick provenance"
    echo "  A =$A"
    echo "  A'=$APRIME"
    return 0
  fi
  echo "guard unexpectedly flagged a cherry-pick (would be false provenance claim)" >&2
  return 1
}

# ---- run matrix -----------------------------------------------------------

echo "Lucid branch-flow policy — regression suite"
echo "validator: $VALIDATOR"
echo ""

run_case "01 valid logic direct commit"                         PASS t01_logic_direct
run_case "02 valid docs direct commit"                          PASS t02_docs_direct
run_case "03 valid design direct commit"                        PASS t03_design_direct
run_case "04 develop -> logic merge"                            FAIL t04_develop_into_logic
run_case "05 develop -> docs merge"                             FAIL t05_develop_into_docs
run_case "06 develop -> design merge"                           FAIL t06_develop_into_design
run_case "07 main -> logic merge"                               FAIL t07_main_into_logic
run_case "08 main -> docs merge"                                FAIL t08_main_into_docs
run_case "09 main -> design merge"                              FAIL t09_main_into_design
run_case "10 clean temp branch -> logic"                        PASS t10_legit_temp_into_logic
run_case "11 develop-contaminated temp -> logic"               FAIL t11_contaminated_temp_into_logic
run_case "12 historical violation in baseline, clean new"       PASS t12_historical_violation_baseline
run_case "13 category fast-forward onto develop (transition)"  FAIL t13_ff_integration_ancestry
run_case "14 PR logic -> develop"                               PASS t14_pr_logic_develop
run_case "15 PR design -> develop"                              PASS t15_pr_design_develop
run_case "16 PR docs -> develop"                                PASS t16_pr_docs_develop
run_case "17 PR develop -> main"                                PASS t17_pr_develop_main
run_case "18 PR develop -> docs"                                FAIL t18_pr_develop_docs
run_case "19 PR main -> logic"                                  FAIL t19_pr_main_logic
run_case "20 PR logic -> main"                                  FAIL t20_pr_logic_main
run_case "21 cherry-pick limitation demonstration"             PASS t21_cherrypick_limitation

echo "Result | Scenario                                                   | Expected | Actual"
echo "-------+------------------------------------------------------------+----------+--------"
printf '%s\n' "$ROWS" | sed '/^$/d'
echo ""
echo "Passed: $PASS_COUNT   Failed: $FAIL_COUNT"

[ "$FAIL_COUNT" = "0" ]
