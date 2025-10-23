# Required GitHub Secrets for n8n Deployment

This document lists all GitHub Secrets that must be configured before deploying n8n.

## Go to: https://github.com/First4Figures/n8n.first4figures.com/settings/secrets/actions

---

## Staging Environment Secrets

### Database Configuration (RDS)

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `STAGING_DB_HOST` | `tf-staging-api-figgyz-com-postgresql.cluster-c7nppfw6qj2v.us-east-1.rds.amazonaws.com` | RDS endpoint for staging |
| `STAGING_DB_PORT` | `5432` | PostgreSQL port |
| `STAGING_DB_NAME` | `n8n` | Database name |
| `STAGING_DB_USER` | `n8nstaging` | Database username |
| `STAGING_DB_PASSWORD` | `d96c87f68c697976da79b430a29ab5666590c5c617b33e68b76eba50587a9b7f` | Database password |

### n8n Application Configuration

| Secret Name | Value | Notes |
|-------------|-------|-------|
| `STAGING_N8N_ENCRYPTION_KEY` | *(existing value - do not change)* | Encryption key for credentials |
| `STAGING_N8N_BASIC_AUTH_USER` | *(existing value - do not change)* | Web UI username |
| `STAGING_N8N_BASIC_AUTH_PASSWORD` | *(existing value - do not change)* | Web UI password |

### AWS Deployment Credentials

| Secret Name | Notes |
|-------------|-------|
| `DEPLOY_AWS_ACCESS_KEY_ID` | *(existing - already configured)* |
| `DEPLOY_AWS_SECRET_ACCESS_KEY` | *(existing - already configured)* |
| `DEPLOY_AWS_ROLE_ARN` | *(existing - already configured)* |

---

## Production Environment Secrets (For Future Deployment)

### Database Configuration (RDS)

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `PRODUCTION_DB_HOST` | `<production-rds-endpoint>` | RDS endpoint for production |
| `PRODUCTION_DB_PORT` | `5432` | PostgreSQL port |
| `PRODUCTION_DB_NAME` | `n8n` | Database name |
| `PRODUCTION_DB_USER` | `n8nproduction` | Database username |
| `PRODUCTION_DB_PASSWORD` | `<generate-strong-password>` | Database password |

### n8n Application Configuration

| Secret Name | Notes |
|-------------|-------|
| `PRODUCTION_N8N_ENCRYPTION_KEY` | Generate new: `openssl rand -base64 32` |
| `PRODUCTION_N8N_BASIC_AUTH_USER` | e.g., `f4fn8nadmin` |
| `PRODUCTION_N8N_BASIC_AUTH_PASSWORD` | Generate strong password |

---

## How to Add/Update Secrets

1. Go to: https://github.com/First4Figures/n8n.first4figures.com/settings/secrets/actions
2. Click "New repository secret" or "Update" for existing secrets
3. Enter the secret name (exactly as shown above)
4. Enter the secret value
5. Click "Add secret" or "Update secret"

---

## Verification Checklist

Before deploying, verify all required secrets are configured:

### Staging Deployment:
- [ ] `STAGING_DB_HOST`
- [ ] `STAGING_DB_PORT`
- [ ] `STAGING_DB_NAME`
- [ ] `STAGING_DB_USER`
- [ ] `STAGING_DB_PASSWORD`
- [ ] `STAGING_N8N_ENCRYPTION_KEY`
- [ ] `STAGING_N8N_BASIC_AUTH_USER`
- [ ] `STAGING_N8N_BASIC_AUTH_PASSWORD`
- [ ] `DEPLOY_AWS_ACCESS_KEY_ID`
- [ ] `DEPLOY_AWS_SECRET_ACCESS_KEY`
- [ ] `DEPLOY_AWS_ROLE_ARN`

### Production Deployment (when ready):
- [ ] `PRODUCTION_DB_HOST`
- [ ] `PRODUCTION_DB_PORT`
- [ ] `PRODUCTION_DB_NAME`
- [ ] `PRODUCTION_DB_USER`
- [ ] `PRODUCTION_DB_PASSWORD`
- [ ] `PRODUCTION_N8N_ENCRYPTION_KEY`
- [ ] `PRODUCTION_N8N_BASIC_AUTH_USER`
- [ ] `PRODUCTION_N8N_BASIC_AUTH_PASSWORD`

---

## Security Notes

- ✅ **Database credentials**: No longer hardcoded in values.yaml
- ✅ **All sensitive values**: Managed as GitHub Secrets
- ✅ **Per-environment**: Separate secrets for staging and production
- ✅ **RDS isolation**: Dedicated database users (n8nstaging, n8nproduction)
- ⚠️ **Encryption key**: NEVER change in production (will lose access to encrypted credentials)
- ⚠️ **Password rotation**: Update both GitHub Secret AND RDS user password together

---

## RDS User Creation Commands

### Staging (Already Done)
```sql
-- User and database already created
-- n8nstaging user with password: d96c87f68c697976da79b430a29ab5666590c5c617b33e68b76eba50587a9b7f
```

### Production (Future)
```sql
-- Connect to production RDS
CREATE USER n8nproduction WITH PASSWORD '<PRODUCTION_DB_PASSWORD>';
CREATE DATABASE n8n OWNER n8nproduction;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8nproduction;
\c n8n
GRANT ALL PRIVILEGES ON SCHEMA public TO n8nproduction;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO n8nproduction;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO n8nproduction;
```
