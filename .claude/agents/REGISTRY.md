# Agent Registry

## Available Specialist Agents

### Infrastructure Agent
**File**: `infrastructure.md`
**Role**: Docker, Docker Compose, container orchestration, volume management
**Use when**:
- Modifying docker-compose.yml
- Working with container configuration
- Managing volumes and networks
- Troubleshooting container issues

### Database Agent
**File**: `database.md`
**Role**: PostgreSQL administration, schema changes, backups, queries
**Use when**:
- Working with database schema
- Modifying init-data.sql
- Database migrations
- Backup/restore operations
- Performance tuning

### n8n Agent
**File**: `n8n.md`
**Role**: n8n configuration, workflows, integrations, troubleshooting
**Use when**:
- Configuring n8n settings
- Working with n8n environment variables
- Troubleshooting workflow issues
- n8n version updates

## Coordinator Role
The Coordinator (default) handles:
- Task routing to specialist agents
- Cross-domain tasks
- General project coordination
- Documentation updates
- Initial task assessment

## Task Routing Guidelines
1. Assess the task domain
2. Route to specialist if task is domain-specific
3. Handle coordination tasks directly
4. Keep todo.json updated throughout
5. Use recall MCP to maintain project knowledge
