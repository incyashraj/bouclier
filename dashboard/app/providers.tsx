"use client";

import { useEffect, useState, type ReactNode } from "react";
import dynamic from "next/dynamic";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { baseSepolia, base, mainnet } from "viem/chains";
import { createConfig, http, WagmiProvider } from "wagmi";

// Minimal config with no connectors — safe for SSR (no WalletConnect / indexedDB)
const ssrSafeConfig = createConfig({
  chains: [mainnet, base, baseSepolia],
  transports: {
    [mainnet.id]: http(),
    [base.id]: http(),
    [baseSepolia.id]: http(process.env.NEXT_PUBLIC_RPC_URL || undefined),
  },
  ssr: true,
});

const queryClient = new QueryClient();

// Lazy-load the full RainbowKit + WalletConnect providers client-side only
const RainbowProviders = dynamic(() => import("./rainbow-providers"), {
  ssr: false,
});

export function Providers({ children }: { children: ReactNode }) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  // SSR / first render: use minimal config so wagmi hooks work (return disconnected)
  if (!mounted) {
    return (
      <WagmiProvider config={ssrSafeConfig}>
        <QueryClientProvider client={queryClient}>
          {children}
        </QueryClientProvider>
      </WagmiProvider>
    );
  }

  // Client: full RainbowKit + WalletConnect
  return (
    <RainbowProviders>{children}</RainbowProviders>
  );
}
