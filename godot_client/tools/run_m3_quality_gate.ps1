# Kudurru Kings M3: Windows workstation release gate. No production deployment.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
$client = Join-Path $root 'godot_client'
$godot = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path $godot)) { throw 'Godot 4.7.2 unavailable' }
$branch = (git branch --show-current).Trim()
if ($branch -ne 'build/m3-turn-deployment-20261020') {
    throw "Refusing to run mutable M3 checks on $branch"
}
function Run-Python([string[]]$arguments) {
    & python @arguments
    if ($LASTEXITCODE -ne 0) { throw "Python failed: $($arguments -join ' ')" }
}
function Run-Godot([string[]]$arguments) {
    $output = (& $godot --headless --path $client @arguments 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    Write-Output $output
    if ($exitCode -ne 0 -or $output -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Compilation failed|Invalid call') {
        throw "Godot failed: $($arguments -join ' ')"
    }
}
Run-Python @('godot_client/tools/balance_costs.py', '--apply')
Run-Python @('godot_client/tools/export_cost_panel.py')
Run-Python @('godot_client/tools/audit_legacy_exports.py')
Run-Python @('godot_client/tools/build_catalog.py')
Run-Python @('godot_client/tools/simulate_faction_costs.py')
Run-Python @('godot_client/tests/test_cost_balance.py')
Run-Godot @('--editor', '--quit')
Run-Godot @('--script', 'res://tests/test_runner.gd')
Run-Godot @('--script', 'res://tests/test_dev_match.gd')
Run-Godot @('--script', 'res://tests/test_economy_lab_ui.gd')
Run-Godot @('res://scenes/economy_lab.tscn', '--quit-after', '8')
Run-Godot @('--quit-after', '8')
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace gate failed' }
Write-Output 'KUDURRU_M3_ECONOMY_LAB_QUALITY_GATE_PASS'
