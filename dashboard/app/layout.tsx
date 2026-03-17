import type { Metadata } from "next";
import { Providers } from "./providers";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./globals.css";

export const metadata: Metadata = {
  title: "Bouclier — The Trust Layer for AI Agents",
  description: "On-chain permission management and audit trail for AI agents",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`min-h-screen ${GeistSans.variable} ${GeistMono.variable} font-sans bg-background text-text antialiased selection:bg-accent/20 selection:text-accent pb-20 md:pb-0`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
