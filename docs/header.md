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
