# Kudurru Kings M2 Cost Balance Gate — Windows PowerShell 5.1+
# Fail on both process exit and Godot-reported script errors.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$client = Join-Path $root 'godot_client'
$godot = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path $godot)) { throw "Godot 4.7.2 missing: $godot" }
Set-Location $root
$branch = (git branch --show-current).Trim()
if ($branch -ne 'build/cost-balance-v1-20261020') {
    throw "Cost gate refuses branch $branch"
}

function Run-Python([string[]] $parts) {
    Write-Output ("PYTHON: " + ($parts -join ' '))
    & python @parts
    if ($LASTEXITCODE -ne 0) { throw "Python gate failure: $($parts -join ' ')" }
}
function Run-Godot([string[]] $parts) {
    $output = (& $godot --headless --path $client @parts 2>&1 | Out-String)
    Write-Output $output
    $code = $LASTEXITCODE
    if ($code -ne 0 -or $output -match '(?m)SCRIPT ERROR|ERROR:|FAIL:|Parse Error|Compilation failed') {
        throw "Godot execution gate failure: $($parts -join ' ')"
    }
}

Run-Python @('godot_client/tools/balance_costs.py', '--apply')
Run-Python @('godot_client/tools/export_cost_panel.py')
Run-Python @('godot_client/tools/simulate_faction_costs.py')
Run-Python @('godot_client/tools/audit_legacy_exports.py')
Run-Python @('godot_client/tools/build_catalog.py')
Run-Python @('godot_client/tools/audit_master.py')
Run-Python @('godot_client/tests/test_cost_balance.py')
Run-Godot @('--editor', '--quit')
Run-Godot @('--script', 'res://tests/test_runner.gd')
Run-Godot @('--quit-after', '8')
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed' }
Write-Output 'KUDURRU_COST_BALANCE_V1_QUALITY_GATE_PASS'
