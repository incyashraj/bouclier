"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Menu, X } from "lucide-react";

const GridCross = ({ className = "" }: { className?: string }) => (
  <div className={`crosshair font-mono opacity-50 ${className}`}>+</div>
);

export function MarketingNav() {
  const router = useRouter();
  const [mobileOpen, setMobileOpen] = useState(false);

  const navLinks = [
    { label: "Protocol", href: "/protocol" },
    { label: "Registry", href: "/registry" },
    { label: "Nodes", href: "/nodes" },
    { label: "Audits", href: "/audits" },
    { label: "Compare", href: "/compare" },
    { label: "Developers", href: "/developers" },
    { label: "Docs", href: "/docs" },
    { label: "Pricing", href: "/pricing" },
    { label: "GitHub", href: "/github" },
    { label: "Bug Bounty", href: "/bug-bounty" },
  ];

  return (
    <>
      <div className="relative border-b border-border w-full h-[80px]">
        <div className="max-w-[1400px] w-full mx-auto h-full px-6 flex items-center justify-between border-x border-border relative bg-background z-50">
          <GridCross className="top-full left-0 z-10" />
          <GridCross className="top-full right-0 z-10" />
          
          <div 
            className="flex items-center gap-1 cursor-pointer font-bold text-2xl tracking-tighter hover:text-accent transition-colors" 
            onClick={() => router.push('/')}
          >
            <span className="w-4 h-[3px] bg-text rounded-sm inline-block mb-1"></span>
            bouclier.eth
          </div>

          {/* Desktop nav */}
          <div className="hidden lg:flex items-center gap-10 text-[13px] font-semibold tracking-wide uppercase text-text-muted">
            <div className="relative group p-4 -m-4 cursor-pointer">
              <span className="hover:text-text transition-colors flex items-center group-hover:text-text">
                Product <span className="ml-1 text-[10px]">▼</span>
              </span>
              <div className="absolute top-full left-0 mt-0 w-48 bg-surface border border-border opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 flex flex-col shadow-2xl">
                <Link href="/protocol" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Protocol</Link>
                <Link href="/registry" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Registry</Link>
                <Link href="/nodes" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Nodes</Link>
                <Link href="/audits" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Audits</Link>
                <Link href="/compare" className="px-4 py-3 hover:bg-body hover:text-accent transition-colors">Compare</Link>
              </div>
            </div>

            <div className="relative group p-4 -m-4 cursor-pointer">
              <span className="hover:text-text transition-colors flex items-center group-hover:text-text">
                Resources <span className="ml-1 text-[10px]">▼</span>
              </span>
              <div className="absolute top-full left-0 mt-0 w-48 bg-surface border border-border opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 flex flex-col shadow-2xl">
                <Link href="/developers" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Developers</Link>
                <Link href="/docs" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">Documentation</Link>
                <Link href="/github" className="px-4 py-3 border-b border-border hover:bg-body hover:text-accent transition-colors">GitHub</Link>
                <Link href="/bug-bounty" className="px-4 py-3 hover:bg-body hover:text-accent transition-colors">Bug Bounty</Link>
              </div>
            </div>

            <Link href="/docs" className="hover:text-text transition-colors">Docs</Link>
            <Link href="/pricing" className="hover:text-text transition-colors">Pricing</Link>
          </div>

          <div className="flex items-center gap-3">
            <Button onClick={() => router.push('/dashboard')} variant="primary" size="sm" className="uppercase px-5 z-20 relative hidden sm:flex">+ Launch App</Button>
            
            {/* Hamburger */}
            <button 
              onClick={() => setMobileOpen(!mobileOpen)} 
              className="lg:hidden p-2 hover:bg-surface rounded-md transition-colors"
              aria-label="Toggle menu"
            >
              {mobileOpen ? <X size={22} /> : <Menu size={22} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-[100] lg:hidden">
          <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" onClick={() => setMobileOpen(false)} />
          <div className="absolute top-0 right-0 w-[280px] max-w-[80vw] h-full bg-background border-l border-border overflow-y-auto">
            <div className="flex items-center justify-between p-5 border-b border-border">
              <span className="font-bold text-lg tracking-tighter">Menu</span>
              <button onClick={() => setMobileOpen(false)} className="p-1"><X size={20} /></button>
            </div>
            <nav className="flex flex-col py-2">
              {navLinks.map((link) => (
                <Link 
                  key={link.href}
                  href={link.href} 
                  onClick={() => setMobileOpen(false)}
                  className="px-6 py-3.5 text-sm font-semibold uppercase tracking-wider text-text-muted hover:text-accent hover:bg-surface/50 transition-colors border-b border-border/40"
                >
                  {link.label}
                </Link>
              ))}
            </nav>
            <div className="p-5">
              <Button onClick={() => { setMobileOpen(false); router.push('/dashboard'); }} variant="primary" size="sm" className="uppercase w-full">+ Launch App</Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
