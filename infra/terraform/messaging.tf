provider "aws" {
  region = "us-east-1"
}

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


######################### END OF ROLES AND POLICIES ###################

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

#############################################
resource "aws_iam_policy" "order-created-policy" {
  name = "order-created-policy"
  policy = <<EOF
  "Version": "2012-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "topic-subscription-arn: "${aws_sns_topic_subscription.orderPaymentSubscription.arn}",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.order-created.arn}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "${aws_sns_topic.order-processor.arn}"
        }
      }
    }
  ]
}
EOF
}


resource "aws_sqs_queue_policy" "order-created-queue-policy" {
  queue_url = aws_sqs_queue.order-created.url
  policy     = aws_iam_policy.order-created-policy.policy
}
