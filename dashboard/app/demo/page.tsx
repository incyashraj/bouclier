"use client";

import React from "react";
import { MarketingPageTemplate } from "@/components/layout/MarketingPageTemplate";
import { Play } from "lucide-react";

const Step = ({ n, title, children }: { n: number; title: string; children: React.ReactNode }) => (
  <div className="border border-border bg-surface p-6 rounded-sm">
    <div className="flex items-start gap-4">
      <div className="min-w-[36px] h-9 flex items-center justify-center bg-accent text-white font-bold text-sm rounded-sm">
        {n}
      </div>
      <div className="flex-1">
        <h3 className="text-lg font-bold tracking-tight mb-3">{title}</h3>
        <div className="text-sm text-text-muted leading-relaxed space-y-2">{children}</div>
      </div>
    </div>
  </div>
);

const Code = ({ children }: { children: React.ReactNode }) => (
  <code className="px-1.5 py-0.5 bg-background rounded text-xs font-mono text-accent">{children}</code>
);

const Pre = ({ children }: { children: string }) => (
  <pre className="bg-[#0F0F10] text-[#E5E5E5] p-4 rounded-sm text-xs font-mono overflow-x-auto mt-3 mb-2 leading-relaxed whitespace-pre-wrap">{children}</pre>
);

