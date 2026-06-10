# 📦 Amazon ECR — Flow-Based Notes

> **Purpose:** Quick-reference guide covering what ECR is, how it compares to Docker Hub, how images are stored, versioning, and storage mechanics.

---

## 1. 🤔 What is Amazon ECR?

**Amazon Elastic Container Registry (ECR)** is a fully managed AWS service for storing, managing, and deploying **Docker (and OCI-compatible) container images**.

Think of it as **Docker Hub — but private, AWS-native, and integrated with IAM**.

```
Developer builds image
    → Tags it
    → Pushes to ECR repository
        → ECS / EKS / Lambda pulls the image
            → Container runs ✅
```

ECR handles the registry infrastructure — you just push and pull images.

---

## 2. 🆚 ECR vs Docker Hub

| Feature            | Amazon ECR                                 | Docker Hub                                |
| ------------------ | ------------------------------------------ | ----------------------------------------- |
| **Hosting**        | AWS-managed, private by default            | Public cloud, public by default           |
| **Access Control** | IAM policies + resource-based policies     | Username/password, teams                  |
| **Integration**    | Native with ECS, EKS, CodePipeline, Lambda | Requires manual config with AWS           |
| **Network**        | Stays within AWS VPC (no internet needed)  | Traffic goes over public internet         |
| **Pricing**        | Pay for storage + data transfer            | Free tier limited; paid for private repos |
| **Image Scanning** | Built-in (Basic + Enhanced via Inspector)  | Available on paid plans                   |
| **Availability**   | AWS SLA-backed                             | Public service, occasional outages        |
| **Authentication** | `aws ecr get-login-password` via AWS CLI   | `docker login` with credentials           |

```
Docker Hub Flow:
  Developer → docker push → Docker Hub (internet) → ECS pulls (internet)

ECR Flow:
  Developer → aws ecr get-login-password → docker push → ECR (within AWS)
      → ECS / EKS pulls (private network) ✅ faster + more secure
```

> 💡 For AWS workloads, **ECR is preferred** — no internet hop, IAM-controlled, and tightly integrated.

---

## 3. 🗂️ How Images Are Stored in ECR

### Repository Structure

```
AWS Account
    └── ECR Registry (one per region per account)
            └── Repository (e.g., "my-app")
                    ├── Image (tagged: v1.0)
                    ├── Image (tagged: v1.1)
                    ├── Image (tagged: latest)
                    └── Image (untagged — digest only)
```

- Each **repository** holds multiple image versions.
- Each **image** is identified by a **tag** (e.g., `v1.0`) and a **digest** (immutable SHA256 hash).
- Images are stored as **layers** — shared layers across images are stored only once (deduplication).

### Storage Flow

```
docker build → creates image layers (each layer = a diff)
    → docker push to ECR
        → ECR checks: does this layer already exist?
            ├── Yes → skip upload (deduplication) ✅
            └── No  → upload and store layer
```

> 💡 Layer deduplication saves storage costs — if two images share a base OS layer, it's only stored once.

---

## 4. 🔢 Versioning in ECR

ECR does **not** have automatic semantic versioning — you control tags manually. There are two identifiers per image:

### Tags (Mutable by default)

- Human-readable labels like `v1.0`, `latest`, `prod`, `staging`.
- By default, tags are **mutable** — you can push a new image with the same tag and it overwrites the old one.
- Enable **Tag Immutability** to prevent overwriting a tag once pushed.

```
Tag Immutability OFF (default):
  Push image → tag: latest → stores as latest
  Push new image → tag: latest → OVERWRITES previous latest ⚠️

Tag Immutability ON:
  Push image → tag: v1.0 → stores as v1.0
  Push new image → tag: v1.0 → ❌ REJECTED (tag already exists)
```

### Digests (Always Immutable)

- A SHA256 hash of the image manifest — never changes, never overwritten.
- Even if a tag is overwritten, the old image is still accessible via its digest.

```
Image reference options:
  my-app:latest             ← by tag (may change if mutable)
  my-app@sha256:abc123...   ← by digest (always the same image)
```

