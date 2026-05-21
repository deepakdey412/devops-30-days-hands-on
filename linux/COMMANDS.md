# 🐧 Linux Commands for DevOps — Complete Field Guide

> **Why this matters:** Every CI pipeline, every Kubernetes node, every cloud server runs Linux. You don't need to memorize everything — you need to know what exists and where to reach for it.

---

## 📋 Table of Contents

1. [File System Navigation](#1-file-system-navigation)
2. [File Operations](#2-file-operations)
3. [File Permissions & Ownership](#3-file-permissions--ownership)
4. [Viewing & Searching File Content](#4-viewing--searching-file-content)
5. [Process Management](#5-process-management)
6. [Disk & Memory Usage](#6-disk--memory-usage)
7. [Networking](#7-networking)
8. [User & Group Management](#8-user--group-management)
9. [Package Management](#9-package-management)
10. [Archiving & Compression](#10-archiving--compression)
11. [System Services — systemctl](#11-system-services--systemctl)
12. [Shell & Environment](#12-shell--environment)
13. [Cron Jobs — Task Scheduling](#13-cron-jobs--task-scheduling)
14. [SSH & Remote Access](#14-ssh--remote-access)
15. [Log Management](#15-log-management)
16. [DevOps-Specific Power Commands](#16-devops-specific-power-commands)
17. [Cheat Sheet — Quick Reference](#17-cheat-sheet--quick-reference)

---

## 1. File System Navigation

The filesystem is where everything starts. Knowing your way around is non-negotiable.

```bash
pwd                    # print current working directory
ls                     # list files
ls -la                 # list all files (including hidden) with permissions + size
ls -lh                 # human-readable file sizes (KB, MB, GB)
cd /var/log            # change to absolute path
cd ..                  # go one directory up
cd ~                   # go to home directory
cd -                   # go back to previous directory (very useful)
tree                   # visual directory tree (install if missing)
tree -L 2              # tree with max depth of 2 levels
```

**DevOps context:** You'll live in `/etc` (configs), `/var/log` (logs), `/opt` (apps), `/tmp` (temp files), `/home` (users), `/proc` (system info).

```bash
# Important directories every DevOps engineer knows:
/etc/nginx/            # Nginx config
/var/log/syslog        # system logs (Ubuntu)
/var/log/messages      # system logs (CentOS/RHEL)
/etc/systemd/system/   # service unit files
/proc/meminfo          # live memory stats
/proc/cpuinfo          # CPU details
```

---

## 2. File Operations

```bash
touch file.txt              # create empty file / update timestamp
mkdir app                   # create directory
mkdir -p /opt/app/config    # create nested directories in one shot
cp file.txt backup.txt      # copy file
cp -r dir1/ dir2/           # copy directory recursively
mv old.txt new.txt          # rename / move file
rm file.txt                 # delete file
rm -rf /tmp/old-build/      # force delete directory recursively (be careful)
ln -s /opt/app/bin/app /usr/local/bin/app  # create symlink
find / -name "nginx.conf"   # find file by name from root
find /var/log -name "*.log" -mtime -7      # logs modified in last 7 days
```

> ⚠️ `rm -rf` with wrong path has deleted production systems. Always double-check the path. Consider `rm -i` (interactive) when unsure.

---

## 3. File Permissions & Ownership

Linux permissions are the foundation of system security. DevOps engineers deal with these constantly.

```bash
ls -l file.txt
# Output: -rwxr-xr-- 1 ubuntu devops 1024 Jan 10 file.txt
#          ─┬──────── ─ ─────── ──────
#           │          owner   group
#           └── permissions (owner | group | others)
```

### Permission Breakdown

```
r = read    (4)
w = write   (2)
x = execute (1)

rwx = 4+2+1 = 7
rw- = 4+2+0 = 6
r-x = 4+0+1 = 5
r-- = 4+0+0 = 4
```

```bash
chmod 755 script.sh         # rwxr-xr-x  (owner: full, others: read+exec)
chmod 644 config.yml        # rw-r--r--  (owner: read+write, others: read)
chmod 600 ~/.ssh/id_rsa     # rw-------  (private key — only owner reads)
chmod +x deploy.sh          # add execute permission to everyone
chmod -R 755 /opt/app/      # apply recursively to directory

chown ubuntu file.txt       # change owner
chown ubuntu:devops file.txt # change owner and group
chown -R ubuntu:ubuntu /opt/app/  # recursive ownership change
```

**DevOps context:** SSH keys must be `600`. Web server files typically `644`. Scripts need `755`. Wrong permissions = service won't start or SSH won't work.

---

## 4. Viewing & Searching File Content

```bash
cat file.txt               # print entire file
cat -n file.txt            # print with line numbers
less file.txt              # scroll through file (q to quit)
head file.txt              # first 10 lines
head -n 50 file.txt        # first 50 lines
tail file.txt              # last 10 lines
tail -n 100 file.txt       # last 100 lines
tail -f /var/log/app.log   # live follow log (Ctrl+C to stop)
tail -f /var/log/app.log | grep ERROR   # live follow + filter errors
```

### grep — The Most Used DevOps Command

```bash
grep "error" app.log                   # find lines containing "error"
grep -i "error" app.log                # case-insensitive
grep -r "DB_HOST" /etc/               # search recursively in directory
grep -n "FAILED" deploy.log            # show line numbers
grep -v "DEBUG" app.log                # exclude lines with DEBUG
grep -c "timeout" app.log             # count matching lines
grep -A 3 "Exception" app.log         # 3 lines after match (context)
grep -B 3 "Exception" app.log         # 3 lines before match
grep "ERROR\|WARN" app.log            # multiple patterns (OR)
```

### sed & awk — Text Processing

```bash
# sed — stream editor (find & replace)
sed 's/old/new/g' file.txt            # replace all occurrences (stdout only)
sed -i 's/old/new/g' file.txt         # replace in-place (modifies file)
sed -i 's/localhost/prod-db/g' app.conf  # swap DB host in config

# awk — column/field processing
awk '{print $1}' file.txt             # print first column
awk -F: '{print $1}' /etc/passwd      # print usernames (: delimiter)
awk '/ERROR/ {print $0}' app.log      # print lines containing ERROR
ps aux | awk '{print $1, $11}'        # print user + command from ps
```

---

## 5. Process Management

```bash
ps aux                     # all running processes (user, PID, CPU, MEM, CMD)
ps aux | grep nginx        # find nginx process
pgrep nginx                # get PID of nginx
pidof nginx                # same as pgrep

top                        # live process monitor (q to quit)
htop                       # better top (install separately)

kill 1234                  # graceful stop (SIGTERM) by PID
kill -9 1234               # force kill (SIGKILL) — no cleanup
killall nginx              # kill all processes named nginx
pkill -f "python app.py"   # kill by matching full command string

nohup ./script.sh &        # run in background, survives terminal close
./script.sh &              # run in background (dies if terminal closes)
jobs                       # list background jobs
fg 1                       # bring job 1 to foreground
bg 1                       # send job 1 to background
```

**DevOps context:** `kill -9` is the last resort — it doesn't let the process clean up. Always try `kill` (SIGTERM) first. In containers, PID 1 must handle signals properly.

---

## 6. Disk & Memory Usage

```bash
df -h                      # disk usage of all mounted filesystems
df -h /                    # disk usage of root partition
du -sh /var/log/           # size of a directory
du -sh *                   # size of each item in current directory
du -sh /* | sort -h        # sorted by size — find space hogs

free -h                    # memory usage (RAM + swap) in human-readable
free -m                    # in megabytes
vmstat 1 5                 # memory/cpu/io stats every 1s, 5 times

lsblk                      # list block devices (disks, partitions)
fdisk -l                   # disk partition details
mount | grep /dev          # show mounted devices
```

**DevOps context:** Disk full = services crash. Always set up disk alerts. `/var/log` and `/var/lib/docker` are common culprits.

```bash
# Quick way to find what's eating disk:
du -sh /var/* | sort -rh | head -10
du -sh /var/lib/docker/    # Docker images/containers
journalctl --disk-usage    # systemd journal size
```

---

## 7. Networking

```bash
ip addr                    # show IP addresses (replaces ifconfig)
ip addr show eth0          # specific interface
ip route                   # routing table
ip link                    # network interfaces state

ping google.com            # test connectivity
ping -c 4 google.com       # ping exactly 4 times

curl https://api.example.com           # make HTTP GET request
curl -I https://example.com            # headers only
curl -X POST -H "Content-Type: application/json" \
  -d '{"key":"value"}' https://api.example.com   # POST with JSON
curl -o file.tar.gz https://example.com/file.tar.gz  # download file

wget https://example.com/file.tar.gz   # download file
wget -q --spider https://example.com   # check if URL is reachable (quiet)

netstat -tulnp             # listening ports + process (older systems)
ss -tulnp                  # same but faster (modern replacement)
ss -tulnp | grep :80       # check what's on port 80

nmap -sV localhost         # scan open ports
telnet db-host 5432        # test if port is reachable
nc -zv db-host 5432        # same with netcat (better)

dig google.com             # DNS lookup
nslookup google.com        # DNS lookup (simpler output)
host google.com            # DNS lookup (simplest)

traceroute google.com      # trace network path to host
```

**DevOps context:** `ss -tulnp` is the most-used command when a service won't connect — instantly tells you what's listening on what port under which process.

---

## 8. User & Group Management

```bash
whoami                     # current user
id                         # current user UID, GID, groups
id username                # info about specific user
w                          # who is logged in and what they're doing
last                       # login history

useradd -m -s /bin/bash deploy        # create user with home + bash shell
passwd deploy                         # set password for user
usermod -aG docker deploy             # add user to docker group
usermod -aG sudo deploy               # give sudo access
userdel -r olduser                    # delete user + home directory

groupadd devops            # create group
groupdel devops            # delete group
groups deploy              # list groups for user

su - deploy                # switch to user (full environment)
sudo command               # run command as root
sudo -u deploy command     # run command as specific user
visudo                     # safely edit sudoers file
```

**DevOps context:** Running apps as root is a security risk. Always create a dedicated service user. Adding to `docker` group = passwordless docker access (effectively root on that system).

---

## 9. Package Management

### Ubuntu / Debian (apt)

```bash
apt update                          # refresh package list
apt upgrade                         # upgrade all packages
apt install nginx                   # install package
apt install -y nginx curl git       # install multiple, auto-confirm
apt remove nginx                    # remove package (keep config)
apt purge nginx                     # remove package + config files
apt autoremove                      # remove unused dependencies
apt search nginx                    # search packages
apt show nginx                      # package details
dpkg -l | grep nginx                # check if installed
```

### CentOS / RHEL (yum / dnf)

```bash
yum update                          # update all
yum install nginx                   # install
yum remove nginx                    # remove
yum search nginx                    # search
dnf install nginx                   # dnf (newer RHEL/CentOS 8+)
rpm -qa | grep nginx                # check if installed
```

---

## 10. Archiving & Compression

```bash
# tar — most common in DevOps
tar -czf archive.tar.gz /opt/app/        # create gzip archive
tar -cjf archive.tar.bz2 /opt/app/      # create bzip2 archive (smaller)
tar -xzf archive.tar.gz                  # extract gzip archive
tar -xzf archive.tar.gz -C /opt/        # extract to specific directory
tar -tzf archive.tar.gz                  # list contents without extracting

# zip / unzip
zip -r app.zip /opt/app/                 # create zip
unzip app.zip                            # extract zip
unzip app.zip -d /opt/                   # extract to directory
unzip -l app.zip                         # list contents

# gzip
gzip file.txt                            # compress (replaces original)
gunzip file.txt.gz                       # decompress
gzip -k file.txt                         # compress and keep original
```

**Memory trick for tar:** `czf` = **C**reate **Z**ip **F**ile | `xzf` = e**X**tract **Z**ip **F**ile

---

## 11. System Services — systemctl

The most important service management tool in modern Linux (systemd).

```bash
systemctl status nginx             # check service status
systemctl start nginx              # start service
systemctl stop nginx               # stop service
systemctl restart nginx            # stop + start
systemctl reload nginx             # reload config without downtime
systemctl enable nginx             # auto-start on boot
systemctl disable nginx            # remove from auto-start
systemctl is-active nginx          # returns "active" or "inactive"
systemctl is-enabled nginx         # returns "enabled" or "disabled"

systemctl list-units --type=service           # all services
systemctl list-units --type=service --state=failed  # failed services
systemctl daemon-reload            # reload systemd after unit file change
```

### Writing a Service Unit File

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload            # pick up new unit file
systemctl enable --now myapp       # enable + start immediately
```

---

## 12. Shell & Environment

```bash
echo $PATH                         # print PATH variable
echo $HOME                         # print home directory
env                                # list all environment variables
printenv DB_HOST                   # print specific variable

export DB_HOST=prod-db.internal    # set env variable (current session)
export PATH=$PATH:/opt/myapp/bin   # add to PATH

# Make permanent — add to ~/.bashrc or ~/.profile:
echo 'export DB_HOST=prod-db.internal' >> ~/.bashrc
source ~/.bashrc                   # reload without restarting terminal

history                            # command history
history | grep docker              # search history
!!                                 # run last command again
!curl                              # run last command starting with "curl"
Ctrl+R                             # reverse search through history

alias ll='ls -la'                  # create shortcut
alias k='kubectl'                  # DevOps favourite
unalias ll                         # remove alias
```

### Useful Shell Tricks

```bash
command1 && command2       # run command2 ONLY if command1 succeeds
command1 || command2       # run command2 ONLY if command1 fails
command1 ; command2        # run both regardless

# Redirect output
command > file.txt         # stdout to file (overwrite)
command >> file.txt        # stdout to file (append)
command 2> error.log       # stderr to file
command > out.txt 2>&1     # both stdout and stderr to file
command 2>/dev/null        # discard errors

# Pipe output
ps aux | grep nginx | grep -v grep
cat app.log | grep ERROR | wc -l   # count error lines
```

---

## 13. Cron Jobs — Task Scheduling

```bash
crontab -e                 # edit cron jobs for current user
crontab -l                 # list cron jobs
crontab -r                 # remove all cron jobs
crontab -u deploy -l       # list cron jobs for specific user
```

### Cron Syntax

```
*  *  *  *  *   command
│  │  │  │  │
│  │  │  │  └── Day of week (0-7, 0=Sunday)
│  │  │  └───── Month (1-12)
│  │  └──────── Day of month (1-31)
│  └─────────── Hour (0-23)
└────────────── Minute (0-59)
```

### Common Cron Examples

```bash
# Every minute
* * * * * /opt/scripts/check.sh

# Every day at 2 AM
0 2 * * * /opt/scripts/backup.sh

# Every Monday at 9 AM
0 9 * * 1 /opt/scripts/weekly-report.sh

# Every 15 minutes
*/15 * * * * /opt/scripts/healthcheck.sh

# First day of every month at midnight
0 0 1 * * /opt/scripts/monthly-cleanup.sh

# Redirect output to log
0 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## 14. SSH & Remote Access

```bash
ssh user@host                          # connect to remote server
ssh -p 2222 user@host                  # custom port
ssh -i ~/.ssh/mykey.pem user@host      # with specific private key
ssh -L 8080:localhost:80 user@host     # local port forwarding
ssh -R 9090:localhost:3000 user@host   # remote port forwarding

scp file.txt user@host:/opt/app/       # copy file to remote
scp user@host:/var/log/app.log ./      # copy file from remote
scp -r ./app/ user@host:/opt/          # copy directory to remote

rsync -avz ./app/ user@host:/opt/app/  # sync directory (only changed files)
rsync -avz --delete ./app/ user@host:/opt/app/  # sync + delete remote extras
```

### SSH Key Setup

```bash
ssh-keygen -t ed25519 -C "your@email.com"    # generate key pair (Ed25519 recommended)
ssh-keygen -t rsa -b 4096 -C "your@email.com"  # RSA 4096-bit alternative

# Copy public key to server
ssh-copy-id user@host
# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh user@host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Fix permissions (SSH is strict about this)
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
```

### SSH Config File (`~/.ssh/config`)

```ini
Host prod
  HostName 10.0.1.50
  User deploy
  IdentityFile ~/.ssh/prod_key.pem
  Port 22

Host bastion
  HostName bastion.company.com
  User ubuntu
  IdentityFile ~/.ssh/bastion.pem
```

```bash
ssh prod          # connects using config above
ssh bastion       # connects using bastion config
```

---

## 15. Log Management

```bash
# Real-time log following
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
tail -f /var/log/syslog

# systemd journal logs
journalctl -u nginx                    # logs for nginx service
journalctl -u nginx -f                 # follow live
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-10 09:00:00"
journalctl -p err                      # only error-level logs
journalctl --disk-usage                # how much space journal uses
journalctl --vacuum-time=7d            # delete logs older than 7 days

# Search and filter logs
grep "500" /var/log/nginx/access.log | wc -l     # count 500 errors
grep "$(date +%d/%b/%Y)" /var/log/nginx/access.log  # today's entries
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn  # HTTP status codes count
```

---

## 16. DevOps-Specific Power Commands

These aren't in textbooks — they come from real production experience.

```bash
# Watch a command output refresh every 2 seconds
watch -n 2 'kubectl get pods'
watch -n 1 'df -h /'

# xargs — apply command to each line of output
cat servers.txt | xargs -I {} ssh {} 'uptime'
find . -name "*.log" | xargs rm -f

# cut — extract columns
cut -d: -f1 /etc/passwd                # extract usernames
cut -d, -f1,3 data.csv                 # extract columns 1 and 3

# wc — count lines, words, chars
wc -l app.log                          # count lines in log
cat app.log | grep ERROR | wc -l       # count error lines

# sort + uniq — find patterns
sort file.txt                          # sort lines
sort -r file.txt                       # reverse sort
sort -k2 -n file.txt                   # sort by column 2, numerically
uniq -c sorted.txt                     # count duplicate lines
sort file.txt | uniq -c | sort -rn     # frequency analysis

# date — useful in scripts
date                                   # current date + time
date +%Y-%m-%d                         # formatted date: 2024-01-10
date +%s                               # Unix timestamp
date -d "7 days ago" +%Y-%m-%d        # date 7 days ago

# tr — character replacement
echo "hello" | tr 'a-z' 'A-Z'         # uppercase
echo "a:b:c" | tr ':' ','             # replace delimiter

# tee — write to file AND stdout simultaneously
./deploy.sh 2>&1 | tee deploy.log     # see output + save to file

# timeout — kill command if it runs too long
timeout 30 ./healthcheck.sh           # kill after 30 seconds

# Check open files by process
lsof -p 1234                          # files opened by PID 1234
lsof -i :8080                         # what's using port 8080
lsof -u deploy                        # files opened by user deploy
```

---

## 17. Cheat Sheet — Quick Reference

### File System

| Command               | Description                     |
| --------------------- | ------------------------------- |
| `ls -la`              | List all files with permissions |
| `pwd`                 | Current directory               |
| `cd -`                | Previous directory              |
| `find / -name "file"` | Find file by name               |
| `tree -L 2`           | Directory tree (depth 2)        |

### File Operations

| Command             | Description                 |
| ------------------- | --------------------------- |
| `cp -r src/ dst/`   | Copy directory              |
| `mv old new`        | Move / rename               |
| `rm -rf dir/`       | Delete directory (careful!) |
| `ln -s target link` | Create symlink              |
| `touch file`        | Create empty file           |

### Permissions

| Command                 | Description            |
| ----------------------- | ---------------------- |
| `chmod 755 script.sh`   | rwxr-xr-x              |
| `chmod 644 file.txt`    | rw-r--r--              |
| `chmod 600 key.pem`     | rw------- (SSH keys)   |
| `chown user:group file` | Change ownership       |
| `chmod +x script.sh`    | Add execute permission |

### Viewing Files

| Command                  | Description             |
| ------------------------ | ----------------------- |
| `tail -f app.log`        | Live log follow         |
| `grep -i "error" log`    | Case-insensitive search |
| `grep -r "pattern" dir/` | Recursive search        |
| `less file`              | Scrollable view         |
| `wc -l file`             | Count lines             |

### Process Management

| Command                | Description          |
| ---------------------- | -------------------- |
| `ps aux`               | All processes        |
| `ps aux \| grep nginx` | Find process         |
| `kill -9 PID`          | Force kill           |
| `top` / `htop`         | Live monitor         |
| `nohup cmd &`          | Background + persist |

### Disk & Memory

| Command                 | Description        |
| ----------------------- | ------------------ |
| `df -h`                 | Disk usage         |
| `du -sh dir/`           | Directory size     |
| `free -h`               | Memory usage       |
| `du -sh /* \| sort -rh` | Find space hogs    |
| `lsblk`                 | List block devices |

### Networking

| Command            | Description            |
| ------------------ | ---------------------- |
| `ss -tulnp`        | Open ports + processes |
| `curl -I url`      | HTTP headers only      |
| `ping -c 4 host`   | Test connectivity      |
| `nc -zv host port` | Test port reachable    |
| `dig domain`       | DNS lookup             |

### Services

| Command                               | Description        |
| ------------------------------------- | ------------------ |
| `systemctl status svc`                | Service status     |
| `systemctl restart svc`               | Restart service    |
| `systemctl enable svc`                | Auto-start on boot |
| `journalctl -u svc -f`                | Live service logs  |
| `systemctl list-units --state=failed` | Failed services    |

### SSH

| Command                          | Description         |
| -------------------------------- | ------------------- |
| `ssh user@host`                  | Connect to server   |
| `scp file user@host:path`        | Copy file to remote |
| `rsync -avz src/ user@host:dst/` | Sync directory      |
| `ssh-keygen -t ed25519`          | Generate key pair   |
| `ssh-copy-id user@host`          | Copy key to server  |

### Compression

| Command                    | Description             |
| -------------------------- | ----------------------- |
| `tar -czf out.tar.gz dir/` | Create archive          |
| `tar -xzf archive.tar.gz`  | Extract archive         |
| `tar -tzf archive.tar.gz`  | List contents           |
| `unzip file.zip -d dir/`   | Extract zip             |
| `gzip -k file`             | Compress, keep original |

### Power Commands

| Command               | Description                  |
| --------------------- | ---------------------------- |
| `watch -n 2 'cmd'`    | Repeat command every 2s      |
| `cmd \| tee file.log` | Output to screen + file      |
| `cmd1 && cmd2`        | Run cmd2 only if cmd1 passes |
| `cmd 2>/dev/null`     | Suppress errors              |
| `history \| grep ssh` | Search command history       |

---

## ⚡ Must-Know One-Liners

```bash
# Find and kill process on a port
kill $(lsof -t -i:8080)

# Check last 100 errors in log with timestamp
grep "ERROR" app.log | tail -100

# Disk usage sorted, top 10
du -sh /var/* | sort -rh | head -10

# Count HTTP status codes in nginx log
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Test if a service is up from inside a container
nc -zv postgres 5432 && echo "DB reachable" || echo "DB unreachable"

# Create a backup with timestamp
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz /opt/app/

# Watch memory every second
watch -n 1 free -h

# Find all files modified in last 24 hours
find /opt/app -mtime -1 -type f

# Run last command as sudo
sudo !!

# Show real-time network connections
watch -n 1 'ss -tulnp'
```

---

_These commands cover ~90% of what a DevOps engineer needs day-to-day. The other 10% you'll find in man pages: `man command` or `command --help`._

---

⭐ **Star this repo** · 👨‍💻 **Follow** → [github.com/deepak412](https://github.com/deepakdey412) · More DevOps guides dropping regularly.
