variable "enable" {
  description = "Whether the GuardDuty detector is enabled. When false, no protection plans are managed."
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "Frequency at which detector findings are exported to configured targets (EventBridge, S3). Ignored for the first occurrence of a finding, which is always published immediately."
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_s3_protection" {
  description = "Whether to enable S3 data event monitoring (S3_DATA_EVENTS)."
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Whether to enable EKS audit log monitoring (EKS_AUDIT_LOGS)."
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Whether to enable EBS malware protection for EC2 instances (EBS_MALWARE_PROTECTION)."
  type        = bool
  default     = false
}

variable "enable_rds_protection" {
  description = "Whether to enable RDS login activity monitoring (RDS_LOGIN_EVENTS). Defaults to true, matching what GuardDuty turns on for a new detector."
  type        = bool
  default     = true
}

variable "enable_lambda_protection" {
  description = "Whether to enable Lambda network activity monitoring (LAMBDA_NETWORK_LOGS). Defaults to true, matching what GuardDuty turns on for a new detector."
  type        = bool
  default     = true
}

variable "findings_export" {
  description = "Export findings to an existing S3 bucket, encrypted with an existing KMS key in the same region. bucket_arn may include a prefix (arn:aws:s3:::bucket/prefix) that already exists in the bucket. Both the bucket policy and the key policy must allow GuardDuty; see README. null disables the export."
  type = object({
    bucket_arn  = string
    kms_key_arn = string
  })
  default = null

  validation {
    condition     = var.findings_export == null ? true : can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9](/.*)?$", var.findings_export.bucket_arn))
    error_message = "findings_export.bucket_arn must be an S3 bucket ARN, optionally with a prefix: arn:aws:s3:::bucket or arn:aws:s3:::bucket/prefix."
  }

  validation {
    condition     = var.findings_export == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:.+$", var.findings_export.kms_key_arn))
    error_message = "findings_export.kms_key_arn must be a KMS key ARN (arn:aws:kms:<region>:<account>:key/<id>), not a bare key ID."
  }
}

variable "tags" {
  description = "Tags applied to the detector."
  type        = map(string)
  default     = {}
}
