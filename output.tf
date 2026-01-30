## 📂 outputs.tf

# -----------------------------------------------------
# GCP Group Details Output
# -----------------------------------------------------

output "gcp_groups_details" {
  description = "Details fetched from Google Workspace for the configured groups, confirming lookup success."
  value = {
    for name, group in data.googleworkspace_group.gcp_groups : name => {
      group_id             = group.id
      email                = group.email
      display_name         = group.name
      description          = group.description
      direct_members_count = group.direct_members_count
    }
  }
}

# -----------------------------------------------------
# AWS Identity Center Group Details Output
# -----------------------------------------------------

output "aws_identity_center_groups" {
  description = "AWS Identity Center groups created by this module."
  value = {
    for name, group in aws_identitystore_group.identity_center_groups : name => {
      group_id     = group.group_id
      display_name = group.display_name
      description  = group.description
    }
  }
}

# -----------------------------------------------------
# Sync Summary Output
# -----------------------------------------------------

output "sync_summary" {
  description = "Summary of the synchronization: group count, total memberships, and identity store ID."
  value = {
    identity_store_id   = local.identity_store_id
    groups_synced       = length(aws_identitystore_group.identity_center_groups)
    memberships_created = length(aws_identitystore_group_membership.synced_memberships)
    active_users_found  = length(local.active_user_map)
  }
}
