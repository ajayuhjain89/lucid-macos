/** Prepared source candidate. Public downloads and Sparkle use currentRelease only. */
export interface PendingRelease {
  version: string;
  buildNumber: number;
  status: string;
  highlights: string[];
}

/** Set while a candidate awaits qualification; null when nothing is pending. */
export const pendingRelease: PendingRelease | null = null;
