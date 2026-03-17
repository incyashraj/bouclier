import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Bouclier',
  tagline: 'The Trust Layer for Autonomous AI Agents on Blockchain',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  url: 'https://docs.bouclier.xyz',
  baseUrl: '/',
  organizationName: 'bouclier-protocol',
  projectName: 'bouclier',
  onBrokenLinks: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl: 'https://github.com/bouclier-protocol/bouclier/tree/main/bouclier-docs/',
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl: 'https://github.com/bouclier-protocol/bouclier/tree/main/bouclier-docs/',
          // Useful options to enforce blogging best practices
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/bouclier-social-card.png',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Bouclier',
      logo: {
        alt: 'Bouclier Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'mainSidebar',
          position: 'left',
          label: 'Docs',
        },
        {to: '/blog', label: 'Blog', position: 'left'},
        {
          href: 'https://github.com/bouclier-protocol/bouclier',
          label: 'GitHub',
          position: 'right',
        },
        {
          href: 'https://www.npmjs.com/package/@bouclier/sdk',
          label: 'npm',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Quickstart', to: '/docs/quickstart' },
            { label: 'Contracts', to: '/docs/contracts/overview' },
            { label: 'TypeScript SDK', to: '/docs/sdk/typescript' },
            { label: 'Python SDK', to: '/docs/sdk/python' },
          ],
        },
        {
          title: 'Integrations',
          items: [
            { label: 'LangChain', to: '/docs/integrations/langchain' },
            { label: 'ELIZA', to: '/docs/integrations/eliza' },
            { label: 'AgentKit', to: '/docs/integrations/agentkit' },
          ],
        },
        {
          title: 'Community',
          items: [
            { label: 'GitHub', href: 'https://github.com/bouclier-protocol/bouclier' },
            { label: 'npm', href: 'https://www.npmjs.com/org/bouclier' },
            { label: 'PyPI', href: 'https://pypi.org/project/bouclier-sdk/' },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Bouclier Protocol. Built at NTU Singapore.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
