<!--
  Lucid PR. Title format:
    [Design] <task>   [Logic] <task>   [Docs] <task>
    [Integration] Merge verified <category> into develop
    [Release] Promote develop to main
  See github_workflow.md for the full workflow.
  Add labels: one type: + one or more area: + one status:.
-->

## Type

- [ ] Design
- [ ] Logic
- [ ] Docs

## Area

<!-- Which product/repository area(s)? e.g. reader, toolbar, mermaid, rendering, build, docs -->

## Summary

<!-- What changed? -->

## Why

<!-- Why was this work required? -->

## Verification

<!-- How was it verified? Fill in the applicable checklist below. -->

### Design verification (if design)
- [ ] Dark mode checked
- [ ] Light mode checked
- [ ] Sepia mode checked
- [ ] Reader checked
- [ ] Editor checked (if relevant)
- [ ] Split checked (if relevant)
- [ ] Narrow window checked
- [ ] Normal window checked
- [ ] Fullscreen checked
- [ ] Hover / keyboard-focus states checked
- [ ] Screenshots attached

### Logic verification (if logic)
- [ ] Build succeeds (`./build.sh`)
- [ ] Relevant tests pass
- [ ] Manual behavior verified
- [ ] No obvious regression
- [ ] Error path checked
- [ ] Performance checked (if relevant)
- [ ] Memory checked (if relevant)

### Docs verification (if docs)
- [ ] Markdown renders correctly
- [ ] Links checked
- [ ] Commands verified
- [ ] Paths verified
- [ ] Screenshots current
- [ ] Examples match current Lucid behavior
- [ ] No stale instructions

## Screenshots

<!-- Required for visual/design work when relevant. -->

## Checklist

- [ ] Correct task branch used (`design-*` / `logic-*` / `docs-*`)
- [ ] PR direction is allowed (see github_workflow.md §7)
- [ ] Relevant verification completed
- [ ] No unrelated changes included
- [ ] Labels applied (type + area + status)
- [ ] Ready for category branch review
