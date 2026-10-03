# Lucid stable-release audit — 2026-10-01

Audited `main` at `b8ec22c5c105e28b1ccd6bbc7139b111cd4e815c` (1.0.7, build 8), on Apple Silicon/macOS 27.0.1. The starting worktree was clean. No production source, configuration, release artifact, or Git history was changed. Diagnostic tests were staged temporarily in the Swift test target, then moved here so ordinary tests remain unaffected.

**Assessment: do not ship stable yet. Cross-tab Undo is a confirmed release blocker because it modifies the wrong document. Named-buffer recovery is also a confirmed data-loss gap that should be fixed before stable.** The remaining confirmed session/preview defects should also be resolved and verified before calling the release stable.

## Architecture and scope

Read README, CONTRIBUTING, the branch/release workflow, changelog, build/CI scripts and current test suites. No AGENTS.md was found in the repository or its ancestor directories. Recent engineering commits were examined, especially `ab543df` (new tabs, empty state, close/quit), `f63eb02` (restoration), `7bef415` (tabs), `3de29cc` (image insertion), `792e06a` (asset resolution), and `3c1d25d` (startup crash fix).

Lucid uses a SwiftUI DocumentGroup/AppKit document shell. WindowDocumentManager owns independent DocumentSession buffers and file watchers. Each window shares one native NSTextView and one WKWebView across its tabs. Preferences are shared, pane/view state is window scoped, and the offline WebEngine renders Markdown/math/diagrams. Separate offscreen WebKit rendering supports exports. Session snapshots and recents use UserDefaults/bookmarks; Sparkle handles updates.

Traced open/new/recent → session/tab → editor/preview → save/watch/conflict → close/quit → restoration, along with image resolution, export readiness, update availability and release metadata. Reviewed error paths for decoding, image/file I/O, WebContent-process termination, rendering cancellation, export timeout and update configuration. Read the documented ad-hoc-signing/Gatekeeper and manual-upgrade limitations; those are disclosed release constraints, not newly discovered code bugs.

## Confirmed findings (severity order)

### 1. RELEASE BLOCKER — Undo edits the wrong tab

**User-visible failure:** undoing an edit made in tab B after switching to A deletes text from A. Saving A persists the corruption.

