"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Crosshair, Shield, AlertTriangle, Clock } from "lucide-react";
import { motion } from "framer-motion";

const practices = [
  { title: "Formal Verification", desc: "Critical contract paths will be formally verified using Certora and Halmos to prove mathematical correctness." },
  { title: "Continuous Fuzzing", desc: "Echidna and Foundry fuzz tests run on every commit with 10M+ iterations per campaign." },
  { title: "Invariant Testing", desc: "Protocol invariants are encoded as on-chain assertions that revert deployments on violation." },
  { title: "Multi-Sig Governance", desc: "All contract upgrades will require multi-sig approval with a 48-hour timelock." },
  { title: "Bug Bounty Program", desc: "Security rewards program planned for launch. See the Bug Bounty page for planned tier structure." },
  { title: "Incident Response", desc: "Emergency pause mechanisms and circuit breakers built into core contracts from day one." },
];

export default function AuditsPage() {
  return (
    <MarketingPageTemplate
      title="Security"
      subtitle="Verifiable Trust"
      description="Security is foundational to Bouclier. Our contracts are designed for auditability using industry-standard security practices and open-source development."
      icon={Crosshair}
    >
      {/* Audit Status */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Audit Status</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>SECURITY AUDIT PROGRAM</span>
            <span className="flex items-center gap-2 text-amber-600">
              <Clock size={12} />
              PRE-AUDIT PHASE
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30 space-y-4">
            <p className="text-sm text-text-muted leading-relaxed">
              Bouclier is currently in active development. Professional security audits will be conducted before mainnet deployment. We are committed to engaging reputable audit firms and publishing all reports publicly.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {[
                { label: "Planned Audits", value: "Pre-Mainnet", desc: "Core contracts + policy modules" },
                { label: "All Reports", value: "Public", desc: "Published on GitHub + this page" },
                { label: "Code", value: "Open Source", desc: "Full source available for review" },
              ].map((item, i) => (
                <div key={i} className="p-4 border border-border rounded-md bg-surface/50">
                  <div className="font-mono text-xs text-text-muted uppercase tracking-widest mb-1">{item.label}</div>
                  <div className="font-bold text-text text-sm">{item.value}</div>
                  <div className="text-xs text-text-muted mt-1">{item.desc}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Security Practices */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Security Practices</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {practices.map((p, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }} className="p-5 sm:p-6 border border-border rounded-lg bg-surface/40 hover:bg-surface/70 transition-colors">
              <div className="w-8 h-8 rounded-md border border-border flex items-center justify-center bg-background mb-4">
                <Shield size={14} className="text-accent" />
              </div>
              <h3 className="font-bold text-text mb-2 text-sm">{p.title}</h3>
              <p className="text-xs text-text-muted leading-relaxed">{p.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Disclosure Process */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Responsible Disclosure</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
          <div className="relative max-w-2xl mx-auto">
            {[
              { step: "Discovery", time: "T+0", desc: "Vulnerability reported via the bug bounty program or direct disclosure" },
              { step: "Assessment", time: "T+24h", desc: "Security team triages severity and confirms reproducibility" },
              { step: "Remediation", time: "T+72h", desc: "Patch developed, tested with formal verification" },
              { step: "Deployment", time: "T+96h", desc: "Multi-sig approves fix. Timelock executed for non-critical" },
              { step: "Disclosure", time: "T+30d", desc: "Full public disclosure with technical write-up" },
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

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <AlertTriangle className="w-8 h-8 text-accent mx-auto mb-4" />
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Found a Vulnerability?</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">We take security seriously. Report any issues through our bug bounty program.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/bug-bounty" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors">Bug Bounty Program</a>
          <a href="/github" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">View Source</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
