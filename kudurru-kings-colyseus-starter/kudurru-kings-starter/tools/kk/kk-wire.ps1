Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
function Write-UTF8($Path,$Text){
  $dir=[System.IO.Path]::GetDirectoryName($Path)
  if($dir -and -not (Test-Path $dir)){ [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  [System.IO.File]::WriteAllText($Path,$Text,[System.Text.UTF8Encoding]::new($false))
}
$Repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ServerRoom = Join-Path $Repo "server\src\rooms\KudurruRoom.ts"
$ClientMain = Join-Path $Repo "client\src\main.ts"
if(!(Test-Path $ServerRoom)){ throw "Not found: $ServerRoom" }
if(!(Test-Path $ClientMain)){ throw "Not found: $ClientMain" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item $ServerRoom "$ServerRoom.bak.$stamp" -Force
Copy-Item $ClientMain "$ClientMain.bak.$stamp" -Force

# ======== SERVER PATCH ========
$room = Get-Content -Raw $ServerRoom

# Ensure MapSchema import once
if($room -notmatch '\bMapSchema\b'){
  $room = "import { MapSchema } from ""@colyseus/schema"";`r`n$room"
}

# Inject helper methods after `export class KudurruRoom {`
if($room -notmatch 'kkEnsureStateShape\('){
  $helpers = @"
  // ===== KK Helpers (auto-injected) =====
  private kkEnsureStateShape() {
    const s:any = this.state as any;
    if (!s.players) s.players = (typeof MapSchema !== "undefined") ? new MapSchema<any>() : (s.players || {});
    if (!s.hands)   s.hands   = (typeof MapSchema !== "undefined") ? new MapSchema<any>() : (s.hands || {});
    if (!s.table)   s.table   = {};
    if (!s.table.pools) s.table.pools = {};
    if (s.phase == null) s.phase = "Upkeep";
    if (s.activeIndex == null) s.activeIndex = 0;
  }
  private kkPhaseNext() {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    const order = ["Upkeep","Main","Battle","End"];
    const i = order.indexOf(s.phase);
    s.phase = order[(i<0?0:i+1)%order.length];
  }
  private kkAddBotSeat() {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    const id = `bot_${Math.random().toString(36).slice(2,7)}`;
    s.players[id] = { id, name: `Bot ${Object.keys((s.players as any)).length} 🤖`, ai: true, hand: [] };
    try { if (!s.hands[id]) s.hands[id] = []; } catch {}
    console.log("[KK][srv] bot seated:", id);
  }
  private kkResetMatch() {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    s.table.pools = {};
    const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players;
    for (const pid in P) { try { s.hands[pid] = []; } catch {} }
    s.phase = "Upkeep";
    s.activeIndex = 0;
    console.log("[KK][srv] match reset");
  }
  private kkDeal(pid:string, n:number=6) {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    s.hands[pid] = s.hands[pid] || [];
    for (let i=0;i<n;i++){
      const idx = Math.floor(Math.random()*999);
      s.hands[pid].push({ id:`c_${Date.now()}_${i}`, name:`Card ${idx}`, type:"Character", rarity:"Mid", atk:0, def:0 });
    }
  }
  // ===== /helpers =====
"@
  $classOpen = [regex]::Match($room,'export\s+class\s+KudurruRoom[^{]*\{',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if(-not $classOpen.Success){ throw "Can't find 'export class KudurruRoom {'" }
  $insertPos = $classOpen.Index + $classOpen.Length
  $room = $room.Substring(0,$insertPos) + "`r`n$helpers`r`n" + $room.Substring($insertPos)
}

# Preserve original handleAdmin
if($room -notmatch 'handleAdmin_core\s*='){
  $script:kk_first = $true
  $room = [regex]::Replace($room,'handleAdmin\s*=\s*\(',
    { if($script:kk_first){ $script:kk_first=$false; 'handleAdmin_core = (' } else { $args[0].Value } })
}

# Add admin/action wrappers
if($room -notmatch 'kkHandleAction\('){
  $wrappers = @"
  private kkHandleAdmin = (_client:any, msg:any) => {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    const t = msg?.type;
    console.log("[KK][srv] admin:", t, msg);
    switch(t){
      case "ADD_BOTS":       { const n = Math.max(1, Math.min(3, msg?.count ?? 1)); for (let i=0;i<n;i++) this.kkAddBotSeat(); _client.send?.("ack",{ok:true,type:"ADD_BOTS"}); return; }
      case "RESET_MATCH":    { this.kkResetMatch(); _client.send?.("ack",{ok:true,type:"RESET_MATCH"}); return; }
      case "DEAL6":          { const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players; for (const pid in P) this.kkDeal(pid,6); _client.send?.("ack",{ok:true,type:"DEAL6"}); return; }
      case "SET_POOLS":
      case "SEED_POOLS":     { s.table.pools ||= {}; Object.assign(s.table.pools, msg?.pools || {}); _client.send?.("ack",{ok:true,type:"SET_POOLS"}); return; }
    }
    try{ if (typeof this.handleAdmin_core === "function") { return this.handleAdmin_core(_client, msg); } }catch(e){ console.warn("[KK][srv] handleAdmin_core error:",e); }
  };
  private kkHandleAction = (_client:any, msg:any) => {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    const t = msg?.type;
    console.log("[KK][srv] action:", t, msg);
    switch(t){
      case "PING":           { _client.send?.("ack",{ok:true,type:"PING",nonce:msg?.nonce}); return; }
      case "NEXT_PHASE":     { this.kkPhaseNext(); _client.send?.("ack",{ok:true,type:"NEXT_PHASE",phase:s.phase}); return; }
      case "DEAL6":          { const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players; for (const pid in P) this.kkDeal(pid,6); _client.send?.("ack",{ok:true,type:"DEAL6"}); return; }
      case "ADD_BOTS":       { const n = Math.max(1, Math.min(3, msg?.count ?? 1)); for (let i=0;i<n;i++) this.kkAddBotSeat(); _client.send?.("ack",{ok:true,type:"ADD_BOTS"}); return; }
      case "RESET_MATCH":    { this.kkResetMatch(); _client.send?.("ack",{ok:true,type:"RESET_MATCH"}); return; }
      case "TOGGLE_REVEAL_AI": { s.revealAI = !!msg?.value; _client.send?.("ack",{ok:true,type:"TOGGLE_REVEAL_AI",value:s.revealAI}); return; }
    }
  };
"@
  $room = $room + "`r`n$wrappers`r`n"
}

# Wire onCreate to the wrappers (once)
if($room -notmatch 'onMessage\(\s*\"admin\".*kkHandleAdmin'){
  $room = [regex]::Replace(
    $room,
    'onCreate\s*\(.*?\)\s*\{',
    {
      $m = $args[0].Value
      "$m`r`n    // KK wiring (idempotent)`r`n    try{ this.onMessage(""admin"",  (c:any,m:any)=> this.kkHandleAdmin(c,m)); }catch{}`r`n    try{ this.onMessage(""action"", (c:any,m:any)=> this.kkHandleAction(c,m)); }catch{}"
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
}
Write-UTF8 $ServerRoom $room

# ======== CLIENT PATCH ========
$main = Get-Content -Raw $ClientMain
if($main -notmatch '__KK_WIRED_CLIENT_V2__'){
  $wire = @"
(() => {
  if ((window as any).__KK_WIRED_CLIENT_V2__) return;
  (window as any).__KK_WIRED_CLIENT_V2__ = true;
  const log = (...a:any[]) => console.log("[KK][cli]", ...a);
  let client:any = (window as any).KK?.client || null;
  let room:any   = (window as any).KK?.room   || null;
  async function join(){
    try{
      const { Client } = await import("colyseus.js");
      const url = (location.protocol==="https:"?"wss":"ws")+"://"+location.hostname+":2567";
      client = new Client(url);
      (window as any).KK = (window as any).KK || {};
      (window as any).KK.client = client;
      log("Joining room 'kudurru'…");
      room = await client.joinOrCreate("kudurru").catch(async ()=>{
        log("'kudurru' not available, trying 'my_room'…");
        return await client.joinOrCreate("my_room");
      });
      (window as any).KK.room = room;
      log("Joined. Session:", room.sessionId);
      room.onMessage("ack", (m:any)=> log("ack:", m));
      room.onStateChange((st:any)=>{ (window as any).KK.state = st; });
      try{ room.send("toggle", {key:"revealAI", value:true}); }catch{}
    } catch(e){ console.error("[KK][cli] join error:", e); alert("Join failed. See console."); }
  }
  function sendBoth(type:string, payload:any={}){
    if(!room){ alert("Join first."); return; }
    const msg = Object.assign({type}, payload);
    try { room.send("admin",  msg); } catch(e){ console.warn("admin send failed", e); }
    try { room.send("action", msg); } catch(e){ console.warn("action send failed", e); }
  }
  function bind(id:string, fn:()=>void){
    const el = document.getElementById(id);
    if(!el){ log("missing button #"+id); return; }
    el.addEventListener("click", ()=>{ try{ log("click #"+id); fn(); } catch(e){ console.error("[KK][cli] click error",e); } });
  }
  bind("join",   join);
  bind("next",   ()=> sendBoth("NEXT_PHASE"));
  bind("bots",   ()=> sendBoth("ADD_BOTS", {count:3}));
  bind("deal6",  ()=> sendBoth("DEAL6"));
  bind("reset",  ()=> sendBoth("RESET_MATCH"));
  bind("reveal", ()=> sendBoth("TOGGLE_REVEAL_AI", {value:true}));
  bind("openlib",()=> { alert("Library UI hook OK (stub)"); });
  setTimeout(()=>{ if(room) sendBoth("PING", {nonce: Date.now()}); }, 1500);
  log("client wiring installed");
})();
"@
  $main += "`r`n/* __KK_WIRED_CLIENT_V2__ */`r`n$wire`r`n"
  Write-UTF8 $ClientMain $main
}

Write-Host "✅ kk-wire applied. Backups created." -ForegroundColor Green