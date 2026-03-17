"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Crosshair, Shield, AlertTriangle, CheckCircle, XCircle, Clock, Bug, Eye, Zap } from "lucide-react";
import { motion } from "framer-motion";

const slitherFindings = [
  { id: "S-1", severity: "Info", title: "Locked ether in PermissionVault", status: "Fixed", detail: "Added receive() revert + rescueETH()" },
  { id: "S-2", severity: "Low", title: "Reentrancy-events in emergencyRevoke", status: "Fixed", detail: "Event moved before external call (CEI pattern)" },
  { id: "S-3", severity: "Info", title: "Unused return in logAction()", status: "Acknowledged", detail: "Return value intentionally unused — annotated" },
  { id: "S-4", severity: "Info", title: "Unused return in latestRoundData()", status: "Acknowledged", detail: "Partial destructuring is intentional — annotated" },
  { id: "S-5", severity: "Info", title: "Solc version pragma", status: "Fixed", detail: "Updated to ^0.8.24" },
];

const invariants = [
  { id: "INV-1", property: "Agent count consistency", result: true },
  { id: "INV-2", property: "Revocation irreversibility", result: true },
  { id: "INV-3", property: "Audit record immutability", result: true },
  { id: "INV-4", property: "Scope revocation permanence", result: true },
  { id: "INV-5", property: "Module type invariant", result: true },
  { id: "INV-6", property: "Rolling spend monotonicity", result: true },
  { id: "INV-7", property: "Admin non-nullity", result: true },
  { id: "INV-8", property: "Revoked agent blocked", result: true },
  { id: "INV-9", property: "Grant/revoke consistency", result: true },
];

const manualFindings = [
  { id: "M-1", severity: "High", title: "EIP-712 SCOPE_TYPEHASH mismatch", status: "Fixed", detail: "SCOPE_TYPEHASH string did not include nonce field — violated EIP-712 spec. Corrected to include uint256 nonce." },
  { id: "M-2", severity: "Info", title: "Dead code in PermissionVault", status: "Fixed", detail: "Unreachable code path removed." },
];

const acceptedRisks = [
  { id: "AR-1", severity: "Low", title: "Block timestamp in oracle staleness check", rationale: "Required for Chainlink heartbeat validation. ±15s manipulation is negligible." },
  { id: "AR-2", severity: "Low", title: "Block timestamp in scope expiry", rationale: "Permission windows are hours/days — ±15s is irrelevant." },
  { id: "AR-3", severity: "Medium", title: "Chainlink single oracle dependency", rationale: "Stale-price revert implemented. TWAP fallback planned." },
];

const testSuites = [
  { suite: "Unit tests", count: 84, pass: 84, fail: 0 },
  { suite: "Integration tests", count: 7, pass: 7, fail: 0 },
  { suite: "Invariant tests", count: 9, pass: 9, fail: 0 },
];

