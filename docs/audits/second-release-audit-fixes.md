# Second release audit fixes and verification

2026-10-02, implemented directly on `logic`. The original audit findings below remain historical evidence. All four confirmed reproductions fail against the initial working tree and pass against the corrected code. Existing uncommitted changes were preserved; no commit, branch change, integration, publication, or canonical release artifact replacement was performed.

**Confirmed defect status: all four fixed. Release recommendation: hold for the remaining verification gaps below.**

## Baseline evidence

Read CONTRIBUTING.md, docs/github_workflow.md, the first audit's FIXES.md, this audit's AUDIT.md, isolated diagnostics, current production callers and full starting diff. No AGENTS.md was found in the repository. `before-fixes.diff` and `original-working-tree/` preserve the starting modifications and new files.

`reproduction-before-fixes-native.log`: the unchanged independent diagnostics ran with native macOS services. Nine tests: five passed and four failed, with 61 recorded issues. The editor ordering failed all 25 repetitions, pending recovery was lost, the old save path was recreated, and eight rendered image-dimension assertions failed. The initial sandboxed diagnostic could not obtain native WebKit service access and is not counted as valid WebKit evidence.

## Fixes and durable coverage

1. **Displayed editor identity.** Editor text delegates always write the session displayed by LucidTextView. MainWindowView's text binding and cursor/reading callbacks capture a stable session. Shared-editor buffer changes update the image insertion URL. Image-save sheet replies capture their origin and ignore replies after a buffer switch; save requests receive the actual displayed session. Cursor and scroll metadata remain attached to that session, and normal model notifications continue to schedule analysis/recovery.

   Permanent tests retain both coordinator orderings, native insertText, per-session Undo/Redo, delayed text/selection notifications, named disk bytes, and untitled recovery records. The new suite repeats the early ordering 25 times and the interleaved edit/Undo/Redo/save/callback sequence 25 times per run. The original later-ordering test remains unchanged in StableReleaseRegressionTests.swift.

2. **Pending recovery protection.** Recovery records are loaded when the restorer initializes, before managers or launch replacement snapshots exist, and protected again on registration and every snapshot entry point. Live tab IDs are adopted once; unhydrated records remain persisted. A named launch window is preserved while a blank recovery window can hydrate alongside it. New snapshots cannot be reinterpreted as older pending recovery after the last live window closes. Launch cleanup cannot close blank native windows awaiting recovery.

   Tests assert draft bytes and IDs for snapshots that never call restoreInto, three consecutive file-first launches, native named-document presence, partially completed multi-window hydration, recovery-first startup, record deduplication, and last-window unregister semantics. A native NSDocument/window test verifies cleanup before and after hydration. Existing empty/deleted-file, old-schema, Unicode, encoding and multi-window regressions remain passing.

3. **Save destination identity.** DocumentFileIdentity retains an open vnode and resolves its current path with F_GETPATH, checking device/inode and link count. Same-volume moves/renames are followed before watcher callbacks arrive and while inactive. Watcher callbacks update the session URL and watcher together. Save coordinates replacement with NSFileCoordinator and revalidates identity after coordination grants access. Successful atomic saves refresh identity; clean adopted external replacements refresh it too. If identity cannot be resolved, Save uses the explicit destination panel. Cancelling preserves text, baseline, URL and dirty state, including during close review. Explicit Save As can recreate or choose a new file.

   Twenty-five immediate move-to-another-directory tests replace the original path with unrelated contents and assert that only the moved original receives edits. Tests also assert original-path absence, deletion, ambiguous replacement, Save/Save As/close-save cancellation, selected destination bytes and unchanged unrelated buffers. Cross-volume moves lose the original vnode and therefore require a destination decision; an actual cross-volume native move was not tested.

4. **Fresh image assets.** Each native render has a coordinator-specific UUID namespace and monotonic revision for relative and absolute local asset URLs. Revealing a preview forces a fresh render even with unchanged Markdown. In-flight relative requests carry and resolve their original document identity rather than reading the newly selected tab's folder. Obsolete JavaScript delivery completions cannot requeue an older document.

   Real WebKit coverage uses the actual SwiftUI PreviewWebView, coordinator, native scheme handler and repository WebEngine. Ten navigation cycles assert document identity plus naturalWidth/naturalHeight for relative, absolute and shared assets, atomic replacement, unusual directory names and source URL changes representing Save As. Each cycle also replaces the image while the same document's preview is hidden and verifies its new dimensions after reveal. Renderer assertions verify the generated URL format; a native resolver assertion checks delayed requests retain their source directory. Render generation deliberately refreshes local images on Markdown renders; large-image I/O performance was not benchmarked.

Durable source: `tests/LucidTests/SecondReleaseRegressionTests.swift` (15 tests), existing `StableReleaseRegressionTests.swift`, and updated local-asset assertions in `tests/test-security-and-engines.js`.

## Final verification

