import "./kk-seats";
import "./kk-cards";
import "./style.css";
import { Client, Room } from "colyseus.js";
type State = any;

// ====================================================================================
// 1) DOM Shell (unchanged visuals)
// ====================================================================================
const app = document.getElementById("app")!;
app.innerHTML = `
  <div class="h2h-wrap">
    <h2 class="h2h-title">KUDURRU KINGS — Head-to-Head Client (4 Players)</h2>
    <div class="h2h-bar">
      <div class="tabs">
        <button id="join"   class="btn">Join Room</button>
        <button id="next"   class="btn">Next Phase</button>
        <button id="bots"   class="btn">Add 3 Bots</button>
        <button id="deal6"  class="btn">Deal 6</button>
        <button id="reset"  class="btn">Reset Match</button>
        <button id="aitick" class="btn">AI Step</button>
        <button id="reveal" class="btn">Toggle Reveal AI</button>
        <button id="sandbox" class="btn">Toggle Sandbox</button>
        <button id="tutor"  class="btn">Start Tutorial</button>
        <button id="openlib" class="btn">Open Library</button>
      </div>
      <div class="right">
        <small class="mono">Zoom</small>
        <input id="zoom" type="range" min="0.75" max="1.15" value="0.85" step="0.05" />
      </div>
    </div>

    <div class="filter-row">
      <span class="label">Type:</span>
      <div class="tabs" id="typeTabs">
        <button class="tab is-active" data-type="All">All</button>
        <button class="tab" data-type="Boss">Boss</button>
        <button class="tab" data-type="Character">Character</button>
        <button class="tab" data-type="Enemy">Enemy</button>
        <button class="tab" data-type="Pet">Pet</button>
        <button class="tab" data-type="Relic">Relic</button>
        <button class="tab" data-type="Site">Site</button>
        <button class="tab" data-type="Rune">Rune</button>
      </div>
      <div class="right" style="margin-left:auto">
        <span class="label">Rarity</span>
        <div class="tabs" id="rarityTabs">
          <button class="tab is-active" data-rar="All">All</button>
          <button class="tab" data-rar="Low">Low</button>
          <button class="tab" data-rar="Mid">Mid</button>
          <button class="tab" data-rar="Rare">Rare</button>
        </div>
      </div>
    </div>

    <div class="grid-2">
      <div class="panel" id="phasePanel"><div><b>Phase:</b> <span id="phaseTxt">—</span></div></div>
      <div class="panel"><div><b>Analyzer</b></div><div id="analyzer" style="margin-top:6px;color:var(--ink-dim)">Click Start Tutorial for guided steps.</div></div>
    </div>

    <div class="arena panel" id="arena">
      <div class="lane"></div>
      <div class="lane dashed" style="top:calc(50% + 42px)"></div>
      <div class="anchor left"></div><div class="anchor right"></div>
      <div class="vert"></div>
      <div class="plaza"><div><div style="font-size:18px">Kudurru Plaza</div><div style="font-size:11px; color:var(--ink-dim)">Capture to unlock Law slot</div></div></div>
      <div class="seat t"><div><h4 id="pTopNm">P1</h4><p>Influence 0 Tribute 0 Oaths 0/2</p></div></div>
      <div class="seat r"><div><h4 id="pRightNm">P2</h4><p>Influence 0 Tribute 0 Oaths 0/2</p></div></div>
      <div class="seat b"><div><h4 id="pBotNm">P3</h4><p>Influence 0 Tribute 0 Oaths 0/2</p></div></div>
      <div class="seat l"><div><h4 id="pLeftNm">P4</h4><p>Influence 0 Tribute 0 Oaths 0/2</p></div></div>
    </div>

    <div class="hands">
      <div class="hand"><div class="title">P1 Hand (You)</div><div class="cards" id="handYou"></div></div>
      <div class="hand"><div class="title">P2 / P3 Hands</div><div class="cards" id="handOthers"></div></div>
    </div>

    <div class="ring">
      <div class="blob" id="cmdPlay">Play</div>
      <div class="blob" id="cmdMove">Move</div>
      <div class="blob" id="cmdInvoke">Invoke</div>
      <div class="blob" id="cmdEnd">End</div>
    </div>

    <div class="library" id="library">
      <div class="row" style="justify-content:space-between">
        <div class="tabs" id="libTypeTabs">
          <button class="tab is-active" data-type="All">All</button><button class="tab" data-type="Boss">Boss</button><button class="tab" data-type="Character">Character</button><button class="tab" data-type="Enemy">Enemy</button><button class="tab" data-type="Pet">Pet</button><button class="tab" data-type="Relic">Relic</button><button class="tab" data-type="Site">Site</button><button class="tab" data-type="Rune">Rune</button>
        </div>
        <div class="tabs" id="libRarityTabs">
          <button class="tab is-active" data-rar="All">All</button><button class="tab" data-rar="Low">Low</button><button class="tab" data-rar="Mid">Mid</button><button class="tab" data-rar="Rare">Rare</button>
        </div>
      </div>
      <div class="row"><button class="btn" id="libClose">Close</button><small class="mono">Library</small></div>
      <div id="libBody" class="cards"></div>
    </div>
  </div>
`;

