output "id" {
  description = "ID of the GuardDuty detector."
  value       = aws_guardduty_detector.this.id
}

output "arn" {
  description = "ARN of the GuardDuty detector."
  value       = aws_guardduty_detector.this.arn
}

output "account_id" {
  description = "AWS account ID that owns the detector."
  value       = aws_guardduty_detector.this.account_id
}

output "features" {
  description = "Map of managed GuardDuty protection plan names to their status (ENABLED or DISABLED). Empty when the detector is disabled."
  value       = { for name, feature in aws_guardduty_detector_feature.this : name => feature.status }
}

output "publishing_destination_id" {
  description = "Terraform ID of the S3 publishing destination when findings_export is set, otherwise null."
  value       = try(aws_guardduty_publishing_destination.this[0].id, null)
}

output "alert_rule_arn" {
  description = "ARN of the EventBridge rule that forwards findings to alert_sns_topic_arn, otherwise null."
  value       = try(aws_cloudwatch_event_rule.alert[0].arn, null)
}
