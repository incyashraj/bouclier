import Link from "next/link";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center">
        <div className="flex items-center justify-center gap-2 mb-8">
          <span className="w-6 h-[4px] bg-accent rounded-sm inline-block" />
          <span className="font-bold text-xl tracking-tighter">bouclier.eth</span>
        </div>

        <div className="border border-border bg-surface p-8 rounded-sm">
          <p className="font-mono text-[80px] font-bold text-border leading-none mb-4">
            404
          </p>
          <h1 className="text-2xl font-bold tracking-tight mb-3">
            Page not found
          </h1>
          <p className="text-sm text-text-muted mb-6 leading-relaxed">
            The page you&apos;re looking for doesn&apos;t exist or has been moved.
          </p>
          <Link
            href="/"
            className="inline-block px-6 py-2.5 bg-accent text-white text-sm font-semibold uppercase tracking-wider hover:bg-accent-hover transition-colors rounded-sm"
          >
            Back to Home
          </Link>
        </div>
      </div>
    </div>
  );
}
