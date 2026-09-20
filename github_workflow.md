# Lucid — Git & GitHub Workflow

This is the canonical, authoritative description of how work flows through the
Lucid repository. Every contributor should be able to read this file and
understand the complete process without asking anyone.

If the workflow itself changes, **update this file in the same change.**

---

## 1. Purpose

Lucid separates work into three categories — **design**, **logic**, and
**docs** — and moves every change through a strict, verifiable path:

```
WORK → CATEGORY → VERIFY → TAG → DEVELOP → INTEGRATION VERIFY → MAIN
```

The goals:

- `main` is always a stable, verified, releasable state.
- Every category of work is verified in isolation before it is integrated.
- `develop` catches interactions between individually-verified changes.
- Every accepted piece of work leaves an immutable, taggable checkpoint.
- History stays clean and auditable.

---

## 2. Permanent Branches

Five long-lived branches. **Never do task work directly on any of them.**

| Branch    | Role | Receives from | Promotes to |
| :-------- | :--- | :------------ | :---------- |
| `main`    | Stable, verified, releasable state | `develop` (and `hotfix-*` in emergencies) | — |
| `develop` | Integration of already-verified work | `design`, `logic`, `docs` | `main` |
| `design`  | Verified visual / UI / UX work | `design-*` task branches | `develop` |
| `logic`   | Verified non-design implementation | `logic-*` task branches | `develop` |
| `docs`    | Verified documentation | `docs-*` task branches | `develop` |

**What belongs where**

- **design** — UI refinement, visual polish, glass/window chrome, reader styling,
  typography, spacing, themes, animations, micro-interactions, layout, Mermaid
  visual presentation, settings/sidebar visual design, design-system changes.
- **logic** — application/rendering logic, Mermaid interaction (pan/zoom),
  bug fixes, performance, caching, parsing, state, file handling, commands,
  keyboard shortcuts, build scripts, tests, refactors, WebKit/NSTextView behavior.
- **docs** — README, architecture/developer/workflow docs, contributing guide,
  release notes, setup/user guides, doc screenshots, documentation corrections.

---

## 3. Task Branches

All real work happens on a short-lived **task branch** created from its category
branch. One scoped task per branch.

```
design-<task>     # e.g. design-glass-toolbar
logic-<task>      # e.g. logic-mermaid-pan-zoom
docs-<task>       # e.g. docs-github-workflow
```

> **Why a hyphen, not a slash?** Git cannot have a branch named `design` *and* a
> branch named `design/<task>` at the same time — a ref may not be both a branch
> and the path-prefix of another branch (a "directory/file" conflict). Because the
> permanent category branches are named `design`, `logic`, and `docs`, task
> branches use a hyphen separator (`design-<task>`). Verification **tags** use
> slashes (`design/<task>/verified-vN`) because tags live in a separate ref
> namespace and do not conflict.

### Naming rules

- lowercase
- hyphen-separated
- describe exactly one scoped task
- **never** vague: `fix`, `test`, `new`, `changes`, `work`, `temp`, `final`, `misc`

| Good | Bad |
| :--- | :-- |
| `logic-mermaid-pan-zoom` | `logic-fix` |
| `design-reader-polish` | `design-changes` |
| `docs-architecture-guide` | `docs-final` |

---

## 4. Full Merge Flow

The same shape for all three categories:

```
design-<task> → design → verify → tag → develop → integration verify → main
logic-<task>  → logic  → verify → tag → develop → integration verify → main
docs-<task>   → docs   → verify → tag → develop → integration verify → main
```

1. Branch from the category branch.
2. Do the work; self-review.
3. Category-appropriate verification (design/logic/docs — see §6).
4. PR: `task → category`. Merge after verification.
5. Category-branch verification.
6. **Annotated verified tag** on the accepted commit (see §11).
7. PR: `category → develop` (**Integration**). Merge.
8. Integration verification on `develop` (see §6).
9. PR: `develop → main` (**Release**). Merge.
10. Push; tag a semantic release on `main` when appropriate (see §12).

Task branches must **not** bypass their category branch and merge straight into
`develop` or `main`.

---

## 5. Branch Diagram

```
                              main
                                ▲
                                │
                   final integration verification
                                │
                             develop
                     ▲           ▲           ▲
                     │           │           │
                  design       logic        docs
                  ▲             ▲            ▲
                  │             │            │
             design-*       logic-*       docs-*
```

Per-category detail:

