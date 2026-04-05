/** H2H shell + safe wiring + light render helpers */
export function buildShell(): string {
  return `
  <div class="h2h-wrap">
    <h2 class="h2h-title">KUDURRU KINGS — Head-to-Head Client (4 Players)</h2>

    <div class="h-bar">
      <div class="h-buttons">
        <button id="btn-join"       class="btn">Join Room</button>
        <button id="btn-next"       class="btn">Next Phase</button>
        <button id="btn-bots"       class="btn">Add 3 Bots</button>
        <button id="btn-deal6"      class="btn">Deal 6</button>
        <button id="btn-reset"      class="btn">Reset Match</button>
        <button id="btn-aitick"     class="btn">AI Step</button>
        <button id="btn-reveal"     class="btn">Toggle Reveal AI</button>
        <button id="btn-sandbox"    class="btn">Toggle Sandbox</button>
        <button id="btn-tutor"      class="btn">Start Tutorial</button>
        <button id="btn-library"    class="btn">Open Library</button>
      </div>
      <div class="h-right slider">
        <span>Zoom</span>
        <input id="zoom" type="range" min="0.75" max="1.10" step="0.05" value="0.85" />
      </div>
    </div>

    <div class="filter-row">
      <span class="muted">Type:</span>
      <div class="pillbar" id="type-pills">
        <span class="pill active" data-type="All">All</span>
        <span class="pill" data-type="Boss">Boss</span>
        <span class="pill" data-type="Character">Character</span>
        <span class="pill" data-type="Enemy">Enemy</span>
        <span class="pill" data-type="Pet">Pet</span>
        <span class="pill" data-type="Relic">Relic</span>
        <span class="pill" data-type="Site">Site</span>
        <span class="pill" data-type="Rune">Rune</span>
      </div>
      <div style="flex:1"></div>
      <span class="muted">Rarity</span>
      <div class="pillbar" id="rarity-pills">
        <span class="pill active" data-rarity="All">All</span>
        <span class="pill" data-rarity="Low">Low</span>
        <span class="pill" data-rarity="Mid">Mid</span>
        <span class="pill" data-rarity="Rare">Rare</span>
      </div>
    </div>

    <div class="board-top">
      <div id="phase" class="panel"><b>Phase:</b> <span id="phase-line" class="muted">—</span></div>
      <div class="panel"><h3>Analyzer</h3><div id="analyzer" class="muted">Click Start Tutorial for guided steps.</div></div>
    </div>

    <div class="arena">
      <div class="rail"></div>
      <div class="plaza"><div class="t">Kudurru Plaza</div><div class="s">Capture to unlock Law slot</div></div>

      <div class="seat p1"><div id="p1-name">P1</div><div class="sub" id="p1-sub">Influence 0 Tribute 0 Oaths 0/2</div></div>
      <div class="seat p2"><div id="p2-name">P2</div><div class="sub" id="p2-sub">Influence 0 Tribute 0 Oaths 0/2</div></div>
      <div class="seat p3"><div id="p3-name">P3</div><div class="sub" id="p3-sub">Influence 0 Tribute 0 Oaths 0/2</div></div>
      <div class="seat p4"><div id="p4-name">P4</div><div class="sub" id="p4-sub">Influence 0 Tribute 0 Oaths 0/2</div></div>
    </div>

    <div class="hands">
      <div class="hand panel">
        <h4>P1 Hand (You)</h4>
        <div id="hand-p1" class="cards"></div>
      </div>
      <div class="hand panel">
        <h4>P2 / P3 Hands</h4>
        <div id="hand-p2" class="cards" style="margin-bottom:8px"></div>
        <div id="hand-p3" class="cards"></div>
      </div>
    </div>

    <div class="cmd">
      <button class="btn" id="cmd-play">Play</button>
      <button class="btn" id="cmd-move">Move</button>
      <button class="btn" id="cmd-invoke">Invoke</button>
      <button class="btn" id="cmd-end">End</button>
    </div>
  </div>`;
}

