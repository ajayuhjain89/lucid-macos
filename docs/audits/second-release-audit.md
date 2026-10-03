> **Fix update — 2026-10-02:** All four confirmed defects now have implemented fixes and passing original reproductions. See [fix verification](second-release-audit-fixes.md) for permanent regression coverage, final verification and remaining release-hold limitations. The audit below describes the preserved pre-fix working tree.

# Independent second release audit — Lucid

2026-10-02, `logic` at `acc1b1a`, including the existing uncommitted fixes. Host: Apple Silicon, macOS 27.0.1 (26A434). Read the first audit's FIXES.md, repository contribution/branch instructions, every changed production file, the new DocumentCloseReview and regression suite, and callers before testing.

**Release recommendation: hold. Two reproducible data-loss paths remain.** Four actionable defects are confirmed below. These are remaining failures or uncovered workflows, not a claim that all four were newly introduced by the patches. No additional regression attributable solely to a recent fix was established.

No production code was changed. Original source and regression-test hashes still match `original.sha256`, the original diff is retained, and final Git status matches the initial status. Diagnostics were temporarily copied into the test target by `run-diagnostics.sh` and removed automatically. Only ignored scratch evidence and local build artifacts were created/updated. The canonical 1.0.7 DMG remains unchanged.

## Confirmed defects, severity order

### 1. P1 / High — editing before the coordinator refresh still overwrites another tab

**Blocks release: yes.** A rapid tab selection followed by an edit can replace the new tab's entire buffer with the old tab's text. The overwrite has no undo action in the destination tab's history; saving can persist the wrong content.

**Exact failing test:** `keyEventBeforeCoordinatorRefreshMustStayInDisplayedTab`, `SecondReleaseAuditTests.swift:10`. Each completed run executes 25 controlled repetitions. It failed in all 25 on each of five completed runs.

1. Create A containing `Document A 0` and B containing `Document B 0`.
2. Display A with a real LucidTextView and EditorView.Coordinator. Use MainWindowView's actual binding pattern: get/set `manager.activeSession.text`.
3. Select B on the manager, without yielding for SwiftUI's onChange/updateNSView.
4. Deliver native insertText(`!`) to the still-displayed A editor.
5. Assert both buffers and both undo managers.

**Expected:** A becomes `Document A 0!`; B remains `Document B 0`. **Actual:** A remains `Document A 0`; B becomes `Document A 0!`. Undo is registered in A, not B.

**Root cause:** `Sources/Lucid/Views/EditorView.swift:327–337` routes to the session only when the displayed session differs from `parent.documentSession`. In this earlier ordering, both still equal A, so line 336 writes through the binding. That binding, at `Sources/Lucid/Views/MainWindowView.swift:76–85`, resolves the already-selected B dynamically. The permanent regression updates the coordinator parent to B before the event and covers only the later timing boundary.

**Suggested fix:** make text writes target the displayed session unconditionally when one exists, or capture a stable session in the binding. Audit cursor/save/image callbacks for the same identity boundary without dropping normal window notifications.

**Verification:** retain both timing-order tests; interleave edits, Undo/Redo, selection and Save across different-length named and untitled buffers. Assert destination contents, saved bytes, recovery snapshots and session-specific undo histories.

### 2. P1 / High — a named native document can cause unhydrated recovery to be overwritten

**Blocks release: yes.** If a named NSDocument exists before Lucid loads its previous snapshot, the next autosnapshot removes the previous unsaved recovery drafts. This is a startup-order-dependent data-loss path, not the already-fixed draft serialization failure.

**Exact failing test:** `explicitFileLaunchMustRetainUnhydratedRecovery`, `SecondReleaseAuditTests.swift:39`.

1. Persist a window containing `UNSAVED RECOVERY DRAFT` using the real restorer.
2. Add a named NSDocument to NSDocumentController before attempting hydration, representing the file-first launch ordering.
3. Register the manager containing that explicitly opened file.
4. Invoke restoreInto, then saveCurrentSession, as the launch/view-mode autosnapshot path does.
5. Inspect the persisted snapshot for the original draft.

