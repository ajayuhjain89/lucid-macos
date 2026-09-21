# Lucid — Git & GitHub Workflow

This is the canonical, authoritative description of how work flows through the
Lucid repository. Every contributor — human or coding agent — should be able to
read this file and understand the complete process without asking anyone.

If the workflow itself changes, **update this file in the same change.**

> **TL;DR** — Work flows one way only:
> `logic | design | docs → develop → main`.
> Category branches are **intentionally allowed to be behind** develop/main.
> **Never** merge, pull, or cherry-pick develop/main *back* into a category
> branch to "catch up." Being behind is normal, not a problem to fix.

---

## 1. Mental model

Lucid separates work into three **categories** — **logic**, **design**, and
**docs** — but does **not** create a new branch for every task. Ordinary work
happens **directly on the category branch**, then flows forward through
integration:

```
logic  ┐
design ├─→ develop ─→ main
docs   ┘
```

The goals:

- `main` is always a stable, verified, releasable state.
- `develop` is an integration gate that catches interactions between categories.
- Each category branch is a clean, always-usable line of its kind of work.
- **No branch proliferation.** Category separation without a branch per task.
- **Strictly unidirectional.** Content only ever moves forward.

---

## 2. Permanent branches

Exactly five long-lived branches. **None of them is ever deleted or rewritten.**

| Branch    | Role | Receives from | Promotes to |
| :-------- | :--- | :------------ | :---------- |
| `main`    | Stable, verified, releasable product | `develop` | — |
| `develop` | Integration gate for verified category work | `logic`, `design`, `docs` | `main` |
| `logic`   | All engineering / functionality work | worked on directly (+ accepted temporary branches) | `develop` |
| `design`  | All UI / UX / visual work | worked on directly (+ accepted temporary branches) | `develop` |
| `docs`    | All documentation work | worked on directly (+ accepted temporary branches) | `develop` |

**What belongs where**

- **logic** — Swift, AppKit, SwiftUI, architecture, renderer engineering,
  Editor/Reader behavior, Markdown rendering, WebEngine, Mermaid, KaTeX,
  performance, concurrency, commands, shortcuts, file handling, bugs, refactors,
  tests, **build/release engineering, CI/workflow engineering**, technical
  website plumbing.
- **design** — toolbar/sidebar visuals, typography, spacing, themes, icons,
  Reader/Settings appearance, interaction visual polish, branding, website
  visual design, screenshots/assets.
- **docs** — README, user/architecture/contributor docs, this workflow doc,
  release notes, changelog documentation, website documentation content.

---

## 3. Normal workflow — no task branches

For ordinary work, **do not create a new branch.** Decide whether the task is
logic, design, or docs, and work directly on that category branch. Always update
the branch with a **fast-forward-only** pull so you never accidentally create a
merge from a stale remote state.

### logic

```bash
git checkout logic
git pull --ff-only origin logic
# …implement + verify…
git add <reviewed files>
git commit -m "perf: optimize large-document rendering"
git push origin logic
# then open a PR:  logic → develop
```

### design

```bash
git checkout design
git pull --ff-only origin design
# …visual work + verify across Dark/Light/Sepia, Reader/Editor/Split…
git add <reviewed files>
git commit -m "design: refine glass toolbar"
git push origin design
# then open a PR:  design → develop
```

### docs

```bash
git checkout docs
git pull --ff-only origin docs
# …documentation work…
git add <reviewed files>
git commit -m "docs: document the branch-flow guard"
git push origin docs
# then open a PR:  docs → develop
```

Integration and promotion happen through pull requests:

- **`logic | design | docs → develop`** — integration verification.
- **`develop → main`** — final promotion, at a release.

Both are **real merge commits** (never fast-forwarded), preserving the two-lane
history. Do **not** create branches like `logic/large-document-performance`,
`design/top-bar`, `feature/foo`, `fix/bar` for normal work.

---

## 4. Being Behind Is Normal

**This is the single most important invariant in this document.**

A permanent category branch (`logic`, `design`, `docs`) is **not** a mirror of
`develop` or `main`. It is expected — and completely healthy — for a category
branch to be **many commits behind** develop or main.

- `logic is 41 commits behind develop` — **normal.**
- `docs is 70 commits behind main` — **normal.**
- `design is 50 commits behind main` — **normal.**

The GitHub "N commits behind" number is **informational only.** It does not mean
the branch is broken, stale in a bad way, or in need of repair.

### Why being behind is correct

