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
