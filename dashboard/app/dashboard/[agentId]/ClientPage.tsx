"use client";

import { useParams } from "next/navigation";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { getContracts, isDeployed } from "@/lib/contracts";
import {
  agentRegistryAbi,
  revocationRegistryAbi,
  permissionVaultAbi,
  spendTrackerAbi,
  auditLoggerAbi,
} from "@/lib/abis";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { ShieldAlert, ShieldCheck, Activity, Database, Crosshair } from "lucide-react";
import { ConnectButton } from "@rainbow-me/rainbowkit";

const E18 = 10n ** 18n;

function formatUSD(raw: bigint): string {
  return "$" + (Number(raw / E18)).toLocaleString(undefined, { maximumFractionDigits: 2 });
}

function formatDate(ts: number): string {
  return new Date(ts * 1000).toLocaleDateString(undefined, {
    year: "numeric", month: "short", day: "numeric",
  });
}

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
    <div className={`rounded-full flex-shrink-0 border flex items-center justify-center w-3.5 h-3.5 ${outer}`}>
      <div className={`rounded-full w-1.5 h-1.5 ${inner}`}></div>
    </div>
  );
};

function AuditRow({ eventId, chainId }: { eventId: `0x${string}`; chainId: number }) {
  const addrs = getContracts(chainId);
  const { data: rec } = useReadContract({
    address: addrs.auditLogger,
    abi:     auditLoggerAbi,
    functionName: "getAuditRecord",
    args:    [eventId],
  });

  if (!rec) return null;

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border py-4 last:border-0 hover:bg-[#FAFAFA] transition-colors -mx-6 px-6 sm:-mx-8 sm:px-8">
      <div className="flex items-center gap-4 w-full sm:w-1/2 mb-3 sm:mb-0">
        <TargetDot active color={rec.allowed ? "green" : "red"} />
        <div className="flex flex-col gap-0.5 overflow-hidden">
          <span className="font-mono text-sm font-bold text-text truncate max-w-[200px] lg:max-w-xs" title={rec.selector}>
            {rec.selector}
          </span>
          <span className="text-[10px] font-mono uppercase tracking-widest text-text-muted truncate">
            Target: {rec.target.slice(0, 8)}…{rec.target.slice(-6)}
          </span>
        </div>
      </div>
      <div className="flex items-center sm:justify-end gap-6 w-full sm:w-1/2 ml-7 sm:ml-0 text-left sm:text-right">
        <span className="font-mono text-xs text-text-muted w-16 whitespace-nowrap">
          {rec.usdAmount > 0n ? formatUSD(rec.usdAmount) : "—"}
        </span>
        <span className="font-mono text-xs text-text-muted w-24 text-right">
          {formatDate(Number(rec.timestamp))}
        </span>
        {!rec.allowed ? (
          <span className="bg-red-500/10 text-red-600 text-[10px] font-bold tracking-wider px-2 py-1 rounded-sm border border-red-500/20 uppercase w-20 text-center">
            {rec.violationType || "DENIED"}
          </span>
        ) : (
          <span className="bg-green-500/10 text-green-600 text-[10px] font-bold tracking-wider px-2 py-1 rounded-sm border border-green-500/20 uppercase w-20 text-center">
            SUCCESS
          </span>
        )}
      </div>
    </div>
  );
}

function DataRow({ label, value, highlight }: { label: string; value: string | React.ReactNode; highlight?: "red" | "green" }) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between py-3 border-b border-border last:border-0 gap-2">
      <span className="text-[11px] font-mono uppercase tracking-widest text-text-muted">{label}</span>
      <span
        className={`text-sm font-mono font-medium text-right break-all ${
          highlight === "red"
            ? "text-red-500"
            : highlight === "green"
            ? "text-green-600"
            : "text-text"
        }`}
      >
        {value}
      </span>
    </div>
  );
}

