# PVC Stuck in Pending State – Investigation Guide

## Quick Diagnosis Flow
```
kubectl describe pvc → check Events → check StorageClass → check provisioner → fix → verify bound
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **No StorageClass defined** | PVC requests a StorageClass that doesn't exist in the cluster | `kubectl describe pvc <pvc>` → `storageclass.storage.k8s.io not found` | Create StorageClass: `kubectl get sc` to list existing; fix `storageClassName` in PVC |
| 2 | **No default StorageClass set** | PVC has no `storageClassName` and cluster has no default | `kubectl get sc` → no StorageClass marked `(default)` | Set default: `kubectl patch sc <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'` |
| 3 | **Dynamic provisioner not running** | StorageClass exists but the provisioner pod is down | `kubectl get pods -n kube-system` → provisioner pod not Running | Restart provisioner pod; reinstall the CSI driver or storage plugin |
| 4 | **No matching PersistentVolume (static provisioning)** | PVC uses static binding but no PV matches access mode + capacity | `kubectl get pv` → no PV with matching spec; `kubectl describe pvc` → `no persistent volumes available` | Create a PV that matches PVC's `accessModes`, `capacity`, and `storageClassName` |
| 5 | **AccessMode mismatch** | PVC requests `ReadWriteMany` but available PV/StorageClass only supports `ReadWriteOnce` | `kubectl describe pvc <pvc>` → `did not find a matching volume` | Change PVC `accessModes` or use a storage backend that supports desired mode (e.g. NFS for RWX) |
| 6 | **Capacity too large** | PVC requests more storage than any available PV or provisioner can provide | `kubectl describe pvc <pvc>` → `no persistent volumes available for this claim` | Reduce PVC `storage` request or provision larger storage in cloud/on-prem |
| 7 | **Cloud provisioner lacks permissions (IAM)** | AWS EBS / GCP PD provisioner can't create disk due to missing IAM role | Provisioner pod logs → `AccessDenied` / `403 Forbidden` | Attach correct IAM policy to node/service account for volume creation |
| 8 | **StorageClass volumeBindingMode: WaitForFirstConsumer** | PVC stays Pending intentionally until a pod using it is scheduled | `kubectl describe sc <name>` → `VolumeBindingMode: WaitForFirstConsumer` | This is expected behavior — PVC will bind when a pod is created and scheduled |
| 9 | **Wrong namespace — PV already bound** | PVC in a different namespace tries to bind an already-bound PV | `kubectl get pv` → PV shows `Bound` to a different PVC | Create a new PV for this PVC or release/delete the old binding |
| 10 | **CSI driver not installed** | StorageClass references a CSI driver not installed in the cluster | `kubectl describe pvc <pvc>` → `waiting for a volume to be created` with no progress | Install the correct CSI driver (e.g. AWS EBS CSI, Longhorn, Rook-Ceph) |
| 11 | **Topology constraint not satisfiable** | PVC can only be provisioned in specific zones; no node in that zone | Provisioner logs → `topology ... not satisfied` | Ensure nodes exist in required zones or relax topology constraints in StorageClass |
| 12 | **Reclaim policy left PV in Released state** | Old PV has `Released` status; not available for rebinding | `kubectl get pv` → STATUS: `Released` | Manually delete and recreate PV or change `persistentVolumeReclaimPolicy` to `Delete` |

---

## Key Diagnostic Commands

```bash
# Check PVC status
kubectl get pvc -n <namespace>

# Detailed PVC info — check Events
kubectl describe pvc <pvc-name> -n <namespace>

# List all StorageClasses
kubectl get storageclass
kubectl describe sc <storageclass-name>

# List all PersistentVolumes
kubectl get pv

# Describe a specific PV
kubectl describe pv <pv-name>

# Check provisioner pod logs (example: AWS EBS CSI)
kubectl logs -n kube-system -l app=ebs-csi-controller

# Check if default StorageClass is set
kubectl get sc | grep default

# Force PVC to bind to specific PV (static binding)
# Add claimRef in PV spec:
kubectl edit pv <pv-name>
# Add under spec:
#   claimRef:
#     name: <pvc-name>
#     namespace: <namespace>
```

---

## PVC Binding Flow

```
PVC Created
│
├─ storageClassName specified?
│   ├─ YES → Does StorageClass exist?
│   │   ├─ YES → Is provisioner running?
│   │   │   ├─ YES → Volume created → PVC Bound ✓
│   │   │   └─ NO  → Fix provisioner pod
│   │   └─ NO  → Create StorageClass
│   └─ NO  → Is there a default StorageClass?
│       ├─ YES → Uses default provisioner
│       └─ NO  → PVC stays Pending
│
└─ Static binding → Is there a matching PV?
    ├─ YES (capacity + accessMode match) → Bound ✓
    └─ NO  → Create matching PV
```

---

## Access Modes Reference

| Mode | Short | Description | Supported By |
|------|-------|-------------|-------------|
| `ReadWriteOnce` | RWO | One node read+write | Most block storage (EBS, GCE PD) |
| `ReadOnlyMany` | ROX | Many nodes read-only | NFS, CephFS |
| `ReadWriteMany` | RWX | Many nodes read+write | NFS, CephFS, Azure File |
| `ReadWriteOncePod` | RWOP | One pod only | CSI drivers (K8s 1.22+) |

---

## 7-Step Checklist
```bash
kubectl get pvc -n <ns>                          # 1. confirm Pending
kubectl describe pvc <pvc> -n <ns>               # 2. read Events
kubectl get storageclass                         # 3. StorageClass exists?
kubectl get sc | grep default                    # 4. default StorageClass set?
kubectl get pv                                   # 5. any matching PV?
kubectl logs -n kube-system <provisioner-pod>    # 6. provisioner errors?
kubectl describe sc <name>                       # 7. check volumeBindingMode
```

---

> **Key Principle:** `kubectl describe pvc` Events section tells you exactly what's missing — missing StorageClass, no matching PV, or provisioner errors. Always start there.
