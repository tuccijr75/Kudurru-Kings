# Windows x64 executable export, SHA verified and zipped (content NOT certified).
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
if((git branch --show-current).Trim() -ne 'build/m10-deck-construction-20261020'){
 throw 'Wrong branch for Windows candidate'
}
if((git status --porcelain | Out-String).Trim()){throw 'Commit and pass QA before exporting'}
$godot='E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$template=Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe'
if(-not (Test-Path $template)){throw 'Official Windows export template not installed'}
if(-not (Test-Path 'godot_client\export_presets.cfg')){throw 'No Windows preset'}
$sha=(git rev-parse --short=7 HEAD).Trim()
$builds='E:\KudurruKings\Builds'
$name='KudurruKings_M10_WindowsCandidate_'+$sha
$stage=Join-Path $builds $name
$zip=$stage+'.zip'
if(Test-Path $stage){throw 'Existing build folder: refuse overwrite'}
if(Test-Path $zip){throw 'Existing ZIP: refuse overwrite'}
New-Item -ItemType Directory -Path $stage | Out-Null
$exe=Join-Path $stage 'KudurruKings.exe'
$pck=Join-Path $stage 'KudurruKings.pck'
$log=(& $godot --headless --path 'godot_client' --editor --quit 2>&1|Out-String)
if($LASTEXITCODE -ne 0 -or $log -match '(?m)SCRIPT ERROR|ERROR:|Parse Error'){
 Write-Output $log
 throw 'Cannot import source'
}
$log=(& $godot --headless --path 'godot_client' --export-release 'Windows Desktop' $exe 2>&1|Out-String)
if($LASTEXITCODE -ne 0 -or $log -match '(?m)SCRIPT ERROR|ERROR:|Parse Error'){
 Write-Output $log
 throw 'Windows export error'
}
if(-not (Test-Path $exe) -or -not (Test-Path $pck)){throw 'Missing standalone EXE/PCK'}
$smoke=(& $exe --headless --quit-after 10 2>&1 | Out-String)
if($LASTEXITCODE -ne 0 -or $smoke -match '(?m)SCRIPT ERROR|ERROR:|Parse Error'){
 Write-Output $smoke
 throw 'Exported exe failed launch'
}
$notes=@'
KUDURRU KINGS M10 WINDOWS EXECUTABLE — DEVELOPMENT CANDIDATE

Double-click KudurruKings.exe in this same directory as KudurruKings.pck.
Unlike the earlier M8 portable source launcher, this is a native Godot
Windows x64 export: it does not require a separately installed Godot editor.

This is NOT a commercially released complete game. All 754 full card effects,
Boss combat and capture canon, full two-to-four-seat network multiplayer,
certified individual card artwork and signed installer remain unfinished.

Source is under the versioned branch:
build/m10-deck-construction-20261020
No user account rewards are issued and no remote network server is enabled.
This build has been exported and headless-launch tested on ManicsPC.
'@
[IO.File]::WriteAllText((Join-Path $stage 'READ_ME_FIRST.txt'),$notes,[Text.UTF8Encoding]::new($false))
$manifest=@{
 branch=(git branch --show-current).Trim()
 commit=(git rev-parse HEAD).Trim()
 godot='4.7.2.stable'
 level='development candidate; not complete'
 native_launch='PASS'
 full_standard_release_ready=$false
 image_art_certified=$false
 network_2_to_4_wan_certified=$false
 files=@()
}
foreach($path in @($exe,$pck)){
 $stream=[IO.File]::OpenRead($path)
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$digest=([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
 finally{$hasher.Dispose();$stream.Close()}
 $manifest.files+=@{name=(Split-Path $path -Leaf);bytes=(Get-Item $path).Length;sha256=$digest}
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $stage 'BUILD_MANIFEST.json') -Encoding UTF8
Compress-Archive -LiteralPath $stage -DestinationPath $zip -CompressionLevel Optimal
$verify=@'
from zipfile import ZipFile
import sys
p=sys.argv[1]
with ZipFile(p) as z:
 broken=z.testzip()
 if broken:raise RuntimeError("ZIP CRC failure: "+broken)
 names=z.namelist()
 for suffix in ["KudurruKings.exe","KudurruKings.pck","BUILD_MANIFEST.json","READ_ME_FIRST.txt"]:
  if not any(name.endswith("/"+suffix) for name in names):
   raise RuntimeError("ZIP MISSING "+suffix)
 print("M10_ZIP_ENTRIES",len(names))
'@
$verify | & python - $zip
if($LASTEXITCODE -ne 0){throw 'ZIP verification failed'}
Write-Output ('M10_WINDOWS_CANDIDATE='+$zip)
Write-Output ('M10_EXE_BYTES='+(Get-Item $exe).Length)
Write-Output ('M10_PCK_BYTES='+(Get-Item $pck).Length)
Write-Output ('M10_ZIP_BYTES='+(Get-Item $zip).Length)
Write-Output 'KUDURRU_M10_WINDOWS_NATIVE_EXPORT_PASS'
