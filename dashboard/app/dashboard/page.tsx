"use client";

import { useState } from "react";
import {
  useAccount,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import Link from "next/link";
import { getContracts, isDeployed } from "@/lib/contracts";
import {
  agentRegistryAbi,
  revocationRegistryAbi,
  permissionVaultAbi,
  spendTrackerAbi,
  auditLoggerAbi,
} from "@/lib/abis";
import {
  ShieldCheck,
  ShieldAlert,
  Activity,
  Sliders,
  Database,
  X,
  Eye,
  Crosshair,
  Clock,
  Zap,
  BarChart3,
  AlertTriangle,
  ChevronRight,
  RefreshCw,
  FileText,
  Lock,
  Unlock,
  Users,
  TrendingUp,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { parseEther } from "viem";

/* ───────────── helpers ───────────── */
const E18 = 10n ** 18n;

function fmtUSD(raw: bigint): string {
  return "$" + Number(raw / E18).toLocaleString(undefined, { maximumFractionDigits: 2 });
}

function fmtDate(ts: number): string {
  return new Date(ts * 1000).toLocaleDateString(undefined, {
    year: "numeric", month: "short", day: "numeric",
  });
}

function fmtShort(hex: string, head = 10, tail = 6): string {
  if (hex.length <= head + tail + 2) return hex;
  return `${hex.slice(0, head)}…${hex.slice(-tail)}`;
}

const TargetDot = ({ active = false, color = "accent" }: { active?: boolean; color?: string }) => {
  let outer = "border-[#D4D4D8]", inner = "bg-[#D4D4D8]";
  if (active) {
    if (color === "accent")  { outer = "border-accent/30"; inner = "bg-accent"; }
    else if (color === "green")  { outer = "border-green-500/30"; inner = "bg-green-500"; }
    else if (color === "red")    { outer = "border-red-500/30"; inner = "bg-red-500"; }
    else if (color === "yellow") { outer = "border-yellow-500/30"; inner = "bg-yellow-500"; }
  }
  return (
    <div className={`rounded-full border flex items-center justify-center w-3.5 h-3.5 flex-shrink-0 ${outer}`}>
      <div className={`rounded-full w-1.5 h-1.5 ${inner}`} />
    </div>
  );
};

type DetailTab = "overview" | "permissions" | "audit";

/* ═══════════════════════════════════════════════════════
   STAT CARD – top-level KPI tile
   ═══════════════════════════════════════════════════════ */
function StatCard({ icon: Icon, label, value, sub }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string;
}) {
  return (
    <div className="flex flex-col gap-2 p-5 border border-border bg-[#FAFAFA] rounded-sm hover:shadow-sm transition-shadow">
      <div className="flex items-center gap-2 text-text-muted">
        <Icon size={14} />
        <span className="text-[10px] font-mono uppercase tracking-widest">{label}</span>
      </div>
      <span className="text-2xl font-bold tracking-tight text-text leading-none">{value}</span>
      {sub && <span className="text-[10px] font-mono text-text-muted">{sub}</span>}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   AGENT CARD – selectable card in the agent list
   ═══════════════════════════════════════════════════════ */
function AgentCard({ agentId, chainId, isSelected, onSelect }: {
  agentId: `0x${string}`; chainId: number; isSelected: boolean; onSelect: () => void;
}) {
  const addrs = getContracts(chainId);

  const { data: record } = useReadContract({
    address: addrs.agentRegistry, abi: agentRegistryAbi,
    functionName: "resolve", args: [agentId],
  });
  const { data: revoked } = useReadContract({
    address: addrs.revocationRegistry, abi: revocationRegistryAbi,
    functionName: "isRevoked", args: [agentId],
  });
  const { data: scope } = useReadContract({
    address: addrs.permissionVault, abi: permissionVaultAbi,
    functionName: "getActiveScope", args: [agentId],
  });

  if (!record) {
    return (
      <div className="border border-border bg-surface p-5 animate-pulse rounded-sm">
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
  const statusBg = isRev
    ? "bg-red-500/10 text-red-600 border-red-500/20"
    : status === "Active"
    ? "bg-green-500/10 text-green-600 border-green-500/20"
    : "bg-yellow-500/10 text-yellow-600 border-yellow-500/20";

  return (
    <div
      className={`border bg-surface p-5 rounded-sm transition-all cursor-pointer hover:shadow-md group ${
        isSelected
          ? "border-accent shadow-accent/10 ring-1 ring-accent/20"
          : "border-border hover:border-text/20"
      }`}
      onClick={onSelect}
    >
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <TargetDot active color={statusColor} />
          <span className="font-mono text-sm font-bold text-text group-hover:text-accent transition-colors">
            {fmtShort(agentId)}
          </span>
          <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-full border uppercase ${statusBg}`}>
            {isRev ? "Revoked" : status}
          </span>
        </div>
        <div className="flex items-center gap-2">
          {isSelected && (
            <span className="text-[10px] font-mono text-accent uppercase tracking-widest">Selected</span>
          )}
          <ChevronRight
            size={16}
            className={`text-text-muted transition-transform ${isSelected ? "rotate-90 text-accent" : ""}`}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
        <div>
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-0.5">Model</span>
          <span className="font-mono font-semibold text-text px-1.5 py-0.5 bg-background border border-border rounded-sm inline-block">
            {record.model || "—"}
          </span>
        </div>
        <div>
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-0.5">Wallet</span>
          <span className="font-mono text-text-muted truncate block max-w-[140px]">
            {record.agentAddress === "0x0000000000000000000000000000000000000000"
              ? "—"
              : fmtShort(record.agentAddress, 6, 4)}
          </span>
        </div>
        <div>
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-0.5">Registered</span>
          <span className="font-mono text-text-muted">
            {record.registeredAt ? fmtDate(Number(record.registeredAt)) : "—"}
          </span>
        </div>
        <div>
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-0.5">Scope</span>
          {hasScope && !scopeRevoked ? (
            <span className="text-green-600 font-semibold flex items-center gap-1">
              <Lock size={10} /> Active
            </span>
          ) : hasScope && scopeRevoked ? (
            <span className="text-red-500 font-semibold flex items-center gap-1">
              <Unlock size={10} /> Revoked
            </span>
          ) : (
            <span className="text-text-muted flex items-center gap-1">
              <Sliders size={10} /> None
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   OVERVIEW TAB
   ═══════════════════════════════════════════════════════ */
function OverviewTab({ agentId, chainId }: { agentId: `0x${string}`; chainId: number }) {
  const addrs = getContracts(chainId);

  const { data: record } = useReadContract({
    address: addrs.agentRegistry, abi: agentRegistryAbi,
    functionName: "resolve", args: [agentId],
  });
  const { data: revoked } = useReadContract({
    address: addrs.revocationRegistry, abi: revocationRegistryAbi,
    functionName: "isRevoked", args: [agentId],
  });
  const { data: scope } = useReadContract({
    address: addrs.permissionVault, abi: permissionVaultAbi,
    functionName: "getActiveScope", args: [agentId],
  });
  const { data: rollingSpend } = useReadContract({
    address: addrs.spendTracker, abi: spendTrackerAbi,
    functionName: "getRollingSpend", args: [agentId, BigInt(86400)],
  });
  const { data: totalEvents } = useReadContract({
    address: addrs.auditLogger, abi: auditLoggerAbi,
    functionName: "getTotalEvents", args: [agentId],
  });

  if (!record) return <div className="py-12 animate-pulse text-center text-text-muted font-mono text-sm">Loading telemetry…</div>;

  const statusMap = ["Active", "Paused", "Deactivated"];
  const status = statusMap[record.status] ?? "Unknown";
  const isRev = !!revoked;
  const hasScope = scope && scope.dailySpendCapUSD > 0n;
  const scopeActive = hasScope && !scope?.revoked;
  const dailyCap = hasScope ? scope.dailySpendCapUSD : 0n;
  const spend = (rollingSpend as bigint) ?? 0n;
  const utilPct = dailyCap > 0n ? Number((spend * 100n) / dailyCap) : 0;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-1">Status</span>
          <span className={`font-bold text-sm ${isRev ? "text-red-600" : status === "Active" ? "text-green-600" : "text-yellow-600"}`}>
            {isRev ? "REVOKED" : status.toUpperCase()}
          </span>
        </div>
        <div className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-1">24h Spend</span>
          <span className="font-bold text-sm text-text">{fmtUSD(spend)}</span>
        </div>
        <div className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-1">Daily Limit</span>
          <span className="font-bold text-sm text-text">{dailyCap > 0n ? fmtUSD(dailyCap) : "—"}</span>
        </div>
        <div className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
          <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest block mb-1">Auth Events</span>
          <span className="font-bold text-sm text-text">{totalEvents?.toString() ?? "0"}</span>
        </div>
      </div>

      {scopeActive && (
        <div className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest">Daily Limit Utilization</span>
            <span className={`text-xs font-bold font-mono ${utilPct > 80 ? "text-red-600" : utilPct > 50 ? "text-yellow-600" : "text-green-600"}`}>
              {utilPct}%
            </span>
          </div>
          <div className="w-full h-2 bg-border rounded-full overflow-hidden">
            <div
              className={`h-full transition-all rounded-full ${utilPct > 80 ? "bg-red-500" : utilPct > 50 ? "bg-yellow-500" : "bg-green-500"}`}
              style={{ width: `${Math.min(utilPct, 100)}%` }}
            />
          </div>
          <div className="flex justify-between mt-1.5 text-[10px] font-mono text-text-muted">
            <span>{fmtUSD(spend)} spent</span>
            <span>{fmtUSD(dailyCap)} limit</span>
          </div>
        </div>
      )}

      <div className="border border-border bg-[#FAFAFA] rounded-sm">
        <div className="flex items-center gap-2 p-4 border-b border-border">
          <Database size={14} className="text-accent" />
          <span className="text-[11px] font-mono uppercase tracking-widest font-bold">Identity & Registration</span>
        </div>
        <div className="divide-y divide-border">
          {[
            ["Agent ID", agentId],
            ["Wallet Address", record.agentAddress],
            ["Owner", record.owner],
            ["DID", record.did || "—"],
            ["Model", record.model || "—"],
            ["Registered At", record.registeredAt ? fmtDate(Number(record.registeredAt)) : "—"],
            ["Metadata CID", record.metadataCID || "—"],
          ].map(([label, val]) => (
            <div key={label as string} className="flex flex-col sm:flex-row sm:items-center justify-between p-4 gap-1">
              <span className="text-[10px] font-mono uppercase tracking-widest text-text-muted">{label as string}</span>
              <span className="text-text font-mono text-[11px] break-all">{val as string}</span>
            </div>
          ))}
        </div>
      </div>

      {scopeActive && (
        <div className="border border-border bg-[#FAFAFA] rounded-sm">
          <div className="flex items-center gap-2 p-4 border-b border-border">
            <ShieldCheck size={14} className="text-green-500" />
            <span className="text-[11px] font-mono uppercase tracking-widest font-bold">Active Protocol Bounds</span>
          </div>
          <div className="divide-y divide-border">
            {[
              ["Daily Limit", fmtUSD(scope!.dailySpendCapUSD)],
              ["Per-Tx Limit", fmtUSD(scope!.perTxSpendCapUSD)],
              ["Valid From", fmtDate(Number(scope!.validFrom))],
              ["Valid Until", fmtDate(Number(scope!.validUntil))],
              ["Any Protocol", scope!.allowAnyProtocol ? "Yes" : "No"],
              ["Any Token", scope!.allowAnyToken ? "Yes" : "No"],
              ["Trade Window", `${scope!.windowStartHour}:00 – ${scope!.windowEndHour}:00 UTC`],
              ["Chain ID", scope!.allowedChainId.toString()],
            ].map(([label, val]) => (
              <div key={label} className="flex items-center justify-between p-4">
                <span className="text-[10px] font-mono uppercase tracking-widest text-text-muted">{label}</span>
                <span className="text-sm font-mono text-text">{val}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {scopeActive && utilPct > 80 && (
        <div className="border border-red-500/20 bg-red-500/5 rounded-sm p-4 flex items-start gap-3">
          <AlertTriangle size={18} className="text-red-500 mt-0.5 flex-shrink-0" />
          <div>
            <h4 className="font-bold text-sm text-red-700">High Spend Alert</h4>
            <p className="text-xs text-red-600 mt-1">
              This agent has consumed {utilPct}% of its daily limit. Consider reviewing recent activity or adjusting limits.
            </p>
          </div>
        </div>
      )}

      {scope && Number(scope.validUntil) > 0 && Number(scope.validUntil) * 1000 < Date.now() + 7 * 86400000 && Number(scope.validUntil) * 1000 > Date.now() && (
        <div className="border border-yellow-500/20 bg-yellow-500/5 rounded-sm p-4 flex items-start gap-3">
          <Clock size={18} className="text-yellow-600 mt-0.5 flex-shrink-0" />
          <div>
            <h4 className="font-bold text-sm text-yellow-700">Scope Expiring Soon</h4>
            <p className="text-xs text-yellow-600 mt-1">
              This agent&apos;s permission scope expires on {fmtDate(Number(scope.validUntil))}. Renew before expiry to prevent service interruption.
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   PERMISSIONS TAB – Grant / Revoke
   ═══════════════════════════════════════════════════════ */
function PermissionsTab({ agentId, chainId }: { agentId: `0x${string}`; chainId: number }) {
  const { address } = useAccount();
  const contracts = getContracts(chainId);

  const { data: scope, refetch: refetchScope } = useReadContract({
    address: contracts.permissionVault, abi: permissionVaultAbi,
    functionName: "getActiveScope", args: [agentId],
  });

  const [dailyCap, setDailyCap] = useState("1000");
  const [perTxCap, setPerTxCap] = useState("100");
  const [allowAnyProtocol, setAllowAnyProtocol] = useState(true);
  const [validDays, setValidDays] = useState("365");
  const [windowStart, setWindowStart] = useState("0");
  const [windowEnd, setWindowEnd] = useState("24");

  const { writeContract: writeGrant, data: grantHash, isPending: grantPending, error: grantError } = useWriteContract();
  const { isLoading: grantConfirming, isSuccess: grantConfirmed } = useWaitForTransactionReceipt({ hash: grantHash });

  const { writeContract: writeRevoke, data: revokeHash, isPending: revokePending, error: revokeError } = useWriteContract();
  const { isLoading: revokeConfirming, isSuccess: revokeConfirmed } = useWaitForTransactionReceipt({ hash: revokeHash });

  const hasActiveScope = scope && scope.dailySpendCapUSD > 0n && !scope.revoked;

  const handleGrant = () => {
    if (!address) return;
    const now = ~~(Date.now() / 1000);
    const scopeData = {
      agentId,
      allowedProtocols: [] as `0x${string}`[],
      allowedSelectors: [] as `0x${string}`[],
      allowedTokens: [] as `0x${string}`[],
      dailySpendCapUSD: parseEther(dailyCap),
      perTxSpendCapUSD: parseEther(perTxCap),
      validFrom: now,
      validUntil: now + Number(validDays) * 86400,
      allowAnyProtocol,
      allowAnyToken: true,
      revoked: false,
      grantHash: ("0x" + "0".repeat(64)) as `0x${string}`,
      windowStartHour: Number(windowStart),
      windowEndHour: Number(windowEnd),
      windowDaysMask: 127,
      allowedChainId: BigInt(chainId),
    };
    writeGrant({
      address: contracts.permissionVault,
      abi: permissionVaultAbi,
      functionName: "grantPermission",
      args: [agentId, scopeData as any, "0x"],
    });
  };

  const handleRevoke = () => {
    writeRevoke({
      address: contracts.permissionVault,
      abi: permissionVaultAbi,
      functionName: "revokePermission",
      args: [agentId],
    });
  };

  return (
    <div className="space-y-6">
      {hasActiveScope ? (
        <div className="border border-green-500/20 bg-green-500/5 rounded-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <ShieldCheck size={18} className="text-green-500" />
              <span className="font-bold text-sm text-green-700">Active Permission Scope</span>
            </div>
            <span className="text-[10px] font-mono text-green-600 uppercase tracking-widest">
              Expires {fmtDate(Number(scope!.validUntil))}
            </span>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs font-mono mb-4">
            <div><span className="text-green-600/70 text-[10px] uppercase block mb-0.5">Daily Cap</span>{fmtUSD(scope!.dailySpendCapUSD)}</div>
            <div><span className="text-green-600/70 text-[10px] uppercase block mb-0.5">Per-Tx Cap</span>{fmtUSD(scope!.perTxSpendCapUSD)}</div>
            <div><span className="text-green-600/70 text-[10px] uppercase block mb-0.5">Protocols</span>{scope!.allowAnyProtocol ? "Any" : "Restricted"}</div>
            <div><span className="text-green-600/70 text-[10px] uppercase block mb-0.5">Window</span>{scope!.windowStartHour}:00–{scope!.windowEndHour}:00</div>
          </div>
          <div className="border-t border-green-500/20 pt-4 mt-2">
            {revokeConfirmed ? (
              <div className="flex items-center gap-2 text-red-600">
                <ShieldAlert size={16} />
                <span className="text-sm font-bold">Scope Revoked Successfully</span>
                <span className="text-[10px] font-mono ml-2">{revokeHash?.slice(0, 20)}…</span>
              </div>
            ) : (
              <div className="flex items-center gap-3">
                <Button
                  onClick={handleRevoke}
                  disabled={revokePending || revokeConfirming}
                  variant="outline"
                  size="sm"
                  className="border-red-500/30 text-red-600 hover:bg-red-500 hover:text-white hover:border-red-500 uppercase tracking-widest text-[11px] font-bold"
                >
                  {revokePending ? "Signing…" : revokeConfirming ? "Mining…" : "Revoke Entire Scope"}
                </Button>
                {revokeError && (
                  <span className="text-red-500 text-xs font-mono">{(revokeError as any).shortMessage || "Failed"}</span>
                )}
              </div>
            )}
          </div>
        </div>
      ) : scope?.revoked ? (
        <div className="border border-red-500/20 bg-red-500/5 rounded-sm p-4 flex items-center gap-3">
          <ShieldAlert size={18} className="text-red-500" />
          <span className="font-bold text-sm text-red-700">Scope previously revoked. Grant a new scope below.</span>
        </div>
      ) : null}

      <div className="border border-border bg-[#FAFAFA] rounded-sm">
        <div className="flex items-center gap-2 p-4 border-b border-border">
          <Sliders size={14} className="text-accent" />
          <span className="text-[11px] font-mono uppercase tracking-widest font-bold">
            {hasActiveScope ? "Update Permission Scope" : "Grant New Permission Scope"}
          </span>
        </div>

        {grantConfirmed ? (
          <div className="flex flex-col items-center py-10 text-center">
            <ShieldCheck className="text-green-500 mb-4" size={48} />
            <h3 className="font-bold text-lg">Policy Active</h3>
            <p className="font-mono text-xs text-text-muted mt-2">Tx: {grantHash?.slice(0, 24)}…</p>
            <Button variant="outline" size="sm" onClick={() => refetchScope()} className="mt-4 uppercase text-[11px] tracking-widest">
              <RefreshCw size={12} className="mr-1.5" /> Refresh
            </Button>
          </div>
        ) : grantPending || grantConfirming ? (
          <div className="flex flex-col items-center py-10 text-center">
            <div className="w-12 h-12 border-2 border-accent border-t-transparent rounded-full animate-spin mb-4" />
            <p className="text-[11px] font-mono uppercase tracking-widest text-text">
              {grantPending ? "Awaiting Wallet Signature…" : "Mining On-Chain…"}
            </p>
          </div>
        ) : (
          <div className="p-5 space-y-5">
            {grantError && (
              <div className="flex items-start gap-2 p-3 border border-red-500/20 bg-red-500/5 rounded-sm text-red-600">
                <ShieldAlert size={16} className="mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-bold text-xs">Transaction Failed</p>
                  <p className="text-[11px] font-mono mt-1 break-words">{(grantError as any).shortMessage || grantError.message}</p>
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 flex items-center gap-1.5">
                  <Database size={11} /> Daily Spend Limit (USD)
                </label>
                <input
                  type="number" value={dailyCap}
                  onChange={(e) => setDailyCap(e.target.value)}
                  className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
                />
              </div>
              <div>
                <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 flex items-center gap-1.5">
                  <Activity size={11} /> Per-Transaction Cap (USD)
                </label>
                <input
                  type="number" value={perTxCap}
                  onChange={(e) => setPerTxCap(e.target.value)}
                  className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 flex items-center gap-1.5">
                  <Clock size={11} /> Validity (Days)
                </label>
                <input
                  type="number" value={validDays}
                  onChange={(e) => setValidDays(e.target.value)}
                  className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
                />
              </div>
              <div>
                <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 flex items-center gap-1.5">
                  <Zap size={11} /> Window Start (UTC Hour)
                </label>
                <input
                  type="number" min="0" max="23" value={windowStart}
                  onChange={(e) => setWindowStart(e.target.value)}
                  className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
                />
              </div>
              <div>
                <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 flex items-center gap-1.5">
                  <Zap size={11} /> Window End (UTC Hour)
                </label>
                <input
                  type="number" min="0" max="24" value={windowEnd}
                  onChange={(e) => setWindowEnd(e.target.value)}
                  className="w-full bg-white border border-border px-4 py-2.5 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 transition-all rounded-sm"
                />
              </div>
            </div>

            <div
              className="flex items-center gap-3 p-3 border border-border bg-white cursor-pointer hover:border-text/20 transition-all rounded-sm"
              onClick={() => setAllowAnyProtocol(!allowAnyProtocol)}
            >
              <div className={`w-4 h-4 border flex items-center justify-center rounded-sm transition-colors ${
                allowAnyProtocol ? "bg-accent border-accent" : "border-border"
              }`}>
                {allowAnyProtocol && <div className="w-2 h-2 bg-white rounded-sm" />}
              </div>
              <span className="text-[11px] font-mono uppercase tracking-widest text-text">Allow Any Protocol</span>
            </div>

            <Button variant="primary" onClick={handleGrant} className="w-full uppercase text-[11px] tracking-widest h-11 font-mono">
              {hasActiveScope ? "Override & Grant New Scope" : "Grant Permission Scope"}
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   AUDIT TAB – on-chain event feed
   ═══════════════════════════════════════════════════════ */
function AuditRow({ eventId, chainId }: { eventId: `0x${string}`; chainId: number }) {
  const addrs = getContracts(chainId);
  const { data: rec } = useReadContract({
    address: addrs.auditLogger, abi: auditLoggerAbi,
    functionName: "getAuditRecord", args: [eventId],
  });

  if (!rec) return null;

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-border py-3.5 last:border-0 hover:bg-[#FAFAFA] transition-colors -mx-5 px-5">
      <div className="flex items-center gap-3 mb-2 sm:mb-0">
        <TargetDot active color={rec.allowed ? "green" : "red"} />
        <div className="flex flex-col gap-0.5">
          <span className="font-mono text-xs font-bold text-text truncate max-w-[180px]" title={rec.selector}>
            {rec.selector}
          </span>
          <span className="text-[10px] font-mono text-text-muted">
            Target: {fmtShort(rec.target, 6, 4)}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-4 ml-7 sm:ml-0">
        <span className="font-mono text-xs text-text-muted w-16">
          {rec.usdAmount > 0n ? fmtUSD(rec.usdAmount) : "—"}
        </span>
        <span className="font-mono text-[10px] text-text-muted w-20 text-right">
          {fmtDate(Number(rec.timestamp))}
        </span>
        <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-sm border uppercase w-16 text-center ${
          rec.allowed
            ? "bg-green-500/10 text-green-600 border-green-500/20"
            : "bg-red-500/10 text-red-600 border-red-500/20"
        }`}>
          {rec.allowed ? "OK" : rec.violationType || "DENY"}
        </span>
      </div>
    </div>
  );
}

function AuditTab({ agentId, chainId }: { agentId: `0x${string}`; chainId: number }) {
  const addrs = getContracts(chainId);

  const { data: totalEvents } = useReadContract({
    address: addrs.auditLogger, abi: auditLoggerAbi,
    functionName: "getTotalEvents", args: [agentId],
  });
  const { data: eventIds } = useReadContract({
    address: addrs.auditLogger, abi: auditLoggerAbi,
    functionName: "getAgentHistory", args: [agentId, 0n, 50n],
  });

  const ids = (eventIds as `0x${string}`[]) ?? [];
  const total = Number(totalEvents ?? 0);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-mono text-text-muted uppercase tracking-widest">
          {total} Total Event{total !== 1 ? "s" : ""}
        </span>
      </div>

      {ids.length === 0 ? (
        <div className="w-full py-16 flex flex-col items-center justify-center text-center border border-dashed border-border rounded-sm bg-[#FAFAFA]">
          <Crosshair size={32} className="text-text-muted opacity-30 mb-4" />
          <h3 className="font-bold text-text text-sm">No Recorded Executions</h3>
          <p className="text-xs text-text-muted mt-2 max-w-sm">
            Monitoring framework is active. Future on-chain verified transactions for this agent will appear here.
          </p>
        </div>
      ) : (
        <div className="border border-border bg-[#FAFAFA] rounded-sm p-5">
          <div className="flex items-center gap-2 mb-4 pb-3 border-b border-border">
            <Activity size={14} className="text-text" />
            <span className="text-[11px] font-mono uppercase tracking-widest font-bold">Cryptographic Audit Feed</span>
          </div>
          {ids.map((eid) => (
            <AuditRow key={eid} eventId={eid} chainId={chainId} />
          ))}
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   AGENT DETAIL PANEL – appears when an agent is selected
   ═══════════════════════════════════════════════════════ */
function AgentDetailPanel({ agentId, chainId, onClose }: {
  agentId: `0x${string}`; chainId: number; onClose: () => void;
}) {
  const [tab, setTab] = useState<DetailTab>("overview");

  const tabs: { key: DetailTab; label: string; icon: React.ElementType }[] = [
    { key: "overview", label: "Overview", icon: BarChart3 },
    { key: "permissions", label: "Permissions", icon: Sliders },
    { key: "audit", label: "Audit Trail", icon: FileText },
  ];

  return (
    <div className="border border-accent/20 bg-white rounded-sm mt-6 shadow-sm overflow-hidden">
      <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-[#FAFAFA]">
        <div className="flex items-center gap-3">
          <Eye size={16} className="text-accent" />
          <span className="font-bold text-sm tracking-tight">
            Agent {fmtShort(agentId)}
          </span>
        </div>
        <button onClick={onClose} className="p-1.5 hover:bg-surface rounded-sm transition-colors">
          <X size={16} className="text-text-muted" />
        </button>
      </div>

      <div className="flex border-b border-border bg-[#FAFAFA]">
        {tabs.map(({ key, label, icon: TabIcon }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex items-center gap-2 px-5 py-3 text-[11px] font-mono uppercase tracking-widest transition-all border-b-2 ${
              tab === key
                ? "border-accent text-accent font-bold"
                : "border-transparent text-text-muted hover:text-text"
            }`}
          >
            <TabIcon size={13} />
            {label}
          </button>
        ))}
      </div>

      <div className="p-5 bg-white">
        {tab === "overview" && <OverviewTab agentId={agentId} chainId={chainId} />}
        {tab === "permissions" && <PermissionsTab agentId={agentId} chainId={chainId} />}
        {tab === "audit" && <AuditTab agentId={agentId} chainId={chainId} />}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   MAIN DASHBOARD PAGE
   ═══════════════════════════════════════════════════════ */
export default function DashboardPage() {
  const { address, chainId, isConnected } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;
  const [selectedAgent, setSelectedAgent] = useState<`0x${string}` | null>(null);

  const { data: agentIds, isLoading, refetch } = useReadContract({
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
        <div className="absolute top-0 right-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-accent/5 rounded-full blur-[100px] pointer-events-none" />
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
            <TargetDot active color="yellow" /> Network mismatch
          </h3>
          <p className="text-sm opacity-80 pl-5">
            Bouclier Protocol is not deployed on this network. Switch to Base Sepolia using the connector below.
          </p>
          <div className="mt-4 pl-5">
            <ConnectButton />
          </div>
        </div>
      </div>
    );
  }

  const ids = (agentIds as `0x${string}`[] | undefined) ?? [];
  const agentCount = ids.length;

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
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
            Enterprise Dashboard — {agentCount} agent{agentCount !== 1 ? "s" : ""} registered on-chain
          </p>
        </div>
      </div>

      <div className="p-8 lg:p-12 flex-1 bg-surface relative">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard icon={Users} label="Total Agents" value={agentCount} sub="Registered to your wallet" />
          <StatCard icon={ShieldCheck} label="Protocol" value="Bouclier" sub="Base Sepolia (84532)" />
          <StatCard icon={TrendingUp} label="Network" value={isConnected ? "Connected" : "—"} sub={address ? `${address.slice(0, 6)}…${address.slice(-4)}` : ""} />
          <StatCard icon={Activity} label="Contracts" value="5" sub="Registry · Vault · Tracker · Logger · Revoke" />
        </div>

        <div className="flex items-center justify-between mb-5">
          <h3 className="font-bold text-lg tracking-tight">Your Agents</h3>
          <div className="flex items-center gap-3">
            <Button variant="outline" size="sm" onClick={() => refetch()} className="uppercase text-[11px] tracking-widest">
              <RefreshCw size={12} className="mr-1.5" /> Refresh
            </Button>
            <Link href="/dashboard/grant">
              <Button variant="primary" size="sm" className="uppercase text-[11px] tracking-widest pl-4">
                <span className="mr-2 text-xl font-light">+</span> New Agent Policy
              </Button>
            </Link>
          </div>
        </div>

        {isLoading ? (
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="border border-border bg-surface p-5 rounded-sm animate-pulse">
                <div className="h-4 bg-border/50 rounded w-1/4 mb-4" />
                <div className="grid grid-cols-4 gap-4">
                  <div className="h-3 bg-border/30 rounded" />
                  <div className="h-3 bg-border/30 rounded" />
                  <div className="h-3 bg-border/30 rounded" />
                  <div className="h-3 bg-border/30 rounded" />
                </div>
              </div>
            ))}
          </div>
        ) : agentCount === 0 ? (
          <div className="w-full py-20 flex flex-col items-center justify-center text-center border border-dashed border-border rounded-sm bg-[#FAFAFA]">
            <ShieldCheck size={40} className="text-text-muted opacity-30 mb-6" />
            <h3 className="font-bold text-text mb-2">No Agents Registered</h3>
            <p className="text-sm text-text-muted max-w-md">
              You haven&apos;t bound any AI agents to the on-chain registry yet. Create a new grant policy to wrap your first agent with cryptographic spending rules.
            </p>
            <Link href="/dashboard/grant" className="mt-8">
              <Button variant="outline" size="sm">Create First Policy</Button>
            </Link>
          </div>
        ) : (
          <>
            <p className="text-xs font-mono text-text-muted mb-4">
              Click an agent to view details, set permissions, and monitor audit trails.
            </p>
            <div className="space-y-3">
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

            {selectedAgent && (
              <AgentDetailPanel
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
