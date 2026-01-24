## 📂 main.tf

# -----------------------------------------------------
# 1. Look up Existing Google Workspace Groups
# -----------------------------------------------------

# Iterate over the group_mappings variable to fetch details for each group.
data "googleworkspace_group" "gcp_groups" {
  for_each = var.group_mappings
  email    = each.value.gcp_group_email
}

# -----------------------------------------------------
# 1. AWS Identity Center Configuration (Data Lookup)
# -----------------------------------------------------

# Get the Identity Store ID for your AWS Organization/Region.
data "aws_ssoadmin_instances" "current" {}

locals {
  # Assuming you only have one Identity Center instance per region/account
  identity_store_id = data.aws_ssoadmin_instances.current.identity_store_ids[0]
}

# -----------------------------------------------------
# 2. Iterate and Create IAM Identity Center Groups
# -----------------------------------------------------

resource "aws_identitystore_group" "identity_center_groups" {
  for_each = var.group_mappings

  # The display name of the group in Identity Center
  display_name = each.value.aws_role_name # Reusing the role name variable for clarity

  # The unique ID of the Identity Center instance
  identity_store_id = local.identity_store_id

  description = "Group for federated access from GCP: ${each.value.gcp_group_email}"
}

# -----------------------------------------------------
# 3. Attach Permission Sets (Instead of Policy Attachments)
# -----------------------------------------------------
# NOTE: Permissions are granted by creating Permission Sets and 
# assigning them to the groups. This step is complex and usually requires 
# existing Permission Sets.

/*
resource "aws_ssoadmin_account_assignment" "group_assignments" {
  for_each = aws_identitystore_group.identity_center_groups
  
  # Assuming you have a Permission Set ARN defined in your variables:
  permission_set_arn = var.permission_set_arns[each.key]
  
  principal_id       = each.value.group_id
  principal_type     = "GROUP"
  target_id          = var.aws_account_id # The account ID to assign permissions to
  instance_arn       = data.aws_ssoadmin_instances.current.arns[0]
}
*/