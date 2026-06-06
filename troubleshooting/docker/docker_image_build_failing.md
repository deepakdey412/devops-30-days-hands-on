# Docker Image Build Failing – What to Check

## Quick Diagnosis Flow
```
Read build error output → identify failing layer → fix Dockerfile / context → rebuild
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Package not found** | Package name wrong, outdated, or repo cache stale | Build output: `Unable to locate package <name>` | Run `apt-get update` before `apt-get install`; verify package name |
| 2 | **No internet access during build** | Corporate proxy, firewall, or DNS blocking outbound connections | Build hangs or shows `Could not resolve host` | Configure Docker proxy: set `HTTP_PROXY` in build args or `~/.docker/config.json` |
| 3 | **Base image not found** | Wrong image name, tag, or private registry not authenticated | Build output: `pull access denied` / `manifest unknown` | Fix `FROM` line; run `docker login <registry>` if private |
| 4 | **COPY / ADD file not found** | File path wrong or file not in build context | Build output: `COPY failed: file not found` | Check `.dockerignore`; verify file exists relative to build context path |
| 5 | **Permission denied during build** | Script not executable or build user lacks permissions | Build output: `Permission denied` on RUN step | Add `RUN chmod +x script.sh` before executing it |
| 6 | **Dockerfile syntax error** | Wrong instruction keyword or invalid argument | Build output: `unknown instruction` / `dockerfile parse error` | Validate Dockerfile syntax; use `hadolint` for linting |
| 7 | **Build context too large / slow** | Entire project directory (including `node_modules`, `.git`) sent to Docker daemon | Build is very slow; `Sending build context` takes long | Create/update `.dockerignore` to exclude unnecessary files |
| 8 | **Multi-stage build artifact missing** | Wrong stage name or path in `COPY --from=` | Build output: `failed to solve: failed to copy` | Verify `COPY --from=<stage_name>` matches the `AS <name>` in the FROM line |
| 9 | **Dependency version conflict** | Pinned versions incompatible with each other | Build fails during `pip install` / `npm install` with version errors | Use a lockfile (`requirements.txt`, `package-lock.json`), or update dependency versions |
| 10 | **Disk space full on Docker host** | Build layers fill up disk | Build output: `no space left on device` | `docker system prune -a` to free space; check `df -h` |
| 11 | **Build arg / env var not passed** | `ARG` used in Dockerfile but not supplied at build time | Build output: empty value or unexpected behavior | Pass with: `docker build --build-arg VAR=value .` |
| 12 | **Layer cache invalidation causing failures** | Stale cache used with wrong assumptions | Build passes locally but fails in CI | Use `docker build --no-cache .` to rebuild fresh |

---

## Key Diagnostic Commands

```bash
# Build with full output (no cache)
docker build --no-cache -t myapp:debug .

# Build with verbose output
docker build --progress=plain -t myapp:debug .

# Check build context size
du -sh .

# Lint Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile

# Inspect what's in .dockerignore
cat .dockerignore

# Test base image manually
docker run -it ubuntu:22.04 /bin/bash

# Check disk space
df -h
docker system df
```

---

## Common Dockerfile Fixes

```dockerfile
# Fix 1: Always update before install
RUN apt-get update && apt-get install -y curl git

# Fix 2: Make script executable before running
COPY start.sh /app/
RUN chmod +x /app/start.sh

# Fix 3: Pass build args correctly
ARG APP_VERSION
RUN echo "Building version $APP_VERSION"
# Then build with: docker build --build-arg APP_VERSION=1.0 .

# Fix 4: Correct multi-stage COPY
FROM node:18 AS builder
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html   # must match AS name
```

---

## .dockerignore Essentials
```
node_modules
.git
*.log
dist
.env
__pycache__
*.pyc
```

---

## 6-Step Checklist
```bash
docker build --progress=plain --no-cache .    # 1. full verbose build output
# 2. read the exact failing line/layer
cat .dockerignore                             # 3. check excluded files
df -h && docker system df                    # 4. check disk space
docker run -it <base-image> /bin/bash        # 5. test base image manually
hadolint Dockerfile                          # 6. lint for syntax issues
```

---

> **Key Principle:** Always use `--progress=plain` during debugging — it shows every layer output in full detail.
