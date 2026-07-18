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
