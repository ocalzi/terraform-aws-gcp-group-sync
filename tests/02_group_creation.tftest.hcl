# -----------------------------------------------------
# Test Suite: AWS Identity Center Group Creation
# -----------------------------------------------------
# Validates that groups are correctly created in AWS
# Identity Center based on group_mappings input.

mock_provider "aws" {
  source = "./tests/mocks"
}
mock_provider "googleworkspace" {
  source = "./tests/mocks"
}

# ----- Group Resource Creation -----

run "creates_identity_center_groups_for_each_mapping" {
  command = plan

  variables {
    group_mappings = {
      admins = {
        gcp_group_email = "admins@example.com"
        aws_role_name   = "GCP-Admin-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
      }
      developers = {
        gcp_group_email = "devs@example.com"
        aws_role_name   = "GCP-Developer-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/PowerUserAccess"
      }
    }
  }

  # Verify group count matches mapping count
  assert {
    condition     = length(aws_identitystore_group.identity_center_groups) == 2
    error_message = "Should create one Identity Center group per mapping"
  }
}

run "group_display_name_matches_aws_role_name" {
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
    condition     = aws_identitystore_group.identity_center_groups["admins"].display_name == "GCP-Admin-Role"
    error_message = "Group display name should match the aws_role_name from mapping"
  }
}

run "group_description_includes_gcp_email" {
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
    condition     = aws_identitystore_group.identity_center_groups["admins"].description == "Group for federated access from GCP: admins@example.com"
    error_message = "Group description should reference the source GCP group email"
  }
}

# ----- Empty Mappings -----

run "no_groups_created_with_empty_mappings" {
  command = plan

  variables {
    group_mappings = {}
  }

  assert {
    condition     = length(aws_identitystore_group.identity_center_groups) == 0
    error_message = "No groups should be created when mappings are empty"
  }
}
