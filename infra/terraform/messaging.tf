  data "aws_region" "current" {}

resource "aws_sns_topic" "order-processor" {
  name = "order-processor"
}

resource "aws_sqs_queue" "order-created" {
  name = "order-created"
  delay_seconds              = 10
  visibility_timeout_seconds = 30
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 2
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "order-payment" {
  name = "order-payment"
  delay_seconds              = 10
  visibility_timeout_seconds = 30
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 2
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "order-finished" {
  name = "order-finished"
  delay_seconds              = 10
  visibility_timeout_seconds = 30
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 2
  sqs_managed_sse_enabled = true
}

 #Create IAM Role for SNS to publish to SQS
resource "aws_iam_role" "sns_publish_role" {
  name = "sns_publish_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach policy to allow SNS to publish to SQS to the IAM Role
resource "aws_iam_role_policy_attachment" "sns_publish_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaSQSQueueExecutionRole"
  role       = aws_iam_role.sns_publish_role.name
}


resource "aws_sns_topic_subscription" "orderCreatedSubscription" {
  topic_arn = aws_sns_topic.order-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-created.arn

  filter_policy = jsonencode({
    eventType = ["ORDER_CREATED"]
  })
}

resource "aws_sns_topic_subscription" "orderPaymentSubscription" {
  topic_arn = aws_sns_topic.order-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-payment.arn

   filter_policy = jsonencode({
    eventType = ["WAITING_PAYMENT"]
  })
}

resource "aws_sns_topic_subscription" "orderFinishedSubscription" {
  topic_arn = aws_sns_topic.order-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-finished.arn

   filter_policy = jsonencode({
    eventType = ["PAYMENT_APPROVED", "PAYMENT_REFUSED", "OUT_OF_STOCK"]
  })
}
