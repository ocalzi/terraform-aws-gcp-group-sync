## 📂 provider.tf

# -----------------------------------------------------
# Providers Configuration
# -----------------------------------------------------
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
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
}

# -----------------------------------------------------
# Google Workspace Provider Configuration
# -----------------------------------------------------
# This provider must be authenticated using a Service Account with Domain-Wide Delegation (DWD).
# The service account needs the 'Admin SDK' scopes (e.g., https://www.googleapis.com/auth/admin.directory.group.readonly)
provider "googleworkspace" {
  # Configuration details (like impersonated_user and credentials file) 
  # are omitted here but required for execution.
  customer_id             = "YOUR_CUSTOMER_ID" # Replace with your actual customer ID
  # For local testing, you can specify the path to your service account key file
  #credentials             = file("./path-to-your-service-account-key.json")
  impersonated_user_email = "admin@yourdomain.com"
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly"
    # include scopes as needed
  ]
}

