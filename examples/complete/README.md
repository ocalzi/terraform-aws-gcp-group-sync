# Complete Example: GCP to AWS Identity Center Group Sync

This example demonstrates how to consume the [`ocalzi/gcp-group-sync/aws`](https://registry.terraform.io/modules/ocalzi/gcp-group-sync/aws/latest) module from the Terraform Registry.

## Usage

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

## Prerequisites

1. **AWS Identity Center** enabled with SCIM sync from Google Workspace (users must be synced first)
2. **Google Workspace** service account with Domain-Wide Delegation and the required API scopes
3. Both **providers configured by the caller** — see the provider blocks in [`main.tf`](main.tf)

## Provider Configuration

The caller is responsible for configuring both the `aws` and `googleworkspace` providers. This example shows a typical setup:

- **AWS**: region + default tags (credentials via environment or SSO)
- **Google Workspace**: customer ID, impersonated admin email, OAuth scopes

For detailed authentication options (IAM roles, SSO, Workload Identity Federation, etc.), see the [`examples/standalone/`](../standalone/) README.

## Running This Example

```bash
cd examples/complete

# Configure providers (environment variables, SSO, etc.)
export AWS_REGION="eu-west-3"
export GOOGLEWORKSPACE_CREDENTIALS="/path/to/service-account-key.json"

terraform init
terraform plan
terraform apply
```

## Outputs

| Output | Description |
|---|---|
| `sync_summary` | Group count, membership count, active users found |
| `aws_groups` | AWS Identity Center groups created |
| `gcp_groups` | Google Workspace groups that were synced |
