#!/usr/bin/env python3

# USAGE: ./map_render.py

# Creates a separate AWS EC2 instance, renders an Overviewer map there, and terminates the instance.

import os, sys, subprocess, time, json

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

SSH_OPTIONS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/minecraft-ec2.pem"

def runOnRemote(commandString):
  return runLocally(f"ssh {SSH_OPTIONS} ec2-user@{instanceAddress} {commandString}")

def syncToRemote(localPath, remotePath):
  return runLocally(f"rsync -e \"ssh {SSH_OPTIONS}\" -a -r --progress --delete {localPath} ec2-user@{instanceAddress}:{remotePath}")

def syncFromRemote(remotePath, localPath):
  return runLocally(f"rsync -e \"ssh {SSH_OPTIONS}\" -a -r --progress --delete ec2-user@{instanceAddress}:{remotePath} {localPath}")

if len(getInstances()) > 0:
  runLocally("screen -S minecraft -X stuff \"/say Unable to render the map. Previous render isn't finished.$(printf \\\\r)\"")
  print("ERROR! Not all previous t3a.2xlarge instances have been terminated. Aborting to avoid accumulating hosting costs.")
  exit(1)

print("Spinning up a t3a.2xlarge instance...")
runLocally("screen -S minecraft -X stuff \"/say Spinning up a new virtual machine...$(printf \\\\r)\"")
runLocally("aws ec2 run-instances --image-id ami-0cc293023f983ed53 --count 1 --instance-type t3a.2xlarge --key-name minecraft-ec2 --security-group-ids sg-099005316791a75b8 --subnet-id subnet-ff30fe95 --region eu-central-1 --block-device-mappings '[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp2\",\"DeleteOnTermination\":true}}]' --credit-specification CpuCredits=unlimited --tag-specifications 'ResourceType=instance,Tags=[{Key=purpose,Value=minecraft}]' 'ResourceType=volume,Tags=[{Key=purpose,Value=minecraft}]'")

runLocally("screen -S minecraft -X stuff \"/say Waiting 3 minutes for rendering VM to initialize...$(printf \\\\r)\"")
print("Waiting 3 minutes for the instance to initialize...")
time.sleep(180)

instanceInfo = getInstances()[0]
instanceAddress = instanceInfo["PrivateDnsName"]
print(f"Instance ready at {instanceAddress}...")
runLocally(f"screen -S minecraft -X stuff \"/say Rendering VM ready at {instanceAddress}...$(printf \\\\r)\"")

runLocally("~/scripts/minecraft_backup.sh")

runLocally("screen -S minecraft -X stuff \"/say Copying the latest backup to the rendering VM...$(printf \\\\r)\"")
print("Copying the latest backup to the renderer instance...")
syncToRemote("~/minecraft-backups/backup-0", "~/world-backup")

runLocally("screen -S minecraft -X stuff \"/say Copying the old map to the rendering VM...$(printf \\\\r)\"")
print("Copying previous render to the renderer instance...")
syncToRemote("~/overviewer/map", "~/previous-render")

runLocally("screen -S minecraft -X stuff \"/say Starting rendering, this may take 30-60 minutes...$(printf \\\\r)\"")
print("Initiating render procedure...")
syncToRemote("~/scripts/map_render_remote_script.sh", "~/")
runOnRemote("~/map_render_remote_script.sh")

runLocally("screen -S minecraft -X stuff \"/say Copying the newly rendered map to the server...$(printf \\\\r)\"")
print("Copying rendered map to the server instance...")
syncFromRemote("~/overviewer/map/", "~/overviewer/map")
runLocally("sudo systemctl start map") # in case the HTTP server crashed

runLocally("screen -S minecraft -X stuff \"/say Killing the rendering VM...$(printf \\\\r)\"")
print("Terminating the renderer instance...")
runLocally(f"aws ec2 terminate-instances --region eu-central-1 --instance-ids {instanceInfo['InstanceId']}")
time.sleep(30)
