# Kudurru Kings M8 Godot-powered Windows local preview ZIP.
# Assumes the authenticated ManicsPC E:\Godot Godot 4.7.2 install.
# Portable source build, not commercial binary export or online Standard release.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
$branch=(git branch --show-current).Trim()
if($branch -ne 'build/m8-local-game-completion-20261020'){throw 'Wrong branch for M8 preview'}
if(-not [string]::IsNullOrEmpty((git status --porcelain | Out-String).Trim())){throw 'Worktree must be committed before package'}
$exe='E:\Godot\Godot_v4.7.2-stable_win64.exe'
$console='E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
if(-not (Test-Path $exe) -or -not (Test-Path $console)){throw 'Godot 4.7.2 not available'}
$short=(git rev-parse --short=7 HEAD).Trim()
$releaseRoot='E:\KudurruKings\Builds'
$name='KudurruKings_M8_LocalPreview_'+$short
$folder=Join-Path $releaseRoot $name
$archive=$folder+'.zip'
if(Test-Path $folder){throw 'Build staging folder already exists; refuse overwrite'}
if(Test-Path $archive){throw 'Preview ZIP already exists; refuse overwrite'}
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$game=Join-Path $folder 'game'
New-Item -ItemType Directory -Path $game -Force | Out-Null
foreach($part in @('assets','data','scenes','scripts','docs')){
 $source=Join-Path $root ('godot_client\'+$part)
 if(Test-Path $source){Copy-Item -LiteralPath $source -Destination $game -Recurse -Force}
}
foreach($file in @('project.godot','README.md')){
 Copy-Item (Join-Path $root ('godot_client\'+$file)) (Join-Path $game $file)
}
$readme=@'
KUDURRU KINGS M8: LOCAL DEVELOPMENT GAME PREVIEW

1. Extract the ZIP to a local folder on ManicsPC.
2. Double-click PLAY_KUDURRU_KINGS.bat.
3. In the game choose PLAY REAL-CARD MATCH (PREVIEW).
4. Select any of the five factions for you and the opponent.
5. Use card buttons and seven phases to play until 10 Marks.
6. SAVE LOCAL GAME and CONTINUE SAVED GAME preserve and verify your match.

REQUIRES GODOT 4.7.2 ON MANICSPC AT E:\Godot.
This preview contains game assets and source, not a standalone Windows export.
It makes no account connections or permanent collection rewards.
Only a restricted real-card candidate subset is supported. It is not
finished 754-card Standard, not a commercial release, not online multiplayer.

Complete current release status:
game\docs\M8_LOCAL_GAME_REPORT.md
game\data\full_game_completion_audit.json

Source revision: __COMMIT__
'@.Replace('__COMMIT__',(git rev-parse HEAD).Trim())
[IO.File]::WriteAllText((Join-Path $folder 'READ_ME_FIRST.txt'),$readme,[Text.UTF8Encoding]::new($false))
$bat=@'
@echo off
setlocal
set "GODOT=E:\Godot\Godot_v4.7.2-stable_win64.exe"
set "GAME=%~dp0game"
if not exist "%GODOT%" (
 echo Godot 4.7.2 not found at E:\Godot. Install it on ManicsPC first.
 pause
 exit /b 1
)
if not exist "%GAME%\.godot" (
 echo Importing Godot project on first launch...
 "%GODOT%" --headless --editor --path "%GAME%" --quit
 if errorlevel 1 (
  echo Godot import failed.
  pause
  exit /b 1
 )
)
"%GODOT%" --path "%GAME%"
'@
[IO.File]::WriteAllText((Join-Path $folder 'PLAY_KUDURRU_KINGS.bat'),$bat,[Text.ASCIIEncoding]::new())
Write-Output ('Validating staged source: '+$game)
$out=(& $console --headless --path $game --editor --quit 2>&1 | Out-String)
if($LASTEXITCODE -ne 0 -or $out -match '(?m)SCRIPT ERROR|ERROR:|Parse Error|Compilation failed'){Write-Output $out;throw 'Staged Godot import failed'}
$out=(& $console --headless --path $game --quit-after 8 2>&1 | Out-String)
if($LASTEXITCODE -ne 0 -or $out -match '(?m)SCRIPT ERROR|ERROR:|Parse Error|Compilation failed'){Write-Output $out;throw 'Staged launch failed'}
# Remove ephemeral import caches: launcher recreates them as needed.
$cache=Join-Path $game '.godot'
if(Test-Path $cache){Remove-Item -LiteralPath $cache -Recurse -Force}
Compress-Archive -LiteralPath $folder -DestinationPath $archive -CompressionLevel Optimal
Add-Type -AssemblyName System.IO.Compression
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try{
 $names=@($zip.Entries|ForEach-Object {$_.FullName})
 foreach($required in @('project.godot','real_match.tscn','match_integrator.gd','real_cards_v1.json','READ_ME_FIRST.txt')){
  if(-not @($names|Where-Object {$_ -like ('*/'+$required)}).Count){throw ('Missing packaged file: '+$required)}
 }
 Write-Output ('ZIP_COUNT='+$names.Count)
}finally{$zip.Dispose()}
$stream=[IO.File]::OpenRead($archive)
$hasher=[Security.Cryptography.SHA256]::Create()
try {
 $hash=([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-','').ToLowerInvariant()
} finally {
 $stream.Dispose()
 $hasher.Dispose()
}
Write-Output ('M8_PORTABLE_PREVIEW_PATH='+$archive)
Write-Output ('M8_PORTABLE_PREVIEW_SHA256='+$hash)
Write-Output ('M8_PORTABLE_PREVIEW_BYTES='+(Get-Item $archive).Length)
Write-Output 'KUDURRU_M8_WINDOWS_PREVIEW_PACKAGE_PASS'
