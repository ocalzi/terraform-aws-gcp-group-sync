
variable "access_key" {
  description = "AWS Access Key"
  type        = string
  default     = ""
}

variable "secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = ""

}

variable "aws_region" {
  description = "defaul aws region"
  type        = string
  default     = "eu-west-3"
}

variable "aws_account_id" {
  description = "The AWS Account ID where the IAM roles will be created."
  type        = string
  default     = ""
}

variable "gcp_saml_idp_arn" {
  description = "The ARN of the GCP SAML Identity Provider in AWS IAM."
  type        = string
  default     = ""
}

# -----------------------------------------------------
# Group Mapping Variable
# -----------------------------------------------------
variable "group_mappings" {
  description = "A map defining the target GCP groups and their corresponding AWS roles/policies."
  type = map(object({
    # The full email address of the existing Google Workspace Group
    gcp_group_email = string
    # The name of the AWS IAM Role to be created
    aws_role_name = string
    # The AWS policy ARN to attach to the role
    aws_policy_arn = string
  }))
  default = {
    # Example group mapping - replace with your actual groups
    # example_group = {
    #   gcp_group_email = "example-group@example.com"
    #   aws_role_name   = "GCP-Example-Role"
    #   aws_policy_arn  = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    # }
  }
}
