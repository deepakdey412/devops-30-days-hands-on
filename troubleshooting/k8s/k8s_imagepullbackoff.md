# ImagePullBackOff Error – Reasons & Fixes

## Quick Diagnosis Flow
```
kubectl describe pod → check Events → identify pull error → fix image/secret/registry → redeploy
```

---

## Detailed Troubleshooting Table

| # | Problem | Cause | How to Find the Cause | How to Solve It |
|---|---------|-------|-----------------------|-----------------|
| 1 | **Wrong image name or tag** | Typo in image name or tag that doesn't exist in registry | `kubectl describe pod <pod>` → `manifest unknown` / `not found` | Fix `image:` in deployment spec; verify: `docker pull <image>:<tag>` locally |
| 2 | **Image tag doesn't exist** | Using a tag like `latest` that was deleted or a version that was never pushed | `kubectl describe pod <pod>` → `tag does not exist` | Use a valid existing tag; avoid `latest` in production — pin to digest or version |
| 3 | **Private registry — no imagePullSecret** | Image is in a private registry; no credentials provided to Kubernetes | `kubectl describe pod <pod>` → `unauthorized` / `pull access denied` | Create secret and add to pod: `kubectl create secret docker-registry ...` |
| 4 | **imagePullSecret has wrong credentials** | Secret exists but username/password/token is wrong or expired | `kubectl describe pod <pod>` → `unauthorized: authentication required` | Delete and recreate secret with correct credentials |
| 5 | **imagePullSecret not attached to pod/SA** | Secret created but not referenced in pod spec or ServiceAccount | `kubectl describe pod <pod>` → `pull access denied`; `kubectl get pod -o yaml` → no imagePullSecrets | Add to pod spec: `imagePullSecrets: [{name: <secret>}]` or attach to ServiceAccount |
| 6 | **Registry unreachable from node** | Node can't reach the container registry (firewall, DNS, proxy issue) | SSH to node: `curl -I https://<registry>` → connection refused | Fix firewall/proxy rules; configure Docker daemon proxy on node |
| 7 | **Registry rate limiting (Docker Hub)** | Docker Hub pull rate limit exceeded (anonymous: 100/6h, free: 200/6h) | `kubectl describe pod <pod>` → `toomanyrequests` | Authenticate with Docker Hub; use mirror registry; or upgrade to paid plan |
| 8 | **Self-signed / invalid TLS certificate** | Node rejects registry TLS certificate because it's self-signed | SSH to node: `curl https://<registry>` → `SSL certificate problem` | Add CA cert to node's trusted store or configure `insecure-registries` in containerd |
| 9 | **Image doesn't exist for node architecture** | Image built for `amd64` but node is `arm64` (or vice versa) | `kubectl describe pod <pod>` → `no matching manifest for platform` | Build multi-arch image using `docker buildx`; or use arch-specific tag |
| 10 | **Incorrect registry URL** | Wrong registry hostname in image path | `kubectl describe pod <pod>` → `dial tcp: lookup <registry>: no such host` | Fix registry URL in image field; check DNS resolution from node |
| 11 | **ECR / GCR token expired** | Cloud registry tokens (AWS ECR, GCP GCR) have short TTL and expire | `kubectl describe pod <pod>` → `401 Unauthorized` | Use cloud-specific credential helpers or periodic token refresh CronJob |
| 12 | **ImagePullPolicy always + no network** | `imagePullPolicy: Always` forces pull even if image is cached; fails offline | `kubectl describe pod <pod>` → pull attempt fails despite image cached locally | Change to `imagePullPolicy: IfNotPresent` for cached/offline scenarios |

---

## Key Diagnostic Commands

```bash
# Check pod events — always start here
kubectl describe pod <pod-name> -n <namespace>

# Check image name in deployment
kubectl get deployment <name> -o jsonpath='{.spec.template.spec.containers[*].image}'

# Check imagePullSecrets on pod
kubectl get pod <pod> -o jsonpath='{.spec.imagePullSecrets}'

# Check secrets in namespace
kubectl get secrets -n <namespace>

# Inspect secret content
kubectl get secret <secret-name> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Test image pull manually on node
ssh <node>
crictl pull <image>:<tag>
# or
docker pull <image>:<tag>

# Check node can reach registry
curl -I https://registry-1.docker.io
curl -I https://<your-private-registry>
```

---

## Create imagePullSecret (Step-by-Step)

```bash
# For Docker Hub / generic registry
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n <namespace>

# For AWS ECR
kubectl create secret docker-registry ecr-secret \
  --docker-server=<account>.dkr.ecr.<region>.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region <region>)

# Reference in pod spec
spec:
  imagePullSecrets:
    - name: regcred
  containers:
    - name: myapp
      image: myprivaterepo/myapp:1.0
```

---

## Image Pull Policy Reference

| Policy | Behavior | When to Use |
|--------|----------|-------------|
| `Always` | Always pull from registry | Production; ensures latest |
| `IfNotPresent` | Pull only if not cached locally | Dev/offline scenarios |
| `Never` | Never pull; must exist on node | Air-gapped environments |

---

## 6-Step Checklist
```bash
kubectl describe pod <pod> -n <ns>               # 1. read pull error message
kubectl get pod -o yaml | grep image             # 2. verify image name/tag
kubectl get secrets -n <ns>                      # 3. imagePullSecret exists?
kubectl get pod -o jsonpath='{.spec.imagePullSecrets}'  # 4. secret attached?
ssh <node> crictl pull <image>                   # 5. test pull manually on node
ssh <node> curl -I https://<registry>            # 6. registry reachable from node?
```

---

> **Key Principle:** The error message in `kubectl describe pod` Events is very specific — `unauthorized`, `not found`, `toomanyrequests` — each points to a different fix. Always read it carefully.
