# Production Deployment Plan for n8n Platform

## Overview
Deploy n8n to the **f4fpay-production-20230709** EKS cluster using all learnings from staging deployment. This includes infrastructure preparation, GitHub configuration, and deployment activation.

---

## Phase 1: Production Cluster Infrastructure Setup

### 1.1 Switch kubectl Context to Production
```bash
kubectl config use-context arn:aws:eks:us-east-1:169829274692:cluster/f4fpay-production-20230709
```

### 1.2 Install EBS CSI Driver Addon
```bash
aws eks create-addon \
  --cluster-name f4fpay-production-20230709 \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1
```
**Wait for addon to be active (5 pods running)**

### 1.3 Identify Production Node IAM Role
```bash
kubectl get nodes -o yaml | grep "iam.amazonaws.com/role"
# OR check EKS console for node group IAM role
```

### 1.4 Attach EBS CSI Driver Policy to Node Role
```bash
aws iam attach-role-policy \
  --role-name <PRODUCTION-NODE-ROLE-NAME> \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region us-east-1
```

### 1.5 Create gp2-csi Storage Class
```bash
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2-csi
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF
```

### 1.6 Create ECR ImagePullSecret
```bash
ECR_PASSWORD=$(aws ecr get-login-password --region ap-east-1)
kubectl create secret docker-registry n8n-platform-production-ecr \
  --docker-server=169829274692.dkr.ecr.ap-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD"
```

---

## Phase 2: GitHub Secrets Configuration

### 2.1 Required Production Secrets
Add the following secrets in GitHub repository settings under **Settings → Secrets → Actions**:

| Secret Name | Description | Example/Notes |
|-------------|-------------|---------------|
| `PRODUCTION_POSTGRES_PASSWORD` | PostgreSQL database password | Strong random password (32+ chars) |
| `PRODUCTION_N8N_ENCRYPTION_KEY` | n8n credentials encryption | `openssl rand -base64 32` |
| `PRODUCTION_N8N_BASIC_AUTH_USER` | n8n web UI username | e.g., `f4fn8nadmin` |
| `PRODUCTION_N8N_BASIC_AUTH_PASSWORD` | n8n web UI password | Strong random password |

**Note**: AWS credentials (`DEPLOY_AWS_ACCESS_KEY_ID`, `DEPLOY_AWS_SECRET_ACCESS_KEY`, `DEPLOY_AWS_ROLE_ARN`) should already exist from staging setup.

---

## Phase 3: Enable Production Deployment in GitHub Actions

### 3.1 Uncomment Production Job
Edit `.github/workflows/deploy.yml` lines 125-199:
- Remove the `#` comment markers from the entire `deploy_production` job
- This enables production deployment after staging succeeds

### 3.2 Commit the Changes
```bash
git add .github/workflows/deploy.yml
git commit -m "Enable production deployment for n8n platform

- Uncomment deploy_production job in GitHub Actions
- Production deploys after staging validation succeeds
- Cluster: f4fpay-production-20230709
- Domain: n8n.first4figures.com"
git push origin main
```

---

## Phase 4: Verify Pre-Deployment Checklist

### 4.1 DNS Configuration
**Verify** that `n8n.first4figures.com` DNS record points to the production EKS ingress load balancer.

### 4.2 Let's Encrypt Issuer
**Verify** that `letsencrypt-production` ClusterIssuer exists:
```bash
kubectl get clusterissuer letsencrypt-production
```

### 4.3 Nginx Ingress Controller
**Verify** nginx ingress controller is installed:
```bash
kubectl get pods -n ingress-nginx
```

### 4.4 Cert-Manager
**Verify** cert-manager is installed:
```bash
kubectl get pods -n cert-manager
```

---

## Phase 5: Trigger Production Deployment

### 5.1 Automatic Deployment
Push any commit to `main` branch:
- CI workflow runs and validates Helm charts
- Upon CI success, Deploy workflow triggers
- Staging deploys first
- After staging succeeds, production deploys automatically

### 5.2 Monitor Deployment
```bash
# Watch GitHub Actions
gh run watch

# Monitor pods in production cluster
kubectl get pods -w | grep n8n-platform

# Check deployment status
kubectl describe deployment n8n-platform-production

# Check PVC provisioning
kubectl get pvc | grep n8n
```

---

## Phase 6: Post-Deployment Verification

### 6.1 Check Pod Status
```bash
kubectl get pods | grep n8n-platform
```
**Expected**: 2 n8n pods (READY: 1/1), 1 postgres pod (READY: 1/1)

### 6.2 Check Persistent Volumes
```bash
kubectl get pvc
```
**Expected**: All PVCs in `Bound` status with `gp2-csi` storage class

### 6.3 Check Ingress and TLS
```bash
kubectl get ingress n8n-platform-production-ingress
kubectl get certificate n8n-platform-production-tls
```
**Expected**: Certificate READY: True

