# Readiness Probe Failing Repeatedly – Debug Guide

## Quick Diagnosis Flow
```
kubectl describe pod → read probe failure Events → test endpoint manually → fix probe or app → redeploy
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Wrong probe path** | HTTP probe checks a path that doesn't exist in the app | `kubectl describe pod <pod>` → `HTTP probe failed: 404 Not Found` | Fix `path:` in readiness probe to match actual health endpoint (e.g. `/health`, `/ready`) |
| 2 | **Wrong probe port** | Probe checks a port the app doesn't listen on | `kubectl describe pod <pod>` → `Connection refused`; `kubectl exec <pod> -- ss -tulpn` → port mismatch | Fix `port:` in probe to match actual app listening port |
| 3 | **App not ready yet (too short initialDelaySeconds)** | Probe fires before app finishes startup | `kubectl describe pod <pod>` → failures right after container starts | Increase `initialDelaySeconds` to give app time to boot (e.g. 30–60s) |
| 4 | **App health endpoint returns non-200** | Health endpoint returns 4xx/5xx due to app logic error or dependency check | `kubectl exec <pod> -- curl -v http://localhost:<port>/health` → non-200 response | Fix app health endpoint logic; decouple dependency checks from readiness if needed |
| 5 | **Probe timeout too short** | App responds to health check but too slowly; probe times out | `kubectl describe pod <pod>` → `probe timed out`; endpoint is slow | Increase `timeoutSeconds` in probe; optimize app health endpoint response time |
| 6 | **App listening on 127.0.0.1 only** | Probe comes from kubelet on node IP; app only binds to loopback | `kubectl exec <pod> -- ss -tulpn` → `127.0.0.1:<port>` | Fix app to bind to `0.0.0.0`; kubelet probes come from outside the container loopback |
| 7 | **Database / dependency not ready** | App health endpoint checks DB connection and fails if DB is down | `kubectl exec <pod> -- curl http://localhost/health` → DB connection error in response | Separate liveness (app alive) from readiness (app ready to serve); don't fail readiness on external deps unnecessarily |
| 8 | **Probe too aggressive (low failureThreshold)** | Temporary blip fails probe with `failureThreshold: 1`; pod removed from service prematurely | `kubectl describe pod <pod>` → quick repeated failures | Increase `failureThreshold` (e.g. 3–5) and `periodSeconds` for tolerance |
| 9 | **Resource starvation causing slow response** | Pod CPU throttled; health endpoint responds but too slowly | `kubectl top pod <pod>` → near CPU limit | Increase CPU limit; optimize health endpoint; tune probe timeout |
| 10 | **gRPC / TCP probe misconfigured** | Using wrong probe type for the protocol | `kubectl describe pod <pod>` → unexpected connection failures | Use matching probe type: `httpGet` for HTTP, `tcpSocket` for TCP-only, `grpc` for gRPC apps |
| 11 | **TLS / HTTPS app with HTTP probe** | App serves HTTPS but probe uses HTTP (or vice versa) | `kubectl exec <pod> -- curl http://localhost:<port>/health` → SSL redirect or error | Use `scheme: HTTPS` in probe or fix app to expose plain HTTP health endpoint |
| 12 | **Probe port not in container ports spec** | Some network policies use `containerPorts` to allow probe traffic | Probes fail only when NetworkPolicy is in play | Add the probe port to container's `ports:` list in pod spec |

---

## Key Diagnostic Commands

```bash
# Check probe failures in Events
kubectl describe pod <pod-name> -n <namespace>

# Manually test HTTP probe from inside pod
kubectl exec <pod> -- curl -v http://localhost:<port>/health

# Manually test TCP probe
kubectl exec <pod> -- nc -zv localhost <port>

# Check what port the app is listening on
kubectl exec <pod> -- ss -tulpn
kubectl exec <pod> -- netstat -tulpn

# Check app logs for health endpoint errors
kubectl logs <pod> -n <namespace>

# Check resource usage (CPU throttling)
kubectl top pod <pod> -n <namespace>

# View current probe config
kubectl get pod <pod> -o yaml | grep -A20 readinessProbe

# Test probe from node (simulate kubelet)
ssh <node>
curl http://<pod-ip>:<port>/health
```

---

## Probe Configuration Reference

```yaml
readinessProbe:
  httpGet:
    path: /health         # must return 200-399
    port: 8080
    scheme: HTTP          # or HTTPS
  initialDelaySeconds: 30 # wait before first probe
  periodSeconds: 10       # probe every 10s
  timeoutSeconds: 5       # max wait for response
  failureThreshold: 3     # fail after 3 consecutive failures
  successThreshold: 1     # succeed after 1 success (readiness)
```

---

## Probe Types Comparison

| Type | Config | Use When |
|------|--------|----------|
| `httpGet` | `path` + `port` | App exposes HTTP health endpoint |
| `tcpSocket` | `port` only | App uses raw TCP (no HTTP) |
| `exec` | `command` array | Custom script/binary health check |
| `grpc` | `port` + `service` | gRPC app with health protocol |

---

## Readiness vs Liveness vs Startup

| Probe | Failure Effect | Use For |
|-------|---------------|---------|
| `readinessProbe` | Removes pod from Service Endpoints (no traffic) | App ready to accept requests |
| `livenessProbe` | Restarts the container | App is alive and not deadlocked |
| `startupProbe` | Restarts if startup takes too long | Slow-starting apps; replaces initialDelaySeconds |

---

## 7-Step Checklist
```bash
kubectl describe pod <pod> -n <ns>               # 1. read probe failure Events
kubectl exec <pod> -- curl -v http://localhost:<port>/health  # 2. test manually
kubectl exec <pod> -- ss -tulpn                  # 3. app listening on 0.0.0.0?
kubectl get pod <pod> -o yaml | grep -A20 readinessProbe     # 4. review probe config
kubectl logs <pod> -n <ns>                       # 5. app-level errors?
kubectl top pod <pod> -n <ns>                    # 6. CPU throttled?
kubectl get endpoints <svc> -n <ns>              # 7. pod removed from endpoints?
```

---

> **Key Principle:** Always manually `curl` the health endpoint from inside the pod first — if it works there but probe fails, the issue is probe config (port/path/scheme). If it also fails inside, the issue is the app.
