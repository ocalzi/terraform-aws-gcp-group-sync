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