### 6.4 Verify Application Access
- Visit **https://n8n.first4figures.com**
- Verify TLS certificate is valid (Let's Encrypt Production)
- Login with production basic auth credentials
- Create a test workflow to verify functionality

### 6.5 Check Logs
```bash
kubectl logs -f deployment/n8n-platform-production -c n8n-platform-production
kubectl logs -f n8n-platform-production-postgres-0
```

---

## Known Issues & Mitigation

### Issue 1: Multi-Attach Volume Errors During Rolling Updates
**Symptom**: New pods stuck with "Volume is already used by pod(s)"
**Cause**: RWO volumes can only attach to one pod at a time
**Solution**:
```bash
# Delete old failing pods manually
kubectl delete pod <OLD-POD-NAME>
```

### Issue 2: Permissions Errors
**Symptom**: "EACCES: permission denied"
**Cause**: Missing fsGroup in pod security context
**Solution**: Already fixed in values.yaml (`podSecurityContext.fsGroup: 1000`)

### Issue 3: PVCs Stuck Pending
**Symptom**: PVCs show "Waiting for external provisioner"
**Cause**: Missing EBS CSI driver or IAM permissions
**Solution**: Ensure Phase 1 steps 1.2-1.4 completed successfully

---

## Rollback Plan

If production deployment fails:

### 1. Scale Down Production Deployment
```bash
kubectl scale deployment n8n-platform-production --replicas=0
```

### 2. Delete Failed Resources
```bash
kubectl delete deployment n8n-platform-production
kubectl delete pvc n8n-platform-production-data
kubectl delete pvc postgres-data-n8n-platform-production-postgres-0
kubectl delete statefulset n8n-platform-production-postgres
```

### 3. Re-comment Production Job
Edit `.github/workflows/deploy.yml` and re-add `#` comments to lines 125-199

### 4. Investigate and Fix
Review logs, fix issues, then retry deployment

---

## Success Criteria

✅ **Infrastructure Ready**:
- EBS CSI driver installed and running (5 pods)
- gp2-csi storage class created
- Node IAM role has EBS CSI policy attached
- ECR imagePullSecret created

✅ **Deployment Successful**:
- 2 n8n pods running and ready
- 1 PostgreSQL pod running and ready
- All PVCs bound with correct storage class
- TLS certificate issued and valid

✅ **Application Functional**:
- https://n8n.first4figures.com accessible
- Basic authentication working
- Can create and execute workflows
- Data persists after pod restarts

---

## Estimated Timeline

- **Phase 1** (Infrastructure): 10-15 minutes
- **Phase 2** (GitHub Secrets): 5 minutes
- **Phase 3** (Enable Deployment): 2 minutes
- **Phase 4** (Pre-Deployment Checks): 5 minutes
- **Phase 5** (Deployment Execution): 5-10 minutes
- **Phase 6** (Verification): 10 minutes

**Total**: ~40-50 minutes

---

## Next Steps After Deployment

1. **Monitor Production**: Set up alerts for pod health, disk usage
2. **Backup Strategy**: Configure automated PostgreSQL backups
3. **Scaling**: Consider enabling HPA (already configured in values.yaml)
4. **Documentation**: Update runbook with production-specific procedures
5. **Security Audit**: Review RBAC, network policies, secrets rotation

---

## Key Differences: Staging vs Production

| Aspect | Staging | Production |
|--------|---------|------------|
| **Cluster** | f4fpay-staging-20250109 | f4fpay-production-20230709 |
| **Domain** | staging-n8n.first4figures.com | n8n.first4figures.com |
| **Image Tag** | staging | production |
| **Replicas** | 1 | 2 |
| **Resources** | 1Gi RAM / 500m CPU | 2Gi RAM / 1000m CPU |
| **TLS Issuer** | letsencrypt-staging | letsencrypt-production |
| **HPA** | Disabled | Disabled (can enable) |

---

## Infrastructure Checklist (Completed in Staging)

These same steps must be performed on production cluster:

- [x] **Staging**: EBS CSI driver installed ✅
- [ ] **Production**: EBS CSI driver installation pending
- [x] **Staging**: gp2-csi storage class created ✅
- [ ] **Production**: gp2-csi storage class creation pending
- [x] **Staging**: Node IAM role has EBS CSI policy ✅
- [ ] **Production**: Node IAM role policy attachment pending
- [x] **Staging**: ECR imagePullSecret created ✅
- [ ] **Production**: ECR imagePullSecret creation pending

---

## Critical Staging Learnings Applied

### 1. EBS CSI Driver is Required
Without this, PVCs will remain in Pending state indefinitely.

### 2. IAM Policy is Critical
Node role needs `AmazonEBSCSIDriverPolicy` or volumes won't provision.

### 3. Storage Class Must Use CSI Provisioner
Old `kubernetes.io/aws-ebs` provisioner doesn't work. Must use `ebs.csi.aws.com`.

### 4. Pod Security Context is Essential
`fsGroup: 1000` at pod level ensures mounted volumes have correct ownership.

### 5. RWO Volume Limitations
During rolling updates, manually delete old pods to release volumes for new pods.

### 6. Helm v3 Compatibility
Use `{{ now | date "20060102150405" }}` instead of `.Release.Time`.

---

## Production-Specific Considerations

### High Availability
- 2 replicas ensure zero-downtime during pod failures
- Consider enabling HPA for traffic-based scaling
- Set appropriate pod disruption budgets

### Performance
- Higher resource limits (2Gi RAM, 1 CPU)
- PostgreSQL tuning may be needed based on usage
- Monitor and adjust based on actual workload

### Security
- Production TLS certificates (not staging)
- Strong passwords for all services
- Regular security audits
- Consider network policies for pod isolation

### Monitoring
- Set up CloudWatch alarms for pod health
- Monitor disk usage on PVCs
- Track n8n workflow execution metrics
- Set up log aggregation (CloudWatch Logs)

### Backup & Recovery
- Automated PostgreSQL backups to S3
- Test restore procedures regularly
- Document RTO/RPO requirements
- Consider cross-region backup replication

---

## Contact & Support

For issues during deployment:
1. Check GitHub Actions workflow logs
2. Review pod logs: `kubectl logs`
3. Check events: `kubectl get events --sort-by='.lastTimestamp'`
4. Verify infrastructure prerequisites completed
5. Compare with successful staging deployment
