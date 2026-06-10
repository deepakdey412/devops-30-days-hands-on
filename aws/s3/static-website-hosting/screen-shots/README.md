# Amazon S3 Static Website Hosting

## Objective

Host a static website (HTML, CSS, JavaScript, images) directly from an Amazon S3 bucket without using an EC2 instance.

---

## Step 1: Create an `index.html` File

**Purpose:** Create the homepage of the website.

```html
<!DOCTYPE html>
<html>
  <head>
    <title>My S3 Website</title>
  </head>
  <body>
    <h1>Hello from Amazon S3!</h1>
  </body>
</html>
```

---

## Step 2: Upload Files to the S3 Bucket

**Purpose:** Store the website files inside the S3 bucket.

```text
S3 Bucket
 └── index.html
```

---

## Step 3: Enable Static Website Hosting

**Path:**

```text
S3 Bucket
 └── Properties
      └── Static Website Hosting
           └── Enable
```

**Configuration:**

```text
Index document:
index.html
```

**Purpose:** Configure the S3 bucket to serve website content.

---

## Step 4: Disable Block Public Access

**Path:**

```text
S3 Bucket
 └── Permissions
      └── Block Public Access
```

**Purpose:** Allow public users to access the website content.

---

## Step 5: Add a Bucket Policy

**Path:**

```text
S3 Bucket
 └── Permissions
      └── Bucket Policy
```

**Purpose:** Grant public read access to website files.

Example Policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

---

## Step 6: Open the Website Endpoint

**Path:**

```text
Properties
 └── Static Website Hosting
      └── Bucket Website Endpoint
```

Example:

```text
http://bucket-name.s3-website-ap-south-1.amazonaws.com
```

**Purpose:** Access the hosted website through the generated endpoint URL.

---

## Key Benefits

- No EC2 instance required
- Low-cost hosting solution
- Easy deployment
- Highly available and scalable
- Ideal for static websites and portfolios
