# DQ Minecraft Server tech docs

The server is running on [AWS EC2](https://aws.amazon.com/ec2/) in a dedicated _t3a.medium_ instance:

- [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/)
- 2-thread 2.5 GHz
- 4 GB RAM
- 100 GB SSD
- Physically in _eu-central-1a_ zone, that's in Frankfurt

The world is 700 MB in size, the map is 12 GB. Plus we store 10 last hourly world backups on-site.
100 GB of space should be plenty for a while.

AWS billing is managed by @deltaidea.

## Map rendering

Enter `--render-map` in the game chat and wait for a while. You'll see progress messages in the chat.

If there're no automated messages, you're not alone, this happens from time to time. Message @deltaidea or fix it yourself:

- Download the SSH key from Trello (see the tech details card) and save it to `~/.ssh`
- Log into the VM using `ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com`
- Run `screen -S minecraft_watch_commands -X quit` to kill the command detection loop
- Run `screen -dmS minecraft_watch_commands ~/scripts/minecraft_watch_commands.py` to restart it
- Quit the VM using `exit`
- Try writing `--render-map` in the game chat again

It takes about 10-15 minutes to render the map. Here's what the rendering script does specifically:

- Spins up a separate insanely powerful EC2 instance using AWS API
- Makes a world backup and copies it over to the renderer instance.
- Installs Overviewer over there and downloads our map config: https://github.com/dq-server/overviewer-config
- Renders the map (this step takes 8-12 minutes)
- Syncs the map to the main instance
- Terminates the rendering instance because it costs $5 an hour to run

## Shutting down and restarting the server

- To safely shut down the server, enter `--system-shutdown` in the game chat.
- To start the server, open https://manage.minecraft.deltaidea.com and enter the access key from Trello.

## Backups

We're running two backup strategies:

- Hourly backups on-site - to a folder next to the Minecraft server. Only the last 10 hourly backups are stored.
- Weekly backups off-site - to AWS Glacier. They're stored forever.

To recover from an hourly backup, log into the server (`ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com`) and run:

```sh
# Look at the dates and choose a suitable backup
ls -lhAF ~/minecraft-backups
# Change the argument to the backup number, in this case we're using backup-5
~/scripts/minecraft_restore.sh 5
```

You can also download an hourly backup to your PC by running the following command on your machine:

```sh
scp -r -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com:~/minecraft-backups/backup-0 ./world-backup
```

To recover from a weekly off-site backup, message @deltaidea.

## Cron and autorun

We have three `systemctl` services running on the server: one for Minecraft, an HTTP server for the map, and one for DynDNS updating. They all start automatically after a reboot.

`minecraft.service` also spawns a separate process that watches game logs to respond to our custom commands described above.

There're three cron jobs: two for backups and another one for LetsEncrypt cert refreshing for our management API.

## HTTP Management API

The server has a custom little HTTP API, see `management_api.py`. It runs as a `systemctl` service, see `management_api.service`. It's available at https://minecraft.deltaidea.com:5000

This API is used by [manage.minecraft.deltaidea.com](https://manage.minecraft.deltaidea.com) to get Minecraft status. Minecraft only has TCP API, and JavaScript in browsers doesn't allow to send raw TCP packets. So in order to see Minecraft status on the page we have to get it from some kind of a backend. That's why we have this Python script.

There're two endpoints:

- `GET /minecraft-status` returns JSON with the game version and a list of players online. It calls `./minecraft_get_status.sh` internally to get this info.
- `GET /map-status` returns `{"status": 200}` after making a request to `127.0.0.1/overviewer.js` which should be successful if the map isn't down.

There's no authentication at this point, though it would be neat to have some kind of access control for potential future features like server shutdown or map refreshing.

### SSL

Because [manage.minecraft.deltaidea.com](https://manage.minecraft.deltaidea.com) uses HTTPS, JavaScript on that page can't make unencrypted HTTP requests. So to make requests to the management API, it has to have SSL enabled. We're using [Let's Encrypt](https://letsencrypt.org) for that. You don't have to back up any credentials or anything, this is just FYI. See [Migration guide](migration_guide.md) for more info about how it's installed.

## Migrating to another machine

If there's ever a need to migrate to a new machine, we've documented the installation process in [`migration_guide.md`](migration_guide.md).
