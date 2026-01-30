# -----------------------------------------------------
# Test Helper Module - Provides mock input values
# -----------------------------------------------------
# This module generates realistic test fixtures for
# use in terraform test (.tftest.hcl) files.

variable "test_group_mappings" {
  description = "Override group mappings for testing"
  type = map(object({
    gcp_group_email = string
    aws_role_name   = string
    aws_policy_arn  = string
  }))
  default = {
    test_admins = {
      gcp_group_email = "admins@test.example.com"
      aws_role_name   = "GCP-Admin-Role"
      aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
    test_developers = {
      gcp_group_email = "devs@test.example.com"
      aws_role_name   = "GCP-Developer-Role"
      aws_policy_arn  = "arn:aws:iam::aws:policy/PowerUserAccess"
    }
    test_readonly = {
      gcp_group_email = "readonly@test.example.com"
      aws_role_name   = "GCP-ReadOnly-Role"
      aws_policy_arn  = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
  }
}

output "group_mappings" {
  value = var.test_group_mappings
}
