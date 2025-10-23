# n8n Platform - Kubernetes Deployment Guide

## Overview

This document describes the Kubernetes deployment setup for n8n automation platform on AWS EKS using Helm charts and GitHub Actions CI/CD.

## Architecture

### Infrastructure
- **Container Registry**: AWS ECR (ap-east-1)
  - Repository: `n8n-platform`
  - Tags: `staging`, `production`
- **Kubernetes Clusters**:
  - Staging: `f4fpay-staging-20250109` (us-east-1)
  - Production: `f4fpay-production-20230709` (us-east-1)
- **Domains**:
  - Staging: `staging-n8n.first4figures.com`
  - Production: `n8n.first4figures.com`

### Components
1. **n8n Application**: Automation platform
2. **PostgreSQL**: Database (StatefulSet with persistent storage)
3. **Ingress**: Nginx ingress controller with Let's Encrypt TLS
4. **Monitoring**: Datadog APM integration

## Directory Structure

```
infra/deployment/
├── staging/
│   └── k8s/
│       ├── Chart.yaml              # Helm chart metadata
│       ├── values.yaml             # Staging configuration
│       ├── .helmignore
│       └── templates/
│           ├── _helpers.tpl        # Template helpers
│           ├── deployment.yaml     # n8n deployment
│           ├── postgres-statefulset.yaml  # PostgreSQL
│           ├── service.yaml        # Services
│           ├── ingress.yaml        # Ingress rules
│           ├── secrets.yaml        # Secrets template
│           ├── serviceaccount.yaml # Service account
│           ├── hpa.yaml            # Horizontal Pod Autoscaler
│           ├── NOTES.txt           # Post-install notes
│           └── tests/
│               └── test-connection.yaml
└── production/
    └── k8s/                        # Same structure as staging
```

## GitHub Actions Workflows

### CI Workflow (`.github/workflows/ci.yml`)
Triggers on push/PR to main:
- Validates Helm chart syntax
- Builds Dockerfile to verify it compiles
- Runs on every commit

### Deploy Workflow (`.github/workflows/deploy.yml`)
Triggers on:
- **Automatic**: After CI passes on main branch
- **Manual**: Via GitHub Actions UI (workflow_dispatch)
- **PR Comment**: Comment `/deploy:staging` on a PR

#### Deployment Flow
1. **Staging Deployment**:
   - Checkout code
   - Configure AWS credentials (assume role)
   - Login to ECR (ap-east-1)
   - Build and push Docker image tagged as `staging`
   - Configure kubectl for staging EKS cluster
   - Install Helm
   - Deploy using `helm upgrade --install`

2. **Production Deployment** (Currently commented out):
   - Same steps as staging but for production
   - Only runs after staging succeeds
   - Will be enabled once staging is validated

## GitHub Secrets Configuration

### Required Secrets

Add these secrets to your GitHub repository settings:

#### AWS Credentials
```
DEPLOY_AWS_ACCESS_KEY_ID         # AWS access key for deployment
DEPLOY_AWS_SECRET_ACCESS_KEY     # AWS secret key for deployment
DEPLOY_AWS_ROLE_ARN              # ARN of role to assume for deployment
```

#### Staging Environment
```
STAGING_POSTGRES_PASSWORD        # PostgreSQL password for staging
STAGING_N8N_ENCRYPTION_KEY       # n8n encryption key (generate with: openssl rand -hex 32)
STAGING_N8N_BASIC_AUTH_USER      # n8n basic auth username
STAGING_N8N_BASIC_AUTH_PASSWORD  # n8n basic auth password
```

#### Production Environment (For future use)
```
PRODUCTION_POSTGRES_PASSWORD        # PostgreSQL password for production
PRODUCTION_N8N_ENCRYPTION_KEY       # n8n encryption key (different from staging!)
PRODUCTION_N8N_BASIC_AUTH_USER      # n8n basic auth username
PRODUCTION_N8N_BASIC_AUTH_PASSWORD  # n8n basic auth password
```

### Generating Secrets

```bash
# Generate encryption key
openssl rand -hex 32

# Generate random password
openssl rand -base64 24
```

## Manual Deployment

### Prerequisites
- kubectl configured with EKS cluster access
- Helm 3.11.1 or later installed
- AWS CLI configured

### Deploy to Staging

```bash
# 1. Login to ECR
aws ecr get-login-password --region ap-east-1 | \
  docker login --username AWS --password-stdin \
  169829274692.dkr.ecr.ap-east-1.amazonaws.com

# 2. Build and push image
docker build -t 169829274692.dkr.ecr.ap-east-1.amazonaws.com/n8n-platform:staging \
  -f Dockerfile.k8s .
docker push 169829274692.dkr.ecr.ap-east-1.amazonaws.com/n8n-platform:staging

# 3. Configure kubectl
aws eks update-kubeconfig --name f4fpay-staging-20250109 --region us-east-1

# 4. Deploy with Helm
cd infra/deployment/staging
helm upgrade --install n8n-platform-staging k8s \
  --set image.tag="staging" \
  --set postgres.password="YOUR_POSTGRES_PASSWORD" \
  --set n8n.encryptionKey="YOUR_ENCRYPTION_KEY" \
  --set n8n.basicAuth.user="YOUR_USERNAME" \
  --set n8n.basicAuth.password="YOUR_PASSWORD"
```

### Deploy to Production

```bash
# Same steps as staging but use:
# - Image tag: production
# - Cluster: f4fpay-production-20230709
# - Helm release: n8n-platform-production
# - Directory: infra/deployment/production
# - Different secrets!
```

