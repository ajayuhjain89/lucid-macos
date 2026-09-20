"use client";

import { useEffect } from "react";
import { Button } from "@/components/ui/button";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log client-side error to console for debugging
    console.error("Application error:", error);
  }, [error]);

  return (
    <div className="py-24 md:py-36 px-6 text-center max-w-xl mx-auto space-y-6">
      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary">
        <span>Error</span>
        <span>•</span>
        <span>Something went wrong</span>
      </div>
      <h1 className="text-3xl md:text-4xl font-semibold tracking-tight text-text-primary">
        An unexpected error occurred.
      </h1>
      <p className="text-sm text-text-secondary leading-relaxed">
        {error.message || "A client-side exception was encountered while rendering this page."}
      </p>
      <div className="flex items-center justify-center gap-4 pt-4">
        <button
          onClick={() => reset()}
          className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-mac bg-text-primary text-surface hover:opacity-90 transition-opacity"
        >
          Try Again
        </button>
        <Button variant="secondary" size="md" href="/">
          Return Home
        </Button>
      </div>
    </div>
  );
}
