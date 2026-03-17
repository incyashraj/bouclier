"use client";

import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { FileText, ArrowRight, ExternalLink, Copy, Check, Zap, Database, Activity, Shield, AlertTriangle, Eye, Clock, Ban } from "lucide-react";
import { useState } from "react";

const GITHUB_URL = "https://github.com/incyashraj/bouclier";
const BASESCAN = "https://sepolia.basescan.org/address/";

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

function InfoBox({ type = "info", children }: { type?: "info" | "warning" | "tip"; children: React.ReactNode }) {
  const styles = {
    info: { border: "border-blue-200", bg: "bg-blue-50", icon: <Zap size={14} className="text-blue-600 mt-0.5 shrink-0" /> },
    warning: { border: "border-amber-200", bg: "bg-amber-50", icon: <AlertTriangle size={14} className="text-amber-600 mt-0.5 shrink-0" /> },
    tip: { border: "border-emerald-200", bg: "bg-emerald-50", icon: <Check size={14} className="text-emerald-600 mt-0.5 shrink-0" /> },
  };
  const s = styles[type];
  return (
    <div className={`${s.border} ${s.bg} border rounded-lg p-4 flex items-start gap-3`}>
      {s.icon}
      <div className="text-xs text-text-muted leading-relaxed">{children}</div>
    </div>
  );
}

const CONTRACT_ADDRESSES = {
  AgentRegistry: "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
  PermissionVault: "0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
  SpendTracker: "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
  RevocationRegistry: "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
  AuditLogger: "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE",
};

