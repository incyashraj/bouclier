/**
 * Bouclier SDK — Contract ABIs (minimal, focused on the SDK's core operations)
 */

// ── AgentRegistry ─────────────────────────────────────────────────

export const agentRegistryAbi = [
  {
    type: "function", name: "register",
    inputs: [
      { name: "agentWallet",    type: "address" },
      { name: "model",          type: "string"  },
      { name: "parentAgentId",  type: "bytes32" },
      { name: "metadataCID",    type: "string"  },
    ],
    outputs: [{ name: "agentId", type: "bytes32" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function", name: "resolve",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [{
      name: "", type: "tuple",
      components: [
        { name: "agentAddress",  type: "address" },
        { name: "owner",         type: "address" },
        { name: "status",        type: "uint8"   },
        { name: "registeredAt",  type: "uint48"  },
        { name: "agentId",       type: "bytes32" },
        { name: "did",           type: "string"  },
        { name: "model",         type: "string"  },
        { name: "parentAgentId", type: "bytes32" },
        { name: "metadataCID",   type: "string"  },
      ],
    }],
    stateMutability: "view",
  },
  {
    type: "function", name: "getAgentId",
    inputs:  [{ name: "agentWallet", type: "address" }],
    outputs: [{ name: "", type: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function", name: "getAgentsByOwner",
    inputs:  [{ name: "owner", type: "address" }],
    outputs: [{ name: "", type: "bytes32[]" }],
    stateMutability: "view",
  },
  {
    type: "function", name: "isActive",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
  },
  {
    type: "event", name: "AgentRegistered",
    inputs: [
      { name: "agentId",      type: "bytes32", indexed: true  },
      { name: "agentAddress", type: "address", indexed: true  },
      { name: "owner",        type: "address", indexed: true  },
      { name: "did",          type: "string",  indexed: false },
      { name: "registeredAt", type: "uint48",  indexed: false },
    ],
  },
] as const;

// ── PermissionVault ───────────────────────────────────────────────

export const permissionVaultAbi = [
  {
    type: "function", name: "grantPermission",
    inputs: [
      { name: "agentId",        type: "bytes32" },
      {
        name: "scope", type: "tuple",
        components: [
          { name: "agentId",          type: "bytes32"   },
          { name: "allowedProtocols", type: "address[]" },
          { name: "allowedSelectors", type: "bytes4[]"  },
          { name: "allowedTokens",    type: "address[]" },
          { name: "dailySpendCapUSD", type: "uint256"   },
          { name: "perTxSpendCapUSD", type: "uint256"   },
          { name: "validFrom",        type: "uint48"    },
          { name: "validUntil",       type: "uint48"    },
          { name: "allowAnyProtocol", type: "bool"      },
          { name: "allowAnyToken",    type: "bool"      },
          { name: "revoked",          type: "bool"      },
          { name: "grantHash",        type: "bytes32"   },
          { name: "windowStartHour",  type: "uint8"     },
          { name: "windowEndHour",    type: "uint8"     },
          { name: "windowDaysMask",   type: "uint8"     },
          { name: "allowedChainId",   type: "uint64"    },
        ],
      },
      { name: "ownerSignature", type: "bytes" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function", name: "revokePermission",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function", name: "getActiveScope",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [{
      name: "", type: "tuple",
      components: [
        { name: "agentId",          type: "bytes32"   },
        { name: "allowedProtocols", type: "address[]" },
        { name: "allowedSelectors", type: "bytes4[]"  },
        { name: "allowedTokens",    type: "address[]" },
        { name: "dailySpendCapUSD", type: "uint256"   },
        { name: "perTxSpendCapUSD", type: "uint256"   },
        { name: "validFrom",        type: "uint48"    },
        { name: "validUntil",       type: "uint48"    },
        { name: "allowAnyProtocol", type: "bool"      },
        { name: "allowAnyToken",    type: "bool"      },
        { name: "revoked",          type: "bool"      },
        { name: "grantHash",        type: "bytes32"   },
        { name: "windowStartHour",  type: "uint8"     },
        { name: "windowEndHour",    type: "uint8"     },
        { name: "windowDaysMask",   type: "uint8"     },
        { name: "allowedChainId",   type: "uint64"    },
      ],
    }],
    stateMutability: "view",
  },
  {
    type: "function", name: "grantNonces",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function", name: "DOMAIN_SEPARATOR",
    inputs:  [],
    outputs: [{ name: "", type: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function", name: "SCOPE_TYPEHASH",
    inputs:  [],
    outputs: [{ name: "", type: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "event", name: "PermissionGranted",
    inputs: [
      { name: "agentId",   type: "bytes32", indexed: true  },
      { name: "grantHash", type: "bytes32", indexed: true  },
      { name: "validUntil",type: "uint48",  indexed: false },
    ],
  },
  {
    type: "event", name: "PermissionViolation",
    inputs: [
      { name: "agentId",       type: "bytes32", indexed: true  },
      { name: "target",        type: "address", indexed: true  },
      { name: "selector",      type: "bytes4",  indexed: false },
      { name: "violationType", type: "string",  indexed: false },
    ],
  },
] as const;

// ── RevocationRegistry ────────────────────────────────────────────

export const revocationRegistryAbi = [
  {
    type: "function", name: "isRevoked",
    inputs:  [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function", name: "revoke",
    inputs: [
      { name: "agentId", type: "bytes32" },
      { name: "reason",  type: "uint8"   },
      { name: "notes",   type: "string"  },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event", name: "AgentRevoked",
    inputs: [
      { name: "agentId",   type: "bytes32", indexed: true  },
      { name: "revokedBy", type: "address", indexed: true  },
      { name: "reason",    type: "uint8",   indexed: false },
      { name: "revokedAt", type: "uint48",  indexed: false },
    ],
  },
] as const;

// ── AuditLogger ─────────────────────────────────────────────────

export const auditLoggerAbi = [
  {
    type: "function", name: "getAuditRecord",
    inputs:  [{ name: "eventId", type: "bytes32" }],
    outputs: [{
      name: "", type: "tuple",
      components: [
        { name: "eventId",       type: "bytes32" },
        { name: "agentId",       type: "bytes32" },
        { name: "actionHash",    type: "bytes32" },
        { name: "target",        type: "address" },
        { name: "selector",      type: "bytes4"  },
        { name: "tokenAddress",  type: "address" },
        { name: "usdAmount",     type: "uint256" },
        { name: "timestamp",     type: "uint48"  },
        { name: "allowed",       type: "bool"    },
        { name: "violationType", type: "string"  },
        { name: "ipfsCID",       type: "string"  },
      ],
    }],
    stateMutability: "view",
  },
  {
    type: "function", name: "getAgentHistory",
    inputs: [
      { name: "agentId", type: "bytes32" },
      { name: "offset",  type: "uint256" },
      { name: "limit",   type: "uint256" },
    ],
    outputs: [{ name: "eventIds", type: "bytes32[]" }],
    stateMutability: "view",
  },
  {
    type: "event", name: "ActionLogged",
    inputs: [
      { name: "eventId",    type: "bytes32", indexed: true  },
      { name: "agentId",    type: "bytes32", indexed: true  },
      { name: "actionHash", type: "bytes32", indexed: false },
      { name: "target",     type: "address", indexed: false },
      { name: "allowed",    type: "bool",    indexed: false },
    ],
  },
] as const;
