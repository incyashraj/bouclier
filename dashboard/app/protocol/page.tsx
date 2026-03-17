"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { ShieldCheck, Layers, Lock, Zap, Eye, GitBranch, Box } from "lucide-react";
import { motion } from "framer-motion";

const features = [
  { icon: Lock, title: "Immutable Guardrails", desc: "Policy contracts are deployed as immutable bytecode. Once set, not even the deployer can modify boundaries." },
  { icon: Layers, title: "Composable Policies", desc: "Stack multiple policy modules per agent — transfer limits, scope restrictions, rate limiters — all composable." },
  { icon: Zap, title: "Sub-200ms Verification", desc: "Sentinel nodes verify agent actions against policy constraints before settlement, targeting sub-200ms latency." },
  { icon: Eye, title: "Full Auditability", desc: "Every policy check result is recorded on-chain. Complete, tamper-proof audit trails for every agent action." },
  { icon: GitBranch, title: "Permissionless", desc: "Anyone can register an agent, deploy a policy, or run a sentinel node. No centralized gatekeepers." },
  { icon: Box, title: "ZK-Ready Architecture", desc: "Protocol is designed for future ZK proof integration — prove policy adherence without revealing proprietary models." },
];

const layers = [
  { name: "Application Layer", desc: "AI Agents (LangChain, AutoGPT, Custom)", color: "border-blue-200 bg-blue-50" },
  { name: "Verification Layer", desc: "Bouclier SDK + Sentinel Network", color: "border-accent/30 bg-accent/5" },
  { name: "Policy Layer", desc: "IBouclierPolicy Composable Modules", color: "border-emerald-200 bg-emerald-50" },
  { name: "Registry Layer", desc: "Agent IDs, Policy Bindings, Revocation", color: "border-accent/30 bg-accent/5" },
  { name: "Settlement Layer", desc: "Base L2 — Immutable On-Chain State", color: "border-purple-200 bg-purple-50" },
];

export default function ProtocolPage() {
  return (
    <MarketingPageTemplate
      title="Protocol"
      subtitle="Core Infrastructure"
      description="The absolute base layer for autonomous AI interactions. Bouclier enforces strict on-chain limits using composable policy contracts and a decentralized verification network."
      icon={ShieldCheck}
    >
      {/* Feature Grid */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Design Principles</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {features.map((feature, i) => {
            const Icon = feature.icon;
            return (
              <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 * i }} className="p-6 sm:p-8 border border-border bg-surface/30 hover:bg-surface/60 transition-colors rounded-lg group text-left">
                <div className="w-10 h-10 rounded-lg border border-border flex items-center justify-center bg-background mb-4">
                  <Icon size={18} className="text-accent" />
                </div>
                <h3 className="text-base sm:text-lg font-bold text-text mb-3">{feature.title}</h3>
                <p className="text-xs sm:text-sm text-text-muted leading-relaxed">{feature.desc}</p>
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* Architecture Stack */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Architecture Stack</span>
        </div>
        <div className="border border-border rounded-lg p-6 sm:p-8 bg-surface/30">
          <div className="max-w-2xl mx-auto space-y-3">
            {layers.map((layer, i) => (
              <div key={i}>
                <div className={`p-4 border rounded-md ${layer.color} text-center`}>
                  <div className="font-bold text-text text-sm">{layer.name}</div>
                  <div className="font-mono text-[10px] text-text-muted mt-1">{layer.desc}</div>
                </div>
                {i < layers.length - 1 && <div className="w-[1px] h-3 bg-border mx-auto"></div>}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Solidity Interface */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Policy Interface</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#1a1a1c] text-[#a1a1aa] p-3 flex items-center gap-3 text-xs font-mono border-b border-[#2a2a2a]">
            <span className="w-3 h-3 rounded-full bg-red-500/60"></span>
            <span className="w-3 h-3 rounded-full bg-yellow-500/60"></span>
            <span className="w-3 h-3 rounded-full bg-green-500/60"></span>
            <span className="ml-4">IBouclierPolicy.sol</span>
          </div>
          <pre className="bg-[#0f0f10] text-xs sm:text-sm p-4 sm:p-6 overflow-x-auto font-mono leading-relaxed text-[#e2e8f0]">
{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBouclierPolicy {
    /// @notice Validate an agent action against this policy
    /// @param agentId The registered agent identifier  
    /// @param target The contract being called
    /// @param value The ETH value being sent
    /// @param data The calldata being executed
    /// @return valid Whether the action is permitted
    function validate(
        bytes32 agentId,
        address target,
        uint256 value,
        bytes calldata data
    ) external view returns (bool valid);
}`}
          </pre>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Explore the Protocol</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Read the technical documentation or start building with the SDK.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/docs" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors">Documentation</a>
          <a href="/developers" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">Developer SDK</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
