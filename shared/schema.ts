import { z } from "zod";

export type World = "Mars" | "Earth" | "Moon" | "Nibiru";
export type Rarity = "low" | "mid" | "high" | "rare" | "super";
export type CardType = "Character" | "Enemy" | "Boss" | "Pet" | "Relic" | "Site" | "Rune";
export type Phase = "Upkeep" | "Main" | "Battle" | "End";
export type TestAxis = "Stone" | "Veil" | "Oath";

export interface ResourcePools {
  sinew: number;
  sigil: number;
  oath: number;
}

export interface Card {
  id: string;
  name: string;
  type: CardType;
  world: World;
  rarity: Rarity;
  power: number;
  armor: number;
  costSinew: number;
  costSigil: number;
  costOath: number;
  text: string;
  heat: number;
  attachedPet?: Card;
  attachedRelic?: Card;
}

export interface Player {
  id: string;
  name: string;
  position: "top" | "right" | "bottom" | "left";
  hand: Card[];
  battlefield: Card[];
  sites: Card[];
  capture: Card[];
  discard: Card[];
  deck: Card[];
  resources: ResourcePools;
  marks: number;
  isActive: boolean;
}

export interface GameState {
  players: Player[];
  currentPlayerIndex: number;
  phase: Phase;
  marksToWin: number;
  winner?: string;
}

export const cardSchema = z.object({
  id: z.string(),
  name: z.string(),
  type: z.enum(["Character", "Enemy", "Boss", "Pet", "Relic", "Site", "Rune"]),
  world: z.enum(["Mars", "Earth", "Moon", "Nibiru"]),
  rarity: z.enum(["low", "mid", "high", "rare", "super"]),
  power: z.number(),
  armor: z.number(),
  costSinew: z.number(),
  costSigil: z.number(),
  costOath: z.number(),
  text: z.string(),
  heat: z.number(),
});

export type InsertCard = z.infer<typeof cardSchema>;