- Full Swift suite: **121 tests in 20 suites passed**, including native AppKit and real WebKit.
- New permanent suite: **15 tests repeated five times**, including 25 repetitions each of three ordering-sensitive editor/save sequences and 20 navigation/reveal transitions per image test. Logs: `repeated-regressions-1.log` through `repeated-regressions-5.log`.
- Original independent diagnostics: **9 tests passed** against the fixes, including all four exact reproductions. Log: `diagnostics-after-fixes-native.log`.
- Six Node renderer suites: **62 assertions passed**. Branch policy: **23 scenarios passed**.
- Website: **14 tests passed**, TypeScript `tsc --noEmit` passed, production Next.js build passed, canonical release validator passed. The first sandboxed validator failed because tsx's local IPC socket was denied; the native-service rerun passed.
- Supported `build.sh`: optimized arm64 compilation, bundle/resources/Sparkle assembly, ad hoc signing, strict deep signature verification, and **Lucid-local.dmg** creation passed. Used the installed macOS 26.5 SDK and isolated module caches. The host's CLT emit missing optional framework search-path warnings; compilation/testing completed successfully.
- Fresh local DMG: mounted read-only, app strict/deep signature verified, executable compared byte-for-byte with the built executable, image detached afterward. Info.plist lint passed.
- Canonical Lucid-1.0.7.dmg remains unchanged: SHA-256 `175805b93b16a693ac59989d71b53b2ffccf49f29ddd519a0727c327efee7d25`.
- Final diff reviewed against the starting working tree for cross-session callbacks, snapshot overwrite/duplication, cleanup ordering, stale watcher events, save identity/cancellation and stale WebKit delivery. `git diff --check` passed. Original DocumentSession, DocumentCloseReview and StableReleaseRegressionTests contents were preserved.

## Native workflow evidence

Used independently identified, ad hoc signed `/tmp/lucid-second-fixes-native/` app copies and disposable documents/defaults. Installed Lucid documents/preferences were not used. Test app processes were stopped and DMGs detached.

- External rename followed by native Command-S updated `native-moved.md` with `NATIVE EDIT AFTER MOVE`; `native-original.md` remained absent. Disk bytes were asserted.
- Native Save As cancellation preserved `NATIVE UNSAVED MUST SURVIVE CANCELLATION`, its URL and the saved baseline on disk.
- Close Window and Quit presented review; Cancel preserved the buffer. Across two dirty windows, Don't Save followed by Cancel retained both drafts; both exact contents were verified in the isolated persisted snapshot.
- Deleting the named fixture made native Save present a destination panel. Cancel left the draft intact and did not recreate the missing file.
- Interrupted same-identity relaunch hydrated both drafts into new manager/window IDs, retained both original tab IDs and exact draft contents in the post-relaunch snapshot. The process sample showed the main thread idle in its event loop. Computer-use inspection repeatedly timed out on this process, so **visual verification of that same-identity relaunch is incomplete**; a product hang or missing-window defect was not established.
- Replaying the captured interrupted snapshot in a fresh separately identified copy of the rebuilt signed app visibly restored exactly two recovery windows. Accessibility inspection verified both the deleted named document draft and the separate Unicode untitled draft. Keyboard tab navigation, immediate typing, Command-Z and Command-Shift-Z retained the other tab's `NATIVE TAB B`; final persisted recovery contained all three distinct buffers across two windows.

The final DMG was also extracted into a fresh isolated app identity after the launch-cleanup guard was added. Both restored windows were visually inspected. Missing-file Save, Save As, Close Window and Quit cancellation retained the named draft; final snapshot assertions retained both exact drafts across two windows and verified that the missing file was not recreated. Evidence: `native-final-package-settings.plist`.

Snapshots: `native-fixed-before-relaunch.plist`, `native-fixed-interrupted-relaunch.plist`, `native-fixed-replay-final.plist`. The timed-out process's sample is retained as `native-relaunch-sample.txt`. Fresh-identity replay is distinct from direct same-identity relaunch observation and from a live updater installation.

## Remaining limitations and release hold

No confirmed release-blocking data-loss reproduction remains. Direct same-identity relaunch UI inspection still needs completion because of the computer-use timeouts described above. Recovery persistence and hydration did pass, as did fresh-identity native replay; neither substitutes for that missing visual observation.

No macOS 14/15/26 runtime compatibility matrix, Intel validation, live signed Sparkle install/relaunch/rollback/interruption, Developer ID/notarized/quarantined launch, App Translocation, physical power loss or sleep/wake was performed. No real cross-volume move, denied-read/TCC matrix, or full export visual matrix was performed. The existing recovery debounce and asynchronous UserDefaults persistence do not guarantee zero lost keystrokes under immediate kill/power loss. The candidate remains on hold pending direct relaunch UI verification and the previously identified stable-release qualification checks. No compatibility, notarization, updater or power-loss claim is made.
