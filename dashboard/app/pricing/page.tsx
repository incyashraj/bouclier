"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { DollarSign, Zap, Shield, Users, HelpCircle, ArrowRight } from "lucide-react";
import { motion } from "framer-motion";

const tiers = [
  {
    name: "Open Protocol",
    price: "Free",
    desc: "Core protocol is permissionless and free to use. Pay only gas costs on Base L2.",
    features: [
      "Agent registration",
      "Policy deployment",
      "On-chain verification",
      "Audit trail access",
      "Base L2 gas costs only",
    ],
    accent: false,
  },
  {
    name: "Sentinel Staker",
    price: "Stake-Based",
    desc: "Run a sentinel node by staking tokens. Earn verification rewards for securing the network.",
    features: [
      "Everything in Open Protocol",
      "Run sentinel nodes",
      "Earn verification rewards",
      "Priority policy checks",
      "Network governance rights",
    ],
    accent: true,
  },
  {
    name: "Enterprise",
    price: "Custom",
    desc: "Dedicated infrastructure, SLA guarantees, and custom policy development for high-volume deployments.",
    features: [
      "Everything in Sentinel Staker",
      "Dedicated sentinel nodes",
      "Custom policy development",
      "Priority support channel",
      "SLA guarantees",
    ],
    accent: false,
  },
];

const faqs = [
  { q: "How much does it cost to register an agent?", a: "Agent registration requires a single transaction on Base L2. You pay only the gas cost, which is typically under $0.01 on Base." },
  { q: "Are there recurring fees?", a: "No recurring fees for using the open protocol. You pay gas per transaction. Sentinel staking is voluntary and earns rewards." },
  { q: "What about the enterprise tier?", a: "Enterprise pricing is custom based on throughput, node requirements, and support needs. Contact us for a tailored quote." },
  { q: "When will staking and rewards go live?", a: "Staking and sentinel rewards will launch alongside the mainnet deployment. Testnet is available now for node operators to prepare." },
];

export default function PricingPage() {
  return (
    <MarketingPageTemplate
      title="Pricing"
      subtitle="Cost Structure"
      description="Bouclier is an open protocol. Core functionality is free — you pay only Base L2 gas costs. Advanced features use a stake-based model."
      icon={DollarSign}
    >
      {/* Pricing Tiers */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Pricing Tiers</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {tiers.map((tier, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className={`p-6 sm:p-8 border rounded-lg relative ${tier.accent ? "border-accent bg-accent/5" : "border-border bg-surface/40"}`}>
              {tier.accent && <div className="absolute top-0 left-0 w-full h-[2px] bg-accent"></div>}
              <h3 className="font-bold text-text text-lg mb-1">{tier.name}</h3>
              <div className="font-mono text-2xl sm:text-3xl font-bold text-accent mb-3">{tier.price}</div>
              <p className="text-xs text-text-muted mb-6 leading-relaxed">{tier.desc}</p>
              <ul className="space-y-2">
                {tier.features.map((f, j) => (
                  <li key={j} className="text-xs text-text flex items-start gap-2">
                    <Zap size={10} className="text-accent mt-1 flex-shrink-0" />
                    {f}
                  </li>
                ))}
              </ul>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Gas Estimates */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Estimated Gas Costs (Base L2)</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
          <table className="w-full text-sm font-mono min-w-[400px]">
            <thead className="text-[11px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
              <tr>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Operation</th>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Est. Gas</th>
                <th className="font-normal py-3 px-4 sm:px-5 text-left">Est. Cost</th>
              </tr>
            </thead>
            <tbody>
              {[
                { op: "Register Agent", gas: "~48,000", cost: "< $0.01" },
                { op: "Attach Policy", gas: "~32,000", cost: "< $0.01" },
                { op: "Revoke Agent", gas: "~24,000", cost: "< $0.01" },
                { op: "Policy Validation (view)", gas: "0 (read)", cost: "Free" },
              ].map((r, i) => (
                <tr key={i} className="border-b border-border/40 hover:bg-surface/40 transition-colors">
                  <td className="py-3 px-4 sm:px-5 font-bold text-text">{r.op}</td>
                  <td className="py-3 px-4 sm:px-5 text-text-muted text-xs">{r.gas}</td>
                  <td className="py-3 px-4 sm:px-5 text-emerald-600 text-xs font-bold">{r.cost}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="text-[11px] text-text-muted mt-3 font-mono">* Estimates based on Base L2 typical gas prices. Actual costs vary with network conditions.</p>
      </div>

      {/* FAQs */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">FAQ</span>
        </div>
        <div className="space-y-3">
          {faqs.map((faq, i) => (
            <div key={i} className="p-4 sm:p-5 border border-border rounded-lg bg-surface/40">
              <div className="flex items-start gap-3">
                <HelpCircle size={14} className="text-accent mt-0.5 flex-shrink-0" />
                <div>
                  <h3 className="font-bold text-text text-sm mb-1">{faq.q}</h3>
                  <p className="text-xs text-text-muted leading-relaxed">{faq.a}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Ready to Start?</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">The protocol is free to use on testnet. Register your first agent today.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/dashboard" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors">Launch Dashboard</a>
          <a href="/developers" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors flex items-center gap-2">SDK Docs <ArrowRight size={14} /></a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
