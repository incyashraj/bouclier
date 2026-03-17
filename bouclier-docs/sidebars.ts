import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  mainSidebar: [
    'intro',
    'quickstart',
    {
      type: 'category',
      label: 'Smart Contracts',
      items: [
        'contracts/overview',
        'contracts/agent-registry',
        'contracts/permission-vault',
        'contracts/spend-tracker',
        'contracts/audit-logger',
        'contracts/revocation-registry',
      ],
    },
    {
      type: 'category',
      label: 'SDKs',
      items: [
        'sdk/typescript',
        'sdk/python',
      ],
    },
    {
      type: 'category',
      label: 'Integrations',
      items: [
        'integrations/langchain',
        'integrations/eliza',
        'integrations/agentkit',
      ],
    },
    'faq',
  ],
};

export default sidebars;
