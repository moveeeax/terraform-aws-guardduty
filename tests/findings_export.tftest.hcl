# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
mock_provider "aws" {}

run "no_export_by_default" {
  command = plan

  assert {
    condition     = length(aws_guardduty_publishing_destination.this) == 0
    error_message = "Findings export must stay off unless findings_export is set; it needs a bucket and key policy the module does not create."
  }

  assert {
    condition     = output.publishing_destination_id == null
    error_message = "publishing_destination_id must be null when no export is configured."
  }
}

run "export_to_s3_when_configured" {
  command = plan

  variables {
    findings_export = {
      bucket_arn  = "arn:aws:s3:::example-guardduty-findings/guardduty"
      kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
    }
  }

  assert {
    condition     = length(aws_guardduty_publishing_destination.this) == 1
    error_message = "Setting findings_export must create one publishing destination."
  }

  assert {
    condition     = aws_guardduty_publishing_destination.this[0].destination_type == "S3"
    error_message = "The publishing destination must be of type S3."
  }

  assert {
    condition     = aws_guardduty_publishing_destination.this[0].destination_arn == "arn:aws:s3:::example-guardduty-findings/guardduty"
    error_message = "bucket_arn, including its prefix, must be passed through as destination_arn."
  }

  assert {
    condition     = aws_guardduty_publishing_destination.this[0].kms_key_arn == "arn:aws:kms:us-east-1:111122223333:key/a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
    error_message = "kms_key_arn must be passed through to the publishing destination."
  }
}

run "rejects_a_bucket_name_instead_of_an_arn" {
  command = plan

  variables {
    findings_export = {
      bucket_arn  = "example-guardduty-findings"
      kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
    }
  }

  expect_failures = [var.findings_export]
}

run "rejects_a_bare_kms_key_id" {
  command = plan

  variables {
    findings_export = {
      bucket_arn  = "arn:aws:s3:::example-guardduty-findings"
      kms_key_arn = "a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
    }
  }

  expect_failures = [var.findings_export]
}
