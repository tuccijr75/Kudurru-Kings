# M25 uses the shared versioned suite inventory through the portable runner.
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root
& python 'godot_client/tools/run_m19_quality_gate.py' --branch 'build/m25-parallel-completion-20261021' --godot 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --log 'E:\KudurruKings\m25_native_gate_commands.log'
if($LASTEXITCODE -ne 0){throw 'M25 full quality gate failed'}
