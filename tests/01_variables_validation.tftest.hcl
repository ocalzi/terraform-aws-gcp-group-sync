# -----------------------------------------------------
# Test Suite: Variable Validation
# -----------------------------------------------------
# Validates input variable constraints, defaults, and
# edge cases for the group sync module.

mock_provider "aws" {
  source = "./tests/mocks"
}
mock_provider "googleworkspace" {
  source = "./tests/mocks"
}

# ----- Default Values -----

run "default_aws_region_is_eu_west_3" {
  command = plan

  assert {
    condition     = var.aws_region == "eu-west-3"
    error_message = "Default AWS region should be eu-west-3"
  }
}

run "default_group_mappings_is_empty" {
  command = plan

  assert {
    condition     = length(var.group_mappings) == 0
    error_message = "Default group_mappings should be an empty map"
  }
}

# ----- Valid Group Mappings -----

run "accepts_single_group_mapping" {
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
    condition     = length(var.group_mappings) == 1
    error_message = "Should accept a single group mapping"
  }
}

run "accepts_multiple_group_mappings" {
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
        aws_role_name   = "GCP-Dev-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/PowerUserAccess"
      }
      readonly = {
        gcp_group_email = "readonly@example.com"
        aws_role_name   = "GCP-ReadOnly-Role"
        aws_policy_arn  = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
    }
  }

  assert {
    condition     = length(var.group_mappings) == 3
    error_message = "Should accept multiple group mappings"
  }
}

# ----- Custom Region -----

run "accepts_custom_aws_region" {
  command = plan

  variables {
    aws_region = "us-east-1"
  }

  assert {
    condition     = var.aws_region == "us-east-1"
    error_message = "Should accept a custom AWS region"
  }
}
