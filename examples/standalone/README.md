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

The standalone example uses the GitLab HTTP backend (`backend "http" {}`). To use it with GitLab CI/CD:

1. Copy the `.gitlab-ci.yml` from the repository root
2. Set the required CI/CD variables (see root README)
3. Optionally configure scheduled pipelines for continuous sync

## Files

| File | Purpose |
|---|---|
| `main.tf` | Provider config, backend, and module call |
| `variables.tf` | Provider and module input variables |
| `terraform.tfvars.example` | Example variable values |
