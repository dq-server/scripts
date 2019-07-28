# Техническая документация по серверу Майнкрафта

Сервер крутится в [AWS EC2](https://aws.amazon.com/ec2/) в инстансе _t3a.small_:

- [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/)
- 2-thread 2.5 GHz
- 2 GB RAM
- 20 GB SSD
- Физически мы в зоне _eu-central-1a_, во Франкфурте

Мир весит 350 MB, веб-карта – 6 GB. Места должно хватить ещё надолго.

Биллинг AWS идёт в сторону @deltaidea.

## Рендер карты

Нужно залогиниться в инстанс (`ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com`) и выполнить:

```sh
cd ~/scripts && python map_render.py
```

Рендер занимает 30-60 минут. Работает этот скрипт так:

- Создаёт новый, гораздо более мощный инстанс (через API AWS).
- Делает бэкап мира и кидает его в инстанс для рендера.
- Устанавливает там Overviewer и качает туда конфиг из https://github.com/dq-server/overviewer-config
- Рендерит карту (это самый долгий шаг)
- Копирует её по сети обратно на инстанс с Майнкрафтом
- Уничтожает инстанс для рендера, чтобы не тратить деньги

## Бэкапы

Мир бэкапится каждый час в соседнюю папку прямо на инстансе. Хранятся только последние 10 бэкапов.

Возможно, стоит настроить бэкапы в AWS S3, но пока их нету.

Чтобы восстановиться из бэкапа, нужно залогиниться в инстанс (`ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com`) и выполнить:

```sh
# Look at the dates and choose a suitable backup
ls -lhAF ~/minecraft-backups
# Change the argument to the backup number, in this case we're using backup-5
~/scripts/minecraft_restore.sh 5
```

Можно скачать себе последний бэкап, если хочется. Нужно выполнить это на своей машине:

```sh
scp -r -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com:~/minecraft-backups/backup-0 ./world-backup
```

## Крон и автозапуск после ребута

На сервере есть три сервиса systemctl: для Майнкрафта, для HTTP сервера карты, для DynDNS. Они все сами запускаются после ребута.

Есть одно правило crontab: каждый час делать бэкап мира.

## Запуск инстанса с нуля

Если придётся поменять тип инстанса или зону хостинга, вот как переехать.

### Скачиваем мир со старого инстанса

Нужно иметь ключ для входа в **старый** инстанс по SSH, чтобы скачать оттуда мир. Предположим, ключ локально лежит в `~/.ssh/minecraft-ec2.pem`.

```sh
# Stop the server
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com "sudo systemctl disable minecraft"
# Copy the world, whitelist, etc. to the local machine
scp -r -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com:~/minecraft ./
# Remember the DynDNS password
scp -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com:~/.dyndns_password ./
# Shut down the instance to save on AWS costs
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com "sudo shutdown"
```

### Конфигурируем новый инстанс

При создании новой машинки нужно указать следующее:

- Как минимум 2 GB оперативы и 20 GB места
- Amazon Linux 2 при выборе операционки (просто самый свежий, первый в списке)
- Включить публичный DNS, чтобы была связь. Статичный IP не нужен, и он всё равно платный
- Обязательно тыкнуть галочку Termination Protection, чтобы не было даже шанса потом случайно удалить инстанс
- Разрешить входящий трафик на портах TCP/22 (SSH), TCP/80 (карта), TCP/443 (HTTPS для общения с API AWS), TCP+UDP/25565 (Майнкрафт)

### Загружаем мир на новый инстанс

Нужно иметь на руках ключ для входа в **новый** инстанс (`~/.ssh/minecraft-ec2.pem`), папку со скриптами (в которой этот README) и скачанную папку с миром.

```sh
# Upload the world
cd <BACKUP WITH THE WORLD, WHITELIST, ETC>
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<INSTANCE_ADDRESS> "mkdir minecraft"
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<INSTANCE_ADDRESS>:~/minecraft/

# Upload the management scripts
cd <DIRECTORY WITH START-STOP-BACKUP SCRIPTS>
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<INSTANCE_ADDRESS> "mkdir scripts"
scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@<INSTANCE_ADDRESS>:~/scripts/

# Upload the private key for map rendering
scp -r -i ~/.ssh/minecraft-ec2.pem ~/.ssh/minecraft-ec2.pem ec2-user@<INSTANCE_ADDRESS>:~/.ssh/

# Provide the DynDNS password
scp -i ~/.ssh/minecraft-ec2.pem ec2-user@<INSTANCE_ADDRESS>:~/.dyndns_password ./

# Set up services, crontab, etc.
ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@<INSTANCE_ADDRESS> ./system_init_instance.sh
```
