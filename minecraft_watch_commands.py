#!/usr/bin/env python3

# This script is used in minecraft_start.sh, don't call it directly!

import os, sys, subprocess, time

def follow(f):
  f.seek(0,2)
  while True:
    line = f.readline()
    if not line:
      time.sleep(0.1)
      continue
    yield line

logfile = open("/home/ec2-user/minecraft/logs/latest.log", "r")
loglines = follow(logfile)
for line in loglines:
  if "--render-map" in line:
    subprocess.call("/home/ec2-user/scripts/map_render.py", stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    subprocess.call("screen -S minecraft -X stuff \"/say map_render.py finished.$(printf \\\\r)\"", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
  elif "--system-shutdown" in line:
    subprocess.call("/home/ec2-user/scripts/system_safe_shutdown.sh", stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  elif "--test" in line:
    subprocess.call("screen -S minecraft -X stuff \"/say Command listener active.$(printf \\\\r)\"", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
