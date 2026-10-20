# Full M5 source and Godot workstation gate. Does not certify production match release.
$ErrorActionPreference = 'Continue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
if ((git branch --show-current).Trim() -ne 'build/m5-combat-core-20261020') {
 throw 'Quality gate must run on M5 branch'
}
$engine = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $root 'godot_client'
if (-not (Test-Path $engine)) { throw 'Godot 4.7.2 absent' }

function RunPython([string[]] $arguments) {
 $output = (& python @arguments 2>&1 | Out-String)
 $code = $LASTEXITCODE
 if ($code -ne 0 -or $output -match '(?m)Traceback|FAILED|ERROR:') {
  Write-Output $output
  throw "Python gate failed $($arguments -join ' ')"
 }
 Write-Output ("PASS python " + ($arguments -join ' ') + ' | ' + ($output.Trim() -split '\r?\n')[-1])
}

function RunGodot([string[]] $arguments) {
 $output = (& $engine --headless --path $project @arguments 2>&1 | Out-String)
 $code = $LASTEXITCODE
 if ($code -ne 0 -or $output -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Compilation failed|Invalid call') {
  Write-Output $output
  throw "Godot gate failed $($arguments -join ' ')"
 }
 $marker = @($output -split '\r?\n' | Where-Object { $_ -match '^KUDURRU_.* passed=' } | Select-Object -Last 1)
 Write-Output ('PASS godot ' + ($arguments -join ' ') + ' ' + ($marker -join ''))
}

RunPython @('godot_client/tools/balance_costs.py','--apply')
RunPython @('godot_client/tools/export_cost_panel.py')
RunPython @('godot_client/tools/build_catalog.py')
RunPython @('godot_client/tools/build_real_cards.py')
RunPython @('godot_client/tools/compile_character_mechanics.py')
RunPython @('godot_client/tools/audit_m5_readiness.py')
RunPython @('godot_client/tests/test_cost_balance.py')
RunPython @('godot_client/tests/test_real_sources.py')
RunGodot @('--editor','--quit')
foreach ($name in @(
 'test_runner.gd',
 'test_dev_match.gd',
 'test_economy_lab_ui.gd',
 'test_real_effects.gd',
 'test_real_catalog_ui.gd',
 'test_adjacency_rules.gd',
 'test_real_combat_preview.gd',
 'test_real_combat_core.gd',
 'test_real_arbitration_lab.gd',
 'test_real_combat_lab_ui.gd'
)) {
 RunGodot @('--script', ('res://tests/'+$name))
}
RunGodot @('res://scenes/real_combat_lab.tscn','--quit-after','8')
RunGodot @('res://scenes/real_catalog.tscn','--quit-after','8')
RunGodot @('--quit-after','8')
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed' }
Write-Output 'KUDURRU_M5_COMBAT_ARBITRATION_QUALITY_GATE_PASS'
