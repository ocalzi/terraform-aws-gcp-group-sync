<!-- BEGIN_TF_DOCS -->
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

## Technical Documentation

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_googleworkspace"></a> [googleworkspace](#requirement\_googleworkspace) | ~> 0.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_googleworkspace"></a> [googleworkspace](#provider\_googleworkspace) | 0.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_identitystore_group.identity_center_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_identitystore_group_membership.synced_memberships](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group_membership) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_group_mappings"></a> [group\_mappings](#input\_group\_mappings) | A map defining the target GCP groups and their corresponding AWS Identity Center groups. | <pre>map(object({<br/>    # The full email address of the existing Google Workspace Group<br/>    gcp_group_email = string<br/>    # The display name of the AWS Identity Center group to be created<br/>    aws_role_name = string<br/>    # TODO: Reserved for future use — permission set assignment.<br/>    # The AWS policy ARN to attach to the group's permission set<br/>    aws_policy_arn = optional(string, "")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_identity_center_groups"></a> [aws\_identity\_center\_groups](#output\_aws\_identity\_center\_groups) | AWS Identity Center groups created by this module. |
| <a name="output_gcp_groups_details"></a> [gcp\_groups\_details](#output\_gcp\_groups\_details) | Details fetched from Google Workspace for the configured groups, confirming lookup success. |
| <a name="output_sync_summary"></a> [sync\_summary](#output\_sync\_summary) | Summary of the synchronization: group count, total memberships, and identity store ID. |

## Troubleshooting

### Groups Not Syncing via SCIM

**Issue**: Groups from Google Workspace don't automatically appear in AWS Identity Center

**Explanation**: This is **expected behavior**. As documented in the [AWS Identity Center documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-gwp.html), the Google Workspace SCIM integration only supports automatic user provisioning, not group provisioning. This is precisely why this Terraform project exists - to bridge this gap by manually creating and managing groups.

**Solution**: Use this Terraform project to create and sync groups from Google Workspace to AWS Identity Center.

### User Not Found in AWS Identity Center

**Issue**: User exists in Google Workspace but not found in AWS Identity Center

**Solution**:
- Verify SCIM sync is properly configured
- Check user is active in Google Workspace
- Wait for SCIM sync cycle to complete (usually 40 minutes)
- Remember: Users must be synced via SCIM first before this Terraform can add them to groups

### Permission Denied Errors

**Issue**: Terraform cannot create resources in AWS

**Solution**:
- Verify AWS credentials have correct permissions
- Ensure AWS Identity Center is enabled
- Check service account has required Google Workspace API scopes

### Service Account Authentication Failed

**Issue**: Google Workspace provider authentication fails

**Solution**:
- Verify service account has Domain-Wide Delegation enabled
- Check impersonated user email is a workspace admin
- Confirm all required OAuth scopes are granted

## Security Best Practices

1. **Never commit sensitive files**:
   - `terraform.tfvars`
   - `*.tfstate` files
   - Service account JSON keys

2. **Use CI/CD Variables**: Store all secrets as protected, masked variables in GitLab CI or GitHub Actions secrets

3. **Rotate Credentials**: Regularly rotate AWS keys and service account keys

4. **Least Privilege**: Use minimal required permissions for service accounts and AWS users

5. **Enable Backend Encryption**: GitLab manages state encryption automatically

## Testing

This project uses **Terraform native tests** (`.tftest.hcl`, requires Terraform >= 1.6) with mock providers:

```bash
terraform init -backend=false
terraform test -verbose
```

Test suites cover:
- Variable validation and defaults
- Group creation logic
- Membership synchronization pipeline
- Output structure

## Contributing

When making changes:

1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Run `terraform test` to execute the test suite
4. Update documentation with `terraform-docs .` (configured via .terraform-docs.yml)
5. Test changes in a non-production environment first

## Tools Used

This project was created and managed using the following tools:

### Infrastructure as Code
- **Terraform** - Infrastructure provisioning and management
- **tfswitch** - Terraform version management tool
- **terraform-docs** - Automated documentation generation for Terraform modules

### CI/CD & Version Control
- **GitHub Actions** - CI pipeline (validate, test, lint, security scan) and release automation
- **GitLab CI** - Deployment pipeline for scheduled synchronization
- **Git** - Version control system
- **pre-commit** - Git hook framework for identifying issues before commit

### Containerization
- **Docker** - Containerization platform for consistent development environments

### Cloud Providers
- **Google Cloud Platform (GCP)** - Google Workspace integration
- **Amazon Web Services (AWS)** - AWS Identity Center management
<!-- END_TF_DOCS -->