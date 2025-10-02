
import type { User, InsertUser, Player, Phase, Card } from "@shared/schema";
import { randomUUID } from "crypto";

export interface IStorage {
  listUsers?(): User[];
  getUser(id: string): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;

  getGameState(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  playCard(cardId?: string): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  endPhase(): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  attack(attackerId: string, defenderIds?: string[], direct?: boolean, allocations?: Record<string, number>): { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };

  pushStack(entry: any): { ok: true; stack: any[] };
  resolveStack(): { ok: true; stack: any[] };
  passPriority(): { ok: true };
}

export class MemStorage implements IStorage {
  private users: Map<string, User>;
  private game: { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };
  private stack: any[] = [];
  private phaseOrder: Phase[] = ["Upkeep","Main","Battle","End"];

  constructor() {
    this.users = new Map();
    this.game = this.seedGame();
  }

  private seedGame(): { phase: Phase; players: Player[] } {
    return {
      phase: "Main",
      players: [
        { id: "p1", name: "North Gate", isActive: false, resources: { sinew: 3, sigil: 2, oath: 1 }, marks: 10, hand: [], battlefield: [], sites: [], capture: [], discard: [], deck: [] },
        { id: "p2", name: "East Gate",  isActive: false, resources: { sinew: 2, sigil: 1, oath: 1 }, marks: 10, hand: [], battlefield: [], sites: [], capture: [], discard: [], deck: [] },
        { id: "p3", name: "South Gate", isActive: true,  resources: { sinew: 4, sigil: 1, oath: 1 }, marks: 10, hand: [
            { id: "c1", name: "Uruk Shield-Bearer", type: "Character", world: "Earth", rarity: "mid", power: 2, armor: 1, costSinew: 2, costSigil: 0, costOath: 0, text: "Taunt. First strike while defending.", heat: 0 } as Card
          ], battlefield: [
            { id: "c2", name: "Canal Saboteur", type: "Character", world: "Mars", rarity: "mid", power: 3, armor: 2, costSinew: 3, costSigil: 0, costOath: 0, text: "When attacks, you may drain 1 sigil.", heat: 1 } as Card
          ], sites: [], capture: [], discard: [], deck: [] },
        { id: "p4", name: "West Gate",  isActive: false, resources: { sinew: 1, sigil: 2, oath: 2 }, marks: 10, hand: [], battlefield: [], sites: [], capture: [], discard: [], deck: [] },
      ]
    };
  }

  listUsers?(): User[] { return Array.from(this.users.values()); }
  async getUser(id: string): Promise<User | undefined> { return this.users.get(id); }
  async getUserByUsername(username: string): Promise<User | undefined> { for (const u of this.users.values()) if ((u as any).username === username) return u; return undefined; }
  async createUser(insertUser: InsertUser): Promise<User> { const id = randomUUID(); const user: User = { ...insertUser, id }; this.users.set(id, user); return user; }

  getGameState() { return this.withOutcome(this.game); }

  private withOutcome(state: { phase: Phase; players: Player[] } & any) {
    const alive = state.players.filter(p => (p.marks ?? 0) > 0);
    if (alive.length === 1) return { ...state, gameOver: true, winnerId: alive[0].id };
    return { ...state, gameOver: false };
  }
  private computeWinner() { this.game = this.withOutcome(this.game); }

  private nextPhase(current: Phase): Phase { const i = this.phaseOrder.indexOf(current); return this.phaseOrder[(i+1)%this.phaseOrder.length]; }
  private clearSummoningForActive() {
    const i = this.game.players.findIndex(p => p.isActive); if (i < 0) return;
    const p = this.game.players[i];
    p.battlefield = p.battlefield.map((c: any) => ({ ...c, summoning: false }));
    this.game.players[i] = p;
  }
  private getKeywords(card: any): Set<string> {
    const t = (card?.text || "").toLowerCase(); const out = new Set<string>();
    if (t.includes("taunt")) out.add("Taunt");
    if (t.includes("first strike")) out.add("First Strike");
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
      this.clearSummoningForActive();
    }
    this.computeWinner();
    return this.game;
  }

