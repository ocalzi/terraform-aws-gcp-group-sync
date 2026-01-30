# -----------------------------------------------------
# Provider Variables (standalone only — not needed when using as module)
# -----------------------------------------------------

variable "aws_region" {
  description = "AWS region where Identity Center is configured."
  type        = string
  default     = "eu-west-3"
}

variable "google_workspace_customer_id" {
  description = "Your Google Workspace customer ID (e.g., C01234567)."
  type        = string
}

variable "google_workspace_admin_email" {
  description = "Email of a Google Workspace admin to impersonate for API calls."
  type        = string
}

# -----------------------------------------------------
# Module Variable (passed through to the module)
# -----------------------------------------------------

variable "group_mappings" {
  description = "A map defining the target GCP groups and their corresponding AWS Identity Center groups."
  type = map(object({
    gcp_group_email = string
    aws_role_name   = string
    aws_policy_arn  = optional(string, "")
  }))
  default = {}
}