Work flows **forward**: a category branch contributes its commits into
`develop`, and `develop` promotes to `main`. The category branch does **not**
receive anything back. So the moment other categories merge into `develop`, every
other category branch is "behind" — by construction. That is the design working
as intended, not a defect.

### What you must NOT do about it

- **Do not** merge `develop` or `main` into a category branch to reduce the
  "behind" count.
- **Do not** cherry-pick develop/main commits into a category branch to "sync."
- **Do not** reset or fast-forward a category branch onto develop/main.

Reducing the "behind" number by pulling integration history backward is exactly
the mistake that caused the v1.0.2 incident (see §9). **Leave category branches
behind. Contribute forward instead.**

---

## 5. Forbidden vs. correct commands

### Forbidden — backward synchronization

While on **any** category branch (`logic`, `design`, `docs`):

```bash
# ALL FORBIDDEN — these pull integration history backward into a category branch
git merge develop
git merge main
git pull origin develop
git pull origin main
git reset --hard origin/develop
git reset --hard origin/main
git cherry-pick <a-develop-or-main-commit>   # hidden backward sync — forbidden
```

Also forbidden on **any** permanent branch, as routine practice:

```bash
git push --force
git push --force-with-lease        # not for ordinary work
git rebase <published-history>
git commit --amend <published-commit>
git tag -f <moved-tag>             # tag movement
```

### Correct — same-branch update, then contribute forward

```bash
# Update the branch you are ON (fast-forward only — never a back-merge):
git pull --ff-only origin logic     # or design / docs / develop / main

# Contribute forward via PR:
#   logic  → develop
#   design → develop
#   docs   → develop
#   develop → main
```

If `git pull --ff-only` fails, it means your local branch and the remote have
diverged. **Do not** resolve that by merging develop/main in. Investigate why
the category branch diverged (usually an accidental local commit), and fix it on
the category branch itself.

---

## 6. `develop` — the integration gate

`develop` exists to catch interactions between individually-verified categories.

```bash
git checkout develop
git pull --ff-only origin develop
```

- **Never** implement category work directly on `develop`.
- Accepted category PRs merge **into** `develop` (`logic|design|docs → develop`).
- After integrated verification, `develop` promotes to `main` via a PR.
- `develop` is **never** merged back into a category branch.

---

## 7. `main` — final stable

`main` is the final, stable, releasable line.

- **Never** commit directly on `main`.
- **Never** force-push `main`.
- **Never** rewrite `main`.
- Only verified `develop` promotes to `main`, via a `develop → main` PR.
  **`develop` is the only branch that may merge into `main` — no exceptions.**
  There is no direct `hotfix/* → main` path: even an urgent fix goes through a
  category branch, then `develop`, then `main` (see §9).

`main` moves only at a release. Every other permanent branch will therefore be
behind `main` most of the time — which is, again, normal.

---

## 8. Conflict handling

If a `logic|design|docs → develop` PR has a **real** merge conflict:

1. **Inspect the exact conflict** — understand what actually collides.
2. Make the **minimum category-compatible adjustment on the category branch**
   if the conflict can be resolved there without importing integration context.
3. **Preserve category ancestry** — the fix stays on the category branch and
   flows forward.
4. If the conflict **cannot** be resolved safely without integration context:
   **STOP** and explicitly review the integration strategy with a maintainer.

**Never** "resolve" a category → develop conflict by merging `develop` back into
the category branch. That is a hidden back-merge and is forbidden. There are no
silent back-merge exceptions.

---

## 9. Temporary branches — the exception, not the default

A separate temporary branch is allowed **only when isolation is genuinely
useful**: a risky architecture experiment, a proof of concept, a prototype that
may be abandoned, a major/destructive refactor, a dependency/runtime migration,
or parallel investigation that should not touch `logic`/`design`/`docs` yet.

Use a clear, purpose-based name:

```
experiment/textkit2-renderer
prototype/multi-document
migration/swift-6
refactor/document-state-model
hotfix/preview-crash        # a genuine, urgent production fix — still folds
                           # into a category branch, NEVER straight to main
```

Never: `test`, `temp`, `new`, `branch1`, `feature123`, `ayush-work`.

> **Emergencies use the same forward path.** A `hotfix/*` branch (or a direct
> commit on the appropriate category branch) folds into `logic | design | docs`,
> then promotes `→ develop → main`. There is **no** direct `hotfix/* → main`
> shortcut — `develop` is the only branch that merges into `main`.

### Rules

