"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { motion } from "framer-motion";
import Link from "next/link";
import { ShieldCheck, Crosshair, Code, Activity, Database, Key, Github } from "lucide-react";
import { MarketingNav } from "@/components/layout/MarketingNav";

const GridCross = ({ className = "" }: { className?: string }) => (
  <div className={`crosshair font-mono opacity-50 ${className}`}>+</div>
);

const TargetDot = ({ size = "w-3.5 h-3.5", innerSize = "w-1.5 h-1.5", active = false }) => (
  <div className={`rounded-full border flex items-center justify-center ${active ? 'border-accent' : 'border-[#D4D4D8]' } ${size}`}>
    <div className={`rounded-full ${active ? 'bg-accent' : 'bg-[#D4D4D8]'} ${innerSize}`}></div>
  </div>
);

export default function Home() {
  const router = useRouter();

  return (
    <div className="w-full min-h-screen bg-background relative overflow-hidden text-text flex flex-col justify-between">
      
      <motion.div 
        initial={{ y: -50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      >
        <MarketingNav />
      </motion.div>

      <div className="flex-1 w-full flex flex-col justify-center py-12 sm:py-20">
        <motion.div 
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="w-full flex flex-col items-center px-4"
        >
          <div className="text-xs sm:text-sm font-mono text-text-muted mb-4 uppercase tracking-widest tracking-[0.2em] flex items-center gap-2">
            Building on Base <span className="text-[10px]">›</span>
          </div>
          
          <h1 className="text-[2.5rem] sm:text-[4rem] md:text-[5.5rem] font-bold tracking-tighter text-text leading-[1] text-center">
            Trust Layer for
          </h1>
          <h2 className="text-[2.5rem] sm:text-[4rem] md:text-[5.5rem] font-mono tracking-tighter text-dotted leading-[1] text-center">
            autonomous AI
          </h2>

          <p className="mt-6 sm:mt-8 text-base sm:text-lg text-text-muted max-w-2xl text-center px-4">
            An open-source protocol to build, ship, and govern agentic systems with cryptography. Wrap your LLMs in absolute on-chain boundaries.
          </p>

          <div className="mt-8 sm:mt-10 flex flex-col sm:flex-row gap-3 sm:gap-4 w-full sm:w-auto px-4 sm:px-0">
             <Button onClick={() => router.push('/docs')} variant="outline" size="md" className="uppercase rounded-full bg-transparent border-border hover:bg-surface w-full sm:w-auto">+ Read The Docs</Button>
             <Button onClick={() => router.push('/dashboard')} variant="primary" size="md" className="uppercase rounded-full w-full sm:w-auto">+ Open Dashboard</Button>
          </div>
        </motion.div>

        {/* Control Plane Section */}
        <motion.div 
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="w-full border-y border-border relative bg-background mt-16 sm:mt-32"
        >
          <div className="max-w-[1400px] w-full mx-auto border-x border-border relative">
            <GridCross className="top-0 left-0" />
            <GridCross className="top-0 right-0" />
            
            <div className="grid grid-cols-1 lg:grid-cols-3">
              {/* Left Details */}
              <div className="lg:col-span-1 p-6 sm:p-8 lg:p-12 border-b lg:border-b-0 lg:border-r border-border bg-[#FAFAFA] flex flex-col justify-between">
                <div>
                  <div className="flex items-center gap-4 mb-4 text-xs font-mono font-bold tracking-widest text-text-muted uppercase">
                    <TargetDot active />
                    Protocol Overview
                  </div>
                  <h3 className="text-2xl sm:text-3xl font-bold tracking-tight mb-4">Govern your agents</h3>
                  <p className="text-text-muted leading-relaxed mb-8 sm:mb-12 text-sm sm:text-base">
                    Enforce cryptographic boundary constraints at the protocol level. Define hard limits on execution scopes, on-chain permissions, and spend caps through immutable policy contracts.
                  </p>
                </div>

                <div className="grid grid-cols-2 gap-x-6 sm:gap-x-8 gap-y-4 pt-8 sm:pt-12 border-t border-border mt-auto">
                   <div className="flex flex-col gap-1">
                     <span className="text-[10px] uppercase font-mono tracking-widest text-text-muted">Network</span>
                     <span className="font-bold font-mono text-sm">Base L2</span>
                   </div>
                   <div className="flex flex-col gap-1">
                     <span className="text-[10px] uppercase font-mono tracking-widest text-text-muted">License</span>
                     <span className="font-bold font-mono text-sm">MIT</span>
                   </div>
                   <div className="flex flex-col gap-1">
                     <span className="text-[10px] uppercase font-mono tracking-widest text-text-muted">Status</span>
                     <span className="font-bold font-mono text-accent text-sm">In Development</span>
                   </div>
                   <div className="flex flex-col gap-1">
                     <span className="text-[10px] uppercase font-mono tracking-widest text-text-muted">Architecture</span>
                     <span className="font-bold font-mono text-sm">EVM + ZK</span>
                   </div>
                </div>
              </div>

              {/* Right - Features */}
              <div className="lg:col-span-2 bg-surface p-6 sm:p-8 lg:p-12 relative overflow-hidden">
                <div className="absolute right-[-100px] top-[10%] w-96 h-96 opacity-5 pointer-events-none crosshair grid-pattern"></div>
                <div className="flex flex-wrap gap-4 sm:gap-8 items-start mb-8 sm:mb-12 relative z-10">
                   <span className="text-xs font-mono uppercase tracking-widest font-bold border-b-2 border-accent pb-2 text-text">Core Features</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6 relative z-10">
                  {[
                    { icon: ShieldCheck, title: "Immutable Guardrails", desc: "Smart contract policies that cannot be altered after deployment — absolute boundaries." },
                    { icon: Database, title: "Agent Registry", desc: "On-chain identity layer for registering, tracking, and revoking autonomous agents." },
                    { icon: Activity, title: "Sentinel Network", desc: "Decentralized verification nodes that validate every agent action against policies." },
                    { icon: Code, title: "Open Source", desc: "Every contract, SDK, and node is MIT licensed, auditable, and forkable." },
                  ].map((f, i) => (
                    <div key={i} className="p-5 sm:p-6 border border-border rounded-lg bg-background/50 hover:bg-background transition-colors">
                      <f.icon size={18} className="text-accent mb-3" />
                      <h4 className="font-bold text-text text-sm mb-2">{f.title}</h4>
                      <p className="text-xs text-text-muted leading-relaxed">{f.desc}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            
            <GridCross className="bottom-0 left-0" />
            <GridCross className="bottom-0 right-0" />
          </div>
        </motion.div>

        {/* Performance Section */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="w-full border-b border-border bg-background"
        >
          <div className="max-w-[1400px] w-full mx-auto border-x border-border relative">
            <GridCross className="top-0 left-0" />
            <GridCross className="top-0 right-0" />

            <div className="px-4 sm:px-8 lg:px-12 py-16 sm:py-24">
              {/* Heading */}
              <div className="flex flex-col items-center mb-14 sm:mb-20">
                <ShieldCheck size={28} className="text-text/20 mb-4" />
                <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-text text-center">
                  Performance matters
                </h2>
              </div>

              {/* Comparison 1 — Gas Cost */}
              <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)] gap-0 mb-10 sm:mb-16 border border-border rounded-lg overflow-hidden bg-surface/30">
                <div className="p-6 sm:p-8 lg:p-10 border-b lg:border-b-0 lg:border-r border-border">
                  <h3 className="text-2xl sm:text-3xl font-bold tracking-tight text-text leading-tight mb-6">
                    Cheapest agent<br className="hidden sm:block" /> verification
                  </h3>
                  <div className="space-y-3">
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">2,500×</span>
                      <span className="text-text-muted text-sm">cheaper than Ethereum L1</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">50×</span>
                      <span className="text-text-muted text-sm">cheaper than Arbitrum</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">$0</span>
                      <span className="text-text-muted text-sm">for read-only policy checks</span>
                    </div>
                  </div>
                </div>

                <div className="p-6 sm:p-8 flex flex-col justify-center">
                  <div className="flex justify-between items-end mb-2">
                    <span className="font-mono text-xs sm:text-sm font-bold"><span className="text-accent">|</span> $0.001 / Bouclier</span>
                    <span className="font-mono text-xs sm:text-sm font-bold text-text">$2.50 / Ethereum L1 <span className="text-text">|</span></span>
                  </div>
                  <div className="relative h-16 sm:h-20 overflow-hidden rounded-sm">
                    <div className="absolute inset-0" style={{
                      backgroundImage: [
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.07) 0px, rgba(17,17,17,0.07) 1px, transparent 1px, transparent 4px)",
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.14) 0px, rgba(17,17,17,0.14) 1.5px, transparent 1.5px, transparent 7px)",
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.04) 0px, rgba(17,17,17,0.04) 1px, transparent 1px, transparent 11px)",
                      ].join(", "),
                    }} />
                    <div className="absolute left-[0.8%] top-0 bottom-0 w-[2px] bg-accent z-10" />
                    <div className="absolute right-0 top-0 bottom-0 w-[2px] bg-text z-10" />
                  </div>
                  <p className="font-mono text-[11px] text-text-muted mt-3">Cost per agent registration transaction (avg.)</p>
                </div>
              </div>

              {/* Comparison 2 — Throughput */}
              <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)] gap-0 border border-border rounded-lg overflow-hidden bg-surface/30">
                <div className="p-6 sm:p-8 lg:p-10 border-b lg:border-b-0 lg:border-r border-border">
                  <h3 className="text-2xl sm:text-3xl font-bold tracking-tight text-text leading-tight mb-6">
                    Maximum<br className="hidden sm:block" /> throughput
                  </h3>
                  <div className="space-y-3">
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">133×</span>
                      <span className="text-text-muted text-sm">more capacity than L1</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">6×</span>
                      <span className="text-text-muted text-sm">faster block confirmation</span>
                    </div>
                    <div className="flex items-baseline gap-3">
                      <span className="text-accent font-bold font-mono text-xl">2s</span>
                      <span className="text-text-muted text-sm">average block time on Base</span>
                    </div>
                  </div>
                </div>

                <div className="p-6 sm:p-8 flex flex-col justify-center">
                  <div className="flex justify-between items-end mb-2">
                    <span className="font-mono text-xs sm:text-sm font-bold text-text"><span className="text-text">|</span> 15 TPS / Ethereum L1</span>
                    <span className="font-mono text-xs sm:text-sm font-bold">2,000 TPS / Bouclier <span className="text-accent">|</span></span>
                  </div>
                  <div className="relative h-16 sm:h-20 overflow-hidden rounded-sm">
                    <div className="absolute inset-0" style={{
                      backgroundImage: [
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.07) 0px, rgba(17,17,17,0.07) 1px, transparent 1px, transparent 4px)",
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.14) 0px, rgba(17,17,17,0.14) 1.5px, transparent 1.5px, transparent 7px)",
                        "repeating-linear-gradient(90deg, rgba(17,17,17,0.04) 0px, rgba(17,17,17,0.04) 1px, transparent 1px, transparent 11px)",
                      ].join(", "),
                    }} />
                    <div className="absolute left-[0.75%] top-0 bottom-0 w-[2px] bg-text z-10" />
                    <div className="absolute right-0 top-0 bottom-0 w-[2px] bg-accent z-10" />
                  </div>
                  <p className="font-mono text-[11px] text-text-muted mt-3">Network transactions per second capacity</p>
                </div>
              </div>
            </div>

            <GridCross className="bottom-0 left-0" />
            <GridCross className="bottom-0 right-0" />
          </div>
        </motion.div>

        {/* How It Works */}
        <motion.div 
          initial={{ y: 30, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="w-full max-w-[1400px] mx-auto border-x border-border px-4 sm:px-8 lg:px-12 py-16 sm:py-24"
        >
          <div className="flex items-center gap-3 mb-10">
            <div className="w-8 h-[1px] bg-accent"></div>
            <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">How It Works</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {[
              { step: "01", title: "Register Agent", desc: "Deploy or connect your AI agent and register its unique bytes32 identity on-chain." },
              { step: "02", title: "Attach Policies", desc: "Compose guardrail contracts that enforce specific constraints — transfer limits, scope restrictions, rate limits." },
              { step: "03", title: "Verify Actions", desc: "Sentinel nodes intercept and validate every agent transaction against attached policies in real-time." },
              { step: "04", title: "Audit & Govern", desc: "Full on-chain audit trail. Revoke compromised agents instantly with a single transaction." },
            ].map((item, i) => (
              <div key={i} className="p-6 border border-border rounded-lg bg-surface/40 relative group hover:bg-surface/70 transition-colors">
                <div className="absolute -top-3 left-6 bg-accent text-white text-xs font-mono px-3 py-1 rounded-sm">{item.step}</div>
                <h3 className="font-bold text-text mt-4 mb-2 text-sm">{item.title}</h3>
                <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Footer */}
      <motion.footer 
        initial={{ y: 20, opacity: 0 }}
        whileInView={{ y: 0, opacity: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6 }}
        className="w-full border-t border-border bg-[#FAFAFA] relative z-10"
      >
        <div className="max-w-[1400px] w-full mx-auto px-4 sm:px-8 lg:px-12 py-12 sm:py-16 flex justify-between gap-8 sm:gap-12 border-x border-border flex-wrap relative">
          <div className="w-full lg:w-1/3 flex flex-col gap-4 sm:gap-6">
             <div className="flex items-center gap-1 font-bold text-2xl tracking-tighter">
               <span className="w-4 h-[3px] bg-accent rounded-sm inline-block mb-1"></span>
               bouclier.eth
             </div>
             <p className="text-sm text-text-muted leading-relaxed font-mono max-w-sm">
               Open-source protocol for deterministic boundary controls on autonomous AI agents, built on Base L2.
             </p>
             <div className="mt-2 sm:mt-4 flex gap-4 text-text-muted">
               <a href="https://github.com/incyashraj/bouclier" target="_blank" rel="noopener noreferrer" className="hover:text-accent transition-colors"><Github size={18} /></a>
             </div>
          </div>
          
          <div className="flex flex-1 justify-start lg:justify-end gap-12 sm:gap-16 lg:gap-32 font-mono text-sm flex-wrap">
             <div className="flex flex-col gap-3 sm:gap-4">
               <span className="font-bold text-text mb-1 sm:mb-2 uppercase tracking-widest flex items-center gap-2"><Key size={14} className="text-accent" /> Protocol</span>
               <Link href="/protocol" className="text-text-muted hover:text-accent transition-colors">Overview</Link>
               <Link href="/registry" className="text-text-muted hover:text-accent transition-colors">Registry</Link>
               <Link href="/nodes" className="text-text-muted hover:text-accent transition-colors">Nodes</Link>
               <Link href="/audits" className="text-text-muted hover:text-accent transition-colors">Audits</Link>
             </div>
             
             <div className="flex flex-col gap-3 sm:gap-4">
               <span className="font-bold text-text mb-1 sm:mb-2 uppercase tracking-widest flex items-center gap-2"><Crosshair size={14} className="text-accent" /> Resources</span>
               <Link href="/developers" className="text-text-muted hover:text-accent transition-colors">Developers</Link>
               <Link href="/docs" className="text-text-muted hover:text-accent transition-colors">Documentation</Link>
               <Link href="/github" className="text-text-muted hover:text-accent transition-colors">GitHub</Link>
               <Link href="/bug-bounty" className="text-text-muted hover:text-accent transition-colors">Bug Bounty</Link>
               <Link href="/pricing" className="text-text-muted hover:text-accent transition-colors">Pricing</Link>
             </div>
          </div>
        </div>

        <div className="max-w-[1400px] w-full mx-auto px-4 sm:px-8 py-4 sm:py-6 border-x border-t border-border bg-background flex flex-col sm:flex-row justify-between items-center text-[10px] font-mono tracking-widest uppercase text-text-muted gap-3 sm:gap-4">
          <p>&copy; {new Date().getFullYear()} Bouclier Protocol. MIT License.</p>
          <div className="flex gap-4">
            <Link href="/docs" className="hover:text-text transition-colors">Documentation</Link>
            <Link href="/github" className="hover:text-text transition-colors">Source Code</Link>
          </div>
        </div>
      </motion.footer>
    </div>
  );
}
