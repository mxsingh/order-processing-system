import json

def handler(event, context):
    for record in event["Records"]:
        order_event = _unwrap(record)
        order_id = order_event.get("orderId")
        customer_id = order_event.get("customerId")

        print(f"[notification] order {order_id}: notifying customer {customer_id}")

    return {"batchItemFailures": []}


def _unwrap(record):
    sns_envelope = json.loads(record["body"])
    return json.loads(sns_envelope["Message"])