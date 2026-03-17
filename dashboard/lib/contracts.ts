/**
 * Contract addresses per chain.
 * Populated from deployments/ JSON files after testnet deploy.
 * For now, zero-addresses act as a sentinel so the UI shows a "not deployed" state.
 */
export const CONTRACTS = {
  // Base Sepolia (chain id 84532)
  84532: {
    agentRegistry:      "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb" as `0x${string}`,
    revocationRegistry: "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa" as `0x${string}`,
    spendTracker:       "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1" as `0x${string}`,
    auditLogger:        "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735" as `0x${string}`,
    permissionVault:    "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7" as `0x${string}`,
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
