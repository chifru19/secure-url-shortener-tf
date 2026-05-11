import boto3
import os
import uuid
import json

# Connect to DynamoDB (LocalStack will intercept this)
dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:4566", region_name="us-east-1")
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE', 'urls'))

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        long_url = body.get('url')
        
        if not long_url:
            return {"statusCode": 400, "body": json.dumps({"error": "URL is required"})}

        short_id = str(uuid.uuid4())[:8]
        table.put_item(Item={'id': short_id, 'long_url': long_url})

        return {
            "statusCode": 200,
            "body": json.dumps({
                "short_url": f"https://frank.ly/{short_id}",
                "original": long_url
            })
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
