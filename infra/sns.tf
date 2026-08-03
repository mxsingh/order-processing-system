resource "aws_sns_topic" "order_events" {
  name = "${var.project_name}-order-events"
}