# Pod Stuck in Pending State – Troubleshooting Guide

## Quick Diagnosis Flow
```
kubectl describe pod → check Events section → identify scheduler reason → fix → verify
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Insufficient CPU on nodes** | No node has enough allocatable CPU to schedule the pod | `kubectl describe pod <pod>` → Events: `Insufficient cpu` | Add more nodes, reduce pod CPU request, or free up existing node resources |
| 2 | **Insufficient Memory on nodes** | No node has enough allocatable memory | `kubectl describe pod <pod>` → Events: `Insufficient memory` | Increase node count, reduce memory request, or evict unused pods |
| 3 | **No nodes match node selector** | Pod has `nodeSelector` that no node satisfies | `kubectl describe pod <pod>` → `didn't match node selector` | Fix label: `kubectl label node <node> key=value` or remove/fix `nodeSelector` in spec |
| 4 | **Taint / Toleration mismatch** | Nodes have taints; pod has no matching tolerations | `kubectl describe pod <pod>` → `had taints that the pod didn't tolerate` | Add toleration to pod spec or remove taint: `kubectl taint node <node> key:NoSchedule-` |
| 5 | **PVC not bound** | Pod mounts a PVC that is still in `Pending` state | `kubectl get pvc` → STATUS = Pending | Fix PVC (see PVC troubleshooting guide); ensure StorageClass exists |
| 6 | **No available nodes at all** | All nodes are `NotReady`, cordoned, or at capacity | `kubectl get nodes` → all NotReady or SchedulingDisabled | Uncordon: `kubectl uncordon <node>` or add new nodes |
| 7 | **Pod affinity / anti-affinity conflict** | Affinity rules can't be satisfied by any node | `kubectl describe pod <pod>` → `didn't match pod affinity rules` | Relax affinity rules or ensure required pods exist on the right nodes |
| 8 | **Resource quota exceeded** | Namespace quota limits total CPU/memory across all pods | `kubectl describe resourcequota -n <namespace>` | Increase quota or delete unused pods to free quota |
| 9 | **LimitRange conflict** | Pod's resource request/limit outside namespace LimitRange | `kubectl describe limitrange -n <namespace>` | Set resources within allowed LimitRange bounds |
| 10 | **Scheduler not running** | kube-scheduler is down or crashed | `kubectl get pods -n kube-system \| grep scheduler` | Restart scheduler pod or fix scheduler config |

---

## Key Diagnostic Commands

```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace>

# Most important — read Events section
kubectl describe pod <pod-name> -n <namespace>

# Check node capacity and allocatable
kubectl describe nodes | grep -A5 "Allocated resources"

# Check node status
kubectl get nodes

# Check PVC status
kubectl get pvc -n <namespace>

# Check resource quotas
kubectl describe resourcequota -n <namespace>

# Check node taints
kubectl describe node <node-name> | grep Taints

# Check node labels
kubectl get nodes --show-labels
```

---

## Pod Pending Decision Tree

```
Pod Pending
│
├─ describe pod → "Insufficient cpu/memory"
│   └─ Fix: scale nodes or reduce resource requests
│
├─ describe pod → "didn't match node selector"
│   └─ Fix: label nodes correctly
│
├─ describe pod → "had taints that pod didn't tolerate"
│   └─ Fix: add tolerations or remove taints
│
├─ PVC in Pending state
│   └─ Fix: fix storage class / provisioner
│
└─ No events shown
    └─ Check: is kube-scheduler running?
```

---

## 6-Step Checklist
```bash
kubectl get pod <pod> -n <ns>                    # 1. confirm Pending state
kubectl describe pod <pod> -n <ns>               # 2. read Events section
kubectl get nodes                                # 3. are nodes Ready?
kubectl describe nodes | grep -A5 Allocated      # 4. check CPU/memory
kubectl get pvc -n <ns>                          # 5. check PVC bound?
kubectl describe resourcequota -n <ns>           # 6. check quota limits
```

---

> **Key Principle:** The `Events` section in `kubectl describe pod` directly states why the scheduler couldn't place the pod. Always start there.
