# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
#
# Unlike defaults.tftest.hcl, which checks single snapshots of state, the runs
# below share state within this file and apply in sequence. That exercises
# real update-in-place and destroy/recreate transitions, not just isolated
# plans.
mock_provider "aws" {}

run "mixed_selection_is_applied" {
  variables {
    enable                       = true
    enable_s3_protection         = true
    enable_kubernetes_protection = true
    enable_malware_protection    = false
    enable_rds_protection        = true
    enable_lambda_protection     = false
  }

  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 5
    error_message = "All five protection plans must be managed once the detector is enabled, regardless of which are turned on."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EKS_AUDIT_LOGS"].status == "ENABLED"
    error_message = "EKS audit logs should be ENABLED for this mixed selection."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EBS_MALWARE_PROTECTION"].status == "DISABLED"
    error_message = "EBS malware protection should be DISABLED for this mixed selection."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["LAMBDA_NETWORK_LOGS"].status == "DISABLED"
    error_message = "Lambda network logs should be DISABLED for this mixed selection."
  }
}

run "flipping_one_feature_leaves_the_others_untouched" {
  variables {
    enable                       = true
    enable_s3_protection         = true
    enable_kubernetes_protection = false # flipped off from the previous run
    enable_malware_protection    = false
    enable_rds_protection        = true
    enable_lambda_protection     = false
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EKS_AUDIT_LOGS"].status == "DISABLED"
    error_message = "EKS audit logs should have been updated in place to DISABLED."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["S3_DATA_EVENTS"].status == "ENABLED"
    error_message = "S3 data events was untouched by this change and must remain ENABLED."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["RDS_LOGIN_EVENTS"].status == "ENABLED"
    error_message = "RDS login events was untouched by this change and must remain ENABLED."
  }
}

run "disabling_the_detector_removes_every_managed_feature" {
  variables {
    enable                       = false
    enable_s3_protection         = true
    enable_kubernetes_protection = false
    enable_malware_protection    = false
    enable_rds_protection        = true
    enable_lambda_protection     = false
  }

  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 0
    error_message = "No protection plans should be managed once the detector is suspended."
  }

  assert {
    condition     = aws_guardduty_detector.this.enable == false
    error_message = "The detector itself must reflect the suspended state."
  }
}

run "re_enabling_recreates_features_from_current_variables" {
  variables {
    enable                       = true
    enable_s3_protection         = true
    enable_kubernetes_protection = false
    enable_malware_protection    = true # changed while the detector was suspended
    enable_rds_protection        = true
    enable_lambda_protection     = false
  }

  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 5
    error_message = "Re-enabling the detector must recreate all five managed protection plans."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EBS_MALWARE_PROTECTION"].status == "ENABLED"
    error_message = "The feature set must reflect the variable values current at re-enable time, not whatever was set before the detector was suspended."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EKS_AUDIT_LOGS"].status == "DISABLED"
    error_message = "EKS audit logs should stay DISABLED across the suspend/resume cycle."
  }
}