## Helm Configuration

### Key Values (values.yaml)

#### Staging
```yaml
replicaCount: 1                    # Single replica for staging
postgres:
  storage:
    size: 10Gi                     # 10GB for PostgreSQL
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
autoscaling:
  enabled: false                   # Disabled for staging
```

#### Production
```yaml
replicaCount: 2                    # Multiple replicas for HA
postgres:
  storage:
    size: 10Gi                     # 10GB for PostgreSQL
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
autoscaling:
  enabled: false                   # Can be enabled later
  minReplicas: 2
  maxReplicas: 5
```

## Monitoring & Logs

### Check Deployment Status
```bash
# Check pods
kubectl get pods -n default

# Check deployment status
kubectl rollout status deployment/n8n-platform-staging

# Check StatefulSet (PostgreSQL)
kubectl get statefulset -n default
```

### View Logs
```bash
# n8n logs
kubectl logs -f deployment/n8n-platform-staging -c n8n-platform-staging

# PostgreSQL logs
kubectl logs -f n8n-platform-staging-postgres-0

# All containers in pod
kubectl logs -f <pod-name> --all-containers=true
```

### Access n8n
```bash
# Port forward for local testing
kubectl port-forward svc/n8n-platform-staging 5678:5678

# Then access: http://localhost:5678
```

## Troubleshooting

### Pod Not Starting
```bash
# Describe pod for events
kubectl describe pod <pod-name>

# Check init container logs
kubectl logs <pod-name> -c wait-for-postgres
```

### Database Connection Issues
```bash
# Check PostgreSQL is running
kubectl get statefulset
kubectl logs n8n-platform-staging-postgres-0

# Test connection from n8n pod
kubectl exec -it <n8n-pod> -- nc -zv n8n-platform-staging-postgres 5432
```

### Ingress/TLS Issues
```bash
# Check ingress
kubectl get ingress
kubectl describe ingress n8n-platform-staging-ingress

# Check cert-manager certificate
kubectl get certificate
kubectl describe certificate n8n-platform-staging-tls
```

### Image Pull Errors
```bash
# Verify ECR login credentials
kubectl get secret n8n-platform-staging-ecr -o yaml

# Check if image exists in ECR
aws ecr describe-images --repository-name n8n-platform --region ap-east-1
```

## Rollback

### Rollback Deployment
```bash
# View rollout history
kubectl rollout history deployment/n8n-platform-staging

# Rollback to previous version
kubectl rollout undo deployment/n8n-platform-staging

# Rollback to specific revision
kubectl rollout undo deployment/n8n-platform-staging --to-revision=2
```

### Rollback with Helm
```bash
# List releases
helm list

# Rollback to previous release
helm rollback n8n-platform-staging

# Rollback to specific revision
helm rollback n8n-platform-staging 2
```

## Backup & Restore

### Backup PostgreSQL Data
```bash
# Backup database
kubectl exec n8n-platform-staging-postgres-0 -- \
  pg_dump -U n8n n8n > n8n-backup-$(date +%Y%m%d).sql

# Backup PVC (using a backup tool or snapshot)
kubectl get pvc
# Use AWS EBS snapshot for the underlying volume
```

### Restore PostgreSQL Data
```bash
# Restore from backup
kubectl exec -i n8n-platform-staging-postgres-0 -- \
  psql -U n8n n8n < n8n-backup-20250423.sql
```

## Scaling

### Manual Scaling
```bash
# Scale n8n replicas
kubectl scale deployment/n8n-platform-staging --replicas=3

# Or using Helm
helm upgrade n8n-platform-staging k8s \
  --reuse-values \
  --set replicaCount=3
```

### Enable Autoscaling
```bash
# Edit values.yaml and set autoscaling.enabled=true
# Then upgrade
helm upgrade n8n-platform-staging k8s \
  --reuse-values \
  --set autoscaling.enabled=true
```

## Security Considerations

1. **Secrets Management**: All secrets passed via `--set` during deployment
2. **Network Policies**: Consider adding network policies for production
3. **RBAC**: Service account with minimal permissions
4. **TLS**: Automatic TLS via cert-manager and Let's Encrypt
5. **Image Security**: Official n8n image used, scan regularly
6. **Database**: PostgreSQL runs in cluster with persistent storage

## Maintenance

### Update n8n Version
```bash
# Update image in ECR (build new version)
# Or change values.yaml image.tag to specific version

helm upgrade n8n-platform-staging k8s \
  --reuse-values \
  --set image.tag="1.45.0"  # Specific version
```

### Update Helm Chart
```bash
# Make changes to templates or values
# Then upgrade
helm upgrade n8n-platform-staging ./k8s --reuse-values
```

## Production Readiness Checklist

Before enabling production deployment:

- [ ] Staging environment validated and stable
- [ ] All production secrets configured in GitHub
- [ ] Production database backup strategy in place
- [ ] Monitoring and alerting configured
- [ ] Resource limits tested and optimized
- [ ] Ingress and TLS certificates working
- [ ] Disaster recovery plan documented
- [ ] Team trained on deployment and rollback procedures
- [ ] Uncomment production job in `.github/workflows/deploy.yml`

## Support

For issues or questions:
- Review logs using commands above
- Check Helm chart templates in `infra/deployment/*/k8s/templates/`
- Verify GitHub Actions workflow runs
- Consult n8n documentation: https://docs.n8n.io/
