## 📂 membership.tf

# -----------------------------------------------------
# 1. Look up Existing GCP Group Memberships
# -----------------------------------------------------

# Data source to retrieve all members (emails) from the target GCP groups.
data "googleworkspace_group_members" "gcp_group_members" {
  for_each = data.googleworkspace_group.gcp_groups # Assumes this data source exists in main.tf
  group_id = each.value.id
}

# --------------------------------------------------------------------------
# 2. LOCAL: Extract All Memberships and Unique Emails
# --------------------------------------------------------------------------

locals {
  # List of all membership entries (includes inactive users for now)
  all_memberships = flatten([
    for group_key, group_data in data.googleworkspace_group_members.gcp_group_members : [
      for m in group_data.members : {
        key        = "${m.email}:${group_key}"
        user_email = m.email
        # The target Identity Center Group ID from the aws_identitystore_group resource
        target_group_id = aws_identitystore_group.identity_center_groups[group_key].group_id
      }
    ]
  ])

  # Set of all UNIQUE member emails (active and inactive) for GCP status lookup
  unique_user_emails_raw = distinct([
    for m in local.all_memberships : m.user_email
  ])

}

# -----------------------------------------------------
# 3. GCP Data Lookup: Check User Status (Active/Suspended)
# -----------------------------------------------------

# Look up the full user object for every unique member email in Google Workspace.
data "googleworkspace_user" "gcp_users" {
  for_each      = toset(local.unique_user_emails_raw)
  primary_email = each.value
}

# -----------------------------------------------------
# 4. LOCAL: Filter for Active Users Only
# -----------------------------------------------------

locals {
  # Map of only ACTIVE users: { "email": "GCP User ID" }
  active_user_map = {
    for email, user in data.googleworkspace_user.gcp_users : email => user.id
    # SCIM typically only syncs users if 'suspended' is false (i.e., status is 'ACTIVE')
    if user.suspended == false
  }

  # Filter the original membership list to only include ACTIVE users.
  # Keyed by composite "email:group" for stable for_each iteration.
  active_memberships_to_sync = {
    for v in local.all_memberships : v.key => v
    if contains(keys(local.active_user_map), v.user_email)
  }
}

# -----------------------------------------------------
# 5. AWS Data Lookup: Find Corresponding Identity Center User IDs
# -----------------------------------------------------

# Only look up users who are confirmed ACTIVE in GCP. This avoids the lookup error for inactive users.
# The `for_each` is driven by the filtered active user map.
data "aws_identitystore_user" "synced_users" {
  for_each = local.active_user_map

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.key
  }
}

# -----------------------------------------------------
# 6. Resource Creation: Create Group Memberships in Identity Center
# -----------------------------------------------------

# Final filter: We only create a membership if the user was successfully looked up in AWS IC.
# This handles the case where an ACTIVE user hasn't finished SCIM sync yet (transient failure).
resource "aws_identitystore_group_membership" "synced_memberships" {
  # Iterate over active memberships, with a final filter for users that exist in AWS IC.
  # This gracefully handles ACTIVE users whose SCIM sync hasn't completed yet.
  for_each = {
    for key, v in local.active_memberships_to_sync : key => v
    if contains(keys(data.aws_identitystore_user.synced_users), v.user_email)
  }

  identity_store_id = local.identity_store_id

  group_id = each.value.target_group_id

  # Assign the User ID string from the successful AWS lookup
  member_id = data.aws_identitystore_user.synced_users[each.value.user_email].user_id
}