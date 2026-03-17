"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Github, ExternalLink, GitBranch, FileCode, BookOpen, ArrowRight, Star, GitFork, Copy, Check } from "lucide-react";
import { motion } from "framer-motion";
import { useState } from "react";

const GITHUB_URL = "https://github.com/incyashraj/bouclier";

const structure = [
  { path: "contracts/", desc: "Solidity smart contracts — BouclierRegistry, IBouclierPolicy, and reference policy modules", lang: "Solidity" },
  { path: "sdk/", desc: "TypeScript SDK for agent registration, policy management, and validation queries", lang: "TypeScript" },
  { path: "dashboard/", desc: "This website — Next.js 16 static-export app deployed to IPFS via bouclier.eth", lang: "TypeScript" },
  { path: "node/", desc: "Sentinel node reference implementation for mempool monitoring and policy verification", lang: "Rust" },
  { path: "docs/", desc: "Protocol specification, developer guides, and architecture documentation", lang: "MDX" },
  { path: "scripts/", desc: "Deployment scripts, test utilities, and CI/CD workflows", lang: "Shell" },
];

function CopyCloneButton() {
  const [copied, setCopied] = useState(false);
  const cmd = "git clone https://github.com/incyashraj/bouclier.git";
  return (
    <button
      onClick={() => { navigator.clipboard.writeText(cmd); setCopied(true); setTimeout(() => setCopied(false), 2000); }}
      className="w-full flex items-center gap-3 bg-[#0f0f10] border border-[#2a2a2a] rounded-lg p-3 sm:p-4 font-mono text-xs sm:text-sm text-[#e2e8f0] hover:border-accent/40 transition-colors group"
    >
      <span className="text-emerald-500">$</span>
      <span className="flex-1 text-left truncate">{cmd}</span>
      {copied ? <Check size={14} className="text-emerald-500 flex-shrink-0" /> : <Copy size={14} className="text-[#a1a1aa] group-hover:text-accent flex-shrink-0 transition-colors" />}
    </button>
  );
}

export default function GitHubPage() {
  return (
    <MarketingPageTemplate
      title="Open Source"
      subtitle="GitHub"
      description="Bouclier is fully open source under the MIT license. Every contract, SDK, and node implementation is publicly auditable."
      icon={Github}
    >
      {/* Clone & Quick Links */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Quick Start</span>
        </div>
        <div className="space-y-4">
          <CopyCloneButton />
          <div className="flex flex-wrap gap-3">
            <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md bg-surface/50 font-mono text-xs text-text hover:bg-surface transition-colors">
              <Github size={14} /> View Repository <ExternalLink size={10} className="text-text-muted" />
            </a>
            <a href={`${GITHUB_URL}/issues`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md bg-surface/50 font-mono text-xs text-text hover:bg-surface transition-colors">
              Issues <ExternalLink size={10} className="text-text-muted" />
            </a>
            <a href={`${GITHUB_URL}/pulls`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md bg-surface/50 font-mono text-xs text-text hover:bg-surface transition-colors">
              Pull Requests <ExternalLink size={10} className="text-text-muted" />
            </a>
          </div>
        </div>
      </div>

      {/* Philosophy */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Open Source Philosophy</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30 space-y-3">
          <p className="text-sm text-text leading-relaxed">
            A trust layer for AI agents must itself be trustless. Every line of Bouclier code is open source — from the core smart contracts to the sentinel node implementation. <strong>Verify, don&apos;t trust.</strong>
          </p>
          <div className="flex flex-wrap gap-3">
            {["MIT License", "Monorepo", "Open Development", "Community Governed"].map((tag, i) => (
              <span key={i} className="font-mono text-[10px] text-text-muted bg-background border border-border px-3 py-1 rounded">{tag}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Repository Structure */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Repository Structure</span>
        </div>
        <div className="border border-border rounded-lg overflow-hidden">
          <div className="bg-[#FAFAFA] border-b border-border p-3 sm:p-4 flex items-center gap-3 text-xs font-mono text-text-muted">
            <Github size={14} />
            <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="hover:text-accent transition-colors">incyashraj/bouclier</a>
          </div>
          <div className="divide-y divide-border/40">
            {structure.map((item, i) => (
              <motion.a key={i} href={`${GITHUB_URL}/tree/main/${item.path.replace("/","")}`} target="_blank" rel="noopener noreferrer" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.04 * i }} className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-6 hover:bg-surface/50 transition-colors group block">
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <span className="font-mono text-accent font-bold text-sm group-hover:underline">{item.path}</span>
                  <span className="font-mono text-[10px] text-text-muted bg-background border border-border px-2 py-0.5 rounded hidden sm:inline">{item.lang}</span>
                </div>
                <p className="text-xs text-text-muted leading-relaxed flex-1">{item.desc}</p>
              </motion.a>
            ))}
          </div>
        </div>
      </div>

      {/* Contributing */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Contributing</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {[
            { icon: GitBranch, title: "Fork & PR", desc: "Fork the repo, create a branch, make your changes, and submit a pull request. All contributions welcome." },
            { icon: BookOpen, title: "Documentation", desc: "Improve docs, write tutorials, or add code examples. Check the docs/ directory to get started." },
            { icon: Github, title: "Report Issues", desc: "Found a bug or have a feature request? Open an issue with reproduction steps." },
          ].map((item, i) => {
            const Icon = item.icon;
            return (
              <motion.div key={i} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className="p-5 sm:p-6 border border-border rounded-lg bg-surface/40">
                <div className="w-10 h-10 rounded-lg border border-border flex items-center justify-center bg-background mb-4">
                  <Icon size={18} className="text-accent" />
                </div>
                <h3 className="font-bold text-text text-sm mb-2">{item.title}</h3>
                <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <Github className="w-8 h-8 text-accent mx-auto mb-4" />
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">View on GitHub</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Star the repo, fork the code, and join the development effort.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">incyashraj/bouclier <ExternalLink size={14} /></a>
          <a href="/bug-bounty" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors">Bug Bounty</a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
