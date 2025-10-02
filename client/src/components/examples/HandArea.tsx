import { HandArea } from "../HandArea";
import type { Card } from "@shared/schema";
import { useState } from "react";

export default function HandAreaExample() {
  const [selectedId, setSelectedId] = useState<string>();

  const sampleHand: Card[] = [
    {
      id: "h1",
      name: "Flame Striker",
      type: "Character",
      world: "Mars",
      rarity: "mid",
      power: 4,
      armor: 2,
      costSinew: 2,
      costSigil: 0,
      costOath: 1,
      text: "",
      heat: 0,
    },
    {
      id: "h2",
      name: "Mystic Shield",
      type: "Relic",
      world: "Earth",
      rarity: "low",
      power: 0,
      armor: 0,
      costSinew: 0,
      costSigil: 1,
      costOath: 0,
      text: "Attached character gains +2 armor",
      heat: 0,
    },
    {
      id: "h3",
      name: "Shadow Wolf",
      type: "Pet",
      world: "Moon",
      rarity: "mid",
      power: 0,
      armor: 0,
      costSinew: 1,
      costSigil: 1,
      costOath: 0,
      text: "Grants Agile keyword",
      heat: 0,
    },
  ];

  return (
    <HandArea
      cards={sampleHand}
      selectedCardId={selectedId}
      onCardClick={(card) => setSelectedId(card.id)}
    />
  );
}
