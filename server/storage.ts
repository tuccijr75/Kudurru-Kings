import type { User, InsertUser, Player, Phase, Card } from "@shared/schema";
import { randomUUID } from "crypto";
import { cardImageLoader } from "./card-loader";

export interface IStorage {
  listUsers?(): User[];
  getUser(id: string): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;

  getGameState(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  playCard(cardId?: string): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  endPhase(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  attack(attackerId: string, defenderIds?: string[], direct?: boolean, allocations?: Record<string, number>): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  
  dealCards(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  resetGame(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  addBots(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  joinGame(playerName: string): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };

  pushStack(entry: any): { ok: true; stack: any[] };
  resolveStack(): { ok: true; stack: any[] };
  passPriority(): { ok: true };
}

export class MemStorage implements IStorage {
  private users: Map<string, User>;
  private game: { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  public stack: any[] = [];
  private phaseOrder: Phase[] = ["Upkeep","Main","Battle","End"];

  constructor() {
    this.users = new Map();
    this.game = this.seedGame();
  }

  private seedGame(): { phase: Phase; players: Player[] } {
    return {
      phase: "Main",
      players: [
        { 
          id: "p1", 
          name: "North Gate", 
          position: "top",
          isActive: false, 
          resources: { sinew: 5, sigil: 5, oath: 5 }, 
          marks: 10, 
          hand: [], 
          battlefield: [], 
          sites: [], 
          capture: [], 
          discard: [], 
          deck: [] 
        },
        { 
          id: "p2", 
          name: "East Gate",
          position: "right",
          isActive: false, 
          resources: { sinew: 5, sigil: 5, oath: 5 }, 
          marks: 10, 
          hand: [], 
          battlefield: [], 
          sites: [], 
          capture: [], 
          discard: [], 
          deck: [] 
        },
        { 
          id: "p3", 
          name: "South Gate",
          position: "bottom",
          isActive: true,  
          resources: { sinew: 5, sigil: 5, oath: 5 }, 
          marks: 10, 
          hand: [], 
          battlefield: [], 
          sites: [], 
          capture: [], 
          discard: [], 
          deck: [] 
        },
        { 
          id: "p4", 
          name: "West Gate",
          position: "left",
          isActive: false, 
          resources: { sinew: 5, sigil: 5, oath: 5 }, 
          marks: 10, 
          hand: [], 
          battlefield: [], 
          sites: [], 
          capture: [], 
          discard: [], 
          deck: [] 
        },
      ]
    };
  }

  listUsers?(): User[] { 
    return Array.from(this.users.values()); 
  }

  async getUser(id: string): Promise<User | undefined> { 
    return this.users.get(id); 
  }

  async getUserByUsername(username: string): Promise<User | undefined> { 
    for (const u of this.users.values()) {
      if ((u as any).username === username) return u;
    }
    return undefined; 
  }

  async createUser(insertUser: InsertUser): Promise<User> { 
    const id = randomUUID(); 
    const user: User = { ...insertUser, id }; 
    this.users.set(id, user); 
    return user; 
  }

  private shouldAutoAdvance(): boolean {
    return this.game.phase === "Upkeep" || this.game.phase === "End";
  }

  getGameState() {
    while (this.shouldAutoAdvance()) {
      this.endPhase();
    }
    return this.withOutcome(this.game); 
  }

  private withOutcome(state: { phase: Phase; players: Player[] } & any) {
    const alive = state.players.filter(p => (p.marks ?? 0) > 0);
    if (alive.length === 1) {
      return { ...state, gameOver: true, winnerId: alive[0].id };
    }
    return { ...state, gameOver: false };
  }

  private computeWinner() { 
    this.game = this.withOutcome(this.game); 
  }

  private nextPhase(current: Phase): Phase { 
    const i = this.phaseOrder.indexOf(current); 
    return this.phaseOrder[(i+1) % this.phaseOrder.length]; 
  }

  private clearHeatForActive() {
    const i = this.game.players.findIndex(p => p.isActive); 
    if (i < 0) return;
    const p = this.game.players[i];
    p.battlefield = p.battlefield.map((c: any) => ({ 
      ...c, 
      heat: Math.max(0, (c.heat || 0) - 1) 
    }));
    this.game.players[i] = p;
  }

  private refreshResources() {
    const i = this.game.players.findIndex(p => p.isActive);
    if (i < 0) return;
    const p = this.game.players[i];
    
    p.resources = {
      sinew: 5,
      sigil: 5,
      oath: 5
    };
    
    this.game.players[i] = p;
  }

  private getKeywords(card: any): Set<string> {
    const t = (card?.text || "").toLowerCase(); 
    const out = new Set<string>();
    if (t.includes("taunt")) out.add("Taunt");
    if (t.includes("first strike")) out.add("First Strike");
    if (t.includes("haste")) out.add("Haste");
    return out;
  }

  endPhase() {
    const was = this.game.phase;
    const now = this.nextPhase(was);
    this.game.phase = now;
    
    if (was === "End") {
      const idx = this.game.players.findIndex(p => p.isActive);
      const next = (idx + 1) % this.game.players.length;
      this.game.players = this.game.players.map((p, i) => ({ ...p, isActive: i === next }));
      this.game.phase = "Upkeep";
      
      this.refreshResources();
      this.clearHeatForActive();
    }
    
    this.computeWinner();
    return this.game;
  }

  playCard(cardId?: string) {
    if (this.game.phase !== "Main") {
      console.log("Can only play cards during Main phase");
      return this.game;
    }
    
    const idx = this.game.players.findIndex(p => p.isActive);
    if (idx < 0) {
      console.log("No active player found");
      return this.game;
    }
    
    const p = this.game.players[idx];
    const hand: any[] = p.hand as any[];
    
    if (!hand.length) {
      console.log("Hand is empty");
      return this.game;
    }
    
    const card = cardId ? hand.find(c => c.id === cardId) : hand[0];
    if (!card) {
      console.log("Card not found in hand");
      return this.game;
    }

    const costS = (card as any).costSinew ?? 0;
    const costG = (card as any).costSigil ?? 0;
    const costO = (card as any).costOath ?? 0;
    
    console.log(`${p.name} playing card: ${card.name}`);
    console.log(`Cost: ${costS} sinew, ${costG} sigil, ${costO} oath`);
    
    if (p.resources.sinew < costS || p.resources.sigil < costG || p.resources.oath < costO) {
      console.log("Not enough resources");
      return this.game;
    }

    p.resources = { 
      sinew: p.resources.sinew - costS, 
      sigil: p.resources.sigil - costG, 
      oath: p.resources.oath - costO 
    };
    
    p.hand = hand.filter(c => c.id !== card.id);
    
    const keywords = this.getKeywords(card);
    const initialHeat = keywords.has("Haste") ? 0 : 1;
    
    if (card.type === "Site") {
      p.sites = [...p.sites, { ...card, heat: 0 } as any];
    } else {
      p.battlefield = [...p.battlefield, { ...card, heat: initialHeat } as any];
    }
    
    this.game.players[idx] = p;
    console.log(`${card.name} played successfully (heat: ${initialHeat})`);
    
    this.computeWinner();
    return this.game;
  }

  attack(attackerId: string, defenderIds?: string[], direct?: boolean, allocations?: Record<string, number>) {
    if (this.game.phase !== "Battle") {
      console.log("Can only attack during Battle phase");
      return this.game;
    }
    
    const aIdx = this.game.players.findIndex(p => p.isActive);
    if (aIdx < 0) return this.game;
    const dIdx = (aIdx + 1) % this.game.players.length;

    const atkP = this.game.players[aIdx];
    const defP = this.game.players[dIdx];

    const attacker = (atkP.battlefield as any[]).find(c => c.id === attackerId);
    if (!attacker) {
      console.log("Attacker not found");
      return this.game;
    }
    
    if ((attacker as any).heat > 0) {
      console.log(`${attacker.name} still has heat (${attacker.heat}) and cannot attack`);
      return this.game;
    }

    const defendersAll: any[] = (defP.battlefield as any[]) || [];
    const taunts = defendersAll.filter(c => this.getKeywords(c).has("Taunt"));
    let selected: any[] = (defenderIds && defenderIds.length) 
      ? defendersAll.filter(c => defenderIds.includes(c.id)) 
      : [];

    if (!selected.length) {
      if (taunts.length > 0) {
        console.log("Cannot attack directly - must attack Taunt creatures");
        return this.game;
      } else {
        const dmg = (attacker as any).power ?? 0;
        defP.marks = Math.max(0, (defP.marks ?? 0) - dmg);
        console.log(`${atkP.name}'s ${attacker.name} deals ${dmg} damage directly to ${defP.name} (${defP.marks} marks remaining)`);
        this.game.players[dIdx] = defP;
        this.computeWinner();
        return this.game;
      }
    }

    const atkKW = this.getKeywords(attacker);
    
    if (atkKW.has("First Strike")) {
      let remaining = (attacker as any).power ?? 0;
      for (const d of selected) {
        const alloc = allocations && allocations[d.id] != null 
          ? Math.max(0, Math.min(remaining, allocations[d.id])) 
          : Math.min(remaining, Number.MAX_SAFE_INTEGER);
        const toDeal = alloc;
        d.damage = (d.damage ?? 0) + toDeal;
        remaining -= toDeal;
        if ((d.damage ?? 0) >= (d.armor ?? 0)) {
          defP.battlefield = (defP.battlefield as any[]).filter(c => c.id !== d.id);
          defP.discard = [...defP.discard, d];
          console.log(`${d.name} destroyed by first strike`);
        }
        if (remaining <= 0) break;
      }
      selected = selected.filter(d => (defP.battlefield as any[]).find(c => c.id === d.id));
    }

    let attackerDamageTaken = 0;
    for (const d of selected) {
      attackerDamageTaken += (d.power ?? 0);
    }

    if (attackerDamageTaken > 0) {
      attacker.damage = (attacker.damage ?? 0) + attackerDamageTaken;
      if ((attacker.damage ?? 0) >= (attacker.armor ?? 0)) {
        atkP.battlefield = (atkP.battlefield as any[]).filter(c => c.id !== attackerId);
        atkP.discard = [...atkP.discard, attacker];
        console.log(`${attacker.name} destroyed in combat`);
      }
    }

    if (!atkKW.has("First Strike")) {
      let remaining = (attacker as any).power ?? 0;
      for (const d of selected) {
        const alloc = allocations && allocations[d.id] != null 
          ? Math.max(0, Math.min(remaining, allocations[d.id])) 
          : Math.min(remaining, Number.MAX_SAFE_INTEGER);
        const toDeal = alloc;
        d.damage = (d.damage ?? 0) + toDeal;
        remaining -= toDeal;
        if ((d.damage ?? 0) >= (d.armor ?? 0)) {
          defP.battlefield = (defP.battlefield as any[]).filter(c => c.id !== d.id);
          defP.discard = [...defP.discard, d];
          console.log(`${d.name} destroyed`);
        }
        if (remaining <= 0) break;
      }
    }

    this.game.players[aIdx] = atkP;
    this.game.players[dIdx] = defP;
    this.computeWinner();
    return this.game;
  }

  dealCards() {
    const cardTemplates: Omit<Card, 'id'>[] = [
      { 
        name: "Fire Warrior", 
        type: "Character", 
        world: "Mars", 
        rarity: "high", 
        power: 4, 
        armor: 2, 
        costSinew: 3, 
        costSigil: 0, 
        costOath: 1, 
        text: "Haste. Can attack immediately.", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Fire Warrior")
      },
      { 
        name: "Stone Guardian", 
        type: "Character", 
        world: "Earth", 
        rarity: "mid", 
        power: 2, 
        armor: 4, 
        costSinew: 2, 
        costSigil: 2, 
        costOath: 0, 
        text: "Taunt. Must be blocked if able.", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Stone Guardian")
      },
      { 
        name: "Swift Scout", 
        type: "Character", 
        world: "Moon", 
        rarity: "low", 
        power: 3, 
        armor: 1, 
        costSinew: 2, 
        costSigil: 0, 
        costOath: 0, 
        text: "", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Swift Scout")
      },
      { 
        name: "Mystic Sage", 
        type: "Character", 
        world: "Moon", 
        rarity: "rare", 
        power: 1, 
        armor: 3, 
        costSinew: 0, 
        costSigil: 3, 
        costOath: 1, 
        text: "Draw a card when played.", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Mystic Sage")
      },
      { 
        name: "Battle Axe", 
        type: "Relic", 
        world: "Mars", 
        rarity: "mid", 
        power: 0, 
        armor: 0, 
        costSinew: 2, 
        costSigil: 0, 
        costOath: 0, 
        text: "Equipped creature gets +2 power.", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Battle Axe")
      },
      { 
        name: "Shadow Assassin", 
        type: "Character", 
        world: "Nibiru", 
        rarity: "high", 
        power: 5, 
        armor: 1, 
        costSinew: 4, 
        costSigil: 1, 
        costOath: 0, 
        text: "First Strike.", 
        heat: 0,
        imageUrl: cardImageLoader.getImageUrl("Shadow Assassin")
      }
    ];

    this.game.players = this.game.players.map((p, idx) => {
      const newCards = cardTemplates.map((template, tIdx) => ({
        ...template,
        id: `card-${Date.now()}-p${idx}-t${tIdx}-${Math.random()}`
      } as Card));
      
      return {
        ...p,
        hand: [...p.hand, ...newCards]
      };
    });
    
    console.log("Dealt 6 cards to each player");
    return this.game;
  }

  resetGame() {
    this.game = this.seedGame();
    this.stack = [];
    console.log("Game reset");
    return this.game;
  }

  addBots() {
    console.log("Bots feature not yet implemented");
    return this.game;
  }

  joinGame(playerName: string) {
    const idx = this.game.players.findIndex(p => !p.isActive && p.name.includes("Gate"));
    if (idx >= 0) {
      this.game.players[idx].name = playerName;
      console.log(`${playerName} joined as player ${idx + 1}`);
    }
    return this.game;
  }

  pushStack(entry: any) { 
    this.stack.push({ id: String(Date.now()), ...entry }); 
    return { ok: true, stack: this.stack }; 
  }

  resolveStack() { 
    this.stack.pop(); 
    return { ok: true, stack: this.stack }; 
  }

  passPriority() { 
    return { ok: true }; 
  }
}

export const storage = new MemStorage();