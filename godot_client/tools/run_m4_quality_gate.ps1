# M4 self-rebuilding source gate: 754 real cards, 12 effects, 423 exact descriptors.
# Native Python unittest writes progress to stderr; detect failures via process/regex.
$ErrorActionPreference='Continue'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
if ((git branch --show-current).Trim() -ne 'build/m4-real-cards-20261020') {
 throw 'M4 quality gate refuses other branches'
}
$godot='E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project=Join-Path $root 'godot_client'
if (-not (Test-Path $godot)) { throw 'Godot 4.7.2 missing' }
function PythonGate([string[]]$a) {
 $out=(& python @a 2>&1 | Out-String)
 if ($LASTEXITCODE -ne 0 -or $out -match '(?m)Traceback|FAILED|ERROR:') {
  Write-Output $out
  throw "Python gate: $($a -join ' ')"
 }
 Write-Output ("PASS python " + ($a -join ' ') + ' | ' + ($out.Trim() -split '\r?\n')[-1])
}
function GodotGate([string[]]$a) {
 $out=(& $godot --headless --path $project @a 2>&1 | Out-String)
 if ($LASTEXITCODE -ne 0 -or $out -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Invalid call|Compilation failed') {
  Write-Output $out
  throw "Godot gate: $($a -join ' ')"
 }
 $marker=@($out -split '\r?\n' | Where-Object {$_ -match 'KUDURRU_'} | Select-Object -Last 1)
 Write-Output ('PASS godot ' + ($a -join ' ') + ' ' + ($marker -join ' '))
}
PythonGate @('godot_client/tools/balance_costs.py','--apply')
PythonGate @('godot_client/tools/export_cost_panel.py')
PythonGate @('godot_client/tools/build_catalog.py')
PythonGate @('godot_client/tools/build_real_cards.py')
PythonGate @('godot_client/tools/compile_character_mechanics.py')
PythonGate @('godot_client/tests/test_cost_balance.py')
PythonGate @('godot_client/tests/test_real_sources.py')
GodotGate @('--editor','--quit')
foreach($script in @('test_runner.gd','test_dev_match.gd','test_economy_lab_ui.gd',
 'test_real_effects.gd','test_real_catalog_ui.gd','test_adjacency_rules.gd',
 'test_real_combat_preview.gd')) {
 GodotGate @('--script',('res://tests/'+$script))
}
GodotGate @('res://scenes/real_catalog.tscn','--quit-after','6')
GodotGate @('--quit-after','6')
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git diff check failed' }
Write-Output 'KUDURRU_REAL_CARDS_M4_GATE_PASS'
