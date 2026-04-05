import { Room, Client } from "colyseus";
import { Schema, type, MapSchema, ArraySchema } from "@colyseus/schema";

/** Minimal card for now (UI uses names/ids). Extend later. */
class Card extends Schema {
  @type("string") id: string = "";
  @type("string") name: string = "";
}

class Player extends Schema {
  @type("string") id: string = "";
  @type("string") name: string = "";
  @type("boolean") ai: boolean = false;
  @type([Card]) hand = new ArraySchema<Card>();
}

class TableState extends Schema {
  @type({ map: "number" }) pools = new MapSchema<number>();
}

class KKState extends Schema {
  @type("string") phase: string = "Upkeep";
  @type("number") activeIndex: number = 0;
  @type({ map: Player }) players = new MapSchema<Player>();
  @type(TableState) table = new TableState();
}

export class KudurruRoom extends Room<KKState> {

  onCreate(options: any) {
    this.setState(new KKState());

    // Compat for older client buttons that used "toggle"
    this.onMessage("toggle", (client, m: any) => {
      // no-op but prevents "not registered" errors
      client.send("ack", { ok: true, type: "TOGGLED", key: m?.key, value: m?.value });
    });

    // Admin and action channels
    this.onMessage("admin",  (client, m: any) => this.handleAdmin(client, m));
    this.onMessage("action", (client, m: any) => this.handleAction(client, m));
  }

  onJoin(client: Client, _opts: any) {
    // Seat a human player
    const p = new Player();
    p.id   = client.sessionId;
    p.name = `Player ${this.playerCount()+1}`;
    p.ai   = false;
    this.state.players[p.id] = p;

    client.send("ack", { ok: true, type: "JOINED", pid: p.id });
    this.pushUi();
  }

  onLeave(client: Client) {
    delete this.state.players[client.sessionId];
    this.pushUi();
  }

  // ---------- Admin / Action handlers ----------

  private handleAdmin(client: Client, msg: any) {
    const t = msg?.type;
    switch (t) {
      case "ADD_BOTS": {
        const n = Math.max(1, Math.min(3, msg?.count ?? 3));
        for (let i = 0; i < n; i++) this.addBot();
        client.send("ack", { ok: true, type: "ADD_BOTS" });
        this.pushUi();
        return;
      }
      case "DEAL6": {
        this.forEachPlayer(pid => this.deal(pid, 6));
        client.send("ack", { ok: true, type: "DEAL6" });
        return;
      }
      case "NEXT_PHASE": {
        this.nextPhase();
        client.send("ack", { ok: true, type: "NEXT_PHASE", phase: this.state.phase });
        this.pushUi();
        return;
      }
      case "RESET_MATCH": {
        this.resetMatch();
        client.send("ack", { ok: true, type: "RESET_MATCH" });
        this.pushUi();
        return;
      }
    }
    // Unknown admin messages fall through (no crash)
  }

  private handleAction(_client: Client, _msg: any) {
    // (reserved for play/attack/etc — your UI not using this yet)
  }

  // ---------- Helpers ----------

  private playerCount(): number {
    let n = 0; for (const _ in this.state.players) n++; return n;
  }

  private forEachPlayer(fn: (id: string) => void) {
    for (const pid in this.state.players) fn(pid);
  }

  private addBot() {
    const p = new Player();
    const idx = this.playerCount() + 1;
    p.id   = `bot_${idx}`;
    p.name = `Bot ${idx} 🤖`;
    p.ai   = true;
    this.state.players[p.id] = p;
  }

  private deal(pid: string, n: number) {
    const pl = this.state.players[pid];
    if (!pl) return;
    for (let i = 0; i < n; i++) {
      const c = new Card();
      c.id   = `c_${Date.now()}_${Math.random().toString(36).slice(2,7)}`;
      c.name = `Card ${Math.floor(Math.random() * 999)}`;
      pl.hand.push(c);
    }
  }

  private resetMatch() {
    this.forEachPlayer(pid => (this.state.players[pid].hand = new ArraySchema<Card>()));
    this.state.phase = "Upkeep";
    this.state.activeIndex = 0;
  }

  private nextPhase() {
    const order = ["Upkeep", "Main", "Battle", "End"];
    const i = order.indexOf(this.state.phase);
    this.state.phase = order[(i < 0 ? 0 : (i + 1) % order.length)];
  }

  private pushUi() {
    const names: string[] = [];
    for (const pid in this.state.players) names.push(this.state.players[pid].name);
    this.broadcast("ui", {
      phase: this.state.phase,
      activeIndex: this.state.activeIndex,
      names
    });
  }
}