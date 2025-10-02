import { GameCard } from "../GameCard";
import type { Card } from "@shared/schema";

export default function GameCardExample() {
  const sampleCard: Card = {
    id: "card-1",
    name: "Ember Warrior",
    type: "Character",
    world: "Mars",
    rarity: "mid",
    power: 5,
    armor: 2,
    costSinew: 2,
    costSigil: 0,
    costOath: 1,
    text: "When this character attacks, deal 1 damage to all enemies.",
    heat: 1,
  };

  return (
    <div className="p-8 flex gap-4">
      <GameCard card={sampleCard} size="small" />
      <GameCard card={sampleCard} size="normal" />
      <GameCard card={{ ...sampleCard, heat: 0 }} size="large" />
    </div>
  );
}