export default function DemoPage() {
  return (
    <MarketingPageTemplate
      title="Live Demo Guide"
      subtitle="Investor Walkthrough"
      description="Step-by-step script for recording a real-time demo of Bouclier on Base Sepolia testnet."
      icon={Play}
    >
      <div className="space-y-6 max-w-3xl">
        {/* Prerequisites */}
        <div className="border border-accent/30 bg-accent/5 p-6 rounded-sm">
          <h2 className="text-lg font-bold tracking-tight mb-3 flex items-center gap-2">
            <span className="text-accent">&#9632;</span> Prerequisites
          </h2>
          <ul className="text-sm text-text-muted leading-relaxed space-y-2 list-disc list-inside">
            <li>MetaMask (or any wallet) with <strong>Base Sepolia</strong> network added</li>
            <li>Base Sepolia ETH for gas — get free from <Code>https://www.alchemy.com/faucets/base-sepolia</Code></li>
            <li>Foundry installed (<Code>curl -L https://foundry.paradigm.xyz | bash</Code>)</li>
            <li>Terminal access for agent registration (one-time setup)</li>
          </ul>
        </div>

        {/* Pre-Demo Setup */}
        <div className="border border-border bg-surface p-6 rounded-sm">
          <h2 className="text-lg font-bold tracking-tight mb-3">Pre-Demo: Register an Agent (CLI)</h2>
          <p className="text-sm text-text-muted mb-3">
            The dashboard reads agents from on-chain. Register one beforehand using <Code>cast</Code>:
          </p>
          <Pre>{`# Set your private key (the wallet you'll connect in the dashboard)
export PRIVATE_KEY=0x_YOUR_PRIVATE_KEY_HERE

# Register an AI agent on Base Sepolia
cast send 0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB \\
  "register(address,string,bytes32,string)" \\
  0x1111000000000000000000000000000000000001 \\
  "gpt-4-turbo" \\
  0x0000000000000000000000000000000000000000000000000000000000000000 \\
  "" \\
  --rpc-url https://sepolia.base.org \\
  --private-key $PRIVATE_KEY

# Get your agent IDs (owned by your wallet)
cast call 0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB \\
  "getAgentsByOwner(address)(bytes32[])" YOUR_WALLET_ADDRESS \\
  --rpc-url https://sepolia.base.org`}</Pre>
          <p className="text-xs text-text-muted mt-2">
            Tip: Use a memorable DID like <Code>did:bouclier:demo-agent-001</Code> for the video.
          </p>
        </div>

        <h2 className="text-2xl font-bold tracking-tight pt-4">Demo Recording Script</h2>
        <p className="text-sm text-text-muted -mt-2 mb-4">
          Estimated recording time: 5-8 minutes. Each step shows a real on-chain transaction.
        </p>

        <Step n={1} title="Open Landing Page & Connect Wallet">
          <p>Navigate to <Code>http://localhost:3000</Code> (or your deployed URL).</p>
          <p>Show the landing page briefly — scroll the &quot;Why Bouclier?&quot; comparison table.</p>
          <p>Click <strong>&quot;+ Launch App&quot;</strong> in the top nav.</p>
          <p>Connect your MetaMask wallet. Make sure you&apos;re on <strong>Base Sepolia</strong>.</p>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;Bouclier is the compliance layer for AI agents — every agent action is bounded on-chain.&quot;</p>
        </Step>

        <Step n={2} title="View Agent Control Plane">
          <p>You should see your registered agent(s) listed with live status badges.</p>
          <p>Point out the <strong>green &quot;Active&quot;</strong> badge, the agent DID, and the model name (&quot;gpt-4-turbo&quot;).</p>
          <p>Explain: <em>&quot;Every AI agent is registered on-chain with a deterministic identity. Enterprises can see all their agents in one place.&quot;</em></p>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;This is a live read from Base L2 — no off-chain database, no centralized API.&quot;</p>
        </Step>

        <Step n={3} title="Grant Permission Scope (3-Step Wizard)">
          <p>Click <strong>&quot;+ New Agent Policy&quot;</strong>.</p>
          <p><strong>Step 1:</strong> Paste the agent hash ID from your pre-demo setup.</p>
          <p><strong>Step 2:</strong> Set limits:</p>
          <ul className="list-disc list-inside ml-4 space-y-1">
            <li>Daily Spend Limit: <Code>$1,000</Code></li>
            <li>Per-Transaction Cap: <Code>$100</Code></li>
            <li>Leave &quot;Allow Universal&quot; unchecked for safety</li>
          </ul>
          <p><strong>Step 3:</strong> Click &quot;Generate Policy Signature&quot; → MetaMask pops up → sign → wait for on-chain confirmation.</p>
          <p>Show the green <strong>&quot;Policy Active&quot;</strong> confirmation with the tx hash.</p>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;In 15 seconds, we just set deterministic spending boundaries for this AI agent — enforced by the blockchain, not by the AI itself.&quot;</p>
        </Step>

        <Step n={4} title="Inspect Agent Telemetry">
          <p>Click into the agent detail page (either from the success screen link or agent list).</p>
          <p>Walk through each section:</p>
          <ul className="list-disc list-inside ml-4 space-y-1">
            <li><strong>Agent Telemetry</strong> — Model hash, 24h rolling spend, total audit events</li>
            <li><strong>Active Protocol Bounds</strong> — Your just-created scope: $1K/day, $100/tx, valid dates</li>
            <li><strong>Cryptographic Audit Feed</strong> — Shows every action attempted (green = approved, red = denied)</li>
          </ul>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;Full telemetry — every dollar spent, every action taken, every denial. All immutable, all on-chain.&quot;</p>
        </Step>

        <Step n={5} title="Emergency Revoke (Kill Switch)">
          <p>Click the red <strong>&quot;Revoke Entire Scope&quot;</strong> button in the agent header.</p>
          <p>MetaMask pops up → sign → on-chain confirmation.</p>
          <p>The status changes to <strong>&quot;Revoked&quot;</strong> (red badge). The agent can no longer execute ANY transactions.</p>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;Instant kill switch — under 130,000 gas, about 4 milliseconds. If an AI goes rogue, we stop it in one block.&quot;</p>
        </Step>

        <Step n={6} title="Show the Smart Contracts (Basescan)">
          <p>Open Basescan links to show the verified source code:</p>
          <ul className="list-disc list-inside ml-4 space-y-1 font-mono text-xs">
            <li>AgentRegistry: <Code>0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB</Code></li>
            <li>PermissionVault: <Code>0xe0b283A4Dff684E5D700E53900e7B27279f7999F</Code></li>
            <li>SpendTracker: <Code>0x930Eb18B9962c30b388f900ba9AE62386191cD48</Code></li>
            <li>RevocationRegistry: <Code>0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270</Code></li>
            <li>AuditLogger: <Code>0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE</Code></li>
          </ul>
          <p className="text-accent font-semibold mt-2">Talking Point: &quot;All contracts verified on-chain, open-source MIT license. 140+ tests, formal verification with Certora Prover — zero violations.&quot;</p>
        </Step>

        {/* Quick Test Checklist */}
        <div className="border border-border bg-surface p-6 rounded-sm mt-8">
          <h2 className="text-lg font-bold tracking-tight mb-3">Pre-Recording Checklist</h2>
          <ul className="text-sm text-text-muted leading-relaxed space-y-2">
            <li>&#9744; MetaMask connected to Base Sepolia with ETH balance</li>
            <li>&#9744; At least one agent registered (run the <Code>cast send</Code> command above)</li>
            <li>&#9744; Agent hash ID copied to clipboard</li>
            <li>&#9744; Dashboard running locally (<Code>npm run dev</Code>) or deployed</li>
            <li>&#9744; Screen recording software ready (OBS / Loom / QuickTime)</li>
            <li>&#9744; Browser zoom at 100%, no extensions interfering</li>
            <li>&#9744; Close any tabs with sensitive info visible</li>
          </ul>
        </div>

        {/* CLI-Only Quick Test */}
        <div className="border border-border bg-surface p-6 rounded-sm">
          <h2 className="text-lg font-bold tracking-tight mb-3">Bonus: Full CLI-Only Test (No UI)</h2>
          <p className="text-sm text-text-muted mb-3">
            Run the complete flow in terminal if you want to verify contracts work before recording:
          </p>
          <Pre>{`# 1. Register agent
cast send 0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB \\
  "register(address,string,bytes32,string)" \\
  0x4444000000000000000000000000000000000004 \\
  "gpt-4" \\
  0x0000000000000000000000000000000000000000000000000000000000000000 \\
  "" \\
  --rpc-url https://sepolia.base.org --private-key $PRIVATE_KEY

# 2. Check registration
cast call 0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB \\
  "getAgentsByOwner(address)(bytes32[])" YOUR_WALLET \\
  --rpc-url https://sepolia.base.org

# 3. Run the Foundry E2E test suite (139+ tests)
cd contracts && forge test --match-contract E2EFullFlow -vvv

# 4. Check gas report
forge test --gas-report`}</Pre>
        </div>

        <div className="text-center py-8 text-xs font-mono text-text-muted uppercase tracking-widest">
          [SYS] Bouclier Protocol · Demo Guide v1.0
        </div>
      </div>
    </MarketingPageTemplate>
  );
}
