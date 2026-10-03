# Stable audit fixes and verification

Implemented directly on `logic` on 2026-10-01. The original AUDIT.md and its failing diagnostic logs remain historical evidence; production code is now changed with the user's authorization. No integration, push, release publication, or canonical DMG replacement was performed.

## Fixed audit findings

1. **Cross-tab undo corruption:** DocumentSession owns an independent UndoManager. LucidTextView switches to that history, exposes native Undo/Redo actions and validation, and clears obsolete history on disk replacement. The regression exercises native command selectors, Undo, Redo, and switching back to another document. Actual keyboard Undo was verified in the packaged app.
2. **Named-file draft recovery:** snapshots retain dirty text (including empty text), baseline, and encoding. Recovery preserves drafts when their original file disappears or becomes unreadable, and marks genuine disk divergence as a conflict. Manager changes schedule recovery saves after a 250 ms debounce. Termination saves are protected from window teardown overwrites.
3. **Multi-window recovery:** records are consumed once, in order, and unhydrated windows remain in persisted snapshots. AppKit window restoration is coordinated with additional Lucid windows. Empty duplicate launch placeholders are removed only during launch; explicit New Window ends this cleanup phase. Three distinguishable dirty drafts restored across exactly two windows after interrupted relaunch. A subsequent New Window stayed fresh and available.
4. **Destructive quit cancellation:** DocumentCloseReview stages discard decisions and reviews all dirty sessions before removing any tabs. Failed saves and cancellation preserve every tab. Changes made during review require another decision. Repeated close requests cannot enqueue another review. Actual quit with Don't Save for the first tab and Cancel for the next retained both edited tabs and their text.
5. **False external conflicts after saving:** watcher callbacks compare disk text to the saved baseline before treating a dirty buffer as divergent. Actual atomic writes followed immediately by further typing no longer flag an external conflict; genuine external writes still reload clean inactive tabs.
6. **Stale relative images:** preview rendering and local asset URLs include the document identity. Identical Markdown in two different folders now loads each folder's image. A real WKWebView regression verifies distinct natural image widths after switching the source URL.

## Additional failures found while verifying the fixes

- Native document dirty state produced redundant Untitled prompts before Lucid's tab prompts. Tab sessions now own edits and saves; FileDocument supplies the initial file only. The native dirty buffer is cleared while the window retains its tab editing indicator. Actual quit goes directly to the Lucid prompts.
- Native Undo commands initially targeted the empty native document history after introducing per-tab history. Explicit responder actions and command validation now route them to the displayed session, verified with Cmd-Z in the packaged app.
- Edits arriving after tab selection but before the editor redraw could update the newly selected buffer through its binding. The editor delegate now updates the displayed session when its identity differs, including cursor metadata. The focused test reproduces this timing boundary and checks that the other buffer remains unchanged.
- The Close Window shortcut could close dirty restored windows without a Lucid prompt. It depended on window delegate forwarding, whose hook was installed only at initial attachment. The command now calls the transactional tab review explicitly, close notifications target their original window, and the configurator reattaches its close delegate after SwiftUI updates. Actual Close Window and the red close button both presented a save review, and Cancel retained the draft.

## Verification

- Full Swift suite: **106 tests in 18 suites passed**, including **15 permanent stable-release regression tests** in `tests/LucidTests/StableReleaseRegressionTests.swift`.
- Six Node renderer suites: **62 assertions passed**.
- Branch-flow policy suite: **23 scenarios passed**.
- Website suite: **14 tests passed**.
- Supported `./build.sh`: release compilation, bundle resources, Sparkle framework copy, signing, strict deep signature verification, and local DMG creation succeeded. SDKROOT points to the installed macOS 26.5 SDK because this host's macOS 27 SDK lacks the required macro plugins.
- `git diff --check`: passed.
- Canonical `Lucid-1.0.7.dmg` is unchanged: SHA-256 `175805b93b16a693ac59989d71b53b2ffccf49f29ddd519a0727c327efee7d25`.
- Native behavior was exercised using separately identified, ad hoc signed `/tmp` test bundles and isolated defaults, not installed Lucid preferences. Their temporary processes were stopped afterward.

Logs retained beside this report: `final-swift.log` and `final-build.log`. The permanent regression suite is part of the source changes; audit evidence remains ignored under `scratch/`. Generated `Lucid.app` and `Lucid-local.dmg` are ignored local development artifacts.

## Remaining release checks

All confirmed audit bugs have fixes and passing reproduction checks. This does not certify every macOS version or a published stable artifact: macOS 14 through 26, physical sleep/wake, power loss, and a live signed Sparkle upgrade were not re-tested here. Recovery snapshots are debounced and UserDefaults is asynchronously persisted, so the interrupted-relaunch checks do not prove zero lost keystrokes under immediate process kill or power failure. Integrate through `develop`, then verify the actual signed release package and supported OS matrix before publishing.