```
design-<task>            logic-<task>            docs-<task>
    ↓                        ↓                       ↓
 design                   logic                    docs
    ↓ verify                ↓ verify                 ↓ verify
    ↓ tag                   ↓ tag                    ↓ tag
 develop  ← integration ← develop  ← integration ← develop
    ↓ integration verify
   main
```

---

## 6. Verification Rules

Work may only advance when the relevant gate passes.

### Design verification (design-* → design, and before develop)
Applicable visual checks — Dark / Light / Sepia; Reader / Editor / Split;
narrow / normal / fullscreen windows; hover & keyboard-focus states; animations;
layout, typography, spacing. **Attach screenshots.** Design work must not reach
`develop` before visual verification.

### Logic verification (logic-* → logic, and before develop)
Applicable technical checks — build succeeds; relevant tests pass; runtime /
manual interaction verified; no regression; error paths checked; performance /
memory checked when relevant. Logic must not reach `develop` before technical
verification.

### Docs verification (docs-* → docs, and before develop)
Markdown renders; links, commands, and paths are correct; screenshots current;
examples match current code; no stale instructions; spelling/grammar; headings/TOC.

### Integration verification (on `develop`, before `main`)
App builds; no regression; UI/rendering works; tests pass; docs still accurate;
themes load; Reader/Editor/Split work; no merge conflicts; no broken resources.
`develop` exists to catch interactions between individually-verified changes.

### `main` stability
`main` only ever receives verified work through `develop` (or a verified
`hotfix-*` — see §15). It must always be releasable.

---

## 7. Pull Request Rules

Promotion happens via PRs. Allowed directions:

| PR type | Source → Target |
| :------ | :-------------- |
| Task | `design-*` → `design`, `logic-*` → `logic`, `docs-*` → `docs` |
| Integration | `design` → `develop`, `logic` → `develop`, `docs` → `develop` |
| Release | `develop` → `main` |
| Hotfix (emergency) | `hotfix-*` → `main` (then back-merge to `develop`) |

Disallowed (flagged by the branch-flow check, see §13): task branches straight to
`develop`/`main`, `design`/`logic`/`docs` straight to `main`, etc.

### PR titles

```
[Design] <task description>
[Logic]  <task description>
[Docs]   <task description>
[Integration] Merge verified <category> into develop
[Release] Promote develop to main
```

Every PR should carry **one `type:` label + at least one `area:` label + one
`status:` label** (see §10) and complete the PR template checklist (see §26 in the
task spec / `.github/pull_request_template.md`).

---

## 8. Branch Naming Convention (summary)

```
design-<task>   design-glass-toolbar   design-reader-polish
logic-<task>    logic-mermaid-pan-zoom logic-rendering-fix
docs-<task>     docs-github-workflow   docs-architecture-guide
hotfix-<task>   hotfix-preview-crash
```

---

## 9. Commit Convention

Conventional-style, imperative, scoped. Examples:

```
design:   design: refine glass toolbar
feat:     feat: add Mermaid pan mode
fix:      fix: preserve diagram zoom state
perf:     perf: reduce preview update work
refactor: refactor: simplify diagram interaction state
test:     test: add Mermaid transform tests
docs:     docs: document GitHub workflow
build:    build: update macOS build script
```

Never: `update`, `changes`, `done`, `final`, `fixed stuff`.

---

## 10. Labels

Every PR: **one type + one (or more) area + one current status.**

**Type** — `type:design`, `type:logic`, `type:docs`

**Status** — `status:planned`, `status:in-progress`, `status:verification`,
`status:verified`, `status:blocked`

**Area** — `area:reader`, `area:editor`, `area:mermaid`, `area:toolbar`,
`area:sidebar`, `area:settings`, `area:themes`, `area:rendering`,
`area:performance`, `area:build`, `area:docs`, `area:accessibility`, `area:window`

Example: `type:design` + `area:toolbar` + `status:verification`.

---

## 11. Work (Verification) Tags

Every completed, **genuinely verified** task gets an **annotated** tag that
pins the exact accepted commit.

```
design/<task>/verified-vN
logic/<task>/verified-vN
docs/<task>/verified-vN
```

Create it **only after** verification, on the accepted commit in the category
branch:

```bash
git tag -a logic/mermaid-pan-zoom/verified-v1 \
  -m "Verified Mermaid pan, zoom, fit and reset implementation"
git push origin logic/mermaid-pan-zoom/verified-v1
```

