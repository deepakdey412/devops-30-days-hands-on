# Service Unable to Route Traffic to Pods – Debug Guide

## Quick Diagnosis Flow
```
kubectl get endpoints → check selector → check targetPort → check pod readiness → test DNS → fix
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Empty Endpoints (no pod selected)** | Service selector doesn't match any running pod labels | `kubectl get endpoints <svc>` → `<none>`; compare selector vs pod labels | Fix selector in Service or labels on pods to match exactly |
| 2 | **Pod not Ready** | Pods exist but fail readiness probe; excluded from Endpoints | `kubectl get pods` → READY shows `0/1`; `kubectl describe pod` → readiness probe failed | Fix readiness probe or fix app to properly respond to health endpoint |
| 3 | **Wrong targetPort** | Service forwards to a port different from what app listens on | `kubectl describe svc <svc>` → TargetPort vs `kubectl exec <pod> -- ss -tulpn` | Align `targetPort` in Service with app's actual listening port |
| 4 | **Service in wrong namespace** | Accessing service by short name from different namespace | `kubectl get svc -A \| grep <svc>` → service in different namespace | Use full DNS: `<svc>.<namespace>.svc.cluster.local` |
| 5 | **kube-proxy not running or misconfigured** | iptables/IPVS rules not applied; Service IP unreachable | `kubectl get pods -n kube-system \| grep kube-proxy` → not Running | Restart kube-proxy; check its logs: `kubectl logs -n kube-system <kube-proxy-pod>` |
| 6 | **CoreDNS not resolving** | Pod can't resolve service name via DNS | `kubectl exec <pod> -- nslookup kubernetes` fails | Check CoreDNS pods: `kubectl get pods -n kube-system \| grep coredns`; restart if crashing |
| 7 | **NetworkPolicy blocking ingress to pods** | NetworkPolicy prevents traffic from reaching selected pods | `kubectl get networkpolicy -n <ns>` → overly strict ingress rules | Update NetworkPolicy to allow traffic on the correct port from the right source |
| 8 | **Headless Service misused** | Using headless service (`clusterIP: None`) expecting load balancing | `kubectl get svc <svc>` → `CLUSTER-IP: None` | Change to regular ClusterIP service, or use correct DNS-based discovery for headless |
| 9 | **Port protocol mismatch (TCP vs UDP)** | Service specifies UDP but app uses TCP or vice versa | `kubectl describe svc <svc>` → Protocol field | Fix `protocol: TCP` or `protocol: UDP` in service port spec |
| 10 | **ExternalName service misconfigured** | Service of type ExternalName points to wrong CNAME | `kubectl describe svc <svc>` → externalName value | Fix `externalName` to correct external DNS name |
| 11 | **Session affinity causing unbalanced routing** | `sessionAffinity: ClientIP` pins clients to one pod, skipping others | `kubectl describe svc <svc>` → SessionAffinity: ClientIP | Change to `sessionAffinity: None` if even load balancing is needed |
| 12 | **Pods on host network bypassing service** | Pods using `hostNetwork: true` don't respond on ClusterIP | `kubectl describe pod <pod>` → `hostNetwork: true` | Remove `hostNetwork: true` or adjust service to use NodePort targeting the host |

---

## Key Diagnostic Commands

```bash
# Check endpoints — MOST IMPORTANT FIRST STEP
kubectl get endpoints <svc-name> -n <namespace>

# Full service description
kubectl describe svc <svc-name> -n <namespace>

# Check pod labels vs service selector
kubectl get pods -n <namespace> --show-labels
kubectl describe svc <svc-name> | grep Selector

# Find pods matching a selector
kubectl get pods -l app=myapp -n <namespace>

# Test DNS resolution from inside a pod
kubectl exec -it <pod> -- nslookup <service-name>
kubectl exec -it <pod> -- nslookup <svc>.<ns>.svc.cluster.local

# Test service IP directly
kubectl exec -it <pod> -- curl http://<clusterIP>:<port>

# Check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system <kube-proxy-pod>

# Check network policies
kubectl get networkpolicy -n <namespace>

# Run one-off debug pod for testing
kubectl run debug --image=nicolaka/netshoot --rm -it --restart=Never -- bash
```

---

## Service Types Quick Reference

| Type | Accessible From | Use Case |
|------|----------------|----------|
| `ClusterIP` | Inside cluster only | Default; internal services |
| `NodePort` | Node IP + port externally | Dev/testing; limited production use |
| `LoadBalancer` | External IP via cloud LB | Production external access |
| `ExternalName` | DNS alias to external service | Proxy to external endpoints |

---

## Endpoint Debug Pattern

```bash
# Step 1: Check if endpoints exist
kubectl get endpoints myapp-svc
# No addresses? → selector mismatch or pods not ready

# Step 2: Get service selector
kubectl get svc myapp-svc -o jsonpath='{.spec.selector}'
# e.g.: {"app":"myapp"}

# Step 3: Find pods with that label
kubectl get pods -l app=myapp --show-labels
# No pods? → wrong label key/value

# Step 4: Check pod readiness
kubectl get pods -l app=myapp
# READY: 0/1? → readiness probe failing
```

---

## 7-Step Checklist
```bash
kubectl get endpoints <svc> -n <ns>              # 1. endpoints populated?
kubectl describe svc <svc> -n <ns>               # 2. selector + targetPort correct?
kubectl get pods -l <selector> -n <ns>           # 3. pods match selector?
kubectl get pods -n <ns>                         # 4. pods are Ready?
kubectl exec <pod> -- nslookup <svc>             # 5. DNS resolves?
kubectl get networkpolicy -n <ns>                # 6. policies blocking?
kubectl get pods -n kube-system | grep proxy     # 7. kube-proxy running?
```

---

> **Key Principle:** Empty Endpoints is the #1 cause. If `kubectl get endpoints <svc>` shows no addresses, the service can never route traffic regardless of anything else.
