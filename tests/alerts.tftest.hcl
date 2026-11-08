# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
mock_provider "aws" {}

run "no_alerts_by_default" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_event_rule.alert) == 0 && length(aws_cloudwatch_event_target.alert) == 0
    error_message = "No EventBridge rule or target may be created unless alert_sns_topic_arn is set."
  }

  assert {
    condition     = output.alert_rule_arn == null
    error_message = "alert_rule_arn must be null when alerts are off."
  }
}

run "alerts_route_high_and_critical_findings_to_sns" {
  command = plan

  variables {
    alert_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.alert) == 1
    error_message = "Setting alert_sns_topic_arn must create one EventBridge rule."
  }

  assert {
    condition = jsondecode(aws_cloudwatch_event_rule.alert[0].event_pattern) == {
      source      = ["aws.guardduty"]
      detail-type = ["GuardDuty Finding"]
      detail      = { severity = [{ numeric = [">=", 7] }] }
    }
    error_message = "The rule must match GuardDuty findings with severity >= 7 by default."
  }

  assert {
    condition     = aws_cloudwatch_event_target.alert[0].arn == "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
    error_message = "The rule's target must be the SNS topic."
  }
}

run "alert_threshold_is_configurable" {
  command = plan

  variables {
    alert_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
    alert_min_severity  = 4
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.alert[0].event_pattern).detail.severity[0].numeric[1] == 4
    error_message = "alert_min_severity must set the numeric threshold in the event pattern."
  }
}

run "accepts_a_critical_only_threshold" {
  command = plan

  variables {
    alert_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
    alert_min_severity  = 9
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.alert[0].event_pattern).detail.severity[0].numeric[1] == 9
    error_message = "Critical findings run from 9.0 to 10.0, so a threshold of 9 must be accepted."
  }
}

run "rejects_severity_above_ten" {
  command = plan

  variables {
    alert_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
    alert_min_severity  = 11
  }

  expect_failures = [var.alert_min_severity]
}

run "rejects_severity_below_one" {
  command = plan

  variables {
    alert_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:guardduty-alerts"
    alert_min_severity  = 0
  }

  expect_failures = [var.alert_min_severity]
}

run "rejects_a_topic_name_instead_of_an_arn" {
  command = plan

  variables {
    alert_sns_topic_arn = "guardduty-alerts"
  }

  expect_failures = [var.alert_sns_topic_arn]
}
