# Pod Running But Application Not Accessible – Investigation Guide

## Quick Diagnosis Flow
```
kubectl get svc → kubectl describe svc → check endpoints → check pod port → test connectivity
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Service selector doesn't match Pod labels** | Service routes to no pods because labels don't align | `kubectl describe svc <svc>` → Endpoints: `<none>` | Fix selector in Service or labels in pod spec to match exactly |
| 2 | **Wrong target port in Service** | Service sends traffic to a port the container doesn't listen on | `kubectl describe svc <svc>` → check `TargetPort` vs `kubectl describe pod` → `containerPort` | Set correct `targetPort` in Service matching app's listen port |
| 3 | **App listening on wrong interface** | App binds to `127.0.0.1` not `0.0.0.0` inside container | `kubectl exec <pod> -- ss -tulpn` → shows `127.0.0.1:PORT` | Change app config to listen on `0.0.0.0`; e.g. Flask: `app.run(host='0.0.0.0')` |
| 4 | **Readiness probe failing** | Pod marked not-ready; Service removes it from Endpoints | `kubectl describe pod <pod>` → `Readiness probe failed` | Fix readiness probe path/port or fix app to respond to probe correctly |
| 5 | **No Endpoints created for Service** | No pods match the service selector in that namespace | `kubectl get endpoints <svc> -n <ns>` → empty addresses | Ensure pods are Running and labels match service selector |
| 6 | **NetworkPolicy blocking traffic** | NetworkPolicy restricts ingress/egress to the pod | `kubectl get networkpolicy -n <ns>` → overly restrictive rules | Update NetworkPolicy to allow required traffic on the correct port |
| 7 | **NodePort / LoadBalancer not reachable externally** | Accessing via external IP but traffic not reaching node or LB not provisioned | `kubectl get svc` → `EXTERNAL-IP` shows `<pending>` | Check cloud LB provisioning; use NodePort or port-forward for testing |
| 8 | **Ingress misconfigured** | Ingress rules don't match the host/path or point to wrong service | `kubectl describe ingress <name>` → check rules and backend | Fix `host`, `path`, and `serviceName`/`servicePort` in Ingress spec |
| 9 | **App crashed / not responding inside pod** | App is up but hangs or errors on requests | `kubectl exec <pod> -- curl localhost:<port>` → timeout or error | Check app logs: `kubectl logs <pod>`; fix app-level error |
| 10 | **Namespace DNS not resolving** | Service accessed by wrong DNS name format | `kubectl exec <pod> -- nslookup <svc>` fails | Use FQDN: `<service>.<namespace>.svc.cluster.local` |
| 11 | **kube-proxy not running** | kube-proxy on the node is down; iptables rules not applied | `kubectl get pods -n kube-system \| grep kube-proxy` | Restart kube-proxy pod or fix its configuration |
| 12 | **Ingress controller not installed** | Ingress resource created but no controller to handle it | `kubectl get pods -n ingress-nginx` → no pods | Install ingress controller: `helm install ingress-nginx ingress-nginx/ingress-nginx` |

---

## Key Diagnostic Commands

```bash
# Check service and its endpoints
kubectl get svc <svc-name> -n <namespace>
kubectl describe svc <svc-name> -n <namespace>
kubectl get endpoints <svc-name> -n <namespace>

# Check pod labels match service selector
kubectl get pod <pod> --show-labels
kubectl describe svc <svc> | grep Selector

# Test connectivity from within cluster
kubectl exec -it <pod> -n <namespace> -- curl http://<svc-name>:<port>

# Test from a debug pod
kubectl run debug --image=busybox --rm -it --restart=Never -- wget -qO- http://<svc>:<port>

# Check app listening interface inside pod
kubectl exec <pod> -- ss -tulpn

# DNS resolution test
kubectl exec <pod> -- nslookup <service-name>
kubectl exec <pod> -- nslookup <service>.<namespace>.svc.cluster.local

# Port-forward for direct testing (bypasses service/ingress)
kubectl port-forward pod/<pod-name> 8080:8080

# Check network policies
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>

# Check ingress
kubectl describe ingress <ingress-name> -n <namespace>
```

---

## Service → Pod Traffic Flow

```
External Request
      ↓
  Ingress Controller
      ↓
  Service (ClusterIP / NodePort / LoadBalancer)
      ↓
  Endpoints (only Ready pods matching selector)
      ↓
  Pod (must listen on 0.0.0.0:containerPort)
      ↓
  Application
```

---

## Quick Label Match Check

```bash
# Get service selector
kubectl get svc myapp -o jsonpath='{.spec.selector}'
# Output: {"app":"myapp","env":"prod"}

# Verify pod has exactly these labels
kubectl get pods --selector=app=myapp,env=prod
# If empty → label mismatch is the problem
```

---

## 7-Step Checklist
```bash
kubectl get endpoints <svc> -n <ns>              # 1. endpoints populated?
kubectl describe svc <svc> -n <ns>               # 2. check selector + targetPort
kubectl get pod <pod> --show-labels              # 3. pod labels match selector?
kubectl describe pod <pod> -n <ns>               # 4. readiness probe passing?
kubectl exec <pod> -- ss -tulpn                  # 5. app on 0.0.0.0?
kubectl port-forward pod/<pod> 8080:8080         # 6. works via port-forward?
kubectl get networkpolicy -n <ns>                # 7. network policies blocking?
```

---

> **Key Principle:** If `kubectl port-forward` works but the Service doesn't — the issue is in the Service config or NetworkPolicy, not the app.
