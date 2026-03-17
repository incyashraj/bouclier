"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Database, ArrowRight } from "lucide-react";
import { motion } from "framer-motion";

export default function RegistryPage() {
  return (
    <MarketingPageTemplate
      title="Agent Registry"
      subtitle="Identity & Access"
      description="Cryptographic agent identity layer. The registry assigns verifiable on-chain credentials and enables instant global revocation of compromised agents."
      icon={Database}
    >
      {/* How It Works */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">How Registration Works</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {[
            { step: "01", title: "Hash Agent Identity", desc: "Generate a unique bytes32 identifier from the agent metadata, owner address, and salt." },
            { step: "02", title: "Attach Policy Contracts", desc: "Link one or more policy modules to the agent ID. Each policy defines a specific constraint." },
            { step: "03", title: "Activate & Monitor", desc: "Once registered, sentinel nodes begin intercepting and validating every matching transaction." },
          ].map((item, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 * i }} className="p-5 sm:p-6 border border-border rounded-lg bg-surface/40 relative">
              <div className="absolute -top-3 left-6 bg-accent text-white text-xs font-mono px-3 py-1 rounded-sm">{item.step}</div>
              <h3 className="font-bold text-text mt-4 mb-2">{item.title}</h3>
              <p className="text-xs sm:text-sm text-text-muted leading-relaxed">{item.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Registry Capabilities */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Registry Capabilities</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {[
            { title: "Permissionless Registration", desc: "Any address can register an agent with attached policies. No approval process or gatekeeping required." },
            { title: "Instant Revocation", desc: "Agent owners can globally revoke an agent in a single transaction. All sentinel nodes stop processing immediately." },
            { title: "Policy Composition", desc: "Attach multiple policy contracts to a single agent. Policies are checked in sequence — all must pass." },
            { title: "On-Chain Audit Trail", desc: "Every registration, policy change, and revocation is recorded as an immutable event on Base L2." },
          ].map((item, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 * i }} className="p-5 sm:p-6 border border-border rounded-lg bg-surface/40 hover:bg-surface/60 transition-colors">
              <h3 className="font-bold text-text text-sm mb-2">{item.title}</h3>
              <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Registry Contract Interface */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Registry Interface</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#1a1a1c] text-[#a1a1aa] p-3 flex items-center gap-3 text-xs font-mono border-b border-[#2a2a2a]">
            <span className="w-3 h-3 rounded-full bg-red-500/60"></span>
            <span className="w-3 h-3 rounded-full bg-yellow-500/60"></span>
            <span className="w-3 h-3 rounded-full bg-green-500/60"></span>
            <span className="ml-4">IBouclierRegistry.sol</span>
          </div>
          <pre className="bg-[#0f0f10] text-xs sm:text-sm p-4 sm:p-6 overflow-x-auto font-mono leading-relaxed text-[#e2e8f0]">
{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBouclierRegistry {
    function registerAgent(
        bytes32 agentId, 
        address[] calldata policies
    ) external;
    
    function revokeAgent(bytes32 agentId) external;
    
    function isActive(
        bytes32 agentId
    ) external view returns (bool);
    
    function getPolicies(
        bytes32 agentId
    ) external view returns (address[] memory);

    event AgentRegistered(bytes32 indexed agentId, address owner);
    event AgentRevoked(bytes32 indexed agentId, string reason);
}`}
          </pre>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Register Your Agent</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Assign a verifiable on-chain identity and attach policy guardrails in a single transaction.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/dashboard" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors">Open Dashboard</a>
          <a href="/developers" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors flex items-center gap-2">SDK Docs <ArrowRight size={14} /></a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
