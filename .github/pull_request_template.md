<!--
  Lucid PR. Most work is committed directly on logic/design/docs and needs no PR.
  Open a PR only for integration or review. Allowed directions (see
  docs/github_workflow.md §7):
    logic | design | docs            -> develop      (Integration)
    develop                          -> main         (Release)
    experiment/… prototype/… migration/… refactor/…  -> logic | design | docs
    hotfix/…                         -> main         (emergency)
-->

## Category

- [ ] Logic (engineering / functionality)
- [ ] Design (UI / UX / visual)
- [ ] Docs (documentation)
- [ ] Integration (category → develop)
- [ ] Release (develop → main)

## Summary

<!-- What changed? -->

## Why

<!-- Why was this work required? -->

## Verification

<!-- Fill in the applicable checklist. -->

### Logic
- [ ] Build succeeds (`./build.sh`)
- [ ] Relevant tests pass
- [ ] Manual behavior verified
- [ ] No obvious regression
- [ ] Performance / memory checked (if relevant)

### Design
- [ ] Dark / Light / Sepia checked
- [ ] Reader / Editor / Split checked (as relevant)
- [ ] Narrow / normal / fullscreen checked
- [ ] Hover / keyboard-focus states checked
- [ ] Screenshots attached

### Docs
- [ ] Markdown renders correctly
- [ ] Links / commands / paths verified
- [ ] Examples match current behavior
- [ ] No stale instructions

## Checklist

- [ ] PR direction is allowed (docs/github_workflow.md §7)
- [ ] No unrelated changes included
- [ ] Ready for integration
