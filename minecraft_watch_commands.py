#!/usr/bin/env python3

# This script is used in minecraft_start.sh, don't call it directly!

import os, sys, subprocess, time

def runLocally(commandString):
  stdoutForBytes = os.fdopen(sys.stdout.fileno(), 'wb', closefd=False)
  p = subprocess.Popen(commandString, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
  output = b""
  for line in p.stdout:
    output += line
    stdoutForBytes.write(line)
    stdoutForBytes.flush()
  return output

def follow(f):
  f.seek(0,2)
  while True:
    line = f.readline()
    if not line:
      time.sleep(0.2)
      continue
    yield line

logfile = open("/home/ec2-user/minecraft/logs/latest.log", "r")
loglines = follow(logfile)
for line in loglines:
  if "--render-map" in line:
    subprocess.call("/home/ec2-user/scripts/map_render.py", stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