export default function DocsPage() {
  return (
    <MarketingPageTemplate
      title="Developer Guide"
      subtitle="Documentation"
      description="Everything you need to integrate Bouclier into your AI agent. From installation to querying audit trails."
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
              { label: "Architecture", anchor: "#architecture" },
              { label: "Core Concepts", anchor: "#concepts" },
              { label: "Contract Addresses", anchor: "#contracts" },
              { label: "TypeScript SDK", anchor: "#sdk-ts" },
              { label: "Python SDK", anchor: "#sdk-py" },
              { label: "Granting Permissions", anchor: "#granting" },
              { label: "Spend Tracking", anchor: "#spending" },
              { label: "Revocation", anchor: "#revocation" },
              { label: "Querying the Audit Trail", anchor: "#audit" },
              { label: "Session Keys", anchor: "#sessions" },
              { label: "Framework Integrations", anchor: "#frameworks" },
              { label: "Contract API Reference", anchor: "#api" },
              { label: "SDK Method Reference", anchor: "#sdk-ref" },
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
                { name: "Base Sepolia ETH", ver: "from faucet" },
              ].map((p, i) => (
                <div key={i} className="flex items-center justify-between p-3 border border-border/40 rounded-md bg-background">
                  <span className="text-sm font-bold text-text">{p.name}</span>
                  <span className="font-mono text-[11px] text-text-muted">{p.ver}</span>
                </div>
              ))}
            </div>
          </div>

          <CodeBlock title="Terminal — Install the TypeScript SDK">{`npm install @bouclier/sdk viem`}</CodeBlock>

          <CodeBlock title="Terminal — Or install the Python SDK">{`pip install bouclier-sdk`}</CodeBlock>

          <CodeBlock title="quickstart.ts — Your first integration">{`import { BouclierClient } from "@bouclier/sdk";
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http("https://sepolia.base.org"),
});

const bouclier = new BouclierClient({
  publicClient,
  addresses: {
    agentRegistry:      "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
    permissionVault:    "0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
    spendTracker:       "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
    revocationRegistry: "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
    auditLogger:        "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE",
  },
});

// Look up an agent
const agentId = await bouclier.getAgentId("0xYourAgentWallet");
const agent = await bouclier.resolveAgent(agentId);
console.log(agent.status, agent.model);

// Check permissions
const scope = await bouclier.getActiveScope(agentId);
console.log("Daily cap:", scope.dailySpendCapUSD);
console.log("Expires:", new Date(Number(scope.validUntil) * 1000));

// Check revocation
const revoked = await bouclier.isRevoked(agentId);
console.log("Revoked:", revoked);`}</CodeBlock>
        </div>
      </div>

      {/* 2. Architecture */}
      <div id="architecture" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">02 — Architecture</span>
        </div>
        <div className="border border-border rounded-lg p-5 sm:p-8 bg-surface/30 font-mono text-xs sm:text-sm leading-relaxed text-text-muted overflow-x-auto">
          <pre className="whitespace-pre">{`  Human / Agent Owner
        |
        |  EIP-712 signed PermissionScope grant
        v
  +---------------------------------------------+
  |          PermissionVault (ERC-7579)         |
  |  Validates every UserOp against the grant:  |
  |  protocols, selectors, tokens, spend caps,  |
  |  time windows, chain ID                     |
  +------+------------+-------------+-----------+
         |            |             |
         v            v             v
  +-----------+ +-----------+ +---------------+
  |  Agent    | | Revocation| |   Spend       |
  |  Registry | | Registry  | |   Tracker     |
  |           | |           | |               |
  | Identity  | | Kill      | | Chainlink     |
  | + status  | | switch    | | rolling USD   |
  +-----------+ +-----------+ +---------------+
         |            |             |
         +------------+-------------+
                      v
               +-------------+
               | AuditLogger |
               | On-chain +  |
               | IPFS anchor |
               +-------------+`}</pre>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 mt-6">
          {[
            { icon: Database, title: "AgentRegistry", desc: "On-chain DID. Register agents, track status, resolve by wallet." },
            { icon: Shield, title: "PermissionVault", desc: "ERC-7579 validator module. Enforces scoped permissions on every UserOp." },
            { icon: Activity, title: "SpendTracker", desc: "Rolling-window spend accounting with Chainlink oracles + TWAP fallback." },
            { icon: Ban, title: "RevocationRegistry", desc: "Kill switch. Instant emergency revoke or 24h timelock reinstatement." },
            { icon: Eye, title: "AuditLogger", desc: "Tamper-proof event log. Every action hashed, timestamped, IPFS-anchored." },
          ].map((item, i) => (
            <div key={i} className="p-4 border border-border rounded-lg bg-surface/40">
              <item.icon size={16} className="text-accent mb-2" />
              <h4 className="font-bold text-text text-xs mb-1">{item.title}</h4>
              <p className="text-[11px] text-text-muted leading-relaxed">{item.desc}</p>
            </div>
          ))}
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
            { term: "Agent ID", type: "bytes32", def: "Unique on-chain identity derived from keccak256(agentWallet, owner, registeredAt). Created by AgentRegistry.register()." },
            { term: "PermissionScope", type: "struct", def: "The full policy grant for an agent: which protocols it can call, which tokens it can move, daily/per-tx USD caps, time window, expiry. Signed via EIP-712 by the agent owner." },
            { term: "Revocation", type: "on-chain", def: "Calling revoke() on RevocationRegistry sets a permanent flag. All subsequent validateUserOp() calls for that agent return VALIDATION_FAILED. Reinstatement requires a 24-hour timelock." },
            { term: "Rolling Spend", type: "ring buffer", def: "SpendTracker records every USD-denominated spend in a ring buffer (max 1000 entries). getRollingSpend(agentId, windowSeconds) sums entries within the window." },
            { term: "Audit Record", type: "struct", def: "Logged by AuditLogger on every agent action: eventId, agentId, target, selector, usdAmount, allowed/denied, violationType, IPFS CID." },
            { term: "ERC-7579 Module", type: "validator", def: "PermissionVault implements the IModule interface. It can be installed on any ERC-4337 modular smart account (Safe, Kernel, Biconomy, etc.) as a validation module." },
            { term: "Session Key", type: "ephemeral", def: "SessionKeyManager allows an agent owner to sign a time-bounded, target-restricted, spend-limited grant for a temporary key \u2014 without exposing the master key." },
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

      {/* 4. Contract Addresses */}
      <div id="contracts" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">04 — Contract Addresses (Base Sepolia)</span>
        </div>

        <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
          <table className="w-full text-sm min-w-[500px]">
            <thead className="text-[11px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border font-mono">
              <tr>
                <th className="font-normal py-3 px-4 text-left">Contract</th>
                <th className="font-normal py-3 px-4 text-left">Address</th>
                <th className="font-normal py-3 px-4 text-left">Basescan</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(CONTRACT_ADDRESSES).map(([name, addr], i) => (
                <tr key={name} className={`border-b border-border/40 ${i % 2 === 0 ? "" : "bg-[#FAFAFA]"}`}>
                  <td className="py-3 px-4 font-bold text-text text-xs">{name}</td>
                  <td className="py-3 px-4 font-mono text-[11px] text-text-muted">{addr}</td>
                  <td className="py-3 px-4">
                    <a href={`${BASESCAN}${addr.toLowerCase()}`} target="_blank" rel="noopener noreferrer" className="text-accent text-xs hover:underline flex items-center gap-1">
                      Verified <ExternalLink size={10} />
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-4">
          <InfoBox type="info">
            <span>All contracts are built with Solidity 0.8.24, Foundry, and OpenZeppelin v5. Source code is verified on Basescan and open on <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">GitHub</a>.</span>
          </InfoBox>
        </div>
      </div>

      {/* 5. TypeScript SDK */}
      <div id="sdk-ts" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">05 — TypeScript SDK</span>
        </div>

        <div className="space-y-6">
          <CodeBlock title="Terminal">{`npm install @bouclier/sdk`}</CodeBlock>

          <CodeBlock title="Initialize BouclierClient">{`import { BouclierClient } from "@bouclier/sdk";
import { createPublicClient, createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http("https://sepolia.base.org"),
});

// Read-only -- no wallet needed for queries
const bouclier = new BouclierClient({
  publicClient,
  addresses: {
    agentRegistry:      "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
    permissionVault:    "0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
    spendTracker:       "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
    revocationRegistry: "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
    auditLogger:        "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE",
  },
});

// With wallet -- needed for signing (grantPermission, buildScopeSignature)
const account = privateKeyToAccount("0xYOUR_PRIVATE_KEY");
const walletClient = createWalletClient({
  account,
  chain: baseSepolia,
  transport: http("https://sepolia.base.org"),
});
const bouclierWithWallet = new BouclierClient({
  publicClient,
  walletClient,
  addresses: { /* same as above */ },
});`}</CodeBlock>

          <CodeBlock title="Agent Lookup">{`// Get agent ID from wallet address
const agentId = await bouclier.getAgentId("0xAgentWallet");

// Resolve full agent record
const agent = await bouclier.resolveAgent(agentId);
// -> { agentId, agentAddress, owner, status, registeredAt,
//     did, model, parentAgentId, metadataCID }

// Check if agent is active
const active = await bouclier.isAgentActive(agentId);

// List all agents owned by an address
const agents = await bouclier.getAgentsByOwner("0xOwnerWallet");`}</CodeBlock>

          <CodeBlock title="Permission Queries">{`// Get the active permission scope for an agent
const scope = await bouclier.getActiveScope(agentId);
// -> { agentId, allowedProtocols, allowedSelectors, allowedTokens,
//     dailySpendCapUSD, perTxSpendCapUSD, validFrom, validUntil,
//     allowAnyProtocol, allowAnyToken, revoked, grantHash,
//     windowStartHour, windowEndHour, windowDaysMask, allowedChainId }

// Get the current grant nonce (increments with each new grant)
const nonce = await bouclier.getGrantNonce(agentId);`}</CodeBlock>
        </div>
      </div>

      {/* 6. Python SDK */}
      <div id="sdk-py" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">06 — Python SDK</span>
        </div>

        <div className="space-y-6">
          <CodeBlock title="Terminal">{`pip install bouclier-sdk`}</CodeBlock>

          <CodeBlock title="quickstart.py">{`from bouclier import BouclierClient

client = BouclierClient(rpc_url="https://sepolia.base.org")

# Look up an agent
agent_id = client.get_agent_id("0xAgentWallet")
agent = client.resolve_agent(agent_id)
print(f"Status: {agent.status}, Model: {agent.model}")

# Check permissions
scope = client.get_active_scope(agent_id)
usd = scope.daily_spend_cap_usd / 1e18
print(f"Daily cap: {usd} USD")

# Check revocation
is_revoked = client.is_revoked(agent_id)

# Full audit trail -- returns hydrated AuditRecord objects
trail = client.get_audit_trail(agent_id, offset=0, limit=100)
for event in trail:
    status = "PASS" if event.allowed else "FAIL"
    usd = event.usd_amount / 1e18
    print(f"{status} {event.target} {usd} USD")

# Total events
total = client.get_total_events(agent_id)
print(f"Total actions logged: {total}")`}</CodeBlock>
        </div>
      </div>

      {/* 7. Granting Permissions */}
      <div id="granting" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">07 — Granting Permissions</span>
        </div>

        <div className="space-y-6">
          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-base mb-3">Permission Grant Flow</h3>
            <div className="space-y-4 text-xs text-text-muted leading-relaxed">
              <div className="flex gap-3">
                <span className="font-mono text-accent font-bold w-5 shrink-0">1.</span>
                <span>Agent owner constructs a <code className="font-mono bg-background border border-border px-1 rounded text-text">PermissionScope</code> struct specifying which protocols, tokens, selectors, spend caps, and time windows the agent is allowed.</span>
              </div>
              <div className="flex gap-3">
                <span className="font-mono text-accent font-bold w-5 shrink-0">2.</span>
                <span>Owner signs the scope via <strong>EIP-712 typed data</strong> using the PermissionVault&apos;s domain separator and <code className="font-mono bg-background border border-border px-1 rounded text-text">SCOPE_TYPEHASH</code>.</span>
              </div>
              <div className="flex gap-3">
                <span className="font-mono text-accent font-bold w-5 shrink-0">3.</span>
                <span>The signed scope is submitted to <code className="font-mono bg-background border border-border px-1 rounded text-text">PermissionVault.grantPermission()</code> which verifies the signature, increments the nonce, and stores the scope on-chain.</span>
              </div>
              <div className="flex gap-3">
                <span className="font-mono text-accent font-bold w-5 shrink-0">4.</span>
                <span>Every subsequent UserOp from that agent is validated against this scope by <code className="font-mono bg-background border border-border px-1 rounded text-text">validateUserOp()</code>. If any check fails, validation returns 1 (reject).</span>
              </div>
            </div>
          </div>

          <CodeBlock title="grant-permission.ts">{`import { BouclierClient, GrantScopeParams } from "@bouclier/sdk";

// Build the scope parameters
const params: GrantScopeParams = {
  agentId,
  dailySpendCapUSD:  BigInt(1000e18),   // $1,000/day
  perTxSpendCapUSD:  BigInt(100e18),    // $100/transaction
  validFrom:         Math.floor(Date.now() / 1000),
  validUntil:        Math.floor(Date.now() / 1000) + 86400 * 30, // 30 days
  allowAnyProtocol:  false,
  allowAnyToken:     false,
  nonce:             await bouclier.getGrantNonce(agentId),
};

// Sign via EIP-712 (requires walletClient)
const signature = await bouclier.buildScopeSignature(params, account);

// Submit the grant on-chain (direct contract call)
// This stores the scope and emits PermissionGranted event`}</CodeBlock>

          <InfoBox type="warning">
            <span><strong>Grant nonces are sequential.</strong> Each new grant must use the next nonce. Call <code className="font-mono">getGrantNonce(agentId)</code> to get the current value before signing.</span>
          </InfoBox>
        </div>
      </div>

      {/* 8. Spend Tracking */}
      <div id="spending" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">08 — Spend Tracking</span>
        </div>

        <div className="space-y-6">
          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-base mb-3">How Spend Limits Work</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
              {[
                { title: "Chainlink Oracles", desc: "Token prices are fetched from Chainlink price feeds. Each token maps to a feed address set by the admin." },
                { title: "TWAP Fallback", desc: "If the latest Chainlink round is stale (>1 hour), SpendTracker falls back to a 4-round TWAP average." },
                { title: "Ring Buffer", desc: "Spends are stored in a ring buffer (max 1,000 entries per agent). getRollingSpend() sums entries within a time window." },
                { title: "Two Cap Types", desc: "dailySpendCapUSD (rolling 24h window) and perTxSpendCapUSD (single transaction limit). Both are USD-denominated (18 decimals)." },
              ].map((item, i) => (
                <div key={i} className="p-3 border border-border/40 rounded-md bg-background">
                  <h4 className="font-bold text-text text-xs mb-1">{item.title}</h4>
                  <p className="text-[11px] text-text-muted leading-relaxed">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>

          <CodeBlock title="Query spend on-chain (read via SDK)">{`// These are read-only calls -- no wallet needed

// Check if a proposed spend would exceed the cap
// Returns true if (rollingSpend + proposedUSD) <= capUSD
const withinCap = await publicClient.readContract({
  address: "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
  abi: spendTrackerAbi,
  functionName: "checkSpendCap",
  args: [agentId, proposedUSD, capUSD],
});

// Get rolling spend for last 24 hours (86400 seconds)
const dailySpend = await publicClient.readContract({
  address: "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
  abi: spendTrackerAbi,
  functionName: "getRollingSpend",
  args: [agentId, 86400n],
});

// Get USD value of a token amount
const usdValue = await publicClient.readContract({
  address: "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
  abi: spendTrackerAbi,
  functionName: "getUSDValue",
  args: [tokenAddress, amount],
});`}</CodeBlock>
        </div>
      </div>

      {/* 9. Revocation */}
      <div id="revocation" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">09 — Revocation</span>
        </div>

        <div className="space-y-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="p-5 border border-red-200 rounded-lg bg-red-50/50">
              <h4 className="font-bold text-text text-sm mb-2 flex items-center gap-2"><Ban size={14} className="text-red-500" /> Revoke (Instant)</h4>
              <p className="text-xs text-text-muted leading-relaxed mb-3">Calling <code className="font-mono bg-background border border-border px-1 rounded">revoke(agentId, reason, notes)</code> immediately sets the revoked flag. All future validateUserOp calls return VALIDATION_FAILED.</p>
              <p className="text-[10px] font-mono text-text-muted">Requires: REVOKER_ROLE</p>
            </div>
            <div className="p-5 border border-amber-200 rounded-lg bg-amber-50/50">
              <h4 className="font-bold text-text text-sm mb-2 flex items-center gap-2"><Clock size={14} className="text-amber-500" /> Reinstate (24h Timelock)</h4>
              <p className="text-xs text-text-muted leading-relaxed mb-3">Calling <code className="font-mono bg-background border border-border px-1 rounded">reinstate(agentId, notes)</code> only works if 24 hours have passed since revocation. Guardians can bypass with emergencyReinstate.</p>
              <p className="text-[10px] font-mono text-text-muted">Requires: REVOKER_ROLE (or GUARDIAN_ROLE for emergency)</p>
            </div>
          </div>

          <CodeBlock title="Check revocation status">{`// Via SDK
const revoked = await bouclier.isRevoked(agentId);

// Direct contract read -- more detail
const record = await publicClient.readContract({
  address: "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
  abi: revocationRegistryAbi,
  functionName: "getRevocationRecord",
  args: [agentId],
});
// -> { revoked, revokedAt, reinstatedAt, revokedBy, reason, notes }`}</CodeBlock>

          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-sm mb-3">Revocation Reasons</h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
              {["UserRequested", "Suspicious", "Compromised", "PolicyViolation", "Emergency"].map((r, i) => (
                <div key={r} className="text-center p-2 border border-border/40 rounded bg-background">
                  <span className="font-mono text-accent text-[10px] block">{i}</span>
                  <span className="text-[11px] text-text font-semibold">{r}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* 10. Audit Trail */}
      <div id="audit" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">10 — Querying the Audit Trail</span>
        </div>

        <div className="space-y-6">
          <InfoBox type="tip">
            <span>The audit trail is fully on-chain and queryable by anyone. No API key needed. Every action your agent took \u2014 allowed or denied \u2014 is logged with full context.</span>
          </InfoBox>

          <CodeBlock title="TypeScript — Full audit trail">{`// Get total number of logged events for an agent
const total = await bouclier.getTotalEvents(agentId);
console.log(\`Total events: \${total}\`);

// Get hydrated audit records (convenience method)
const trail = await bouclier.getAuditTrail(agentId, 0n, 50n);
for (const record of trail) {
  console.log({
    eventId:       record.eventId,
    target:        record.target,
    selector:      record.selector,
    usdAmount:     \`$\${Number(record.usdAmount) / 1e18}\`,
    allowed:       record.allowed,
    violationType: record.violationType || "none",
    timestamp:     new Date(record.timestamp * 1000).toISOString(),
    ipfsCID:       record.ipfsCID || "not anchored",
  });
}

// Or page through event IDs manually
const page1 = await bouclier.getAgentHistory(agentId, 0n, 100n);
const page2 = await bouclier.getAgentHistory(agentId, 100n, 100n);

// Fetch a single record by eventId
const record = await bouclier.getAuditRecord(page1[0]);`}</CodeBlock>

          <CodeBlock title="Python — Full audit trail">{`from bouclier import BouclierClient

client = BouclierClient(rpc_url="https://sepolia.base.org")

total = client.get_total_events(agent_id)
trail = client.get_audit_trail(agent_id, offset=0, limit=100)

for event in trail:
    status = "ALLOWED" if event.allowed else "DENIED"
    usd = event.usd_amount / 1e18
    print(f"[{status}] {event.target} {usd} USD")`}</CodeBlock>

          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-sm mb-3">AuditRecord Fields</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {[
                { field: "eventId", type: "bytes32", desc: "Unique hash for this event" },
                { field: "agentId", type: "bytes32", desc: "The agent that performed the action" },
                { field: "actionHash", type: "bytes32", desc: "Hash of the full action calldata" },
                { field: "target", type: "address", desc: "Contract that was called" },
                { field: "selector", type: "bytes4", desc: "Function selector called" },
                { field: "tokenAddress", type: "address", desc: "Token involved (if applicable)" },
                { field: "usdAmount", type: "uint256", desc: "USD value (18 decimals)" },
                { field: "timestamp", type: "uint48", desc: "Block timestamp" },
                { field: "allowed", type: "bool", desc: "Whether the action was permitted" },
                { field: "violationType", type: "string", desc: "Reason for denial (if blocked)" },
                { field: "ipfsCID", type: "string", desc: "IPFS content hash (if anchored)" },
              ].map((f) => (
                <div key={f.field} className="flex items-start gap-2 p-2 border border-border/40 rounded bg-background">
                  <span className="font-mono text-accent text-[11px] font-bold w-28 shrink-0">{f.field}</span>
                  <span className="text-[11px] text-text-muted">{f.desc}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* 11. Session Keys */}
      <div id="sessions" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">11 — Session Keys</span>
        </div>

        <div className="space-y-6">
          <div className="border border-border rounded-lg p-5 sm:p-6 bg-surface/30">
            <h3 className="font-bold text-text text-base mb-3">Ephemeral Session Keys</h3>
            <p className="text-xs text-text-muted leading-relaxed mb-4">
              SessionKeyManager lets an agent owner sign an EIP-712 typed <code className="font-mono bg-background border border-border px-1 rounded">SessionGrant</code> that
              delegates limited authority to a temporary key. The session key can execute transactions without the master key, but only within the grant&apos;s bounds.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                { label: "Time bounds", desc: "validAfter to validUntil window" },
                { label: "Target whitelist", desc: "Only allowed contract addresses" },
                { label: "Spend limit", desc: "Cumulative USD budget per session" },
                { label: "Nonce-based revocation", desc: "Revoke individual or batch sessions" },
              ].map((item) => (
                <div key={item.label} className="flex items-start gap-2 p-3 border border-border/40 rounded bg-background">
                  <Check size={12} className="text-accent mt-0.5 shrink-0" />
                  <div>
                    <span className="text-xs font-bold text-text">{item.label}</span>
                    <span className="text-[11px] text-text-muted ml-1">{item.desc}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <CodeBlock title="SessionGrant struct">{`struct SessionGrant {
    address sessionKey;       // Temporary key address
    bytes32 agentId;          // Bouclier agent identity
    address[] allowedTargets; // Whitelisted contracts
    uint256 spendLimit;       // Max cumulative USD spend (18 dec)
    uint48 validAfter;        // Unix timestamp -- start
    uint48 validUntil;        // Unix timestamp -- expiry
    uint256 nonce;            // For revocation
}

// Execute: signed by master, called by session key holder
executeViaSession(grant, masterSig, target, value, data, spendUSD)

// Revoke: called by master key
revokeSession(nonce)
batchRevokeSession([nonce1, nonce2, ...])

// Query
isSessionValid(grant, masterSig) -> (bool valid, address master)
remainingBudget(sessionKey, agentId, nonce, spendLimit) -> uint256`}</CodeBlock>
        </div>
      </div>

      {/* 12. Framework Integrations */}
      <div id="frameworks" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">12 — Framework Integrations</span>
        </div>

        <div className="space-y-6">
          <CodeBlock title="LangChain — Callback Handler">{`import { BouclierCallbackHandler } from "@bouclier/langchain";
import { AgentExecutor } from "langchain/agents";

const executor = AgentExecutor.fromAgentAndTools({
  agent,
  tools,
  callbacks: [new BouclierCallbackHandler(bouclier, agentId)],
});

// Every tool call is validated against the agent's scope
// Blocked actions throw with the violation reason`}</CodeBlock>

          <CodeBlock title="Coinbase AgentKit">{`import { BouclierAgentKit } from "@bouclier/agentkit";

// Wraps the base AgentKit -- all actions go through Bouclier
const kit = new BouclierAgentKit(bouclier, agentId, baseKit);

// kit.swap(), kit.transfer(), etc. now enforce permissions`}</CodeBlock>

          <CodeBlock title="ELIZA / ElizaOS">{`import { bouclierPlugin } from "@bouclier/eliza-plugin";

const agent = new ElizaAgent({
  plugins: [bouclierPlugin(bouclier)],
});

// All agent actions validated before execution`}</CodeBlock>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {[
              { name: "@bouclier/langchain", install: "npm install @bouclier/langchain" },
              { name: "@bouclier/agentkit", install: "npm install @bouclier/agentkit" },
              { name: "@bouclier/eliza-plugin", install: "npm install @bouclier/eliza-plugin" },
            ].map((pkg) => (
              <div key={pkg.name} className="p-4 border border-border rounded-lg bg-surface/40">
                <span className="font-mono text-accent text-xs font-bold block mb-2">{pkg.name}</span>
                <code className="text-[10px] text-text-muted font-mono">{pkg.install}</code>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 13. Contract API Reference */}
      <div id="api" className="mb-16 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">13 — Contract API Reference</span>
        </div>

        <div className="space-y-8">
          {/* AgentRegistry */}
          <div>
            <h3 className="font-bold text-text text-sm mb-3 flex items-center gap-2"><Database size={14} className="text-accent" /> AgentRegistry</h3>
            <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
              <table className="w-full text-xs font-mono min-w-[600px]">
                <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                  <tr><th className="font-normal py-2 px-3 text-left">Function</th><th className="font-normal py-2 px-3 text-left">Access</th><th className="font-normal py-2 px-3 text-left">Returns</th></tr>
                </thead>
                <tbody>
                  {[
                    ["register(agentWallet, model, parentAgentId, metadataCID)", "anyone", "bytes32 agentId"],
                    ["resolve(agentId)", "view", "AgentRecord"],
                    ["getAgentId(agentWallet)", "view", "bytes32"],
                    ["getAgentsByOwner(owner)", "view", "bytes32[]"],
                    ["isActive(agentId)", "view", "bool"],
                    ["totalAgents()", "view", "uint256"],
                    ["updateStatus(agentId, newStatus)", "owner/admin", "\u2014"],
                  ].map(([fn, access, ret], i) => (
                    <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                      <td className="py-2 px-3 text-accent">{fn}</td>
                      <td className="py-2 px-3 text-text-muted">{access}</td>
                      <td className="py-2 px-3 text-text">{ret}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* PermissionVault */}
          <div>
            <h3 className="font-bold text-text text-sm mb-3 flex items-center gap-2"><Shield size={14} className="text-accent" /> PermissionVault</h3>
            <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
              <table className="w-full text-xs font-mono min-w-[600px]">
                <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                  <tr><th className="font-normal py-2 px-3 text-left">Function</th><th className="font-normal py-2 px-3 text-left">Access</th><th className="font-normal py-2 px-3 text-left">Returns</th></tr>
                </thead>
                <tbody>
                  {[
                    ["validateUserOp(userOp, userOpHash)", "anyone", "uint256 (0=valid, 1=fail)"],
                    ["grantPermission(agentId, scope, ownerSig)", "owner", "\u2014"],
                    ["revokePermission(agentId)", "owner", "\u2014"],
                    ["emergencyRevoke(agentId)", "owner", "\u2014"],
                    ["getActiveScope(agentId)", "view", "PermissionScope"],
                    ["grantNonces(agentId)", "view", "uint256"],
                    ["isModuleType(moduleTypeId)", "pure", "bool"],
                  ].map(([fn, access, ret], i) => (
                    <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                      <td className="py-2 px-3 text-accent">{fn}</td>
                      <td className="py-2 px-3 text-text-muted">{access}</td>
                      <td className="py-2 px-3 text-text">{ret}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* SpendTracker */}
          <div>
            <h3 className="font-bold text-text text-sm mb-3 flex items-center gap-2"><Activity size={14} className="text-accent" /> SpendTracker</h3>
            <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
              <table className="w-full text-xs font-mono min-w-[600px]">
                <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                  <tr><th className="font-normal py-2 px-3 text-left">Function</th><th className="font-normal py-2 px-3 text-left">Access</th><th className="font-normal py-2 px-3 text-left">Returns</th></tr>
                </thead>
                <tbody>
                  {[
                    ["checkSpendCap(agentId, proposedUSD, capUSD)", "view", "bool"],
                    ["getRollingSpend(agentId, windowSeconds)", "view", "uint256"],
                    ["getUSDValue(token, amount)", "view", "uint256"],
                    ["getPriceFeed(token)", "view", "address"],
                    ["recordSpend(agentId, usdAmount, timestamp)", "VAULT_ROLE", "\u2014"],
                  ].map(([fn, access, ret], i) => (
                    <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                      <td className="py-2 px-3 text-accent">{fn}</td>
                      <td className="py-2 px-3 text-text-muted">{access}</td>
                      <td className="py-2 px-3 text-text">{ret}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* RevocationRegistry */}
          <div>
            <h3 className="font-bold text-text text-sm mb-3 flex items-center gap-2"><Ban size={14} className="text-accent" /> RevocationRegistry</h3>
            <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
              <table className="w-full text-xs font-mono min-w-[600px]">
                <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                  <tr><th className="font-normal py-2 px-3 text-left">Function</th><th className="font-normal py-2 px-3 text-left">Access</th><th className="font-normal py-2 px-3 text-left">Returns</th></tr>
                </thead>
                <tbody>
                  {[
                    ["isRevoked(agentId)", "view", "bool"],
                    ["getRevocationRecord(agentId)", "view", "RevocationRecord"],
                    ["revoke(agentId, reason, notes)", "REVOKER_ROLE", "\u2014"],
                    ["batchRevoke(agentIds[], reason, notes)", "GUARDIAN_ROLE", "\u2014"],
                    ["reinstate(agentId, notes)", "REVOKER_ROLE (24h lock)", "\u2014"],
                    ["emergencyReinstate(agentId, notes)", "GUARDIAN_ROLE", "\u2014"],
                  ].map(([fn, access, ret], i) => (
                    <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                      <td className="py-2 px-3 text-accent">{fn}</td>
                      <td className="py-2 px-3 text-text-muted">{access}</td>
                      <td className="py-2 px-3 text-text">{ret}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* AuditLogger */}
          <div>
            <h3 className="font-bold text-text text-sm mb-3 flex items-center gap-2"><Eye size={14} className="text-accent" /> AuditLogger</h3>
            <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
              <table className="w-full text-xs font-mono min-w-[600px]">
                <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                  <tr><th className="font-normal py-2 px-3 text-left">Function</th><th className="font-normal py-2 px-3 text-left">Access</th><th className="font-normal py-2 px-3 text-left">Returns</th></tr>
                </thead>
                <tbody>
                  {[
                    ["getAuditRecord(eventId)", "view", "AuditRecord"],
                    ["getAgentHistory(agentId, offset, limit)", "view", "bytes32[]"],
                    ["getTotalEvents(agentId)", "view", "uint256"],
                    ["logAction(agentId, actionHash, target, ...)", "LOGGER_ROLE", "bytes32 eventId"],
                    ["addIPFSCID(eventId, cid)", "IPFS_ROLE", "\u2014"],
                  ].map(([fn, access, ret], i) => (
                    <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                      <td className="py-2 px-3 text-accent">{fn}</td>
                      <td className="py-2 px-3 text-text-muted">{access}</td>
                      <td className="py-2 px-3 text-text">{ret}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {/* 14. SDK Method Reference */}
      <div id="sdk-ref" className="mb-20 scroll-mt-24">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-8 h-[1px] bg-accent"></div>
          <span className="font-mono text-xs uppercase tracking-[0.2em] text-text-muted">14 — SDK Method Reference</span>
        </div>

        <div className="space-y-6">
          <h3 className="font-bold text-text text-sm">TypeScript &mdash; BouclierClient</h3>
          <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
            <table className="w-full text-xs font-mono min-w-[600px]">
              <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                <tr>
                  <th className="font-normal py-2 px-3 text-left">Method</th>
                  <th className="font-normal py-2 px-3 text-left">Returns</th>
                </tr>
              </thead>
              <tbody>
                {[
                  ["resolveAgent(agentId)", "AgentRecord"],
                  ["getAgentId(agentWallet)", "Hex"],
                  ["getAgentsByOwner(owner)", "Hex[]"],
                  ["isAgentActive(agentId)", "boolean"],
                  ["getActiveScope(agentId)", "PermissionScope"],
                  ["getGrantNonce(agentId)", "bigint"],
                  ["buildScopeSignature(params, account)", "Hex"],
                  ["isRevoked(agentId)", "boolean"],
                  ["getAuditRecord(eventId)", "AuditRecord"],
                  ["getAgentHistory(agentId, offset?, limit?)", "Hex[]"],
                  ["getTotalEvents(agentId)", "bigint"],
                  ["getAuditTrail(agentId, offset?, limit?)", "AuditRecord[]"],
                ].map(([method, ret], i) => (
                  <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                    <td className="py-2 px-3 text-accent">{method}</td>
                    <td className="py-2 px-3 text-text">{ret}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h3 className="font-bold text-text text-sm mt-8">Python &mdash; BouclierClient</h3>
          <div className="border border-border rounded-lg overflow-hidden overflow-x-auto">
            <table className="w-full text-xs font-mono min-w-[600px]">
              <thead className="text-[10px] text-text-muted uppercase bg-[#FAFAFA] border-b border-border">
                <tr>
                  <th className="font-normal py-2 px-3 text-left">Method</th>
                  <th className="font-normal py-2 px-3 text-left">Returns</th>
                </tr>
              </thead>
              <tbody>
                {[
                  ["resolve_agent(agent_id)", "AgentRecord"],
                  ["get_agent_id(agent_wallet)", "str"],
                  ["get_agents_by_owner(owner)", "list[str]"],
                  ["is_agent_active(agent_id)", "bool"],
                  ["get_active_scope(agent_id)", "PermissionScope"],
                  ["is_revoked(agent_id)", "bool"],
                  ["get_total_events(agent_id)", "int"],
                  ["get_audit_trail(agent_id, offset?, limit?)", "list[AuditRecord]"],
                ].map(([method, ret], i) => (
                  <tr key={i} className="border-b border-border/40 hover:bg-surface/40">
                    <td className="py-2 px-3 text-accent">{method}</td>
                    <td className="py-2 px-3 text-text">{ret}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* CTA */}
      <div className="border border-border rounded-lg p-6 sm:p-10 bg-[#FAFAFA] text-center mb-20">
        <h3 className="text-xl sm:text-2xl font-bold text-text mb-3">Start Building</h3>
        <p className="text-text-muted mb-6 max-w-lg mx-auto text-sm">
          Install the SDK, connect to Base Sepolia, and integrate Bouclier into your agent in minutes.
        </p>
        <div className="flex gap-3 sm:gap-4 justify-center flex-wrap">
          <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="px-5 sm:px-6 py-3 bg-accent text-white font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-accent-hover transition-colors flex items-center gap-2">
            View on GitHub <ExternalLink size={14} />
          </a>
          <a href="/developers" className="px-5 sm:px-6 py-3 border border-border text-text font-semibold uppercase tracking-wider text-sm rounded-sm hover:bg-surface transition-colors flex items-center gap-2">
            Integration Examples <ArrowRight size={14} />
          </a>
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
