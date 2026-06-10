# AWS Lambda

## Overview

AWS Lambda is a serverless compute service that allows you to run code without provisioning or managing servers. You simply upload your code, configure a trigger, and AWS automatically executes the function whenever the specified event occurs.

Lambda follows an event-driven architecture and automatically scales based on incoming requests. AWS manages the underlying infrastructure, operating system, patching, availability, and scaling.

---

## How Lambda Works

```text
Event Source
     │
     ▼
AWS Lambda
     │
     ▼
Process Request
     │
     ▼
Return Response
```

A Lambda function is executed only when an event triggers it. Once the execution is completed, the resources are released automatically.

---

## Common Event Sources

- Amazon S3
- API Gateway
- DynamoDB Streams
- EventBridge
- CloudWatch Events
- SNS
- SQS
- Step Functions

---

## Example: Image Processing

```text
User Uploads Image
        │
        ▼
     S3 Bucket
        │
        ▼
 AWS Lambda Trigger
        │
        ▼
 Resize Image
        │
        ▼
 Save Back to S3
```

When a user uploads an image to an S3 bucket, Lambda is automatically triggered, processes the image, and stores the output without requiring any server management.

---

## Key Features

- Serverless execution model
- Automatic scaling
- Event-driven architecture
- High availability
- Pay-per-use pricing
- Native integration with AWS services
- Supports multiple programming languages

---

## Supported Languages

- Java, Python, Node.js, Go, C#,Ruby, Custom Runtime

---

## Advantages

- No server management required
- Automatically scales with traffic
- Reduced operational overhead
- Cost-effective for variable workloads
- Fast integration with AWS services
- Suitable for microservices and automation

---

## Limitations

- Maximum execution time: 15 minutes
- Cold start latency may occur
- Not ideal for long-running processes
- Limited execution environment compared to EC2

---

## Production Use Cases

### Serverless APIs

```text
Client
  │
  ▼
API Gateway
  │
  ▼
Lambda
  │
  ▼
Database
```

Used for building scalable REST APIs without managing servers.

### DevOps Automation

```text
CloudWatch Event
        │
        ▼
      Lambda
        │
        ▼
Start/Stop Resources
```

Used to automate infrastructure tasks such as starting or stopping EC2 instances.

### File Processing

```text
S3 Upload
    │
    ▼
 Lambda
    │
    ▼
 Process File
```

Used for image resizing, document conversion, and data validation.

### Scheduled Tasks

```text
EventBridge Schedule
         │
         ▼
       Lambda
         │
         ▼
 Execute Job
```

Used for backups, reports, cleanup jobs, and automation scripts.

---

## Lambda vs EC2

| AWS Lambda                      | EC2                                |
| ------------------------------- | ---------------------------------- |
| Serverless                      | Server-based                       |
| No infrastructure management    | Full server management             |
| Auto Scaling                    | Manual/Auto Scaling Groups         |
| Pay per execution               | Pay while instance is running      |
| Best for event-driven workloads | Best for long-running applications |

---

## Real Production Architecture

```text
Users
  │
  ▼
API Gateway
  │
  ▼
Lambda Functions
  │
  ▼
DynamoDB / RDS / S3
```

or

```text
S3
 │
 ▼
Lambda
 │
 ▼
SNS/SQS
 │
 ▼
Other Services
```

---

## Interview One-Liner

AWS Lambda is a serverless compute service that executes code in response to events without requiring server management, automatically scales based on demand, and charges only for the execution time consumed.
