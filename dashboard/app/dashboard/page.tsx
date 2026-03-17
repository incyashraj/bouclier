"use client";

import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import Link from "next/link";
import { getContracts, isDeployed } from "@/lib/contracts";
import { agentRegistryAbi, revocationRegistryAbi, permissionVaultAbi } from "@/lib/abis";
import { ArrowRight, ShieldCheck, ShieldAlert, Activity, Sliders, Database, X, Eye } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { parseEther } from "viem";

// Dot indicator helper
const TargetDot = ({ active = false, color = "accent" }) => {
  const isAccent = color === "accent";
  const isGreen = color === "green";
  const isRed = color === "red";
  const isYellow = color === "yellow";

  let outer = "border-[#D4D4D8]";
  let inner = "bg-[#D4D4D8]";
  if (active) {
    if (isAccent) { outer = "border-accent/30"; inner = "bg-accent"; }
    else if (isGreen) { outer = "border-green-500/30"; inner = "bg-green-500"; }
    else if (isRed) { outer = "border-red-500/30"; inner = "bg-red-500"; }
    else if (isYellow) { outer = "border-yellow-500/30"; inner = "bg-yellow-500"; }
  }

  return (
    <div className={`rounded-full border flex items-center justify-center w-3.5 h-3.5 ${outer}`}>
      <div className={`rounded-full w-1.5 h-1.5 ${inner}`}></div>
    </div>
  );
};

