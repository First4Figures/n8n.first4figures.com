# n8n Self-Hosted Setup with PostgreSQL

## Deployment Options

This project supports two deployment methods:

1. **Local Development** - Docker Compose (see below)
2. **Production** - Kubernetes on AWS EKS (see [DEPLOYMENT.md](DEPLOYMENT.md))

## Local Development - Quick Start

1. **Configure environment variables**
   - Edit `.env` file and update the following:
     - `POSTGRES_PASSWORD` - Set a secure password for PostgreSQL root user
     - `POSTGRES_NON_ROOT_PASSWORD` - Set a secure password for n8n database user
     - `N8N_BASIC_AUTH_PASSWORD` - Set a secure password for n8n web interface
     - `N8N_ENCRYPTION_KEY` - Generate a random encryption key:
       ```bash
       openssl rand -hex 32
       ```

2. **Start the services**
   ```bash
   docker-compose up -d
   ```

3. **Access n8n**
   - Open your browser and navigate to: http://localhost:5678
   - Login with:
     - Username: `admin` (as configured in .env)
     - Password: Your configured password

## Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# n8n only
docker-compose logs -f n8n

# PostgreSQL only
docker-compose logs -f postgres
```

### Restart services
```bash
docker-compose restart
```

### Update n8n to latest version
```bash
docker-compose pull n8n
docker-compose up -d n8n
```

## Data Persistence

- **n8n data**: Stored in Docker volume `n8n-data`
- **PostgreSQL data**: Stored in Docker volume `postgres-data`
- **n8n files**: Stored in `./n8n-files` directory

## Backup

### Backup PostgreSQL database
```bash
docker-compose exec postgres pg_dump -U postgres n8n > backup.sql
```

### Restore PostgreSQL database
```bash
docker-compose exec -T postgres psql -U postgres n8n < backup.sql
```

## Security Considerations

1. Always change default passwords in production
2. Use HTTPS in production (configure reverse proxy like nginx/traefik)
3. Keep n8n and PostgreSQL updated regularly
4. Regular backups of your data

## Kubernetes Deployment

For production deployment to AWS EKS, see the comprehensive guide:

📖 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Full Kubernetes deployment documentation

### Quick Overview

- **CI/CD**: GitHub Actions automated deployment
- **Staging**: `staging-n8n.first4figures.com`
- **Production**: `n8n.first4figures.com`
- **Infrastructure**: Helm charts in `infra/deployment/`
- **Database**: PostgreSQL StatefulSet with persistent storage

### Deploy to Staging

Deployments are automated via GitHub Actions. Manual deployment:

```bash
# See DEPLOYMENT.md for detailed instructions
cd infra/deployment/staging
helm upgrade --install n8n-platform-staging k8s [options]
```

## Troubleshooting

### Local Development

#### Reset everything
```bash
docker-compose down -v
rm -rf n8n-files/*
docker-compose up -d
```

#### Check service health
```bash
docker-compose ps
```

### Kubernetes Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for Kubernetes troubleshooting guides including:
- Pod startup issues
- Database connection problems
- Ingress/TLS configuration
- Rollback procedures