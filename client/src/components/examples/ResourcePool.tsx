import { ResourcePool } from "../ResourcePool";
import { useState } from "react";

export default function ResourcePoolExample() {
  const [sinew, setSinew] = useState(3);
  const [sigil, setSigil] = useState(2);
  const [oath, setOath] = useState(1);

  return (
    <div className="p-8 space-y-4">
      <ResourcePool type="sinew" value={sinew} onChange={setSinew} />
      <ResourcePool type="sigil" value={sigil} onChange={setSigil} />
      <ResourcePool type="oath" value={oath} onChange={setOath} />
    </div>
  );
}
