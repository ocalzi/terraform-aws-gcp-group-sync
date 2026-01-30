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

# Set credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export GOOGLEWORKSPACE_CREDENTIALS="./path-to-service-account-key.json"

# Run
terraform init
terraform plan
terraform apply
```

## GitLab CI/CD

This folder includes a `.gitlab-ci.yml` pipeline configuration that:

- Decodes the Google Workspace service account key from a base64 CI/CD variable
- Runs `validate`, `build` (plan), and `deploy` (apply) stages
- Uses the GitLab HTTP backend for state management

### Setup

1. Set the required CI/CD variables in your GitLab project (Settings > CI/CD > Variables):

   | Variable | Description | Protected | Masked |
   |---|---|---|---|
   | `TF_STATE_NAME` | Terraform state name | No | No |
   | `GOOGLEWORKSPACE_CREDENTIALS_B64` | Base64-encoded service account JSON key | Yes | Yes |
   | `TF_VAR_google_workspace_customer_id` | Google Workspace customer ID | No | No |
   | `TF_VAR_google_workspace_admin_email` | Admin email for impersonation | No | No |
   | `AWS_ACCESS_KEY_ID` | AWS Access Key | Yes | Yes |
   | `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | Yes | Yes |

2. Optionally configure [scheduled pipelines](https://docs.gitlab.com/ci/pipelines/schedules/) for continuous sync (e.g., daily at 2 AM: `0 2 * * *`)

## Files

| File | Purpose |
|---|---|
| `main.tf` | Provider config, backend, and module call |
| `variables.tf` | Provider and module input variables |
| `terraform.tfvars.example` | Example variable values |
| `.gitlab-ci.yml` | GitLab CI/CD pipeline for automated sync |
