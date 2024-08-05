terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.56.1"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "db_instance_id" {
   type    = set(string)
   default = ["rs19hda1vep", "rs19jir1evp", "rs19rpl1evp"]
   description = "The instance ID of the RDS database instance that you want to monitor."
}

resource "aws_sns_topic" "van_prod_sql_rds_sns_alerts" {
  name = "van-prod-sql-rds-sns-topic"
}

resource "aws_sns_topic_subscription" "cloudwatch_email_sub" {
  topic_arn = aws_sns_topic.van_prod_sql_rds_sns_alerts.arn
  protocol  = "email"
  endpoint  = "GLBL.CORP.SQLDBASupport@baxter.com"
}

resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  for_each                  = var.db_instance_id
  alarm_name                = "vanawsrds-${each.key}-High-CPUUtilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "600"
  statistic                 = "Average"
  threshold                 = "90"
  alarm_description         = "Alarm when CPU exceeds 90 percent"
  alarm_actions             = [aws_sns_topic.van_prod_sql_rds_sns_alerts.arn]
  insufficient_data_actions = []
  dimensions = {
    DBInstanceIdentifier = each.key
   }
}

resource "aws_cloudwatch_metric_alarm" "FreeStorageSpace" {
  for_each            = var.db_instance_id
  alarm_name          = "vanawsrds-${each.key}-FreeStorageSpace"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = 16106127360
  alarm_description   = "Alarm when free storage space is less than 15GB"
  alarm_actions       = [aws_sns_topic.van_prod_sql_rds_sns_alerts.arn]
  dimensions = {
    DBInstanceIdentifier = each.key
   }
}