export default function AgentDetailPage() {
  const { agentId } = useParams<{ agentId: string }>();
  const id = agentId as `0x${string}`;

  const { chainId, isConnected } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;

  const addrs = chainId ? getContracts(chainId) : ({} as ReturnType<typeof getContracts>);

  const { data: record } = useReadContract({
    address: isConnected && chainId ? addrs.agentRegistry : undefined,
    abi:     agentRegistryAbi,
    functionName: "resolve",
    args:    [id],
    query: { enabled: !!chainId },
  });

  const { data: revoked } = useReadContract({
    address: isConnected && chainId ? addrs.revocationRegistry : undefined,
    abi:     revocationRegistryAbi,
    functionName: "isRevoked",
    args:    [id],
    query: { enabled: !!chainId },
  });

  const { data: scope } = useReadContract({
    address: isConnected && chainId ? addrs.permissionVault : undefined,
    abi:     permissionVaultAbi,
    functionName: "getActiveScope",
    args:    [id],
    query: { enabled: !!chainId },
  });

  const { data: rollingSpend } = useReadContract({
    address: isConnected && chainId ? addrs.spendTracker : undefined,
    abi:     spendTrackerAbi,
    functionName: "getRollingSpend",
    args:    [id, BigInt(86400)],
    query: { enabled: !!chainId },
  });

  const { data: totalEvents } = useReadContract({
    address: isConnected && chainId ? addrs.auditLogger : undefined,
    abi:     auditLoggerAbi,
    functionName: "getTotalEvents",
    args:    [id],
    query: { enabled: !!chainId },
  });

  const { data: eventIds } = useReadContract({
    address: isConnected && chainId ? addrs.auditLogger : undefined,
    abi:     auditLoggerAbi,
    functionName: "getAgentHistory",
    args:    [id, 0n, 20n],
    query: { enabled: !!chainId },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  function handleRevoke() {
    if (!chainId) return;
    writeContract({
      address: addrs.permissionVault,
      abi:     permissionVaultAbi,
      functionName: "revokePermission",
      args:    [id],
    });
  }

  if (!isConnected || !chainId) {
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
            Authentication required. Connect your enterprise wallet to view agent execution scopes.
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
      <div className="w-full h-full min-h-[70vh] flex flex-col items-center justify-center p-8 bg-surface border-b border-border text-center overflow-hidden relative">
        <div className="bento-card-dark p-12 max-w-lg w-full flex flex-col items-center shadow-2xl relative z-10 transition-all duration-700 border-yellow-500/20 bg-yellow-500/5">
          <div className="w-16 h-16 border border-yellow-500/20 flex items-center justify-center bg-white rounded-xl mb-8 -mt-20 shadow-lg">
            <ShieldAlert size={28} className="text-yellow-600" />
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-yellow-800 mb-4">Network Mismatch</h2>
          <p className="text-yellow-800/80 text-sm mb-10 leading-relaxed">
            Bouclier Protocol is not currently deployed on this active network. Switch to Base Sepolia using the connector below.
          </p>
          <div className="w-full flex justify-center scale-110">
            <ConnectButton />
          </div>
        </div>
      </div>
    );
  }

  if (!record) {
    return (
      <div className="w-full h-full min-h-[70vh] flex flex-col items-center justify-center p-8 bg-surface border-b border-border">
        <TargetDot active color="accent" />
        <div className="text-sm font-mono mt-4 uppercase tracking-widest text-text-muted animate-pulse">Resolving Identity...</div>
      </div>
    );
  }

  const statusMap = ["Active", "Paused", "Deactivated"];
  const isRev = !!revoked;
  const status = statusMap[record.status] ?? "Unknown";

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
      {/* Header Area */}
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        {/* Architect Graphic */}
        <div className="absolute right-[-100px] top-[-50px] w-96 h-96 opacity-5 pointer-events-none crosshair"></div>
        <div className="relative z-10">
          <Link href="/dashboard" className="text-[10px] font-mono tracking-widest uppercase text-text-muted hover:text-accent mb-6 inline-flex border-b border-transparent hover:border-accent pb-0.5 transition-colors">
            ← Registry Index
          </Link>
          
          <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-6 mt-4">
             <div>
                <div className="flex items-center gap-4 mb-3">
                  <TargetDot active color={isRev ? "red" : (status === "Active" ? "green" : "yellow")} />
                  {isRev ? (
                    <span className="bg-red-500/10 text-red-600 text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-sm border border-red-500/20 uppercase">
                      Revoked
                    </span>
                  ) : (
                    <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-sm border uppercase ${status === "Active" ? "bg-green-500/10 text-green-600 border-green-500/20" : "bg-yellow-500/10 text-yellow-600 border-yellow-500/20"}`}>
                      {status}
                    </span>
                  )}
                </div>
                <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-text leading-none font-mono mt-2 break-all">
                  {id}
                </h1>
                <p className="text-sm font-mono text-text-muted mt-3 tracking-tight break-all">
                  DID: {record.did || "None"}
                </p>
             </div>
             
             <div className="flex-shrink-0">
               {!revoked && scope && !scope.revoked && (
                 <div className="flex flex-col items-end gap-2">
                   <Button
                     onClick={handleRevoke}
                     disabled={isPending || isConfirming}
                     variant="outline"
                     className="border-red-500/30 text-red-600 hover:bg-red-500 hover:text-white hover:border-red-500 uppercase tracking-widest text-[11px] h-10 px-6 font-bold"
                   >
                     {isPending ? "Signing..." : isConfirming ? "Mining..." : "Revoke Entire Scope"}
                   </Button>
                   {isConfirmed && <div className="text-[10px] uppercase font-mono text-green-600 tracking-widest">Scope Revoked</div>}
                 </div>
               )}
             </div>
          </div>
        </div>
      </div>

      {/* Main Content Pane */}
      <div className="flex-1 bg-surface p-8 lg:p-12 relative">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Column 1: Info & Scope */}
          <div className="lg:col-span-1 flex flex-col gap-8">
             
             {/* Stats Info */}
             <div className="bento-card-dark border border-border p-6 sm:p-8 bg-[#FAFAFA]">
               <div className="flex items-center gap-3 mb-6 pb-4 border-b border-border">
                  <Database size={18} className="text-accent" />
                  <h3 className="font-bold text-sm tracking-widest uppercase">Agent Telemetry</h3>
               </div>
               <div className="flex flex-col">
                 <DataRow label="Model Hash" value={record.model || "—"} />
                 <DataRow label="24h Rolling Spend" value={rollingSpend != null ? formatUSD(rollingSpend as bigint) : "—"} />
                 <DataRow label="Total Auth Events" value={totalEvents?.toString() ?? "—"} />
               </div>
             </div>

             {/* Permission Scope */}
             <div className="bento-card-dark border border-border p-6 sm:p-8 bg-[#FAFAFA]">
               <div className="flex items-center gap-3 mb-6 pb-4 border-b border-border">
                  <ShieldCheck size={18} className="text-text-muted" />
                  <h3 className="font-bold text-sm tracking-widest uppercase">Active Protocol Bounds</h3>
               </div>
               
               {!scope || scope.agentId === ("0x" + "0".repeat(64)) ? (
                <div className="py-8 text-center text-xs font-mono text-text-muted uppercase tracking-widest border border-dashed border-border mt-4">
                  No active on-chain scope
                </div>
              ) : (
                <div className="flex flex-col">
                  <DataRow label="Daily Limit" value={formatUSD(scope.dailySpendCapUSD as bigint)} />
                  <DataRow label="Per-Tx Limit" value={formatUSD(scope.perTxSpendCapUSD as bigint)} />
                  <DataRow label="Valid From" value={formatDate(Number(scope.validFrom))} />
                  <DataRow label="Valid Until" value={formatDate(Number(scope.validUntil))} />
                  <DataRow label="Any Protocol" value={scope.allowAnyProtocol ? "Yes" : "No"} />
                  <DataRow label="Any Token" value={scope.allowAnyToken ? "Yes" : "No"} />
                  <DataRow
                    label="Status"
                    value={scope.revoked ? "Revoked" : "Active"}
                    highlight={scope.revoked ? "red" : "green"}
                  />
                  
                  <div className="pt-4 mt-2 border-t border-border">
                    <span className="text-[11px] font-mono uppercase tracking-widest text-text-muted block mb-3">Allowed Sub-Protocols</span>
                    <div className="flex flex-wrap gap-2">
                       {scope.allowAnyProtocol ? (
                          <span className="text-xs font-mono px-2 py-1 bg-green-500/10 text-green-600 border border-green-500/20 rounded-sm">ALL (Universal Access)</span>
                       ) : (scope.allowedProtocols as string[]).length > 0 ? (
                          (scope.allowedProtocols as string[]).map((p) => (
                             <span key={p} className="text-[10px] font-mono px-2 py-1 bg-body border border-border rounded-sm">{p}</span>
                          ))
                       ) : (
                          <span className="text-xs font-mono px-2 py-1 bg-surface border border-border text-text-muted rounded-sm">NONE BINDED</span>
                       )}
                    </div>
                  </div>
                </div>
              )}
             </div>

          </div>

          {/* Column 2: Audit Feed */}
          <div className="lg:col-span-2 bento-card-dark border border-border bg-[#FAFAFA]">
            <div className="flex items-center gap-3 p-6 sm:p-8 border-b border-border">
               <Activity size={18} className="text-text" />
               <h3 className="font-bold text-sm tracking-widest uppercase">Cryptographic Audit Feed</h3>
            </div>
            
            <div className="p-6 sm:p-8 pt-2">
              {!eventIds || (eventIds as `0x${string}`[]).length === 0 ? (
                <div className="w-full py-16 flex flex-col items-center justify-center text-center border border-dashed border-border mt-6">
                  <Crosshair size={32} className="text-text-muted opacity-30 mb-4" />
                  <h3 className="font-bold text-text text-sm">No recorded executions</h3>
                  <p className="text-xs text-text-muted mt-2">
                    Monitoring framework active. Future verified transactions will populate here.
                  </p>
                </div>
              ) : (
                <div className="flex flex-col">
                  {(eventIds as `0x${string}`[]).map((eid) => (
                    <AuditRow key={eid} eventId={eid} chainId={chainId} />
                  ))}
                </div>
              )}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}