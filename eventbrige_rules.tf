
# EC2 Rule
resource "aws_cloudwatch_event_rule" "ec2_run_instances" {
  name        = "ec2-runinstances-rule"
  description = "Capture EC2 RunInstances events from CloudTrail"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : ["RunInstances"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_run_instances.name
  target_id = "TagEnforcerLambda"
  arn       = aws_lambda_function.tag_enforcer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_enforcer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_run_instances.arn
}

# RDS Rule
resource "aws_cloudwatch_event_rule" "rds_createdb" {
  name        = "RDS-CreateDB-Rule"
  description = "Trigger Lambda on RDS creation"
  event_pattern = jsonencode({
    "source" : ["aws.rds"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : ["CreateDBInstance"]
    }
  })
}

resource "aws_cloudwatch_event_target" "rds_lambda" {
  rule      = aws_cloudwatch_event_rule.rds_createdb.name
  target_id = "SendRdsToLambda"
  arn       = aws_lambda_function.tag_enforcer.arn
}

resource "aws_lambda_permission" "allow_eventbridge_rds" {
  statement_id  = "AllowExecutionFromEventBridgeRds"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_enforcer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_createdb.arn
}

# S3 Rule
resource "aws_cloudwatch_event_rule" "s3_createbucket" {
  name        = "S3-CreateBucket-Rule"
  description = "Trigger Lambda on S3 bucket creation"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : ["CreateBucket"]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_createbucket.name
  target_id = "SendS3ToLambda"
  arn       = aws_lambda_function.tag_enforcer.arn
}

resource "aws_lambda_permission" "allow_eventbridge_s3" {
  statement_id  = "AllowExecutionFromEventBridgeS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_enforcer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_createbucket.arn
}

