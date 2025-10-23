# Global Project Knowledge

## Project Type
Self-hosted n8n automation platform

## Technology Stack
- **Runtime**: Docker, Docker Compose
- **Automation Platform**: n8n (latest)
- **Database**: PostgreSQL 16
- **Infrastructure**: Docker containers with persistent volumes

## Key Directories
- `/infra/` - Infrastructure configuration and scripts
- `/n8n-files/` - n8n file storage
- `.env` - Environment variables (not committed)
- `docker-compose.yml` - Service orchestration

## Services
1. **n8n**: Automation platform on port 5678
2. **postgres**: PostgreSQL database on port 5432

## Common Tasks
- Starting environment: `docker-compose up -d`
- Viewing logs: `docker-compose logs -f`
- Accessing n8n: http://localhost:5678
- Database backups: Using pg_dump via docker-compose exec

## Important Notes
- All data persisted in Docker volumes
- Encryption key required for n8n
- Basic auth configured for web interface
- PostgreSQL has both root and n8n-specific users
