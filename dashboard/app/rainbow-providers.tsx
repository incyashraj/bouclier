"use client";

import { useState, type ReactNode } from "react";
import { RainbowKitProvider, getDefaultConfig } from "@rainbow-me/rainbowkit";
import "@rainbow-me/rainbowkit/styles.css";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { baseSepolia, base, mainnet } from "viem/chains";
import { http, WagmiProvider } from "wagmi";

function makeConfig() {
  return getDefaultConfig({
    appName: "Bouclier",
    projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "demo",
    chains: [mainnet, base, baseSepolia],
    transports: {
      [mainnet.id]: http(),
      [base.id]: http(),
      [baseSepolia.id]: http(process.env.NEXT_PUBLIC_RPC_URL || undefined),
    },
    ssr: true,
  });
}

export default function RainbowProviders({ children }: { children: ReactNode }) {
  const [config] = useState(() => makeConfig());
  const [queryClient] = useState(() => new QueryClient());

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>{children}</RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
