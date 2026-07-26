terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # aws_guardduty_detector_feature was introduced in provider 5.20.0;
      # on an earlier 5.x release this module fails at apply time with
      # "Invalid resource type", not at init/validate time.
      version = ">= 5.20.0"
    }
  }
}