export default function AuditsPage() {
  const totalTests = testSuites.reduce((sum, s) => sum + s.count, 0);
  const totalPass = testSuites.reduce((sum, s) => sum + s.pass, 0);

  return (
    <MarketingPageTemplate
      title="Security"
      subtitle="Audit Reports"
      description="Full transparency on every security analysis performed on the Bouclier protocol. All findings, fixes, and accepted risks are documented here."
      icon={Crosshair}
    >
      {/* Overall Status */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Overall Status</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>SECURITY ASSESSMENT</span>
            <span className="flex items-center gap-2 text-green-600">
              <CheckCircle size={12} />
              INTERNAL AUDIT COMPLETE — RISK: LOW
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30 space-y-4">
            <p className="text-sm text-text-muted leading-relaxed">
              All five core contracts have undergone static analysis (Slither v0.11.5), symbolic execution (Mythril v0.24.8), invariant fuzzing (Foundry, 128K+ calls), and manual security review. All identified issues have been resolved or formally accepted with documented rationale. Certora formal verification specs are written and pending cloud execution. Third-party audit is planned pre-mainnet.
            </p>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {[
                { label: "Test Suite", value: `${totalPass}/${totalTests}`, desc: "All tests passing" },
                { label: "Invariants", value: "9/9", desc: "Hold after 128K fuzz calls" },
                { label: "Critical Findings", value: "0", desc: "Zero unresolved" },
                { label: "Overall Risk", value: "LOW", desc: "All findings addressed" },
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

      {/* Slither Static Analysis */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Slither Static Analysis</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>SLITHER v0.11.5 — ALL 5 CONTRACTS</span>
            <span className="flex items-center gap-2 text-green-600">
              <CheckCircle size={12} />
              5 FINDINGS — ALL RESOLVED
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border text-left font-mono text-text-muted uppercase tracking-widest">
                    <th className="py-3 pr-3">ID</th>
                    <th className="py-3 pr-3">Severity</th>
                    <th className="py-3 pr-3">Finding</th>
                    <th className="py-3 pr-3">Status</th>
                    <th className="py-3">Resolution</th>
                  </tr>
                </thead>
                <tbody>
                  {slitherFindings.map((f, i) => (
                    <tr key={i} className="border-b border-border/50 last:border-0">
                      <td className="py-3 pr-3 font-mono text-accent">{f.id}</td>
                      <td className="py-3 pr-3">
                        <span className={`px-2 py-0.5 rounded font-mono ${f.severity === "Low" ? "bg-yellow-100 text-yellow-700" : "bg-gray-100 text-gray-600"}`}>{f.severity}</span>
                      </td>
                      <td className="py-3 pr-3 text-text">{f.title}</td>
                      <td className="py-3 pr-3">
                        <span className={`flex items-center gap-1 ${f.status === "Fixed" ? "text-green-600" : "text-blue-600"}`}>
                          <CheckCircle size={10} />
                          {f.status}
                        </span>
                      </td>
                      <td className="py-3 text-text-muted">{f.detail}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {/* Mythril Symbolic Execution */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Mythril Symbolic Execution</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>MYTHRIL v0.24.8 — RUNTIME BYTECODE ANALYSIS</span>
            <span className="flex items-center gap-2 text-green-600">
              <CheckCircle size={12} />
              0 ACTIONABLE FINDINGS
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border text-left font-mono text-text-muted uppercase tracking-widest">
                    <th className="py-3 pr-3">Contract</th>
                    <th className="py-3 pr-3">Issues</th>
                    <th className="py-3 pr-3">SWC IDs</th>
                    <th className="py-3">Disposition</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    { contract: "AgentRegistry", issues: 0, swc: "—", disposition: "Clean" },
                    { contract: "PermissionVault", issues: 0, swc: "—", disposition: "Clean" },
                    { contract: "RevocationRegistry", issues: 0, swc: "—", disposition: "Clean" },
                    { contract: "AuditLogger", issues: 0, swc: "—", disposition: "Clean" },
                    { contract: "SpendTracker", issues: 1, swc: "SWC-116", disposition: "Accepted — block.timestamp needed for oracle staleness" },
                    { contract: "PermissionVault (ext)", issues: 2, swc: "SWC-123, SWC-101", disposition: "False positives — receive() revert by design; Solidity 0.8.24 overflow protection" },
                  ].map((r, i) => (
                    <tr key={i} className="border-b border-border/50 last:border-0">
                      <td className="py-3 pr-3 font-mono text-text">{r.contract}</td>
                      <td className="py-3 pr-3 text-text">{r.issues}</td>
                      <td className="py-3 pr-3 font-mono text-text-muted">{r.swc}</td>
                      <td className="py-3 text-text-muted">{r.disposition}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-text-muted mt-4">12 SWC vulnerability classes tested. All critical classes (SWC-104, SWC-106, SWC-107, SWC-110, SWC-112, SWC-113, SWC-114) returned clean across all contracts.</p>
          </div>
        </div>
      </div>

      {/* Foundry Invariant Fuzzing */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Invariant Fuzzing</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>FOUNDRY v1.5.1 — 256 RUNS × 500 CALLS = 128,000 FUZZ CALLS PER INVARIANT</span>
            <span className="flex items-center gap-2 text-green-600">
              <CheckCircle size={12} />
              9/9 INVARIANTS HOLD
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border text-left font-mono text-text-muted uppercase tracking-widest">
                    <th className="py-3 pr-3">ID</th>
                    <th className="py-3 pr-3">Property</th>
                    <th className="py-3">Result</th>
                  </tr>
                </thead>
                <tbody>
                  {invariants.map((inv, i) => (
                    <tr key={i} className="border-b border-border/50 last:border-0">
                      <td className="py-3 pr-3 font-mono text-accent">{inv.id}</td>
                      <td className="py-3 pr-3 text-text">{inv.property}</td>
                      <td className="py-3">
                        <span className="flex items-center gap-1 text-green-600">
                          <CheckCircle size={10} />
                          HOLDS
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-text-muted mt-4">A BouclierHandler contract with 7 handler functions drives the fuzzer through realistic protocol operations including agent registration, permission grants, revocations, audit logging, spend recording, and timestamp warping.</p>
          </div>
        </div>
      </div>

      {/* Manual Security Review */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Manual Security Review</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>MANUAL CODE REVIEW — ALL CONTRACTS</span>
            <span className="flex items-center gap-2 text-green-600">
              <CheckCircle size={12} />
              2 FINDINGS — ALL FIXED
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border text-left font-mono text-text-muted uppercase tracking-widest">
                    <th className="py-3 pr-3">ID</th>
                    <th className="py-3 pr-3">Severity</th>
                    <th className="py-3 pr-3">Finding</th>
                    <th className="py-3 pr-3">Status</th>
                    <th className="py-3">Resolution</th>
                  </tr>
                </thead>
                <tbody>
                  {manualFindings.map((f, i) => (
                    <tr key={i} className="border-b border-border/50 last:border-0">
                      <td className="py-3 pr-3 font-mono text-accent">{f.id}</td>
                      <td className="py-3 pr-3">
                        <span className={`px-2 py-0.5 rounded font-mono ${f.severity === "High" ? "bg-red-100 text-red-700" : "bg-gray-100 text-gray-600"}`}>{f.severity}</span>
                      </td>
                      <td className="py-3 pr-3 text-text">{f.title}</td>
                      <td className="py-3 pr-3">
                        <span className="flex items-center gap-1 text-green-600">
                          <CheckCircle size={10} />
                          {f.status}
                        </span>
                      </td>
                      <td className="py-3 text-text-muted">{f.detail}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {/* Certora Formal Verification */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Formal Verification</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 text-xs font-mono text-text-muted">
            <span>CERTORA PROVER — 3 SPEC FILES, 15 RULES</span>
            <span className="flex items-center gap-2 text-amber-600">
              <Clock size={12} />
              SPECS WRITTEN — PENDING CLOUD RUN
            </span>
          </div>
          <div className="p-5 sm:p-6 bg-surface/30 space-y-4">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border text-left font-mono text-text-muted uppercase tracking-widest">
                    <th className="py-3 pr-3">Spec File</th>
                    <th className="py-3 pr-3">Contract</th>
                    <th className="py-3 pr-3">Rules</th>
                    <th className="py-3">Key Properties</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    { file: "PermissionVault.spec", contract: "PermissionVault", rules: 7, props: "Revoked agent always fails, binary validation result, nonce monotonicity, expired scope rejection" },
                    { file: "SpendTracker.spec", contract: "SpendTracker", rules: 4, props: "Spend cap enforced, zero cap = no limit, rolling monotonicity" },
                    { file: "RevocationRegistry.spec", contract: "RevocationRegistry", rules: 4, props: "Revoke always sets flag, timelock respected, double-revoke reverts" },
                  ].map((s, i) => (
                    <tr key={i} className="border-b border-border/50 last:border-0">
                      <td className="py-3 pr-3 font-mono text-accent">{s.file}</td>
                      <td className="py-3 pr-3 text-text">{s.contract}</td>
                      <td className="py-3 pr-3 text-text">{s.rules}</td>
                      <td className="py-3 text-text-muted">{s.props}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-text-muted">Configuration files prepared. Execution requires CERTORAKEY API access. Will be run prior to mainnet deployment.</p>
          </div>
        </div>
      </div>

      {/* Test Suite */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Test Suite</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {testSuites.map((s, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }} className="p-5 border border-border rounded-lg bg-surface/40">
              <div className="flex items-center justify-between mb-3">
                <span className="font-mono text-xs text-text-muted uppercase tracking-widest">{s.suite}</span>
                <span className="flex items-center gap-1 text-green-600 text-xs font-mono">
                  <CheckCircle size={10} />
                  {s.pass}/{s.count}
                </span>
              </div>
              <div className="w-full bg-border rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: `${(s.pass / s.count) * 100}%` }}></div>
              </div>
            </motion.div>
          ))}
        </div>
        <p className="text-xs text-text-muted mt-4">All {totalTests} Solidity tests pass after all security fixes including EIP-712 SCOPE_TYPEHASH correction and oracle circuit breaker implementation.</p>
      </div>

      {/* Accepted Risks */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Accepted Risks</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
          <div className="space-y-4">
            {acceptedRisks.map((r, i) => (
              <div key={i} className="flex gap-4 items-start">
                <span className={`px-2 py-0.5 rounded font-mono text-xs flex-shrink-0 ${r.severity === "Medium" ? "bg-yellow-100 text-yellow-700" : "bg-gray-100 text-gray-600"}`}>{r.severity}</span>
                <div>
                  <span className="text-sm text-text font-medium">{r.title}</span>
                  <p className="text-xs text-text-muted mt-0.5">{r.rationale}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Security Fixes Applied */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Key Fixes Applied</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {[
            { icon: Shield, title: "Locked Ether Protection", desc: "Added receive() revert and rescueETH() for accidental ETH recovery." },
            { icon: Zap, title: "CEI Pattern Enforcement", desc: "Events moved before external calls in emergencyRevoke to prevent reentrancy-events." },
            { icon: Eye, title: "EIP-712 Typehash Correction", desc: "SCOPE_TYPEHASH corrected to include nonce field per EIP-712 specification." },
            { icon: Shield, title: "Oracle Circuit Breaker", desc: "5% deviation threshold on Chainlink price feeds with admin-refreshable anchor prices." },
          ].map((fix, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }} className="p-5 border border-border rounded-lg bg-surface/40">
              <div className="w-8 h-8 rounded-md border border-border flex items-center justify-center bg-background mb-3">
                <fix.icon size={14} className="text-accent" />
              </div>
              <h3 className="font-bold text-text mb-1 text-sm">{fix.title}</h3>
              <p className="text-xs text-text-muted leading-relaxed">{fix.desc}</p>
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

      {/* Next Steps */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Pre-Mainnet Roadmap</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[
            { title: "Certora Cloud Run", desc: "Execute all 15 formal verification rules via Certora Prover cloud API.", status: "Next" },
            { title: "Third-Party Audit", desc: "Competitive audit via Code4rena or engagement with Trail of Bits / OpenZeppelin.", status: "Planned" },
            { title: "Immunefi Bug Bounty", desc: "$100K bounty pool — $50K critical, $10K high, $2K medium, $500 low.", status: "Prepared" },
          ].map((item, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }} className="p-5 border border-border rounded-lg bg-surface/40">
              <span className={`inline-block px-2 py-0.5 rounded font-mono text-[10px] mb-3 ${item.status === "Next" ? "bg-accent/10 text-accent" : item.status === "Planned" ? "bg-amber-100 text-amber-700" : "bg-green-100 text-green-700"}`}>{item.status}</span>
              <h3 className="font-bold text-text mb-1 text-sm">{item.title}</h3>
              <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <AlertTriangle className="w-8 h-8 text-accent mx-auto mb-4" />
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Found a Vulnerability?</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">We take security seriously. Report any issues through our bug bounty program.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/bug-bounty" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors">Bug Bounty Program</a>
          <a href="https://github.com/incyashraj/bouclier" target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">View Source</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
