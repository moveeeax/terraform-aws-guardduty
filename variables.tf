variable "enable" {
  description = "Whether the GuardDuty detector is enabled."
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "Frequency at which detector findings are exported to configured targets."
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_s3_protection" {
  description = "Whether to enable S3 data event monitoring."
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Whether to enable EKS audit log monitoring."
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Whether to enable EBS malware protection for EC2 instances."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the detector."
  type        = map(string)
  default     = {}
}