> ✅ Best practice: Use **digest references** in production deployments for deterministic behavior.

---

## 5. 💾 Storage Details

### What Takes Up Storage Space?

- **Image layers** — each unique layer is billed once (deduplication applies).
- **Image manifests** — small JSON files describing the image; not significant in size.
- **Untagged images** — old image versions pushed out by newer tags; still stored until deleted.

### Pricing

- **Storage:** ~$0.10 per GB/month.
- **Data transfer in:** Free.
- **Data transfer out:** Free within the same AWS region; charged for cross-region or internet transfers.

### Lifecycle Policies 🧹

ECR supports **lifecycle policies** to auto-delete old/untagged images and control costs.

```
Lifecycle Policy Rule Example:
  → If image is untagged
      AND older than 7 days
          → ❌ Delete automatically

  → If more than 5 tagged images exist with prefix "dev-"
      → Delete oldest beyond 5
```

```
Configure lifecycle policy:
  ECR Console → Repository → Lifecycle Policy → Add Rule
      → Set: tag prefix / untagged / count / age
      → Save → ECR enforces automatically
```

> 💡 Without lifecycle policies, old untagged images accumulate silently and increase storage costs.

---

## 6. 🔐 Security in ECR

```
Pulling an Image:
  ECS Task / Developer
      → Authenticate: aws ecr get-login-password | docker login
          → IAM policy allows ecr:GetAuthorizationToken?
              ├── Yes → Token issued (valid 12 hours)
              └── No  → ❌ Auth Denied
                  → Pull image: ecr:BatchGetImage + ecr:GetDownloadUrlForLayer
                      ├── Allowed → ✅ Image pulled
                      └── Denied  → ❌ Pull failed
```

Key security features:

- **IAM policies** control push/pull access per user, role, or service.
- **Repository policies** (resource-based) allow cross-account access.
- **Encryption at rest** — images are encrypted using AWS KMS (AES-256 by default).
- **Image scanning** — scans for OS/package vulnerabilities on push or on demand.

---

## 🗺️ Complete ECR Flow

```
[1] Build Image
    docker build -t my-app:v1.0 .
        │
        ▼
[2] Authenticate to ECR
    aws ecr get-login-password --region us-east-1 \
      | docker login --username AWS <account>.dkr.ecr.amazonaws.com
        │
        ▼
[3] Tag Image for ECR
    docker tag my-app:v1.0 <account>.dkr.ecr.<region>.amazonaws.com/my-app:v1.0
        │
        ▼
[4] Push to ECR
    docker push <account>.dkr.ecr.<region>.amazonaws.com/my-app:v1.0
        → ECR deduplicates layers
        → Stores image + manifest
        → Assigns digest (SHA256)
        │
        ▼
[5] Deploy
    ECS / EKS / Lambda pulls image from ECR
    (stays within AWS network — no internet hop)
        │
        ▼
[6] Lifecycle Policy (ongoing)
    ECR auto-deletes old/untagged images per rules ✅
```

---

## 📝 Quick Revision Summary

| Topic                  | Key Point                                                         |
| ---------------------- | ----------------------------------------------------------------- |
| **What is ECR**        | AWS-managed private container image registry                      |
| **vs Docker Hub**      | Private by default, IAM-controlled, AWS-native, no internet hop   |
| **Storage**            | Images stored as deduplicated layers; manifests per image         |
| **Tags**               | Mutable by default; enable immutability to lock tags              |
| **Digests**            | SHA256 hash; always immutable; use in prod for reliability        |
| **Versioning**         | Manual tagging (no auto-versioning); digest is the true version   |
| **Lifecycle Policies** | Auto-delete old/untagged images to control cost                   |
| **Security**           | IAM + repo policies, KMS encryption, built-in image scanning      |
| **Auth token**         | Valid for **12 hours**; obtained via `aws ecr get-login-password` |

> 🔑 **Golden Rule:** Tag for humans, digest for machines. Always enable tag immutability and lifecycle policies in production.
