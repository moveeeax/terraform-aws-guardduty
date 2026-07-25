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

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

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
