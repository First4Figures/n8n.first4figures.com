# GitHub Secrets Configuration

This document lists all GitHub Secrets that need to be configured for the CI/CD pipeline to work.

## How to Add Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

## Required Secrets

### AWS Deployment Credentials

These credentials are used to authenticate with AWS and deploy to EKS clusters.

| Secret Name | Description | Example/Notes |
|------------|-------------|---------------|
| `DEPLOY_AWS_ACCESS_KEY_ID` | AWS Access Key ID for deployment | `AKIAIOSFODNN7EXAMPLE` |
| `DEPLOY_AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key for deployment | Keep secure, never commit |
| `DEPLOY_AWS_ROLE_ARN` | ARN of IAM role to assume for deployment | `arn:aws:iam::123456789012:role/DeploymentRole` |

**Permissions Required:**
- ECR: `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`, `ecr:PutImage`
- EKS: `eks:DescribeCluster`, `eks:ListClusters`
- AssumeRole permissions for the deployment role

### Staging Environment Secrets

| Secret Name | Description | How to Generate |
|------------|-------------|-----------------|
| `STAGING_POSTGRES_PASSWORD` | PostgreSQL database password for staging | `openssl rand -base64 24` |
| `STAGING_N8N_ENCRYPTION_KEY` | n8n encryption key for credentials | `openssl rand -hex 32` |
| `STAGING_N8N_BASIC_AUTH_USER` | n8n basic auth username | Choose a username (e.g., `admin`) |
| `STAGING_N8N_BASIC_AUTH_PASSWORD` | n8n basic auth password | `openssl rand -base64 24` |

### Production Environment Secrets (For Future Use)

**⚠️ Important:** Use **different** values from staging for security!

| Secret Name | Description | How to Generate |
|------------|-------------|-----------------|
| `PRODUCTION_POSTGRES_PASSWORD` | PostgreSQL database password for production | `openssl rand -base64 24` |
| `PRODUCTION_N8N_ENCRYPTION_KEY` | n8n encryption key for credentials | `openssl rand -hex 32` |
| `PRODUCTION_N8N_BASIC_AUTH_USER` | n8n basic auth username | Choose a username |
| `PRODUCTION_N8N_BASIC_AUTH_PASSWORD` | n8n basic auth password | `openssl rand -base64 24` |

## Generating Secret Values

### Generate Encryption Key
```bash
openssl rand -hex 32
```
Output example: `56a69263fbf7dbb954cc72899020cd1f08e7909bd61b4b4fb31770997bc6e387`

### Generate Secure Password
```bash
openssl rand -base64 24
```
Output example: `8kXqP3mZvN9wYhF2LdGcT5sB`

### Generate Strong Password (Alternative)
```bash
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

## Security Best Practices

1. **Never commit secrets to version control**
   - Always use GitHub Secrets
   - Never hardcode secrets in code or config files

2. **Use different secrets for staging and production**
   - Prevents accidental production access via staging credentials
   - Limits blast radius if staging is compromised

3. **Rotate secrets regularly**
   - Change passwords every 90 days
   - Update secrets in both GitHub and the deployment

4. **Principle of least privilege**
   - AWS IAM roles should have minimum required permissions
   - Use separate roles for staging and production if possible

5. **Audit access**
   - Review who has access to GitHub Secrets
   - Monitor AWS CloudTrail for deployment activities

## Testing Secrets Configuration

After adding all secrets, you can test the configuration by:

1. **Trigger CI workflow**:
   ```bash
   git commit --allow-empty -m "Test CI workflow"
   git push
   ```

2. **Trigger manual deployment**:
   - Go to **Actions** → **Deploy Workflow** → **Run workflow**
   - Select branch: `main`
   - Click **Run workflow**

3. **Check logs**:
   - View the workflow run in GitHub Actions
   - Look for any authentication or secret-related errors

## Troubleshooting

### Error: "Unable to locate credentials"
- Check `DEPLOY_AWS_ACCESS_KEY_ID` and `DEPLOY_AWS_SECRET_ACCESS_KEY` are set
- Verify the AWS credentials are valid

### Error: "Access Denied" when assuming role
- Verify `DEPLOY_AWS_ROLE_ARN` is correct
- Check the IAM role trust policy allows the AWS account to assume it
- Ensure the role has necessary permissions

### Error: "InvalidParameterException" during Helm deployment
- One or more secrets may be missing or empty
- Check all staging/production secrets are configured
- Verify secret names match exactly (case-sensitive)

### Deployment succeeds but n8n doesn't start
- Check `STAGING_N8N_ENCRYPTION_KEY` is a valid 64-character hex string
- Verify database password is correct
- Check pod logs: `kubectl logs -f deployment/n8n-platform-staging`

## Updating Secrets

When you need to update a secret:

1. **Update in GitHub**:
   - Go to repository Settings → Secrets
   - Click on the secret name
   - Update the value
   - Save

2. **Redeploy**:
   - Trigger the deployment workflow manually, OR
   - Push a new commit to trigger automatic deployment

3. **Verify**:
   - Check the deployment completes successfully
   - Test the application with new credentials

## Secret Rotation Schedule

Recommended rotation schedule:

- **Passwords**: Every 90 days
- **Encryption keys**: Annually (requires data migration!)
- **AWS credentials**: Every 180 days or when staff changes

**Note:** Rotating the n8n encryption key requires re-encrypting all stored credentials. Plan carefully!

## References

- [GitHub Encrypted Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [n8n Environment Variables](https://docs.n8n.io/hosting/environment-variables/)
