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
