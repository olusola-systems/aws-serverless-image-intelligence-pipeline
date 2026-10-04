# Serverless Image Intelligence Pipeline

## Project Overview

For Week 31, I built a serverless image intelligence pipeline that automatically analyzes images uploaded to Amazon S3 and stores the detected image labels and confidence scores in Amazon DynamoDB.

The pipeline uses an Amazon S3 `ObjectCreated` event to trigger an AWS Lambda function. The Lambda function sends the uploaded image to Amazon Rekognition for image analysis, then stores the returned labels and confidence scores in DynamoDB. Amazon CloudWatch provides visibility into the Lambda execution and analysis process.

I provisioned the infrastructure with Terraform so the entire environment can be deployed consistently and managed as code.

## Architecture

#

The pipeline follows this flow:

```text
Image Upload
     │
     ▼
Amazon S3
Image Bucket
     │
     │ ObjectCreated Event
     ▼
AWS Lambda
Image Analyzer
     │
     ├──────────────► Amazon Rekognition
     │                DetectLabels
     │
     ▼
Amazon DynamoDB
Analysis Results
     │
     ▼
Amazon CloudWatch
Logs & Monitoring
```

## How It Works

1. I upload an image to the private Amazon S3 bucket.
2. S3 generates an `ObjectCreated` event.
3. The event invokes the Lambda image analyzer.
4. Lambda identifies the S3 bucket and object key from the event.
5. Lambda sends the image to Amazon Rekognition using `DetectLabels`.
6. Rekognition analyzes the image and returns detected labels with confidence scores.
7. Lambda converts the confidence values to DynamoDB-compatible `Decimal` values.
8. Lambda stores the analysis results in DynamoDB.
9. CloudWatch records the Lambda execution logs.

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon S3 | Stores uploaded images |
| AWS Lambda | Processes and analyzes uploaded images |
| Amazon Rekognition | Detects objects and concepts in images |
| Amazon DynamoDB | Stores image analysis results |
| Amazon CloudWatch | Provides Lambda execution logs |
| AWS IAM | Controls Lambda permissions |
| Terraform | Provisions and manages the infrastructure |

## Terraform Infrastructure

I used Terraform to provision the complete serverless pipeline.

The Terraform configuration creates:

- A private S3 image bucket
- S3 Block Public Access configuration
- S3 server-side encryption using SSE-S3
- S3 versioning
- A DynamoDB results table using on-demand billing
- An IAM role for Lambda
- Least-privilege permissions for S3, Rekognition, DynamoDB, and CloudWatch
- The Lambda image analyzer
- S3-to-Lambda event notification
- Lambda permission allowing S3 to invoke the function

The Terraform configuration uses the AWS provider and packages the Lambda Python source code using the `archive_file` data source.

## Lambda Image Analyzer

The Lambda function is written in Python and uses the AWS SDK for Python (`boto3`).

The function extracts the S3 bucket and object key from the S3 event and sends the image to Rekognition:

```python
response = rekognition.detect_labels(
    Image={
        "S3Object": {
            "Bucket": bucket,
            "Name": key
        }
    },
    MaxLabels=10,
    MinConfidence=80
)
```

The pipeline limits the analysis to the top 10 labels and requires a minimum confidence of 80%.

The returned confidence values are converted to `Decimal` before being written to DynamoDB because DynamoDB does not support Python floating-point values.

## DynamoDB Results

Each analyzed image is stored as an item using the S3 object key as the `imageId`.

The stored item contains:

```text
imageId
bucket
objectKey
labels
analyzedAt
```

The `labels` attribute contains the detected labels and their confidence scores.

For the test image `test-car.jpg`, Rekognition returned:

```text
Machine       100%
Spoke         100%
Wheel         100%
Alloy Wheel   100%
Car           100%
Car Wheel     100%
Tire          100%
Vehicle       100%
Sports Car    93.11%
Coupe         86.46%
```

## Security

I configured the S3 image bucket with security in mind.

The bucket has:

