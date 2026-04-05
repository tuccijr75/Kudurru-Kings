# kk-fix.ps1  — patch server+client wiring (PowerShell 7 safe, no nested here-strings)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-UTF8([string]$Path,[string]$Text){
  $dir=[System.IO.Path]::GetDirectoryName($Path)
  if($dir -and -not (Test-Path $dir)){ [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  [System.IO.File]::WriteAllText($Path,$Text,[System.Text.UTF8Encoding]::new($false))
}
function Lines([string[]]$a){ ($a -join "`r`n") }

function Find-RepoRoot {
  $cur = Get-Item (Get-Location).Path
  for($i=0;$i -lt 6;$i++){
    $clientMain = Join-Path $cur.FullName "client\src\main.ts"
    $serverRoom = Join-Path $cur.FullName "server\src\rooms\KudurruRoom.ts"
    if( (Test-Path $clientMain) -and (Test-Path $serverRoom) ){ return $cur.FullName }
    if(-not $cur.Parent){ break }
    $cur = $cur.Parent
  }
  throw "Could not find repo root (needs client\src\main.ts and server\src\rooms\KudurruRoom.ts)."
}

$Root  = Find-RepoRoot
$ServerRoom = Join-Path $Root "server\src\rooms\KudurruRoom.ts"
$ClientMain = Join-Path $Root "client\src\main.ts"
if(!(Test-Path $ServerRoom)){ throw "Not found: $ServerRoom" }
if(!(Test-Path $ClientMain)){ throw "Not found: $ClientMain" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item $ServerRoom "$ServerRoom.bak.$stamp" -Force
Copy-Item $ClientMain "$ClientMain.bak.$stamp" -Force

# ===================== SERVER PATCH =====================
$room = Get-Content -Raw $ServerRoom

# Ensure MapSchema import (prepend once if missing)
if($room -notmatch '\bMapSchema\b'){
  $room = "import { MapSchema } from ""@colyseus/schema"";`r`n" + $room
}

# Helpers (only if not already present)
if($room -notmatch 'kkEnsureStateShape\s*\('){
  $m = [regex]::Match($room,'export\s+class\s+KudurruRoom[^{]*\{',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if(-not $m.Success){ throw "Can't find 'export class KudurruRoom {' in $ServerRoom" }
  $insertPos = $m.Index + $m.Length

  $helpers = Lines @(
'  // ==== KK helpers & wrappers (auto-injected) ===================================',
'  private kkEnsureStateShape(): void {',
'    const s: any = this.state as any;',
'    try { if (!s.players) s.players = new MapSchema<any>(); } catch { s.players = s.players || {}; }',
'    try { if (!s.hands)   s.hands   = new MapSchema<any>(); } catch { s.hands   = s.hands   || {}; }',
'    if (!s.table) s.table = {};',
'    if (!s.table.pools) s.table.pools = {};',
'    if (s.phase == null) s.phase = "Upkeep";',
'    if (s.activeIndex == null) s.activeIndex = 0;',
'  }',
'',
'  private kkPhaseNext(): void {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    const order = ["Upkeep","Main","Battle","End"];',
'    const i = order.indexOf(s.phase);',
'    s.phase = order[(i < 0 ? 0 : i + 1) % order.length];',
'  }',
'',
'  private kkAddBotSeat(): void {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    const id = "bot_" + Math.random().toString(36).slice(2,7);',
'    const count = (typeof (s.players as any)?.toJSON === "function"',
'      ? Object.keys((s.players as any).toJSON()).length',
'      : Object.keys(s.players || {}).length);',
'    s.players[id] = { id: id, name: "Bot " + (count + 1) + " 🤖", ai: true, hand: [] };',
'    try { if (!s.hands[id]) s.hands[id] = []; } catch {}',
'    console.log("[KK][srv] bot seated:", id);',
'  }',
'',
'  private kkResetMatch(): void {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    s.table = s.table || {};',
'    s.table.pools = s.table.pools || {};',
'    const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players;',
'    for (const pid in P) { try { s.hands[pid] = []; } catch {} }',
'    s.phase = "Upkeep";',
'    s.activeIndex = 0;',
'    console.log("[KK][srv] match reset");',
'  }',
'',
'  private kkDeal(pid: string, n: number = 6): void {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    s.hands[pid] = s.hands[pid] || [];',
'    for (let i = 0; i < n; i++) {',
'      const idx = Math.floor(Math.random() * 999);',
'      s.hands[pid].push({ id: "c_" + Date.now() + "_" + pid + "_" + i, name: "Card " + idx, type: "Character", rarity: "Mid", atk: 0, def: 0 });',
'    }',
'  }',
'',
'  private kkSafeAck(client: any, payload: any): void {',
'    try { if (client && typeof client.send === "function") client.send("ack", payload); } catch {}',
'  }',
'',
'  private kkHandleAdmin = (_client: any, msg: any): void => {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    const t = msg && msg.type;',
'    console.log("[KK][srv] admin:", t, msg);',
'    switch (t) {',
'      case "ADD_BOTS": {',
'        const n = Math.max(1, Math.min(3, (msg && msg.count) ? msg.count : 1));',
'        for (let i = 0; i < n; i++) this.kkAddBotSeat();',
'        this.kkSafeAck(_client, { ok: true, type: "ADD_BOTS" });',
'        return;',
'      }',
'      case "RESET_MATCH": {',
'        this.kkResetMatch();',
'        this.kkSafeAck(_client, { ok: true, type: "RESET_MATCH" });',
'        return;',
'      }',
'      case "DEAL6": {',
'        const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players;',
'        for (const pid in P) this.kkDeal(pid, 6);',
'        this.kkSafeAck(_client, { ok: true, type: "DEAL6" });',
'        return;',
'      }',
'      case "SET_POOLS":',
'      case "SEED_POOLS": {',
'        s.table = s.table || {};',
'        s.table.pools = s.table.pools || {};',
'        const src = (msg && msg.pools) ? msg.pools : {};',
'        for (const k in src) { s.table.pools[k] = src[k]; }',
'        this.kkSafeAck(_client, { ok: true, type: t });',
'        return;',
'      }',
'    }',
'    try {',
'      // @ts-ignore',
'      if (typeof this.handleAdmin_core === "function") { /* @ts-ignore */ return this.handleAdmin_core(_client, msg); }',
'    } catch (e) { console.warn("[KK][srv] handleAdmin_core error:", e); }',
'  };',
'',
'  private kkHandleAction = (_client: any, msg: any): void => {',
'    this.kkEnsureStateShape();',
'    const s: any = this.state as any;',
'    const t = msg && msg.type;',
'    console.log("[KK][srv] action:", t, msg);',
'    switch (t) {',
'      case "PING":',
'        this.kkSafeAck(_client, { ok: true, type: "PING", nonce: msg && msg.nonce }); return;',
'      case "NEXT_PHASE":',
'        this.kkPhaseNext(); this.kkSafeAck(_client, { ok: true, type: "NEXT_PHASE", phase: s.phase }); return;',
'      case "DEAL6": {',
'        const P = typeof s.players?.toJSON === "function" ? s.players.toJSON() : s.players;',
'        for (const pid in P) this.kkDeal(pid, 6);',
'        this.kkSafeAck(_client, { ok: true, type: "DEAL6" }); return;',
'      }',
'      case "ADD_BOTS": {',
'        const n = Math.max(1, Math.min(3, (msg && msg.count) ? msg.count : 1));',
'        for (let i = 0; i < n; i++) this.kkAddBotSeat();',
'        this.kkSafeAck(_client, { ok: true, type: "ADD_BOTS" }); return;',
'      }',
'      case "RESET_MATCH":',
'        this.kkResetMatch(); this.kkSafeAck(_client, { ok: true, type: "RESET_MATCH" }); return;',
'      case "TOGGLE_REVEAL_AI":',
'        s.revealAI = !!(msg && msg.value); this.kkSafeAck(_client, { ok: true, type: "TOGGLE_REVEAL_AI", value: s.revealAI }); return;',
'    }',
'  };',
'  // ==== /KK helpers & wrappers ==============================================='
  )

  $room = $room.Insert($insertPos, "`r`n$helpers`r`n")
}

# Ensure onCreate wires messages
if($room -match 'onCreate\s*\([^\)]*\)\s*\{'){
  if($room -notmatch 'onMessage\(\s*"admin"'){
    $room = [regex]::Replace(
      $room,
      'onCreate\s*\([^\)]*\)\s*\{',
      { $m = $args[0].Value; "$m`r`n    // KK wiring`r`n    this.onMessage(""admin"",  (c: any, m: any) => this.kkHandleAdmin(c, m));`r`n    this.onMessage(""action"", (c: any, m: any) => this.kkHandleAction(c, m));" },
      [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
  }
} else {
  $m2 = [regex]::Match($room,'export\s+class\s+KudurruRoom[^{]*\{',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $pos2 = $m2.Index + $m2.Length
  $stub = Lines @(
'  public onCreate(options: any): void {',
'    // KK wiring',
'    this.onMessage("admin",  (c: any, m: any) => this.kkHandleAdmin(c, m));',
'    this.onMessage("action", (c: any, m: any) => this.kkHandleAction(c, m));',
'  }'
  )
  $room = $room.Insert($pos2, "`r`n$stub`r`n")
}

Write-UTF8 $ServerRoom $room

# ===================== CLIENT PATCH =====================
$main = Get-Content -Raw $ClientMain
if($main -notmatch '__KK_WIRED_CLIENT_V2__'){
  $wire = Lines @(
'/* __KK_WIRED_CLIENT_V2__ */',
'(() => {',
'  if ((window as any).__KK_WIRED_CLIENT_V2__) return;',
'  (window as any).__KK_WIRED_CLIENT_V2__ = true;',
'  const log = (...a:any[]) => console.log("[KK][cli]", ...a);',
'  let client:any = (window as any).KK?.client || null;',
'  let room:any   = (window as any).KK?.room   || null;',
'',
'  async function join(){',
'    try{',
'      const { Client } = await import("colyseus.js");',
'      const url = (location.protocol==="https:"?"wss":"ws")+"://"+location.hostname+":2567";',
'      client = new Client(url);',
'      (window as any).KK = (window as any).KK || {};',
'      (window as any).KK.client = client;',
'      log("Joining room ''kudurru''…");',
'      room = await client.joinOrCreate("kudurru").catch(async ()=>{',
'        log("''kudurru'' not available, trying ''my_room''…");',
'        return await client.joinOrCreate("my_room");',
'      });',
'      (window as any).KK.room = room;',
'      log("Joined. Session:", room.sessionId);',
'      room.onMessage("ack", (m:any)=> log("ack:", m));',
'      room.onStateChange((st:any)=>{ (window as any).KK.state = st; });',
'      try{ room.send("toggle", {key:"revealAI", value:true}); }catch{}',
'    } catch(e){ console.error("[KK][cli] join error:", e); alert("Join failed. See console."); }',
'  }',
'',
'  function sendBoth(type:string, payload:any={}){',
'    if(!room){ alert("Join first."); return; }',
'    const msg = Object.assign({type}, payload);',
'    try { room.send("admin",  msg); } catch(e){ console.warn("admin send failed", e); }',
'    try { room.send("action", msg); } catch(e){ console.warn("action send failed", e); }',
'  }',
'',
'  function bind(id:string, fn:()=>void){',
'    const el = document.getElementById(id);',
'    if(!el){ log("missing button #"+id); return; }',
'    el.addEventListener("click", ()=>{ try{ log("click #"+id); fn(); } catch(e){ console.error("[KK][cli] click error",e); } });',
'  }',
'',
'  bind("join",   join);',
'  bind("next",   ()=> sendBoth("NEXT_PHASE"));',
'  bind("bots",   ()=> sendBoth("ADD_BOTS", {count:3}));',
'  bind("deal6",  ()=> sendBoth("DEAL6"));',
'  bind("reset",  ()=> sendBoth("RESET_MATCH"));',
'  bind("reveal", ()=> sendBoth("TOGGLE_REVEAL_AI", {value:true}));',
'  bind("openlib",()=> { alert("Library UI hook OK (stub)"); });',
'',
'  setTimeout(()=>{ if(room) sendBoth("PING", {nonce: Date.now()}); }, 1500);',
'  log("client wiring installed");',
'})();'
  )
  $main = $main + "`r`n" + $wire + "`r`n"
  Write-UTF8 $ClientMain $main
}

Write-Host "✅ KK patch complete." -ForegroundColor Green
Write-Host "Backups:" -ForegroundColor DarkGray
Write-Host "  $ServerRoom.bak.$stamp" -ForegroundColor DarkGray
Write-Host "  $ClientMain.bak.$stamp" -ForegroundColor DarkGray
Write-Host "Next: start servers:" -ForegroundColor Yellow
Write-Host ("  SERVER: cd ""{0}"" ; npm run dev" -f (Join-Path $Root 'server')) -ForegroundColor DarkGray
Write-Host ("  CLIENT: cd ""{0}"" ; npm run dev" -f (Join-Path $Root 'client')) -ForegroundColor DarkGray