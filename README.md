# terraform-aws-guardduty

Terraform module that manages an [Amazon
GuardDuty](https://aws.amazon.com/guardduty/) detector. It enables threat
detection for the account in the current region and toggles the S3, EKS and
malware protection data sources through simple boolean inputs.

## Usage

```hcl
module "guardduty" {
  source = "github.com/moveeeax/terraform-aws-guardduty"

  enable               = true
  enable_s3_protection = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

## Inputs

| Name                           | Description                                             | Type          | Default        | Required |
|--------------------------------|---------------------------------------------------------|---------------|----------------|:--------:|
| `enable`                       | Whether the detector is enabled.                        | `bool`        | `true`         |    no    |
| `finding_publishing_frequency` | Frequency findings are exported.                        | `string`      | `"SIX_HOURS"`  |    no    |
| `enable_s3_protection`         | Enable S3 data event monitoring.                        | `bool`        | `true`         |    no    |
| `enable_kubernetes_protection` | Enable EKS audit log monitoring.                        | `bool`        | `false`        |    no    |
| `enable_malware_protection`    | Enable EBS malware protection.                          | `bool`        | `false`        |    no    |
| `tags`                         | Tags applied to the detector.                           | `map(string)` | `{}`           |    no    |

## Outputs

| Name         | Description                                        |
|--------------|----------------------------------------------------|
| `id`         | ID of the GuardDuty detector.                      |
| `arn`        | ARN of the GuardDuty detector.                     |
| `account_id` | AWS account ID that owns the detector.             |

## License

[MIT](LICENSE)
