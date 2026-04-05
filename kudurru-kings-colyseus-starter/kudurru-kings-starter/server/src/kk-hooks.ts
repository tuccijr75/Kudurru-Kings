import type { Client } from "colyseus";
import { KudurruRoom } from "./rooms/KudurruRoom";

type UiPayload = { phase: string; activeIndex: number; names: string[] };

function namesFrom(room:any): string[] {
  // Prefer schema players -> name; fallback to clients
  try {
    const s:any = room.state;
    const P = typeof s?.players?.toJSON === "function" ? s.players.toJSON() : s?.players;
    if (P && typeof P === "object") {
      const ids = Object.keys(P);
      return ids.slice(0, 4).map((id, i) => P[id]?.name ?? `P${i + 1}`);
    }
  } catch {}
  // fallback to joined clients + any tracked bots
  const base = (room.clients || []).slice(0,4).map((c:any,i:number)=> c?.auth?.name ?? `P${i+1}`);
  const bots: string[] = room._kk?.botNames || [];
  return [...base, ...bots].slice(0,4);
}

(function patch(){
  const proto:any = (KudurruRoom as any).prototype;
  if (proto.__kkPatched) return; proto.__kkPatched = true;

  const order = ["Upkeep","Main","Battle","End"];

  const origOnCreate = proto.onCreate;
  proto.onCreate = function(...args:any[]){
    origOnCreate?.apply(this,args);
    this._kk = this._kk || { phase: "Upkeep", activeIndex: 0, botNames: [] as string[] };

    const broadcastUi = () => {
      const p:UiPayload = { phase: this._kk.phase, activeIndex: this._kk.activeIndex, names: namesFrom(this) };
      try { this.broadcast("ui", p); } catch {}
    };
    this._kkBroadcastUi = broadcastUi;

    // admin wires
    this.onMessage("admin", (client:Client, msg:any) => {
      switch (msg?.type) {
        case "ADD_BOTS": {
          const n = Math.max(1, Math.min(3, Number(msg?.count ?? 1)));
          const start = this._kk.botNames.length;
          for (let i=0;i<n;i++) this._kk.botNames.push(`Bot ${start+i+1} 🤖`);
          try { client.send("ack", { ok:true, type:"ADD_BOTS" }); } catch {}
          broadcastUi();
          return;
        }
        case "RESET_MATCH": {
          this._kk.phase = "Upkeep"; this._kk.activeIndex = 0;
          try { client.send("ack", { ok:true, type:"RESET_MATCH" }); } catch {}
          broadcastUi();
          return;
        }
      }
    });

    // action wires
    this.onMessage("action", (client:Client, msg:any) => {
      switch (msg?.type) {
        case "NEXT_PHASE": {
          const i = order.indexOf(this._kk.phase);
          this._kk.phase = order[(i<0?0:i+1) % order.length];
          try { client.send("ack", { ok:true, type:"NEXT_PHASE", phase: this._kk.phase }); } catch {}
          broadcastUi();
          return;
        }
        case "PLAY_CARD": {
          // Minimal ack so the UI can react; your rules engine can hook in later.
          try { client.send("ack", { ok:true, type:"PLAY_CARD", id: msg?.id }); } catch {}
          return;
        }
      }
    });

    // First UI snapshot (may race with client bind — harmless)
    setTimeout(broadcastUi, 0);
  };

  const origOnJoin = proto.onJoin;
  proto.onJoin = function(...a:any[]){
    const r = origOnJoin?.apply(this,a);
    this._kk && setTimeout(this._kkBroadcastUi, 0);
    return r;
  };

  const origOnLeave = proto.onLeave;
  proto.onLeave = function(...a:any[]){
    const r = origOnLeave?.apply(this,a);
    this._kk && setTimeout(this._kkBroadcastUi, 0);
    return r;
  };
})();