**UI reproduction:** open a saved file A in Editor mode; create a new tab B, choose Start Writing and paste `New draft B`; switch back to A with Command-Shift-[; press Command-Z. In the fresh release build, A's buffer changed from a prefix of `LOCAL UNSAVED TWO...` to `VED TWO...`, although that undo belonged to B. The isolated AppKit test demonstrates the same failure: type `Draft B`, replace the editor source with `Saved document A`, undo → `ocument A`.

**Expected/actual:** undo affects only the active document's own history (or is unavailable). Actual: a retained undo operation targets character ranges in a different buffer.

**Root cause:** `Sources/Lucid/Views/EditorView.swift:94` enables undo on the shared text view. `Sources/Lucid/Views/MainWindowView.swift:460–466` replaces its string on tab switch without changing/resetting its undo manager. External text replacement at `EditorView.swift:220–228` has the same missing invalidation. DocumentSession owns no independent undo history.

**Suggested fix:** give sessions separate undo managers/history and bind the active session's manager to the shared editor; at minimum invalidate the old undo stack whenever the editor switches buffers. Treat external reloads deliberately so stale range operations cannot survive source replacement.

**Verify:** `sharedEditorUndoDoesNotMutateAnotherDocument` (diagnostic line 71) plus UI Undo/Redo across several tabs, close/reopen, external reload, and different-length Unicode documents. Ensure undo still works within one tab.

### 2. HIGH — Saved-file session snapshots discard unsaved edits

**User-visible failure:** after an interrupted session, restoration of a named tab loads its old disk contents, marks it clean, and loses the edited buffer even when a snapshot was explicitly captured.

**Minimal failing test:** open a file containing `Disk baseline`; set its session buffer to `Unsaved work`; call saveSession(managers:); restore into a new manager. Actual text is `Disk baseline`, isDirty is false. `namedDirtyDocumentRecoversUnsavedBuffer` at diagnostic line 10 reproduces this through the real managers and temporary disk file.

**Expected/actual:** captured recovery state retains the unsaved buffer and dirty status. Actual: only disk contents survive.

**Root cause:** `Sources/Lucid/Services/SessionRestorationManager.swift:54–61` explicitly assigns draftText=nil for every named file. Restoration at lines 258–270 reloads disk text as both buffer and baseline. Deleted named files are additionally excluded by lines 197–199. The normal in-window open path bypasses FileDocument's ownership for additional tabs, so native document autosave cannot be relied on to recover all these buffers.

**Suggested fix:** persist dirty named buffers with their baseline/encoding and reconcile them with disk on recovery. Retain recoverable drafts when the file disappeared. Schedule durable, coalesced recovery snapshots after edits rather than relying solely on tab operations/termination.

**Verify:** the failing test, followed by force-quit/relaunch for active and inactive named tabs, unsaved drafts, deleted files, and external changes after snapshot. Full process-crash recovery was not executed; the snapshot-to-restore loss itself is confirmed.

### 3. HIGH — Window restoration repeatedly selects the first window

**User-visible failure:** a saved multi-window session cannot recover all distinct window/tab sets through the restoration implementation; restoring a second manager copies the first window again. Drafts belonging to other records remain inaccessible through this path.

**Minimal failing test:** save managers A (`Window A`) and B (`Window B`) in one snapshot; restore two fresh managers. Both receive `Window A`. `restoringTwoWindowsRetainsBothDistinctTabSets`, diagnostic line 26, fails with the second buffer equal to `Window A`.

**Expected/actual:** each saved window restores its own tab set once. Actual: each restore uses the same first record.

**Root cause:** `Sources/Lucid/Services/SessionRestorationManager.swift:251` unconditionally uses snapshot.windows.first. There is no consumed-record tracking or orchestration creating the other saved windows. `Sources/Lucid/Views/MainWindowView.swift:299–313` invokes this same operation when an empty document window appears.

**Suggested fix:** coordinate restoration once at application startup; recreate all saved windows and bind each to its own restoration record. Ordinary New Window must start fresh. Track records consumed during that launch.

**Verify:** the failing test and full quit/relaunch with two distinct multi-tab windows, active-tab/cursor state, draft content, and a subsequent New Window. The model restoration failure is confirmed; full OS multi-window relaunch was not completed.

### 4. HIGH — Cancelling quit leaves earlier tabs removed

**User-visible failure:** an aborted quit still closes tabs that were handled by earlier save prompts, changing the current session and discarding their tab state.

**UI reproduction (fresh optimized build):** edit A and B in one window; quit. After the native Untitled prompt described below, the custom prompt asks about A. Choose Save for A; choose Cancel for B. Lucid stays running, but A's tab is gone and only B remains. A's content was saved to disk in this reproduction; no content loss is claimed for that saved tab.

**Expected/actual:** cancelling the aggregate quit retains the open tabs/session; successful saves may remain saved. Actual: earlier tabs have already been removed before the user finishes the decision.

**Root cause:** `Sources/Lucid/LucidApp.swift:328` uses closeAllTabs for termination. `Sources/Lucid/Services/WindowDocumentManager.swift:258–263` saves and immediately removes each tab, while lines 308–312 recurse and allow a later cancellation. removeSession at lines 277–290 also changes the persisted session. The same implementation is used by window close (`MainWindowView.swift:1340`).

**Suggested fix:** separate save/discard approval from removal; collect decisions across all windows, retain buffers and tab metadata until the aggregate close is approved, and preserve a pre-quit snapshot for restoration. Avoid removing clean tabs as a side effect of saving dirty tabs for termination.

**Verify:** Save A/Cancel B, Don't Save A/Cancel B, multi-window cancellation, failed save, and successful quit/relaunch. Verify tab order and reading/cursor state as well as disk content.

### 5. MEDIUM — Lucid mistakes its own save for an external edit

**User-visible failure:** a rapid edit immediately after Save can produce a misleading “changed on disk” conflict. Reload from Disk then discards the edits made after saving, despite no other application modifying the file.

**Minimal failing test:** open a named file, make its tab inactive to avoid blocking on a modal; edit it, saveSession (atomic write), immediately edit again before yielding the main actor. After 600 ms, hasExternalConflict is true and lastExternalDiskText contains Lucid's own saved text. `ownAtomicSaveDoesNotCauseExternalConflict`, diagnostic line 40, uses the actual FileWatcher callback. The paired clean external-write test passes.

**Expected/actual:** disk equal to savedBaselineText should not conflict with newer local edits. Actual: disk is compared only to the current buffer.

**Root cause:** `Sources/Lucid/Services/WindowDocumentManager.swift:398–418` ignores only disk==session.text; it never ignores disk==savedBaselineText. Atomic saving at lines 329–331 triggers asynchronous vnode callbacks after the user can have edited again.

**Suggested fix:** use a three-way comparison of saved baseline, current buffer and latest disk text; ignore unchanged baseline/self-save notifications without clearing genuine outstanding conflicts.

**Verify:** the diagnostic, active-tab Save-and-type, rapid repeated saves, and genuine divergent external writes. Confirm no false alerts and no missed real conflicts.

### 6. MEDIUM — Identical Markdown can show another tab's relative image

**User-visible failure:** two documents in different directories with identical Markdown, such as `![Image](image.png)`, can keep displaying the first document's image after switching to the second.

**Minimal failing test:** the real PreviewWebView representable, Coordinator, custom asset handler and shipped WebEngine render an image with naturalWidth=1 in directory A. Change documentFileURL to B, which has the same Markdown but a width=2 image. After the update, naturalWidth remains 1. Initial loading is explicitly asserted and passes. `sameMarkdownTabSwitchReloadsRelativeImages`, diagnostic line 89, reproduces this in real WebKit. The SwiftPM host has no app-bundle engine, so the test explicitly loads the repository's exact engine into the component.

**Expected/actual:** assets resolve afresh against B. Actual: the existing DOM/image stays from A.

**Root cause:** `Sources/Lucid/Views/PreviewWebView.swift:285–290` considers only Markdown equality and visibility when deciding to render. Its custom scheme resolver consults the current document directory (lines 146–149), but changing that closure's base does not reload an image already loaded under the identical lucid-asset URL. PreviewRenderCoordinator also deduplicates unchanged Markdown.

**Suggested fix:** include document identity/asset base in the render key and force a new render on document changes; make asset URLs/cache identity document specific if required to prevent WebKit resource reuse.

**Verify:** this test plus real tab switching between identical-text documents with different same-named images, Save As into another folder, hidden/revealed preview, and export comparison.

## Observed integration issue requiring further root-cause verification

**Medium, suspected integration cause:** quitting or Close Window showed AppKit's native “Do you want to keep this new document ‘Untitled’?” Save/Delete panel before Lucid's named-tab prompts. This happened both in the supplied 1.0.7 bundle copy and the freshly compiled optimized copy, including a window holding named-file tabs. The user-visible extra prompt is observed, but the precise AppKit/SwiftUI interception sequence was not verified under the original production bundle identity. Keep this separate from the six confirmed root-cause findings.

Evidence points to mixed ownership: `MainWindowView.swift:86–90` conditionally mirrors an active buffer into the FileDocument; tab-owned files can live in an untitled native document shell, while `LucidApp.swift:303–335` implements a separate later termination review. Verify native document change-count/autosave state and the SwiftUI quit path under the original identity before choosing a fix. Expected exit should ask about actual dirty tabs once. Do not simply suppress native prompts until tab protection is verified.

## Checks and results

- Existing Swift suite: **91 tests / 17 suites passed** outside the execution sandbox. Includes real WebKit integration, decoding, editor input, outline, file watcher, image assets, clipboard, recents, pane/view state, preferences and restoration.
- All six Node suites passed: heading tracking (7), Mermaid (17), outline parity (1), renderer conformance (16), security/engine gating (13), theme concurrency/performance (8).
- Branch-flow policy: **23 cases passed**.
- Website tests: **14 tests / 3 files passed**. Release validator passed using `node --import tsx scripts/validate-release.ts` (tsx CLI's IPC was denied inside sandbox).
- Focused audit suite: **6 tests: 5 failed as intended, 1 passed**, with six failed expectations total. Five model/AppKit/WebKit defects reproduced; quit cancellation was verified separately through UI.
- Fresh optimized arm64 build succeeded with the SDK workaround described by the repository. Both original app and corrected temporary fresh app passed deep/strict code-signature verification. Info.plist lint passed.
- Canonical 1.0.7 DMG: size 6,743,060 bytes and SHA-256 `175805b93b16a693ac59989d71b53b2ffccf49f29ddd519a0727c327efee7d25` match release metadata; Ed25519 signature verified against Info.plist's public key without accessing private keys.
- Live appcast version 1.0.7/build 8, URL, size, signature and minimum OS matched local configuration. GitHub download followed redirects to HTTP 200 with matching Content-Length. No update was installed.
- Native UI: isolated first launch/empty state, Start Writing, new/open tabs, saved-file editor/reader, keyboard tab switching, save, Undo, Open Recent, New Window, quit prompts and cancellation. Used only temporary documents. UI input/panel timing occasionally required refreshing the target or direct file double-click; those automation artifacts are not reported as Lucid bugs.

Initial sandboxed Swift runs could not access cache/XPC services, produced clipboard/type-service errors, and stalled. They were stopped and replaced by the successful unsandboxed run; these environment failures are not product findings. Release compilation's symbol-generation step likewise required execution outside the sandbox.

## Limits / remaining release validation

Not completed: macOS 14/15 testing; notarized/quarantined first install and App Translocation; actual Sparkle download/install/relaunch from a previous release; update interruption/rollback; sleep/wake and OS shutdown; long-duration background/resource pressure; intentional connectivity loss in updater UI; permission-denied save/image/export dialogs; full process-crash and OS multi-window restoration; comprehensive PDF/HTML export visual inspection; Finder drag-and-drop across every supported image format. Source inspection and existing tests cover parts of these paths but do not substitute for end-to-end checks. No crash or deadlock was confirmed in exercised paths.

Diagnostic copies had separate bundle identifiers so production Lucid preferences and documents were not used. No private signing key was read. The canonical DMG and repository Lucid.app were not overwritten. All retained artifacts are in this ignored `scratch/stable-audit/` directory. `run-diagnostics.sh` stages this test source without overwriting an existing file, runs the filtered suite, and removes the staged file on exit. It requires macOS services outside restrictive execution sandboxes. Expected current result is failure until the production bugs are fixed.
