import json
import os
import boto3
import uuid
from datetime import datetime, timezone

TABLE_NAME = os.environ["TABLE_NAME"]
TOPIC_ARN = os.environ["ORDER_EVENTS_TOPIC_ARN"]

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
sns = boto3.client("sns")

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Request body must be valid JSON"})

    customer_id = body.get("customerId")
    items = body.get("items")

    if not customer_id or not items:
        return _response(400, {"error": "customerId and items are required fields"})

    order_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()
    status = "PENDING"

    order_item = {
        "PK": f"ORDER#{order_id}",
        "SK": f"ORDER#{order_id}",
        "GSI1PK": f"STATUS#{status}",
        "GSI1SK": f"ORDER#{order_id}",
        "orderId": order_id,
        "customerId": customer_id,
        "items" : items,
        "status": status,
        "createdAt": created_at
    }

    table.put_item(Item = order_item)

    sns.publish(
        TopicArn = TOPIC_ARN,
        Message = json.dumps({
            "orderId": order_id,
            "customerId": customer_id,
            "items": items,
            "status": status
        }),
        MessageAttributes = {
            "eventType": {
                "DataType": "String",
                "StringValue": "OrderCreated"
            }
        }
    )

    return _response(
        201, 
        {
            "orderId": order_id,
            "status": status,
            "createdAt": created_at
        }
    )


def _response(status_code, body_dict):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body_dict)
    }
