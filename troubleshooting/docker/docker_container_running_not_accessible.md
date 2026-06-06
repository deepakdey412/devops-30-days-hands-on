# Container Running But Application Not Accessible – Reasons & Fixes

## Quick Diagnosis Flow
```
docker ps (check ports) → curl localhost → check app logs → check network → fix
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Port not published to host** | Container runs but port not mapped with `-p` | `docker ps` — PORTS column is empty or wrong | Re-run with: `docker run -p 8080:8080 <image>` |
| 2 | **App listening on wrong interface** | App binds to `127.0.0.1` (loopback) instead of `0.0.0.0` | `docker exec <c> ss -tulpn` — shows `127.0.0.1:8080` not `0.0.0.0:8080` | Configure app to listen on `0.0.0.0`; e.g. Flask: `app.run(host='0.0.0.0')` |
| 3 | **App not started / still starting** | Container is running but the app process inside hasn't started yet | `docker exec <c> ps aux` — app process not listed | Add a healthcheck; wait for startup; check app logs for startup errors |
| 4 | **App crashed silently** | Process started then died; container still shows as running (init holds it) | `docker exec <c> ps aux` — main process missing | Check `docker logs <container>` for the crash reason |
| 5 | **Wrong port in `-p` mapping** | Host port mapped to wrong container port | `docker ps` — e.g. `0.0.0.0:8080->3000/tcp` but app runs on `3000` | Correct the mapping: `docker run -p 8080:3000 <image>` |
| 6 | **Firewall on Docker host blocking port** | Host firewall denies inbound traffic to the published port | `sudo ufw status` / `iptables -L -n \| grep 8080` | `sudo ufw allow 8080/tcp && sudo ufw reload` |
| 7 | **App returns error (500/502)** | App is accessible but crashes on request due to code/config issue | `curl -v http://localhost:8080` — returns HTTP error | Check app logs: `docker logs <container>` — fix the application error |
| 8 | **Reverse proxy misconfiguration** | Nginx/Traefik/Caddy in front of container routes incorrectly | Proxy logs show upstream connection error | Check proxy config; ensure `proxy_pass` targets correct container port |
| 9 | **Container on different Docker network** | Container attached to a custom network, not accessible from default bridge | `docker inspect <container> \| grep NetworkMode` | Connect container to the right network: `docker network connect <network> <container>` |
| 10 | **Accessing wrong IP / host** | Trying to access container IP directly instead of host port | Confirm: `curl http://localhost:<published_port>` vs container IP | Always access via `localhost:<host_port>`, not container IP (it's internal) |
| 11 | **Cloud / VM security group blocking port** | Running on AWS/GCP/Azure with no inbound rule for the port | Test: `curl` from inside VM works but from outside doesn't | Add inbound rule in the cloud security group for the port |
| 12 | **HTTPS vs HTTP mismatch** | App expects HTTPS but accessed via HTTP or vice versa | `curl http://...` returns redirect or SSL error | Access using the correct protocol; configure TLS properly |

---

## Key Diagnostic Commands

```bash
# Check port mappings
docker ps

# Test from host
curl -v http://localhost:8080

# Check what app is listening on inside container
docker exec <container> ss -tulpn
docker exec <container> netstat -tulpn

# Check app process is running
docker exec <container> ps aux

# Check container network
docker inspect <container> | grep -A20 NetworkSettings

# List docker networks
docker network ls
docker network inspect bridge

# Check host firewall
sudo ufw status
sudo iptables -L -n | grep 8080

# Check resource/port on host
sudo ss -tulpn | grep 8080
```

---

## Port Mapping Quick Reference

```bash
# Map host:container
docker run -p 8080:3000 myapp      # host port 8080 → container port 3000

# Bind to specific host IP
docker run -p 127.0.0.1:8080:3000 myapp   # only localhost on host

# Expose all interfaces (default)
docker run -p 0.0.0.0:8080:3000 myapp
```

---

## App Listen Address Fix (Common Languages)

```python
# Flask
app.run(host='0.0.0.0', port=5000)

# FastAPI / Uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000
```

```javascript
// Node.js / Express
app.listen(3000, '0.0.0.0')
```

```yaml
# Spring Boot (application.properties)
server.address=0.0.0.0
```

---

## 6-Step Checklist
```bash
docker ps                              # 1. port mapping correct?
curl -v http://localhost:<port>        # 2. accessible from host?
docker exec <c> ss -tulpn             # 3. app listening on 0.0.0.0?
docker exec <c> ps aux                # 4. app process running?
docker logs <container>               # 5. any errors?
sudo ufw status                       # 6. firewall allowing port?
```

---

> **Key Principle:** A container "running" only means the container process is alive — not that your app inside it is up and reachable. Always verify with `curl` and `ps aux` inside.
