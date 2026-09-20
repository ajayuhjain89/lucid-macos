import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="py-24 md:py-36 px-6 text-center max-w-xl mx-auto space-y-6">
      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary">
        <span>404</span>
        <span>•</span>
        <span>Page Not Found</span>
      </div>
      <h1 className="text-3xl md:text-4xl font-semibold tracking-tight text-text-primary">
        This page does not exist.
      </h1>
      <p className="text-sm text-text-secondary leading-relaxed">
        The link you followed may be broken or the page may have been moved.
      </p>
      <div className="flex items-center justify-center gap-4 pt-4">
        <Button variant="primary" size="md" href="/">
          Return Home
        </Button>
        <Button variant="secondary" size="md" href="/download">
          Download Lucid
        </Button>
      </div>
    </div>
  );
}