// ====================================================================================
// 2) Helpers
// ====================================================================================
const $$ = (q:string, r:Document|HTMLElement=document)=>Array.from(r.querySelectorAll(q)) as HTMLElement[];
const $  = (q:string, r:Document|HTMLElement=document)=>r.querySelector(q) as HTMLElement;
function on(id:string, fn:()=>void){ const el = document.getElementById(id); if (el) el.addEventListener("click", fn); }
function escapeHtml(s:string){ return s.replace(/[&<>"']/g,(ch)=> ch==="&"?"&amp;":ch=="<"?"&lt;":ch==">"?"&gt;":ch=='"'?"&quot;":"&#39;"); }
function log(...a:any[]){ console.log("[KK]", ...a); }

// ====================================================================================
/** Robust join + graceful offline fallback */
// ====================================================================================
const WS = (location.protocol==="https:"?"wss":"ws")+"://localhost:2567";
const client = new Client(WS);
let room: Room<State> | null = null;
let myId = ""; let lastState: any = null;
let tutorialOn=false; let offline=true;     // start offline until we successfully join

// filters
const filters   = { type:"All", rarity:"All" };
const libFilter = { type:"All", rarity:"All" };

// offline demo state
let seatNames = ["P1","P2","P3","P4"];
let offlinePhase: "Upkeep"|"Main"|"Battle"|"End" = "Upkeep";

// ====================================================================================
// 3) Card source (seed library immediately so Library works before joining)
// ====================================================================================
type Card = { name:string; type:string; rarity:"Low"|"Mid"|"Rare"; atk:number; def:number; cost:number };
let libCards: Card[] = seedLibrary(240);    // ~200+ cards across types & rarities

function seedLibrary(n:number):Card[]{
  const types = ["Boss","Character","Enemy","Pet","Relic","Site","Rune"];
  const rarRoll = () => {
    const r = Math.random();
    return r < 0.55 ? "Low" : r < 0.88 ? "Mid" : "Rare";
  };
  const namesByType:Record<string,string[]> = {
    "Boss":["Warden of Ishtar","Leviathan of Eridu","Moon Citadel Tyrant","Dust Archon","Loom Sovereign"],
    "Character":["Sandline Assassin","Obsidian Sentry","Vault Captain","Canal Duelist","Storm Scribe","Reed Runner"],
    "Enemy":["Lion of Ishtar","Canal Brigand","Reed Stalker","Basalt Marauder","Gate Hound"],
    "Pet":["Reed Cat","River Saboteur","Cedar Ranger’s Hawk"],
    "Relic":["Heavy Crowns","Anchor of Eridu","Sanctuary Court","Festival Censer","Audit Ledger"],
    "Site":["Canal Gates","North Gate Captaincy","Moon Outpost","Star Observatory","Rift Bridge"],
    "Rune":["Edict of Passage","Oath of Glass","Hex of Dust","Law of Loom"]
  };
  const pick = (arr:string[]) => arr[Math.floor(Math.random()*arr.length)];
  const cards:Card[] = [];
  for(let i=0;i<n;i++){
    const t = types[Math.floor(Math.random()*types.length)];
    const rar = rarRoll() as Card["rarity"];
    const base = rar==="Low"?1:rar==="Mid"?2:3;
    cards.push({
      name: `${pick(namesByType[t])} ${Math.floor(Math.random()*300)+1}`,
      type: t,
      rarity: rar,
      atk: base + Math.floor(Math.random()*3),
      def: base + Math.floor(Math.random()*3),
      cost: Math.max(1, base-1 + Math.floor(Math.random()*3))
    });
  }
  return cards;
}

// ====================================================================================
// 4) UI interactions
// ====================================================================================
const z = document.getElementById("zoom") as HTMLInputElement;
if (z){ const setZ=(v:string)=>document.documentElement.style.setProperty("--card-scale", v); setZ(z.value); z.addEventListener("input", ()=>setZ(z.value)); }

wireTabs("typeTabs","type",filters, ()=> render(lastState));
wireTabs("rarityTabs","rarity",filters, ()=> render(lastState));
wireTabs("libTypeTabs","type",libFilter, ()=> renderLibrary());
wireTabs("libRarityTabs","rarity",libFilter, ()=> renderLibrary());

on("openlib", ()=> { $("#library").classList.add("is-open"); renderLibrary(); });
on("libClose",()=> $("#library").classList.remove("is-open"));

on("tutor",  ()=>{ tutorialOn = !tutorialOn; updateTutorial(); });
on("cmdPlay",  ()=> action("PLAY_CARD"));
on("cmdMove",  ()=> action("MOVE"));
on("cmdInvoke",()=> action("INVOKE"));
on("cmdEnd",   ()=> action("NEXT_PHASE"));

on("next",   ()=> action("NEXT_PHASE"));
on("deal6",  ()=> action("DEAL6"));
on("aitick", ()=> admin("AI_TICK"));
on("reset",  ()=> admin("RESET_MATCH"));
on("reveal", ()=> toggle("revealAI"));
on("sandbox",()=> toggle("sandbox"));

on("bots", async ()=>{
  if (!offline && room){
    try { room.send("admin", {type:"ADD_BOTS", count:3}); } catch {}
    for(let i=0;i<3;i++){ try { room.send("admin", {type:"ADD_BOT"}); } catch{} }
  } else {
    // offline: seat 2..4 become bots
    seatNames = ["Player 1","Bot 1 🤖","Bot 2 🤖","Bot 3 🤖"];
    // give everyone some cards to make hands visible
    dealOfflineHands();
    render(null);
  }
});

on("join", async ()=>{
  // Try to join server. If it fails, remain in offline mode and keep UI working.
  try {
    log("Using server:", WS);
    log("Joining room 'kudurru'…");
    room = await client.joinOrCreate<State>("kudurru");
  } catch {
    try {
      log("'kudurru' not available, trying 'my_room'…");
      room = await client.joinOrCreate<State>("my_room");
    } catch (err) {
      log("Server unreachable → staying in offline demo mode.");
      offline = true;
      seatNames = ["Player 1","Bot 1 🤖","Bot 2 🤖","Bot 3 🤖"];
      dealOfflineHands();
      updateTutorial();
      render(null);
      return;
    }
  }
  // joined OK
  offline = false;
  myId = room!.sessionId;
  log("Joined. Session:", myId);
  try { room!.send("toggle", {key:"revealAI", value:true}); } catch {}
  room!.onStateChange((st:any)=>{
    lastState = st;
    render(st);
    updateTutorial();
  });
});

// ====================================================================================
// 5) Render & filtering
// ====================================================================================
function wireTabs(containerId:string, key:"type"|"rarity", target:{type:string,rarity:string}, cb:()=>void){
  const c = document.getElementById(containerId)!; if(!c) return;
  c.addEventListener("click", (ev)=>{
    const b = (ev.target as HTMLElement).closest(".tab") as HTMLElement | null;
    if(!b) return;
    for(const t of $$(".tab", c)) t.classList.remove("is-active");
    b.classList.add("is-active");
    const v = (b.dataset.type || b.dataset.rar || "All");
    (target as any)[key] = v;
    cb();
  });
}

function passFilter(card:any, f:{type:string, rarity:string}){
  const t = (card?.type || "Unknown");
  const r = (card?.rarity || "Mid");
  const typeOk = (f.type==="All" || t===f.type);
  const rarOk  = (f.rarity==="All" || r===f.rarity);
  return typeOk && rarOk;
}

function render(st:any){
  // names
  if (offline){
    $("#pTopNm").textContent   = seatNames[0]||"P1";
    $("#pRightNm").textContent = seatNames[1]||"P2";
    $("#pBotNm").textContent   = seatNames[2]||"P3";
    $("#pLeftNm").textContent  = seatNames[3]||"P4";
  } else {
    const names = extractNames(st);
    $("#pTopNm").textContent   = names[0] || "P1";
    $("#pRightNm").textContent = names[1] || "P2";
    $("#pBotNm").textContent   = names[2] || "P3";
    $("#pLeftNm").textContent  = names[3] || "P4";
  }

  // phase text
  const phase = offline ? offlinePhase : (st?.phase || "—");
  $("#phaseTxt").textContent = ` ${phase} — Active: ${offline? seatNames[0] : (extractNames(st)[st?.activeIndex||0] || "—")} `;

  // hands
  if (offline){
    $("#handYou").innerHTML    = offHands.you.filter(c=>passFilter(c, filters)).map(cardHtml).join("");
    $("#handOthers").innerHTML = offHands.others.filter(c=>passFilter(c, filters)).slice(0,18).map(cardHtml).join("");
  } else {
    const players = extractPlayers(st);
    const me = players.find(p=>p.id===myId) || players[0];
    const others = players.filter(p=>p.id!==myId);
    const myCards = (me?.hand||[]).filter((c:any)=>passFilter(c, filters));
    const othCards = others.flatMap(o => (o?.hand||[])).filter((c:any)=>passFilter(c, filters));
    $("#handYou").innerHTML    = myCards.map(cardHtml).join("");
    $("#handOthers").innerHTML = othCards.slice(0,18).map(cardHtml).join("");
  }
}

function cardHtml(c:any){
  const name = (c?.name || "Card");
  const type = (c?.type || "—");
  const rar  = (c?.rarity || "Mid");
  const atk  = (c?.atk ?? c?.power ?? 0);
  const def  = (c?.def ?? c?.armor ?? 0);
  const cost = (c?.cost ?? c?.pips ?? 0);
  const rcls = rar==="Low"?"r-low":(rar==="Rare"?"r-rare":"r-mid");
  return `
  <div class="card" title="${escapeHtml(name)}">
    <div class="hdr"><span class="badge">${escapeHtml(type)}</span><span class="${rcls}">${escapeHtml(rar)}</span></div>
    <div class="name">${escapeHtml(name)}</div>
    <div class="pips"><span class="pip">⋄ ${cost}</span><span class="pip">⚔ ${atk}</span><span class="pip">🛡 ${def}</span></div>
    <div class="stats"><span></span><span></span></div>
  </div>`;
}

// Library always works: we seeded libCards upfront
function renderLibrary(){
  const body = $("#libBody");
  if(!body) return;
  const items = libCards.filter(c=>passFilter(c, libFilter));
  body.innerHTML = items.map(cardHtml).join("");
}

// ====================================================================================
// 6) Actions / admin / toggles (safe both online & offline)
// ====================================================================================
function action(type:string){
  if (!offline && room){ try { room.send("action", {type}); } catch{} }
  if (offline){
    if (type==="NEXT_PHASE"){
      offlinePhase = offlinePhase==="Upkeep" ? "Main" : offlinePhase==="Main" ? "Battle" : "Upkeep";
      updateTutorial();
      render(null);
    } else if (type==="PLAY_CARD"){
      // no-op demo
    } else if (type==="DEAL6"){
      dealOfflineHands();
      render(null);
    }
  }
}
function admin(type:string){
  if (!offline && room){ try { room.send("admin", {type}); } catch{} }
}
function toggle(key:"revealAI"|"sandbox"){
  if (!offline && room){
    const val = !(lastState?.[key]);
}
}

// ====================================================================================
// 7) Tutorial
// ====================================================================================
function updateTutorial(){
  const a = $("#analyzer");
  const ph = offline ? offlinePhase : (lastState?.phase || "—");
  const lines:string[] = [];
  lines.push(`<b>Tutorial — ${escapeHtml(ph)}</b>`);
  if (ph==="Upkeep"){
    lines.push("Upkeep refreshes resources. Hover pips on any card to learn costs.");
    lines.push("Click <b>Next Phase</b> to enter Main.");
  } else if (ph==="Main"){
    lines.push("Play a Character from your hand. Relics attach; Pets accompany.");
  } else if (ph==="Battle"){
    lines.push("Choose an attacker, then a defender. Resolve the test.");
  } else {
    lines.push("Proceed until the phase advances.");
  }
  a.innerHTML = lines.map(l=>`<div>${l}</div>`).join("");
}

// ====================================================================================
// 8) Online helpers
// ====================================================================================
function extractPlayers(st:any){
  const out:any[]=[]; const mp:any=st?.players; if(!mp) return out;
  if (typeof mp.forEach==="function"){ mp.forEach((p:any,id:string)=>out.push({id, ...p})); return out; }
  if (typeof mp.toJSON==="function"){ const obj=mp.toJSON(); for(const id in obj) out.push({id,...obj[id]}); return out; }
  for(const id in mp) out.push({id,...mp[id]}); return out;
}
function extractNames(st:any){
  const ps = extractPlayers(st);
  return ps.map(p=>p.name || (p.ai? "Bot":"Player"));
}

// ====================================================================================
// 9) Offline: minimal hand data to make cards visible
// ====================================================================================
const offHands:{you:Card[]; others:Card[]} = { you:[], others:[] };
function dealOfflineHands(){
  offHands.you    = libCards.slice(0, 6);
  offHands.others = libCards.slice(6, 6+18);
}

// initial render (offline shell visible immediately)
dealOfflineHands();
render(null);
updateTutorial();



/* __KK_WIRED_CLIENT_V4__ */
(() => {
  if ((window as any).__KK_WIRED_CLIENT_V4__) return;
  (window as any).__KK_WIRED_CLIENT_V4__ = true;

  const log = (...a:any[]) => console.log("[KK][cli]", ...a);

  let client:any = (window as any).KK?.client || null;
  let room:any   = (window as any).KK?.room   || null;
  let joining = false;

  const wsOpen = () => !!(room && room.connection && room.connection.readyState === 1);

  async function leave() {
    try { if (room) { await room.leave(true); } } catch {}
    room = null;
    if ((window as any).KK) (window as any).KK.room = null;
  }

  // Replace an element with a fresh clone to drop any old listeners
  function rebind(id:string, handler:(ev?:any)=>void) {
    const el = document.getElementById(id);
    if (!el) { log("missing #"+id); return; }
    const clone = el.cloneNode(true) as HTMLElement;
    el.replaceWith(clone);
    clone.id = id;
    clone.addEventListener("click", (ev)=>{ try { handler(ev); } catch(e){ console.error("[KK] click error", e); } });
  }

  async function join(){ /* __KK_JOIN_GUARD__ */ if ((window as any).KK?.room) { console.log("[KK][cli] already joined"); return; }
    if (joining) return room;
    joining = true;
    const joinBtn = document.getElementById("join") as HTMLButtonElement | null;
    try{
      if (joinBtn) joinBtn.disabled = true;

      // Always close any previous room first (handles HMR/stale refs)
      await leave();

      const { Client } = await import("colyseus.js");
      const url = (location.protocol === "https:" ? "wss" : "ws") + "://" + location.hostname + ":2567";
      client = new Client(url);
      room = await client.joinOrCreate("kudurru").catch(async () => client.joinOrCreate("my_room"));
      (window as any).KK = Object.assign((window as any).KK || {}, { client, room });

      log("Joined. Session:", room.sessionId);

      room.onMessage("ack", (m:any)=> log("ack:", m));
      room.onStateChange((st:any)=>{ (window as any).KK.state = st; });
      room.onLeave(()=> { log("room left"); if (joinBtn) joinBtn.disabled = false; });

      return room;
    } catch (e) {
      console.error("[KK][cli] join error:", e);
      alert("Join failed. Start the server (ws://localhost:2567) and try again.");
      throw e;
    } finally {
      joining = false;
      if (joinBtn && !wsOpen()) joinBtn.disabled = false;
    }
  }

  async function ensure(){ if (!wsOpen()) await join(); return room; }

  async function sendAdmin(type:string, payload:any={}) {
    const r = await ensure();
    try { r.send("admin", Object.assign({type}, payload)); }
    catch(e){ console.error("admin send failed", e); }
  }

  async function sendAction(type:string, payload:any={}) {
    const r = await ensure();
    try { r.send("action", Object.assign({type}, payload)); }
    catch(e){ console.error("action send failed", e); }
  }

  // Re-bind toolbar buttons with a clean listener each time
  rebind("join",   ()=> join());
  rebind("bots",   ()=> sendAdmin("ADD_BOTS", {count:3}));
  rebind("deal6",  ()=> sendAdmin("DEAL6"));
  rebind("reset",  ()=> sendAdmin("RESET_MATCH"));
  rebind("next",   ()=> sendAction("NEXT_PHASE"));
  rebind("reveal", ()=> sendAction("TOGGLE_REVEAL_AI", {value:true}));
  rebind("openlib",()=> alert("Library UI will open here (stub)."));

  // Console helpers for quick manual control
  (window as any).KK = Object.assign((window as any).KK || {}, { join, leave, sendAdmin, sendAction });

  log("client wiring ready");
})();







/* __KK_PHASE_UI_V1__ */
(() => {
  try {
    const log = (...a:any[]) => console.log("[KK][ui]", ...a);

    function findPhaseContainer(): HTMLElement | null {
      // Heuristic: the first .hzh-panel (left side) in the top row is your Phase panel.
      // Fallback: any element whose text begins with "Phase:".
      const panels = document.querySelectorAll<HTMLElement>(".hzh-panel");
      if (panels.length > 0) return panels[0];
      const all = Array.from(document.querySelectorAll<HTMLElement>("div,section,header"));
      const found = all.find(el => (el.textContent||"").trim().startsWith("Phase:"));
      return found || null;
    }

    function readActiveName(): string | undefined {
      // Pull whatever your layout shows as current active player; keep "P1" if we can't detect.
      const label = document.querySelector<HTMLElement>(".seat-card.active, .seat--active, .kk-active")?.textContent?.trim();
      return label && label.length < 20 ? label : undefined;
    }

    function setPhaseUI(phase?: string) {
      const host = findPhaseContainer();
      if (!host) return;
      const active = readActiveName() || "P1";
      const p = (phase && phase.length) ? phase : "—";
      const text = `Phase: ${p} — Active: ${active}`;
      // Replace only the leading "Phase: …" line, keep the rest of the panel intact.
      // Strategy: if it has a firstChild text node starting with "Phase:", rewrite it;
      // otherwise, inject/update a <span data-kk="phase-line"> at the start.
      const span = host.querySelector('[data-kk="phase-line"]') as HTMLElement | null;
      if (span) {
        span.textContent = text;
        return;
      }
      // Create or rewrite the first line in a safe way
      const first = host.firstChild;
      if (first && first.nodeType === Node.TEXT_NODE && (first.textContent||"").trim().startsWith("Phase:")) {
        first.textContent = text + " ";
      } else {
        const s = document.createElement("span");
        s.setAttribute("data-kk","phase-line");
        s.textContent = text;
        host.insertBefore(s, host.firstChild);
      }
    }

    function bindRoomObservers() {
      const KK:any = (window as any).KK || {};
      const room:any = KK.room;
      if (!room) { log("no room yet; observers will bind after JOINED"); return; }

      // On JOINED (already happened in your flow), ensure UI reflects default / current state
      setPhaseUI((KK.state && (KK.state as any).phase) || "Upkeep");

      // Listen for acks from our server wiring
      room.onMessage && room.onMessage("ack", (m:any) => {
        if (!m || !m.type) return;
        if (m.type === "NEXT_PHASE")  { setPhaseUI(m.phase); }
        if (m.type === "RESET_MATCH") { setPhaseUI("Upkeep"); }
        if (m.type === "DEAL6")       { /* no-op visually */ }
        if (m.type === "JOINED")      { setPhaseUI(((window as any).KK?.state as any)?.phase || "Upkeep"); }
      });

      // Also reflect server state changes, in case your schema later exposes `state.phase`
      room.onStateChange && room.onStateChange((st:any) => {
        if (st && (st as any).phase) setPhaseUI((st as any).phase);
      });

      log("phase observer bound (ui v1)");
    }

    // Bind now if we already have KK.room; otherwise bind after JOINED ack.
    if ((window as any).KK?.room) {
      bindRoomObservers();
    } else {
      // Attach a lightweight hook to bind once the client code writes KK.room
      const origDefine = Object.defineProperty;
      try {
        origDefine(window as any, "KK", {
          configurable: true,
          enumerable: true,
          set(v:any){
            (window as any).__kkShim = v;
            if (v && v.room) setTimeout(bindRoomObservers, 0);
          },
          get(){ return (window as any).__kkShim; }
        });
      } catch {}
    }
  } catch (e) {
    console.warn("[KK][ui] phase hotfix failed", e);
  }
})();

/* __KK_OBSERVERS_V6__ */
(() => {
  if ((window as any).__KK_OBSERVERS_V6__) return;
  (window as any).__KK_OBSERVERS_V6__ = true;

  const log = (...a:any[]) => console.log("[KK][ui]", ...a);

  // -- helpers --------------------------------------------------------------
  function norm(t:string){ return (t||"").replace(/\s+/g," ").trim(); }

  function findPhaseEl(): HTMLElement | null {
    // Try a few likely spots, else scan for a node whose text starts with "Phase:"
    const guesses = ["#kk-phase-text","#phaseText","[data-phase]"];
    for (const sel of guesses) { const el = document.querySelector(sel) as HTMLElement; if (el) return el; }
    const all = Array.from(document.querySelectorAll("div,span,p,h2,.h2h-box,.h2h-body")) as HTMLElement[];
    for (const el of all) if (/^Phase:/i.test(norm(el.textContent||""))) return el;
    return null;
  }

  function renderPhase(phase:string, active:string) {
    const el = findPhaseEl();
    if (!el) return;
    const text = `Phase: ${phase || "—"} — Active: ${active || "—"}`;
    if (norm(el.textContent||"") !== norm(text)) {
      el.textContent = text;
      el.setAttribute("aria-live","polite");
    }
  }

  function findAnalyzerBody(): HTMLElement | null {
    // The panel labeled "Analyzer" — find a sibling/body area near that heading.
    const nodes = Array.from(document.querySelectorAll("div,section,article")) as HTMLElement[];
    for (const n of nodes) {
      if (/^Analyzer$/i.test(norm(n.textContent||""))) {
        // Use the next sibling body/panel if present
        const parent = n.parentElement;
        if (!parent) break;
        // Prefer a nearby element with more content area
        const candidates = Array.from(parent.querySelectorAll(".h2h-body, .h2h-panel, div, p")) as HTMLElement[];
        for (const c of candidates) {
          const area = c.getBoundingClientRect();
          if (area.width > 200 && area.height > 40) return c;
        }
      }
    }
    // Fallback: the first decent-sized panel to the right side
    const panels = nodes.filter(n => (n.getBoundingClientRect().left > window.innerWidth*0.55));
    return (panels.find(p => p.getBoundingClientRect().height > 80) as HTMLElement) || null;
  }

  function tutorialCopy(phase:string){
    switch ((phase||"").toLowerCase()){
      case "upkeep": return "Upkeep refreshes resources. Hover pips on any card to learn costs. Click Next Phase to enter Main.";
      case "main":   return "Main: play a Character or Site from your hand. Click a card to select it. (UI demo: select toggles.)";
      case "battle": return "Battle: click your attacker, then an enemy to target. (UI demo only.)";
      case "end":    return "End: actions wrap up and control passes. Click Next Phase to loop back to Upkeep.";
      default:       return "Click Start Tutorial for guided steps.";
    }
  }

  function renderAnalyzer(phase:string){
    const body = findAnalyzerBody(); if (!body) return;
    const msg = "Tutorial — " + (phase || "Upkeep");
    const copy = tutorialCopy(phase || "Upkeep");
    // Try to respect existing structure; otherwise just set text
    if (body.firstElementChild && body.firstElementChild.tagName === "DIV") {
      body.firstElementChild.textContent = msg + "  ·  " + copy;
    } else {
      body.textContent = msg + " — " + copy;
    }
  }

  function isHandArea(el:Element|null){
    if (!el) return false;
    const t = (el.id||"") + " " + (el.className||"");
    return /hand/i.test(t) || /P1 Hand/i.test(el.textContent||"");
  }

  function relabelSeats(names:Record<string,string>){
    // find P1..P4 labels that are NOT under a "... Hand" area
    const all = Array.from(document.querySelectorAll("div,span,p")) as HTMLElement[];
    const map: Record<string,HTMLElement> = {};
    for (const el of all){
      const txt = norm(el.textContent||"");
      if (/^P[1-4]$/.test(txt) && !isHandArea(el.closest("*"))) map[txt] = el;
    }
    let botIdx = 1;
    for (const seat of ["P1","P2","P3","P4"]){
      const el = map[seat]; if (!el) continue;
      const proposed = names[seat] || (seat==="P2"||seat==="P3" ? `Bot ${botIdx++} 🤖` : seat.replace("P","Player "));
      if (el.textContent !== proposed) el.textContent = proposed;
    }
  }

  // Lightweight card interaction: toggle selection in the bottom panels
  function enableCardClicks(){
    document.addEventListener("click", (ev) => {
      const target = ev.target as HTMLElement;
      if (!target) return;
      const card = target.closest(".kk-card, .card, [data-card]") as HTMLElement | null;
      if (!card) return;
      card.classList.toggle("is-selected");
    }, { capture:false, passive:true });
  }

  // -- wire to room/acks/state ----------------------------------------------
  const KK:any = (window as any).KK || {};
  function bindToRoom(room:any){
    if (!room) return;
    try {
      // 1) listen to state (if server exposes fields via schema)
      const st:any = room.state as any;
      if (st && st.onChange){
        st.onChange(()=>{
          const phase = (st as any).phase || "";
          const active = (st as any).activeName || (st as any).active || "P1";
          renderPhase(phase, active);
          renderAnalyzer(phase);
          try {
            const names:Record<string,string> = {};
            const P = typeof st.players?.toJSON === "function" ? st.players.toJSON() : st.players;
            if (P) {
              let i = 1;
              for (const id in P){ names[`P${i}`] = P[id]?.name || `P${i}`; i++; }
            }
            relabelSeats(names);
          } catch {}
        });
        log("phase observer bound (v6:state)");
      }
    } catch {}

    // 2) also listen to ACKs so UI updates even if state fields aren’t synced
    room.onMessage("ack", (m:any) => {
      if (m?.type === "NEXT_PHASE") { renderPhase(m.phase || "", "P1"); renderAnalyzer(m.phase || ""); }
      if (m?.type === "RESET_MATCH"){ renderPhase("Upkeep","P1"); renderAnalyzer("Upkeep"); }
      if (m?.type === "ADD_BOTS")   { relabelSeats({}); }
      if (m?.type === "DEAL6")      { /* cards already visible; keep UI stable */ }
    });
  }

  // Attach once when the page has a room ready
  const attach = () => {
    const R = (window as any).KK?.room;
    if (R) { bindToRoom(R); log("observer installed (v6)"); enableCardClicks(); }
  };

  // Try immediately and also on a short delay (after join)
  attach();
  setTimeout(attach, 300);
})();






/* __KK_UI_V10__ */
(() => {
  if ((window as any).__KK_UI_V10__) return; (window as any).__KK_UI_V10__ = true;
  const W:any = window as any; const getRoom = () => W.KK?.room || null;

  function ensureBody(){ if(!document.body){ const b=document.createElement("body"); document.documentElement.appendChild(b); } }
  function banner(): HTMLElement {
    let b = document.getElementById("kk-phase-banner") as HTMLElement | null;
    if (!b) {
      ensureBody();
      b = document.createElement("div");
      b.id = "kk-phase-banner";
      b.style.cssText = "position:fixed;left:8px;top:6px;z-index:2147483647;pointer-events:none;color:#d9c28b;font:12px/1.2 ui-sans-serif,system-ui,Segoe UI,Roboto;";
      b.textContent = "Phase: —  Active: —";
      document.body.appendChild(b);
    }
    return b!;
  }

  function fromState(s:any){
    if (!s) return { phase:"Upkeep", activeIndex:0, names:[] as string[] };
    const phase = s.phase ?? "Upkeep";
    const ai = (s.activeIndex ?? 0);
    let names: string[] = [];
    try {
      const P:any = (typeof s.players?.toJSON === "function") ? s.players.toJSON() : s.players;
      if (P) {
        names = Object.keys(P).map(k => P[k]?.name || k);
      }
    } catch {}
    return { phase, activeIndex: ai, names };
  }

  function applyUi(p:any){
    const b = banner();
    const phase = p?.phase ?? "Upkeep";
    const ai = (p?.activeIndex ?? 0) + 1;
    const names: string[] = Array.isArray(p?.names) ? p.names : [];
    b.textContent = `Phase: ${phase} — Active: P${ai}` + (names.length ? `  |  Players: ${names.join(", ")}` : "");
  }
  (window as any).__KK_UI_V10_APPLY__ = applyUi; // used by early ui listener

  function bind(){
    const room = getRoom(); if(!room) return;

    // State-based updates (works even if server never sends "ui")
    try {
      room.onStateChange((st:any) => {
        const info = fromState(st);
        applyUi(info);
      });
    } catch {}

    // Still listen for explicit "ui" & "ack" messages
    try { room.onMessage("ui",  (m:any)=> applyUi(m)); } catch {}
    try { room.onMessage("ack", (m:any)=> {
      if(m?.type==="NEXT_PHASE") applyUi({ phase:m.phase });
      if(m?.type==="RESET_MATCH") applyUi({ phase:"Upkeep", activeIndex:0 });
    }); } catch {}

    // Visual click highlight for cards (no gameplay)
    const css = `.kk-sel{ outline:2px solid rgba(255,214,101,.55); box-shadow:0 0 8px rgba(227,178,60,.35); border-radius:.6rem; }`;
    const st = document.createElement("style"); st.textContent = css; document.head.appendChild(st);
    document.addEventListener("click", (ev) => {
      const el = (ev.target as HTMLElement)?.closest(".card, .kk-card, [data-card]") as HTMLElement | null;
      if (!el) return;
      el.classList.toggle("kk-sel");
    });

    console.log("[KK][ui] overlay bound (v10b)");
  }

  const iv = setInterval(()=>{ if(getRoom()){ clearInterval(iv); bind(); } }, 300);
  console.log("[KK][ui] overlay installed (v10b)");
})();

/* __KK_CARD_V1__ */
(() => {
  if ((window as any).__KK_CARD_V1__) return; (window as any).__KK_CARD_V1__ = true;
  const W:any = window as any;

  function css(){
    if (document.getElementById('kk-card-css')) return;
    const s = document.createElement('style'); s.id='kk-card-css';
    s.textContent = `
    .kk-card{ position:relative; perspective: 1000px; }
    .kk-card3d{ position:relative; width:100%; height:100%; transform-style:preserve-3d; transition:transform .35s ease; }
    .kk-card.is-flipped .kk-card3d{ transform: rotateY(180deg); }
    .kk-face{ position:absolute; inset:0; backface-visibility:hidden; border-radius:.75rem; overflow:hidden; }
    .kk-front{
      background:
        url("/frames/character.png") center/cover no-repeat,
        linear-gradient(180deg,#0f1320,#141a2a);
      color:#e6d7a6;
    }
    .kk-back{
      transform:rotateY(180deg);
      background:radial-gradient(120% 120% at 30% 10%, #1b2438, #0d1220);
      color:#cfd9e6;
    }
    .kk-title{ font-weight:700; letter-spacing:.02em; padding:.4rem .55rem; background:rgba(0,0,0,.35); border-bottom:1px solid rgba(255,214,101,.2);}
    .kk-stats{ display:flex; gap:.35rem; padding:.35rem .55rem; flex-wrap:wrap}
    .kk-stat{ font-size:.72rem; padding:.18rem .35rem; border-radius:.4rem; border:1px solid rgba(255,214,101,.25); background:rgba(255,214,101,.06)}
    .kk-rules{ font-size:.8rem; line-height:1.15rem; padding:.6rem; white-space:pre-wrap;}
    .kk-chip{ position:absolute; right:.45rem; top:.45rem; font-size:.72rem; padding:.15rem .5rem; border-radius:999px; border:1px solid rgba(255,214,101,.35); background:rgba(0,0,0,.35);}
    `;
    document.head.appendChild(s);
  }

  function getRoom(){ return W.KK?.room || null; }

  // Try to find card data in KK.state.hands by id
  function getCardData(id:string): any{
    if(!id) return null;
    try{
      const st:any = W.KK?.state;
      const H = st?.hands || {};
      for(const pid in H){
        const v:any = (H as any)[pid];
        const arr = Array.isArray(v) ? v : (typeof v?.toJSON === 'function' ? Object.values(v.toJSON()) : []);
        for(const c of arr){ if(c?.id===id) return c; }
      }
    }catch{}
    return null;
  }

  function txt(el:Element|undefined|null){ return (el as HTMLElement)?.textContent?.trim() || ''; }

  function buildFaceFront(card:any, base:HTMLElement){
    const f = document.createElement('div'); f.className='kk-face kk-front';
    const name = card?.name || base.getAttribute('data-name') || txt(base.querySelector('[data-name]')) || 'Unknown';
    const rarity = card?.rarity || base.getAttribute('data-rarity') || '';
    const atk = (card?.atk ?? base.getAttribute('data-atk')) ?? undefined;
    const def = (card?.def ?? base.getAttribute('data-def')) ?? undefined;
    const type = card?.type || base.getAttribute('data-type') || '';
    const rules = base.getAttribute('data-text') || txt(base.querySelector('[data-text]')) || '';
    f.innerHTML = `
      <div class="kk-title">${name}</div>
      <div class="kk-chip">${type || ''} ${rarity? '• '+rarity : ''}</div>
      <div class="kk-stats">
        ${atk!==undefined ? `<div class="kk-stat">ATK ${atk}</div>` : ``}
        ${def!==undefined ? `<div class="kk-stat">DEF ${def}</div>` : ``}
      </div>
      <div class="kk-rules">${rules}</div>
    `;
    return f;
  }

  function buildFaceBack(card:any, base:HTMLElement){
    const b = document.createElement('div'); b.className='kk-face kk-back';
    const name = card?.name || base.getAttribute('data-name') || 'Details';
    const text = base.getAttribute('data-text') || card?.text || 'No additional details.';
    const meta = [
      ['Type', card?.type || base.getAttribute('data-type') || '—'],
      ['Rarity', card?.rarity || base.getAttribute('data-rarity') || '—'],
      ['ID', card?.id || base.getAttribute('data-card-id') || '—']
    ].map(([k,v])=>`<div class="kk-stat"><b>${k}</b> ${v}</div>`).join('');
    b.innerHTML = `
      <div class="kk-title">${name} — Details</div>
      <div class="kk-stats">${meta}</div>
      <div class="kk-rules">${text}</div>
    `;
    return b;
  }

  function upgradeCard(el:Element){
    const host = el as HTMLElement;
    if(host.classList.contains('kk-card')) return;

    // we need a stable id for PLAY
    let id = host.getAttribute('data-card-id') || host.getAttribute('data-id') || host.id || '';
    if (!id) { id = 'c_'+Math.random().toString(36).slice(2); host.setAttribute('data-card-id', id); }

    host.classList.add('kk-card');
    const wrap = document.createElement('div'); wrap.className='kk-card3d';

    const data = getCardData(id);
    const front = buildFaceFront(data, host);
    const back  = buildFaceBack(data, host);

    // preserve current footprint
    const rect = host.getBoundingClientRect();
    if (!host.style.width  && rect.width)  host.style.width  = rect.width+'px';
    if (!host.style.height && rect.height) host.style.height = rect.height+'px';

    // swap content for our 3D faces
    host.replaceChildren(); wrap.appendChild(front); wrap.appendChild(back); host.appendChild(wrap);

    host.addEventListener('click', (e)=>{ host.classList.toggle('is-flipped'); e.stopPropagation(); });
    host.addEventListener('dblclick', (e)=>{
      e.stopPropagation();
      try {
        getRoom()?.send?.('action', { type:'PLAY', cardId: id });
        console.log('[KK][card] PLAY sent', id);
      } catch(err){ console.warn('[KK][card] PLAY send failed', err); }
    });
  }

  function scan(){ document.querySelectorAll('.card, .kk-card, [data-card], [data-card-id]').forEach(upgradeCard); }

  function observe(){
    const mo = new MutationObserver((muts)=>{
      for(const m of muts){
        m.addedNodes?.forEach(n=>{
          if(!(n instanceof HTMLElement)) return;
          if(n.matches('.card, .kk-card, [data-card], [data-card-id]')) upgradeCard(n);
          n.querySelectorAll?.('.card, .kk-card, [data-card], [data-card-id]').forEach(upgradeCard);
        });
      }
    });
    mo.observe(document.documentElement, { childList:true, subtree:true });
  }

  css(); scan(); observe();
  console.log('[KK][card] flip+play installed (v1)');
})();