**Expected:** opening another file may defer recovery, but the unhydrated draft remains recoverable. **Actual:** restoreInto returns false; the next snapshot contains only the newly opened document. The old draft no longer exists in saved recovery data.

**Root cause:** `Sources/Lucid/Services/SessionRestorationManager.swift:318–324` returns for any named native document before initializing `remainingRestorationWindows`. Preservation at line 289 therefore appends nothing; saveCurrentSession at lines 207–211 replaces the persisted snapshot. The corresponding native-document guard in `Sources/Lucid/Views/MainWindowView.swift:282–285` can skip restoreInto altogether, while onAppear publishes session view state at lines 294–296, scheduling the new recovery autosave.

**Evidence boundary:** the loss is deterministic through the real persistence/controller APIs. The Finder Open With native run happened in the opposite order and preserved both drafts plus the opened file. A packaged-app failure under forced file-first startup timing was not established; ordinary Finder launch is not claimed to fail every time.

**Suggested fix:** capture/protect persisted recovery independently of the native-document restoration decision, before any replacement autosnapshot. Defer or present recovered drafts without silently deleting them when a launch file is supplied.

**Verification:** exercise both file-first and recovery-first orderings, native named-window restoration, Finder multi-file launch, pending multiple windows, cancellation, and interruption between hydration steps. Assert the persisted draft contents even when no recovery window is displayed.

### 3. P2 / Medium — externally moving a document makes Save recreate its old path

**Blocks release alone: no; fix before a stable release is recommended.** Users see a successful save, but reopening the moved document shows the old content. The edited version is silently written to an abandoned filename.

**Exact failing test:** `externalRenameMustNotSilentlySaveToAbandonedPath`, `SecondReleaseAuditTests.swift:181`, repeated successfully as a failure in the diagnostic runs. Also reproduced in the signed app extracted from the fresh local DMG:

1. Open `native-original.md` containing `NATIVE MOVE BASELINE\n` in Lucid's editor.
2. Move it externally to `native-moved.md`; allow file events to settle.
3. Replace the editor contents with `NATIVE EDIT AFTER MOVE` and press Command-S.
4. Read both files from disk.

**Expected:** follow the same file to its new URL, or require an explicit destination decision if the file can no longer be resolved. **Actual:** Save succeeds without a warning, recreates `native-original.md` containing the edit, and leaves `native-moved.md` at `NATIVE MOVE BASELINE\n`.

**Root cause:** `Sources/Lucid/Services/FileWatcher.swift:48–52` reconnects at the immutable old URL on rename. `Sources/Lucid/Services/WindowDocumentManager.swift:350–352` silently returns when that URL disappears. No session URL/state update occurs, and saveSession at lines 279–285 atomically writes and marks saved at that stale URL.

**Suggested fix:** follow file identity/bookmarks when moved, update the session and watcher URLs, and surface unavailable originals before silently recreating a previously opened document. Keep explicit user-requested recreation available.

**Verification:** same-directory rename, move to another directory/volume, deletion, destination permissions, and dirty inactive tabs. Assert the actual destination bytes and original-path absence, not just save completion.

### 4. P2 / Medium — revisiting a document can show an obsolete replacement image

**Blocks release alone: no; fix before a stable release is recommended.** The initial A→B image-identity fix passes, but returning to a document after its asset changes can still display the previous image.

**Exact failing test:** `replacedImagesStayCurrentAcrossRepeatedNavigation`, `SecondReleaseAuditTests.swift:218`. Uses the actual PreviewWebView representable, coordinator, scheme handler and repository WebEngine in real WebKit.