  playCard(cardId?: string) {
    if (this.game.phase !== "Main") return this.game;
    const idx = this.game.players.findIndex(p => p.isActive);
    if (idx < 0) return this.game;
    const p = this.game.players[idx];
    const hand: any[] = p.hand as any[];
    if (!hand.length) return this.game;
    const card = cardId ? hand.find(c => c.id === cardId) : hand[0];
    if (!card) return this.game;

    const costS = (card as any).costSinew ?? 0;
    const costG = (card as any).costSigil ?? 0;
    const costO = (card as any).costOath ?? 0;
    if (p.resources.sinew < costS || p.resources.sigil < costG || p.resources.oath < costO) return this.game;

    p.resources = { sinew: p.resources.sinew - costS, sigil: p.resources.sigil - costG, oath: p.resources.oath - costO };
    p.hand = hand.filter(c => c.id !== card.id);
    p.battlefield = [...p.battlefield, { ...card, summoning: true } as any];
    this.game.players[idx] = p;
    this.computeWinner();
    return this.game;
  }

  attack(attackerId: string, defenderIds?: string[], direct?: boolean, allocations?: Record<string, number>) {
    if (this.game.phase !== "Battle") return this.game;
    const aIdx = this.game.players.findIndex(p => p.isActive);
    if (aIdx < 0) return this.game;
    const dIdx = (aIdx + 1) % this.game.players.length;

    const atkP = this.game.players[aIdx];
    const defP = this.game.players[dIdx];

    const attacker = (atkP.battlefield as any[]).find(c => c.id === attackerId);
    if (!attacker) return this.game;
    if ((attacker as any).summoning) return this.game;

    const defendersAll: any[] = (defP.battlefield as any[]) || [];
    const taunts = defendersAll.filter(c => this.getKeywords(c).has("Taunt"));
    let selected: any[] = (defenderIds && defenderIds.length) ? defendersAll.filter(c => defenderIds.includes(c.id)) : [];

    if (!selected.length) {
      if (taunts.length > 0) {
        // must block Taunt; illegal direct attack
        this.computeWinner();
        return this.game;
      } else {
        // direct to marks
        const dmg = (attacker as any).power ?? 0;
        defP.marks = Math.max(0, (defP.marks ?? 0) - dmg);
        this.game.players[dIdx] = defP;
        this.computeWinner();
        return this.game;
      }
    }

    // FIRST STRIKE STEP (attacker only)
    const atkKW = this.getKeywords(attacker);
    if (atkKW.has("First Strike")) {
      let remaining = (attacker as any).power ?? 0;
      for (const d of selected) {
        const alloc = allocations && allocations[d.id] != null ? Math.max(0, Math.min(remaining, allocations[d.id])) : Math.min(remaining, Number.MAX_SAFE_INTEGER);
        const toDeal = alloc;
        d.damage = (d.damage ?? 0) + toDeal;
        remaining -= toDeal;
        if ((d.damage ?? 0) >= (d.armor ?? 0)) {
          defP.battlefield = (defP.battlefield as any[]).filter(c => c.id !== d.id);
          defP.discard = [...defP.discard, d];
        }
        if (remaining <= 0) break;
      }
      // refresh selected to those still alive
      selected = selected.filter(d => (defP.battlefield as any[]).find(c => c.id === d.id));
    }

    // BLOCKERS DEAL DAMAGE (sum)
    let attackerDamageTaken = 0;
    for (const d of selected) attackerDamageTaken += (d.power ?? 0);

    if (attackerDamageTaken > 0) {
      attacker.damage = (attacker.damage ?? 0) + attackerDamageTaken;
      if ((attacker.damage ?? 0) >= (attacker.armor ?? 0)) {
        atkP.battlefield = (atkP.battlefield as any[]).filter(c => c.id !== attackerId);
        atkP.discard = [...atkP.discard, attacker];
      }
    }

    // NORMAL STEP (attacker to remaining blockers if not First Strike)
    if (!atkKW.has("First Strike")) {
      let remaining = (attacker as any).power ?? 0;
      for (const d of selected) {
        const alloc = allocations && allocations[d.id] != null ? Math.max(0, Math.min(remaining, allocations[d.id])) : Math.min(remaining, Number.MAX_SAFE_INTEGER);
        const toDeal = alloc;
        d.damage = (d.damage ?? 0) + toDeal;
        remaining -= toDeal;
        if ((d.damage ?? 0) >= (d.armor ?? 0)) {
          defP.battlefield = (defP.battlefield as any[]).filter(c => c.id !== d.id);
          defP.discard = [...defP.discard, d];
        }
        if (remaining <= 0) break;
      }
    }

    this.game.players[aIdx] = atkP;
    this.game.players[dIdx] = defP;
    this.computeWinner();
    return this.game;
  }

  pushStack(entry: any) { this.stack.push({ id: String(Date.now()), ...entry }); return { ok: true, stack: this.stack }; }
  resolveStack() { this.stack.pop(); return { ok: true, stack: this.stack }; }
  passPriority() { return { ok: true }; }
}

export const storage = new MemStorage();
