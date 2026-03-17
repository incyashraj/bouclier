"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { FileText, BookOpen, Code, Terminal, Shield, Layers, ArrowRight, ExternalLink, Copy, Check, Zap, Database, Activity, Box, GitBranch } from "lucide-react";
import { motion } from "framer-motion";
import { useState } from "react";

const GITHUB_URL = "https://github.com/incyashraj/bouclier";

function CodeBlock({ title, children }: { title: string; children: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="border border-border rounded-lg overflow-hidden">
      <div className="bg-[#1a1a1c] text-[#a1a1aa] p-3 flex items-center justify-between text-xs font-mono border-b border-[#2a2a2a]">
        <div className="flex items-center gap-3">
          <span className="w-3 h-3 rounded-full bg-red-500/60"></span>
          <span className="w-3 h-3 rounded-full bg-yellow-500/60"></span>
          <span className="w-3 h-3 rounded-full bg-green-500/60"></span>
          <span className="ml-4">{title}</span>
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

export default function DocsPage() {
  return (
    <MarketingPageTemplate
      title="Documentation"
      subtitle="Developer Guide"
      description="Everything you need to understand, integrate, and build on the Bouclier protocol. From installation to deploying custom policies."
      icon={FileText}
    >
      {/* Table of Contents */}
      <div className="mb-16">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">Contents</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
          <nav className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {[
              { label: "Quick Start", anchor: "#quickstart" },
              { label: "Architecture Overview", anchor: "#architecture" },
              { label: "Core Concepts", anchor: "#concepts" },
              { label: "Smart Contracts", anchor: "#contracts" },
              { label: "SDK Integration", anchor: "#sdk" },
              { label: "Writing Policies", anchor: "#policies" },
              { label: "Sentinel Nodes", anchor: "#nodes" },
              { label: "API Reference", anchor: "#api" },
            ].map((item, i) => (
              <a key={i} href={item.anchor} className="flex items-center gap-3 p-2 rounded-md hover:bg-surface/60 transition-colors group">
                <span className="font-mono text-[10px] text-accent w-5">{String(i + 1).padStart(2, "0")}</span>
                <span className="text-sm text-text group-hover:text-accent transition-colors">{item.label}</span>
              </a>
            ))}
          </nav>
        </div>
      </div>

      {/* 1. Quick Start */}
      <div id="quickstart" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">01 — Quick Start</span>
        </div>

        <div className="space-y-6">
          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-lg mb-4">Prerequisites</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                { name: "Node.js", ver: "v18+" },
                { name: "Foundry", ver: "latest" },
                { name: "Git", ver: "v2+" },
                { name: "A wallet", ver: "with Base Sepolia ETH" },
              ].map((p, i) => (
                <div key={i} className="flex items-center justify-between p-3 border border-border/40 rounded-md bg-background">
                  <span className="text-sm font-bold text-text">{p.name}</span>
                  <span className="font-mono text-[11px] text-text-muted">{p.ver}</span>
                </div>
              ))}
            </div>
          </div>

          <CodeBlock title="Terminal — Clone & Install">{`# Clone the monorepo
git clone https://github.com/incyashraj/bouclier.git
cd bouclier

# Install dependencies
npm install

# Build contracts
cd contracts
forge build

# Run tests
forge test`}</CodeBlock>

          <CodeBlock title="Terminal — Deploy to Base Sepolia">{`# Set environment variables
export BASE_SEPOLIA_RPC="https://sepolia.base.org"
export PRIVATE_KEY="your-deployer-private-key"

# Deploy the registry contract
forge script script/DeployRegistry.s.sol \\
  --rpc-url $BASE_SEPOLIA_RPC \\
  --private-key $PRIVATE_KEY \\
  --broadcast

# Deploy a sample policy
forge script script/DeployTransferLimitPolicy.s.sol \\
  --rpc-url $BASE_SEPOLIA_RPC \\
  --private-key $PRIVATE_KEY \\
  --broadcast`}</CodeBlock>
        </div>
      </div>

      {/* 2. Architecture */}
      <div id="architecture" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">02 — Architecture Overview</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-8 bg-surface/30 font-mono text-xs sm:text-sm leading-relaxed text-text-muted overflow-x-auto">
          <pre className="whitespace-pre">{`  ┌─────────────────────────────────────────────┐
  │           AI Agent (any framework)          │
  │  LangChain · AutoGPT · CrewAI · Custom     │
  └──────────────────┬──────────────────────────┘
                     │ action request
                     ▼
  ┌─────────────────────────────────────────────┐
  │           Bouclier SDK                      │
  │  @bouclier/sdk · bouclier-rs · bouclier-py │
  └──────────────────┬──────────────────────────┘
                     │ validate()
                     ▼
  ┌─────────────────────────────────────────────┐
  │         Sentinel Network                    │
  │    Distributed policy verification nodes    │
  └──────────────────┬──────────────────────────┘
                     │ check policies
                     ▼
  ┌─────────────────────────────────────────────┐
  │       On-Chain Registry (Base L2)           │
  │  Agent IDs · Policy Bindings · Revocation   │
  └──────────────────┬──────────────────────────┘
                     │ settlement
                     ▼
  ┌─────────────────────────────────────────────┐
  │         Target Protocol / Contract          │
  │  DeFi · NFT · DAO · Any EVM Contract       │
  └─────────────────────────────────────────────┘`}</pre>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-6">
          {[
            { icon: Database, title: "Registry Layer", desc: "On-chain identity and policy bindings on Base L2. Immutable contract state." },
            { icon: Activity, title: "Verification Layer", desc: "Sentinel nodes intercept and validate agent actions against registered policies." },
            { icon: Shield, title: "Policy Layer", desc: "Composable smart contract modules — each one defines a specific constraint." },
          ].map((item, i) => {
            const Icon = item.icon;
            return (
              <div key={i} className="p-4 border border-border rounded-lg bg-surface/40">
                <Icon size={16} className="text-accent mb-2" />
                <h4 className="font-bold text-text text-sm mb-1">{item.title}</h4>
                <p className="text-xs text-text-muted leading-relaxed">{item.desc}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* 3. Core Concepts */}
      <div id="concepts" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">03 — Core Concepts</span>
        </div>
        <div className="space-y-3">
          {[
            { term: "Agent ID", type: "bytes32", def: "A unique identifier derived from keccak256(abi.encodePacked(owner, metadata, salt)). This is the on-chain identity for an autonomous agent." },
            { term: "Policy Contract", type: "IBouclierPolicy", def: "An immutable smart contract that implements a validate() function. Returns true if the agent action is permitted, false to block." },
            { term: "Policy Binding", type: "mapping", def: "The on-chain link between an Agent ID and an array of policy contract addresses. All policies must pass for an action to proceed." },
            { term: "Sentinel Node", type: "off-chain", def: "A verification node that monitors the Base L2 mempool, intercepts agent transactions, and runs policy checks before settlement." },
            { term: "Revocation", type: "transaction", def: "A single-call operation (revokeAgent) that globally deactivates an agent. All sentinel nodes stop processing its transactions immediately." },
            { term: "Validation Result", type: "struct", def: "The response from a policy check: { valid: bool, reason: string }. On failure, the sentinel node blocks the action and logs the reason." },
          ].map((item, i) => (
            <div key={i} className="p-4 border border-border rounded-lg bg-surface/40">
              <div className="flex items-center gap-3 mb-1">
                <span className="font-mono text-accent font-bold text-sm">{item.term}</span>
                <span className="font-mono text-[10px] text-text-muted bg-background border border-border px-2 py-0.5 rounded">{item.type}</span>
              </div>
              <p className="text-xs text-text-muted leading-relaxed">{item.def}</p>
            </div>
          ))}
        </div>
      </div>

      {/* 4. Smart Contracts */}
      <div id="contracts" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">04 — Smart Contracts</span>
        </div>

        <div className="space-y-6">
          <CodeBlock title="IBouclierRegistry.sol">{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBouclierRegistry {
    /// @notice Register a new agent with attached policies
    /// @param agentId Unique bytes32 identifier for the agent
    /// @param policies Array of policy contract addresses
    function registerAgent(
        bytes32 agentId,
        address[] calldata policies
    ) external;

    /// @notice Revoke an agent — stops all sentinel processing
    /// @param agentId The agent to revoke
    function revokeAgent(bytes32 agentId) external;

    /// @notice Check if an agent is currently active
    function isActive(bytes32 agentId) external view returns (bool);

    /// @notice Get all policies attached to an agent
    function getPolicies(
        bytes32 agentId
    ) external view returns (address[] memory);

    /// @notice Add a policy to an existing agent
    function addPolicy(bytes32 agentId, address policy) external;

    /// @notice Remove a policy from an agent
    function removePolicy(bytes32 agentId, address policy) external;

    event AgentRegistered(bytes32 indexed agentId, address indexed owner);
    event AgentRevoked(bytes32 indexed agentId);
    event PolicyAdded(bytes32 indexed agentId, address indexed policy);
    event PolicyRemoved(bytes32 indexed agentId, address indexed policy);
}`}</CodeBlock>

          <CodeBlock title="IBouclierPolicy.sol">{`// SPDX-License-Identifier: MIT
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
}`}</CodeBlock>

          <CodeBlock title="TransferLimitPolicy.sol — Example">{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBouclierPolicy} from "./IBouclierPolicy.sol";

/// @title TransferLimitPolicy
/// @notice Enforces a maximum ETH transfer per transaction
contract TransferLimitPolicy is IBouclierPolicy {
    uint256 public immutable maxTransferWei;

    constructor(uint256 _maxTransferWei) {
        maxTransferWei = _maxTransferWei;
    }

    function validate(
        bytes32, /* agentId */
        address, /* target */
        uint256 value,
        bytes calldata /* data */
    ) external view override returns (bool valid) {
        return value <= maxTransferWei;
    }
}`}</CodeBlock>
        </div>
      </div>

      {/* 5. SDK Integration */}
      <div id="sdk" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">05 — SDK Integration</span>
        </div>

        <div className="space-y-6">
          <div className="border border-amber-200 bg-amber-50 rounded-lg p-4 flex items-start gap-3">
            <Zap size={16} className="text-amber-600 mt-0.5 flex-shrink-0" />
            <p className="text-xs text-text-muted leading-relaxed">The TypeScript SDK is in active development. Install from the monorepo while the npm package is being prepared.</p>
          </div>

          <CodeBlock title="install.sh">{`# From the monorepo root
cd sdk
npm install
npm run build

# Link for local development
npm link`}</CodeBlock>

          <CodeBlock title="register-agent.ts">{`import { BouclierClient } from "@bouclier/sdk";
import { createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// Initialize the Bouclier client
const account = privateKeyToAccount(process.env.PRIVATE_KEY as \`0x\${string}\`);
const bouclier = new BouclierClient({
  chain: baseSepolia,
  transport: http(process.env.BASE_SEPOLIA_RPC),
  account,
});

// Generate an agent ID
const agentId = bouclier.generateAgentId({
  name: "treasury-bot",
  version: "1.0.0",
  salt: "unique-salt-value",
});

// Register with policies
const tx = await bouclier.registerAgent({
  agentId,
  policies: [
    "0x...TransferLimitPolicy",
    "0x...ScopeRestrictionPolicy",
  ],
});

console.log("Agent registered:", tx.hash);
console.log("Agent ID:", agentId);`}</CodeBlock>

          <CodeBlock title="validate-action.ts">{`// Validate an action before execution
const result = await bouclier.validate({
  agentId,
  target: "0x...TargetContract",
  value: 0n,
  data: encodedCalldata,
});

if (result.valid) {
  // All policies passed — safe to execute
  const tx = await walletClient.sendTransaction({
    to: target,
    value: 0n,
    data: encodedCalldata,
  });
} else {
  console.error("Policy violation:", result.reason);
}

// Check agent status
const isActive = await bouclier.isActive(agentId);

// Get attached policies
const policies = await bouclier.getPolicies(agentId);

// Revoke in emergency
await bouclier.revokeAgent(agentId);`}</CodeBlock>
        </div>
      </div>

      {/* 6. Writing Policies */}
      <div id="policies" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">06 — Writing Custom Policies</span>
        </div>

        <div className="space-y-6">
          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-base mb-3">Policy Design Rules</h3>
            <ul className="space-y-2">
              {[
                "Policies must implement IBouclierPolicy with a pure/view validate() function",
                "Policies should be stateless where possible — use immutable constructor params",
                "validate() must return true to allow and false to block — no reverts",
                "Multiple policies are checked in sequence — ALL must pass",
                "Deploy as immutable contracts — no upgradeable proxies for trust guarantees",
              ].map((rule, i) => (
                <li key={i} className="flex items-start gap-2 text-xs text-text-muted leading-relaxed">
                  <span className="text-accent font-mono text-[10px] mt-0.5">{String(i + 1).padStart(2, "0")}</span>
                  {rule}
                </li>
              ))}
            </ul>
          </div>

          <CodeBlock title="ScopeRestrictionPolicy.sol — Custom Example">{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBouclierPolicy} from "./IBouclierPolicy.sol";

/// @title ScopeRestrictionPolicy  
/// @notice Restricts an agent to only interact with whitelisted contracts
contract ScopeRestrictionPolicy is IBouclierPolicy {
    mapping(address => bool) public allowedTargets;
    
    constructor(address[] memory _targets) {
        for (uint i = 0; i < _targets.length; i++) {
            allowedTargets[_targets[i]] = true;
        }
    }

    function validate(
        bytes32, /* agentId */
        address target,
        uint256, /* value */
        bytes calldata /* data */
    ) external view override returns (bool valid) {
        return allowedTargets[target];
    }
}`}</CodeBlock>

          <CodeBlock title="test/ScopeRestrictionPolicy.t.sol — Testing">{`// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ScopeRestrictionPolicy.sol";

contract ScopeRestrictionPolicyTest is Test {
    ScopeRestrictionPolicy policy;
    address allowed = address(0xA);
    address blocked = address(0xB);

    function setUp() public {
        address[] memory targets = new address[](1);
        targets[0] = allowed;
        policy = new ScopeRestrictionPolicy(targets);
    }

    function testAllowedTarget() public view {
        bool valid = policy.validate(
            bytes32(0), allowed, 0, ""
        );
        assertTrue(valid);
    }

    function testBlockedTarget() public view {
        bool valid = policy.validate(
            bytes32(0), blocked, 0, ""
        );
        assertFalse(valid);
    }

    function testFuzz(address target) public view {
        bool valid = policy.validate(
            bytes32(0), target, 0, ""
        );
        assertEq(valid, target == allowed);
    }
}`}</CodeBlock>
        </div>
      </div>

      {/* 7. Sentinel Nodes */}
      <div id="nodes" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">07 — Sentinel Nodes</span>
        </div>

        <div className="space-y-6">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {[
              { title: "Monitor", desc: "Scans the Base L2 mempool for transactions from registered agents" },
              { title: "Verify", desc: "Runs each pending action through the agent's attached policy contracts" },
              { title: "Enforce", desc: "Blocks invalid transactions and logs violations to the on-chain audit trail" },
            ].map((item, i) => (
              <div key={i} className="p-4 border border-border rounded-lg bg-surface/40 text-center">
                <div className="w-8 h-8 rounded-full border border-accent/30 bg-accent/10 flex items-center justify-center text-accent font-mono text-xs font-bold mx-auto mb-3">{i + 1}</div>
                <h4 className="font-bold text-text text-sm mb-1">{item.title}</h4>
                <p className="text-xs text-text-muted">{item.desc}</p>
              </div>
            ))}
          </div>

          <CodeBlock title="Terminal — Run a Testnet Node">{`# Clone and build
git clone https://github.com/incyashraj/bouclier.git
cd bouclier/node
cargo build --release

# Initialize configuration
./target/release/bouclier-node init --network base-sepolia

# Start the sentinel node
./target/release/bouclier-node start \\
  --rpc $BASE_SEPOLIA_RPC \\
  --registry 0x...RegistryAddress`}</CodeBlock>
        </div>
      </div>

      {/* 8. API Reference */}
      <div id="api" className="mb-20 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">08 — API Reference</span>
        </div>

        <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
          <table className="w-full text-sm font-mono min-w-[500px]">
            <thead className="text-[11px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
              <tr>
                <th className="font-normal py-3 px-4 text-left">Method</th>
                <th className="font-normal py-3 px-4 text-left">Parameters</th>
                <th className="font-normal py-3 px-4 text-left">Returns</th>
              </tr>
            </thead>
            <tbody>
              {[
                { method: "registerAgent", params: "agentId, policies[]", returns: "TransactionHash" },
                { method: "revokeAgent", params: "agentId", returns: "TransactionHash" },
                { method: "isActive", params: "agentId", returns: "boolean" },
                { method: "getPolicies", params: "agentId", returns: "address[]" },
                { method: "addPolicy", params: "agentId, policy", returns: "TransactionHash" },
                { method: "removePolicy", params: "agentId, policy", returns: "TransactionHash" },
                { method: "validate", params: "agentId, target, value, data", returns: "{ valid, reason }" },
                { method: "generateAgentId", params: "name, version, salt", returns: "bytes32" },
              ].map((r, i) => (
                <tr key={i} className="border-b border-border/40 hover:bg-surface/40 transition-colors">
                  <td className="py-3 px-4 text-accent font-bold text-xs">{r.method}</td>
                  <td className="py-3 px-4 text-text-muted text-xs">{r.params}</td>
                  <td className="py-3 px-4 text-text text-xs">{r.returns}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Start Building</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">Clone the repo, deploy to testnet, and register your first agent.</p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">View on GitHub <ExternalLink size={14} /></a>
          <a href="/developers" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors flex items-center gap-2">SDK Reference <ArrowRight size={14} /></a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
