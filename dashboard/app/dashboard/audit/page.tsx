"use client";

import { useState } from "react";
import { useAccount, useReadContract } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  ShieldAlert,
  Activity,
  Crosshair,
  RefreshCw,
  Search,
  Download,
  ChevronDown,
  ChevronUp,
  ExternalLink,
  Copy,
  Check,
} from "lucide-react";
import { isDeployed, getContracts } from "@/lib/contracts";
import {
  agentRegistryAbi,
  auditLoggerAbi,
} from "@/lib/abis";
import { Button } from "@/components/ui/Button";
import Link from "next/link";

const E18 = 10n ** 18n;
function fmtUSD(raw: bigint) { return "$" + Number(raw / E18).toLocaleString(undefined, { maximumFractionDigits: 2 }); }
function fmtDate(ts: number) { return new Date(ts * 1000).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }); }
function fmtShort(hex: string, h = 8, t = 6) { return hex.length <= h + t + 2 ? hex : `${hex.slice(0, h)}…${hex.slice(-t)}`; }

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      onClick={(e) => { e.stopPropagation(); navigator.clipboard.writeText(text); setCopied(true); setTimeout(() => setCopied(false), 1500); }}
      className="p-1 hover:bg-border/50 rounded-sm transition-colors"
      title="Copy"
    >
      {copied ? <Check size={12} className="text-green-500" /> : <Copy size={12} className="text-text-muted" />}
    </button>
  );
}