/** helpers */
const $ = (s:string,root:Document|HTMLElement=document)=> root.querySelector(s) as HTMLElement|null;
function on(id:string, type:string, fn:EventListenerOrEventListenerObject){ const el = document.getElementById(id); if(el) el.addEventListener(type,fn); }
function setZoomInput(){
  const z = document.getElementById("zoom") as HTMLInputElement|null;
  if(!z) return;
  const apply = (v:string)=> document.documentElement.style.setProperty("--card-scale", v);
  apply(z.value); z.addEventListener("input", ()=>apply(z.value));
}

export type Handlers = {
  onJoin: () => void|Promise<void>;
  onNext: () => void;
  onBots: () => void;
  onDeal6: () => void;
  onReset: () => void;
  onAiStep: () => void;
  onReveal: () => void;
  onSandbox: () => void;
  onTutorial: () => void;
  onOpenLibrary: () => void;
  onCmd?: (cmd:"Play"|"Move"|"Invoke"|"End") => void;
};

export function wireControls(h:Handlers){
  setZoomInput();
  on("btn-join","click",  ()=> h.onJoin());
  on("btn-next","click",  ()=> h.onNext());
  on("btn-bots","click",  ()=> h.onBots());
  on("btn-deal6","click", ()=> h.onDeal6());
  on("btn-reset","click", ()=> h.onReset());
  on("btn-aitick","click",()=> h.onAiStep());
  on("btn-reveal","click",()=> h.onReveal());
  on("btn-sandbox","click",()=> h.onSandbox());
  on("btn-tutor","click",  ()=> h.onTutorial());
  on("btn-library","click",()=> h.onOpenLibrary());
  on("cmd-play","click", ()=> h.onCmd?.("Play"));
  on("cmd-move","click", ()=> h.onCmd?.("Move"));
  on("cmd-invoke","click",()=> h.onCmd?.("Invoke"));
  on("cmd-end","click",  ()=> h.onCmd?.("End"));
}

/** lightweight render hooks (state → UI) */
export function renderState(state:any, room:any){
  try{
    // Phase line
    const players = toArray(state?.players);
    const activeIdx = state?.activeIndex ?? 0;
    const active = players[activeIdx];
    setHTML("#phase-line", `Turn ${state?.turn ?? 1} — ${state?.phase ?? "Upkeep"} — Active: <b>${escape(active?.name ?? "—")}</b>`);

    // Seat labels
    seat(1, players[0]); seat(2, players[1]); seat(3, players[2]); seat(4, players[3]);

    // Hands (uses simple chips; swap to your card renderer if you prefer)
    renderHand("#hand-p1", players[0]?.hand);
    renderHand("#hand-p2", players[1]?.hand);
    renderHand("#hand-p3", players[2]?.hand);
  }catch(_e){}
}

function seat(i:number, p:any){
  setText(`#p${i}-name`, p?.name ? `${p.name}${p.ai?" 🤖":""}` : `P${i}`);
  setText(`#p${i}-sub`, `Influence ${p?.inf??0} Tribute ${p?.trib??0} Oaths ${p?.oaths??0}/2`);
}

function renderHand(sel:string, cards:any[]){
  const host = $(sel); if(!host){return;}
  const items = (cards||[]).slice(0,12).map((c:any)=>`<div class="card-mini" title="${escape(c?.name||"")}">${escape((c?.name||"").slice(0,18)||"—")}</div>`).join("");
  host.innerHTML = items || `<span class="muted">(empty)</span>`;
}

/* utils */
function setText(sel:string, txt:string){ const el = $(sel); if(el) el.textContent = txt; }
function setHTML(sel:string, html:string){ const el = $(sel); if(el) el.innerHTML = html; }
function escape(s:any){ return String(s??"").replace(/[&<>"]/g,(ch)=> ch==="&"?"&amp;": ch=="<"?"&lt;": ch==">"?"&gt;":"&quot;"); }
function toArray(mapish:any){ const out:any[]=[]; if(!mapish) return out;
  if(typeof mapish.forEach==="function"){ mapish.forEach((v:any,k:any)=> out.push({id:k,...v})); return out; }
  if(typeof mapish.toJSON==="function"){ const o = mapish.toJSON(); for(const k in o) out.push({id:k,...o[k]}); return out; }
  for(const k in mapish) out.push({id:k,...mapish[k]}); return out;
}
