import type { Metadata } from "next";
import { Providers } from "./providers";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import { Toaster } from "sonner";
import "./globals.css";

export const metadata: Metadata = {
  title: "Bouclier — The Trust Layer for AI Agents",
  description: "On-chain permission management and audit trail for autonomous AI agents. Open-source protocol built on Base L2.",
  metadataBase: new URL("https://bouclier.eth.limo"),
  icons: {
    icon: "/favicon.svg",
    apple: "/favicon.svg",
  },
  openGraph: {
    title: "Bouclier — The Trust Layer for AI Agents",
    description: "On-chain permission management and audit trail for autonomous AI agents. Open-source protocol built on Base L2.",
    url: "https://bouclier.eth.limo",
    siteName: "Bouclier Protocol",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Bouclier — The Trust Layer for AI Agents",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Bouclier — The Trust Layer for AI Agents",
    description: "On-chain permission management and audit trail for autonomous AI agents. Open-source protocol built on Base L2.",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#FF451A" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "WebApplication",
              name: "Bouclier Protocol",
              url: "https://bouclier.eth.limo",
              description:
                "On-chain permission management and audit trail for autonomous AI agents",
              applicationCategory: "Blockchain",
              operatingSystem: "Web",
              offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
              creator: {
                "@type": "Organization",
                name: "Bouclier Protocol",
                url: "https://github.com/incyashraj/bouclier",
              },
            }),
          }}
        />
      </head>
      <body className={`min-h-screen ${GeistSans.variable} ${GeistMono.variable} font-sans bg-background text-text antialiased selection:bg-accent/20 selection:text-accent pb-20 md:pb-0`}>
        <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-accent focus:text-white focus:rounded-sm focus:text-sm focus:font-semibold">
          Skip to content
        </a>
        <Providers>{children}</Providers>
        <Toaster position="top-right" richColors closeButton />
      </body>
    </html>
  );
}
