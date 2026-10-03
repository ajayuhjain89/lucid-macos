# Working with documents in the pending 1.0.8 candidate

These improvements are prepared for 1.0.8 and are not in the published 1.0.7 download yet.

## Tabs and closing

Each tab has its own edits and Undo/Redo history. Save applies to the displayed document.
Closing a window or quitting reviews unsaved tabs. Cancel keeps all tabs open, even if
an earlier tab was marked Don't Save. Saves completed before cancellation remain saved.
A failed save leaves the edited buffer available.

## Save destinations

Lucid follows an open file when it is renamed or moved on the same volume. If the original
file was deleted, replaced ambiguously, or moved across volumes, Save asks for a destination.
Cancelling that panel preserves the draft. Use Save As to explicitly choose a new location.
An external change that differs from both your current text and saved baseline requires
review; Lucid's own save does not create a false conflict with subsequent typing.

## Interrupted sessions

Recovery retains separate windows and unsaved named-file buffers, including drafts whose
original file is missing. Opening a different file during launch does not erase pending
recovery. Save recovered text to disk before relying on it as a durable copy. Snapshots are
coalesced and preferences are persisted asynchronously, so immediate termination or power
loss can lose the most recent keystrokes.

## Outline and images

Toggle the outline with Control-Command-S. Its filter remains available across toggles.
Drag the divider or use its accessibility increment/decrement actions to resize it.
Existing windows keep independent widths; the last chosen width seeds new windows.
Document position and find matches are preserved through layout changes.
Relative images resolve against their own document folder and refresh when the preview
renders or becomes visible. Lucid does not promise continuous monitoring of image-only edits
while an unchanged preview remains visible.
