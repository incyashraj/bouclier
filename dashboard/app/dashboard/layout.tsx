"use client";

import { useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Menu, X } from "lucide-react";

// The simple dot and line classes match the new architecture
const GridCross = ({ className = "" }: { className?: string }) => (
  <div className={`crosshair font-mono opacity-50 ${className}`}>+</div>
);

const links = [
  { href: "/dashboard", label: "My Agents" },
  { href: "/dashboard/grant", label: "New Grant" },
  { href: "/dashboard/audit", label: "Audit Ledger" },
  { href: "/dashboard/team", label: "Team" },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileOpen, setMobileOpen] = useState(false);

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

          <div className="flex items-center gap-3">
            <ConnectButton 
               showBalance={false} 
               chainStatus="icon"
            />
            {/* Mobile hamburger */}
            <button
              className="md:hidden p-2 text-text-muted hover:text-text transition-colors"
              onClick={() => setMobileOpen(!mobileOpen)}
              aria-label="Toggle navigation"
            >
              {mobileOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>

        {/* Mobile dropdown */}
        {mobileOpen && (
          <div className="md:hidden absolute top-full left-0 right-0 z-50 border-b border-border bg-surface shadow-lg">
            <nav className="max-w-[1400px] mx-auto flex flex-col border-x border-border">
              {links.map((l) => (
                <Link
                  key={l.href}
                  href={l.href}
                  onClick={() => setMobileOpen(false)}
                  className={`px-6 py-4 text-[13px] font-semibold tracking-wide uppercase border-b border-border last:border-b-0 transition-colors ${
                    pathname === l.href
                      ? "text-accent bg-accent/5"
                      : "text-text-muted hover:text-text hover:bg-surface"
                  }`}
                >
                  {l.label}
                </Link>
              ))}
            </nav>
          </div>
        )}
      </header>

      {/* Page content strictly bounded inside the borders */}
      <main className="w-full relative flex-1">
        <div className="max-w-[1400px] w-full min-h-[calc(100vh-80px-48px)] mx-auto border-x border-border relative bg-background">
          {children}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border bg-surface">
        <div className="max-w-[1400px] mx-auto border-x border-border px-6 py-3 flex items-center justify-between text-[10px] font-mono tracking-wider text-text-muted uppercase">
          <span>Bouclier Protocol · Base Sepolia</span>
          <div className="flex items-center gap-4">
            <a href="https://github.com/incyashraj/bouclier" target="_blank" rel="noopener noreferrer" className="hover:text-text transition-colors">GitHub</a>
            <a href="https://sepolia.basescan.org" target="_blank" rel="noopener noreferrer" className="hover:text-text transition-colors">Basescan</a>
            <span>v1.0.0</span>
          </div>
        </div>
      </footer>
    </div>
  );
}