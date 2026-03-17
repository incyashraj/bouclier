"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Code, Box, Terminal, BookOpen, ArrowRight, Clock, Zap, Shield, Database, ExternalLink, Copy, Check, Layers, GitBranch } from "lucide-react";
import { motion } from "framer-motion";
import { useState } from "react";

const GITHUB_URL = "https://github.com/incyashraj/bouclier";

function CodeBlock({ title, lang, children }: { title: string; lang?: string; children: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="border border-border rounded-lg overflow-hidden">
      <div className="bg-[#1a1a1c] text-[#a1a1aa] p-3 flex items-center justify-between text-xs font-mono border-b border-[#2a2a2a]">
        <div className="flex items-center gap-3">
          <span className="w-3 h-3 rounded-full bg-red-500/60"></span>
          <span className="w-3 h-3 rounded-full bg-yellow-500/60"></span>
          <span className="w-3 h-3 rounded-full bg-green-500/60"></span>
          <span className="ml-4">{title}</span>
          {lang && <span className="text-[10px] text-[#555] ml-2">{lang}</span>}
        </div>
        <button onClick={() => { navigator.clipboard.writeText(children); setCopied(true); setTimeout(() => setCopied(false), 2000); }} className="hover:text-white transition-colors">
          {copied ? <Check size={12} className="text-emerald-500" /> : <Copy size={12} />}
        </button>
      </div>
      <pre className="bg-[#0f0f10] text-xs sm:text-sm p-4 sm:p-6 overflow-x-auto font-mono leading-relaxed text-[#e2e8f0]">
        {children}
      </pre>
    </div>
  );
}

const integrations = [
  { 
    name: "LangChain", 
    desc: "Wrap any LangChain agent tool with Bouclier policy validation before execution.",
    code: `import { BouclierClient } from "@bouclier/sdk";
import { DynamicTool } from "langchain/tools";

const bouclier = new BouclierClient({ /* config */ });

// Wrap a tool with Bouclier validation
const safeTool = new DynamicTool({
  name: "safe-transfer",
  description: "Transfer tokens with policy enforcement",
  func: async (input) => {
    const action = parseTransferInput(input);
    
    // Validate against all attached policies
    const check = await bouclier.validate({
      agentId: AGENT_ID,
      target: action.contract,
      value: action.value,
      data: action.calldata,
    });
    
    if (!check.valid) {
      return \`Blocked: \${check.reason}\`;
    }
    
    return await executeTransfer(action);
  },
});`
  },
  {
    name: "AutoGPT / Custom Agents",
    desc: "Add a pre-execution hook to any agent loop — validate every outbound transaction.",
    code: `import { BouclierClient } from "@bouclier/sdk";

const bouclier = new BouclierClient({ /* config */ });

// Agent execution loop
async function agentStep(agentId, action) {
  // 1. Validate before execution
  const result = await bouclier.validate({
    agentId,
    target: action.to,
    value: action.value,
    data: action.data,
  });

  if (!result.valid) {
    console.error("Policy blocked:", result.reason);
    return { success: false, reason: result.reason };
  }

  // 2. Execute the validated action
  const tx = await wallet.sendTransaction(action);
  return { success: true, hash: tx.hash };
}`
  },
  {
    name: "Python (AI/ML Pipelines)",
    desc: "Call the Bouclier registry directly from Python using web3.py for ML agent pipelines.",
    code: `from web3 import Web3

w3 = Web3(Web3.HTTPProvider("https://sepolia.base.org"))

# Load the registry contract
registry = w3.eth.contract(
    address="0x...RegistryAddress",
    abi=REGISTRY_ABI,
)

# Check if an agent is active
is_active = registry.functions.isActive(agent_id).call()

# Get attached policies
policies = registry.functions.getPolicies(agent_id).call()

# Validate via policy contract directly
policy = w3.eth.contract(address=policies[0], abi=POLICY_ABI)
is_valid = policy.functions.validate(
    agent_id, target, value, calldata
).call()`
  },
];

