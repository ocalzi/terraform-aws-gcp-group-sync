# -----------------------------------------------------
# Test Suite: Output Validation
# -----------------------------------------------------
# Validates that outputs are correctly structured and
# contain expected data from GCP group lookups.

mock_provider "aws" {
  source = "./tests/mocks"
}
mock_provider "googleworkspace" {
  source = "./tests/mocks"
}

# ----- Output Structure -----

run "gcp_groups_details_output_has_correct_keys" {
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
    condition     = contains(keys(output.gcp_groups_details), "admins")
    error_message = "Output should contain a key for each group mapping"
  }
}

run "gcp_groups_details_output_empty_for_no_mappings" {
  command = plan

  variables {
    group_mappings = {}
  }

  assert {
    condition     = length(output.gcp_groups_details) == 0
    error_message = "Output should be empty when no group mappings are provided"
  }
}
