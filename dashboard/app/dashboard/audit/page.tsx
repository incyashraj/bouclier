"use client";

import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { ShieldAlert, Database } from "lucide-react";
import { isDeployed } from "@/lib/contracts";

export default function AuditLedgerPage() {
  const { isConnected, chainId } = useAccount();
  const deployed = isConnected && chainId ? isDeployed(chainId) : false;

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
            Authentication required. Connect your enterprise wallet to view the global execution audit ledger.
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
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12 relative overflow-hidden">
        <div className="relative z-10">
          <h1 className="text-[2.5rem] font-bold tracking-tight text-text leading-none mb-3">
            Global Audit Ledger<span className="text-accent">_</span>
          </h1>
          <p className="max-w-xl text-text-muted font-medium text-sm leading-relaxed tracking-wide">
            Immutable log of all AI agent protocol requests, payload hashing, and execution bounds evaluated natively by the AuditLogger primitive.
          </p>
        </div>
      </div>
      
      <div className="flex-1 p-8 lg:p-12">
        <div className="w-full border border-border border-dashed bg-surface/50 p-12 flex flex-col items-center justify-center min-h-[40vh] text-center">
            <Database size={40} className="text-border mb-6" />
            <h3 className="font-mono text-sm uppercase tracking-widest text-text-muted mb-2">Syncing with Subgraph</h3>
            <p className="text-[13px] text-text-muted/60 max-w-md">
              The query engine is currently aggregating historical logs. Real-time ledger view will be available once the initial blockchain scan is complete.
            </p>
        </div>
      </div>
    </div>
  );
}