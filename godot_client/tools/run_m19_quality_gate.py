#!/usr/bin/env python3
"""Portable execution of the source-controlled M19 PowerShell gate inventory.
No exports or native Windows certification are implied by a Linux run.
"""
import subprocess,re,sys,os,json
from pathlib import Path
import argparse
parser=argparse.ArgumentParser(description="Run every M19 quality gate on Windows or Linux")
parser.add_argument('--branch',default='build/m19-command-integrity-20261020',help='Exact isolated branch to validate; default M19')
parser.add_argument('--godot',required=True,type=Path)
parser.add_argument('--log',type=Path,default=Path('m19_quality_gate.log'))
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]; os.chdir(root)
godot=str(args.godot.resolve())
version=subprocess.run([godot,'--version'],capture_output=True,text=True,check=True).stdout.strip()
if not version.startswith('4.7.2.stable'):raise SystemExit('Godot 4.7.2 required: '+version)
branch=subprocess.check_output(['git','branch','--show-current'],text=True).strip()
if branch!=args.branch:raise SystemExit('Wrong branch: '+branch)
os.environ['KUDURRU_GODOT']=godot
stage='m19'; ps=(root/'godot_client/tools/run_m19_quality_gate.ps1').read_text()
commands=[]
for line in ps.splitlines():
 if line.startswith('PythonGate @('):commands.append([sys.executable]+re.findall("'([^']+)'",line))
for t in re.search(r'foreach\(\$test in @\((.*?)\)\)',ps,re.S)[1].split(','):
 t=t.strip().strip("'");commands.append([sys.executable,'godot_client/tests/'+t])
commands.append([godot,'--headless','--path','godot_client','--editor','--quit'])
for critical in re.findall("'([^']+)'",re.search(r'foreach\(\$critical in @\((.*?)\)\)',ps,re.S)[1]):commands.append([godot,'--headless','--path','godot_client','--check-only','--script','res://scripts/'+critical])
testgroups=re.findall(r'foreach\(\$test in @\((.*?)\)\)',ps,re.S)
for t in re.findall("'([^']+)'",testgroups[1]):commands.append([godot,'--headless','--path','godot_client','--script','res://tests/'+t])
for scene in ['real_match','real_combat_lab','real_catalog','deck_builder','local_match_client']:
 commands.append([godot,'--headless','--path','godot_client','res://scenes/'+scene+'.tscn','--quit-after','8'])
commands.append([godot,'--headless','--path','godot_client','--quit-after','8'])
log=args.log.resolve()
with log.open('w') as f:
 for cmd in commands:
  p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180,env={**os.environ,'GODOT_SILENCE_ROOT_WARNING':'1'})
  f.write('$ '+' '.join(cmd)+'\n'+p.stdout+'\n');f.flush()
  bad=re.search(r'SCRIPT ERROR|ERROR:|Parse Error|\bFAIL(?:ED)?\b|Traceback|Invalid call|Compilation failed',p.stdout)
  if p.returncode or bad:
   print('FAIL',cmd,p.returncode,p.stdout,flush=True);sys.exit(1)
  marker=[x for x in p.stdout.splitlines() if 'passed=' in x or 'Ran ' in x or 'AUDIT cards=' in x]
  print('PASS',cmd[-1],'; '.join(marker),flush=True)
 a=json.loads((root/'godot_client/data/full_game_completion_audit.json').read_text());assert a['source_card_count']==754 and a['full_standard_releasable'] is False and a['blocked_gate_count']>0
 subprocess.run(['git','diff','--check'],check=True)
 print('KUDURRU_M19_FULL_GATE_PASS commands='+str(len(commands)),flush=True)
