# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `findings_export` exports findings to an existing S3 bucket, encrypted with an
  existing KMS key, through `aws_guardduty_publishing_destination`. Off by
  default. Output `publishing_destination_id`. The README lists the bucket and
  key policy statements GuardDuty needs; the module creates neither.
- `alert_sns_topic_arn` and `alert_min_severity` (default `7`) add an
  EventBridge rule that forwards GuardDuty findings at or above the threshold to
  an SNS topic. Off by default. Output `alert_rule_arn`.

## [1.1.0] - 2026-11-05

### Fixed

- Require aws provider `>= 5.20.0`, the first release with
  `aws_guardduty_detector_feature`.

### Changed

- CI: current action majors, pinned OpenTofu, Dependabot.
- Tests: lifecycle suite for toggling protection plans and the detector.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-aws-guardduty/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-aws-guardduty/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-aws-guardduty/releases/tag/v1.0.0
