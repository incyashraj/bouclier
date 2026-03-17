# Bouclier Dashboard — Frontend Redesign Guidelines for Gemini

> **Purpose:** This document provides everything a Gemini model (or any AI assistant) needs to understand the existing Bouclier dashboard, the protocol it connects to, and the design vision for a complete frontend rebuild with elite-tier blockchain aesthetics, animations, and modern UX.

---

## Table of Contents

1. [Project Context](#1-project-context)
2. [Existing Codebase Inventory](#2-existing-codebase-inventory)
3. [Smart Contract Interface (What the Frontend Reads/Writes)](#3-smart-contract-interface)
4. [Design Vision & Requirements](#4-design-vision--requirements)
5. [Recommended Tech Stack](#5-recommended-tech-stack)
6. [Page-by-Page Requirements](#6-page-by-page-requirements)
7. [Component Architecture](#7-component-architecture)
8. [Blockchain Integration Details](#8-blockchain-integration-details)
9. [Deployment & Hosting](#9-deployment--hosting)
10. [Files to Preserve (Do Not Rewrite)](#10-files-to-preserve)
11. [Reference Designs & Inspiration](#11-reference-designs--inspiration)

---

## 1. Project Context

**Bouclier** (French for "shield") is an on-chain trust layer for AI agents. It enforces permission scopes, spend caps, and revocation controls before any AI agent transaction executes on the blockchain.

**What this dashboard does:**
- Connects to a user's wallet (Base Sepolia / Base mainnet)
- Shows all AI agents registered under that wallet
- Displays each agent's permission scope (allowed protocols, spend caps, time validity)
- Shows real-time audit trail (approved + blocked transactions)
- Allows granting new permissions (EIP-712 signature flow)
- Allows revoking agent permissions (on-chain transaction)
- Shows rolling 24h USD spend for each agent

**Target users:**
- Enterprise compliance officers monitoring AI agent activity
- Developers managing their AI agents' permissions
- Security teams reviewing audit trails

**The brand:**
- Name: Bouclier
- Tagline: "The Trust Layer for AI Agents"
- Primary chain: Base (Coinbase L2)
- Aesthetic: Elite blockchain infrastructure — think Etherscan meets Linear meets Dune Analytics

---

## 2. Existing Codebase Inventory

### Directory Structure
```
dashboard/
├── app/
│   ├── globals.css                 ← Just @tailwind directives
│   ├── layout.tsx                  ← Root layout (html + body + Providers)
│   ├── page.tsx                    ← Redirects to /dashboard
│   ├── providers.tsx               ← Wagmi + RainbowKit + ReactQuery providers
│   └── dashboard/
│       ├── layout.tsx              ← Sidebar/nav shell with ConnectButton
│       ├── page.tsx                ← Agent list (reads AgentRegistry + RevocationRegistry)
│       ├── grant/
│       │   └── page.tsx            ← EIP-712 grant permission form
│       └── [agentId]/
│           └── page.tsx            ← Agent detail (scope, spend, audit feed, revoke button)
├── components/                     ← EMPTY — needs to be built out
├── lib/
│   ├── abis.ts                     ← ABI slices for all 5 contracts
│   └── contracts.ts                ← Contract addresses per chain + helpers
├── package.json
├── tailwind.config.ts
├── next.config.ts
├── tsconfig.json
└── .env.local
```

### Current Tech Stack
| Technology | Version | Purpose |
|---|---|---|
| Next.js | 16.1.6 | React framework (App Router) |
| React | 19.0.0 | UI library |
| wagmi | 2.14.6 | Ethereum hooks |
| viem | 2.23.0 | Ethereum client |
| RainbowKit | 2.2.4 | Wallet connection modal |
| TanStack Query | 5.62.0 | Data fetching/caching |
| Tailwind CSS | 3.4.17 | Utility CSS |
| TypeScript | 5.x | Type safety |
| Bun | 1.3.10 | Package manager |

### Current Styling (Minimal)
- Dark theme: `bg-gray-950 text-gray-100`
- Brand colors: `brand-500: #6366f1`, `brand-600: #4f46e5`, `brand-700: #4338ca` (indigo)
- No animations, no gradients, no glassmorphism, no particle effects
- Plain Tailwind utility classes only
- No component library (no shadcn, no Radix)
- Empty `components/` folder — all UI is inline in page files

### What's Working (Preserve the Logic)
- Wallet connection via RainbowKit ✅
- Reading agent list from AgentRegistry contract ✅
- Reading revocation status from RevocationRegistry ✅
- Reading permission scope from PermissionVault ✅
- Reading rolling spend from SpendTracker ✅
- Reading audit trail from AuditLogger ✅
- EIP-712 signature flow for granting permissions ✅
- On-chain revoke transaction ✅
- Chain detection (Base Sepolia / Base mainnet) ✅

---

## 3. Smart Contract Interface

### Contract Addresses (Base Sepolia — Chain ID 84532)

```typescript
const contracts = {
  agentRegistry:      "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
  revocationRegistry: "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
  permissionVault:    "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
  spendTracker:       "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1",
  auditLogger:        "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735",
};
```

### Key Contract Reads (What the Dashboard Fetches)

| Function | Contract | Returns | Used On |
|---|---|---|---|
| `getAgentsByOwner(address)` | AgentRegistry | `bytes32[]` (agent IDs) | Dashboard main page |
| `resolve(bytes32 agentId)` | AgentRegistry | `AgentRecord` struct (did, model, status, owner, wallet) | Agent list + detail |
| `isRevoked(bytes32 agentId)` | RevocationRegistry | `bool` | Agent list + detail |
| `getActiveScope(bytes32 agentId)` | PermissionVault | `PermissionScope` struct | Agent detail |
| `getRollingSpend(bytes32 agentId, uint256 windowSeconds)` | SpendTracker | `uint256` (USD ×10^18) | Agent detail |
| `getTotalEvents(bytes32 agentId)` | AuditLogger | `uint256` | Agent detail |
| `getAgentHistory(bytes32 agentId, uint256 offset, uint256 limit)` | AuditLogger | `bytes32[]` (event IDs) | Agent detail |
| `getAuditRecord(bytes32 eventId)` | AuditLogger | `AuditRecord` struct | Audit feed rows |
| `grantNonces(bytes32 agentId)` | PermissionVault | `uint256` | Grant form (replay protection) |
| `DOMAIN_SEPARATOR()` | PermissionVault | `bytes32` | Grant form (EIP-712) |

### Key Contract Writes (What the Dashboard Sends)

| Function | Contract | Purpose |
|---|---|---|
| `grantPermission(bytes32, PermissionScope, bytes signature)` | PermissionVault | Grant scoped permission to agent |
| `revokePermission(bytes32 agentId)` | PermissionVault | Revoke agent's active scope |

### The Graph Subgraph (Optional — for historical data)

Endpoint: `https://api.studio.thegraph.com/query/1744498/bouclier-base-sepolia/v0.0.1`

Entities: `Agent`, `PermissionGrant`, `RevocationEvent`, `AuditEvent`, `PermissionViolation`, `SpendRecord`, `AgentDailySpend`

Can be used for historical charts, activity timelines, and analytics that don't need real-time on-chain reads.

---

## 4. Design Vision & Requirements

### Aesthetic Pillars

1. **Dark blockchain theme** — Deep dark background (#0a0a0f or similar near-black), NOT plain gray-950
2. **Neon accent glow** — Cyan/electric blue (#00f0ff) and indigo/violet (#6366f1) as primary accents with subtle glow/bloom effects
3. **Glassmorphism** — Frosted glass cards with `backdrop-blur`, subtle borders with gradient opacity
4. **Particle/grid background** — Subtle animated particle network or hex grid in the background (think blockchain node connections)
5. **Smooth micro-animations** — Every interaction should feel alive: hover states, page transitions, number counters, progress bars
6. **Typography** — Modern geometric sans-serif (Inter or Geist) for body, monospace (JetBrains Mono or Fira Code) for addresses/hashes
7. **Data visualization** — Animated charts for spend data, activity heatmaps, real-time status indicators

### Color Palette

| Role | Color | Hex | Usage |
|---|---|---|---|
| Background (primary) | Near-black | `#0a0a0f` | Page background |
| Background (card) | Dark glass | `#12121a` with `backdrop-blur-xl` | Cards, panels |
| Background (elevated) | Slightly lighter | `#1a1a2e` | Hover states, active items |
| Accent primary | Electric cyan | `#00f0ff` | CTAs, active states, glow effects |
| Accent secondary | Indigo/violet | `#6366f1` | Links, secondary buttons |
| Success | Neon green | `#00ff88` | Active status, approved events |
| Danger | Neon red | `#ff3366` | Revoked, blocked, error states |
| Warning | Amber | `#ffaa00` | Paused, expiring states |
| Text primary | White | `#f0f0f5` | Headlines, important text |
| Text secondary | Gray | `#8888a0` | Descriptions, labels |
| Text muted | Dark gray | `#555570` | Timestamps, metadata |
| Border | Subtle glow | `rgba(99, 102, 241, 0.15)` | Card borders |

### Animation Requirements

| Element | Animation | Library Suggestion |
|---|---|---|
| Page transitions | Fade + slide up (200ms) | Framer Motion |
| Card hover | Subtle scale(1.01) + border glow intensify | CSS transitions + Framer |
| Numbers/stats | Count-up animation on mount | Framer Motion `useSpring` |
| Status badges | Subtle pulse on "Active" states | CSS `@keyframes` |
| Background | Floating particle network (low-density) | tsParticles or custom Canvas/Three.js |
| Loading states | Skeleton shimmer (not spinner) | CSS shimmer animation |
| Buttons | Gradient shift on hover | CSS `background-position` transition |
| Charts | Animated draw-in on mount | Recharts or Chart.js with animation |
| Toast notifications | Slide in from right, auto-dismiss | Sonner or react-hot-toast |
| Connect wallet | Smooth modal with backdrop blur | RainbowKit (already there) |
| Audit feed | New items slide in from top (real-time feel) | Framer Motion `AnimatePresence` |
| Revoke button | Red glow intensify on hover, confirmation modal | Framer Motion + dialog |

### Responsive Design

- Desktop-first (primary use case: compliance officers on 1440px+ screens)
- Tablet (1024px): 2-column layouts collapse gracefully
- Mobile (768px): Single column, bottom nav instead of sidebar
- All tables become scrollable cards on mobile

### Accessibility

- All interactive elements keyboard-navigable
- Color contrast meets WCAG AA
- Focus rings visible
- Screen reader labels on icon-only buttons

---

## 5. Recommended Tech Stack

### Keep (Already Working)
- **Next.js 16** (App Router) — keep
- **React 19** — keep
- **wagmi 2 + viem 2** — keep (this is the blockchain integration layer)
- **RainbowKit 2** — keep (wallet connection)
- **TanStack Query 5** — keep (data caching)
- **TypeScript 5** — keep

### Add for UI/UX
| Package | Purpose | Why |
|---|---|---|
| **Framer Motion** | Animations, page transitions, layout animations | Industry standard for React animation |
| **shadcn/ui** | Pre-built accessible components (Dialog, Dropdown, Toast, etc.) | Built on Radix primitives, fully customizable, works with Tailwind |
| **Recharts** or **Tremor** | Spend charts, activity graphs | React-native charting with Tailwind integration |
| **Sonner** | Toast notifications | Beautiful, minimal toast library |
| **tsParticles** or **@react-three/fiber** | Animated background effects | Particle network or 3D blockchain visualization |
| **tailwindcss-animate** | Tailwind animation utilities | Extends Tailwind with animate-in/out classes |
| **@fontsource/inter** + **@fontsource/jetbrains-mono** | Typography | Self-hosted fonts (no Google Fonts latency) |
| **clsx** + **tailwind-merge** | Conditional class merging | Clean className composition |
| **lucide-react** | Icons | Consistent, tree-shakeable icon set |

### Tailwind Config Upgrade
Upgrade from Tailwind 3 to **Tailwind 4** (if stable) or enhance v3 with:
- Custom color palette (the neon blockchain theme above)
- Extended animations and keyframes
- Custom backdrop-blur values
- Glow/shadow utilities

---

## 6. Page-by-Page Requirements

### 6.1 Landing Page (`/`)

**Current:** Instant redirect to `/dashboard`

**New design:** A proper landing/hero page before wallet connection:

- **Hero section:** Large headline "The Trust Layer for AI Agents" with particle background
- **Feature grid:** 4 cards (Identity, Scope, Spend Caps, Kill Switch) with icon + description + glow hover
- **Stats section:** Animated counters (agents registered, transactions monitored, protocols supported)
- **CTA:** "Connect Wallet" button (prominent, glowing) → redirects to `/dashboard` after connect
- **Footer:** Links to docs, GitHub, social

### 6.2 Dashboard — Agent List (`/dashboard`)

**Current:** Simple list of agent rows with basic status badges

**New design:**

- **Top bar:** Network indicator (Base Sepolia/Mainnet) + connected wallet address + disconnect
- **Stats overview:** 4 glassmorphism cards at top:
  - Total Agents (with count-up animation)
  - Active / Revoked ratio (mini donut chart)
  - Total 24h Spend (USD, animated counter)
  - Recent Violations (count + color indicator)
- **Agent cards:** Replace flat list with grid of glassmorphism cards:
  - Agent ID (monospace, truncated)
  - DID string
  - Status badge (Active=green glow, Revoked=red glow, Paused=amber pulse)
  - 24h spend mini sparkline
  - Last activity timestamp
  - Click → agent detail
- **Sidebar navigation:** (persistent)
  - Dashboard (home)
  - Agents
  - Grant Permission
  - Audit Trail (new global page)
  - Settings (future)
- **Empty state:** Animated illustration + "Register your first agent" CTA
- **Real-time indicator:** Subtle pulsing dot showing "Connected to Base Sepolia"

### 6.3 Agent Detail (`/dashboard/[agentId]`)

**Current:** Basic info + scope fields + audit rows

**New design:**

- **Agent header:** Large card with:
  - Agent ID (full, copyable with click animation)
  - DID beneath
  - Status badge (large, glowing)
  - Revoke button (red, with confirmation modal + warning text)
- **Tab navigation:** Tabs for Overview | Scope | Activity | Analytics
- **Overview tab:**
  - 3 stat cards: Rolling 24h Spend (with circular progress toward cap), Total Events, Days Active
  - Activity timeline (last 10 events, vertical timeline with dots)
- **Scope tab:**
  - All permission scope fields rendered in a clean 2-column grid
  - Allowed protocols shown as address pills with copy buttons
  - Time validity shown as a visual timeline bar (green = active period)
  - Cap values formatted as USD with progress bars showing usage
- **Activity tab:**
  - Full audit feed table with:
    - Timestamp
    - Action (selector, formatted as function name if possible)
    - Target contract (address pill)
    - USD amount
    - Status: ✅ Approved / ❌ Blocked (with reason)
  - Filter by: All | Approved | Blocked
  - Pagination
- **Analytics tab:** (new — uses subgraph data)
  - Spend over time chart (line chart, last 7/30 days)
  - Actions per day bar chart
  - Violation rate metric

### 6.4 Grant Permission (`/dashboard/grant`)

**Current:** Basic form with text inputs and toggles

**New design:**

- **Multi-step wizard** (not a single form):
  - Step 1: Select agent (dropdown of user's agents, or paste agent ID)
  - Step 2: Set spend limits (slider + number input for daily cap, per-tx cap)
  - Step 3: Set scope (protocols, selectors, tokens — with search/add interface)
  - Step 4: Set time validity (calendar picker for start/end date)
  - Step 5: Review & Sign (summary card + "Sign with Wallet" CTA)
- **Progress indicator:** Step dots at top showing current position
- **Each step:** Animated transition (slide left/right)
- **Review step:** Shows a formatted summary card with all parameters, looks like a "permission certificate"
- **After signing:** Success animation (checkmark with particle burst) + link to agent detail

### 6.5 Global Audit Trail (`/dashboard/audit`) — NEW PAGE

- Table of ALL audit events across all agents (fetched from subgraph)
- Columns: Timestamp | Agent ID | Action | Target | USD Amount | Status
- Filters: By agent, by status (approved/blocked), by date range
- Export button (CSV)

### 6.6 Settings Page (`/dashboard/settings`) — NEW PAGE (Placeholder)

- Connected wallet info
- Network switcher
- Theme toggle (future — dark only for now)
- Links to docs, GitHub, support

---

## 7. Component Architecture

### Suggested Component Tree

```
components/
├── layout/
│   ├── Sidebar.tsx              ← Persistent left nav with icons + labels
│   ├── TopBar.tsx               ← Network badge + wallet + notifications
│   ├── PageContainer.tsx        ← Max-width container with padding
│   └── PageTransition.tsx       ← Framer Motion AnimatePresence wrapper
├── ui/
│   ├── GlassCard.tsx            ← Reusable glassmorphism card
│   ├── StatCard.tsx             ← Stat with label, value, icon, optional sparkline
│   ├── StatusBadge.tsx          ← Active/Revoked/Paused with glow
│   ├── AddressPill.tsx          ← Truncated address with copy button
│   ├── AnimatedCounter.tsx      ← Count-up number animation
│   ├── ProgressRing.tsx         ← Circular progress (spend vs cap)
│   ├── Skeleton.tsx             ← Loading shimmer placeholder
│   ├── Button.tsx               ← Primary/secondary/danger variants with glow
│   ├── Modal.tsx                ← Confirmation dialog with backdrop blur
│   └── Toast.tsx                ← Notification wrapper (Sonner)
├── charts/
│   ├── SpendLineChart.tsx       ← 7d/30d spend over time
│   ├── ActivityBarChart.tsx     ← Daily action counts
│   └── DonutChart.tsx           ← Active vs revoked agents
├── agent/
│   ├── AgentCard.tsx            ← Grid card for agent list
│   ├── AgentHeader.tsx          ← Detail page header with status + actions
│   ├── ScopeView.tsx            ← Permission scope display
│   ├── AuditFeed.tsx            ← List of audit events with status icons
│   └── AuditRow.tsx             ← Single audit event row
├── grant/
│   ├── GrantWizard.tsx          ← Multi-step form container
│   ├── StepSelectAgent.tsx
│   ├── StepSpendLimits.tsx
│   ├── StepScope.tsx
│   ├── StepValidity.tsx
│   └── StepReview.tsx
├── effects/
│   ├── ParticleBackground.tsx   ← Animated particle network
│   ├── GlowEffect.tsx          ← Reusable glow/bloom wrapper
│   └── GridBackground.tsx       ← Subtle hex/dot grid overlay
└── web3/
    ├── ConnectButton.tsx        ← Custom-styled RainbowKit trigger
    ├── NetworkBadge.tsx         ← Shows current chain with icon
    └── TxStatus.tsx             ← Transaction pending/confirmed indicator
```

---

## 8. Blockchain Integration Details

### Wallet Connection (KEEP AS-IS)

The wagmi + RainbowKit setup in `app/providers.tsx` works correctly. Keep the same structure:

```tsx
// providers.tsx — DO NOT change the core logic
const wagmiConfig = getDefaultConfig({
  appName: "Bouclier",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "demo",
  chains: [baseSepolia, base],
  ssr: true,
});
```

### Contract ABIs (KEEP AS-IS)

The file `lib/abis.ts` contains minimal ABI slices for all 5 contracts. These are correct and match the deployed contracts. Do not modify.

### Contract Addresses (KEEP AS-IS)

The file `lib/contracts.ts` has per-chain address mapping. Do not modify.

### Key wagmi Hooks Used

```tsx
// Reading contract data
useReadContract({ address, abi, functionName, args })

// Writing to contracts
useWriteContract() → writeContract({ address, abi, functionName, args })

// EIP-712 signing
useSignTypedData() → signTypedDataAsync({ domain, types, primaryType, message })

// Wallet state
useAccount() → { address, chainId, isConnected }
```

### EIP-712 Domain (For Grant Permission)

```typescript
domain: {
  name:              "BouclierPermissionVault",
  version:           "1",
  chainId:           chainId,        // from useAccount()
  verifyingContract: addrs.permissionVault,
}
```

### Data Formatting

- USD values from contracts are `uint256` in 18 decimals. Format: `Number(raw / 10n**18n)` → `$X,XXX.XX`
- Timestamps are Unix seconds. Format: `new Date(ts * 1000)`
- Agent IDs are `bytes32` hex strings. Display truncated: `0x1234abcd…`
- Addresses are `0x{40 hex chars}`. Display truncated: `0x1234…5678`

---

## 9. Deployment & Hosting

### Current: Vercel (to be replaced)

The app is currently deployed on Vercel. The user wants something more reliable / self-controlled.

### Recommended Alternatives

| Option | Pros | Cons | Best For |
|---|---|---|---|
| **Cloudflare Pages** | Free, global CDN, fast, DDoS protection, custom domains | No server-side features (SSR via Workers) | Static/SSG export |
| **AWS Amplify** | Full Next.js SSR support, reliable, scalable | Costs money, more setup | Production apps |
| **Railway** | Simple deploy, Docker support, SSR works | Costs money ($5/mo+) | Full-stack apps |
| **Self-hosted (VPS)** | Full control, Docker compose | Needs maintenance | Maximum control |
| **Coolify** (self-hosted PaaS) | Free, Vercel-like but self-hosted on VPS | Needs a VPS ($5/mo) | Self-hosted with UI |

**Recommendation:** **Cloudflare Pages** for the dashboard (it's a client-side app — SSR isn't critical since all data comes from wagmi/RPC hooks). Free, fast, reliable, and professional.

### Export Strategy

Since the dashboard is entirely client-rendered (all data from wagmi hooks, no server API calls), it can be exported as a static site:

```js
// next.config.ts
const nextConfig = {
  output: 'export', // static HTML export
};
```

This generates a `out/` folder deployable to any static host.

---

## 10. Files to Preserve (Do Not Rewrite)

These files contain working blockchain integration logic. Preserve their core logic even if you restructure:

| File | Why |
|---|---|
| `lib/abis.ts` | Correct ABI slices matching deployed contracts |
| `lib/contracts.ts` | Correct addresses per chain |
| `app/providers.tsx` | Working wagmi + RainbowKit + Query setup |

The **logic** inside the page files (wagmi hooks, contract reads, EIP-712 signing, revoke transaction) must be preserved — but it should be refactored into the new component architecture.

---

## 11. Reference Designs & Inspiration

Look at these for visual inspiration (do NOT copy — use as aesthetic reference):

### Blockchain Dashboard Aesthetics
- **Dune Analytics** — Clean dark theme, great data visualization
- **Etherscan** — Data-dense but readable
- **Zapper.fi** — Modern DeFi dashboard with glassmorphism
- **DeBank** — Portfolio view with clean card design

### General SaaS Design Excellence
- **Linear** — Smooth animations, dark theme, professional
- **Raycast** — Beautiful dark UI with keyboard-first design
- **Vercel Dashboard** — Clean, minimal, great typography
- **Stripe Dashboard** — Data visualization, professional feel

### Specific Effects
- **Particle network background:** See https://particles.js.org for tsParticles demos
- **Glassmorphism:** CSS `backdrop-filter: blur(20px)` with `background: rgba(18, 18, 26, 0.7)` and subtle border gradient
- **Glow effects:** `box-shadow: 0 0 20px rgba(0, 240, 255, 0.15)` on hover
- **Number animations:** Framer Motion `useSpring` with `useMotionValue`

---

## Quick Start for the Gemini Model

1. **Read `lib/abis.ts` and `lib/contracts.ts`** — understand what blockchain data is available
2. **Read `app/providers.tsx`** — understand the web3 provider setup (keep this)
3. **Read all 4 page files** in `app/dashboard/` — understand the current wagmi hook usage and data flow
4. **Install new dependencies:**
   ```bash
   bun add framer-motion lucide-react sonner clsx tailwind-merge recharts @fontsource/inter @fontsource/jetbrains-mono
   bunx --bun shadcn@latest init
   ```
5. **Start with the component library** — build `GlassCard`, `StatusBadge`, `AnimatedCounter`, `Sidebar` first
6. **Then rebuild pages** — extract wagmi logic from existing pages into the new components
7. **Add animations last** — page transitions, particle background, chart animations
8. **Test with wallet** — connect MetaMask to Base Sepolia and verify all contract reads still work

---

*This document is the single source of truth for the frontend rebuild. All blockchain integration logic is tested and working — the redesign is purely visual/UX.*
