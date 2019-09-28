# Migration guide

Here we've recorded how to migrate to a new VM. This was last needed to migrate to a larger SSD.

You are encouraged to run the commands line by line, just in case something's changed since the last migration.
Please update this document as you go if something is different this time.

Before starting, make sure no one is playing and map render isn't currently running.

Do not terminate the old VM until you've made sure the new server is performing OK.

## Spin up the new host machine

When creating a new EC2 instance or otherwise preparing a machine, make sure it has:

- At least 4 GB RAM and 50 GB SSD; if you must make do with lower specs, adjust memory usage in [`minecraft_start.sh`](minecraft_start.sh)
- Amazon Linux 2 (based on RHEL so CentOS should be fine as well, but check first)
- Reachable from the internet (enable Public DNS in EC2 options). You don't need a static IP, we're using DynDNS
- Enable Termination Protection in EC2 options to prevent data loss
- Open ports TCP/22 (SSH), TCP/80 (map), TCP/443 (HTTPS to talk to AWS API), TCP/5000 (our management API), TCP+UDP/25565 (Minecraft)
- Use the same SSH key pair for seamless migration

## Copying over the world and config files

Pro Tip: It might be easier to follow this guide if you have two terminals open with SSH connections to the old and new machine.

Run the following on the old VM, substituting `<NEW_VM>` with the address of the new machine, e.g. `ec2-<...>.eu-central-1.compute.amazonaws.com`.

```sh
~/scripts/minecraft_stop.sh
~/scripts/map_stop.sh

cd ~/minecraft
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM> mkdir minecraft
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<NEW_VM>:~/minecraft/

cd ~/minecraft-backups
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM> mkdir minecraft-backups
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<NEW_VM>:~/minecraft-backups/

cd ~/overviewer/map
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM> mkdir overviewer
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM> mkdir overviewer/map
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<NEW_VM>:~/overviewer/map/

cd ~/scripts
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM> mkdir scripts
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<NEW_VM>:~/scripts/

scp -r -i ~/.ssh/minecraft-ec2.pem ~/.ssh/minecraft-ec2.pem ec2-user@<NEW_VM>:~/.ssh/

scp -r -i ~/.ssh/minecraft-ec2.pem ~/.dyndns_password ec2-user@<NEW_VM>:~/
```

## Starting up services on the new machine

Run the following on the new remote:

```sh
sudo yum update -y
sudo yum install -y java-1.8.0 nc epel-release python36 python36-pip
sudo amazon-linux-extras install epel -y
sudo yum install -y certbot

# IMPORTANT! This line requires interaction. It asks for email, etc.
# Email used previously: n@deltaidea.com
# Domain names: minecraft.deltaidea.com
sudo certbot certonly --standalone

sudo cp ./scripts/*.service /etc/systemd/system/
sudo systemctl daemon-reload

sudo systemctl enable --now dyndns
sudo systemctl enable --now minecraft
sudo systemctl enable --now map
sudo systemctl enable --now management_api
```

## Setting up cron jobs

Open up the cron job list for the current user (`ec2-user`) like this: `EDITOR=nano crontab -e`, and add two backup jobs:

```text
0 * * * * /home/ec2-user/scripts/minecraft_backup.sh
30 0 * * 1 /home/ec2-user/scripts/minecraft_backup_to_glacier.sh
```

The press `Ctrl+O` to save and `Ctrl+X` to exit.

Add LetsEncrypt certificate renewal job with sudo by running `sudo EDITOR=nano crontab -e` and adding:

```text
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew
```

You should see `crontab: installing new crontab` both times after saving and exiting.

To learn more about cron scheduling, see [Wikipedia](https://en.wikipedia.org/wiki/Cron).
