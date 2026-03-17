"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Activity, Globe, Wifi, Cpu, Terminal, ArrowRight } from "lucide-react";
import { motion } from "framer-motion";

const nodeTypes = [
  { icon: Globe, title: "Full Sentinel Node", desc: "Complete mempool monitoring, policy verification, and consensus participation. Requires staking.", tier: "Tier 1" },
  { icon: Wifi, title: "Light Verifier", desc: "Lightweight node that validates specific agent policies without full mempool scanning. Lower resource requirements.", tier: "Tier 2" },
  { icon: Cpu, title: "Archive Node", desc: "Stores complete historical verification data. Powers the analytics dashboard and audit trail queries.", tier: "Tier 3" },
];

const requirements = [
  { spec: "CPU", min: "4 cores", rec: "8+ cores" },
  { spec: "RAM", min: "8 GB", rec: "16 GB" },
  { spec: "Storage", min: "100 GB SSD", rec: "500 GB NVMe" },
  { spec: "Network", min: "25 Mbps", rec: "100+ Mbps" },
  { spec: "OS", min: "Linux / macOS", rec: "Ubuntu 22.04+" },
];

export default function NodesPage() {
  return (
    <MarketingPageTemplate
      title="Sentinel Nodes"
      subtitle="Decentralized Observers"
      description="A decentralized network of verification nodes that continuously scan AI agent transactions and validate them against on-chain policy constraints."
      icon={Activity}
    >
      {/* Network Status */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Network Status</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>SENTINEL NETWORK</span>
            <span className="flex items-center gap-2 text-amber-600">
              <span className="relative flex h-2 w-2"><span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span><span className="relative inline-flex rounded-full h-2 w-2 bg-amber-500"></span></span>
              PRE-LAUNCH — TESTNET ONLY
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <p className="text-sm text-text-muted leading-relaxed">
              The sentinel network is currently in testnet phase on Base Sepolia. Node operators can begin testing configurations and policy verification flows. Mainnet launch details will be announced through our documentation and GitHub.
            </p>
          </div>
        </div>
      </div>

      {/* Node Types */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Node Types</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {nodeTypes.map((node, i) => {
            const Icon = node.icon;
            return (
              <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className="p-6 sm:p-8 border border-border rounded-lg bg-surface/60 hover:bg-surface transition-all group relative">
                <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-accent/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <span className="font-mono text-[10px] text-accent uppercase tracking-widest">{node.tier}</span>
                <div className="w-10 h-10 rounded-lg border border-border flex items-center justify-center bg-background mt-4 mb-4">
                  <Icon size={18} className="text-accent" />
                </div>
                <h3 className="text-base sm:text-lg font-bold text-text mb-3">{node.title}</h3>
                <p className="text-xs sm:text-sm text-text-muted leading-relaxed">{node.desc}</p>
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* System Requirements */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">System Requirements</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
          <table className="w-full text-sm font-mono min-w-[400px]">
            <thead className="text-[11px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
              <tr>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Spec</th>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Minimum</th>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Recommended</th>
              </tr>
            </thead>
            <tbody>
              {requirements.map((r, i) => (
                <tr key={i} className="border-b border-border/40 hover:bg-surface/40 transition-colors">
                  <td className="py-3 px-4 sm:px-5 font-bold text-text">{r.spec}</td>
                  <td className="py-3 px-4 sm:px-5 text-text-muted text-xs">{r.min}</td>
                  <td className="py-3 px-4 sm:px-5 text-text text-xs">{r.rec}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Quick Start CLI */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Quick Start (Testnet)</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#1a1a1c] text-[#a1a1aa] p-3 flex items-center gap-3 text-xs font-mono border-b border-[#2a2a2a]">
            <Terminal size={12} />
            <span>Terminal</span>
          </div>
          <div className="bg-[#0f0f10] p-4 sm:p-6 font-mono text-xs sm:text-sm space-y-3 overflow-x-auto">
            <div className="flex items-center gap-2"><span className="text-emerald-500">$</span><span className="text-[#e2e8f0]">git clone https://github.com/incyashraj/bouclier</span></div>
            <div className="flex items-center gap-2"><span className="text-emerald-500">$</span><span className="text-[#e2e8f0]">cd bouclier-node && cargo build --release</span></div>
            <div className="flex items-center gap-2"><span className="text-emerald-500">$</span><span className="text-[#e2e8f0]">./target/release/bouclier-node init --network base-sepolia</span></div>
            <div className="flex items-center gap-2"><span className="text-emerald-500">$</span><span className="text-[#e2e8f0]">./target/release/bouclier-node start --rpc $BASE_SEPOLIA_RPC</span></div>
          </div>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Run a Sentinel Node</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Help secure the network by running a testnet node. Mainnet staking and rewards coming soon.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/docs" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">Setup Guide <ArrowRight size={14} /></a>
          <a href="/github" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">View Source</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
