/** Prepared source candidate. Public downloads and Sparkle use currentRelease only. */
export const pendingRelease = {
  version: "1.0.8",
  buildNumber: 9,
  status: "Awaiting stable qualification. This version is not available for download yet.",
  highlights: [
    "Editing and Undo/Redo stay with the displayed tab, including rapid tab changes.",
    "Recover unsaved edits in named files and separate windows, including drafts whose original file disappeared.",
    "Cancelling close or quit keeps every tab available; failed saves preserve unsaved text.",
    "Save follows same-volume file moves and asks for a destination when the original file cannot be identified.",
    "Local images refresh when switching documents, returning to replaced assets, or revealing the preview.",
    "Smoother sidebar toggles and resizing preserve filter text, editor focus, reading position, and find matches. Open windows resize their sidebars independently.",
  ],
};