- A temporary branch that is accepted into a category branch **must derive from
  the appropriate category context** and must **not** carry `develop` or `main`
  ancestry backward into the category branch.
- Temporary branches are **never** merged directly into `main`.
- Rejected temporary branches are deleted (record any useful findings first).
- Accepted temporary work folds into a category branch, then flows forward
  through `develop` to `main` like any other category work.

---

## 10. History rewrite policy

**The v1.0.2 repair was a one-time, exceptional, surgical reconstruction.**

Two incorrect backward-sync commits —

```
34259a5f04ef5e7d33d58e97e3c2f3ab23ced581
43c0cc0d71edabed162029ae2fa7acaa1c08b1ab
```

— were removed from permanent ancestry while preserving **identical release
content** (the v1.0.2 DMG, its SHA-256, and its source tree were unchanged).

This does **not** establish history rewriting as an allowed maintenance
technique. Going forward:

- **No history rewrites.** No `filter-branch`, no `filter-repo`, no
  `rebase`/`amend`/`reset --hard` of published permanent history, no branch
  recreation, no squashing of published history for cosmetics, no tag movement.
- If a workflow mistake happens again: **stop, preserve published history, and
  fix forward.** A clean graph is achieved by *not* making the mistake, not by
  rewriting after the fact.
- Another extraordinary reconstruction happens **only** with the explicit
  authorization of the repository owner, as a deliberate one-off — never as
  routine cleanup.

### Clean history ≠ perfectly linear history

A **clean** history means: correct branch direction, meaningful commits,
legitimate PR merge commits, no accidental backward integration, no duplicate
sync commits, no unnecessary force pushes, no rewriting for appearance.

It does **not** mean one straight line, no merge commits, or zero branches.
Parallel lanes and forward merge bubbles in a Git graph are normal and correct.
**Do not rewrite history for aesthetics.** Only topology *violations* matter.

---

## 11. Force-push policy

Force pushes are **disabled on all five permanent branches** (`main`, `develop`,
`logic`, `design`, `docs`) at the GitHub protection level.

The v1.0.2 maintenance window, during which force pushes and admin bypass were
temporarily enabled, was **exceptional and is over.** Do **not** re-enable force
pushes for ordinary work, and do not use `--force` / `--force-with-lease` on any
permanent branch as part of normal development.

---

## 12. Layered protection model

Enforcement is deliberately layered so no single mechanism is a single point of
failure:

| Layer | Mechanism | What it catches | Where |
| :---- | :-------- | :-------------- | :---- |
| **1** | GitHub branch protections | force-push, deletion, direct pushes to protected branches, missing required checks | server |
| **2** | Local **pre-push** transition guard | a push that would introduce develop/main ancestry into a category branch | your machine |
| **3** | Required **PR** direction + ancestry CI | disallowed PR directions and backward-merge ancestry in a PR | server (Actions) |
| **4** | This canonical workflow documentation | human/agent behavior, cherry-pick policy, conflict strategy | process |
| **5** | Manual audit (`--audit-history`) | topology drift, incident-commit reachability | on demand |

The shared validator `scripts/validate-branch-ancestry.sh` powers layers 2, 3,
and 5, and is unit-tested by `tests/test-branch-flow-policy.sh`.

### Install the local guard

```bash
bash scripts/install-git-guards.sh
git config --local --get core.hooksPath   # expect: .githooks
```

The installer only sets **repository-local** `core.hooksPath`; it never modifies
global Git configuration, and refuses to overwrite an existing local hooksPath.

---

## 13. Honest limitations of automated enforcement

The automation is truthful about what it can and cannot prove:

- **A. Category push workflows are not relied upon.** Permanent category
  branches are intentionally kept behind, so the version of a `push` workflow on
  `docs`/`design`/`logic` may be old or absent. Enforcement therefore lives in
  the **local pre-push guard** (ref transitions) and **PR CI** (integration),
  not in category push events.
- **B. Cherry-pick provenance cannot be proven.** If `develop` has commit `A`
  and someone cherry-picks it into `docs` as `A'`, then `A'` is a brand-new
  object with a different SHA and **no ancestry link** to `A`. Pure topology
  cannot detect this. Cherry-picking develop/main commits back into a category
  branch as a synchronization mechanism is forbidden by **policy** (§5), not by
  the validator.
