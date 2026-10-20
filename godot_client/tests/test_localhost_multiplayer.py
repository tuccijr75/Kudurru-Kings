"""Real socket E2E for loopback-only Godot authoritative match preview.

Not a TLS or remote multiplayer security certification. Test sockets are
bound to 127.0.0.1 and the server is terminated after every run.
"""
import json
import socket
import subprocess
import time
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ENGINE=Path(r"E:\Godot\Godot_v4.7.2-stable_win64_console.exe")
HOST="127.0.0.1"
PORT=31147

class LocalhostMatchTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.server=subprocess.Popen(
    [str(ENGINE),"--headless","--path",str(ROOT/"godot_client"),
     "res://scenes/localhost_match_server.tscn"],
    stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,
    creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,
  )
  for _ in range(80):
   if cls.server.poll() is not None:raise RuntimeError("Godot server failed to launch")
   try:
    with socket.create_connection((HOST,PORT),0.15):break
   except OSError:
    time.sleep(0.1)
  else:raise RuntimeError("Loopback port never opened")

 @classmethod
 def tearDownClass(cls):
  subprocess.run(["taskkill","/F","/T","/PID",str(cls.server.pid)],
                 capture_output=True,timeout=10)

 def connect(self):
  s=socket.create_connection((HOST,PORT),3)
  s.settimeout(4)
  f=s.makefile("r",encoding="utf-8")
  welcome=json.loads(f.readline())
  return s,f,welcome

 def send(self,s,payload):
  s.sendall((json.dumps(payload)+"\n").encode("utf-8"))

 def recv(self,f):
  raw=f.readline()
  if not raw:raise AssertionError("Server closed unexpectedly")
  return json.loads(raw)

 def test_two_seats_private_and_authoritative(self):
  s0,f0,w0=self.connect()
  s1,f1,w1=self.connect()
  try:
   self.assertTrue(w0["ok"] and w1["ok"])
   self.assertEqual([0,1],[w0["seat"],w1["seat"]])
   self.assertNotEqual(w0["token"],w1["token"])
   self.assertEqual(6,len(w0["view"]["players"][0]["hand"]))
   self.assertEqual(6,len(w1["view"]["players"][1]["hand"]))
   self.assertNotIn("hand",w0["view"]["players"][1])
   self.assertNotIn("hand",w1["view"]["players"][0])
   self.assertNotIn("seed",w0["view"])
   self.assertNotIn("action_log",w0["view"])
   self.assertNotIn("peek_used",w0["view"])
   self.send(s0,{"type":"ACTION","token":"forged","action":{"type":"KEEP","revision":0}})
   self.assertEqual("BAD_SESSION_TOKEN",self.recv(f0)["error"])
   self.send(s0,{"type":"ACTION","token":w0["token"],"action":{"type":"KEEP","revision":0,"seat":1}})
   v0=self.recv(f0)
   v1=self.recv(f1)
   self.assertEqual(1,v0["view"]["revision"])
   self.assertEqual(1,v1["view"]["revision"])
   self.assertFalse(v1["view"]["setup_complete"])
   self.send(s0,{"type":"ACTION","token":w0["token"],"action":{"type":"ADVANCE","revision":1}})
   self.assertEqual("SETUP_ALREADY_DECIDED",self.recv(f0)["error"])
   self.send(s1,{"type":"ACTION","token":w1["token"],"action":{"type":"KEEP","revision":1,"seat":0}})
   v1=self.recv(f1)
   v0=self.recv(f0)
   self.assertEqual(2,v1["view"]["revision"])
   self.assertTrue(v1["view"]["setup_complete"])
   self.assertNotIn("hand",v1["view"]["players"][0])
   self.send(s1,{"type":"ACTION","token":w1["token"],"action":{"type":"ADVANCE","revision":2,"seat":0}})
   self.assertEqual("NOT_ACTIVE_SEAT",self.recv(f1)["error"])
   self.send(s0,{"type":"ACTION","token":w0["token"],"action":{"type":"ADVANCE","revision":0}})
   self.assertEqual("STALE_REVISION",self.recv(f0)["error"])
   self.send(s0,{"type":"ACTION","token":w0["token"],"action":{"type":"ADVANCE","revision":2}})
   v0=self.recv(f0);v1=self.recv(f1)
   self.assertEqual(3,v0["view"]["revision"])
   self.assertEqual(v0["view"]["revision"],v1["view"]["revision"])
   self.assertNotIn("hand",v1["view"]["players"][0])
   self.assertEqual(6,len(v0["view"]["players"][0]["hand"]))
   self.send(s0,{"type":"VIEW","token":w0["token"]})
   self.assertEqual(3,self.recv(f0)["view"]["revision"])
   print("KUDURRU_M9_LOOPBACK_MULTIPLAYER_PRIVATE_PASS")
  finally:
   for f in [f0,f1]:f.close()
   for s in [s0,s1]:s.close()

if __name__=="__main__":
 unittest.main(verbosity=2)
