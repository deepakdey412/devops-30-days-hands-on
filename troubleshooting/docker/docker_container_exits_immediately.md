# Container Exits Immediately After Startup – Steps to Take

## Quick Diagnosis Flow
```
docker ps -a (check status) → docker logs → check exit code → debug interactively → fix
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **No foreground process** | CMD/ENTRYPOINT runs a process that exits immediately (e.g. a shell script with no blocking call) | `docker logs <container>` — no output or instant exit | Ensure the main process runs in foreground; add `tail -f /dev/null` for debug or fix the app |
| 2 | **Wrong CMD / ENTRYPOINT** | Command in Dockerfile is incorrect, not found, or has wrong syntax | `docker logs <container>` — `exec: not found` / `no such file` | Fix CMD/ENTRYPOINT in Dockerfile; test with `docker run -it --entrypoint /bin/sh <image>` |
| 3 | **Script exits on error (set -e)** | Shell script uses `set -e`; any failing command exits the script | `docker logs <container>` — shows which command failed | Debug the failing command; remove `set -e` temporarily to identify it |
| 4 | **Missing dependency / binary** | App requires a library or binary not installed in the image | `docker logs <container>` — `cannot find library` / `command not found` | Add the missing package to the Dockerfile: `RUN apt-get install -y <package>` |
| 5 | **Missing or wrong config file** | App can't find its config file and exits with error | `docker logs <container>` — `config not found` / `no such file` | Mount config: `-v ./config.yaml:/app/config.yaml` or `COPY` in Dockerfile |
| 6 | **Missing environment variable** | App requires an ENV var and fails immediately if not set | `docker logs <container>` — `KeyError` / `undefined` / `required env var missing` | Pass env var: `docker run -e DB_URL=... <image>` or `--env-file .env` |
| 7 | **Permission denied on entrypoint script** | Script file not marked as executable | `docker logs <container>` — `permission denied` | Add to Dockerfile: `RUN chmod +x /app/entrypoint.sh` |
| 8 | **OOM (Out of Memory)** | Container hits memory limit immediately on startup | `docker inspect <container> \| grep OOMKilled` → `true` | Increase memory: `docker run -m 512m <image>` or fix memory leak |
| 9 | **Port already in use** | App fails to bind to a port that is already occupied inside the container | `docker logs <container>` — `Address already in use` | Fix port conflict or change the app's listen port |
| 10 | **Bad line endings (CRLF vs LF)** | Script created on Windows has `\r\n` line endings; Linux can't execute it | `docker logs <container>` — `/bin/bash^M: bad interpreter` | Convert: `dos2unix entrypoint.sh` and rebuild image |
| 11 | **Database / service not ready** | App tries to connect to DB on startup; DB not yet available; app exits | `docker logs <container>` — connection refused to DB | Add retry logic or use `wait-for-it.sh` / `dockerize` to wait for dependencies |
| 12 | **Architecture mismatch** | Image built for `arm64` but host is `amd64` or vice versa | `docker logs <container>` — `exec format error` | Rebuild for correct arch: `docker build --platform linux/amd64 .` |

---

## Key Diagnostic Commands

```bash
# Check container status (shows Exited + exit code)
docker ps -a

# Read logs of exited container
docker logs <container_id>

# Get exit code
docker inspect <container_id> --format='{{.State.ExitCode}}'

# Check OOM kill
docker inspect <container_id> | grep OOMKilled

# Debug interactively (override entrypoint)
docker run -it --entrypoint /bin/sh <image_name>

# Check if script is executable in image
docker run --rm --entrypoint ls <image_name> -la /app/

# Run with more memory
docker run -m 512m <image_name>

# Check for CRLF in scripts
file entrypoint.sh
cat -A entrypoint.sh | head -5    # ^M at end = CRLF
```

---

## Exit Code Reference

| Exit Code | Meaning | Common Fix |
|-----------|---------|------------|
| `0` | Process completed successfully | Add blocking foreground process |
| `1` | General error / app crash | Check logs for error details |
| `2` | Misuse of shell command | Fix script syntax |
| `126` | Permission denied | `chmod +x` the script |
| `127` | Command not found | Install missing package or fix path |
| `137` | OOM Kill | Increase memory limit |
| `139` | Segfault | Rebuild with correct base image |
| `255` | Exit called with -1 | App-level fatal error |

---

## Interactive Debug Pattern

```bash
# Step 1: Override entrypoint to get a shell
docker run -it --entrypoint /bin/sh <image_name>

# Step 2: Manually run the CMD to see what happens
/app/entrypoint.sh

# Step 3: Check dependencies
which myapp
ls -la /app/
env | grep -i required_var

# Step 4: Fix → rebuild → test
docker build -t myapp:debug .
docker run myapp:debug
```

---

## Wait for Dependencies (wait-for-it pattern)

```dockerfile
# Add wait-for-it to image
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh
CMD ["/wait-for-it.sh", "db:5432", "--", "python", "app.py"]
```

---

## 7-Step Checklist
```bash
docker ps -a                                      # 1. check exit status
docker logs <container>                           # 2. read error output
docker inspect <container> | grep ExitCode        # 3. get exit code
docker inspect <container> | grep OOMKilled       # 4. OOM check
docker run -it --entrypoint /bin/sh <image>       # 5. debug interactively
file entrypoint.sh                                # 6. check line endings
docker run -m 512m <image>                        # 7. try with more memory
```

---

> **Key Principle:** Always override the entrypoint with `/bin/sh` to get a shell inside the image and run commands manually — this instantly reveals what's failing at startup.