function AuditRecordRow({ eventId, chainId, searchTerm }: { eventId: `0x${string}`; chainId: number; searchTerm: string }) {
  const [expanded, setExpanded] = useState(false);
  const addrs = getContracts(chainId);

  const { data: rec } = useReadContract({
    address: addrs.auditLogger,
    abi: auditLoggerAbi,
    functionName: "getAuditRecord",
    args: [eventId],
  });

  if (!rec) return (
    <div className="border-b border-border p-4 animate-pulse">
      <div className="h-3 bg-border/40 rounded w-1/3" />
    </div>
  );

  // Filter by search term
  if (searchTerm) {
    const s = searchTerm.toLowerCase();
    const matches =
      rec.target.toLowerCase().includes(s) ||
      rec.selector.toLowerCase().includes(s) ||
      eventId.toLowerCase().includes(s) ||
      rec.agentId.toLowerCase().includes(s) ||
      (rec.violationType && rec.violationType.toLowerCase().includes(s));
    if (!matches) return null;
  }

  return (
    <div className={`border-b border-border transition-colors ${expanded ? "bg-[#FAFAFA]" : "hover:bg-[#FAFAFA]"}`}>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 gap-2 cursor-pointer" onClick={() => setExpanded(!expanded)}>
        <div className="flex items-center gap-3">
          <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${rec.allowed ? "bg-green-500" : "bg-red-500"}`} />
          <div className="flex flex-col">
            <span className="font-mono text-xs font-bold text-text">{fmtShort(eventId)}</span>
            <span className="text-[10px] font-mono text-text-muted">Agent: {fmtShort(rec.agentId)}</span>
          </div>
        </div>
        <div className="flex items-center gap-4 ml-6 sm:ml-0">
          <span className="font-mono text-xs text-text-muted w-24">
            {rec.selector !== "0x00000000" ? rec.selector : "—"}
          </span>
          <span className="font-mono text-xs text-text-muted w-20">
            {rec.usdAmount > 0n ? fmtUSD(rec.usdAmount) : "—"}
          </span>
          <span className="font-mono text-[10px] text-text-muted w-32 text-right hidden md:block">
            {fmtDate(Number(rec.timestamp))}
          </span>
          <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-sm border uppercase w-16 text-center ${
            rec.allowed
              ? "bg-green-500/10 text-green-600 border-green-500/20"
              : "bg-red-500/10 text-red-600 border-red-500/20"
          }`}>
            {rec.allowed ? "OK" : "DENY"}
          </span>
          {expanded ? <ChevronUp size={14} className="text-text-muted" /> : <ChevronDown size={14} className="text-text-muted" />}
        </div>
      </div>

      {expanded && (
        <div className="px-4 pb-4 pt-0 border-t border-border/50 bg-white">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs mt-3">
            {[
              ["Event ID", eventId],
              ["Agent ID", rec.agentId],
              ["Action Hash", rec.actionHash],
              ["Target", rec.target],
              ["Selector", rec.selector],
              ["Token", rec.tokenAddress],
              ["USD Amount", rec.usdAmount > 0n ? fmtUSD(rec.usdAmount) : "0"],
              ["Timestamp", fmtDate(Number(rec.timestamp))],
              ["Outcome", rec.allowed ? "Allowed" : "Denied"],
              ["Violation", rec.violationType || "—"],
              ["IPFS CID", rec.ipfsCID || "—"],
            ].map(([label, value]) => (
              <div key={label as string} className="flex items-start justify-between gap-2 p-2 bg-[#FAFAFA] border border-border/50 rounded-sm">
                <span className="text-[10px] font-mono uppercase tracking-widest text-text-muted flex-shrink-0">{label as string}</span>
                <div className="flex items-center gap-1">
                  <span className="font-mono text-[11px] text-text break-all text-right">{fmtShort(value as string, 14, 8)}</span>
                  {(value as string).startsWith("0x") && (value as string).length > 10 && <CopyButton text={value as string} />}
                </div>
              </div>
            ))}
          </div>
          <div className="flex gap-2 mt-3">
            <a
              href={`https://sepolia.basescan.org/tx/${eventId}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[10px] font-mono text-accent hover:underline flex items-center gap-1"
            >
              View on Basescan <ExternalLink size={10} />
            </a>
          </div>
        </div>
      )}
    </div>
  );
}

function AgentAuditSection({ agentId, chainId, searchTerm }: { agentId: `0x${string}`; chainId: number; searchTerm: string }) {
  const addrs = getContracts(chainId);

  const { data: record } = useReadContract({
    address: addrs.agentRegistry,
    abi: agentRegistryAbi,
    functionName: "resolve",
    args: [agentId],
  });
  const { data: totalEvents } = useReadContract({
    address: addrs.auditLogger,
    abi: auditLoggerAbi,
    functionName: "getTotalEvents",
    args: [agentId],
  });
  const { data: eventIds } = useReadContract({
    address: addrs.auditLogger,
    abi: auditLoggerAbi,
    functionName: "getAgentHistory",
    args: [agentId, 0n, 100n],
  });

  const ids = (eventIds as `0x${string}`[]) ?? [];
  const total = Number(totalEvents ?? 0);
  const model = record?.model || "Unknown";

  if (total === 0 && !searchTerm) return null;

  return (
    <div className="border border-border bg-surface rounded-sm overflow-hidden mb-4">
      <div className="flex items-center justify-between p-4 bg-[#FAFAFA] border-b border-border">
        <div className="flex items-center gap-3">
          <Activity size={14} className="text-accent" />
          <span className="font-mono text-xs font-bold text-text">{fmtShort(agentId)}</span>
          <span className="text-[10px] font-mono text-text-muted bg-background border border-border px-2 py-0.5 rounded-sm">{model}</span>
        </div>
        <span className="text-[10px] font-mono text-text-muted">{total} event{total !== 1 ? "s" : ""}</span>
      </div>
      {ids.length > 0 ? (
        ids.map((eid) => (
          <AuditRecordRow key={eid} eventId={eid} chainId={chainId} searchTerm={searchTerm} />
        ))
      ) : (
        <div className="p-6 text-center text-xs text-text-muted font-mono">No events recorded</div>
      )}
    </div>
  );
}

export default function AuditLedgerPage() {
  const { isConnected, chainId, address } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;
  const [searchTerm, setSearchTerm] = useState("");

  const { data: agentIds, isLoading, refetch } = useReadContract({
    address: isConnected && chainId && deployed ? getContracts(chainId).agentRegistry : undefined,
    abi: agentRegistryAbi,
    functionName: "getAgentsByOwner",
    args: address ? [address] : undefined,
    query: { enabled: !!address && deployed },
  });

  if (!isConnected || !chainId) {
    return (
      <div className="w-full h-full min-h-[70vh] flex flex-col items-center justify-center p-8 bg-surface border-b border-border text-center overflow-hidden relative">
        <div className="absolute top-0 right-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none" />
        <div className="bento-card-dark p-12 max-w-lg w-full flex flex-col items-center shadow-2xl relative z-10">
          <div className="w-16 h-16 border border-border flex items-center justify-center bg-[#FAFAFA] rounded-xl mb-8 -mt-20 shadow-lg">
            <ShieldAlert size={28} className="text-accent" />
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-text mb-4">Registry Locked</h2>
          <p className="text-text-muted text-sm mb-10 leading-relaxed">
            Authentication required. Connect your enterprise wallet to view the global execution audit ledger.
          </p>
          <div className="w-full flex justify-center scale-110"><ConnectButton /></div>
        </div>
      </div>
    );
  }

  if (!deployed) {
    return (
      <div className="w-full h-full min-h-[70vh] flex flex-col items-center justify-center p-8 bg-surface border-b border-border text-center overflow-hidden relative">
        <div className="bento-card-dark p-12 max-w-lg w-full flex flex-col items-center shadow-2xl relative z-10 border-yellow-500/20 bg-yellow-500/5">
          <div className="w-16 h-16 border border-yellow-500/20 flex items-center justify-center bg-white rounded-xl mb-8 -mt-20 shadow-lg">
            <ShieldAlert size={28} className="text-yellow-600" />
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-yellow-800 mb-4">Network Mismatch</h2>
          <p className="text-yellow-800/80 text-sm mb-10 leading-relaxed">
            Switch to Base Sepolia using the connector below.
          </p>
          <div className="w-full flex justify-center scale-110"><ConnectButton /></div>
        </div>
      </div>
    );
  }

  const ids = (agentIds as `0x${string}`[] | undefined) ?? [];

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        <div className="relative z-10">
          <h1 className="text-[2.5rem] font-bold tracking-tight text-text leading-none mb-3">
            Global Audit Ledger<span className="text-accent">_</span>
          </h1>
          <p className="max-w-xl text-text-muted font-medium text-sm leading-relaxed">
            Immutable, tamper-proof record of every AI agent action — cryptographically anchored on-chain by the AuditLogger contract.
          </p>
        </div>
      </div>

      <div className="flex-1 p-8 lg:p-12">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <div className="relative flex-1 max-w-md">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input
              type="text"
              placeholder="Search by agent ID, target, selector…"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-white border border-border pl-9 pr-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
            />
          </div>
          <div className="flex items-center gap-3">
            <Button variant="outline" size="sm" onClick={() => refetch()} className="uppercase text-[11px] tracking-widest">
              <RefreshCw size={12} className="mr-1.5" /> Refresh
            </Button>
          </div>
        </div>

        {isLoading ? (
          <div className="space-y-4">
            {[1, 2].map((i) => (
              <div key={i} className="border border-border bg-surface p-5 rounded-sm animate-pulse">
                <div className="h-4 bg-border/50 rounded w-1/4 mb-3" />
                <div className="h-3 bg-border/30 rounded w-2/3" />
              </div>
            ))}
          </div>
        ) : ids.length === 0 ? (
          <div className="w-full py-20 flex flex-col items-center justify-center text-center border border-dashed border-border rounded-sm bg-[#FAFAFA]">
            <Crosshair size={40} className="text-text-muted opacity-30 mb-6" />
            <h3 className="font-bold text-text mb-2">No Agents Registered</h3>
            <p className="text-sm text-text-muted max-w-md">
              Register agents first to view their audit trail. All on-chain verified transactions will appear here.
            </p>
            <Link href="/dashboard" className="mt-6">
              <Button variant="outline" size="sm">Go to Dashboard</Button>
            </Link>
          </div>
        ) : (
          <div>
            <p className="text-xs font-mono text-text-muted mb-4">
              Showing audit trails for {ids.length} agent{ids.length !== 1 ? "s" : ""} registered to your wallet. Click any entry to expand full details.
            </p>
            {ids.map((id) => (
              <AgentAuditSection key={id} agentId={id} chainId={chainId!} searchTerm={searchTerm} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}