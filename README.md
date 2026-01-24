# GCP to AWS Identity Center Group Synchronization

This Terraform project automates the synchronization of Google Workspace groups and their members to AWS Identity Center (formerly AWS SSO). It ensures that organizational group structures and user memberships remain consistent across both cloud platforms.

## Features

- **Group Synchronization**: Automatically mirrors Google Workspace groups to AWS Identity Center
- **Member Synchronization**: Syncs active Google Workspace group members to corresponding AWS Identity Center groups
- **Active User Filtering**: Only syncs active users (excludes suspended Google Workspace accounts)
- **Configurable Mappings**: Define custom group-to-role mappings via variables
- **GitLab CI/CD Ready**: Includes pipeline configuration for automated deployments

## Prerequisites

Before using this project, ensure you have:

1. **Google Workspace Setup**
   - Service Account with Domain-Wide Delegation enabled
   - Required API scopes:
     - `https://www.googleapis.com/auth/admin.directory.user`
     - `https://www.googleapis.com/auth/admin.directory.userschema`
     - `https://www.googleapis.com/auth/admin.directory.group.readonly`
   - Service account JSON key file

2. **AWS Setup**
   - AWS Identity Center enabled in your organization
   - SCIM synchronization configured between Google Workspace and AWS Identity Center
   - AWS credentials with permissions to manage Identity Center resources

3. **Tools**
   - Terraform >= 1.0
   - AWS CLI configured (optional but recommended)

## Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd gcp_aws_sync
```

### 2. Create Configuration File

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
access_key       = "YOUR_AWS_ACCESS_KEY"
secret_key       = "YOUR_AWS_SECRET_KEY"
aws_region       = "eu-west-3"
aws_account_id   = "123456789012"
gcp_saml_idp_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxx"

group_mappings = {
  admins = {
    gcp_group_email = "admins@yourdomain.com"
    aws_role_name   = "GCP-Admin-Role"
    aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
```

### 3. Set Google Workspace Credentials

Export the path to your Google Workspace service account key:

```bash
export GOOGLEWORKSPACE_CREDENTIALS=./path-to-your-service-account-key.json
```

Update `provider.tf` with your Google Workspace details:
- `customer_id`: Your Google Workspace customer ID
- `impersonated_user_email`: Email of an admin user to impersonate

### 4. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## GitLab CI/CD Configuration

### Required CI/CD Variables

Set these variables in your GitLab project settings (Settings > CI/CD > Variables):

| Variable | Description | Protected | Masked |
|----------|-------------|-----------|--------|
| `TF_STATE_NAME` | Name for your Terraform state | No | No |
| `GOOGLEWORKSPACE_CREDENTIALS_B64` | Base64-encoded service account JSON key | Yes | Yes |
| `TF_VAR_access_key` | AWS Access Key | Yes | Yes |
| `TF_VAR_secret_key` | AWS Secret Key | Yes | Yes |
| `TF_VAR_aws_account_id` | AWS Account ID | No | No |
| `TF_VAR_gcp_saml_idp_arn` | GCP SAML IdP ARN | No | No |

### Encoding Service Account Key

```bash
cat your-service-account-key.json | base64 | tr -d '\n'
```

Copy the output and set it as `GOOGLEWORKSPACE_CREDENTIALS_B64` in GitLab CI/CD variables.

### Pipeline Stages

The GitLab CI/CD pipeline includes:
1. **validate**: Validates Terraform syntax
2. **build**: Creates Terraform plan
3. **deploy**: Applies Terraform changes
4. **cleanup**: Removes temporary resources

## Architecture

### Data Flow

```
Google Workspace Groups → Terraform → AWS Identity Center Groups
         ↓                               ↓
    GCP Members → Filter Active → AWS IC Memberships
```

### Components

1. **main.tf**: Group synchronization logic
2. **membership.tf**: Member synchronization with active user filtering
3. **provider.tf**: Provider configurations and backend setup
4. **variables.tf**: Input variable definitions
5. **output.tf**: Output definitions

## How It Works

### Group Synchronization

1. Reads Google Workspace groups from `group_mappings` variable
2. Creates corresponding groups in AWS Identity Center
3. Associates groups with descriptions linking to source GCP groups

### Member Synchronization

1. Retrieves all members from configured Google Workspace groups
2. Filters for active users only (suspended users are excluded)
3. Looks up corresponding AWS Identity Center user IDs via SCIM
4. Creates group memberships in AWS Identity Center

### Error Handling

- **Suspended Users**: Automatically excluded from synchronization
- **Incomplete SCIM Sync**: Gracefully handles users not yet synced to AWS
- **Multiple Memberships**: Supports users in multiple groups

## Troubleshooting

### User Not Found in AWS Identity Center

**Issue**: User exists in Google Workspace but not found in AWS Identity Center

**Solution**: 
- Verify SCIM sync is properly configured
- Check user is active in Google Workspace
- Wait for SCIM sync cycle to complete (usually 40 minutes)

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

