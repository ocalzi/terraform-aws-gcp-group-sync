# -----------------------------------------------------
# Terraform and Provider Version Constraints
# -----------------------------------------------------
# This module requires the caller to configure both
# the AWS and Google Workspace providers.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = "~> 0.7"
    }
  }
}
