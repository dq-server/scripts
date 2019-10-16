#!/usr/bin/env python3

# USAGE: ./map_render.py

# Creates a separate AWS EC2 instance, renders an Overviewer map there, and terminates the instance.

import os, sys, subprocess, time, json

def runLocally(commandString, getOutput=False, logToMinecraft=False):
  p = subprocess.Popen(commandString, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
  output = b""
  for line in p.stdout:
    if getOutput:
      output += line
    if logToMinecraft == True:
      runLocally(f"screen -S minecraft -X stuff \"/say {str(line, 'utf-8')}$(printf \\\\r)\"")
  if getOutput:
    return output

def getInstances():
  output = runLocally("aws ec2 describe-instances --filters \"Name=instance-type,Values=c5.24xlarge\" \"Name=instance-state-name,Values=pending,running\" --query \"Reservations[].Instances\" --region \"eu-central-1\"", getOutput=True)
  parsed = json.loads(output)
  return parsed if len(parsed) == 0 else parsed[0]

SSH_OPTIONS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/minecraft-ec2.pem"

def runOnRemote(commandString):
  return runLocally(f"ssh {SSH_OPTIONS} -o LogLevel=ERROR ubuntu@{instanceAddress} \"{commandString}\"", logToMinecraft=True)

def copyToRemote(localPath, remotePath):
  return runLocally(f"scp -r -p {SSH_OPTIONS} -o LogLevel=ERROR {localPath} ubuntu@{instanceAddress}:\"{remotePath}\" >/dev/null 2>&1")

def syncFromRemote(remotePath, localPath):
  return runLocally(f"rsync -e \"ssh {SSH_OPTIONS}\" -a -r --delete ubuntu@{instanceAddress}:\"{remotePath}\" {localPath} >/dev/null 2>&1")

if len(getInstances()) > 0:
  runLocally("screen -S minecraft -X stuff \"/say Unable to render the map. Previous render isn't finished.$(printf \\\\r)\"")
  print("ERROR! Not all previous c5.24xlarge instances have been terminated. Aborting to avoid accumulating hosting costs.")
  exit(1)

try:
  print("Spinning up a rendering VM (c5.24xlarge)...")
  runLocally("screen -S minecraft -X stuff \"/say Spinning up a new virtual machine (96 CPU cores)...$(printf \\\\r)\"")
  runLocally("aws ec2 run-instances --image-id ami-0cc0a36f626a4fdf5 --count 1 --instance-type c5.24xlarge --key-name minecraft-ec2 --security-group-ids sg-099005316791a75b8 --subnet-id subnet-ff30fe95 --region eu-central-1 --block-device-mappings '[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":30,\"VolumeType\":\"gp2\",\"DeleteOnTermination\":true}}]' --tag-specifications 'ResourceType=instance,Tags=[{Key=purpose,Value=minecraft}]' 'ResourceType=volume,Tags=[{Key=purpose,Value=minecraft}]'")

  print("Waiting 30 seconds for the VM to initialize...")
  time.sleep(30)
  instanceInfo = getInstances()[0]
  instanceAddress = instanceInfo["PrivateDnsName"]
  print(f"Instance ready at {instanceAddress}...")

  runLocally(f"screen -S minecraft -X stuff \"/say Rendering VM ready, making a backup to copy over...$(printf \\\\r)\"")
  runLocally("~/scripts/minecraft_backup.sh")

  runLocally("screen -S minecraft -X stuff \"/say Copying the latest backup to the rendering VM...$(printf \\\\r)\"")
  print("Copying the latest backup to the renderer instance...")
  copyToRemote("~/minecraft-backups/backup-0", "~/world-backup")

  print("Initiating render procedure...")
  copyToRemote("~/scripts/map_render_remote_script.sh", "~/")
  runOnRemote("~/map_render_remote_script.sh")

  runLocally("screen -S minecraft -X stuff \"/say Copying the newly rendered map to the server...$(printf \\\\r)\"")
  print("Copying rendered map to the server instance...")
  syncFromRemote("~/overviewer/map", "~/overviewer")

except Exception as e:
  runLocally("screen -S minecraft -X stuff \"/say Error! Trying to print it below:$(printf \\\\r)\"")
  try:
    runLocally(f"screen -S minecraft -X stuff \"/say {str(e)}$(printf \\\\r)\"")
  finally:
    runLocally("screen -S minecraft -X stuff \"/say End of stacktrace.$(printf \\\\r)\"")

finally:
  runLocally("screen -S minecraft -X stuff \"/say Killing the rendering VM...$(printf \\\\r)\"")
  print("Terminating the renderer instance...")
  runLocally(f"aws ec2 terminate-instances --region eu-central-1 --instance-ids {instanceInfo['InstanceId']}")
  time.sleep(10)