2. **Use GitLab CI/CD Variables**: Store all secrets as protected, masked variables

3. **Rotate Credentials**: Regularly rotate AWS keys and service account keys

4. **Least Privilege**: Use minimal required permissions for service accounts and AWS users

5. **Enable Backend Encryption**: GitLab manages state encryption automatically

## Contributing

When making changes:

1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Update documentation with `terraform-docs markdown table . > README.md`
4. Test changes in a non-production environment first

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |
| <a name="requirement_googleworkspace"></a> [googleworkspace](#requirement\_googleworkspace) | ~> 0.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_googleworkspace"></a> [googleworkspace](#provider\_googleworkspace) | ~> 0.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_identitystore_group.identity_center_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_identitystore_group_membership.synced_memberships](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group_membership) | resource |
| [aws_identitystore_user.synced_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_user) | data source |
| [aws_ssoadmin_instances.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |
| [googleworkspace_group.gcp_groups](https://registry.terraform.io/providers/hashicorp/googleworkspace/latest/docs/data-sources/group) | data source |
| [googleworkspace_group_members.gcp_group_members](https://registry.terraform.io/providers/hashicorp/googleworkspace/latest/docs/data-sources/group_members) | data source |
| [googleworkspace_user.gcp_users](https://registry.terraform.io/providers/hashicorp/googleworkspace/latest/docs/data-sources/user) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | AWS Access Key | `string` | `""` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS Account ID where the IAM roles will be created. | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | defaul aws region | `string` | `"eu-west-3"` | no |
| <a name="input_gcp_saml_idp_arn"></a> [gcp\_saml\_idp\_arn](#input\_gcp\_saml\_idp\_arn) | The ARN of the GCP SAML Identity Provider in AWS IAM. | `string` | `""` | no |
| <a name="input_group_mappings"></a> [group\_mappings](#input\_group\_mappings) | A map defining the target GCP groups and their corresponding AWS roles/policies. | <pre>map(object({<br/>    # The full email address of the existing Google Workspace Group<br/>    gcp_group_email = string<br/>    # The name of the AWS IAM Role to be created<br/>    aws_role_name = string<br/>    # The AWS policy ARN to attach to the role<br/>    aws_policy_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | AWS Secret Key | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gcp_groups_details"></a> [gcp\_groups\_details](#output\_gcp\_groups\_details) | Details fetched from Google Workspace for the core, it, and dev groups, confirming lookup success. |

<!-- BEGIN_TF_DOCS -->
# GCP to AWS Identity Center Group Synchronization

This Terraform project automates the synchronization of Google Workspace groups and their members to AWS Identity Center (formerly AWS SSO). It ensures that organizational group structures and user memberships remain consistent across both cloud platforms.

## Features

- **Group Synchronization**: Automatically mirrors Google Workspace groups to AWS Identity Center
- **Member Synchronization**: Syncs active Google Workspace group members to corresponding AWS Identity Center groups
- **Active User Filtering**: Only syncs active users (excludes suspended Google Workspace accounts)
- **Configurable Mappings**: Define custom group-to-role mappings via variables
- **GitLab CI/CD Ready**: Includes pipeline configuration for automated deployments

## Prerequisites

Before using this project, ensure you have:

1. **Google Workspace Setup**
   - Service Account with Domain-Wide Delegation enabled
   - Required API scopes:
     - `https://www.googleapis.com/auth/admin.directory.user`
     - `https://www.googleapis.com/auth/admin.directory.userschema`
     - `https://www.googleapis.com/auth/admin.directory.group.readonly`
   - Service account JSON key file

2. **AWS Setup**
   - AWS Identity Center enabled in your organization
   - SCIM synchronization configured between Google Workspace and AWS Identity Center
   - AWS credentials with permissions to manage Identity Center resources

3. **Tools**
   - Terraform >= 1.0
   - AWS CLI configured (optional but recommended)

## Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd gcp_aws_sync
```

### 2. Create Configuration File

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
access_key       = "YOUR_AWS_ACCESS_KEY"
secret_key       = "YOUR_AWS_SECRET_KEY"
aws_region       = "eu-west-3"
aws_account_id   = "123456789012"
gcp_saml_idp_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxx"

group_mappings = {
  admins = {
    gcp_group_email = "admins@yourdomain.com"
    aws_role_name   = "GCP-Admin-Role"
    aws_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
```

### 3. Set Google Workspace Credentials

Export the path to your Google Workspace service account key:

```bash
export GOOGLEWORKSPACE_CREDENTIALS=./path-to-your-service-account-key.json
```

Update `provider.tf` with your Google Workspace details:
- `customer_id`: Your Google Workspace customer ID
- `impersonated_user_email`: Email of an admin user to impersonate

### 4. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## GitLab CI/CD Configuration

### Required CI/CD Variables

Set these variables in your GitLab project settings (Settings > CI/CD > Variables):

| Variable | Description | Protected | Masked |
|----------|-------------|-----------|--------|
| `TF_STATE_NAME` | Name for your Terraform state | No | No |
| `GOOGLEWORKSPACE_CREDENTIALS_B64` | Base64-encoded service account JSON key | Yes | Yes |
| `TF_VAR_access_key` | AWS Access Key | Yes | Yes |
| `TF_VAR_secret_key` | AWS Secret Key | Yes | Yes |
| `TF_VAR_aws_account_id` | AWS Account ID | No | No |
| `TF_VAR_gcp_saml_idp_arn` | GCP SAML IdP ARN | No | No |

### Encoding Service Account Key

```bash
cat your-service-account-key.json | base64 | tr -d '\n'
```

Copy the output and set it as `GOOGLEWORKSPACE_CREDENTIALS_B64` in GitLab CI/CD variables.

### Pipeline Stages

The GitLab CI/CD pipeline includes:
1. **validate**: Validates Terraform syntax
2. **build**: Creates Terraform plan
3. **deploy**: Applies Terraform changes
4. **cleanup**: Removes temporary resources

## Architecture

### Data Flow

```
Google Workspace Groups → Terraform → AWS Identity Center Groups
         ↓                               ↓
    GCP Members → Filter Active → AWS IC Memberships
```

### Components

1. **main.tf**: Group synchronization logic
2. **membership.tf**: Member synchronization with active user filtering
3. **provider.tf**: Provider configurations and backend setup
4. **variables.tf**: Input variable definitions
5. **output.tf**: Output definitions

## How It Works

### Group Synchronization

1. Reads Google Workspace groups from `group_mappings` variable
2. Creates corresponding groups in AWS Identity Center
3. Associates groups with descriptions linking to source GCP groups

### Member Synchronization

1. Retrieves all members from configured Google Workspace groups
2. Filters for active users only (suspended users are excluded)
3. Looks up corresponding AWS Identity Center user IDs via SCIM
4. Creates group memberships in AWS Identity Center

### Error Handling

- **Suspended Users**: Automatically excluded from synchronization
- **Incomplete SCIM Sync**: Gracefully handles users not yet synced to AWS
- **Multiple Memberships**: Supports users in multiple groups

## Technical Documentation

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |
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
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | AWS Access Key | `string` | `""` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS Account ID where the IAM roles will be created. | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | defaul aws region | `string` | `"eu-west-3"` | no |
| <a name="input_gcp_saml_idp_arn"></a> [gcp\_saml\_idp\_arn](#input\_gcp\_saml\_idp\_arn) | The ARN of the GCP SAML Identity Provider in AWS IAM. | `string` | `""` | no |
| <a name="input_group_mappings"></a> [group\_mappings](#input\_group\_mappings) | A map defining the target GCP groups and their corresponding AWS roles/policies. | <pre>map(object({<br/>    # The full email address of the existing Google Workspace Group<br/>    gcp_group_email = string<br/>    # The name of the AWS IAM Role to be created<br/>    aws_role_name = string<br/>    # The AWS policy ARN to attach to the role<br/>    aws_policy_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | AWS Secret Key | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gcp_groups_details"></a> [gcp\_groups\_details](#output\_gcp\_groups\_details) | Details fetched from Google Workspace for the  groups, confirming lookup success. |

## Troubleshooting

### User Not Found in AWS Identity Center

**Issue**: User exists in Google Workspace but not found in AWS Identity Center

**Solution**:
- Verify SCIM sync is properly configured
- Check user is active in Google Workspace
- Wait for SCIM sync cycle to complete (usually 40 minutes)

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

2. **Use GitLab CI/CD Variables**: Store all secrets as protected, masked variables

3. **Rotate Credentials**: Regularly rotate AWS keys and service account keys

4. **Least Privilege**: Use minimal required permissions for service accounts and AWS users

5. **Enable Backend Encryption**: GitLab manages state encryption automatically

## Contributing

When making changes:

1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Update documentation with `terraform-docs .` (configured via .terraform-docs.yml)
4. Test changes in a non-production environment first

## Tools Used

This project was created and managed using the following tools:

### Infrastructure as Code
- **Terraform** - Infrastructure provisioning and management
- **tfswitch** - Terraform version management tool
- **terraform-docs** - Automated documentation generation for Terraform modules

### CI/CD & Version Control
- **GitLab CI** - Continuous integration and deployment pipeline
- **Git** - Version control system
- **pre-commit** - Git hook framework for identifying issues before commit

### Containerization
- **Docker** - Containerization platform for consistent development environments

### AI Development Assistant
- **OpenCode** - AI-powered coding assistant for project development and automation

### Cloud Providers
- **Google Cloud Platform (GCP)** - Google Workspace integration
- **Amazon Web Services (AWS)** - AWS Identity Center management

## Contributing

When making changes:

1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Update documentation with `terraform-docs .` (configured via .terraform-docs.yml)
4. Test changes in a non-production environment first
<!-- END_TF_DOCS -->