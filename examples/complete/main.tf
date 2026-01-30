# =============================================================================
# Complete Example: GCP to AWS Identity Center Group Sync
# =============================================================================
# This example shows how to consume the module from the Terraform Registry.
#
# Prerequisites:
#   1. AWS Identity Center enabled with SCIM sync from Google Workspace
#   2. Google Workspace service account with Domain-Wide Delegation
#   3. Environment variables or provider config for authentication
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

  # Optional: configure your backend
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "gcp-group-sync/terraform.tfstate"
  #   region = "eu-west-3"
  # }
}

# -----------------------------------------------------
# Provider Configuration (caller's responsibility)
# -----------------------------------------------------

provider "aws" {
  region = "eu-west-3"

  # Authentication: use any supported method
  # - Environment: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  # - Shared credentials file: ~/.aws/credentials
  # - IAM role (EC2, ECS, Lambda)
  # - SSO: aws sso login --profile my-profile

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "gcp-group-sync"
    }
  }
}

provider "googleworkspace" {
  customer_id             = "C01234567" # Your Google Workspace customer ID
  impersonated_user_email = "admin@yourdomain.com"

  # Authentication: use any supported method
  # - Environment: GOOGLEWORKSPACE_CREDENTIALS (path to JSON key)
  # - Inline: credentials = file("./service-account-key.json")

  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
  ]
}

# -----------------------------------------------------
# Module Usage
# -----------------------------------------------------

module "gcp_group_sync" {
  source  = "ocalzi/gcp-group-sync/aws"
  version = "~> 1.0"

  group_mappings = {
    admins = {
      gcp_group_email = "admins@yourdomain.com"
      aws_role_name   = "GCP-Admin-Role"
    }
    developers = {
      gcp_group_email = "developers@yourdomain.com"
      aws_role_name   = "GCP-Developer-Role"
    }
    readonly = {
      gcp_group_email = "readonly@yourdomain.com"
      aws_role_name   = "GCP-ReadOnly-Role"
    }
  }
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