export default function DevelopersPage() {
  return (
    <MarketingPageTemplate
      title="Developers"
      subtitle="Build With Bouclier"
      description="Integrate policy-enforced guardrails into any autonomous agent. SDKs, code samples, and framework-specific guides."
      icon={Code}
    >
      {/* Quick Links */}
      <div className="mb-16">
        <div className="flex flex-wrap gap-3">
          <a href="/docs#quickstart" className="inline-flex items-center gap-2 px-4 py-2 bg-accent text-white rounded-md font-mono text-xs hover:bg-accent-hover transition-colors">
            <Zap size={12} /> Quick Start Guide
          </a>
          <a href="/docs#contracts" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md font-mono text-xs text-text hover:bg-surface transition-colors">
            <Code size={12} /> Contract Reference
          </a>
          <a href="/docs#api" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md font-mono text-xs text-text hover:bg-surface transition-colors">
            <Database size={12} /> API Reference
          </a>
          <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 px-4 py-2 border border-border rounded-md font-mono text-xs text-text hover:bg-surface transition-colors">
            <GitBranch size={12} /> Source Code <ExternalLink size={10} className="text-text-muted" />
          </a>
        </div>
      </div>

      {/* SDK Status Banner */}
      <div className="mb-16">
        <div className="border border-amber-200 bg-amber-50 rounded-lg p-4 sm:p-5 flex items-start gap-3">
          <Clock size={18} className="text-amber-600 mt-0.5 flex-shrink-0" />
          <div>
            <p className="text-sm font-bold text-text mb-1">Early Development Phase</p>
            <p className="text-xs text-text-muted leading-relaxed">SDKs are under active development in the <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="text-accent underline">monorepo</a>. The API surface shown below represents the intended design — interfaces may change before the stable release.</p>
          </div>
        </div>
      </div>

      {/* 5 Minute Integration */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">5-Minute Integration</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 mb-8">
          {[
            { step: "01", title: "Clone", desc: "Clone the monorepo and build the SDK" },
            { step: "02", title: "Deploy", desc: "Deploy registry + policies to Base Sepolia" },
            { step: "03", title: "Register", desc: "Register your agent with policy bindings" },
            { step: "04", title: "Validate", desc: "Wrap agent actions with validate() calls" },
          ].map((s, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 * i }} className="p-4 border border-border rounded-lg bg-surface/40 relative">
              <div className="absolute -top-3 left-4 bg-accent text-white text-[10px] font-mono px-2 py-0.5 rounded-sm">{s.step}</div>
              <h4 className="font-bold text-text text-sm mt-2 mb-1">{s.title}</h4>
              <p className="text-[11px] text-text-muted leading-relaxed">{s.desc}</p>
            </motion.div>
          ))}
        </div>

        <CodeBlock title="Terminal — Full Setup" lang="bash">{`# Clone the monorepo
git clone https://github.com/incyashraj/bouclier.git && cd bouclier

# Install & build
npm install && cd contracts && forge build && cd ../sdk && npm run build

# Deploy to Base Sepolia (set PRIVATE_KEY and BASE_SEPOLIA_RPC)
cd ../contracts
forge script script/DeployRegistry.s.sol --rpc-url $BASE_SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast

# Run tests
forge test -vvv`}</CodeBlock>
      </div>

      {/* Framework Integrations */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Framework Integrations</span>
        </div>

        <div className="space-y-8">
          {integrations.map((integration, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }}>
              <div className="flex items-center gap-3 mb-3">
                <span className="font-bold text-text">{integration.name}</span>
                <span className="text-xs text-text-muted">— {integration.desc}</span>
              </div>
              <CodeBlock title={`${integration.name.toLowerCase().replace(/[^a-z]/g, "-")}-integration`} lang={i === 2 ? "python" : "typescript"}>
                {integration.code}
              </CodeBlock>
            </motion.div>
          ))}
        </div>
      </div>

      {/* SDK Packages */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">SDK Packages</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
          {[
            { name: "@bouclier/sdk", lang: "TypeScript", desc: "Core SDK for registering agents, attaching policies, and querying the registry. Built on viem.", status: "In Development", path: "sdk/" },
            { name: "@bouclier/react", lang: "React", desc: "React hooks — useBouclier(), useAgent(), usePolicy(). Built on wagmi + the core SDK.", status: "Planned", path: "sdk/react/" },
            { name: "bouclier-rs", lang: "Rust", desc: "Native Rust client for sentinel nodes and high-performance contract interaction.", status: "Planned", path: "node/" },
            { name: "bouclier-py", lang: "Python", desc: "Python bindings for AI/ML pipelines. Integrates with web3.py for direct contract calls.", status: "Planned", path: "sdk/python/" },
          ].map((sdk, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.06 * i }} className="p-5 sm:p-6 border border-border rounded-lg bg-surface/40 hover:bg-surface/70 transition-colors">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <span className="font-mono text-accent text-sm font-bold">{sdk.name}</span>
                  <span className="ml-2 font-mono text-[10px] text-text-muted px-2 py-0.5 bg-background border border-border rounded">{sdk.lang}</span>
                </div>
                <span className="font-mono text-[10px] text-amber-600 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded flex-shrink-0">{sdk.status}</span>
              </div>
              <p className="text-xs text-text-muted leading-relaxed mb-3">{sdk.desc}</p>
              <a href={`${GITHUB_URL}/tree/main/${sdk.path}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1.5 text-[11px] font-mono text-accent hover:underline">
                View source <ExternalLink size={10} />
              </a>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Integration Patterns */}
      <div className="mb-20">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Design Patterns</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {[
            { icon: Shield, title: "Pre-Execution Hook", desc: "Validate every agent action before it hits the mempool. Block invalid transactions at the SDK layer." },
            { icon: Layers, title: "Composable Policies", desc: "Stack multiple policy contracts per agent. Transfer limits + scope restrictions + rate limiters — all enforced together." },
            { icon: Box, title: "Framework Agnostic", desc: "Works with LangChain, AutoGPT, CrewAI, or any custom agent. One validate() call wraps any outbound action." },
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
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Start Building</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Clone the repo, check the docs, and ship your first policy-enforced agent.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href="/docs" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">Full Documentation <ArrowRight size={14} /></a>
          <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors flex items-center gap-2">GitHub <ExternalLink size={14} /></a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
