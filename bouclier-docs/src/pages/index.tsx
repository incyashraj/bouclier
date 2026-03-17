import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/quickstart">
            Get Started — 10 min ⚡
          </Link>
          &nbsp;&nbsp;
          <Link className="button button--outline button--secondary button--lg" to="/docs/">
            Read the Docs
          </Link>
        </div>
      </div>
    </header>
  );
}

function Features() {
  const features = [
    {
      title: 'Cryptographic Permission Scopes',
      description: 'EIP-712 signed scopes define exactly what your agent can call, spend, and access. Enforced by the ERC-7579 PermissionVault on every action.',
    },
    {
      title: 'Instant Kill Switch',
      description: 'One transaction revokes any agent, instantly. The 24-hour reinstatement timelock prevents re-activation by a compromised account.',
    },
    {
      title: 'Immutable Audit Trail',
      description: 'Every agent action is hashed, timestamped, and anchored on-chain. AuditLogger is append-only by design — proven with Echidna invariant tests.',
    },
    {
      title: 'Chainlink Spend Caps',
      description: 'Real USD-denominated spend limits enforced via Chainlink price feeds. Rolling daily caps hard-stop agents before they drain your wallet.',
    },
    {
      title: 'Framework Adapters',
      description: 'Native integrations for LangChain, ELIZA, and Coinbase AgentKit. Add Bouclier with 2 lines of code in any major AI agent framework.',
    },
    {
      title: 'Open Source',
      description: 'All 5 contracts are source-verified on Basescan. The SDK is MIT-licensed and published on npm and PyPI.',
    },
  ];

  return (
    <section style={{padding: '2rem 0'}}>
      <div className="container">
        <div className="row">
          {features.map(({title, description}) => (
            <div key={title} className={clsx('col col--4')} style={{marginBottom: '1.5rem'}}>
              <div className="card" style={{height: '100%', padding: '1.5rem'}}>
                <h3>{title}</h3>
                <p>{description}</p>
              </div>
            </div>
          ))}
        </div>
        <div style={{textAlign: 'center', marginTop: '2rem'}}>
          <h2>Live on Base Sepolia</h2>
          <p>All 5 contracts deployed and source-verified. 76/76 unit tests + 7/7 fork tests passing.</p>
          <Link className="button button--primary button--lg" to="/docs/contracts/overview">
            View Contract Addresses →
          </Link>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description="The Trust Layer for Autonomous AI Agents on Blockchain — cryptographic permission scopes, instant revocation, immutable audit trails.">
      <HomepageHeader />
      <main>
        <Features />
      </main>
    </Layout>
  );
}

