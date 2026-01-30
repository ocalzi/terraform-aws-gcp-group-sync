# =============================================================================
# Standalone Usage: GCP to AWS Identity Center Group Sync
# =============================================================================
# This example shows how to use the Terraform code directly as a standalone
# project (clone and run) — without consuming it as a remote module.
#
# This is the original usage pattern before the project was published to the
# Terraform Registry. It is ideal for:
#   - Teams who want to fork and customise the code
#   - GitLab CI/CD scheduled pipelines for continuous sync
#   - Environments where consuming remote modules is restricted
#
# Prerequisites:
#   1. AWS Identity Center enabled with SCIM sync from Google Workspace
#   2. Google Workspace service account with Domain-Wide Delegation
#   3. Credentials configured via environment variables or provider config
# =============================================================================

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

  # GitLab-managed Terraform state backend
  # For other backends, replace with your preferred backend configuration.
  backend "http" {
  }
}

# -----------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------
# Authentication options (choose one):
#   - Environment variables: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#   - Shared credentials file: ~/.aws/credentials
#   - IAM role (EC2, ECS, Lambda)
#   - SSO: aws sso login --profile my-profile
#   - CI/CD: set TF_VAR_access_key and TF_VAR_secret_key as pipeline variables

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "gcp-to-aws-group-sync"
    }
  }
}

# -----------------------------------------------------
# Google Workspace Provider Configuration
# -----------------------------------------------------
# This provider must be authenticated using a Service Account with
# Domain-Wide Delegation (DWD).
#
# Authentication options:
#   - Environment variable: GOOGLEWORKSPACE_CREDENTIALS (path to JSON key)
#   - Inline: credentials = file("./service-account-key.json")
#   - CI/CD: decode base64 key in before_script (see .gitlab-ci.yml)

provider "googleworkspace" {
  customer_id             = var.google_workspace_customer_id
  impersonated_user_email = var.google_workspace_admin_email

  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
  ]
}

# -----------------------------------------------------
# Module Source (local path to root)
# -----------------------------------------------------
# Points to the root of the repository where the module code lives.

module "gcp_group_sync" {
  source = "../../"

  group_mappings = var.group_mappings
}

# -----------------------------------------------------
# Outputs
# -----------------------------------------------------

output "sync_summary" {
  description = "Summary of the group synchronization"
  value       = module.gcp_group_sync.sync_summary
}

output "aws_groups" {
  description = "AWS Identity Center groups created"
  value       = module.gcp_group_sync.aws_identity_center_groups
}

output "gcp_groups" {
  description = "Google Workspace groups that were synced"
  value       = module.gcp_group_sync.gcp_groups_details
}
