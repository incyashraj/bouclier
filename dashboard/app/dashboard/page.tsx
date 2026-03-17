"use client";

import { useAccount, useReadContract } from "wagmi";
import Link from "next/link";
import { getContracts, isDeployed } from "@/lib/contracts";
import { agentRegistryAbi, revocationRegistryAbi } from "@/lib/abis";
import { ArrowRight, ShieldCheck, ShieldAlert } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConnectButton } from "@rainbow-me/rainbowkit";

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

function AgentRow({ agentId, chainId }: { agentId: `0x${string}`; chainId: number }) {
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

  if (!record) return null;

  const shortId = agentId.slice(0, 10) + "…";
  const statusMap = ["Active", "Paused", "Deactivated"];
  const status = statusMap[record.status] ?? "Unknown";
  const isRev = !!revoked;

  return (
    <Link
      href={`/dashboard/${agentId}`}
      className="bento-card-dark flex items-center justify-between p-5 border border-border group"
    >
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center gap-3">
          <TargetDot active color={isRev ? "red" : (status === "Active" ? "green" : "yellow")} />
          <span className="font-mono text-[13px] font-bold text-text group-hover:text-accent transition-colors">
            {shortId}
          </span>
          
          {isRev ? (
            <span className="bg-red-500/10 text-red-600 text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-full border border-red-500/20 uppercase">
              Revoked
            </span>
          ) : (
            <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-full border uppercase ${status === "Active" ? "bg-green-500/10 text-green-600 border-green-500/20" : "bg-yellow-500/10 text-yellow-600 border-yellow-500/20"}`}>
              {status}
            </span>
          )}
        </div>
        <span className="text-xs text-text-muted truncate max-w-sm ml-6 font-mono" title={record.did}>
          {record.did || "No DID associated"}
        </span>
      </div>

      <div className="flex items-center gap-6">
        <span className="text-xs font-mono text-text-muted px-3 py-1 bg-surface border border-border rounded-md shadow-sm">
          {record.model || "Unknown Model"}
        </span>

        <div className="w-8 h-8 rounded-full border border-border flex items-center justify-center bg-surface group-hover:bg-accent group-hover:text-white group-hover:border-accent transition-all">
          <ArrowRight size={14} />
        </div>
      </div>
    </Link>
  );
}

export default function DashboardPage() {
  const { address, chainId, isConnected } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;

  const { data: agentIds } = useReadContract({
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
            Bouclier Protocol is not currently deployed on this active network. Switch to Base Sepolia or deploy the core primitive contracts first.
          </p>
        </div>
      </div>
    );
  }

  const ids = (agentIds as `0x${string}`[] | undefined) ?? [];

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
      {/* Header Area */}
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        {/* Background decorative diagram element */}
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

      {/* Main Content Pane */}
      <div className="p-8 lg:p-12 flex-1 bg-surface relative">
        <div className="flex items-center justify-between mb-8 pb-4 border-b border-border">
          <h3 className="font-bold text-lg tracking-tight">Active Scopes</h3>
          <Link href="/dashboard/grant">
            <Button variant="primary" size="sm" className="uppercase text-[11px] tracking-widest pl-4">
              <span className="mr-2 text-xl font-light">+</span> New Agent Policy
            </Button>
          </Link>
        </div>

        {ids.length === 0 ? (
          <div className="bento-card-dark w-full py-24 flex flex-col items-center justify-center text-center border-dashed border-border mt-8">
            <ShieldCheck size={40} className="text-text-muted opacity-30 mb-6" />
            <h3 className="font-bold text-text mb-2">No agents under your control</h3>
            <p className="text-sm text-text-muted max-w-md">
              You haven't bound any LLMs to the registry yet. Create a new grant policy to wrap your first agent with cryptographic rules.
            </p>
            <Link href="/dashboard/grant" className="mt-8">
               <Button variant="outline" size="sm">Create Policy</Button>
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {ids.map((id) => (
              <AgentRow key={id} agentId={id} chainId={chainId!} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}