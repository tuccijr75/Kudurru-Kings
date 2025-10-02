import { PlayerZone } from "../PlayerZone";
import type { Player } from "@shared/schema";

export default function PlayerZoneExample() {
  const samplePlayer: Player = {
    id: "p1",
    name: "P1 Lapis",
    position: "top",
    hand: [],
    battlefield: [
      {
        id: "c1",
        name: "Fire Knight",
        type: "Character",
        world: "Mars",
        rarity: "high",
        power: 6,
        armor: 3,
        costSinew: 3,
        costSigil: 0,
        costOath: 1,
        text: "",
        heat: 0,
      },
    ],
    sites: [
      {
        id: "s1",
        name: "Ancient Forge",
        type: "Site",
        world: "Mars",
        rarity: "mid",
        power: 0,
        armor: 0,
        costSinew: 2,
        costSigil: 0,
        costOath: 0,
        text: "",
        heat: 0,
      },
    ],
    capture: [],
    discard: [],
    deck: [],
    resources: { sinew: 3, sigil: 2, oath: 1 },
    marks: 4,
    isActive: true,
  };

  return (
    <div className="p-8">
      <PlayerZone player={samplePlayer} />
    </div>
  );
}
