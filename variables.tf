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
