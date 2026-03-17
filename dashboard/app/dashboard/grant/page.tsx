"use client";

import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useSignTypedData, useWaitForTransactionReceipt } from "wagmi";
import { getContracts, isDeployed } from "@/lib/contracts";
import { agentRegistryAbi, permissionVaultAbi } from "@/lib/abis";
import { Button } from "@/components/ui/Button";
import { ShieldAlert, ShieldCheck, Database, Sliders, ChevronDown, Clock, Zap, ExternalLink } from "lucide-react";
import Link from "next/link";
import { parseEther } from "viem";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { toast } from "sonner";

function fmtShort(hex: string, h = 10, t = 6) { return hex.length <= h + t + 2 ? hex : `${hex.slice(0, h)}…${hex.slice(-t)}`; }

export default function GrantPage() {
  const { isConnected, chainId, address } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;

  // Wizard state
  const [step, setStep] = useState(1);

  // Form State
  const [agentId, setAgentId] = useState("");
  const [dailyCap, setDailyCap] = useState("1000");
  const [perTxCap, setPerTxCap] = useState("100");
  const [allowAnyProtocol, setAllowAnyProtocol] = useState(true);
  const [validDays, setValidDays] = useState("365");
  const [windowStart, setWindowStart] = useState("0");
  const [windowEnd, setWindowEnd] = useState("24");
  const [signature, setSignature] = useState<`0x${string}`>();

  const contracts = isConnected && chainId ? getContracts(chainId) : null;

  // Fetch user's agents for the picker
  const { data: ownedAgentIds } = useReadContract({
    address: contracts?.agentRegistry,
    abi: agentRegistryAbi,
    functionName: "getAgentsByOwner",
    args: address ? [address] : undefined,
    query: { enabled: !!address && deployed },
  });
  const agentOptions = (ownedAgentIds as `0x${string}`[] | undefined) ?? [];

  // Read nonces
  const { data: nonce } = useReadContract({
    address: agentId && contracts ? contracts.permissionVault : undefined,
    abi: permissionVaultAbi,
    functionName: "grantNonces",
    args: agentId ? [agentId as `0x${string}`] : undefined,
    query: { enabled: !!agentId && agentId.length === 66 && !!contracts },
  });

  const { signTypedDataAsync } = useSignTypedData();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const handleSignRow = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!contracts || !chainId || !address) return;

    const currentNonce = nonce ?? 0n;

    // Ensure agentId is strictly 32 bytes (66 chars including 0x)
    const finalAgentId = (agentId.startsWith("0x") ? agentId : "0x" + agentId).padEnd(66, "0") as `0x${string}`;

    const validFromTs = ~~(Date.now() / 1000);
    const validUntilTs = validFromTs + Number(validDays) * 86400;
    const dailyCapWei = parseEther(dailyCap);
    const perTxCapWei = parseEther(perTxCap);

    try {
      // 1. Sign EIP-712 typed data matching the contract's SCOPE_TYPEHASH
      const sig = await signTypedDataAsync({
        domain: {
          name: "BouclierPermissionVault",
          version: "1",
          chainId,
          verifyingContract: contracts.permissionVault,
        },
        types: {
          PermissionScope: [
            { name: "agentId", type: "bytes32" },
            { name: "nonce", type: "uint256" },
            { name: "dailySpendCapUSD", type: "uint256" },
            { name: "perTxSpendCapUSD", type: "uint256" },
            { name: "validFrom", type: "uint48" },
            { name: "validUntil", type: "uint48" },
            { name: "allowAnyProtocol", type: "bool" },
            { name: "allowAnyToken", type: "bool" },
          ],
        },
        primaryType: "PermissionScope",
        message: {
          agentId: finalAgentId,
          nonce: currentNonce,
          dailySpendCapUSD: dailyCapWei,
          perTxSpendCapUSD: perTxCapWei,
          validFrom: validFromTs,
          validUntil: validUntilTs,
          allowAnyProtocol: allowAnyProtocol,
          allowAnyToken: true,
        },
      });

      setSignature(sig);
      setStep(3);

      // 2. Build the full scope struct matching the ABI tuple
      const scopeData = {
        agentId: finalAgentId,
        allowedProtocols: [] as readonly `0x${string}`[],
        allowedSelectors: [] as readonly `0x${string}`[],
        allowedTokens: [] as readonly `0x${string}`[],
        dailySpendCapUSD: dailyCapWei,
        perTxSpendCapUSD: perTxCapWei,
        validFrom: validFromTs,
        validUntil: validUntilTs,
        allowAnyProtocol: allowAnyProtocol,
        allowAnyToken: true,
        revoked: false,
        grantHash: ("0x" + "0".repeat(64)) as `0x${string}`,
        windowStartHour: Number(windowStart),
        windowEndHour: Number(windowEnd),
        windowDaysMask: 127,
        allowedChainId: BigInt(chainId),
      };

      // 3. Submit on-chain with explicit gas to avoid estimation masking reverts
      writeContract({
        address: contracts.permissionVault,
        abi: permissionVaultAbi,
        functionName: "grantPermission",
        args: [finalAgentId, scopeData, sig],
        gas: 500_000n,
      });

    } catch (err: any) {
      console.error("Sign/Grant Error:", err);
      toast.error(err?.shortMessage || err?.message || "Signature rejected");
    }
  };

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
            Authentication required. Connect your enterprise wallet to view and assign new execution limits.
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

  return (
    <div className="w-full h-full min-h-[calc(100vh-80px)] flex flex-col">
      {/* Header */}
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        {/* Architect Graphic */}
        <div className="absolute right-0 top-0 w-1/3 h-full opacity-5 pointer-events-none crosshair grid-pattern"></div>
        <div className="relative z-10">
          <Link href="/dashboard" className="text-[10px] font-mono tracking-widest uppercase text-text-muted hover:text-accent mb-6 inline-flex border-b border-transparent hover:border-accent pb-0.5 transition-colors">
            ← Registry Index
          </Link>
          <h1 className="text-[2.5rem] font-bold tracking-tight text-text leading-none mb-3 mt-4">
             Access Provisions<span className="text-accent">_</span>
          </h1>
          <p className="text-sm font-mono text-text-muted mt-2 tracking-tight">
             CRYPTOGRAPHIC PERMISSION GENERATION PROTOCOL
          </p>
        </div>
      </div>

      {/* Wizard */}
      <div className="p-8 lg:p-12 flex-1 bg-surface flex justify-center">
        <div className="w-full max-w-2xl bento-card-dark bg-[#FAFAFA] border border-border flex flex-col">
           
           <div className="flex w-full border-b border-border font-mono text-[10px] tracking-widest font-bold uppercase">
             <div className={`flex-1 p-4 ${step >= 1 ? "text-accent border-b-2 border-accent bg-accent/5" : "text-text-muted opacity-50"}`}>
               1. Select Agent
             </div>
             <div className={`flex-1 p-4 border-l border-border ${step >= 2 ? "text-accent border-b-2 border-accent bg-accent/5" : "text-text-muted opacity-50"}`}>
               2. Set Limits
             </div>
             <div className={`flex-1 p-4 border-l border-border ${step >= 3 ? "text-accent border-b-2 border-accent bg-accent/5" : "text-text-muted opacity-50"}`}>
               3. Authorize
             </div>
           </div>

           <div className="p-8">
             {step === 1 && (
               <form onSubmit={(e) => { e.preventDefault(); if (agentId.length === 66) setStep(2); }} className="space-y-6">
                 {/* Agent Picker from on-chain registry */}
                 {agentOptions.length > 0 && (
                   <div>
                     <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block">
                       Your Registered Agents
                     </label>
                     <div className="space-y-2">
                       {agentOptions.map((id) => (
                         <button
                           key={id}
                           type="button"
                           onClick={() => setAgentId(id)}
                           className={`w-full text-left px-4 py-3 border font-mono text-xs transition-all rounded-sm flex items-center justify-between group ${
                             agentId === id
                               ? "border-accent bg-accent/5 text-accent"
                               : "border-border bg-body text-text-muted hover:border-text hover:text-text"
                           }`}
                         >
                           <span className="truncate">{fmtShort(id, 14, 8)}</span>
                           {agentId === id && <ShieldCheck size={14} className="text-accent flex-shrink-0 ml-2" />}
                         </button>
                       ))}
                     </div>
                   </div>
                 )}

                 {/* Manual entry fallback */}
                 <div>
                   <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block">
                     {agentOptions.length > 0 ? "Or Paste Agent ID Manually" : "Target Agent Hash ID"}
                   </label>
                   <input
                     type="text"
                     placeholder="0x..."
                     value={agentId}
                     onChange={(e) => setAgentId(e.target.value)}
                     className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                     required
                   />
                   {agentId.length > 0 && agentId.length !== 66 && (
                     <p className="text-[10px] font-mono text-yellow-600 mt-1">Agent ID must be 66 characters (0x + 64 hex digits)</p>
                   )}
                 </div>

                 <Button type="submit" variant="primary" disabled={agentId.length !== 66} className="w-full font-mono uppercase tracking-widest text-[11px] h-12 disabled:opacity-40">
                   Proceed to Limits →
                 </Button>
               </form>
             )}

             {step === 2 && (
               <form onSubmit={handleSignRow} className="space-y-6">
                 <div className="grid grid-cols-2 gap-6">
                   <div>
                     <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-2">
                       <Sliders size={12} /> Daily Spend Limit (USD)
                     </label>
                     <input
                       type="number"
                       value={dailyCap}
                       onChange={(e) => setDailyCap(e.target.value)}
                       className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                       required
                     />
                   </div>
                   <div>
                     <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-2">
                       <Database size={12} /> Per-Transaction Cap (USD)
                     </label>
                     <input
                       type="number"
                       value={perTxCap}
                       onChange={(e) => setPerTxCap(e.target.value)}
                       className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                       required
                     />
                   </div>
                 </div>

                 {/* Validity Period */}
                 <div>
                   <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-2">
                     <Clock size={12} /> Validity Period (Days)
                   </label>
                   <input
                     type="number"
                     min="1"
                     max="3650"
                     value={validDays}
                     onChange={(e) => setValidDays(e.target.value)}
                     className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                     required
                   />
                 </div>

                 {/* Active Window */}
                 <div className="grid grid-cols-2 gap-6">
                   <div>
                     <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-2">
                       <Zap size={12} /> Window Start (UTC Hour)
                     </label>
                     <input
                       type="number"
                       min="0"
                       max="23"
                       value={windowStart}
                       onChange={(e) => setWindowStart(e.target.value)}
                       className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                       required
                     />
                   </div>
                   <div>
                     <label className="text-[11px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block flex items-center gap-2">
                       <Zap size={12} /> Window End (UTC Hour)
                     </label>
                     <input
                       type="number"
                       min="0"
                       max="24"
                       value={windowEnd}
                       onChange={(e) => setWindowEnd(e.target.value)}
                       className="w-full bg-body border border-border px-4 py-3 text-sm font-mono focus:outline-none focus:border-text transition-all rounded-sm"
                       required
                     />
                   </div>
                 </div>

                 <div className="flex items-center gap-3 p-4 border border-border bg-body mt-4 cursor-pointer hover:border-text transition-all"
                      onClick={() => setAllowAnyProtocol(!allowAnyProtocol)}>
                   <div className={`w-4 h-4 border flex items-center justify-center ${allowAnyProtocol ? "bg-accent border-accent" : "border-border"}`}>
                     {allowAnyProtocol && <div className="w-2 h-2 bg-white"></div>}
                   </div>
                   <span className="text-[11px] font-mono uppercase tracking-widest text-text">Allow Universal Smart Contract Interaction (DANGEROUS)</span>
                 </div>

                 <div className="flex gap-4 pt-4">
                   <Button type="button" variant="outline" onClick={() => setStep(1)} className="font-mono uppercase tracking-widest text-[11px] h-12 px-6">
                     ← Back
                   </Button>
                   <Button type="submit" variant="primary" className="flex-1 font-mono uppercase tracking-widest text-[11px] h-12">
                     Generate Policy Signature
                   </Button>
                 </div>
               </form>
             )}

             {step === 3 && (
               <div className="flex flex-col items-center justify-center py-8 text-center space-y-4">
                 {isPending ? (
                   <div className="animate-pulse flex flex-col items-center">
                     <div className="w-12 h-12 border-2 border-accent border-t-transparent rounded-full animate-spin mb-4" />
                     <p className="text-[11px] font-mono uppercase tracking-widest text-text">Awaiting Signature...</p>
                   </div>
                 ) : isConfirming ? (
                   <div className="animate-pulse flex flex-col items-center">
                     <Database className="text-accent mb-4" size={32} />
                     <p className="text-[11px] font-mono uppercase tracking-widest text-accent">Mining On-Chain...</p>
                   </div>
                 ) : isConfirmed ? (
                   <div className="flex flex-col items-center">
                     <ShieldCheck className="text-green-500 mb-4" size={48} />
                     <h3 className="font-bold text-lg">Policy Active</h3>
                     <p className="font-mono text-xs text-text-muted mt-2 truncate w-full max-w-sm">
                       Hash: {hash}
                     </p>
                     <a
                       href={`https://sepolia.basescan.org/tx/${hash}`}
                       target="_blank"
                       rel="noopener noreferrer"
                       className="text-[10px] font-mono text-accent hover:underline mt-1 inline-flex items-center gap-1"
                     >
                       View on Basescan <ExternalLink size={10} />
                     </a>
                     <Link href="/dashboard">
                       <Button variant="outline" className="mt-8 font-mono uppercase tracking-widest text-[11px]">View Dashboard</Button>
                     </Link>
                   </div>
                 ) : writeError ? (
                   <div className="flex flex-col items-center text-red-500">
                     <ShieldAlert size={32} className="mb-4" />
                     <p className="font-bold text-sm">Transaction Failed</p>
                     <p className="text-xs mt-2 font-mono break-words max-w-sm">
                       {(writeError as any)?.cause?.reason
                         || (writeError as any)?.shortMessage
                         || writeError.message}
                     </p>
                     <div className="flex gap-3 mt-6">
                       <Button variant="outline" onClick={() => setStep(1)} className="font-mono uppercase tracking-widest text-[11px]">Start Over</Button>
                       <Button variant="outline" onClick={() => setStep(2)} className="font-mono uppercase tracking-widest text-[11px]">Edit Limits</Button>
                     </div>
                   </div>
                 ) : null}
               </div>
             )}
           </div>
        </div>
      </div>
    </div>
  );
}