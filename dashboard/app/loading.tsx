export default function Loading() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="flex items-center gap-2">
          <span className="w-6 h-[4px] bg-accent rounded-sm inline-block animate-pulse" />
          <span className="font-bold text-xl tracking-tighter">bouclier.eth</span>
        </div>
        <div className="flex items-center gap-2 text-sm font-mono text-text-muted">
          <span className="relative flex h-2.5 w-2.5">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-accent opacity-75" />
            <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-accent" />
          </span>
          Loading...
        </div>
      </div>
    </div>
  );
}
