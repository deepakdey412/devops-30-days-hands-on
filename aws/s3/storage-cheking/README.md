# Checking Amazon S3 Bucket Storage Usage

## Objective

Determine the total storage used by an Amazon S3 bucket and the number of objects stored within it.

---

## Method 1: Using AWS CLI

Run the following command:

```bash
aws s3 ls s3://YOUR-BUCKET-NAME --recursive --human-readable --summarize
```

---

## Sample Output

```text
2026-06-10 06:37:05    0 Bytes dev/
2026-06-10 06:37:29    0 Bytes dev/folder01/
2026-06-10 06:46:43  157.9 KiB dev/folder01/Deepak_Dey_Resume.pdf

Total Objects: 5
Total Size: 157.9 KiB
```

---

## Understanding the Output

```text
Total Objects: 5 //Total number of objects stored in the bucket.
```

```text
Total Size: 157.9 KiB //Total storage currently used by the objects in the bucket.
```

---

## Method 2: Using AWS Console

Path:

```text
S3
 └── Bucket
      └── Metrics
           └── Bucket Size Bytes
```

**Note:** Storage metrics are not real-time and may take up to 24 hours to appear.

---

## Important Note About Versioning

If Versioning is enabled:

```text
resume.pdf (v1)
resume.pdf (v2)
resume.pdf (v3)
```

Each version consumes storage.

Actual storage usage includes all object versions, not just the latest version.

---

## Check Object Versions

```bash
aws s3api list-object-versions --bucket YOUR-BUCKET-NAME
```

Purpose:

- View all versions
- Check Version IDs
- Understand storage consumed by versioned objects

---
