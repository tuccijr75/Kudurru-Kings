# Kudurru Kings M6: preserve printed Guard/First Strike authority and all M5 regression gates.
$ErrorActionPreference='Continue'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
if ((git branch --show-current).Trim() -ne 'build/m6-combat-stat-reconciliation-20261020') {
 throw 'M6 gate refuses wrong source branch'
}
$exe='E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project=Join-Path $root 'godot_client'
if (-not (Test-Path $exe)) { throw 'Godot 4.7.2 not found' }

function RunPython([string[]]$a) {
 $output=(& python @a 2>&1 | Out-String)
 $rc=$LASTEXITCODE
 if ($rc -ne 0 -or $output -match '(?m)Traceback|FAILED|ERROR:') {
  Write-Output $output
  throw "Python validation failed: $($a -join ' ')"
 }
 $marker=($output.Trim() -split '\r?\n')[-1]
 Write-Output ("PASS python " + ($a -join ' ') + ' | '+$marker)
}

function RunGodot([string[]]$a) {
 $output=(& $exe --headless --path $project @a 2>&1 | Out-String)
 $rc=$LASTEXITCODE
 if ($rc -ne 0 -or $output -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Compilation failed|Invalid call') {
  Write-Output $output
  throw "Godot validation failed: $($a -join ' ')"
 }
 $marker=@($output -split '\r?\n' | Where-Object {$_ -match '^KUDURRU_.* passed='} | Select-Object -Last 1)
 Write-Output ('PASS godot ' + ($a -join ' ') + ' ' + ($marker -join ''))
}

RunPython @('godot_client/tools/reconcile_combat_stats.py')
RunPython @('godot_client/tools/balance_costs.py','--apply')
RunPython @('godot_client/tools/export_cost_panel.py')
RunPython @('godot_client/tools/build_catalog.py')
RunPython @('godot_client/tools/compile_character_mechanics.py')
RunPython @('godot_client/tools/build_real_cards.py')
RunPython @('godot_client/tools/audit_m5_readiness.py')
RunPython @('godot_client/tests/test_cost_balance.py')
RunPython @('godot_client/tests/test_real_sources.py')
RunPython @('godot_client/tests/test_m6_stat_reconciliation.py')
RunGodot @('--editor','--quit')
foreach($name in @(
 'test_runner.gd','test_dev_match.gd','test_economy_lab_ui.gd',
 'test_real_effects.gd','test_real_catalog_ui.gd','test_adjacency_rules.gd',
 'test_real_combat_preview.gd','test_real_combat_core.gd',
 'test_real_arbitration_lab.gd','test_real_combat_lab_ui.gd',
 'test_combat_stat_order.gd'
)) {
 RunGodot @('--script',('res://tests/'+$name))
}
RunGodot @('res://scenes/real_combat_lab.tscn','--quit-after','8')
RunGodot @('res://scenes/real_catalog.tscn','--quit-after','8')
RunGodot @('--quit-after','8')
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed' }
Write-Output 'KUDURRU_M6_COMBAT_STAT_AUTHORITY_GATE_PASS'
