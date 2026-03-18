"use client";

import { useState } from "react";
import {
  useAccount,
} from "wagmi";
import {
  Users,
  Shield,
  Eye,
  UserPlus,
  Trash2,
  Copy,
  Check,
  Crown,
  X,
  RefreshCw,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { toast } from "sonner";

/* ─── Types ─── */
type Role = "OWNER" | "ADMIN" | "VIEWER";
type MemberStatus = "active" | "pending";

interface TeamMember {
  id: string;
  wallet: string;
  displayName: string | null;
  role: Role;
  status: MemberStatus;
  joinedAt: string | null;
}

/* ─── Helpers ─── */
function fmtShort(hex: string, head = 8, tail = 6): string {
  if (hex.length <= head + tail + 2) return hex;
  return `${hex.slice(0, head)}…${hex.slice(-tail)}`;
}

function CopyBtn({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      onClick={(e) => {
        e.stopPropagation();
        navigator.clipboard.writeText(text);
        toast.success("Copied!", { duration: 1500 });
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      }}
      className="p-1 hover:bg-border/50 rounded-sm transition-colors"
    >
      {copied ? <Check size={11} className="text-green-500" /> : <Copy size={11} className="text-text-muted" />}
    </button>
  );
}

const ROLE_CONFIG: Record<Role, { label: string; color: string; Icon: React.ElementType; description: string }> = {
  OWNER: {
    label: "Owner",
    color: "bg-purple-500/10 text-purple-700 border-purple-500/20",
    Icon: Crown,
    description: "Full access — manage team, billing, and all agents",
  },
  ADMIN: {
    label: "Admin",
    color: "bg-blue-500/10 text-blue-700 border-blue-500/20",
    Icon: Shield,
    description: "Manage agents, grant permissions, view all data",
  },
  VIEWER: {
    label: "Viewer",
    color: "bg-gray-500/10 text-gray-700 border-gray-500/20",
    Icon: Eye,
    description: "Read-only access to agents and audit trails",
  },
};

function RoleBadge({ role }: { role: Role }) {
  const cfg = ROLE_CONFIG[role];
  return (
    <span className={`text-[10px] font-bold tracking-wider px-2 py-0.5 rounded-full border uppercase flex items-center gap-1 ${cfg.color}`}>
      <cfg.Icon size={9} />
      {cfg.label}
    </span>
  );
}

/* ─── Mock data (replace with real API calls in production) ─── */
function useMockTeam(ownerAddress: string | undefined) {
  const [members, setMembers] = useState<TeamMember[]>(() =>
    ownerAddress
      ? [
          {
            id: "1",
            wallet: ownerAddress,
            displayName: "You (Owner)",
            role: "OWNER",
            status: "active",
            joinedAt: new Date().toISOString(),
          },
        ]
      : []
  );

  const addMember = (wallet: string, role: Role) => {
    setMembers((prev) => [
      ...prev,
      {
        id: crypto.randomUUID(),
        wallet,
        displayName: null,
        role,
        status: "pending",
        joinedAt: null,
      },
    ]);
  };

  const removeMember = (id: string) => {
    setMembers((prev) => prev.filter((m) => m.id !== id));
  };

  return { members, addMember, removeMember };
}

/* ─── Member Row ─── */
function MemberRow({
  member,
  isCurrentUser,
  onRemove,
}: {
  member: TeamMember;
  isCurrentUser: boolean;
  onRemove: () => void;
}) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between py-4 border-b border-border last:border-0 gap-3">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-accent/10 border border-accent/20 flex items-center justify-center flex-shrink-0">
          <span className="text-[10px] font-mono font-bold text-accent">
            {member.wallet.slice(2, 4).toUpperCase()}
          </span>
        </div>
        <div>
          <div className="flex items-center gap-2">
            <span className="font-mono text-sm font-semibold text-text">
              {member.displayName ?? fmtShort(member.wallet)}
            </span>
            <CopyBtn text={member.wallet} />
            {member.status === "pending" && (
              <span className="text-[10px] font-mono text-yellow-600 uppercase tracking-widest">
                · Pending
              </span>
            )}
          </div>
          <span className="text-[10px] font-mono text-text-muted">
            {member.joinedAt
              ? `Joined ${new Date(member.joinedAt).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })}`
              : "Invitation sent"}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-3 ml-11 sm:ml-0">
        <RoleBadge role={member.role} />
        {!isCurrentUser && member.role !== "OWNER" && (
          <button
            onClick={onRemove}
            className="p-1.5 text-text-muted hover:text-red-600 hover:bg-red-500/10 rounded-sm transition-colors"
            title="Remove member"
          >
            <Trash2 size={13} />
          </button>
        )}
      </div>
    </div>
  );
}

