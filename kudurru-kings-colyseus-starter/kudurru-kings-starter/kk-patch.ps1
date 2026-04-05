Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-UTF8($Path,$Text){
  $dir=[System.IO.Path]::GetDirectoryName($Path)
  if($dir -and -not (Test-Path $dir)){ [System.IO.Directory]::CreateDirectory($dir)|Out-Null }
  [System.IO.File]::WriteAllText($Path,$Text,[System.Text.UTF8Encoding]::new($false))
}
function Find-RepoRoot {
  $cur = Get-Item (Get-Location).Path
  for($i=0;$i -lt 6;$i++){
    $clientMain = Join-Path $cur.FullName "client\src\main.ts"
    $serverRoom = Join-Path $cur.FullName "server\src\rooms\KudurruRoom.ts"
    if((Test-Path $clientMain) -and (Test-Path $serverRoom)){ return $cur.FullName }
    if(-not $cur.Parent){ break }
    $cur = $cur.Parent
  }
  throw "Could not find repo root (needs client\src\main.ts and server\src\rooms\KudurruRoom.ts)."
}

$Root = Find-RepoRoot
$ServerRoom = Join-Path $Root "server\src\rooms\KudurruRoom.ts"
$ClientMain = Join-Path $Root "client\src\main.ts"
$Favicon    = Join-Path $Root "client\public\favicon.ico"

# --- backups
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item $ServerRoom "$ServerRoom.bak.$stamp" -Force
Copy-Item $ClientMain "$ClientMain.bak.$stamp" -Force

# ================= SERVER PATCH =================
$room = Get-Content -Raw $ServerRoom
if($room -notmatch 'KK_PATCH_V6'){
  $patch = @'
  // ===== <<KK_PATCH_V6>> =====
  private kkEnsureStateShape() {
    const s:any = this.state as any;
    s.table ||= {}; s.table.pools ||= {};
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
    try { if (!s.players[id]) s.players[id] = { id, name: `Bot ${Object.keys(s.players).length} 🤖` }; } catch {}
    try { if (s.players.set && !s.players.get(id)) s.players.set(id, { id, name: `Bot ${s.players.size} 🤖` }); } catch {}
  }
  private kkDeal(pid:string, n:number=6) {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    try { s.hands[pid] ||= []; } catch {}
    for (let i=0;i<n;i++){
      const idx = Math.floor(Math.random()*999);
      try { s.hands[pid].push({ id:`c_${Date.now()}_${i}`, name:`Card ${idx}`, type:"Character", rarity:"Mid", atk:0, def:0 }); } catch {}
    }
  }
  private kkBroadcastUi() {
    this.kkEnsureStateShape();
    const s:any = this.state as any;
    const phase = s.phase || "Upkeep";
    const activeIndex = s.activeIndex ?? 0;
    const guessNames = () => {
      const arr = ["P1","P2","P3","P4"];
      try{
        const P:any = s.players?.toJSON ? s.players.toJSON() : s.players;
        const ids = Object.keys(P || {});
        for (let i=0;i<Math.min(4,ids.length);i++){
          arr[i] = P[ids[i]]?.name || arr[i];
        }
      }catch{}
      return arr;
    };
    const names = guessNames();
    try { this.broadcast("ui", { phase, activeIndex, names }); } catch {}
  }
  private kkHandleAdmin = (_client:any, msg:any) => {
    this.kkEnsureStateShape();
    const t = msg?.type;
    switch(t){
      case "ADD_BOTS": {
        const n = Math.max(1, Math.min(3, msg?.count ?? 1));
        for (let i=0;i<n;i++) this.kkAddBotSeat();
        this.kkBroadcastUi();
        _client?.send && _client.send("ack", { ok:true, type:"ADD_BOTS" }); return;
      }
      case "RESET_MATCH": {
        this.kkEnsureStateShape();
        const s:any = this.state as any;
        try { if (s.hands?.clear) s.hands.clear(); } catch {}
        try { s.hands = {}; } catch {}
        s.phase = "Upkeep"; s.activeIndex = 0;
        this.kkBroadcastUi();
        _client?.send && _client.send("ack", { ok:true, type:"RESET_MATCH" }); return;
      }
      case "DEAL6": {
        const s:any = this.state as any;
        const P:any = s.players?.toJSON ? s.players.toJSON() : s.players;
        if (P) for (const pid in P) this.kkDeal(pid,6);
        this.kkBroadcastUi();
        _client?.send && _client.send("ack", { ok:true, type:"DEAL6" }); return;
      }
    }
  };
  private kkHandleAction = (_client:any, msg:any) => {
    this.kkEnsureStateShape();
    const t = msg?.type;
    switch(t){
      case "NEXT_PHASE": {
        this.kkPhaseNext();
        const s:any = this.state as any;
        this.kkBroadcastUi();
        _client?.send && _client.send("ack", { ok:true, type:"NEXT_PHASE", phase: s.phase }); return;
      }
      case "PING": { _client?.send && _client.send("ack", { ok:true, type:"PING", nonce: msg?.nonce }); return; }
    }
  };
  // ===== <<KK_PATCH_V6>> END =====
