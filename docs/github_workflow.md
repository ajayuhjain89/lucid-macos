# Lucid — Git & GitHub Workflow

This is the canonical, authoritative description of how work flows through the
Lucid repository. Every contributor — human or coding agent — should be able to
read this file and understand the complete process without asking anyone.

If the workflow itself changes, **update this file in the same change.**

---

## 1. Mental model

Lucid separates work into three **categories** — **logic**, **design**, and
**docs** — but does **not** create a new branch for every task. Ordinary work
happens **directly on the category branch**, then flows through integration:

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

---

## 2. Permanent branches

Exactly five long-lived branches:

| Branch    | Role | Receives from | Promotes to |
| :-------- | :--- | :------------ | :---------- |
| `main`    | Stable, verified, releasable product | `develop` | — |
| `develop` | Integration gate for verified category work | `logic`, `design`, `docs` | `main` |
| `logic`   | All engineering / functionality work | worked on directly (+ accepted temporary branches) | `develop` |
| `design`  | All UI / UX / visual work | worked on directly (+ accepted temporary branches) | `develop` |
| `docs`    | All documentation work | worked on directly (+ accepted temporary branches) | `develop` |

**What belongs where**

- **logic** — Swift, AppKit, SwiftUI, architecture, Editor/Reader behavior,
  Markdown rendering, WebEngine, Mermaid, KaTeX, performance, concurrency,
  commands, shortcuts, file handling, bugs, refactors, tests, build/release
  engineering, technical infrastructure, engineering-oriented website work.
- **design** — toolbar/sidebar visuals, typography, spacing, themes, icons,
  Reader/Settings appearance, interaction polish, branding, website visual
  design, screenshots/assets.
- **docs** — README, user/architecture/contributor docs, this workflow doc,
  release notes, changelog, website documentation content.

---

## 3. Normal workflow — no task branches

For ordinary work, **do not create a new branch.** Determine whether the task is
logic, design, or docs, and work directly on that category branch.

```bash
# engineering example
git checkout logic
git pull origin logic
# …implement + verify…
git add <reviewed files>
git commit -m "perf: optimize large-document rendering"
git push origin logic

# integrate
git checkout develop && git pull origin develop
git merge logic          # integration verification
git push origin develop

# promote when stable
git checkout main && git pull origin main
git merge develop        # final verification
git push origin main
```

Design and docs follow the identical shape on the `design` and `docs` branches.

**Do not** create branches like `logic/large-document-performance`,
`design/top-bar`, `docs/getting-started`, `feature/foo`, `fix/bar`, `perf/foo`
for normal work.

### History hygiene — keep the graph readable

- **Never fast-forward integration/release merges.** This repo sets
  `git config --local merge.ff false`, so `logic|design|docs → develop` and
  `develop → main` always create a real merge commit. Fast-forwards collapse
  `develop` and `main` onto the same commit, which erases the two-lane history.
- **Keep `develop` ahead of `main`.** New work always lands on `develop` (via a
  category branch); `main` only moves at a release. Never commit directly on
  `main`, and never reset one onto the other.
- **Advance a category branch to the latest `develop` before starting work** on
  it, so a new commit never branches from a stale tip and swoops back across the
  graph.

---

## 4. Temporary branches — the exception, not the default

A separate temporary branch is allowed **only when isolation is genuinely
useful**, e.g. a risky architecture experiment, a prototype that may be
abandoned, a major/destructive refactor, a dependency/runtime migration, an
experimental renderer, a proof of concept, or parallel investigation that should
not touch `logic`/`design`/`docs` yet.

Use a clear, purpose-based name:

```
experiment/textkit2-renderer
prototype/multi-document
migration/swift-6
refactor/document-state-model
hotfix/preview-crash        # only for a genuine, urgent production issue
```

Never: `test`, `temp`, `new`, `branch1`, `feature123`, `ayush-work`.

### Lifecycle

```
temporary branch → implement / evaluate → verify
  rejected  → delete it (record any useful findings first)
  accepted  → clean history if messy → merge/cherry-pick into logic|design|docs
            → verify → develop → integration verify → main
```

