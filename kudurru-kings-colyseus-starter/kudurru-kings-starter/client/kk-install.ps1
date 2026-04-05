# kk-install.ps1  —  drop-in installer + runner
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-UTF8($Path,$Text){
  $dir=[System.IO.Path]::GetDirectoryName($Path)
  if($dir -and -not (Test-Path $dir)){ [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  [System.IO.File]::WriteAllText($Path,$Text,[System.Text.UTF8Encoding]::new($false))
}

function Find-RepoRoot {
  $cur = Get-Item (Get-Location).Path
  for($i=0;$i -lt 6;$i++){
    $clientMain = Join-Path $cur.FullName "client\src\main.ts"
    $serverRoom = Join-Path $cur.FullName "server\src\rooms\KudurruRoom.ts"
    if( (Test-Path $clientMain) -and (Test-Path $serverRoom) ){ return $cur.FullName }
    if(-not $cur.Parent){ break }
    $cur = $cur.Parent
  }
  throw "Could not find repo root (needs client\src\main.ts and server\src\rooms\KudurruRoom.ts). Start anywhere inside the project and run again."
}

$Root  = Find-RepoRoot
$Tools = Join-Path $Root "tools\kk"
[void](New-Item -ItemType Directory -Force -Path $Tools)

# ----------------- kk-wire.ps1 (server+client functional wiring) -----------------
$WirePath = Join-Path $Tools "kk-wire.ps1"
$WireCode = @'
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

# ===== SERVER PATCH =====
$room = Get-Content -Raw $ServerRoom

# Ensure MapSchema import
if($room -notmatch '\bMapSchema\b'){
  $room = "import { MapSchema } from ""@colyseus/schema"";`r`n$room"
}

# Inject helpers once
if($room -notmatch 'kkEnsureStateShape\('){
  $helpers = @'
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