function AgentCard({ agentId, chainId, isSelected, onSelect }: { agentId: `0x${string}`; chainId: number; isSelected: boolean; onSelect: () => void }) {
  const addrs = getContracts(chainId);

  const { data: record } = useReadContract({
    address: addrs.agentRegistry,
    abi: agentRegistryAbi,
    functionName: "resolve",
    args: [agentId],
  });

  const { data: revoked } = useReadContract({
    address: addrs.revocationRegistry,
    abi: revocationRegistryAbi,
    functionName: "isRevoked",
    args: [agentId],
  });

  const { data: scope } = useReadContract({
    address: addrs.permissionVault,
    abi: permissionVaultAbi,
    functionName: "getActiveScope",
    args: [agentId],
  });

  if (!record) {
    return (
      <div className="border border-border bg-surface p-6 animate-pulse rounded-sm">
        <div className="h-4 bg-border/50 rounded w-1/3 mb-3" />
        <div className="h-3 bg-border/30 rounded w-2/3" />
      </div>
    );
  }

  const statusMap = ["Active", "Paused", "Deactivated"];
  const status = statusMap[record.status] ?? "Unknown";
  const isRev = !!revoked;
  const hasScope = scope && scope.dailySpendCapUSD > 0n;
  const scopeRevoked = scope?.revoked;

  const statusColor = isRev ? "red" : status === "Active" ? "green" : "yellow";
  const statusBg = isRev ? "bg-red-500/10 text-red-600 border-red-500/20" : status === "Active" ? "bg-green-500/10 text-green-600 border-green-500/20" : "bg-yellow-500/10 text-yellow-600 border-yellow-500/20";

  const E18 = 10n ** 18n;

  return (
    <div
      className={`border bg-surface p-6 rounded-sm transition-all cursor-pointer hover:shadow-md group ${isSelected ? "border-accent shadow-accent/10 ring-1 ring-accent/20" : "border-border hover:border-text/30"}`}
      onClick={onSelect}
    >
      {/* Top row: ID + Status */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <TargetDot active color={statusColor} />
          <span className="font-mono text-sm font-bold text-text group-hover:text-accent transition-colors">
            {agentId.slice(0, 10)}…{agentId.slice(-6)}
          </span>
          <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-full border uppercase ${statusBg}`}>
            {isRev ? "Revoked" : status}
          </span>
        </div>
        <div className="flex items-center gap-2">
          {isSelected && (
            <span className="text-[10px] font-mono text-accent uppercase tracking-widest">Selected</span>
          )}
          <Link href={`/dashboard/${agentId}`} onClick={(e) => e.stopPropagation()} className="w-8 h-8 rounded-full border border-border flex items-center justify-center bg-surface hover:bg-accent hover:text-white hover:border-accent transition-all">
            <Eye size={14} />
          </Link>
        </div>
      </div>

      {/* Agent Info Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4">
        <div className="flex flex-col gap-1">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest">Model</span>
          <span className="text-sm font-mono font-semibold text-text px-2 py-1 bg-background border border-border rounded-sm inline-block w-fit">
            {record.model || "Unknown"}
          </span>
        </div>
        <div className="flex flex-col gap-1">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest">DID</span>
          <span className="text-xs font-mono text-text-muted truncate max-w-[200px]" title={record.did}>
            {record.did || "—"}
          </span>
        </div>
        <div className="flex flex-col gap-1">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest">Registered</span>
          <span className="text-xs font-mono text-text-muted">
            {record.registeredAt ? new Date(Number(record.registeredAt) * 1000).toLocaleDateString() : "—"}
          </span>
        </div>
      </div>

      {/* Scope Status */}
      {hasScope && !scopeRevoked ? (
        <div className="border-t border-border pt-3 mt-1">
          <div className="flex items-center gap-4 text-xs font-mono text-text-muted">
            <span className="flex items-center gap-1.5">
              <Activity size={12} className="text-green-500" />
              <span className="text-green-600 font-semibold">Scope Active</span>
            </span>
            <span>Daily: ${(Number(scope.dailySpendCapUSD / E18)).toLocaleString()}</span>
            <span>Per-Tx: ${(Number(scope.perTxSpendCapUSD / E18)).toLocaleString()}</span>
          </div>
        </div>
      ) : hasScope && scopeRevoked ? (
        <div className="border-t border-border pt-3 mt-1">
          <span className="text-[10px] font-mono text-red-500 uppercase tracking-widest flex items-center gap-1.5">
            <ShieldAlert size={12} /> Scope Revoked
          </span>
        </div>
      ) : (
        <div className="border-t border-border pt-3 mt-1">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest flex items-center gap-1.5">
            <Sliders size={12} /> No scope assigned — select to set limits
          </span>
        </div>
      )}
    </div>
  );
}

function SetLimitsPanel({ agentId, chainId, onClose }: { agentId: `0x${string}`; chainId: number; onClose: () => void }) {
  const { address } = useAccount();
  const contracts = getContracts(chainId);
  const [dailyCap, setDailyCap] = useState("1000");
  const [perTxCap, setPerTxCap] = useState("100");
  const [allowAnyProtocol, setAllowAnyProtocol] = useState(true);

  const { data: nonce } = useReadContract({
    address: contracts.permissionVault,
    abi: permissionVaultAbi,
    functionName: "grantNonces",
    args: [agentId],
  });

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });

  const handleGrant = () => {
    if (!address) return;
    const scopeData = {
      agentId,
      allowedProtocols: [] as `0x${string}`[],
      allowedSelectors: [] as `0x${string}`[],
      allowedTokens: [] as `0x${string}`[],
      dailySpendCapUSD: parseEther(dailyCap),
      perTxSpendCapUSD: parseEther(perTxCap),
      validFrom: ~~(Date.now() / 1000),
      validUntil: ~~(Date.now() / 1000) + 31536000,
      allowAnyProtocol,
      allowAnyToken: true,
      revoked: false,
      grantHash: "0x" + "0".repeat(64) as `0x${string}`,
      windowStartHour: 0,
      windowEndHour: 24,
      windowDaysMask: 127,
      allowedChainId: BigInt(chainId),
    };

    writeContract({
      address: contracts.permissionVault,
      abi: permissionVaultAbi,
      functionName: "grantPermission",
      args: [agentId, scopeData as any, "0x"],
    });
  };

  return (
    <div className="border border-accent/30 bg-accent/5 rounded-sm p-6 mt-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="font-bold text-lg tracking-tight flex items-center gap-2">
          <Sliders size={18} className="text-accent" />
          Set Limits for {agentId.slice(0, 10)}…
        </h3>
        <button onClick={onClose} className="p-1.5 hover:bg-surface rounded-sm transition-colors">
          <X size={18} className="text-text-muted" />
        </button>
      </div>

      {isConfirmed ? (
        <div className="flex flex-col items-center py-8 text-center">
          <ShieldCheck className="text-green-500 mb-4" size={48} />
          <h3 className="font-bold text-lg">Policy Active</h3>
          <p className="font-mono text-xs text-text-muted mt-2">Tx: {hash?.slice(0, 20)}…</p>
          <div className="flex gap-3 mt-6">
            <Link href={`/dashboard/${agentId}`}>
              <Button variant="primary" size="sm" className="uppercase text-[11px] tracking-widest">View Agent Detail</Button>
            </Link>
            <Button variant="outline" size="sm" onClick={onClose} className="uppercase text-[11px] tracking-widest">Close</Button>
          </div>
        </div>
      ) : isPending || isConfirming ? (
        <div className="flex flex-col items-center py-8 text-center">
          <div className="w-12 h-12 border-2 border-accent border-t-transparent rounded-full animate-spin mb-4" />
          <p className="text-[11px] font-mono uppercase tracking-widest text-text">
            {isPending ? "Awaiting Signature…" : "Mining On-Chain…"}
          </p>
        </div>
      ) : writeError ? (
        <div className="flex flex-col items-center py-6 text-center text-red-500">
          <ShieldAlert size={32} className="mb-3" />
          <p className="font-bold text-sm">Transaction Failed</p>
          <p className="text-xs mt-2 font-mono break-words max-w-sm">{(writeError as any).shortMessage || writeError.message}</p>
          <Button variant="outline" size="sm" onClick={() => handleGrant()} className="mt-4">Retry</Button>
        </div>
      ) : (
        <div className="space-y-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-1.5">
                <Database size={11} /> Daily Spend Limit (USD)
              </label>
              <input
                type="number"
                value={dailyCap}
                onChange={(e) => setDailyCap(e.target.value)}
                className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
              />
            </div>
            <div>
              <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-1.5">
                <Activity size={11} /> Per-Transaction Cap (USD)
              </label>
              <input
                type="number"
                value={perTxCap}
                onChange={(e) => setPerTxCap(e.target.value)}
                className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
              />
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 border border-border bg-white cursor-pointer hover:border-text/30 transition-all rounded-sm"
               onClick={() => setAllowAnyProtocol(!allowAnyProtocol)}>
            <div className={`w-4 h-4 border flex items-center justify-center rounded-sm ${allowAnyProtocol ? "bg-accent border-accent" : "border-border"}`}>
              {allowAnyProtocol && <div className="w-2 h-2 bg-white rounded-sm" />}
            </div>
            <span className="text-[11px] font-mono uppercase tracking-widest text-text">Allow Any Protocol</span>
          </div>

          <Button variant="primary" onClick={handleGrant} className="w-full uppercase text-[11px] tracking-widest h-11 font-mono">
            Grant Permission Scope
          </Button>
        </div>
      )}
    </div>
  );
}

export default function DashboardPage() {
  const { address, chainId, isConnected } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;
  const [selectedAgent, setSelectedAgent] = useState<`0x${string}` | null>(null);

  const { data: agentIds, isLoading } = useReadContract({
    address: isConnected && chainId && deployed
      ? getContracts(chainId).agentRegistry
      : undefined,
    abi: agentRegistryAbi,
    functionName: "getAgentsByOwner",
    args: address ? [address] : undefined,
    query: { enabled: !!address && deployed },
  });

  if (!isConnected) {
    return (
      <div className="w-full h-full min-h-[70vh] flex flex-col items-center justify-center p-8 bg-surface border-b border-border text-center overflow-hidden relative">
        <div className="absolute top-0 right-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none"></div>
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none"></div>
        
        <div className="bento-card-dark p-12 max-w-lg w-full flex flex-col items-center shadow-2xl relative z-10 transition-all duration-700 hover:shadow-accent/5">
          <div className="w-16 h-16 border border-border flex items-center justify-center bg-[#FAFAFA] rounded-xl mb-8 -mt-20 shadow-lg">
            <ShieldAlert size={28} className="text-accent" />
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-text mb-4">Registry Locked</h2>
          <p className="text-text-muted text-sm mb-10 leading-relaxed">
            Authentication required. Connect your enterprise wallet to view registered agents, monitor real-time execution limits, and control active scopes.
          </p>
          <div className="w-full flex justify-center scale-110">
            <ConnectButton />
          </div>
        </div>
      </div>
    );
  }

  if (!deployed) {
    return (
      <div className="w-full p-8 border-b border-border bg-[#FAFAFA]">
        <div className="bento-card-dark p-6 border-yellow-500/20 bg-yellow-500/5 max-w-2xl text-yellow-800">
          <h3 className="font-bold flex items-center gap-2 mb-2">
            <TargetDot active color="yellow" /> Network mismatch or non-deployed status
          </h3>
          <p className="text-sm opacity-80 pl-5">
            Bouclier Protocol is not currently deployed on this active network. Switch to Base Sepolia using the connector below.
          </p>
          <div className="mt-4 pl-5">
            <ConnectButton />
          </div>
        </div>
      </div>
    );
  }

  const ids = (agentIds as `0x${string}`[] | undefined) ?? [];

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
      {/* Header Area */}
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        <svg className="absolute -right-20 top-0 w-96 h-full stroke-border opacity-50" fill="none">
           <path d="M50,0 Q100,100 200,100 T350,100" strokeWidth="1" />
           <path d="M50,40 Q100,140 200,140 T350,140" strokeWidth="1" />
           <path d="M50,80 Q100,180 200,180 T350,180" strokeWidth="1" />
        </svg>

        <div className="relative z-10">
          <h1 className="text-[2.5rem] font-bold tracking-tight text-text leading-none mb-3">
             Agent Control Plane<span className="text-accent">_</span>
          </h1>
          <p className="text-sm font-mono text-text-muted mt-2 tracking-tight">
             {ids.length} AGENT{ids.length !== 1 ? "S" : ""} REGISTERED & SECURED ON-CHAIN
          </p>
        </div>
      </div>

      {/* Main Content */}
      <div className="p-8 lg:p-12 flex-1 bg-surface relative">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-bold text-lg tracking-tight">Your Agents</h3>
          <Link href="/dashboard/grant">
            <Button variant="primary" size="sm" className="uppercase text-[11px] tracking-widest pl-4">
              <span className="mr-2 text-xl font-light">+</span> New Agent Policy
            </Button>
          </Link>
        </div>

        {isLoading ? (
          <div className="space-y-4">
            {[1, 2].map((i) => (
              <div key={i} className="border border-border bg-surface p-6 rounded-sm animate-pulse">
                <div className="h-4 bg-border/50 rounded w-1/3 mb-4" />
                <div className="h-3 bg-border/30 rounded w-2/3 mb-2" />
                <div className="h-3 bg-border/30 rounded w-1/2" />
              </div>
            ))}
          </div>
        ) : ids.length === 0 ? (
          <div className="w-full py-20 flex flex-col items-center justify-center text-center border border-dashed border-border rounded-sm bg-[#FAFAFA]">
            <ShieldCheck size={40} className="text-text-muted opacity-30 mb-6" />
            <h3 className="font-bold text-text mb-2">No agents under your control</h3>
            <p className="text-sm text-text-muted max-w-md">
              You haven&apos;t bound any LLMs to the registry yet. Create a new grant policy to wrap your first agent with cryptographic rules.
            </p>
            <Link href="/dashboard/grant" className="mt-8">
               <Button variant="outline" size="sm">Create Policy</Button>
            </Link>
          </div>
        ) : (
          <>
            <p className="text-xs font-mono text-text-muted mb-4">
              Select an agent to set spending limits and permissions, or click the eye icon to view full details.
            </p>

            <div className="space-y-4">
              {ids.map((id) => (
                <AgentCard
                  key={id}
                  agentId={id}
                  chainId={chainId!}
                  isSelected={selectedAgent === id}
                  onSelect={() => setSelectedAgent(selectedAgent === id ? null : id)}
                />
              ))}
            </div>

            {/* Inline Set Limits Panel */}
            {selectedAgent && (
              <SetLimitsPanel
                key={selectedAgent}
                agentId={selectedAgent}
                chainId={chainId!}
                onClose={() => setSelectedAgent(null)}
              />
            )}
          </>
        )}
      </div>
    </div>
  );
}