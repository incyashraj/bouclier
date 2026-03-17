"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { GitCompareArrows, Shield, Key, DollarSign, AlertTriangle, FileSearch, Blocks, Code, Users, ArrowRight, Check, X, Minus } from "lucide-react";
import { motion } from "framer-motion";

const comparisonData = [
  {
    category: "Agent Identity",
    bouclier: "On-chain DID per agent with hierarchy and status tracking",
    safeGuards: "No — guards are per-Safe, not per-agent",
    custodial: "Off-chain API keys tied to organization",
    custom: "Manual mapping, no standard",
    scores: [2, 0, 1, 0],
  },
  {
    category: "Permission Scopes",
    bouclier: "EIP-712 signed, on-chain enforced — protocol allowlists, asset whitelists, spend caps, time windows",
    safeGuards: "Transaction-level checks only — no scoped grants or EIP-712 signing",
    custodial: "Proprietary policy engine, enforced off-chain",
    custom: "Custom require() modifiers per contract",
    scores: [2, 1, 1, 0],
  },
  {
    category: "Spend Limits",
    bouclier: "Rolling-window USD-denominated limits with Chainlink oracle + TWAP fallback",
    safeGuards: "ETH-only or no native support",
    custodial: "USD limits but custodial — you don't hold keys",
    custom: "Self-built, no oracle integration",
    scores: [2, 0, 1, 0],
  },
  {
    category: "Revocation",
    bouclier: "Instant emergency override + 24h timelock, on-chain registry",
    safeGuards: "Remove guard via admin transaction",
    custodial: "API call — centralized, opaque",
    custom: "Custom implementation required",
    scores: [2, 1, 1, 0],
  },
  {
    category: "Audit Trail",
    bouclier: "Every action hashed on-chain + optional IPFS anchoring, queryable via SDK",
    safeGuards: "Transaction events only — no structured agent-level audit log",
    custodial: "Centralized logs — not independently verifiable",
    custom: "Whatever you build",
    scores: [2, 0, 0, 0],
  },
  {
    category: "Modular Accounts",
    bouclier: "ERC-7579 validator module — composable with any modular smart account",
    safeGuards: "Safe-only — not portable to other account types",
    custodial: "Vendor lock-in — no standard interface",
    custom: "N/A — only works with your contracts",
    scores: [2, 1, 0, 0],
  },
  {
    category: "Open Source",
    bouclier: "MIT license, permissionless, fully verifiable on-chain",
    safeGuards: "Guard logic is open, but tightly coupled to Safe",
    custodial: "Proprietary — closed source",
    custom: "Depends on your project",
    scores: [2, 1, 0, 1],
  },
  {
    category: "Multi-Framework",
    bouclier: "LangChain, AgentKit, ELIZA integrations + TypeScript and Python SDKs",
    safeGuards: "No agent framework integrations",
    custodial: "REST APIs only — no agent-native SDKs",
    custom: "Manual integration required",
    scores: [2, 0, 1, 0],
  },
];

function ScoreIcon({ score }: { score: number }) {
  if (score === 2) return <Check size={16} className="text-emerald-500" />;
  if (score === 1) return <Minus size={16} className="text-yellow-500" />;
  return <X size={16} className="text-red-400" />;
}

const approaches = [
  {
    name: "Safe Guards",
    icon: Shield,
    summary: "Transaction filtering for Safe multisigs. Checks each transaction against custom logic before execution.",
    bestFor: "Multisig-native teams already using Safe who need basic tx filtering.",
    limitation: "Per-Safe, not per-agent. No identity, no audit trail, no spend tracking, not portable.",
  },
  {
    name: "Custodial MPC",
    icon: Key,
    summary: "Fireblocks, Fordefi, and similar — key management + policy enforcement via centralized infrastructure.",
    bestFor: "Institutions that need key custody and are comfortable with vendor dependency.",
    limitation: "Closed source. You don't hold keys. Audit logs aren't independently verifiable. Vendor lock-in.",
  },
  {
    name: "Roll Your Own",
    icon: Code,
    summary: "Custom modifiers, bespoke access control, hand-rolled audit logging.",
    bestFor: "Teams with unique requirements that don't fit any existing solution.",
    limitation: "Months of engineering. No standard. No interoperability. Every integration is custom.",
  },
];

