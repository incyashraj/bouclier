export const dynamicParams = false;

export function generateStaticParams() {
  return [{ agentId: "1" }];
}

import ClientPage from "./ClientPage";

export default function AgentPage() {
  return <ClientPage />;
}
