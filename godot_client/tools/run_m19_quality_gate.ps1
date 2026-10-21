# Kudurru Kings M19 — full production-contract and integrated-match quality gate.
# Source: Godot 4.7.2, full Python validators and every previous regression suite.
$ErrorActionPreference='Continue'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
if ((git branch --show-current).Trim() -ne 'build/m19-command-integrity-20261020') {
 throw 'Refuse release gate outside M19 development branch'
}
$exe='E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project=Join-Path $root 'godot_client'
if (-not (Test-Path $exe)) { throw 'Godot 4.7.2 unavailable' }
function PythonGate([string[]]$a) {
 $out=(& python @a 2>&1 | Out-String)
 $rc=$LASTEXITCODE
 if($rc -ne 0 -or $out -match '(?m)Traceback|FAILED|ERROR:') {
  Write-Output $out
  throw "PYTHON_GATE_FAIL $($a -join ' ')"
 }
 Write-Output ('PASS Python '+($a -join ' ')+' : '+($out.Trim() -split '\r?\n')[-1])
}
function GodotGate([string[]]$a) {
 $out=(& $exe --headless --path $project @a 2>&1 | Out-String)
 $rc=$LASTEXITCODE
 if($rc -ne 0 -or $out -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Invalid call|Compilation failed') {
  Write-Output $out
  throw "GODOT_GATE_FAIL $($a -join ' ')"
 }
 $marker=@($out -split '\r?\n' | Where-Object {$_ -match '^KUDURRU_.*passed='} | Select-Object -Last 1)
 Write-Output ('PASS Godot '+($a -join ' ')+' : '+($marker -join ''))
}
PythonGate @('godot_client/tools/reconcile_combat_stats.py')
PythonGate @('godot_client/tools/balance_costs.py','--apply')
PythonGate @('godot_client/tools/export_cost_panel.py')
PythonGate @('godot_client/tools/build_catalog.py')
PythonGate @('godot_client/tools/build_real_cards.py')
PythonGate @('godot_client/tools/compile_character_mechanics.py')
PythonGate @('godot_client/tools/audit_m5_readiness.py')
PythonGate @('godot_client/tools/audit_full_game.py')
PythonGate @('godot_client/tools/build_completion_ledger.py')
foreach($test in @('test_cost_balance.py','test_real_sources.py','test_m6_stat_reconciliation.py','test_full_game_audit.py','test_collection_ledger.py','test_localhost_multiplayer.py')) {
 PythonGate @(('godot_client/tests/'+$test))
}
GodotGate @('--editor','--quit')
foreach($critical in @('match_integrator.gd','match_storage.gd','real_match_ui.gd','local_match_client_ui.gd','localhost_match_server.gd')) {
 GodotGate @('--check-only','--script',('res://scripts/'+$critical))
}
foreach($test in @(
 'test_runner.gd','test_dev_match.gd','test_economy_lab_ui.gd',
 'test_real_effects.gd','test_real_catalog_ui.gd','test_adjacency_rules.gd',
 'test_real_combat_preview.gd','test_real_combat_core.gd',
 'test_real_arbitration_lab.gd','test_real_combat_lab_ui.gd',
 'test_combat_stat_order.gd','test_integrated_match.gd',
 'test_real_match_ui.gd','test_match_passives.gd',
 'test_match_storage.gd','test_faction_matchups.gd','test_live_edicts.gd',
 'test_full_match_replay.gd','test_jurisdiction_core.gd','test_candidate_capture.gd',
 'test_deck_registry.gd','test_deck_builder_ui.gd',
 'test_more_live_edicts.gd','test_night_market_clause.gd','test_night_market_ui.gd',
 'test_opponent_support.gd','test_priority_choices.gd','test_priority_ui.gd',
 'test_end_phase_integrity.gd','test_defeat_restore.gd',
 'test_local_match_client_ui.gd','test_river_evacuation.gd','test_river_ui.gd',
 'test_defender_priority.gd','test_combat_choice_ui.gd',
 'test_network_combat_e2e.gd','test_command_integrity.gd','test_network_deck_lobby.gd'
)) {
 GodotGate @('--script',('res://tests/'+$test))
}
GodotGate @('res://scenes/real_match.tscn','--quit-after','8')
GodotGate @('res://scenes/real_combat_lab.tscn','--quit-after','8')
GodotGate @('res://scenes/real_catalog.tscn','--quit-after','8')
GodotGate @('res://scenes/deck_builder.tscn','--quit-after','8')
GodotGate @('res://scenes/local_match_client.tscn','--quit-after','8')
GodotGate @('--quit-after','8')
git diff --check
if($LASTEXITCODE -ne 0){throw 'Git whitespace gate failed'}
$report=Get-Content 'godot_client/data/full_game_completion_audit.json' -Raw | ConvertFrom-Json
if($report.full_standard_releasable -ne $false -or $report.source_card_count -ne 754 -or $report.blocked_gate_count -le 0){
 throw 'PRODUCTION_RELEASE_STATUS_INCORRECT'
}
Write-Output 'KUDURRU_M19_COMMAND_INTEGRITY_QUALITY_GATE_PASS'