1. Render A with `![Image](image.png)` and a width-1 PNG.
2. Navigate to B with the same Markdown but its own PNG.
3. Atomically replace A's image with a width-4 PNG while away.
4. Navigate back to A, including hidden/revealed preview transitions.
5. Wait 500 ms and assert `window.lucid.documentIdentity` and the rendered image's naturalWidth.
6. Repeat navigation and replacements ten times.

**Expected:** identity is A and naturalWidth is 4. **Actual:** identity is correctly A, but naturalWidth remains 1. Later returns similarly retain cached widths (for example B remains 3 when its replacement is 5). The final run had eight dimension failures across ten transitions; every document-identity assertion passed. Earlier 200 ms and 500 ms runs reproduced the stale assets as well.

**Root cause:** `Sources/Lucid/Resources/WebEngine/bridge.js:379–381` varies the relative asset URL by document path only. Returning to the same document reuses the same URL despite replacing the underlying asset. `Sources/Lucid/Services/PreviewRenderCoordinator.swift:144–159` sends the correct identity/render, but the reused resource key allows WebKit's cached image to survive. The native response in `Sources/Lucid/Views/PreviewWebView.swift:572–589` adds no asset-version identity or explicit invalidation.

**Suggested fix:** version local asset requests by an appropriate render/asset generation, or reliably invalidate their WebKit resource cache. Include absolute assets and Save As/navigation in the policy.

**Verification:** assert pixels or dimensions for rewritten assets on A→B→A, repeated replacement, Editor/Reader transitions, unusual paths, absolute images and export comparison. A document-identity check alone is insufficient.

## Verification and workflow coverage

| Workflow | Current evidence |
| --- | --- |
| Baseline Swift tests | 106 tests / 18 suites passed, including all 15 existing stable-release regressions. |
| Independent diagnostics | Final run: 9 tests; 5 passed, 4 failed for the confirmed defects. Logs retain exact expected/actual values. |
| Editing/tab switching | Earlier coordinator-refresh ordering fails deterministically; existing later-boundary and per-tab Undo tests pass. |
| Undo/Redo across save/reload | Native NSTextView with Unicode: Save, switch away/back, Undo becomes dirty, Redo matches saved contents; clean external replacement clears stale Undo/Redo. Passed. |
| Recovery | Empty dirty UTF-16 draft with deleted original, old-schema snapshots, large Unicode named draft and separate window all passed. File-first hydration/persistence ordering fails. |
| Large/unusual documents | 20,000 repetitions of multi-line Unicode/CRLF/tab content round-trip through recovery and disk; a filename with spaces, Chinese characters, #, %, and café. Passed. This is a content check, not a large-document responsiveness benchmark. |
| External edits | Five genuine divergence→baseline-reversion cycles preserve local text and baseline and set/clear conflict state appropriately; existing self-save and clean-reload tests pass. |
| Close/quit | Native restored-window Command-Shift-W and red close button present review; Cancel retains draft. Across-window discard-then-cancel quit preserves all captured drafts in the successful replay. Permanent staged-discard/failed-save/repeated-review tests pass. |
| Real denied write | Signed app with fixture directory mode 0555: Save reports permission failure; Save during close review also fails; window and edited buffer survive. Disk retains previous contents and recovery retains `UNSAVED AFTER DENIED WRITE`. Permissions were restored. |
| Save As cancellation | Original URL and dirty contents survive native panel cancellation. |
| Image/navigation interactions | Initial distinct-document identity regression passes; repeated replaced-image returns fail with matching identities and stale dimensions. |
| Renderer/website/policy | Six Node suites: 62 assertions passed. Branch policy: 23 scenarios passed. Website: 14 tests passed. Canonical release validator passed. |
| Build/package | Supported build succeeded using macOS 26.5 SDK and isolated module caches. Fresh arm64 app and local DMG created. App, mounted fresh DMG app and shipped DMG app pass strict/deep code-signature checks; mounted fresh executable equals built executable; plist lint passes. Both DMGs mounted read-only and were detached afterward. |
| Compatibility metadata | App Mach-O minimum macOS 14.0; Info.plist minimum 14.0; bundled Sparkle minimum 12.0. Metadata is consistent, but older-OS runtime compatibility was not tested. |
| Manual upgrade | Old signed 1.0.7 DMG copy generated an actual old-schema multi-window snapshot and persisted sepia/font-size-19 settings. Replaced only the isolated bundle with the current DMG app, preserving its disposable identity/data. Successful replay restored all four captured draft buffers across three native windows, including Unicode, and settings; snapshot contents matched after close/quit cancellation. This was manual replacement, not a Sparkle installation. |