- Block Public Access enabled
- Public ACLs blocked
- Public bucket policies blocked
- Public access restricted
- Server-side encryption using SSE-S3
- Versioning enabled

The Lambda execution role is also limited to the permissions required by the pipeline, including:

- Reading objects from the image bucket
- Calling Rekognition `DetectLabels`
- Writing analysis results to the DynamoDB table
- Writing logs to CloudWatch

No AWS credentials or secrets are stored in the repository.

## Testing and Validation

I tested the pipeline end-to-end by uploading an image named `test-car.jpg` to the S3 bucket.

The first test successfully demonstrated that the S3 event triggered Lambda, but the execution failed when Lambda attempted to store the Rekognition confidence values in DynamoDB because the values were Python floating-point numbers.

I corrected the Lambda implementation by converting the confidence values to `Decimal` before writing them to DynamoDB.

I then uploaded the image again.

The second test successfully completed the entire pipeline:

```text
S3 Upload
   ↓
S3 ObjectCreated Event
   ↓
Lambda
   ↓
Rekognition
   ↓
DynamoDB
   ↓
CloudWatch Logs
```

CloudWatch showed:

```text
IMAGE ANALYSIS REQUEST RECEIVED
Analyzing image: s3://.../test-car.jpg
Analysis complete: 10 labels detected
```

The resulting DynamoDB item contained the image metadata, analysis timestamp, detected labels, and confidence scores.

## Challenges & Solutions

### DynamoDB Float Serialization Error

**Problem:** The first Lambda execution successfully reached the image analysis stage but failed when writing the Rekognition results to DynamoDB.

**Cause:** Rekognition returned confidence values as Python floating-point numbers, while DynamoDB does not support Python `float` values through `boto3`.

**Resolution:** I converted the confidence values to `Decimal` before storing them in DynamoDB.

```python
from decimal import Decimal

labels = [
    {
        "name": label["Name"],
        "confidence": Decimal(str(round(label["Confidence"], 2)))
    }
    for label in response["Labels"]
]
```

After redeploying the Lambda function and uploading the image again, the pipeline completed successfully.

## Lessons Learned

This project helped me understand how event-driven serverless architectures can connect multiple AWS services without requiring a continuously running server. Instead of having a separate application constantly checking for new images, S3 automatically triggered Lambda whenever an object was created.

I also learned an important practical detail about DynamoDB data types. Although Rekognition returns confidence scores as floating-point numbers, DynamoDB requires numeric values to be represented using `Decimal` when using Python's `boto3` library. Understanding how data types behave between AWS services is important when building serverless integrations.

I also gained more experience designing IAM permissions around what a Lambda function actually needs to accomplish. The Lambda role was given access to the image bucket, Rekognition, the specific DynamoDB table, and CloudWatch logging rather than broad administrative permissions.

Finally, this project reinforced the value of infrastructure as code. Terraform allowed me to define the S3 bucket, Lambda function, IAM permissions, DynamoDB table, and event integration in a repeatable configuration rather than manually creating each resource.

## Future Improvements

Some improvements I could make to this pipeline include:

- Build an API for retrieving image analysis results.
- Create a frontend for uploading images and viewing detected labels.
- Add automated CI/CD deployment through GitHub Actions.
- Expand the pipeline to use additional Amazon Rekognition capabilities such as text detection or content moderation.
- Add richer image metadata and search capabilities around analyzed images.

## Project Outcome

I successfully built and tested an event-driven serverless image intelligence pipeline using Amazon S3, AWS Lambda, Amazon Rekognition, DynamoDB, CloudWatch, IAM, and Terraform.

The final system automatically analyzes uploaded images, identifies objects and concepts, records confidence scores, and stores the results for later use.

This project extended my previous serverless work from simply storing and querying image metadata into using AWS-managed machine learning capabilities to extract intelligence from the images themselves.

## Next Project

In the next project, I plan to build on this image intelligence pipeline by introducing an application layer that can interact with the analysis results, moving from an automated backend processing pipeline toward a complete serverless application experience.
