# Docker Host Disk Space Getting Full – Identifying the Issue

## Quick Diagnosis Flow
```
df -h → docker system df → identify top consumer → clean / fix → prevent recurrence
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Unused Docker images** | Old, pulled, or intermediate build images accumulate | `docker images -a` — list all images with sizes | `docker image prune -a` — removes all unused images |
| 2 | **Dangling images (untagged)** | Failed or intermediate builds leave `<none>:<none>` images | `docker images -f dangling=true` | `docker image prune` — removes only dangling images |
| 3 | **Stopped containers not removed** | Containers stopped but not deleted retain filesystem layers | `docker ps -a` — many stopped containers | `docker container prune` / use `--rm` flag on run |
| 4 | **Unused volumes** | Named/anonymous volumes left behind after containers are deleted | `docker volume ls` — many orphaned volumes | `docker volume prune` — removes all unused volumes |
| 5 | **Unused networks** | Custom networks not cleaned up | `docker network ls` — many custom networks | `docker network prune` |
| 6 | **Large build cache** | `docker build` caches every layer; cache grows with repeated builds | `docker system df` — `Build Cache` row shows size | `docker builder prune` or `docker builder prune -a` |
| 7 | **Container logs growing too large** | JSON log files for containers grow unbounded | `du -sh /var/lib/docker/containers/*/*-json.log` | Set log limits in daemon or per-container (see below) |
| 8 | **Large volumes with app data** | App writing too much data (DB, logs, uploads) to a volume | `docker exec <container> du -sh /data` | Archive old data; add log rotation; move to external storage |
| 9 | **Many image layers from frequent rebuilds** | CI/CD rebuilding images repeatedly, filling up overlay2 | `du -sh /var/lib/docker/overlay2/` | Add `--no-cache` selectively; push and prune old image tags |
| 10 | **Bind mount consuming host space** | Container writes to a host path via bind mount | `df -h` + `du -sh /host/path` | Limit data written; add log rotation; clean old files |

---

## Key Diagnostic Commands

```bash
# Overall disk usage summary
df -h

# Docker-specific usage breakdown
docker system df

# Detailed Docker usage (verbose)
docker system df -v

# Find top disk users on host
du -sh /var/lib/docker/*

# Check overlay2 (image layers)
du -sh /var/lib/docker/overlay2/

# Check container log sizes
du -sh /var/lib/docker/containers/*/*-json.log | sort -rh | head -10

# List all images with size
docker images --format "{{.Size}}\t{{.Repository}}:{{.Tag}}" | sort -rh | head -20

# List volumes
docker volume ls

# Check volume disk usage
docker system df -v | grep -A20 "VOLUME NAME"
```

---

## Cleanup Commands

```bash
# Safe full cleanup (removes stopped containers, dangling images, unused networks, cache)
docker system prune

# Aggressive cleanup (also removes unused images, not just dangling)
docker system prune -a

# Individual cleanups
docker container prune     # stopped containers
docker image prune -a      # unused images
docker volume prune        # unused volumes
docker network prune       # unused networks
docker builder prune       # build cache
docker builder prune -a    # all build cache
```

---

## Prevent Log Files from Growing

```json
// /etc/docker/daemon.json — set global log limits
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
```

```bash
# Per-container log limit
docker run --log-opt max-size=50m --log-opt max-file=3 myapp
```

---

## Automate Cleanup (Cron)

```bash
# Add to crontab: run cleanup every Sunday at 2 AM
0 2 * * 0 docker system prune -f >> /var/log/docker-cleanup.log 2>&1
```

---

## 6-Step Checklist
```bash
df -h                                          # 1. check overall disk
docker system df                               # 2. Docker usage breakdown
docker system df -v                            # 3. identify top consumers
du -sh /var/lib/docker/containers/*/*-json.log # 4. check log file sizes
docker images -a | sort -k7 -rh               # 5. find large images
docker system prune -a                         # 6. clean up safely
```

---

> **Key Principle:** Run `docker system df` first — it breaks down disk usage by images, containers, volumes, and build cache so you know exactly where to clean.
