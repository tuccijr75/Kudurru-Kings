import { CombatModal } from "../CombatModal";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import type { Card } from "@shared/schema";

export default function CombatModalExample() {
  const [open, setOpen] = useState(false);

  const attacker: Card = {
    id: "att1",
    name: "Battle Mage",
    type: "Character",
    world: "Moon",
    rarity: "high",
    power: 7,
    armor: 3,
    costSinew: 1,
    costSigil: 3,
    costOath: 1,
    text: "",
    heat: 0,
  };

  const defender: Card = {
    id: "def1",
    name: "Iron Guardian",
    type: "Enemy",
    world: "Mars",
    rarity: "mid",
    power: 5,
    armor: 4,
    costSinew: 3,
    costSigil: 0,
    costOath: 0,
    text: "",
    heat: 0,
  };

  return (
    <div className="p-8">
      <Button onClick={() => setOpen(true)} data-testid="button-open-combat">
        Open Combat Modal
      </Button>
      <CombatModal
        open={open}
        onClose={() => setOpen(false)}
        attacker={attacker}
        defender={defender}
      />
    </div>
  );
}
