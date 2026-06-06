# Pod in CrashLoopBackOff State – Troubleshooting Guide

## Quick Diagnosis Flow
```
kubectl logs (current + previous) → describe pod → check exit code → fix app/config → redeploy
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Application crashes on startup** | Unhandled exception, missing module, or startup error in the app | `kubectl logs <pod>` → stack trace or error message | Fix the application code or dependency; rebuild and redeploy image |
| 2 | **Missing environment variable** | App reads required ENV var not set in pod spec | `kubectl logs <pod>` → `KeyError`, `env var not set` | Add `env:` or `envFrom:` with correct ConfigMap/Secret reference in deployment spec |
| 3 | **Wrong or missing ConfigMap / Secret** | Referenced ConfigMap or Secret doesn't exist in namespace | `kubectl describe pod <pod>` → `configmap not found` / `secret not found` | Create missing resource: `kubectl create configmap ...` or `kubectl create secret ...` |
| 4 | **Liveness probe killing the pod** | Liveness probe fails repeatedly; Kubernetes kills and restarts the pod | `kubectl describe pod <pod>` → `Liveness probe failed` in Events | Fix the probe endpoint, increase `initialDelaySeconds`, or fix app startup time |
| 5 | **OOM (Out of Memory)** | Container exceeds memory limit; kernel OOM kills it | `kubectl describe pod <pod>` → `OOMKilled`; Exit code `137` | Increase `resources.limits.memory` or fix memory leak in app |
| 6 | **Wrong CMD / ENTRYPOINT** | Container command exits immediately or is invalid | `kubectl logs <pod>` → `exec not found` / no output | Fix `command:` and `args:` in container spec; test image locally |
| 7 | **Permission denied on mounted files** | Container user has no read/write access to mounted volume or file | `kubectl logs <pod>` → `Permission denied` | Set `securityContext.runAsUser` or use `fsGroup` in pod spec |
| 8 | **Database / dependency not reachable** | App tries to connect to a service that's not yet ready and panics | `kubectl logs <pod>` → `connection refused`, `timeout` | Add init container with wait logic, or implement retry/backoff in app |
| 9 | **Image has wrong entrypoint** | Docker image ENTRYPOINT doesn't match expected runtime behavior | `kubectl logs <pod>` → immediate exit with code 0 or 1 | Fix Dockerfile ENTRYPOINT or override with `command:` in pod spec |
| 10 | **Volume mount path conflict** | Mount path overwrites a critical directory inside the container (e.g. `/etc`) | `kubectl logs <pod>` → missing binaries or config files | Fix `mountPath` to a non-critical path; use subPath if needed |
| 11 | **Resource limit too low (CPU throttling)** | App starves for CPU; health probes time out; pod gets killed | `kubectl top pod <pod>` → CPU at limit; OOMKilled | Increase `resources.limits.cpu` and `memory` |
| 12 | **Init container failing** | Init container exits with error; main container never starts | `kubectl describe pod <pod>` → init container status; `kubectl logs <pod> -c <init-container-name>` | Fix init container logic or its dependencies |

---

## Key Diagnostic Commands

```bash
# Check pod status and restart count
kubectl get pod <pod-name> -n <namespace>

# Current logs
kubectl logs <pod-name> -n <namespace>

# Previous container logs (before last crash) — MOST USEFUL
kubectl logs <pod-name> -n <namespace> --previous

# Events and probe results
kubectl describe pod <pod-name> -n <namespace>

# Check exit code
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

# Check OOM
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Resource usage
kubectl top pod <pod-name> -n <namespace>

# Exec into container if it stays up briefly
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Check init containers
kubectl logs <pod-name> -c <init-container-name> -n <namespace>
```

---

## Exit Code Reference

| Exit Code | Meaning | Typical Fix |
|-----------|---------|-------------|
| `0` | Exited cleanly (no blocking process) | Add foreground process in CMD |
| `1` | App error / crash | Check logs for exception |
| `137` | OOM Kill (SIGKILL) | Increase memory limit |
| `139` | Segfault | Rebuild image with correct base |
| `143` | SIGTERM (graceful kill) | Fix liveness probe or startup delay |

---

## Liveness Probe Fix Example

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30   # give app time to start
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5
```

---

## 7-Step Checklist
```bash
kubectl get pod <pod> -n <ns>                         # 1. check restart count
kubectl logs <pod> -n <ns> --previous                 # 2. read crash logs
kubectl describe pod <pod> -n <ns>                    # 3. check Events + probes
kubectl get pod <pod> -o jsonpath='{...exitCode}'     # 4. get exit code
kubectl top pod <pod> -n <ns>                         # 5. check resource usage
kubectl get configmap,secret -n <ns>                  # 6. verify config/secrets exist
kubectl logs <pod> -c <init-container> -n <ns>        # 7. check init containers
```

---

> **Key Principle:** Always use `--previous` flag with `kubectl logs` — it shows logs from the crashed container, not the newly started (and possibly empty) one.
