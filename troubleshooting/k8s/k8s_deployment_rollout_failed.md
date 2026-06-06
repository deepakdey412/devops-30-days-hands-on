# Deployment Rollout Failed – Commands & Troubleshooting Guide

## Quick Diagnosis Flow
```
kubectl rollout status → kubectl describe deployment → kubectl describe pod (new) → fix → rollout or rollback
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **New pods in CrashLoopBackOff** | New image or config causes pods to crash on startup | `kubectl get pods` → new pods crashing; `kubectl logs <new-pod> --previous` | Fix image/config; rollback: `kubectl rollout undo deployment/<name>` |
| 2 | **New image pull fails (ImagePullBackOff)** | Wrong image tag, registry unreachable, or missing imagePullSecret | `kubectl describe pod <new-pod>` → `Failed to pull image` | Fix image tag or add `imagePullSecrets` to deployment spec |
| 3 | **Readiness probe failing on new pods** | New version doesn't expose the health endpoint or it's slow to start | `kubectl describe pod <new-pod>` → `Readiness probe failed` | Increase `initialDelaySeconds`, fix probe path, or fix app health endpoint |
| 4 | **Insufficient cluster resources** | New pods can't be scheduled; old pods can't be terminated yet | `kubectl describe pod <new-pod>` → `Insufficient cpu/memory` | Free up cluster resources or adjust `maxSurge`/`maxUnavailable` in strategy |
| 5 | **Wrong environment variable / secret** | New deployment references missing or changed ConfigMap/Secret | `kubectl describe pod <new-pod>` → `secret not found` | Create/update ConfigMap or Secret before rolling out |
| 6 | **Rollout stuck (deadline exceeded)** | `progressDeadlineSeconds` exceeded; rollout never completes | `kubectl rollout status deployment/<name>` → `timed out` | Fix root cause; or increase `progressDeadlineSeconds`; then rollback |
| 7 | **Wrong resource limits blocking scheduling** | New spec has resource requests/limits no node can satisfy | `kubectl describe pod <new-pod>` → `Insufficient memory` | Fix resource requests in deployment spec to realistic values |
| 8 | **Volume or PVC not available** | New pod spec references a non-existent or unbound PVC | `kubectl describe pod <new-pod>` → `persistentvolumeclaim not found` | Create/fix PVC before deploying; or update pod spec to correct PVC name |
| 9 | **Deployment strategy misconfigured** | `maxUnavailable: 0` and `maxSurge: 0` locks rollout | `kubectl describe deployment <name>` → strategy section | Fix: set `maxSurge: 1` or `maxUnavailable: 1` in `strategy.rollingUpdate` |
| 10 | **Namespace quota blocks new pods** | ResourceQuota prevents new pod creation during rollout | `kubectl describe resourcequota -n <ns>` → quota exceeded | Increase quota or delete unused resources in namespace |

---

## Key Diagnostic Commands

```bash
# Check rollout status (live progress)
kubectl rollout status deployment/<deployment-name> -n <namespace>

# View rollout history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Describe deployment (check strategy, events)
kubectl describe deployment <deployment-name> -n <namespace>

# Watch pods during rollout
kubectl get pods -n <namespace> -w

# Check new (failing) pod logs
kubectl logs <new-pod-name> -n <namespace> --previous

# Describe new pod for Events
kubectl describe pod <new-pod-name> -n <namespace>

# ROLLBACK to previous version
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2 -n <namespace>

# Pause rollout (stop mid-way)
kubectl rollout pause deployment/<deployment-name> -n <namespace>

# Resume rollout
kubectl rollout resume deployment/<deployment-name> -n <namespace>

# Force restart all pods (new rollout with same config)
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

---

## Rollout Strategy Reference

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # max extra pods above desired count during rollout
      maxUnavailable: 0    # min available pods during rollout (0 = no downtime)
```

| Field | Meaning | Recommendation |
|-------|---------|----------------|
| `maxSurge` | Extra pods created above desired | Set to 1-25% for safe rollout |
| `maxUnavailable` | Pods that can be down during rollout | Set to 0 for zero-downtime |
| `progressDeadlineSeconds` | Time before rollout is marked failed | Default 600s; increase for slow starts |

---

## Rollback Decision Flow

```
kubectl rollout status → "timed out" or pods failing
│
├─ Immediate fix needed → kubectl rollout undo deployment/<name>
│
├─ Rollback to specific version → kubectl rollout undo --to-revision=<n>
│
└─ Investigate first → kubectl rollout pause → debug → fix → kubectl rollout resume
```

---

## 7-Step Checklist
```bash
kubectl rollout status deployment/<name> -n <ns>     # 1. rollout progress
kubectl get pods -n <ns>                             # 2. new pods status
kubectl describe pod <new-pod> -n <ns>               # 3. events on new pod
kubectl logs <new-pod> --previous -n <ns>            # 4. crash logs
kubectl describe deployment <name> -n <ns>           # 5. strategy + events
kubectl rollout history deployment/<name> -n <ns>    # 6. revision history
kubectl rollout undo deployment/<name> -n <ns>       # 7. rollback if needed
```

---

> **Key Principle:** Always `kubectl rollout undo` first to restore service, then investigate the failed revision. Don't debug in production with users impacted.
