# Node Status is NotReady – Troubleshooting Guide

## Quick Diagnosis Flow
```
kubectl describe node → check Conditions → SSH into node → check kubelet/runtime → fix → rejoin
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **kubelet service not running** | kubelet crashed or was stopped on the node | SSH to node: `systemctl status kubelet` → inactive/failed | Restart: `sudo systemctl restart kubelet`; check: `journalctl -u kubelet -f` |
| 2 | **Node out of disk space** | Disk pressure causes kubelet to mark node NotReady | `kubectl describe node <node>` → Conditions: `DiskPressure: True` | Free space: remove unused images `crictl rmi --prune`; clean logs; expand disk |
| 3 | **Node out of memory** | Memory pressure — system OOM; kubelet or processes killed | `kubectl describe node <node>` → `MemoryPressure: True` | Evict pods: `kubectl drain <node>`; add RAM or swap; check for memory leaks |
| 4 | **Too many pods on node (PID pressure)** | PID limit reached; no new processes can start | `kubectl describe node <node>` → `PIDPressure: True` | Reduce pods on node; increase PID limits on OS |
| 5 | **Container runtime (containerd/Docker) down** | Container runtime is crashed or unresponsive | SSH to node: `systemctl status containerd` or `systemctl status docker` → failed | Restart runtime: `sudo systemctl restart containerd`; check runtime logs |
| 6 | **Network plugin (CNI) failed** | CNI plugin crashed; node loses pod networking | `kubectl describe node <node>` → NetworkUnavailable: True; check CNI pod logs | Restart CNI pods: `kubectl delete pod -n kube-system -l k8s-app=<cni-name>` |
| 7 | **Node unreachable (network issue)** | Network failure between control plane and node | `kubectl get node` → NotReady; `ping <node-ip>` fails | Fix network routing, firewall rules, or VPN; check cloud security groups |
| 8 | **Certificate expired** | Node certificate expired; kubelet can't authenticate to API server | `journalctl -u kubelet` → `x509: certificate has expired` | Renew certs: `kubeadm certs renew all`; rotate kubelet certificates |
| 9 | **API server unreachable from node** | kubelet can't reach kube-apiserver | SSH to node: `curl -k https://<api-server>:6443/healthz` → connection refused | Check control plane health; fix network between node and control plane |
| 10 | **Node resource exhaustion (CPU)** | CPU completely saturated; OS becomes unresponsive | SSH to node: `top` / `htop` → 100% CPU | Kill runaway processes; drain node: `kubectl drain <node> --ignore-daemonsets` |
| 11 | **Wrong node time (clock skew)** | Time difference between node and control plane causes auth failures | `date` on node vs control plane; `journalctl -u kubelet` → `clock skew` | Sync NTP: `sudo timedatectl set-ntp true`; verify with `chronyc tracking` |
| 12 | **Node manually cordoned** | Node was cordoned (SchedulingDisabled) — not NotReady but no new pods | `kubectl get nodes` → STATUS: `Ready,SchedulingDisabled` | Uncordon: `kubectl uncordon <node-name>` |

---

## Key Diagnostic Commands

```bash
# Check all node statuses
kubectl get nodes -o wide

# Detailed node info — check Conditions section
kubectl describe node <node-name>

# SSH into the node, then check kubelet
sudo systemctl status kubelet
sudo journalctl -u kubelet -f

# Check container runtime
sudo systemctl status containerd
sudo systemctl status docker

# Check disk pressure
df -h
du -sh /var/lib/containerd/*

# Check memory pressure
free -h
sudo dmesg | grep -i oom

# Check CNI pods
kubectl get pods -n kube-system

# Node resource usage
kubectl top nodes

# Drain node safely before maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Cordon/Uncordon
kubectl cordon <node-name>
kubectl uncordon <node-name>
```

---

## Node Conditions Reference

| Condition | Healthy State | Meaning if True |
|-----------|--------------|-----------------|
| `Ready` | `True` | Node is healthy |
| `MemoryPressure` | `False` | Node is low on memory |
| `DiskPressure` | `False` | Node is low on disk |
| `PIDPressure` | `False` | Too many processes |
| `NetworkUnavailable` | `False` | CNI not configured |

---

## Node Recovery Flow

```
Node NotReady
│
├─ SSH accessible?
│   ├─ YES → check kubelet → check runtime → check disk/memory
│   └─ NO  → network issue → fix firewall/VPN/routing
│
├─ kubelet running?
│   ├─ YES → check runtime → check CNI → check API reachability
│   └─ NO  → restart kubelet: systemctl restart kubelet
│
└─ Node recovered → kubectl uncordon <node>
```

---

## 8-Step Checklist
```bash
kubectl get nodes                                 # 1. confirm NotReady
kubectl describe node <node>                      # 2. check Conditions + Events
ssh <node> systemctl status kubelet               # 3. kubelet running?
ssh <node> journalctl -u kubelet -f               # 4. kubelet error logs
ssh <node> systemctl status containerd            # 5. runtime running?
ssh <node> df -h && free -h                       # 6. disk and memory ok?
kubectl get pods -n kube-system                   # 7. CNI pods healthy?
kubectl top nodes                                 # 8. resource usage
```

---

> **Key Principle:** Always SSH into the node and check kubelet logs — the control plane only reports what the node tells it. The real reason is always on the node itself.
