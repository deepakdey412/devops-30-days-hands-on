# Docker Container Keeps Restarting – Investigation Guide

## Quick Diagnosis Flow
```
docker ps -a → docker logs <container> → inspect exit code → fix root cause → redeploy
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **App crashes on startup** | Unhandled exception or missing dependency in the app | `docker logs <container_id>` — look for stack trace or error message | Fix the application bug, ensure all dependencies are installed in the image |
| 2 | **Exit code 1 (General Error)** | App exited with a non-zero code due to config/runtime error | `docker inspect <container> --format='{{.State.ExitCode}}'` | Check app logs, fix misconfiguration or runtime error |
| 3 | **Exit code 137 (OOM Kill)** | Container ran out of memory; kernel killed the process | `docker inspect <container> \| grep OOMKilled` → `true` | Increase memory limit: `docker run -m 512m ...` or fix memory leak |
| 4 | **Exit code 139 (Segfault)** | Segmentation fault in the application or its libraries | `docker logs <container>` + check `dmesg` on host | Rebuild image with correct base, check for corrupt binaries |
| 5 | **Restart policy set to `always`** | Docker automatically restarts the container even on healthy exit | `docker inspect <container> \| grep RestartPolicy` | Change policy: `--restart=on-failure:5` instead of `always` |
| 6 | **Missing environment variables** | App fails because required ENV vars are not set | `docker logs <container>` — look for `KeyError`, `undefined variable` | Pass correct env vars: `docker run -e VAR=value ...` or use `.env` file |
| 7 | **Port or file already in use** | App can't bind to port or access a file that is locked | `docker logs <container>` — `Address already in use` | Stop conflicting process or change the app's port mapping |
| 8 | **Entrypoint / CMD misconfigured** | Wrong command causes immediate crash | `docker inspect <container> --format='{{.Config.Cmd}}'` | Fix `ENTRYPOINT` or `CMD` in Dockerfile; test with `docker run -it --entrypoint /bin/sh <image>` |
| 9 | **Volume mount permission error** | Container process can't read/write mounted volume | `docker logs <container>` — `Permission denied` | Fix: `chown -R <user>:<group>` on the host path or use `--user` flag |
| 10 | **Healthcheck failing repeatedly** | Docker marks container unhealthy and restarts it | `docker inspect <container> \| grep -A5 Health` | Fix the healthcheck endpoint or increase `--health-retries` and `--health-timeout` |

---

## Key Diagnostic Commands

```bash
# See container status and restart count
docker ps -a

# View logs (last 50 lines)
docker logs --tail 50 <container_id>

# Follow live logs
docker logs -f <container_id>

# Get exit code
docker inspect <container_id> --format='{{.State.ExitCode}}'

# Check if OOM killed
docker inspect <container_id> | grep OOMKilled

# Check restart policy
docker inspect <container_id> | grep -A3 RestartPolicy

# Check healthcheck status
docker inspect <container_id> | grep -A10 Health

# Run interactively to debug
docker run -it --entrypoint /bin/sh <image_name>

# Check resource usage
docker stats <container_id>
```

---

## Exit Code Reference

| Exit Code | Meaning | Common Cause |
|-----------|---------|--------------|
| `0` | Clean exit | App finished (check restart policy) |
| `1` | General error | App crash, config issue |
| `137` | OOM / SIGKILL | Out of memory or `docker stop` |
| `139` | Segfault | Binary or library corruption |
| `143` | SIGTERM | Graceful shutdown signal |

---

## 6-Step Checklist
```bash
docker ps -a                                      # 1. check restart count
docker logs --tail 100 <container>                # 2. read error logs
docker inspect <container> | grep ExitCode        # 3. get exit code
docker inspect <container> | grep OOMKilled       # 4. check OOM
docker inspect <container> | grep RestartPolicy   # 5. check restart policy
docker run -it --entrypoint /bin/sh <image>       # 6. debug interactively
```

---

> **Key Principle:** The exit code + logs together always tell the story. Never restart without first reading the logs.
