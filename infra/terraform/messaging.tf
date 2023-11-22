provider "aws" {
  region = "us-east-1"
  access_key              = "mock_access_key"
  secret_key              = "mock_secret_key"
}

resource "aws_sns_topic" "order-processor" {
  name = "order-processor"
}

resource "aws_sqs_queue" "order-created" {
  name = "order-created"
}

resource "aws_sqs_queue" "order-payment" {
  name = "order-payment"
}

resource "aws_sqs_queue" "order-finished" {
  name = "order-finished"
}

resource "aws_sns_topic_subscription" "orderCreatedSubscription" {
  topic_arn = aws_sns_topic.order-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-created.arn

  filter_policy = {
    eventType = ["ORDER_CREATED"]
  }
}

resource "aws_sns_topic_subscription" "orderPaymentSubscription" {
  topic_arn = aws_sns_topic.order-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-payment.arn

   filter_policy = {
    eventType = ["WAITING_FOR_PAYMENT"]
  }
}

resource "aws_sns_topic_subscription" "subscription3" {
  topic_arn = aws_sns_topic.eorder-processor.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order-finished.arn

   filter_policy = {
    eventType = ["PAYMENT_APPROVED", "PAYMENT_REFUSED", "OUT_OF_STOCK"]
  }
}