Revised & re-verified work gets a new version (`…/verified-v2`).
**Verification tags are immutable — never move or reuse one.**

---

## 12. Release Tags

Releases on `main` use plain semantic versions, kept **separate** from work tags:

```
v1.0.0   v1.1.0   v1.1.1   v2.0.0
```

`logic/mermaid-pan-zoom/verified-v1` (a work checkpoint) and `v1.2.0` (a release)
serve different purposes and must not be conflated.

---

## 13. Branch Protection

Where the repository plan permits, protect `main`, `develop`, `design`, `logic`,
`docs`:

- **`main`** — require PR, passing checks, no direct push, resolved conversations,
  up-to-date branch.
- **`develop`** — require PR, passing checks, no direct push.
- **`design` / `logic` / `docs`** — require task PR + relevant verification, no
  direct push for normal work.

A lightweight **branch-flow** GitHub Action (`.github/workflows/branch-flow.yml`)
validates that each PR uses an allowed source→target direction and flags
bypasses. Maintainers can override by adding the `workflow:override` label to a PR.

> **Current state:** see the repository's final report / README. On private repos
> without a paid plan, GitHub branch-protection rules may be unavailable via API or
> UI. If so, the discipline above is enforced by convention + the branch-flow
> check, and protection should be enabled once the plan allows it. To enable it
> manually: **Repo → Settings → Branches → Add branch ruleset** (or classic
> **Branch protection rules**), target each permanent branch, and enable
> *Require a pull request before merging* and *Require status checks to pass*.

---

## 14. Task Lifecycle Examples

### Design

```
design-glass-toolbar
 → PR [Design] → design        (screenshots: dark/light/sepia, reader, windows)
 → design/glass-toolbar/verified-v1
 → PR [Integration] design → develop
 → integration verification
 → PR [Release] develop → main
```

### Logic

```
logic-mermaid-pan-zoom
 → PR [Logic] → logic          (build + tests + manual verification)
 → logic/mermaid-pan-zoom/verified-v1
 → PR [Integration] logic → develop
 → integration verification
 → PR [Release] develop → main
```

### Docs

```
docs-github-workflow
 → PR [Docs] → docs            (markdown/links/commands/paths verified)
 → docs/github-workflow/verified-v1
 → PR [Integration] docs → develop
 → content/integration verification
 → PR [Release] develop → main
```

---

## 15. Hotfix Process (emergency only)

For serious, production-breaking bugs **only**:

```
hotfix-<task> → main   (after verification)
             → then immediately back-merge into develop
             → and the relevant category branch if needed
```

Never use `hotfix-*` for normal development.

---

## 16. Starting New Work

Always start from the latest category branch.

```bash
# design
git checkout design && git pull origin design
git checkout -b design-glass-toolbar

# logic
git checkout logic && git pull origin logic
git checkout -b logic-mermaid-pan-zoom

# docs
git checkout docs && git pull origin docs
git checkout -b docs-github-workflow
```

Before opening the PR, sync with the category branch to avoid stale conflicts:

```bash
git fetch origin
git merge origin/<category>   # or rebase, per the chosen strategy
```

---

## 17. Completing Work

```
commit (clean, conventional messages)
push task branch
open task PR  →  category         (labels + checklist)
verify
merge task PR into category
tag the verified commit           (design|logic|docs)/<task>/verified-vN
open Integration PR  category  →  develop
integration verify
open Release PR       develop  →  main
push; tag semantic release on main when appropriate
delete the task branch (the verified tag preserves the checkpoint)
```

**Merge strategy:** squash-merge scoped task branches into their category branch
(clean, one commit per task); use merge commits for Integration and Release PRs so
category/integration history is preserved.

---

## 18. Rules — Never Do This

- Never work directly on `main`.
- Never use `develop` as a task/sandbox branch.
- Never bypass category verification.
- Never merge a task branch straight into `develop` or `main`.
- Never reuse or move a `verified-*` tag.
- Never mix unrelated tasks into one branch.
- Never force-push a protected/shared branch during normal work.

---

## Quick Reference

```
main      stable, releasable           ← develop only
develop   integration gate             ← design | logic | docs
design    verified visual work         ← design-*
logic     verified implementation      ← logic-*
docs      verified documentation       ← docs-*

task branch:   <category>-<task>        (design-…, logic-…, docs-…)
verified tag:  <category>/<task>/verified-vN   (annotated, immutable)
release tag:   vMAJOR.MINOR.PATCH
```
