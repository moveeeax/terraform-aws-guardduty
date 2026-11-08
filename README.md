# terraform-aws-guardduty

Terraform module that manages an [Amazon
GuardDuty](https://aws.amazon.com/guardduty/) detector. It enables threat
detection for the account in the current region and toggles the protection
plans — S3 data events, EKS audit logs, EBS malware protection, RDS login
events and Lambda network logs — through simple boolean inputs.

Protection plans are managed with `aws_guardduty_detector_feature` resources.
The `datasources` block on `aws_guardduty_detector` is deprecated by the AWS
provider and cannot express RDS or Lambda protection at all.

## Usage

```hcl
module "guardduty" {
  source = "github.com/moveeeax/terraform-aws-guardduty"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_protection         = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

GuardDuty allows exactly one detector per account per region. If the account
already has one, import it before applying:

```sh
terraform import 'module.guardduty.aws_guardduty_detector.this' <detector-id>
```

## Exporting findings to S3

GuardDuty keeps findings for 90 days. For longer retention or SIEM ingestion,
set `findings_export` and the module creates an
`aws_guardduty_publishing_destination` of type `S3`. It is off by default
because it needs a bucket and a KMS key that the module does not create:

```hcl
module "guardduty" {
  source = "github.com/moveeeax/terraform-aws-guardduty"

  findings_export = {
    bucket_arn  = aws_s3_bucket.findings.arn # or "<bucket arn>/<prefix>"
    kms_key_arn = aws_kms_key.findings.arn
  }

  # GuardDuty needs the policies below before it can write.
  depends_on = [aws_s3_bucket_policy.findings, aws_kms_key.findings]
}
```

The bucket and the key must be in the same region. A prefix in `bucket_arn`
must already exist in the bucket; GuardDuty does not create folders.

Policy statements, adapted from the AWS guide
[Exporting generated GuardDuty findings to Amazon S3 buckets](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_exportfindings.html).
They scope `aws:SourceArn` to any detector in the account instead of the exact
detector ID, so the policies do not depend on the module and the `depends_on`
above does not create a cycle; the same pair can then serve detectors in other
regions too. The guide's two encryption deny statements are folded into one
here, and its non-HTTPS deny is left to your own bucket baseline:

```hcl
data "aws_caller_identity" "current" {}

locals {
  guardduty_source = {
    account = data.aws_caller_identity.current.account_id
    arn     = "arn:aws:guardduty:*:${data.aws_caller_identity.current.account_id}:detector/*"
  }
}

# Bucket policy
data "aws_iam_policy_document" "findings_bucket" {
  statement {
    sid       = "AllowGuardDutyGetBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.findings.arn]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.guardduty_source.account]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.guardduty_source.arn]
    }
  }

  statement {
    sid       = "AllowGuardDutyPutObject"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.findings.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.guardduty_source.account]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.guardduty_source.arn]
    }
  }

  statement {
    sid       = "DenyGuardDutyUploadsWithoutTheKey"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.findings.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.findings.arn]
    }
  }
}

# Key policy statement (add to the key's existing policy)
#   principal: Service guardduty.amazonaws.com
#   action:    kms:GenerateDataKey
#   resource:  the key ARN
#   conditions: the same aws:SourceAccount and aws:SourceArn as above
```

In an opt-in region the AWS guide uses the regional service principal
(for example `guardduty.me-south-1.amazonaws.com`) instead of
`guardduty.amazonaws.com`.

## Notes

- **Destroying this module deletes GuardDuty findings.** Per the AWS
  provider, deleting `aws_guardduty_detector` is equivalent to disabling
  GuardDuty for the region, which removes all existing findings. To pause
  monitoring without losing history, set `enable = false` instead of
  removing the module.
- **Member accounts:** `finding_publishing_frequency` only takes effect on
  standalone or GuardDuty administrator accounts. On a member account the
  value is controlled by the delegated administrator and any value set here
  is ignored by AWS, which will show up as permanent drift. This module does
  not attempt to detect or special-case member accounts.

## Requirements

| Name      | Version    |
|-----------|------------|
| terraform | >= 1.5     |
| aws       | >= 5.20.0  |

`aws_guardduty_detector_feature`, which this module uses to manage every
protection plan, was added in provider version 5.20.0. On an older 5.x
provider the module passes `validate` but fails at `apply` with an "Invalid
resource type" error.

Running the test suite (`terraform test`) additionally requires Terraform or
OpenTofu >= 1.7 for `mock_provider`. The module itself does not.

## Inputs

| Name                           | Description                                              | Type          | Default              | Required |
|--------------------------------|----------------------------------------------------------|---------------|----------------------|:--------:|
| `enable`                       | Whether the detector is enabled. When false, no protection plans are managed. | `bool`        | `true`               |    no    |
| `finding_publishing_frequency` | How often findings are exported. One of `FIFTEEN_MINUTES`, `ONE_HOUR`, `SIX_HOURS`. | `string`      | `"FIFTEEN_MINUTES"`  |    no    |
| `enable_s3_protection`         | Enable S3 data event monitoring (`S3_DATA_EVENTS`).      | `bool`        | `true`               |    no    |
| `enable_kubernetes_protection` | Enable EKS audit log monitoring (`EKS_AUDIT_LOGS`).      | `bool`        | `false`              |    no    |
| `enable_malware_protection`    | Enable EBS malware protection (`EBS_MALWARE_PROTECTION`).| `bool`        | `false`              |    no    |
| `enable_rds_protection`        | Enable RDS login activity monitoring (`RDS_LOGIN_EVENTS`).| `bool`       | `true`               |    no    |
| `enable_lambda_protection`     | Enable Lambda network activity monitoring (`LAMBDA_NETWORK_LOGS`). | `bool` | `true`               |    no    |
| `findings_export`              | Export findings to an existing S3 bucket (`bucket_arn`, optionally with `/prefix`) encrypted with an existing KMS key (`kms_key_arn`). `null` disables the export. | `object({...})` | `null` |    no    |
| `tags`                         | Tags applied to the detector.                            | `map(string)` | `{}`                 |    no    |

The RDS and Lambda defaults match what GuardDuty turns on for a newly created
detector, so adopting this module does not silently switch them off.

## Outputs

| Name         | Description                                                             |
|--------------|-------------------------------------------------------------------------|
| `id`         | ID of the GuardDuty detector.                                            |
| `arn`        | ARN of the GuardDuty detector.                                           |
| `account_id` | AWS account ID that owns the detector.                                   |
| `features`   | Map of managed protection plan names to `ENABLED` / `DISABLED`. Empty when the detector is disabled. |
| `publishing_destination_id` | Terraform ID of the S3 publishing destination, or `null` when `findings_export` is not set. |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

`terraform test` uses a mocked AWS provider, so it needs no credentials and
makes no API calls.

## License

[MIT](LICENSE)
