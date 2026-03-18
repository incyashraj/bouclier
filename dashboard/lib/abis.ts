/**
 * Minimal ABI slices needed by the dashboard.
 * Full ABIs live in packages/sdk/src/abis.ts; these are scoped to what the UI reads.
 */

export const agentRegistryAbi = [
  {
    name: "getAgentsByOwner",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "owner", type: "address" }],
    outputs: [{ name: "", type: "bytes32[]" }],
  },
  {
    name: "resolve",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
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
      },
    ],
  },
  {
    name: "isActive",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    name: "register",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "agentWallet",    type: "address" },
      { name: "model",          type: "string"  },
      { name: "parentAgentId",  type: "bytes32" },
      { name: "metadataCID",    type: "string"  },
    ],
    outputs: [{ name: "agentId", type: "bytes32" }],
  },
  {
    name: "totalAgents",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
] as const;

export const revocationRegistryAbi = [
  {
    name: "isRevoked",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
  },
] as const;

export const permissionVaultAbi = [
  {
    name: "getActiveScope",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "agentId",           type: "bytes32"   },
          { name: "allowedProtocols",  type: "address[]" },
          { name: "allowedSelectors",  type: "bytes4[]"  },
          { name: "allowedTokens",     type: "address[]" },
          { name: "dailySpendCapUSD",  type: "uint256"   },
          { name: "perTxSpendCapUSD",  type: "uint256"   },
          { name: "validFrom",         type: "uint48"    },
          { name: "validUntil",        type: "uint48"    },
          { name: "allowAnyProtocol",  type: "bool"      },
          { name: "allowAnyToken",     type: "bool"      },
          { name: "revoked",           type: "bool"      },
          { name: "grantHash",         type: "bytes32"   },
          { name: "windowStartHour",   type: "uint8"     },
          { name: "windowEndHour",     type: "uint8"     },
          { name: "windowDaysMask",    type: "uint8"     },
          { name: "allowedChainId",    type: "uint64"    },
        ],
      },
    ],
  },
  {
    name: "grantNonces",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "grantPermission",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "agentId",        type: "bytes32" },
      {
        name: "scope",
        type: "tuple",
        components: [
          { name: "agentId",           type: "bytes32"   },
          { name: "allowedProtocols",  type: "address[]" },
          { name: "allowedSelectors",  type: "bytes4[]"  },
          { name: "allowedTokens",     type: "address[]" },
          { name: "dailySpendCapUSD",  type: "uint256"   },
          { name: "perTxSpendCapUSD",  type: "uint256"   },
          { name: "validFrom",         type: "uint48"    },
          { name: "validUntil",        type: "uint48"    },
          { name: "allowAnyProtocol",  type: "bool"      },
          { name: "allowAnyToken",     type: "bool"      },
          { name: "revoked",           type: "bool"      },
          { name: "grantHash",         type: "bytes32"   },
          { name: "windowStartHour",   type: "uint8"     },
          { name: "windowEndHour",     type: "uint8"     },
          { name: "windowDaysMask",    type: "uint8"     },
          { name: "allowedChainId",    type: "uint64"    },
        ],
      },
      { name: "ownerSignature", type: "bytes" },
    ],
    outputs: [],
  },
  {
    name: "revokePermission",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [],
  },
  {
    name: "emergencyRevoke",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [],
  },
  {
    name: "SCOPE_TYPEHASH",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }],
  },
  {
    name: "DOMAIN_SEPARATOR",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }],
  },
] as const;

export const spendTrackerAbi = [
  {
    name: "getRollingSpend",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "agentId",       type: "bytes32" },
      { name: "windowSeconds", type: "uint256" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
] as const;

export const auditLoggerAbi = [
  {
    name: "getTotalEvents",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "agentId", type: "bytes32" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "getAgentHistory",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "agentId", type: "bytes32" },
      { name: "offset",  type: "uint256" },
      { name: "limit",   type: "uint256" },
    ],
    outputs: [{ name: "", type: "bytes32[]" }],
  },
  {
    name: "getAuditRecord",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "eventId", type: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "eventId",      type: "bytes32" },
          { name: "agentId",      type: "bytes32" },
          { name: "actionHash",   type: "bytes32" },
          { name: "target",       type: "address" },
          { name: "selector",     type: "bytes4"  },
          { name: "tokenAddress", type: "address" },
          { name: "usdAmount",    type: "uint256" },
          { name: "timestamp",    type: "uint48"  },
          { name: "allowed",      type: "bool"    },
          { name: "violationType",type: "string"  },
          { name: "ipfsCID",      type: "string"  },
        ],
      },
    ],
  },
] as const;
