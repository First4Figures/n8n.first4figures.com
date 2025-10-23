# Pre-Deployment Checklist

Use this checklist before deploying n8n to Kubernetes for the first time.

## ☐ AWS Setup

### ECR Repository
- [ ] Create ECR repository in ap-east-1 region
  ```bash
  aws ecr create-repository \
    --repository-name n8n-platform \
    --region ap-east-1 \
    --image-scanning-configuration scanOnPush=true
  ```
- [ ] Verify repository created: `aws ecr describe-repositories --region ap-east-1`

### IAM Permissions
- [ ] Verify deployment IAM role exists
- [ ] Check role has ECR push permissions
- [ ] Check role has EKS access permissions
- [ ] Test role assumption works
  ```bash
  aws sts assume-role --role-arn <DEPLOY_AWS_ROLE_ARN> --role-session-name test
  ```

### EKS Cluster Access
- [ ] Staging cluster accessible: `aws eks describe-cluster --name f4fpay-staging-20250109 --region us-east-1`
- [ ] Production cluster accessible: `aws eks describe-cluster --name f4fpay-production-20230709 --region us-east-1`
- [ ] kubectl configured: `aws eks update-kubeconfig --name f4fpay-staging-20250109 --region us-east-1`
- [ ] Can list pods: `kubectl get pods -n default`

## ☐ GitHub Configuration

### Repository Setup
- [ ] Repository exists and accessible
- [ ] Main branch protected (if desired)
- [ ] GitHub Actions enabled

### Secrets Configuration
- [ ] Navigate to Settings → Secrets and variables → Actions
- [ ] Add AWS secrets:
  - [ ] `DEPLOY_AWS_ACCESS_KEY_ID`
  - [ ] `DEPLOY_AWS_SECRET_ACCESS_KEY`
  - [ ] `DEPLOY_AWS_ROLE_ARN`

- [ ] Generate and add staging secrets:
  ```bash
  # PostgreSQL password
  openssl rand -base64 24

  # n8n encryption key
  openssl rand -hex 32

  # Basic auth password
  openssl rand -base64 24
  ```
  - [ ] `STAGING_POSTGRES_PASSWORD`
  - [ ] `STAGING_N8N_ENCRYPTION_KEY`
  - [ ] `STAGING_N8N_BASIC_AUTH_USER` (e.g., "admin")
  - [ ] `STAGING_N8N_BASIC_AUTH_PASSWORD`

- [ ] Verify all secrets added: Settings → Secrets → Actions (should show 8 secrets)

## ☐ DNS Configuration

### Staging Domain
- [ ] DNS record exists for `staging-n8n.first4figures.com`
- [ ] Record points to staging cluster load balancer OR
- [ ] Plan to update DNS after ingress IP is available
- [ ] Test DNS resolution: `nslookup staging-n8n.first4figures.com`

### Production Domain (For later)
- [ ] DNS record planned for `n8n.first4figures.com`
- [ ] Domain ownership verified

## ☐ Kubernetes Cluster Preparation

### cert-manager (for TLS certificates)
- [ ] cert-manager installed in cluster
  ```bash
  kubectl get pods -n cert-manager
  ```
- [ ] If not installed, install it:
  ```bash
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
  ```
- [ ] Verify cert-manager running:
  ```bash
  kubectl get pods -n cert-manager
  ```

### Nginx Ingress Controller
- [ ] Nginx ingress controller installed
  ```bash
  kubectl get pods -n ingress-nginx
  ```
- [ ] Ingress controller has external IP
  ```bash
  kubectl get svc -n ingress-nginx
  ```

### Storage Class
- [ ] Check `gp2` storage class exists
  ```bash
  kubectl get storageclass gp2
  ```
- [ ] Verify it can provision volumes

### Datadog (Optional but recommended)
- [ ] Datadog agent running in cluster
  ```bash
  kubectl get pods -n datadog
  ```
- [ ] Or plan to install Datadog later

## ☐ Local Testing

### Helm Chart Validation
- [ ] Helm installed locally (3.11.1+)
  ```bash
  helm version
  ```
- [ ] Validate staging chart:
  ```bash
  helm lint infra/deployment/staging/k8s/
  ```
- [ ] Validate production chart:
  ```bash
  helm lint infra/deployment/production/k8s/
  ```