- **C. PR `BASE..HEAD` cannot reconstruct prior ref movements.** If a category
  branch was fast-forwarded onto `develop` *before* a PR was opened, the PR's
  `BASE..HEAD` range may not reveal that historical transition. This is exactly
  why the local `--transition` pre-push guard exists and inspects the actual
  `OLD..NEW` ref movement.
- **D. Portable-Bash constraint.** The validator and hooks target Bash 3.2 (the
  macOS system shell) as well as Bash 5 on GitHub's Ubuntu runners, so they
  avoid Bash-4+-only features (associative arrays, `mapfile`, `${var,,}`).

---

## 14. Verification gates

- **Category (`logic`/`design`/`docs`)** — before pushing: builds succeed
  (`./build.sh` for logic; visual checks across Dark/Light/Sepia and
  Reader/Editor/Split for design; links/commands/paths for docs); relevant tests
  pass; no regression.
- **Integration (`develop`)** — app builds, no regression, tests pass, docs
  accurate, themes load, Reader/Editor/Split work, no broken resources.
- **`main`** — only ever receives verified work through `develop`. Always
  releasable.

---

## 15. Pull request directions

The only allowed permanent-branch PR directions (the **Branch Flow Policy**
check — job *Validate PR direction* — enforces both direction **and** ancestry;
add the `workflow:override` label to bypass for a reviewed maintenance merge):

| PR type | Source → Target |
| :------ | :-------------- |
| Integration | `logic` → `develop`, `design` → `develop`, `docs` → `develop` |
| Release | `develop` → `main` — **the only path into `main`** |
| Temporary intake (incl. hotfixes) | `experiment/*` \| `prototype/*` \| `migration/*` \| `refactor/*` \| `hotfix/*` → `logic` \| `design` \| `docs` |

**Explicitly forbidden** (never open these):

```
develop → logic     develop → design     develop → docs
main    → logic     main    → design     main    → docs
main    → develop   (as ordinary synchronization)
logic   → main      design  → main       docs    → main
hotfix/* → main     (no direct path to main — route through a category branch)
logic   → docs      logic   → design     docs    → logic
docs    → design    design  → logic      design  → docs
```

---

## 16. Commit convention

Conventional-style, imperative, scoped:

```
feat: add Mermaid pan mode
fix: guard heading echoes by current render revision
perf: move document analysis off the typing path
refactor: simplify diagram interaction state
design: refine glass toolbar
docs: document the category-branch workflow
build: update macOS build script
ci: add branch-flow ancestry validator
test: add Mermaid transform tests
```

Never: `update`, `changes`, `done`, `final`, `fixed stuff`, `wip`.

---

## 17. Tags

Use **annotated** tags only for meaningful milestones/releases. Do **not** use
branch-path-style tags such as `logic/performance/verified-v1`. **Tags are never
moved** once published.

```
foundation-v1   functional-integrity-v1   performance-v1     # milestones
v1.0.0   v1.0.1   v1.0.2                                      # releases
```

---

## 18. Branch protection (enforced)

Configured at the GitHub level (not merely advisory):

- **`main`** — require a PR before merging; require the `Build (macOS, Apple
  Silicon)` status check; **admin enforcement ON** (no bypass); force pushes
  **OFF**; deletions **OFF**; conversation resolution required. "Require branches
  to be up to date before merging" is intentionally **OFF** — requiring it would
  force a `main → develop` back-merge on every release, which contradicts the
  no-back-merge model. Merge commits are used (linear history is **not**
  required).
- **`develop`** — require a PR before merging; require the `Build (macOS, Apple
  Silicon)` status check; **admin enforcement ON**; force pushes **OFF**;
  deletions **OFF**.
- **`logic` / `design` / `docs`** — working category branches; direct pushes by
  the owner/agents are expected; force pushes **OFF**; deletions **OFF**.

`Require linear history` is **not** enabled on any branch — Lucid intentionally
uses merge commits for PR integration.

---

## Quick reference

```
main      stable, releasable            ← develop only
develop   integration gate              ← logic | design | docs
logic     engineering / functionality   ← direct work (+ accepted experiments)
design    UI / UX / visual              ← direct work (+ accepted experiments)
docs      documentation                 ← direct work (+ accepted experiments)

normal work:      commit directly on logic | design | docs, then PR → develop
update a branch:  git pull --ff-only origin <same-branch>   (never a back-merge)
being behind:     normal — never "sync" develop/main backward into a category
temporary branch: experiment/… prototype/… migration/… refactor/… (isolation only)
release tag:       vMAJOR.MINOR.PATCH   (annotated, never moved)
```
