# GCP to AWS Identity Center Group Synchronization

This Terraform project automates the synchronization of Google Workspace groups and their members to AWS Identity Center (formerly AWS SSO). It ensures that organizational group structures and user memberships remain consistent across both cloud platforms.

## Features

- **Group Synchronization**: Automatically mirrors Google Workspace groups to AWS Identity Center
- **Member Synchronization**: Syncs active Google Workspace group members to corresponding AWS Identity Center groups
- **Active User Filtering**: Only syncs active users (excludes suspended Google Workspace accounts)
- **Configurable Mappings**: Define custom group-to-role mappings via variables
- **GitLab CI/CD Ready**: Includes pipeline configuration for automated deployments

## Why This Project Exists

When integrating Google Workspace with AWS Identity Center using SCIM provisioning, **AWS only supports automatic synchronization of users, not groups**. 

According to [AWS Documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-gwp.html):

> SCIM automatic synchronization from Google Workspace is currently limited to user provisioning. Automatic group provisioning is not supported at this time. Groups can be manually created with AWS CLI Identity Store create-group command or AWS Identity and Access Management (IAM) API CreateGroup. Alternatively, you can use ssosync to synchronize Google Workspace users and groups into IAM Identity Center.

### Understanding the Limitation

The SCIM 2.0 protocol itself supports both user and group provisioning, but AWS's implementation for Google Workspace only includes user provisioning. This means:

- ✅ **Users** are automatically synced from Google Workspace to AWS Identity Center via SCIM
- ✅ **User updates** (name changes, status changes) are automatically reflected
- ❌ **Groups** must be created and managed separately in AWS Identity Center
- ❌ **Group memberships** are not automatically synced

### Solutions for Group Management

AWS documentation suggests three approaches:

1. **Manual Creation**: Use AWS CLI or API to manually create groups (not scalable)
2. **ssosync**: Use the open-source [ssosync](https://github.com/awslabs/ssosync) tool from AWS Labs
3. **Infrastructure as Code**: Use Terraform (this project's approach)

### Terraform vs ssosync

Both solutions achieve similar goals but with different philosophies:

| Feature | This Terraform Project | ssosync |
|---------|----------------------|---------|
| **Approach** | Infrastructure as Code | Sync daemon/scheduled job |
| **Configuration** | Declarative HCL | Command-line flags / environment variables |
| **Group Selection** | Explicit mapping (opt-in specific groups) | All groups or filtered by query (opt-out) |
| **Version Control** | Full Git history of group structure | Configuration only |
| **Customization** | Highly customizable (Terraform flexibility) | Limited to ssosync features |
| **State Management** | Terraform state (shows drift, plan changes) | No state (idempotent sync) |
| **CI/CD Integration** | Native GitLab CI/CD | Requires custom deployment |
| **Permissions Management** | Extensible (can add permission sets, account assignments) | Groups and memberships only |
| **Learning Curve** | Requires Terraform knowledge | Simpler, single binary |
| **Maintenance** | Standard Terraform workflows | Binary updates, lambda deployments |
| **Audit Trail** | Git commits + Terraform outputs | CloudWatch logs (if using Lambda) |
| **Tooling Overhead** | Uses existing Terraform/GitLab stack | Requires deploying and maintaining additional tool (Lambda/container/cron) |
| **Operational Complexity** | No new infrastructure needed | New service to monitor, patch, and maintain |
| **Best For** | Organizations already using Terraform/IaC, need customization, startups wanting to minimize tooling | Quick setup, sync all groups, lightweight solution |

**Choose ssosync if:**
- You want to sync all Google Workspace groups automatically
- You prefer a simple, standalone tool
- You don't need infrastructure-as-code benefits
- You want AWS Labs maintained solution

**Choose this Terraform project if:**
- You want explicit control over which groups are synced
- You're already using Terraform for infrastructure
- You need version control and audit trails
- You want to extend with permission sets and account assignments
- You prefer declarative configuration over imperative sync
- You need GitLab CI/CD integration
- **You want to avoid adding another tool to your stack** (especially valuable for startups and small teams)
- **You prefer leveraging existing tools** rather than introducing new infrastructure to maintain

### How This Terraform Project Works

1. **Users**: Synced automatically from Google Workspace → AWS Identity Center via SCIM
2. **Groups**: Created by Terraform reading from Google Workspace and creating in AWS Identity Center
3. **Group Memberships**: Terraform reads GCP group members and creates AWS Identity Center memberships
4. **Continuous Sync**: GitLab pipelines can run on schedule to keep memberships in sync

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
   - **SCIM synchronization configured between Google Workspace and AWS Identity Center** (for user sync)
   - AWS credentials with permissions to manage Identity Center resources
   - Note: Users must be synced via SCIM before this Terraform project can add them to groups

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

### Automated Synchronization with Scheduled Pipelines

To keep group memberships synchronized automatically, you can configure GitLab to run Terraform on a schedule. This ensures that when users are added or removed from Google Workspace groups, the changes are reflected in AWS Identity Center.

#### Setting Up Scheduled Pipelines

1. **Navigate to CI/CD Schedule Settings**
   - Go to your GitLab project
   - Navigate to **CI/CD > Schedules**
   - Click **New schedule**

2. **Configure the Schedule**
   ```
   Description: Daily Group Membership Sync
   Interval Pattern: 0 2 * * *  (runs daily at 2 AM UTC)
   Target Branch: main
   Active: ✓
   ```

3. **Add Schedule Variables** (optional)
   - `TERRAFORM_AUTO_APPLY`: `true` (for automatic deployment)
   - `SCHEDULE_RUN`: `true` (to identify scheduled runs in pipeline logic)

#### Pipeline Configuration for Auto-Apply

Update your `.gitlab-ci.yml` to support auto-apply on scheduled runs. Add the following to your deploy stage:

```yaml
deploy:
  stage: deploy
  image: 
    name: hashicorp/terraform:latest
    entrypoint: [""]
  before_script:
    - cd ${TF_ROOT}
    - echo "$GOOGLEWORKSPACE_CREDENTIALS_B64" | base64 -d > gcp-credentials.json
    - export GOOGLEWORKSPACE_CREDENTIALS=${TF_ROOT}/gcp-credentials.json
    - terraform init
  script:
    - terraform apply plan.tfplan
  dependencies:
    - build
  only:
    - main
    - schedules
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule" && $TERRAFORM_AUTO_APPLY == "true"'
      when: always  # Auto-apply for scheduled runs when flag is set
    - when: manual  # Default to manual approval for regular runs
```

#### Recommended Sync Frequency

Consider these factors when choosing your sync schedule:

- **SCIM Sync Time**: Google Workspace SCIM sync can take up to 24 hours (usually completes within 40 minutes)
- **Group Volatility**: How frequently do group memberships change in your organization?
- **Terraform State Locks**: Ensure only one pipeline runs at a time

**Recommended schedules:**

- **High Volatility Organizations**: Every 4-6 hours
  ```
  0 */6 * * *
  ```

- **Medium Volatility**: Daily (recommended)
  ```
  0 2 * * *
  ```

- **Low Volatility**: Weekly
  ```
  0 2 * * 0
  ```

#### Safety Considerations

1. **State Locking**: GitLab backend handles state locking automatically
2. **Approval Gates**: Consider keeping manual approval for production and auto-apply only for dev/staging
3. **Notifications**: Configure GitLab pipeline notifications to alert on failures
4. **Monitoring**: Review pipeline logs regularly to catch any sync issues

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