export default function ComparePage() {
  return (
    <MarketingPageTemplate
      title="Bouclier vs Alternatives"
      subtitle="Compare"
      description="How Bouclier compares to existing approaches for securing AI agents on-chain."
      icon={GitCompareArrows}
    >
      {/* ── The Problem ─────────────────────────────────────────── */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">The Problem</span>
        </div>
        <div className="border border-border rounded-lg p-6 sm:p-8 bg-[#FAFAFA]">
          <p className="text-text text-sm sm:text-base leading-relaxed max-w-3xl">
            AI agents executing on-chain transactions need identity, permissions, spend controls, and audit trails. 
            Today, teams either repurpose multisig guards (designed for humans, not agents), 
            rely on custodial MPC vaults (closed-source, vendor lock-in), 
            or build custom solutions from scratch (months of work, no interoperability).
          </p>
          <p className="text-text-muted text-sm mt-4 max-w-3xl">
            Bouclier is purpose-built for agent permission management — scoped identity, enforcement, audit, and revocation 
            as a composable on-chain protocol that works across any ERC-4337/7579 account and any agent framework.
          </p>
        </div>
      </div>

      {/* ── Comparison Table ────────────────────────────────────── */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Feature Comparison</span>
        </div>
        <div className="overflow-x-auto -mx-2 px-2">
          <table className="w-full text-xs sm:text-sm border border-border rounded-lg overflow-hidden">
            <thead>
              <tr className="bg-[#0f0f10] text-white text-left">
                <th className="p-3 sm:p-4 font-mono font-semibold uppercase tracking-wider text-[10px] sm:text-xs border-b border-[#2a2a2a] w-[15%]">Capability</th>
                <th className="p-3 sm:p-4 font-mono font-semibold uppercase tracking-wider text-[10px] sm:text-xs border-b border-[#2a2a2a] text-accent w-[25%]">Bouclier</th>
                <th className="p-3 sm:p-4 font-mono font-semibold uppercase tracking-wider text-[10px] sm:text-xs border-b border-[#2a2a2a] w-[20%]">Safe Guards</th>
                <th className="p-3 sm:p-4 font-mono font-semibold uppercase tracking-wider text-[10px] sm:text-xs border-b border-[#2a2a2a] w-[20%]">Custodial MPC</th>
                <th className="p-3 sm:p-4 font-mono font-semibold uppercase tracking-wider text-[10px] sm:text-xs border-b border-[#2a2a2a] w-[20%]">Roll Your Own</th>
              </tr>
            </thead>
            <tbody>
              {comparisonData.map((row, i) => (
                <motion.tr
                  key={row.category}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.05 }}
                  className={`border-b border-border ${i % 2 === 0 ? "bg-background" : "bg-[#FAFAFA]"}`}
                >
                  <td className="p-3 sm:p-4 font-semibold text-text whitespace-nowrap">{row.category}</td>
                  <td className="p-3 sm:p-4 text-text">
                    <div className="flex items-start gap-2">
                      <ScoreIcon score={row.scores[0]} />
                      <span>{row.bouclier}</span>
                    </div>
                  </td>
                  <td className="p-3 sm:p-4 text-text-muted">
                    <div className="flex items-start gap-2">
                      <ScoreIcon score={row.scores[1]} />
                      <span>{row.safeGuards}</span>
                    </div>
                  </td>
                  <td className="p-3 sm:p-4 text-text-muted">
                    <div className="flex items-start gap-2">
                      <ScoreIcon score={row.scores[2]} />
                      <span>{row.custodial}</span>
                    </div>
                  </td>
                  <td className="p-3 sm:p-4 text-text-muted">
                    <div className="flex items-start gap-2">
                      <ScoreIcon score={row.scores[3]} />
                      <span>{row.custom}</span>
                    </div>
                  </td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ── Approach Breakdown ──────────────────────────────────── */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Approach Breakdown</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {approaches.map((a, i) => (
            <motion.div
              key={a.name}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 + i * 0.1 }}
              className="border border-border rounded-lg p-5 sm:p-6 bg-background hover:border-text-muted transition-colors"
            >
              <div className="flex items-center gap-3 mb-4">
                <a.icon size={18} className="text-text-muted" />
                <span className="font-semibold text-sm text-text">{a.name}</span>
              </div>
              <p className="text-xs text-text-muted leading-relaxed mb-4">{a.summary}</p>
              <div className="space-y-3">
                <div>
                  <span className="font-mono text-[10px] uppercase tracking-wider text-emerald-600">Best for</span>
                  <p className="text-xs text-text mt-1">{a.bestFor}</p>
                </div>
                <div>
                  <span className="font-mono text-[10px] uppercase tracking-wider text-red-400">Limitation</span>
                  <p className="text-xs text-text-muted mt-1">{a.limitation}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* ── Why Bouclier ────────────────────────────────────────── */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Why Bouclier</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { icon: Users, title: "Agent-Native", desc: "Built for autonomous agents, not retrofitted from multisig tooling." },
            { icon: Blocks, title: "ERC-7579 Composable", desc: "Works with any modular smart account — not locked to one wallet provider." },
            { icon: FileSearch, title: "Verifiable Audit Trail", desc: "Every action on-chain and queryable. Not centralized logs you have to trust." },
            { icon: Code, title: "Open Protocol", desc: "MIT licensed, permissionless. Inspect, fork, self-host — no vendor lock-in." },
          ].map((item, i) => (
            <motion.div
              key={item.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 + i * 0.08 }}
              className="border border-border rounded-lg p-5 bg-background"
            >
              <item.icon size={18} className="text-accent mb-3" />
              <h3 className="text-sm font-semibold text-text mb-2">{item.title}</h3>
              <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* ── CTA ─────────────────────────────────────────────────── */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h2 className="text-xl sm:text-2xl font-bold tracking-tight mb-3">Ready to secure your agents?</h2>
        <p className="text-sm text-text-muted mb-6 max-w-xl mx-auto">
          Deploy Bouclier on Base Sepolia in minutes. Open source, permissionless, and free to start.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          <a href="/developers" className="inline-flex items-center gap-2 bg-[#0f0f10] text-white px-6 py-3 rounded-md text-sm font-semibold hover:bg-[#1a1a1c] transition-colors">
            Get Started <ArrowRight size={14} />
          </a>
          <a href="/docs" className="inline-flex items-center gap-2 border border-border px-6 py-3 rounded-md text-sm font-semibold text-text-muted hover:text-text hover:border-text-muted transition-colors">
            Read the Docs
          </a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
