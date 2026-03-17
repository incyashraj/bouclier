"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

// The simple dot and line classes match the new architecture
const GridCross = ({ className = "" }: { className?: string }) => (
  <div className={`crosshair font-mono opacity-50 ${className}`}>+</div>
);

const links = [
  { href: "/dashboard", label: "My Agents" },
  { href: "/dashboard/grant", label: "New Grant" },
  { href: "/dashboard/audit", label: "Audit Ledger" }
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();

  return (
    <div className="flex min-h-screen flex-col bg-background font-sans text-text">
      {/* Navbar Matrix - Matching landing page */}
      <header className="relative border-b border-border w-full h-[80px]">
        <div className="max-w-[1400px] w-full mx-auto h-full px-6 flex items-center justify-between border-x border-border relative bg-surface">
          <GridCross className="top-full left-0 z-10" />
          <GridCross className="top-full right-0 z-10" />
          
          <div className="flex items-center gap-10">
            <div 
              onClick={() => router.push("/")}
              className="flex items-center gap-1 cursor-pointer font-bold text-2xl tracking-tighter"
            >
              <span className="w-4 h-[3px] bg-text rounded-sm inline-block mb-1"></span>
              bouclier.eth
            </div>

            <nav className="hidden md:flex items-center gap-8 text-[13px] font-semibold tracking-wide uppercase text-text-muted">
              {links.map((l) => (
                <Link
                  key={l.href}
                  href={l.href}
                  className={
                    pathname === l.href
                      ? "text-accent transition-colors"
                      : "hover:text-text transition-colors"
                  }
                >
                  {l.label}
                </Link>
              ))}
            </nav>
          </div>

          <ConnectButton 
             showBalance={false} 
             chainStatus="icon"
          />
        </div>
      </header>

      {/* Page content strictly bounded inside the borders */}
      <main className="w-full relative flex-1">
        <div className="max-w-[1400px] w-full min-h-[calc(100vh-80px)] mx-auto border-x border-border relative bg-background">
          {children}
        </div>
      </main>
    </div>
  );
}