# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
mock_provider "aws" {}

run "rejects_misspelled_publishing_frequency" {
  command = plan

  variables {
    # A plausible typo: the API value is FIFTEEN_MINUTES, not 15_MINUTES.
    finding_publishing_frequency = "15_MINUTES"
  }

  expect_failures = [var.finding_publishing_frequency]
}

run "rejects_lowercase_publishing_frequency" {
  command = plan

  variables {
    finding_publishing_frequency = "six_hours"
  }

  expect_failures = [var.finding_publishing_frequency]
}

run "accepts_every_documented_publishing_frequency" {
  command = plan

  variables {
    finding_publishing_frequency = "ONE_HOUR"
  }

  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "ONE_HOUR"
    error_message = "ONE_HOUR is a valid GuardDuty publishing frequency and must be accepted."
  }
}
