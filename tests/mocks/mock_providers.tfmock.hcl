# -----------------------------------------------------
# Mock Provider Overrides for Terraform Tests
# -----------------------------------------------------
# These mocks simulate API responses from AWS and Google
# Workspace without requiring real credentials or network.

# Mock AWS SSO Admin instances (Identity Center)
mock_data "aws_ssoadmin_instances" {
  defaults = {
    identity_store_ids = ["d-1234567890"]
    arns               = ["arn:aws:sso:::instance/ssoins-1234567890abcdef"]
  }
}

# Mock Google Workspace group lookups
mock_data "googleworkspace_group" {
  defaults = {
    id                   = "mock-group-id-001"
    email                = "mock-group@test.example.com"
    name                 = "Mock Test Group"
    description          = "A mocked Google Workspace group for testing"
    direct_members_count = "3"
  }
}

# Mock Google Workspace group members
mock_data "googleworkspace_group_members" {
  defaults = {
    members = [
      {
        email  = "active-user1@test.example.com"
        role   = "MEMBER"
        type   = "USER"
        status = "ACTIVE"
        id     = "user-001"
      },
      {
        email  = "active-user2@test.example.com"
        role   = "MEMBER"
        type   = "USER"
        status = "ACTIVE"
        id     = "user-002"
      },
      {
        email  = "suspended-user@test.example.com"
        role   = "MEMBER"
        type   = "USER"
        status = "SUSPENDED"
        id     = "user-003"
      }
    ]
  }
}

# Mock Google Workspace user lookup (active user)
mock_data "googleworkspace_user" {
  defaults = {
    id            = "mock-user-id-001"
    primary_email = "mock-user@test.example.com"
    suspended     = false
    is_admin      = false
    name = [{
      given_name  = "Mock"
      family_name = "User"
      full_name   = "Mock User"
    }]
  }
}

# Mock AWS Identity Store user lookup
mock_data "aws_identitystore_user" {
  defaults = {
    user_id           = "aws-user-id-001"
    identity_store_id = "d-1234567890"
    user_name         = "mock-user@test.example.com"
  }
}

# Mock AWS Identity Store group resource
mock_resource "aws_identitystore_group" {
  defaults = {
    group_id          = "aws-group-id-001"
    identity_store_id = "d-1234567890"
    display_name      = "Mock-Group"
    description       = "Mocked group"
  }
}

# Mock AWS Identity Store group membership resource
mock_resource "aws_identitystore_group_membership" {
  defaults = {
    membership_id     = "aws-membership-id-001"
    identity_store_id = "d-1234567890"
    group_id          = "aws-group-id-001"
    member_id         = "aws-user-id-001"
  }
}
