/**
 * Contract addresses per chain.
 * Populated from deployments/ JSON files after testnet deploy.
 * For now, zero-addresses act as a sentinel so the UI shows a "not deployed" state.
 */
export const CONTRACTS = {
  // Base Sepolia (chain id 84532)
  84532: {
    agentRegistry:      "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB" as `0x${string}`,
    revocationRegistry: "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270" as `0x${string}`,
    spendTracker:       "0x930Eb18B9962c30b388f900ba9AE62386191cD48" as `0x${string}`,
    auditLogger:        "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE" as `0x${string}`,
    permissionVault:    "0xe0b283A4Dff684E5D700E53900e7B27279f7999F" as `0x${string}`,
  },
  // Base mainnet (chain id 8453) — populated after mainnet deploy
  8453: {
    agentRegistry:      "0x0000000000000000000000000000000000000000" as `0x${string}`,
    revocationRegistry: "0x0000000000000000000000000000000000000000" as `0x${string}`,
    spendTracker:       "0x0000000000000000000000000000000000000000" as `0x${string}`,
    auditLogger:        "0x0000000000000000000000000000000000000000" as `0x${string}`,
    permissionVault:    "0x0000000000000000000000000000000000000000" as `0x${string}`,
  },
} as const;

export type SupportedChainId = keyof typeof CONTRACTS;

export function getContracts(chainId: number) {
  const addrs = CONTRACTS[chainId as SupportedChainId];
  if (!addrs) {
    return {
      agentRegistry: "0x0000000000000000000000000000000000000000" as `0x${string}`,
      revocationRegistry: "0x0000000000000000000000000000000000000000" as `0x${string}`,
      spendTracker: "0x0000000000000000000000000000000000000000" as `0x${string}`,
      auditLogger: "0x0000000000000000000000000000000000000000" as `0x${string}`,
      permissionVault: "0x0000000000000000000000000000000000000000" as `0x${string}`,
    };
  }
  return addrs;
}

export function isDeployed(chainId: number): boolean {
  try {
    const addrs = getContracts(chainId);
    if (!addrs) return false;
    return addrs.agentRegistry !== "0x0000000000000000000000000000000000000000";
  } catch {
    return false;
  }
}
