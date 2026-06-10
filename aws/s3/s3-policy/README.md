# 🔐 Amazon S3 Security — Flow-Based Notes

> **Purpose:** Quick-reference guide covering S3 security mechanisms, how they work, and when to use them.

---

## 1. 🧑‍💼 IAM Users + S3 Access

**Purpose:** Grant individual AWS users permission to access S3 via identity-based policies.

```
IAM User → Has IAM Policy?
    ├── Yes → Policy allows S3 action? → Yes → ✅ Access Granted
    │                                  → No  → ❌ Access Denied
    └── No  → ❌ Access Denied
```

**Example:** Attach `AmazonS3ReadOnlyAccess` to a developer IAM user to allow read-only bucket access.

---

## 2. 🤖 IAM Roles + S3 Access

**Purpose:** Grant temporary, role-based S3 access to AWS services (e.g., EC2, Lambda) or cross-account principals — no long-term credentials needed.

```
EC2 / Lambda / Cross-Account User
    → Assumes IAM Role
        → Role has S3 Policy?
            ├── Yes → ✅ Temporary credentials issued → Access Granted
            └── No  → ❌ Access Denied
```

**Example:** Attach a role with `s3:GetObject` to an EC2 instance so it can read files without storing AWS keys.

---

## 3. 📋 Bucket Policies

**Purpose:** Resource-based policies attached directly to an S3 bucket — control who (any principal, including other accounts) can do what.

```
Request arrives at Bucket
    → Bucket Policy exists?
        ├── Yes → Policy allows action + principal?
        │           ├── Yes → ✅ Access Granted
        │           └── No  → ❌ Access Denied
        └── No  → Fall through to IAM / ACL checks
```

**Example:** Allow a specific external AWS account to `s3:PutObject` into your bucket by specifying their Account ID as the principal.

> 💡 Bucket policies can **grant or deny** access and support conditions (e.g., IP range, MFA, VPC).

---

## 4. 🚫 Block Public Access

**Purpose:** Account-level or bucket-level guardrails that override policies/ACLs to prevent any public exposure — even if a policy accidentally allows it.

```
Public Access Request
    → Block Public Access setting ON?
        ├── Yes → ❌ Blocked (regardless of bucket policy or ACL)
        └── No  → Evaluate bucket policy / ACL normally
```

**Example:** Enable "Block all public access" on an account to ensure no bucket is ever accidentally made public.

> ⚠️ Recommended to keep **enabled by default** for all buckets unless intentionally hosting public content.

---

## 5. 📄 ACL (Access Control Lists)

**Purpose:** Legacy, object/bucket-level permissions using predefined grants. Mostly superseded by bucket policies but still used for cross-account object ownership.

```
Request for S3 Object
    → ACL enabled on bucket?
        ├── Yes → Requester matches ACL grantee?
        │           ├── Yes → ✅ Access Granted
        │           └── No  → ❌ Access Denied
        └── No (ACL disabled / Object Ownership = BucketOwner) → Use Policy only
```

**Example:** Grant another AWS account `READ` permission on a specific object using a canned ACL (`bucket-owner-read`).

> 💡 AWS now recommends **disabling ACLs** and using bucket policies for all access control.

---

## 6. 🔗 Pre-Signed URLs

**Purpose:** Provide time-limited, secure access to a private S3 object without changing bucket permissions — anyone with the URL can access it until it expires.

```
App / User requests file access
    → Backend generates Pre-Signed URL
        (signed with IAM credentials + expiry time)
    → URL shared with requester
        → Request made before expiry?
            ├── Yes → ✅ S3 serves the object
            └── No  → ❌ URL expired, Access Denied
```

**Example:** Generate a 15-minute pre-signed URL so a customer can download their invoice from a private S3 bucket.

> ⏱️ Expiry can range from **seconds to 7 days** (depending on credential type used).

---

## 7. 🗑️ MFA Delete

**Purpose:** Require multi-factor authentication to permanently delete object versions or disable versioning — protects against accidental or malicious deletion.

```
Delete request on versioned object
    → MFA Delete enabled on bucket?
        ├── Yes → Valid MFA token provided?
        │           ├── Yes → ✅ Delete proceeds
        │           └── No  → ❌ Delete rejected
        └── No  → Delete proceeds without MFA check
```

**Example:** Enable MFA Delete on a compliance bucket so that even a compromised root account cannot silently delete audit logs.

> 🔑 MFA Delete can only be enabled/disabled by the **root account** using the AWS CLI.

---

## 🗺️ Complete S3 Security Flow

```
Incoming S3 Request
        │
        ▼
[1] Block Public Access ON?
    ├── Yes + Public Request → ❌ DENY
    └── No / Private Request → Continue
        │
        ▼
[2] Is there an explicit DENY in Bucket Policy?
    └── Yes → ❌ DENY (always wins)
        │
        ▼
[3] Bucket Policy has explicit ALLOW?
    ├── Yes → ✅ ALLOW
    └── No  → Continue
        │
        ▼
[4] Is requester using an IAM Role or User?
    └── IAM Policy has explicit ALLOW?
        ├── Yes → ✅ ALLOW
        └── No  → Continue
            │
            ▼
[5] ACL grants access?
    ├── Yes → ✅ ALLOW
    └── No  → ❌ DENY (default)
        │
        ▼
[6] Is this a versioned object delete?
    └── MFA Delete enabled?
        ├── Yes → Valid MFA? → Yes → ✅ | No → ❌
        └── No  → Proceed normally

[Pre-Signed URL] bypasses IAM/ACL checks — valid if not expired ⏱️
```

---

## 📝 Quick Revision Summary

| Mechanism               | Type                  | Best Used For                                           |
| ----------------------- | --------------------- | ------------------------------------------------------- |
| **IAM Users + Policy**  | Identity-based        | Granting AWS users direct S3 access                     |
| **IAM Roles**           | Identity-based        | EC2, Lambda, cross-account temporary access             |
| **Bucket Policy**       | Resource-based        | Fine-grained, cross-account, condition-based rules      |
| **Block Public Access** | Guardrail             | Preventing accidental public exposure                   |
| **ACL**                 | Legacy resource-based | Object-level cross-account grants (legacy)              |
| **Pre-Signed URL**      | Time-limited token    | Sharing private objects securely without policy changes |
| **MFA Delete**          | Deletion safeguard    | Protecting versioned objects from deletion              |

> 🔑 **Golden Rule:** An explicit **DENY always wins**. Without an explicit ALLOW, the default is **DENY**.
