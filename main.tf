locals {
  # Protection plans, keyed by the feature name the GuardDuty API expects.
  # Booleans are mapped to ENABLED/DISABLED here so a caller can never pass a
  # misspelled status string through to the API.
  detector_features = {
    S3_DATA_EVENTS         = var.enable_s3_protection
    EKS_AUDIT_LOGS         = var.enable_kubernetes_protection
    EBS_MALWARE_PROTECTION = var.enable_malware_protection
    RDS_LOGIN_EVENTS       = var.enable_rds_protection
    LAMBDA_NETWORK_LOGS    = var.enable_lambda_protection
  }

  # Features cannot be configured on a suspended detector; the API rejects the
  # UpdateDetector call. Skip them entirely when the detector is turned off.
  #
  # Removing entries here makes Terraform destroy the corresponding
  # aws_guardduty_detector_feature resources. The AWS provider does not call
  # any API to disable a feature on destroy (it is state-only removal), so
  # this relies on aws_guardduty_detector.enable = false already suspending
  # all monitoring regardless of per-feature status. Re-enabling recreates
  # the feature resources from the then-current variable values.
  enabled_detector_features = var.enable ? local.detector_features : {}
}

resource "aws_guardduty_detector" "this" {
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

resource "aws_guardduty_detector_feature" "this" {
  for_each = local.enabled_detector_features

  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  status      = each.value ? "ENABLED" : "DISABLED"
}

# Long-term retention: GuardDuty keeps findings for 90 days only. The bucket
# and KMS key are the caller's, and their policies must allow GuardDuty
# (see README); the module does not create or change either.
resource "aws_guardduty_publishing_destination" "this" {
  count = var.findings_export == null ? 0 : 1

  detector_id      = aws_guardduty_detector.this.id
  destination_type = "S3"
  destination_arn  = var.findings_export.bucket_arn
  kms_key_arn      = var.findings_export.kms_key_arn
}

# Findings go to EventBridge on the default bus whether or not anything listens.
# This rule forwards those at or above alert_min_severity to an SNS topic. The
# topic policy must let events.amazonaws.com publish (see README).
resource "aws_cloudwatch_event_rule" "alert" {
  count = var.alert_sns_topic_arn == null ? 0 : 1

  name_prefix = "guardduty-findings-"
  description = "GuardDuty findings with severity >= ${var.alert_min_severity}"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.alert_min_severity] }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "alert" {
  count = var.alert_sns_topic_arn == null ? 0 : 1

  rule = aws_cloudwatch_event_rule.alert[0].name
  arn  = var.alert_sns_topic_arn
}
