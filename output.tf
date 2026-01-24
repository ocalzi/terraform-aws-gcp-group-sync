## 📂 outputs.tf

# -----------------------------------------------------
# AWS Outputs
# -----------------------------------------------------


# -----------------------------------------------------
# GCP Group Details Output
# -----------------------------------------------------

output "gcp_groups_details" {
  description = "Details fetched from Google Workspace for the  groups, confirming lookup success."
  value = {
    for name, group in data.googleworkspace_group.gcp_groups : name => {
      # The ID is the unique Group ID, useful for other API calls
      group_id = group.id
      # The email is the primary email (e.g., core@alouette.ai)
      email = group.email
      # The display name
      display_name = group.name
      # The group description
      description = group.description
      # The number of direct members (users, not nested groups)
      direct_members_count = group.direct_members_count
    }
  }
}