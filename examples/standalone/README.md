# Standalone Usage

This example shows how to run the GCP-to-AWS group sync as a **standalone project** — without consuming it as a remote Terraform module.

This is ideal for:

- Teams who want to **fork and customise** the sync logic
- **GitLab CI/CD scheduled pipelines** for continuous group synchronisation
- Environments where consuming **remote modules is restricted**

## Quick Start

```bash
cd examples/standalone

# Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Set credentials (see Authentication sections below)
# ...

# Run
terraform init
terraform plan
terraform apply
```

---

## Authentication

This standalone setup requires credentials for **two providers**: AWS and Google Workspace. The sections below detail every supported method for each.

### AWS Authentication

The AWS provider supports multiple authentication methods. Choose the one that fits your environment. They are evaluated in the order listed below — the first one found wins.

> **Reference**: [AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

#### Option 1: Environment Variables (recommended for CI/CD)

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_REGION="eu-west-3"
```

#### Option 2: Shared Credentials File

The AWS CLI creates `~/.aws/credentials` when you run `aws configure`:

```ini
# ~/.aws/credentials
[default]
aws_access_key_id     = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Named profile
[gcp-sync]
aws_access_key_id     = AKIAI...
aws_secret_access_key = wJalr...
```

To use a named profile:

```bash
export AWS_PROFILE="gcp-sync"
```

> **Reference**: [AWS CLI Named Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)

#### Option 3: AWS IAM Role (EC2 / ECS / Lambda)

If running on AWS infrastructure, the provider automatically uses the attached IAM role — no credentials needed. Just ensure the role has the required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sso:*",
        "identitystore:*"
      ],
      "Resource": "*"
    }
  ]
}
```

> **Reference**: [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)

#### Option 4: AWS SSO / Identity Center

```bash
# Configure SSO profile
aws configure sso --profile gcp-sync

# Login before running Terraform
aws sso login --profile gcp-sync
export AWS_PROFILE="gcp-sync"
```

> **Reference**: [AWS SSO with Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#sso-credentials)

#### Option 5: Assume Role

Add to the `provider "aws"` block in `main.tf`:

```hcl
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformGroupSync"
    session_name = "gcp-group-sync"
  }
}
```

> **Reference**: [AWS Provider Assume Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#assuming-an-iam-role)

#### Required AWS Permissions

Whichever method you choose, the identity must have permissions for:

| Service | Actions | Purpose |
|---|---|---|
| **SSO Admin** | `sso:ListInstances` | Look up Identity Center instance |
| **Identity Store** | `identitystore:CreateGroup`, `CreateGroupMembership`, `ListUsers`, `ListGroups`, `ListGroupMemberships`, `DeleteGroup`, `DeleteGroupMembership` | Manage groups and memberships |

---

### Google Workspace Authentication

The Google Workspace provider requires a **Service Account with Domain-Wide Delegation (DWD)**. The service account impersonates a Workspace admin to access the Admin SDK API.

> **Reference**: [Google Workspace Provider Authentication](https://registry.terraform.io/providers/hashicorp/googleworkspace/latest/docs#authentication)

#### Prerequisites

1. **Create a Service Account** in [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. **Enable Domain-Wide Delegation** on the service account
3. **Authorise API scopes** in [Google Workspace Admin Console](https://admin.google.com/) → Security → API Controls → Domain-wide Delegation:

   | Scope | Purpose |
   |---|---|
   | `https://www.googleapis.com/auth/admin.directory.user` | Read user accounts |
   | `https://www.googleapis.com/auth/admin.directory.userschema` | Read user schemas |
   | `https://www.googleapis.com/auth/admin.directory.group.readonly` | Read group memberships |

4. **Download the JSON key** for the service account

> **Step-by-step guide**: [Set up Domain-Wide Delegation](https://developers.google.com/identity/protocols/oauth2/service-account#delegatingauthority)

#### Option 1: Environment Variable (recommended)

Point to the JSON key file:

```bash
export GOOGLEWORKSPACE_CREDENTIALS="/path/to/service-account-key.json"
```

Or inline the JSON content directly:

```bash
export GOOGLEWORKSPACE_CREDENTIALS='{"type":"service_account","project_id":"...","private_key_id":"..."}'
```

#### Option 2: Inline Credentials in Provider Block

```hcl
provider "googleworkspace" {
  credentials             = file("${path.module}/service-account-key.json")
  customer_id             = var.google_workspace_customer_id
  impersonated_user_email = var.google_workspace_admin_email

  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.userschema",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
  ]
}
```

> **Warning**: Do not commit the JSON key file to version control. Add it to `.gitignore`.

#### Option 3: CI/CD Base64-Encoded Variable (GitLab)

Encode the key:

```bash
cat service-account-key.json | base64 | tr -d '\n'
```

Store the output as `GOOGLEWORKSPACE_CREDENTIALS_B64` in GitLab CI/CD variables (protected + masked). The `.gitlab-ci.yml` in this folder decodes it automatically:

```yaml
before_script:
  - echo "$GOOGLEWORKSPACE_CREDENTIALS_B64" | base64 -d > "${GOOGLEWORKSPACE_CREDENTIALS}"
```

#### Option 4: Workload Identity Federation (keyless — advanced)

Avoids long-lived JSON keys by federating from another identity provider (e.g., AWS, GitHub Actions OIDC):

```hcl
provider "googleworkspace" {
  credentials = file("${path.module}/credential-config.json")
  # credential-config.json is a workload identity pool config, not a service account key
  customer_id             = var.google_workspace_customer_id
  impersonated_user_email = var.google_workspace_admin_email
  oauth_scopes            = [...]
}
```

> **Reference**: [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)

#### Finding Your Customer ID

Your Google Workspace Customer ID (e.g., `C01234567`) can be found at:

- [Google Workspace Admin Console](https://admin.google.com/) → Account → Account settings
- Or via `gcloud organizations list`

---

## GitLab CI/CD

This folder includes a `.gitlab-ci.yml` pipeline configuration that:

- Decodes the Google Workspace service account key from a base64 CI/CD variable
- Runs `validate`, `build` (plan), and `deploy` (apply) stages
- Uses the GitLab HTTP backend for state management

### CI/CD Variables

Set these in your GitLab project (Settings > CI/CD > Variables):

| Variable | Description | Protected | Masked |
|---|---|---|---|
| `TF_STATE_NAME` | Terraform state name | No | No |
| `GOOGLEWORKSPACE_CREDENTIALS_B64` | Base64-encoded service account JSON key | Yes | Yes |
| `TF_VAR_google_workspace_customer_id` | Google Workspace customer ID | No | No |
| `TF_VAR_google_workspace_admin_email` | Admin email for impersonation | No | No |
| `AWS_ACCESS_KEY_ID` | AWS Access Key | Yes | Yes |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | Yes | Yes |

### Scheduled Sync

Configure [scheduled pipelines](https://docs.gitlab.com/ci/pipelines/schedules/) for continuous synchronisation:

| Frequency | Cron Expression | Use Case |
|---|---|---|
| Every 4 hours | `0 */4 * * *` | High-volatility orgs |
| Daily at 2 AM | `0 2 * * *` | Most organisations (recommended) |
| Weekly (Sunday) | `0 2 * * 0` | Low-volatility orgs |

---

## Files

| File | Purpose |
|---|---|
| `main.tf` | Provider config, backend, and module call |
| `variables.tf` | Provider and module input variables |
| `terraform.tfvars.example` | Example variable values |
| `.gitlab-ci.yml` | GitLab CI/CD pipeline for automated sync |