Sparkle's official [upgrade documentation](https://sparkle-project.org/documentation/upgrading/) confirms 2.10 requires macOS 12+. Apple's [LSMinimumSystemVersion documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/LSMinimumSystemVersion) describes the app's declared minimum; neither declaration proves runtime support on every macOS release.

Canonical `Lucid-1.0.7.dmg` still has SHA-256 `175805b93b16a693ac59989d71b53b2ffccf49f29ddd519a0727c327efee7d25`. The fresh bundle is ad hoc signed, as produced by build.sh; Developer ID/notarized distribution was not validated.

## Unresolved observations and validation gaps

- A quit prompt appeared attached to a background recovery window in one native sequence; selecting that window exposed it. The repeat brought the prompt forward normally. This is not a confirmed fifth defect; focus/automation/startup ordering remains unresolved.
- An initial upgrade-content mismatch followed an accessibility click on a combined tab element that could invoke its close action. Keyboard navigation replay preserved all input buffers. This observation is excluded from findings.
- Native Finder file launch preserved recovery in the tested ordering. The failing file-first ordering is established by the controller/persistence diagnostic, but its real-world occurrence rate and forced packaged startup reproduction remain unverified.
- Not run on macOS 14, 15, or 26. No other OS installations/VMs were available in this audit. No Intel support is claimed; Lucid advertises arm64.
- No live signed Sparkle download/install/relaunch, rollback, updater interruption, quarantined/notarized first launch, or App Translocation validation. Previous shipped artifact was available and used; a Developer ID/notarized candidate and alternate OS environments were not available here.
- No power loss, physical sleep/wake, long resource-pressure run, exhaustive pending Save As/Open/export ordering, denied-read/TCC workflow, or cross-volume move test. Debounced UserDefaults snapshots do not prove zero lost keystrokes on immediate kill/power loss.
- PDF/HTML/rich-text export code and existing tests were reviewed/run where included, but a full native export visual/content matrix was not performed.
- The diagnostic-host permission-error modal could not be dismissed reliably by the diagnostic timer. Its test was removed from the runnable suite and retained separately as `DeniedWriteDiagnostic.swift.txt`; a stack sample shows waiting in the expected NSAlert runModal. The same failure workflow was then verified through the actual signed app UI. This harness problem is not a product finding.

## Reproduction artifacts and preservation

Run `scratch/second-release-audit/run-diagnostics.sh` with native macOS service access to stage the isolated test source temporarily. It refuses to overwrite an existing diagnostic filename and removes its staged file on exit. It is expected to fail until the four defects are addressed. Source: `SecondReleaseAuditTests.swift`; decisive output: `diagnostics-final.log`; earlier repetitions: `diagnostics-1.log` through `diagnostics-4.log`.

Build and baseline logs, renderer/website/policy logs, original source hashes/diff, old/upgraded disposable settings snapshots, native final recovery snapshot and the modal stack sample are retained in this directory. All disposable app processes were stopped and test images detached. Installed Lucid preferences and documents were not used or changed.

**Do not promote this candidate to stable with the two P1 defects present.** After fixing them, retain both editor event orderings and recovery startup orderings as permanent assertions, address the two P2 failures, rebuild and test the actual distribution package, then complete the supported-OS and real upgrade checks. Passing baseline tests and the successful workflows above are useful evidence, not a guarantee that the app is bug-free.
