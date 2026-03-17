"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Bug, Shield, AlertTriangle, Clock, CheckCircle, ArrowRight } from "lucide-react";
import { motion } from "framer-motion";

const tiers = [
  { severity: "Critical", range: "Up to $50,000", desc: "Fund loss, consensus bypass, or remote code execution on sentinel nodes.", color: "border-red-300 bg-red-50 text-red-700" },
  { severity: "High", range: "Up to $25,000", desc: "Policy bypass, unauthorized agent actions, or state corruption vulnerabilities.", color: "border-orange-300 bg-orange-50 text-orange-700" },
  { severity: "Medium", range: "Up to $10,000", desc: "Denial of service, information leaks, or griefing attacks with limited impact.", color: "border-amber-300 bg-amber-50 text-amber-700" },
  { severity: "Low", range: "Up to $2,000", desc: "Minor issues, gas optimizations, or informational findings with minimal risk.", color: "border-blue-300 bg-blue-50 text-blue-700" },
];

const rules = [
  "Vulnerabilities must be reported privately via the disclosure form before any public disclosure.",
  "Only test against testnet deployments (Base Sepolia). Do not test against mainnet contracts.",
  "Social engineering, phishing, and physical attacks are out of scope.",
  "Duplicate reports receive no reward — first valid report wins.",
  "Severity is determined by the Bouclier security team based on impact and likelihood.",
  "Rewards are paid in USDC on Base within 30 days of fix confirmation.",
];

export default function BugBountyPage() {
  return (
    <MarketingPageTemplate
      title="Bug Bounty"
      subtitle="Security Rewards"
      description="Help secure the Bouclier protocol. We offer rewards for responsibly disclosed vulnerabilities across all protocol components."
      icon={Bug}
    >
      {/* Program Status */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Program Status</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>BUG BOUNTY PROGRAM</span>
            <span className="flex items-center gap-2 text-emerald-600">
              <span className="relative flex h-2 w-2"><span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span><span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span></span>
              ACCEPTING REPORTS
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <p className="text-sm text-text-muted leading-relaxed">
              The bug bounty program is active for testnet contracts and SDK code. Report scope will expand to mainnet contracts upon deployment. All valid reports receive acknowledgment within 48 hours.
            </p>
          </div>
        </div>
      </div>

      {/* Reward Tiers */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Reward Tiers</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {tiers.map((tier, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 * i }} className={`p-5 sm:p-6 border rounded-lg ${tier.color}`}>
              <div className="flex items-start justify-between mb-3">
                <span className="font-bold text-sm">{tier.severity}</span>
                <span className="font-mono text-sm font-bold">{tier.range}</span>
              </div>
              <p className="text-xs opacity-80 leading-relaxed">{tier.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Scope */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">In Scope</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {[
            { name: "bouclier-contracts", desc: "Smart contract vulnerabilities — registry, policies, verification" },
            { name: "bouclier-sdk", desc: "SDK security issues — auth bypass, input validation, key handling" },
            { name: "bouclier-node", desc: "Sentinel node exploits — consensus attacks, DoS, memory safety" },
            { name: "Policy Modules", desc: "Logic flaws in reference policy implementations" },
            { name: "Dashboard", desc: "XSS, CSRF, and wallet interaction vulnerabilities" },
            { name: "Documentation", desc: "Security-relevant documentation errors (informational only)" },
          ].map((item, i) => (
            <div key={i} className="p-4 border border-border rounded-lg bg-surface/40">
              <span className="font-mono text-accent text-xs font-bold">{item.name}</span>
              <p className="text-[11px] text-text-muted mt-1 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Rules */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Rules & Guidelines</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30 space-y-3">
          {rules.map((rule, i) => (
            <div key={i} className="flex items-start gap-3">
              <CheckCircle size={14} className="text-accent mt-0.5 flex-shrink-0" />
              <p className="text-xs text-text-muted leading-relaxed">{rule}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Disclosure Timeline */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Disclosure Timeline</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
          <div className="relative max-w-2xl mx-auto">
            {[
              { step: "Report Submitted", time: "Day 0", desc: "Submit via the bug bounty form with full reproduction steps" },
              { step: "Acknowledgment", time: "< 48 hours", desc: "Security team confirms receipt and begins triage" },
              { step: "Severity Assessment", time: "< 7 days", desc: "Impact classified and reward range communicated" },
              { step: "Fix Deployed", time: "Varies", desc: "Patch developed, tested, and deployed via governance process" },
              { step: "Reward Payment", time: "< 30 days", desc: "USDC payment sent after fix confirmation" },
            ].map((item, i) => (
              <div key={i} className="flex gap-4 sm:gap-6 mb-6 last:mb-0">
                <div className="flex flex-col items-center">
                  <div className="w-8 h-8 rounded-full border border-accent/30 bg-accent/10 flex items-center justify-center text-accent font-mono text-xs font-bold flex-shrink-0">{i + 1}</div>
                  {i < 4 && <div className="w-[1px] flex-1 bg-border mt-2"></div>}
                </div>
                <div className="pb-6">
                  <div className="flex items-center gap-3 mb-1 flex-wrap">
                    <span className="font-bold text-text text-sm">{item.step}</span>
                    <span className="font-mono text-[10px] text-accent bg-accent/10 px-2 py-0.5 rounded">{item.time}</span>
                  </div>
                  <p className="text-xs text-text-muted">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Safe Harbor */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Safe Harbor</span>
        </div>
        <div className="border border-accent/20 bg-accent/5 rounded-lg p-5 sm:p-6">
          <div className="flex items-start gap-3">
            <Shield size={18} className="text-accent mt-0.5 flex-shrink-0" />
            <div>
              <h3 className="font-bold text-text text-sm mb-2">We Will Not Pursue Legal Action</h3>
              <p className="text-xs text-text-muted leading-relaxed">
                Security researchers acting in good faith under this program are protected. We will not initiate legal action against researchers who discover and report vulnerabilities following the rules outlined above. This includes accessing systems, sending transactions to testnet contracts, and analyzing code — as long as no user funds or data are put at risk.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <AlertTriangle className="w-8 h-8 text-accent mx-auto mb-4" />
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Report a Vulnerability</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Found something? Submit a report and help secure the protocol.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="https://github.com/incyashraj/bouclier/security/advisories" target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">Submit Report <ArrowRight size={14} /></a>
          <a href="/audits" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">Security Practices</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
