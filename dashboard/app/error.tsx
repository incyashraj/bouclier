"use client";

import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[Bouclier] Unhandled error:", error);
  }, [error]);

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center">
        <div className="flex items-center justify-center gap-2 mb-8">
          <span className="w-6 h-[4px] bg-accent rounded-sm inline-block" />
          <span className="font-bold text-xl tracking-tighter">bouclier.eth</span>
        </div>

        <div className="border border-border bg-surface p-8 rounded-sm">
          <p className="font-mono text-xs uppercase tracking-widest text-accent mb-4">
            [ERR] Runtime Exception
          </p>
          <h1 className="text-2xl font-bold tracking-tight mb-3">
            Something went wrong
          </h1>
          <p className="text-sm text-text-muted mb-6 leading-relaxed">
            An unexpected error occurred. This has been logged automatically.
          </p>
          <button
            onClick={reset}
            className="px-6 py-2.5 bg-accent text-white text-sm font-semibold uppercase tracking-wider hover:bg-accent-hover transition-colors rounded-sm"
          >
            Try Again
          </button>
        </div>

        <p className="mt-6 text-xs font-mono text-text-muted">
          {error.digest && <span>Error ID: {error.digest}</span>}
        </p>
      </div>
    </div>
  );
}