/* ─── Invite Form ─── */
function InviteForm({ onInvite }: { onInvite: (wallet: string, role: Role) => void }) {
  const [open, setOpen] = useState(false);
  const [wallet, setWallet] = useState("");
  const [role, setRole] = useState<Role>("VIEWER");

  const handleSubmit = () => {
    const addr = wallet.trim();
    if (!addr.match(/^0x[0-9a-fA-F]{40}$/)) {
      toast.error("Invalid wallet address — must be a 0x Ethereum address");
      return;
    }
    onInvite(addr, role);
    toast.success("Invitation sent", { description: `${fmtShort(addr)} will join as ${role}` });
    setWallet("");
    setRole("VIEWER");
    setOpen(false);
  };

  if (!open) {
    return (
      <Button variant="primary" size="sm" onClick={() => setOpen(true)} className="uppercase text-[11px] tracking-widest">
        <UserPlus size={13} className="mr-1.5" /> Invite Member
      </Button>
    );
  }

  return (
    <div className="border border-accent/20 bg-white rounded-sm p-5 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <UserPlus size={14} className="text-accent" />
          <span className="text-[11px] font-mono uppercase tracking-widest font-bold">Invite Team Member</span>
        </div>
        <button onClick={() => setOpen(false)} className="p-1 hover:bg-surface rounded-sm">
          <X size={14} className="text-text-muted" />
        </button>
      </div>

      <div className="space-y-4">
        <div>
          <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-1.5 block">
            Wallet Address *
          </label>
          <input
            type="text"
            value={wallet}
            onChange={(e) => setWallet(e.target.value)}
            placeholder="0x…"
            className="w-full bg-white border border-border px-3 py-2 text-sm font-mono focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/20 rounded-sm"
          />
        </div>

        <div>
          <label className="text-[10px] font-mono font-bold tracking-wider uppercase text-text-muted mb-2 block">
            Role
          </label>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
            {(["VIEWER", "ADMIN", "OWNER"] as Role[]).map((r) => {
              const cfg = ROLE_CONFIG[r];
              return (
                <button
                  key={r}
                  onClick={() => setRole(r)}
                  className={`p-3 border rounded-sm text-left transition-all ${
                    role === r
                      ? "border-accent ring-1 ring-accent/20 bg-accent/5"
                      : "border-border hover:border-text/20"
                  }`}
                >
                  <div className="flex items-center gap-1.5 mb-1">
                    <cfg.Icon size={12} className={role === r ? "text-accent" : "text-text-muted"} />
                    <span className="text-[11px] font-mono font-bold uppercase tracking-widest">{cfg.label}</span>
                  </div>
                  <p className="text-[10px] text-text-muted leading-tight">{cfg.description}</p>
                </button>
              );
            })}
          </div>
        </div>

        <Button
          variant="primary"
          onClick={handleSubmit}
          disabled={!wallet}
          className="w-full uppercase text-[11px] tracking-widest h-10"
        >
          Send Invitation
        </Button>
      </div>
    </div>
  );
}

/* ─── Page ─── */
export default function TeamPage() {
  const { address, isConnected } = useAccount();
  const { members, addMember, removeMember } = useMockTeam(address);

  if (!isConnected) {
    return (
      <div className="w-full min-h-[70vh] flex flex-col items-center justify-center p-8 text-center">
        <div className="bento-card-dark p-10 max-w-sm w-full flex flex-col items-center shadow-xl">
          <Users size={32} className="text-accent mb-6" />
          <h2 className="text-2xl font-bold tracking-tight mb-3">Team Access Locked</h2>
          <p className="text-sm text-text-muted mb-8">Connect your wallet to manage team members.</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  const activeCount = members.filter((m) => m.status === "active").length;
  const pendingCount = members.filter((m) => m.status === "pending").length;

  return (
    <div className="w-full min-h-[calc(100vh-80px)] flex flex-col">
      {/* Header */}
      <div className="border-b border-border bg-[#FAFAFA] p-8 lg:p-12">
        <h1 className="text-[2.5rem] font-bold tracking-tight text-text leading-none mb-3">
          Team Management<span className="text-accent">_</span>
        </h1>
        <p className="text-sm font-mono text-text-muted">
          {activeCount} active member{activeCount !== 1 ? "s" : ""}
          {pendingCount > 0 && `, ${pendingCount} pending`}
        </p>
      </div>

      <div className="p-8 lg:p-12 flex-1 bg-surface space-y-6">
        {/* Role legend */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {(Object.entries(ROLE_CONFIG) as [Role, typeof ROLE_CONFIG[Role]][]).map(([role, cfg]) => (
            <div key={role} className="p-4 border border-border bg-[#FAFAFA] rounded-sm">
              <div className="flex items-center gap-2 mb-1">
                <cfg.Icon size={13} className="text-text-muted" />
                <span className="font-mono font-bold text-xs uppercase tracking-widest">{cfg.label}</span>
              </div>
              <p className="text-[11px] text-text-muted">{cfg.description}</p>
            </div>
          ))}
        </div>

        {/* Member list */}
        <div className="border border-border bg-white rounded-sm">
          <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-[#FAFAFA]">
            <div className="flex items-center gap-2">
              <Users size={14} className="text-accent" />
              <span className="text-[11px] font-mono uppercase tracking-widest font-bold">Members</span>
            </div>
          </div>
          <div className="px-5">
            {members.length === 0 ? (
              <div className="py-12 text-center text-text-muted text-sm font-mono">
                No members yet. Invite someone below.
              </div>
            ) : (
              members.map((m) => (
                <MemberRow
                  key={m.id}
                  member={m}
                  isCurrentUser={m.wallet.toLowerCase() === address?.toLowerCase()}
                  onRemove={() => {
                    removeMember(m.id);
                    toast.success("Member removed");
                  }}
                />
              ))
            )}
          </div>
        </div>

        {/* Invite section */}
        <InviteForm
          onInvite={(wallet, role) => addMember(wallet, role)}
        />

        {/* Note */}
        <p className="text-[11px] font-mono text-text-muted">
          Invitations are recorded on-chain via the platform contract. Members must connect the invited wallet to accept. Role changes take effect immediately.
        </p>
      </div>
    </div>
  );
}
