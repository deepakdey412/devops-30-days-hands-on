# Amazon S3 Object Versioning

## Objective

Enable versioning in an Amazon S3 bucket to preserve, retrieve, and restore different versions of an object.

---

## What is S3 Versioning?

Amazon S3 Versioning is a feature that keeps multiple versions of the same object in a bucket. When a file is uploaded, modified, or deleted, S3 preserves the previous version instead of permanently replacing it.

**Benefits:**

- Protects against accidental deletion
- Protects against accidental overwrites
- Allows recovery of previous versions
- Improves data durability and backup capabilities

---

## Step 1: Create an S3 Bucket

**Purpose:** Create a bucket to store objects.

```text id="8o4nh4"
S3
 └── Create Bucket
```

---

## Step 2: Enable Bucket Versioning

**Path:**

```text id="9d0i1m"
S3 Bucket
 └── Properties
      └── Bucket Versioning
           └── Enable
```

**Purpose:** Allow S3 to maintain multiple versions of the same object.

---

## Step 3: Upload an Object

Example:

```text id="lzjlwm"
resume.pdf
```

S3 assigns a unique Version ID.

```text id="l3ql0r"
Version ID: v1
```

---

## Step 4: Upload the Same Object Again

Upload the updated file using the same name.

```text id="q1efyi"
resume.pdf
```

S3 creates a new version instead of replacing the old one.

```text id="c9v8py"
Version ID: v2
```

---

## Step 5: View Object Versions

**Path:**

```text id="rw93zl"
Bucket
 └── Objects
      └── Show Versions
```

**Purpose:** View all versions of an object stored in the bucket.

---

## Version History

```text id="08ykkf"
resume.pdf (v3)
     │
     ▼
resume.pdf (v2)
     │
     ▼
resume.pdf (v1)
```

All versions remain stored until they are explicitly deleted.

---

## Important Note

Objects uploaded **before enabling versioning** have:

```text id="1qlb0m"
Version ID = null
```

Objects uploaded **after enabling versioning** receive unique Version IDs.

Example:

```text id="38kj2g"
resume.pdf
 ├── Version ID: null
 ├── Version ID: qsDlgef_0YOV1axG...
 └── Version ID: YgH76sdfKj89mN2...
```

---

## Key Benefits

- Prevents accidental data loss
- Supports rollback and recovery
- Maintains object history
- Improves backup and disaster recovery strategies
