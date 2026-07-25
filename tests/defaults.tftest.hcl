# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports the required_version declared in versions.tf.
mock_provider "aws" {}

run "detector_is_enabled_by_default" {
  assert {
    condition     = aws_guardduty_detector.this.enable == true
    error_message = "The detector must be enabled by default; a threat-detection module that ships disabled does nothing."
  }
}

run "findings_are_published_promptly_by_default" {
  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "Default finding_publishing_frequency must be FIFTEEN_MINUTES so findings reach EventBridge/S3 without a multi-hour delay."
  }
}

run "default_protection_plans" {
  assert {
    condition     = aws_guardduty_detector_feature.this["S3_DATA_EVENTS"].status == "ENABLED"
    error_message = "S3 data event monitoring must be enabled by default."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["RDS_LOGIN_EVENTS"].status == "ENABLED"
    error_message = "RDS login event monitoring must be enabled by default; GuardDuty enables it for new detectors and turning it off would be a silent regression."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["LAMBDA_NETWORK_LOGS"].status == "ENABLED"
    error_message = "Lambda network log monitoring must be enabled by default; GuardDuty enables it for new detectors."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EKS_AUDIT_LOGS"].status == "DISABLED"
    error_message = "EKS audit logs default to off and must stay off unless requested."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EBS_MALWARE_PROTECTION"].status == "DISABLED"
    error_message = "EBS malware protection defaults to off and must stay off unless requested."
  }
}

run "every_protection_plan_can_be_turned_on" {
  variables {
    enable_s3_protection         = true
    enable_kubernetes_protection = true
    enable_malware_protection    = true
    enable_rds_protection        = true
    enable_lambda_protection     = true
  }

  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 5
    error_message = "All five protection plans should be managed."
  }

  assert {
    condition = alltrue([
      for feature in aws_guardduty_detector_feature.this : feature.status == "ENABLED"
    ])
    error_message = "Every protection plan should be ENABLED when all toggles are true."
  }
}

run "no_features_are_managed_when_detector_is_disabled" {
  variables {
    enable = false
  }

  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 0
    error_message = "Protection plans must not be configured on a suspended detector; the GuardDuty API rejects the call."
  }
}
