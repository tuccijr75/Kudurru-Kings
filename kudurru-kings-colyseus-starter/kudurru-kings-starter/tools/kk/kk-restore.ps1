Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
function Restore-Latest($target){
  $dir = Split-Path $target -Parent
  $name = Split-Path $target -Leaf
  $pattern = "$name.bak.*"
  $candidates = Get-ChildItem -Path $dir -Filter $pattern | Sort-Object LastWriteTime -Descending
  if(!$candidates){ throw "No backups for $target" }
  Copy-Item $candidates[0].FullName $target -Force
  Write-Host "Restored -> $target" -ForegroundColor Yellow
}
$Repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ServerRoom = Join-Path $Repo "server\src\rooms\KudurruRoom.ts"
$ClientMain = Join-Path $Repo "client\src\main.ts"
Restore-Latest $ServerRoom
Restore-Latest $ClientMain
Write-Host "✅ Restore complete."