- [ ] Template rendering works:
  ```bash
  helm template test infra/deployment/staging/k8s/ \
    --set postgres.password=test \
    --set n8n.encryptionKey=test \
    --set n8n.basicAuth.user=test \
    --set n8n.basicAuth.password=test
  ```

### Dockerfile Build Test
- [ ] Docker installed locally
- [ ] Dockerfile builds successfully:
  ```bash
  docker build -f Dockerfile.k8s -t n8n-platform:test .
  ```

## ☐ Documentation Review

### Read Key Documents
- [ ] Read [DEPLOYMENT.md](DEPLOYMENT.md) - Comprehensive deployment guide
- [ ] Read [GITHUB_SECRETS.md](GITHUB_SECRETS.md) - Secrets configuration
- [ ] Review [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Implementation overview
- [ ] Understand deployment workflow in [.github/workflows/deploy.yml](.github/workflows/deploy.yml)

### Understand Procedures
- [ ] Know how to check deployment status
- [ ] Know how to view logs
- [ ] Know how to rollback deployment
- [ ] Know backup and restore procedures

## ☐ Team Preparation

### Knowledge Transfer
- [ ] Team members aware of new deployment process
- [ ] Access permissions granted to relevant team members
- [ ] Emergency contacts identified

### Communication
- [ ] Stakeholders notified of upcoming deployment
- [ ] Maintenance window scheduled (if needed)
- [ ] Rollback plan communicated

## ☐ Monitoring & Alerting

### Monitoring Setup
- [ ] Datadog dashboards prepared (or plan created)
- [ ] Log aggregation configured
- [ ] Metrics collection verified

### Alerting
- [ ] Critical alerts configured:
  - [ ] Pod restart alerts
  - [ ] High error rate
  - [ ] Database connection failures
  - [ ] Disk space warnings
- [ ] Alert recipients configured

## ☐ Backup Strategy

### Backup Plan
- [ ] Backup procedure documented
- [ ] Backup schedule defined (e.g., daily)
- [ ] Backup retention policy defined
- [ ] Restore procedure tested

### Initial Backup
- [ ] Plan for first backup after deployment
- [ ] Backup storage location identified
- [ ] Backup verification process defined

## ☐ Final Pre-Deployment Checks

### Code Review
- [ ] Review all Helm chart files
- [ ] Review GitHub Actions workflows
- [ ] Review Dockerfile
- [ ] No sensitive data in repository

### Git Repository
- [ ] All changes committed
- [ ] Commit messages clear and descriptive
- [ ] No uncommitted changes
- [ ] Ready to push to main branch

### Risk Assessment
- [ ] Rollback procedure understood
- [ ] Impact of failure assessed
- [ ] Downtime expectations communicated
- [ ] Team available during deployment

## ☐ Deployment Day Preparation

### Pre-Deployment
- [ ] All team members available
- [ ] Monitoring dashboards open
- [ ] kubectl configured and tested
- [ ] AWS credentials verified
- [ ] Communication channel ready (Slack/etc)

### Deployment Checklist
- [ ] Push code to trigger CI/CD
- [ ] Monitor CI workflow
- [ ] Monitor deploy workflow
- [ ] Check pod status
- [ ] Verify ingress created
- [ ] Test HTTPS access
- [ ] Verify basic auth works
- [ ] Create test workflow in n8n
- [ ] Execute test workflow
- [ ] Check logs for errors
- [ ] Verify PostgreSQL data persists

### Post-Deployment
- [ ] Document deployment time and issues
- [ ] Update monitoring dashboards
- [ ] Schedule follow-up review
- [ ] Update this checklist with learnings

## 🚨 Abort Criteria

Stop deployment and rollback if:
- CI workflow fails repeatedly
- Pods fail to start after 10 minutes
- Database connection fails
- Ingress doesn't get external IP after 15 minutes
- TLS certificate provisioning fails
- Critical errors in application logs
- Unable to access n8n interface after 20 minutes

## ✅ Success Criteria

Deployment is successful when:
- All pods running and healthy
- n8n accessible via HTTPS
- TLS certificate valid (Let's Encrypt)
- Basic auth working
- Can create and execute workflows
- Data persists after pod restart
- Logs show no errors
- Database backup successful
- Monitoring shows healthy metrics

---

**Last Updated**: 2025-10-23
**Review Before**: Every deployment
**Estimated Time**: First deployment: 2-3 hours | Subsequent: 30-60 minutes
