# Kubernetes Cluster Running Slow – Identifying the Issue

## Quick Diagnosis Flow
```
kubectl top nodes/pods → check control plane → check etcd → check network → identify bottleneck → fix
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Node CPU saturation** | Nodes running at 100% CPU; pods throttled and slow | `kubectl top nodes` → CPU% near 100 | Drain and redistribute pods; add nodes; optimize app CPU usage |
| 2 | **Node memory pressure** | Nodes OOM; pods being evicted or throttled | `kubectl top nodes` → Memory near limit; `kubectl get events` → eviction events | Add memory; reduce pod memory usage; set proper limits |
| 3 | **etcd slow or degraded** | etcd I/O latency causes slow API server responses | `kubectl get --raw /metrics \| grep etcd_disk`; etcd pod logs → slow WAL fsync | Use SSD for etcd; defragment: `etcdctl defrag`; compact old revisions |
| 4 | **API server overloaded** | Too many requests (kubectl, controllers, operators) overwhelming kube-apiserver | API server metrics → high `apiserver_request_duration_seconds`; slow `kubectl` responses | Enable API priority & fairness; scale API server replicas; reduce polling intervals in controllers |
| 5 | **Too many pods per node** | Nodes beyond recommended pod density (default 110 pods/node) | `kubectl describe node <node>` → `Non-terminated Pods` count | Increase `--max-pods` or add more nodes to distribute pods |
| 6 | **DNS (CoreDNS) overloaded** | High volume of DNS queries causing resolution delays | `kubectl top pod -n kube-system` → CoreDNS high CPU; app logs → slow DNS | Scale CoreDNS: `kubectl scale deploy coredns -n kube-system --replicas=3`; enable NodeLocal DNSCache |
| 7 | **Network plugin (CNI) performance** | CNI (Calico/Flannel/Cilium) misconfigured or under load | High pod-to-pod latency; check CNI pod logs and node network stats | Tune CNI settings; switch to higher performance CNI (Cilium eBPF); check MTU settings |
| 8 | **Slow storage / PVC I/O** | Apps waiting on slow disk I/O through PVC | `kubectl exec <pod> -- dd if=/dev/zero of=/data/test bs=1M count=100` → measure throughput | Switch to faster StorageClass (SSD); check CSI driver performance |
| 9 | **Too many CRDs / controllers** | Excessive Custom Resources and controllers adding load to API server and etcd | `kubectl get crd | wc -l`; API server logs showing slow list operations | Remove unused CRDs/operators; tune controller resync intervals |
| 10 | **Scheduler throughput low** | Large number of pending pods taking long to schedule | `kubectl get pods --field-selector=status.phase=Pending \| wc -l` → many pending | Increase scheduler throughput: `--kube-api-qps`, `--kube-api-burst`; simplify affinity rules |
| 11 | **Log/metric volume overwhelming node** | Excessive logging filling disk and slowing nodes | `df -h` on nodes → disk filling fast; `kubectl logs <pod>` → very verbose output | Set log limits; reduce log verbosity; offload to external log aggregation |
| 12 | **Horizontal Pod Autoscaler lag** | HPA slow to scale up; app under load during scale delay | `kubectl describe hpa <name>` → scale events and current/desired replicas | Tune `--horizontal-pod-autoscaler-sync-period`; pre-scale during known peak times |

---

## Key Diagnostic Commands

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage (sorted by CPU)
kubectl top pods -A --sort-by=cpu

# Pod resource usage (sorted by memory)
kubectl top pods -A --sort-by=memory

# Check for eviction events
kubectl get events -A | grep -i evict

# Check pending pods
kubectl get pods -A | grep Pending

# Check API server response time
kubectl get --raw /metrics | grep apiserver_request_duration

# Check etcd health (on control plane node)
ETCDCTL_API=3 etcdctl endpoint health
ETCDCTL_API=3 etcdctl endpoint status --write-out=table

# Defragment etcd
ETCDCTL_API=3 etcdctl defrag

# Check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl top pod -n kube-system

# Check HPA status
kubectl get hpa -A
kubectl describe hpa <name> -n <namespace>

# Check node conditions for pressure
kubectl describe nodes | grep -A5 Conditions

# Check resource quota usage
kubectl describe resourcequota -A
```

---

## Cluster Performance Baseline

| Component | Healthy Threshold | Warning Signal |
|-----------|------------------|----------------|
| Node CPU | < 70% | > 85% sustained |
| Node Memory | < 80% | > 90% |
| etcd WAL fsync | < 10ms | > 100ms |
| API server p99 latency | < 1s | > 5s |
| CoreDNS CPU | < 100m per replica | > 300m |
| Pod scheduling time | < 1s | > 10s |

---

## Performance Improvement Actions

```bash
# Scale CoreDNS for DNS performance
kubectl scale deploy coredns -n kube-system --replicas=3

# Enable NodeLocal DNSCache (reduces CoreDNS load)
# Apply NodeLocal DNS DaemonSet manifest from k8s docs

# Defrag etcd (run on control plane)
ETCDCTL_API=3 etcdctl defrag --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Compact etcd revisions
ETCDCTL_API=3 etcdctl compact $(etcdctl endpoint status --write-out="json" | jq '.[0].Status.header.revision')
```

---

## 8-Step Checklist
```bash
kubectl top nodes                                # 1. node CPU/memory
kubectl top pods -A --sort-by=cpu               # 2. top resource consumers
kubectl get pods -A | grep Pending              # 3. scheduling backlog
kubectl get events -A | grep -i evict           # 4. eviction events
kubectl top pod -n kube-system                  # 5. control plane component load
etcdctl endpoint status --write-out=table       # 6. etcd health
kubectl describe nodes | grep -A5 Conditions    # 7. node pressure conditions
kubectl get hpa -A                              # 8. autoscaler status
```

---

> **Key Principle:** Slow clusters almost always trace to one of three roots — node resource exhaustion, etcd I/O degradation, or DNS bottlenecks. Check all three in parallel.
