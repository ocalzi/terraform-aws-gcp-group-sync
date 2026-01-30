
variable "access_key" {
  description = "AWS Access Key. Prefer using AWS_ACCESS_KEY_ID environment variable or IAM roles instead."
  type        = string
  default     = ""
  sensitive   = true
}

variable "secret_key" {
  description = "AWS Secret Key. Prefer using AWS_SECRET_ACCESS_KEY environment variable or IAM roles instead."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region where Identity Center is configured."
  type        = string
  default     = "eu-west-3"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format (e.g., us-east-1, eu-west-3)."
  }
}

# TODO: Reserved for future use — AWS account assignment or permission set resources.
# variable "aws_account_id" {
#   description = "The AWS Account ID where the IAM roles will be created."
#   type        = string
#   default     = ""
# }

# TODO: Reserved for future use — SAML-based federation configuration.
# variable "gcp_saml_idp_arn" {
#   description = "The ARN of the GCP SAML Identity Provider in AWS IAM."
#   type        = string
#   default     = ""
# }

# -----------------------------------------------------
# Group Mapping Variable
# -----------------------------------------------------
variable "group_mappings" {
  description = "A map defining the target GCP groups and their corresponding AWS Identity Center groups."
  type = map(object({
    # The full email address of the existing Google Workspace Group
    gcp_group_email = string
    # The display name of the AWS Identity Center group to be created
    aws_role_name = string
    # TODO: Reserved for future use — permission set assignment.
    # The AWS policy ARN to attach to the group's permission set
    aws_policy_arn = optional(string, "")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.group_mappings : can(regex("^[^@]+@[^@]+\\.[^@]+$", v.gcp_group_email))
    ])
    error_message = "Each gcp_group_email must be a valid email address format."
  }

  validation {
    condition = alltrue([
      for k, v in var.group_mappings : length(v.aws_role_name) > 0
    ])
    error_message = "Each aws_role_name must be a non-empty string."
  }
}
