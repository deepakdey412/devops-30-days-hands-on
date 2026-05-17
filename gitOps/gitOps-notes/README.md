# 🚀 Argo CD + GitOps — Engineering Reference

> **Core idea:** Git is the single source of truth. Argo CD ensures your cluster always reflects it — automatically, continuously, without human intervention.

---

## 📋 Table of Contents

1. [Why Manual Deployments Break at Scale](#1-why-manual-deployments-break-at-scale)
2. [What is GitOps?](#2-what-is-gitops)
3. [GitOps in One Diagram](#3-gitops-in-one-diagram)
4. [Desired State vs Actual State](#4-desired-state-vs-actual-state)
5. [Pull vs Push — The Security Argument](#5-pull-vs-push--the-security-argument)
6. [CI vs CD — Separation of Concerns](#6-ci-vs-cd--separation-of-concerns)
7. [Full Industry Workflow](#7-full-industry-workflow)
8. [Key Features](#8-key-features)
9. [Argo CD Application — Core Config](#9-argo-cd-application--core-config)
10. [Multi-Environment Production Pattern](#10-multi-environment-production-pattern)
11. [Argo CD Internal Architecture](#11-argo-cd-internal-architecture)
12. [Sync & Health Status Reference](#12-sync--health-status-reference)
13. [Real-World Impact](#13-real-world-impact)
14. [The Golden Rule](#14-the-golden-rule)

---

## 1. Why Manual Deployments Break at Scale

```bash
kubectl apply -f deployment.yml   # who ran this? when? which version?
```

At scale, this becomes a liability:

- **No audit trail** — who deployed what, and when
- **Drift** — production diverges silently from your repo
- **Human error** — wrong context, wrong namespace, wrong version
- **No rollback strategy** — reverting means remembering what was there before
- **Credential exposure** — CI tools need direct cluster access

GitOps eliminates all of this by treating Git as the deployment mechanism itself.

---

## 2. What is GitOps?

```
GitOps = Git + Operations
       = GitHub controls Kubernetes automatically
       = What's in GitHub → what runs in production
```

GitHub becomes three things at once:
- 📋 **Source of Truth** — the real config store
- 🔐 **Deployment Control** — no manual `kubectl` needed
- 📜 **Audit Log** — `git log` shows every change, by whom, when

---

## 3. GitOps in One Diagram

```
Developer
   │  git push
   ▼
GitHub Repo ──────────────────────────────┐
(Desired State: replicas=3, image=v2)     │
                                          │ Argo CD polls / webhook
                                          ▼
                                     Argo CD
                                  (lives inside cluster)
                                     │
                              Compare desired vs actual
                                     │
                    ┌────────────────┴─────────────────┐
                    │ Mismatch?                         │ Match?
                    ▼                                   ▼
             kubectl apply                        Do nothing ✅
                    │
                    ▼
           Kubernetes Cluster
           (Actual State synced)
```

**No Jenkins pushing to cluster. No SSH. No manual `kubectl`.** The cluster reaches out to Git — not the other way around.

---

## 4. Desired State vs Actual State

This is the entire foundation of GitOps:

| | Desired State | Actual State |
|---|---|---|
| **Where** | Git Repository | Kubernetes Cluster |
| **What** | Your YAML manifests | Running pods, deployments, services |
| **Owned by** | Developers (via PRs) | Argo CD (via reconciliation) |

```yaml
# GitHub says this:        # Cluster has this:     # Argo CD does:
replicas: 3          ≠     2 pods running     →    Creates 1 pod ✅
image: myapp:v2      ≠     image: myapp:v1    →    Rolls out v2  ✅
replicas: 3          =     3 pods running     →    Nothing       ✅
```

This constant compare-and-correct cycle is the **Reconciliation Loop** — it runs continuously, not just on deployments.

---

## 5. Pull vs Push — The Security Argument

```
❌ Push (Traditional CI/CD)
   Jenkins ──PUSHES──▶ Kubernetes
   Cluster credentials live in CI. Attack surface: HIGH.

✅ Pull (GitOps)
   Argo CD (inside cluster) ──PULLS FROM──▶ GitHub
   Cluster never exposes itself externally. Attack surface: LOW.
```

Argo CD runs **inside** your cluster. It pulls from Git. Your cluster never needs inbound access from external tools — a fundamental security improvement that most teams underestimate.

---

## 6. CI vs CD — Separation of Concerns

```
CI Pipeline (Build)                    CD Pipeline (Deploy)
──────────────────────────────────────────────────────────
GitHub Actions / Jenkins               Argo CD
        │                                    │
        ▼                                    ▼
  Lint + Test code                   Watch Git for changes
  Build Docker image                 Compare desired vs actual
  Push → DockerHub / ECR             Sync to Kubernetes
  Update image tag in YAML           Self-heal on drift
  git push manifest repo ──────────▶ Deploy automatically
```

> **Rule of thumb:** CI owns the artifact. CD owns the delivery. Never mix them.

---

## 7. Full Industry Workflow

```
Feature branch merged to main
          │
          ▼
   GitHub Actions triggered
   ├── Run tests
   ├── Build Docker image (myapp:v2.1.4)
   └── Push to ECR / DockerHub
          │
          ▼
   Update K8s manifest repo
   └── image: myapp:v2.1.4  (git commit + push)
          │
          ▼
   Argo CD detects manifest change
   └── Syncs cluster to new desired state
          │
          ▼
   Rolling update in Kubernetes ✅
   └── Zero-downtime. Fully automated.
```

Tagging images with the **exact Git SHA** (e.g. `myapp:abc1234`) makes every deployment fully traceable to a commit.

---

## 8. Key Features

| Feature | Behaviour |
|---|---|
| **Auto Sync** | Deploys on every Git push, no manual trigger |
| **Drift Detection** | Catches manual `kubectl` changes not in Git |
| **Self Healing** | Reverts drift automatically back to Git state |
| **Pruning** | Deletes Kubernetes resources removed from Git |
| **Rollback** | `git revert` → Argo redeploys the previous state |
| **Multi-cluster** | One Argo CD instance can manage many clusters |

### Drift in Practice
```bash
# Someone panics and manually scales in production:
kubectl scale deployment api --replicas=20

# Git still declares:
replicas: 3

# With selfHeal: true — Argo CD reverts to 3 within minutes.
# Git wins. Always.
```

---

## 9. Argo CD Application — Core Config

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payments-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/k8s-manifests
    targetRevision: HEAD
    path: services/payments/production
  destination:
    server: https://kubernetes.default.svc
    namespace: payments-prod
  syncPolicy:
    automated:
      prune: true       # remove resources deleted from Git
      selfHeal: true    # revert manual cluster changes
    syncOptions:
      - CreateNamespace=true
```

---

## 10. Multi-Environment Production Pattern

```
k8s-manifests/
├── base/                    # shared configs (Kustomize base)
│   └── deployment.yml
└── overlays/
    ├── dev/                 # replicas: 1 | image: :latest
    ├── staging/             # replicas: 2 | image: :v1.8
    └── production/          # replicas: 10 | image: :v1.7
```

Each environment has its own Argo CD Application pointing to its overlay. Promotion = updating the image tag in the next environment via a PR. **Promotion is a code review, not a manual operation.**

---

## 11. Argo CD Internal Architecture

```
┌──────────────────────────────────────────────┐
│                  Argo CD                     │
│                                              │
│  API Server      → REST/gRPC, UI, CLI, RBAC  │
│  Repo Server     → Git clone, YAML/Helm/     │
│                    Kustomize rendering        │
│  App Controller  → Reconciliation engine,    │
│                    desired vs actual compare  │
│  Redis           → State cache               │
└──────────────────┬───────────────────────────┘
                   │  kubectl / K8s API
                   ▼
          Kubernetes Cluster
```

Argo CD supports **Helm, Kustomize, Jsonnet, and plain YAML** — no lock-in to a single templating approach.

---

## 12. Sync & Health Status Reference

```
Sync Status         Health Status
─────────────────   ──────────────────────────
✅ Synced           ✅ Healthy      — all good
⚠️  OutOfSync       ⚠️  Degraded    — something failing
❌ Missing          🔄 Progressing  — rollout in progress
                    ⏸️  Suspended    — paused manually
```

---

## 13. Real-World Impact

| Problem | GitOps Solution |
|---|---|
| "Who deployed this?" | `git log` — full history, author, timestamp |
| "Production is broken" | `git revert` + auto-redeploy in minutes |
| "The cluster drifted" | Self-healing reverts to Git state |
| "Cluster was wiped" | Recreate it. Argo restores everything from Git. |
| "CI needs cluster creds" | Not with pull model — zero external exposure |

---

## 14. The Golden Rule

```
╔══════════════════════════════════════════════════╗
║  Never change the cluster directly.              ║
║  Change Git. Argo CD handles the rest.           ║
╚══════════════════════════════════════════════════╝
```

If `kubectl edit` or `kubectl apply` is your deployment process, you're building technical debt. Every manual change that isn't in Git is a change you'll eventually lose, forget, or break.

---

## ⚡ Engineering Mental Model

```
Declarative Config  +  Version Control  +  Automated Reconciliation
                                        =
                              Production you can trust
```

GitOps is not a tool — it's a discipline. Argo CD is just the best implementation of it for Kubernetes.

---

*Argo CD Docs: [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io) · CNCF Graduated Project*