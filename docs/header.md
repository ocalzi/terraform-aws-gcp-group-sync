# GCP to AWS Identity Center Group Synchronization

This Terraform **module** automates the synchronization of Google Workspace groups and their members to AWS Identity Center (formerly AWS SSO). It ensures that organizational group structures and user memberships remain consistent across both cloud platforms.

## Module Usage

### From Terraform Registry

```hcl
module "gcp_group_sync" {
  source  = "ocalzi/gcp-group-sync/aws"
  version = "~> 1.0"

  group_mappings = {
    admins = {
      gcp_group_email = "admins@yourdomain.com"
      aws_role_name   = "GCP-Admin-Role"
    }
    developers = {
      gcp_group_email = "developers@yourdomain.com"
      aws_role_name   = "GCP-Developer-Role"
    }
  }
}
```

### From GitHub

```hcl
module "gcp_group_sync" {
  source = "github.com/ocalzi/terraform-aws-gcp-group-sync?ref=v1.1.0"

  group_mappings = {
    admins = {
      gcp_group_email = "admins@yourdomain.com"
      aws_role_name   = "GCP-Admin-Role"
    }
  }
}
```

### Provider Configuration

The **caller** is responsible for configuring both providers. The module does not include provider blocks.

```hcl
provider "aws" {
  region = "eu-west-3"
}

provider "googleworkspace" {
  customer_id             = "C01234567"
  impersonated_user_email = "admin@yourdomain.com"
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
  ]
}
```

See [`examples/complete/main.tf`](examples/complete/main.tf) for a full working example.

## A Note on Continuous Improvement

This project embodies the principle that no work is complete in isolation. Every codebase benefits from the insights, experiences, and contributions of others. Your feedback, improvements, and perspectives are not just welcome—they're essential to making this solution better for everyone.

## Features

- **Terraform Registry Module**: Consumable as a reusable module with `module "..." { source = "ocalzi/gcp-group-sync/aws" }`
- **Group Synchronization**: Automatically mirrors Google Workspace groups to AWS Identity Center
- **Member Synchronization**: Syncs active Google Workspace group members to corresponding AWS Identity Center groups
- **Active User Filtering**: Only syncs active users (excludes suspended Google Workspace accounts)
- **Configurable Mappings**: Define custom group-to-role mappings via variables
- **CI/CD Ready**: Includes GitHub Actions CI and GitLab pipeline configuration

## Why This Project Exists

When integrating Google Workspace with AWS Identity Center using SCIM provisioning, **AWS only supports automatic synchronization of users, not groups**.

According to [AWS Documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-gwp.html):

> SCIM automatic synchronization from Google Workspace is currently limited to user provisioning. Automatic group provisioning is not supported at this time. Groups can be manually created with AWS CLI Identity Store create-group command or AWS Identity and Access Management (IAM) API CreateGroup. Alternatively, you can use ssosync to synchronize Google Workspace users and groups into IAM Identity Center.

### Understanding the Limitation

The SCIM 2.0 protocol itself supports both user and group provisioning, but AWS's implementation for Google Workspace only includes user provisioning. This means:

- Users are automatically synced from Google Workspace to AWS Identity Center via SCIM
- User updates (name changes, status changes) are automatically reflected
- Groups must be created and managed separately in AWS Identity Center
- Group memberships are not automatically synced

### How This Module Works

1. **Users**: Synced automatically from Google Workspace to AWS Identity Center via SCIM
2. **Groups**: Created by Terraform reading from Google Workspace and creating in AWS Identity Center
3. **Group Memberships**: Terraform reads GCP group members and creates AWS Identity Center memberships
4. **Continuous Sync**: CI/CD pipelines can run on schedule to keep memberships in sync

## Prerequisites

Before using this module, ensure you have:

1. **Google Workspace Setup**
   - Service Account with Domain-Wide Delegation enabled
   - Required API scopes:
     - `https://www.googleapis.com/auth/admin.directory.user`
     - `https://www.googleapis.com/auth/admin.directory.userschema`
     - `https://www.googleapis.com/auth/admin.directory.group.readonly`
   - Service account JSON key file

2. **AWS Setup**
   - AWS Identity Center enabled in your organization
   - **SCIM synchronization configured between Google Workspace and AWS Identity Center** (for user sync)
   - AWS credentials with permissions to manage Identity Center resources
   - Note: Users must be synced via SCIM before this module can add them to groups

3. **Tools**
   - Terraform >= 1.6
   - AWS CLI configured (optional but recommended)

## Architecture

### Data Flow

```
Google Workspace Groups → Terraform Module → AWS Identity Center Groups
         ↓                                          ↓
    GCP Members → Filter Active Only → AWS IC Group Memberships
```

### Components

1. **versions.tf**: Terraform and provider version constraints
2. **main.tf**: Group synchronization logic
3. **membership.tf**: Member synchronization with active user filtering
4. **variables.tf**: Input variable definitions
5. **output.tf**: Output definitions
