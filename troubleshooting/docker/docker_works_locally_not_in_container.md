# Application Works Locally But Not Inside Container – Troubleshooting

## Quick Diagnosis Flow
```
docker logs → exec into container → compare env → check networking → fix
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Missing environment variables** | App reads env vars that exist locally but not in container | `docker exec <container> env` — compare with local `env` | Pass vars via `-e`, `--env-file`, or `docker-compose environment:` |
| 2 | **Wrong file paths** | Local absolute paths hardcoded in app config don't exist in container | `docker exec <container> ls /expected/path` — path missing | Use relative paths or mount correct paths as volumes |
| 3 | **Database / service not reachable** | App uses `localhost` to connect to DB, but in container `localhost` = container itself | `docker exec <container> curl http://localhost:5432` — connection refused | Use Docker service name: `postgres`, `mysql`, or host IP instead of `localhost` |
| 4 | **Different OS / architecture** | Local is macOS/Windows; container is Linux; binary or dependency incompatible | `docker exec <container> uname -a` vs local `uname -a` | Build for the correct target: `docker build --platform linux/amd64 .` |
| 5 | **Missing files (not copied in image)** | Files exist locally but aren't in the Docker image | `docker exec <container> ls /app` — files missing | Fix `COPY` in Dockerfile; check `.dockerignore` isn't excluding them |
| 6 | **Config file differences** | Local config file has different values than the one baked into image | `docker exec <container> cat /app/config.yaml` | Mount config as volume: `-v ./config.yaml:/app/config.yaml` |
| 7 | **Wrong working directory** | App expects to run from a specific directory, but container starts from `/` | `docker exec <container> pwd` | Set `WORKDIR /app` in Dockerfile |
| 8 | **Port not exposed or mapped** | App listens on a port, but it's not exposed or mapped to the host | `docker ps` — check PORTS column; `docker inspect` for exposed ports | Add `EXPOSE 3000` in Dockerfile and `-p 3000:3000` on `docker run` |
| 9 | **Dependency version mismatch** | Local has a different version of runtime (Node, Python, Java) than the container | `docker exec <container> node --version` vs local `node --version` | Pin exact version in `FROM` statement: `FROM node:18.19.0` |
| 10 | **Read-only filesystem** | Container filesystem is read-only or volume not writable | `docker exec <container> touch /app/test` — permission denied | Mount a writable volume for paths that need write access |
| 11 | **DNS resolution inside container** | Container can't resolve hostnames that local machine resolves via VPN/custom DNS | `docker exec <container> nslookup myservice.internal` fails | Add `--dns` flag or configure DNS in `docker-compose`: `dns: 8.8.8.8` |
| 12 | **Secret / credential not available** | API keys or certs exist locally but not in container | Check app error for `unauthorized` / `invalid credentials` | Use Docker secrets, env vars, or mounted secret files |

---

## Key Diagnostic Commands

```bash
# Exec into running container
docker exec -it <container_id> /bin/bash

# Check environment inside container
docker exec <container_id> env

# Check files inside container
docker exec <container_id> ls -la /app

# Check networking from inside container
docker exec <container_id> curl http://db-service:5432
docker exec <container_id> nslookup db-service

# Check working directory
docker exec <container_id> pwd

# Compare file content
docker exec <container_id> cat /app/config.yaml

# Check which user is running
docker exec <container_id> whoami

# Check OS and arch
docker exec <container_id> uname -a
```

---

## Localhost vs Container Networking

```
# WRONG - works locally but fails in container
DB_HOST=localhost

# CORRECT - use service name (docker-compose) or host gateway
DB_HOST=postgres              # docker-compose service name
DB_HOST=host.docker.internal  # reach host machine from container (Docker Desktop)
DB_HOST=172.17.0.1            # default Docker bridge gateway IP (Linux)
```

---

## 6-Step Checklist
```bash
docker logs <container>                  # 1. read error
docker exec <container> env              # 2. check env vars
docker exec <container> ls /app          # 3. verify files exist
docker exec <container> cat /app/config  # 4. check config values
docker exec <container> curl http://db:5432  # 5. check service connectivity
docker exec <container> node --version   # 6. verify runtime version
```

---

> **Key Principle:** `localhost` inside a container is the container itself — not the host machine. This single fact solves most "works locally, fails in Docker" issues.
