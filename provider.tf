## 📂 provider.tf

# -----------------------------------------------------
# Providers Configuration
# -----------------------------------------------------
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # TODO: Reserved for future use — GCP project-level resources.
    # google = {
    #   source  = "hashicorp/google"
    #   version = "~> 5.0"
    # }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = "~> 0.7"
    }
  }

  # GitLab-managed Terraform state backend
  backend "http" {
  }
}

# -----------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Module    = "gcp-to-aws-group-sync"
    }
  }
}

# -----------------------------------------------------
# Google Workspace Provider Configuration
# -----------------------------------------------------
# This provider must be authenticated using a Service Account with Domain-Wide Delegation (DWD).
# The service account needs the 'Admin SDK' scopes (e.g., https://www.googleapis.com/auth/admin.directory.group.readonly)
#
# Required configuration (set via environment or tfvars):
#   - customer_id:             Your Google Workspace customer ID
#   - impersonated_user_email: Email of a Workspace admin to impersonate
#   - credentials:             Path to service account JSON key (or set GOOGLEWORKSPACE_CREDENTIALS env var)
provider "googleworkspace" {
  # customer_id             = "YOUR_CUSTOMER_ID"
  # impersonated_user_email = "admin@yourdomain.com"
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
  ]
}

