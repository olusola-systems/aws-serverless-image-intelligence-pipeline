import json
import os
from datetime import datetime, timezone
from decimal import Decimal
from urllib.parse import unquote_plus

import boto3


rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TABLE_NAME"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    print("IMAGE ANALYSIS REQUEST RECEIVED")

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        print(f"Analyzing image: s3://{bucket}/{key}")

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

        labels = [
            {
                "name": label["Name"],
                "confidence": Decimal(str(round(label["Confidence"], 2)))
            }
            for label in response["Labels"]
        ]

        image_id = key

        table.put_item(
            Item={
                "imageId": image_id,
                "bucket": bucket,
                "objectKey": key,
                "labels": labels,
                "analyzedAt": datetime.now(timezone.utc).isoformat()
            }
        )

        print(f"Analysis complete: {len(labels)} labels detected")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Image analysis completed successfully"
        })
    }
