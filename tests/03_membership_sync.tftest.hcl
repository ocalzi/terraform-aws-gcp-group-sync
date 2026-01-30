# -----------------------------------------------------
# Test Suite: Membership Synchronization Logic
# -----------------------------------------------------
# Validates the membership pipeline: GCP member extraction,
# active user filtering, and AWS group membership creation.

mock_provider "aws" {
  source = "./tests/mocks"
}
mock_provider "googleworkspace" {
  source = "./tests/mocks"
}

# ----- Membership Locals Computation -----

run "all_memberships_flatten_correctly" {
  command = plan

  variables {
    group_mappings = {
      admins = {
        gcp_group_email = "admins@example.com"
        aws_role_name   = "GCP-Admin-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
      }
    }
  }

  # The flattened memberships list should contain entries
  # (one per member per group from mock data)
  assert {
    condition     = length(local.all_memberships) > 0
    error_message = "all_memberships should contain flattened member entries"
  }
}

run "unique_emails_are_deduplicated" {
  command = plan

  variables {
    group_mappings = {
      admins = {
        gcp_group_email = "admins@example.com"
        aws_role_name   = "GCP-Admin-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
      }
    }
  }

  # unique_user_emails_raw should have no duplicates
  assert {
    condition     = length(local.unique_user_emails_raw) == length(distinct(local.unique_user_emails_raw))
    error_message = "unique_user_emails_raw should contain only distinct emails"
  }
}

# ----- Identity Store ID -----

run "identity_store_id_is_set" {
  command = plan

  variables {
    group_mappings = {
      admins = {
        gcp_group_email = "admins@example.com"
        aws_role_name   = "GCP-Admin-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
      }
    }
  }

  assert {
    condition     = local.identity_store_id != ""
    error_message = "identity_store_id should be populated from AWS SSO Admin data source"
  }
}

# ----- Empty Mappings Edge Case -----

run "no_memberships_with_empty_mappings" {
  command = plan

  variables {
    group_mappings = {}
  }

  assert {
    condition     = length(local.all_memberships) == 0
    error_message = "No memberships should exist when group mappings are empty"
  }
}