Temporary branches must never become permanent category branches, and are
**never merged directly into `main`**.

---

## 5. Rules for coding agents (Codex / Claude / others)

- **Never create a new branch for ordinary work.** Engineering → `logic`,
  design → `design`, documentation → `docs`; work directly there.
- Only create a branch when (1) the user explicitly asks, or (2) the work is a
  genuine experiment / prototype / migration / major-refactor where isolation
  has a concrete benefit. Name it for its purpose.
- Verified category work → `develop`; verified integrated work → `main`.
- Accepted temporary work goes into a category branch first, never straight to
  `main`.
- Rejected temporary branches are deleted.
- Never discard uncommitted user work.
- Never force-push casually; use `--force-with-lease` and only on a branch you
  intentionally rewrote.

---

## 6. Verification gates

- **Category (`logic`/`design`/`docs`)** — before pushing: builds succeed
  (`./build.sh` for logic; visual checks across Dark/Light/Sepia and
  Reader/Editor/Split for design; links/commands/paths for docs); relevant tests
  pass; no regression.
- **Integration (`develop`)** — app builds, no regression, tests pass, docs still
  accurate, themes load, Reader/Editor/Split work, no broken resources. `develop`
  exists to catch interactions between individually-verified categories.
- **`main`** — only ever receives verified work through `develop`. Always
  releasable.

---

## 7. Pull request directions

The workflow is direct-to-category, so **most work needs no PR**. When PRs are
used (e.g. for review or protected branches), only these directions are allowed
(the `branch-flow` check enforces them; add the `workflow:override` label to
bypass for maintenance):

| PR type | Source → Target |
| :------ | :-------------- |
| Integration | `logic` → `develop`, `design` → `develop`, `docs` → `develop` |
| Release | `develop` → `main` |
| Temporary intake | `experiment/*` \| `prototype/*` \| `migration/*` \| `refactor/*` → `logic` \| `design` \| `docs` |
| Hotfix (emergency) | `hotfix/*` → `main` (then back-merge to `develop`) |

Disallowed: anything into `main` other than `develop`/`hotfix/*`; ad-hoc
`feature/*`/`fix/*` task branches for normal work.

---

## 8. Commit convention

Conventional-style, imperative, scoped:

```
feat: add Mermaid pan mode
fix: guard heading echoes by current render revision
perf: move document analysis off the typing path
refactor: simplify diagram interaction state
design: refine glass toolbar
docs: document the category-branch workflow
build: update macOS build script
test: add Mermaid transform tests
```

Never: `update`, `changes`, `done`, `final`, `fixed stuff`, `wip`.

---

## 9. Tags

Use **annotated** tags only for meaningful milestones/releases. Do **not** use
branch-path-style tags such as `logic/performance/verified-v1`.

```
foundation-v1   functional-integrity-v1   performance-v1     # milestones
v1.0.0-beta.1   v1.0.0                                        # releases
```

Tags are not required for every commit.

---

## 10. Branch protection (recommendation)

Optimized for a small team / owner + coding agents — **not** mandatory
PR-per-task, because the workflow intentionally uses direct category branches.

- **`main`** — protect from accidental force-push/delete; require the build check;
  only `develop` (or a verified `hotfix/*`) lands here.
- **`develop`** — integration branch; require the build check.
- **`logic` / `design` / `docs`** — working category branches; direct pushes by
  the owner/agents are expected.

The `branch-flow` GitHub Action validates PR direction as an advisory guard;
maintainers bypass it with the `workflow:override` label.

---

## Quick reference

```
main      stable, releasable            ← develop only
develop   integration gate              ← logic | design | docs
logic     engineering / functionality   ← direct work (+ accepted experiments)
design    UI / UX / visual              ← direct work (+ accepted experiments)
docs      documentation                 ← direct work (+ accepted experiments)

normal work:     commit directly on logic | design | docs
temporary branch: experiment/… prototype/… migration/… refactor/… (only when isolation helps)
release tag:      vMAJOR.MINOR.PATCH
```
