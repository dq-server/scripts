#!/usr/bin/env python3

# USAGE: ./map_render.py

# Creates a separate AWS EC2 instance, renders an Overviewer map there, and terminates the instance.

import os
import sys
import subprocess
import time
import json

def runLocally(commandString):
  stdoutForBytes = os.fdopen(sys.stdout.fileno(), 'wb', closefd=False)
  p = subprocess.Popen(commandString, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
  output = b""
  for line in p.stdout:
    output += line
    stdoutForBytes.write(line)
    stdoutForBytes.flush()
  return output

def getInstances():
  output = runLocally("aws ec2 describe-instances --filters \"Name=instance-type,Values=t3a.2xlarge\" \"Name=instance-state-name,Values=pending,running\" --query \"Reservations[].Instances\" --region \"eu-central-1\"")
  parsed = json.loads(output)
  return parsed if len(parsed) == 0 else parsed[0]

if len(getInstances()) > 0:
  print("ERROR! Not all previous t3a.2xlarge instances have been terminated. Aborting to avoid accumulating hosting costs.")
  exit(1)

SSH_OPTIONS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/minecraft-ec2.pem"

def runOnRemote(commandString):
  return runLocally(f"ssh {SSH_OPTIONS} ec2-user@{instanceAddress} {commandString}")

def copyToRemote(localPath, remotePath):
  return runLocally(f"scp {SSH_OPTIONS} -r {localPath} ec2-user@{instanceAddress}:{remotePath}")

def syncFromRemote(remotePath, localPath):
  return runLocally(f"rsync -e \"ssh {SSH_OPTIONS}\" -a -r --progress --delete ec2-user@{instanceAddress}:{remotePath} {localPath}")

print("Spinning up a t3a.2xlarge instance...")
runLocally("aws ec2 run-instances --image-id ami-0cc293023f983ed53 --count 1 --instance-type t3a.2xlarge --key-name minecraft-ec2 --security-group-ids sg-099005316791a75b8 --subnet-id subnet-ff30fe95 --region eu-central-1 --block-device-mappings '[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp2\",\"DeleteOnTermination\":true}}]' --credit-specification CpuCredits=unlimited --tag-specifications 'ResourceType=instance,Tags=[{Key=purpose,Value=minecraft}]' 'ResourceType=volume,Tags=[{Key=purpose,Value=minecraft}]'")

print("Waiting 3 minutes for the instance to initialize...")
time.sleep(180)

instanceInfo = getInstances()[0]
instanceAddress = instanceInfo["PrivateDnsName"]

runLocally("~/scripts/minecraft_backup.sh")

print("Copying the latest backup to the renderer instance...")
copyToRemote("~/minecraft-backups/backup-0", "~/world-backup")

print("Copying previous render to the renderer instance...")
copyToRemote("~/overviewer/map", "~/previous-render")

print("Initiating render procedure...")
runOnRemote("~/scripts/map_render_remote_script.sh")

print("Copying rendered map to the server instance...")
syncFromRemote("~/overviewer/map/", "~/overviewer/map")
runLocally("sudo systemctl start map") # in case the HTTP server crashed

print("Terminating the renderer instance...")
runLocally(f"aws ec2 terminate-instances --region eu-central-1 --instance-ids {instanceInfo['InstanceId']}")
time.sleep(30)
