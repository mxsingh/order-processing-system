import json

def handler(event, context):
    for record in event["Records"]:
        order_event = _unwrap(record)
        order_id = order_event.get("orderId")
        items = order_event.get("items", [])

        print(f"[inventory-check] order {order_id}: checking stock for {items}")

    return {"batchItemFailures": []}


def _unwrap(record):
    sns_envelope = json.loads(record["body"])
    return json.loads(sns_envelope["Message"])