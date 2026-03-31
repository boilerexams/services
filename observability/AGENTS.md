# AGENTS.md - Boilerexams Observability & Status Page

This document describes the observability infrastructure for Boilerexams, including the Cachet status page, monitoring stack, and Coolify integration.

## Overview

The observability stack provides monitoring, logging, and status page capabilities for all Boilerexams services, with a focus on tracking the health of services interacting with the `boilerexams-backend-v3` API.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Prometheus** | 9090 | Metrics collection & monitoring |
| **Grafana** | 3000 | Metrics visualization & dashboards |
| **Loki** | 3100 | Log aggregation |
| **Promtail** | N/A | Log shipping to Loki |
| **cAdvisor** | 8080 | Container metrics |
| **Casvisor** | 16001 | Casbin access control visualization |
| **Coolify** | 8000/8443 | Deployment platform & uptime tracker |
| **Cachet** | 8001 | Status page (Boilerexams observability) |

## Quick Commands

```bash
cd services/observability

# Start all services
make up

# Stop all services
make down

# View all logs
make logs

# Show container status
make ps

# Clean up (remove containers and volumes)
make clean
```

## Cachet (Status Page)

Cachet provides a public status page for Boilerexams services.

- **URL**: http://10.0.1.15:8001
- **Admin**: http://10.0.1.15:8001/login
- **Credentials**: admin@example.com / admin123

### Build & Run Cachet Only

```bash
make cachet
```

### View Cachet Logs

```bash
make cachet-logs
```

### Architecture

- **Database**: Shares `coolify-db` (PostgreSQL) with Coolify
- **Dockerfile**: Custom-built from `php:8.4-fpm` (no Docker Hub images)
- **Location**: `services/observability/cachet/`

## Configuration Files

- `docker-compose.yml` - Core observability services
- `docker-compose.override.yml` - Application services (Coolify, Cachet)
- `cachet/` - Custom Cachet build files
  - `Dockerfile` - Container build
  - `conf/` - Nginx, PHP, Supervisor configs
  - `entrypoint.sh` - Database init & migrations
  - `README.md` - Cachet-specific documentation

## Network

All services run on the `observability` Docker network (must be created via `make network`).

## Implementation Plan

### Phase 1: Cachet Setup & Database Configuration

1. **Create the observability network**
   ```bash
   make network
   ```

2. **Start Coolify dependencies** (shared database)
   ```bash
   docker compose up -d coolify-db coolify-redis
   ```

3. **Build and start Cachet**
   ```bash
   make cachet
   ```

4. **Verify Cachet is running**
   ```bash
   docker compose ps cachet
   curl -s http://10.0.1.15:8001 | head -20
   ```

### Phase 2: API Monitoring Configuration

1. **Identify boilerexams-backend-v3 endpoints to monitor**
   - Health check endpoint (e.g., `/health`, `/api/health`)
   - API gateway endpoints
   - Authentication service
   - Core API endpoints

2. **Configure Cachet components**
   - Log into Cachet admin panel at http://10.0.1.15:8001/login
   - Create Components for each monitored service:
     - Backend API (boilerexams-backend-v3)
     - Database
     - Cache/Redis
     - Frontend (if applicable)
   - Create Metrics for response time and uptime
   - Set up Incidents template

3. **Add health check endpoints to backend**
   - Ensure `boilerexams-backend-v3` exposes a `/health` endpoint
   - Configure health check to return JSON with service status

### Phase 3: Coolify Integration

1. **Configure Coolify as uptime monitor**
   - Access Coolify at http://10.0.1.15:8000
   - Set up monitoring for all Boilerexams services
   - Configure uptime checks for:
     - Backend API endpoints
     - Frontend applications
     - Database connectivity
     - Cachet status page itself

2. **Link Coolify monitoring data to Cachet**
   - Use Coolify webhooks to notify Cachet of status changes
   - Configure automatic incident creation in Cachet when Coolify detects downtime
   - Set up status synchronization between both platforms

### Phase 4: Prometheus & Grafana Integration

1. **Configure Prometheus to scrape backend metrics**
   - Update `prometheus/prometheus.yml` with backend targets
   - Add job for boilerexams-backend-v3 metrics endpoint

2. **Create Grafana dashboards**
   - API response times
   - Error rates
   - Uptime percentages
   - Database performance

## Verification Steps

### After Phase 1 (Cachet Setup)
```bash
# Verify Cachet container is running
docker compose ps cachet

# Check Cachet logs
make cachet-logs

# Test admin login
curl -X POST http://10.0.1.15:8001/login \
  -d "email=admin@example.com&password=admin123"

# Verify database connection
docker compose exec cachet psql -h coolify-db -U coolify -d cachet -c "SELECT 1"
```

### After Phase 2 (API Monitoring)
```bash
# Test backend health endpoint
curl http://<backend-host>:<port>/health

# Verify Cachet API is accessible
curl http://10.0.1.15:8001/api/v1/components

# Check Cachet components are listed
curl -H "X-Cachet-Token: <api-token>" http://10.0.1.15:8001/api/v1/components
```

### After Phase 3 (Coolify Integration)
```bash
# Verify Coolify is running
docker compose ps coolify

# Check Coolify monitoring status
curl http://10.0.1.15:8000/api/health

# Verify webhook connectivity
curl -X POST http://10.0.1.15:8001/api/v1/incidents \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Incident","message":"Testing webhook","status":1}'
```

### After Phase 4 (Prometheus & Grafana)
```bash
# Verify Prometheus targets
curl http://10.0.1.15:9090/api/v1/targets

# Check Grafana is running
curl http://10.0.1.15:3000/api/health

# Verify Loki logs
curl http://10.0.1.15:3100/ready
```

## Troubleshooting

### Cachet Issues
```bash
# View logs
make cachet-logs

# Restart Cachet
docker compose restart cachet

# Rebuild Cachet
docker compose down cachet
docker compose build cachet
docker compose up -d cachet
```

### Database Issues
```bash
# Check database status
docker compose ps coolify-db

# View database logs
docker compose logs coolify-db

# Connect to database
docker compose exec coolify-db psql -U coolify -d cachet
```

### Network Issues
```bash
# Recreate network
docker network rm observability
make network

# Verify network connectivity
docker compose exec cachet ping coolify-db
```

## Environment Variables

### Cachet
| Variable | Value | Description |
|----------|-------|-------------|
| APP_URL | http://10.0.1.15:8001 | Application URL |
| DB_CONNECTION | pgsql | Database driver |
| DB_HOST | coolify-db | Database host |
| DB_PORT | 5432 | Database port |
| DB_DATABASE | cachet | Database name |
| DB_USERNAME | coolify | Database user |
| DB_PASSWORD | coolify | Database password |
| CACHET_ADMIN_USER | admin | Admin username |
| CACHET_ADMIN_EMAIL | admin@example.com | Admin email |
| CACHET_ADMIN_PASSWORD | admin123 | Admin password |

### Coolify
| Variable | Value | Description |
|----------|-------|-------------|
| APP_URL | http://10.0.1.15:8000 | Application URL |
| DB_CONNECTION | pgsql | Database driver |
| DB_HOST | coolify-db | Database host |
| DB_PORT | 5432 | Database port |
| DB_DATABASE | coolify | Database name |
| DB_USERNAME | coolify | Database user |
| DB_PASSWORD | coolify | Database password |
| REDIS_HOST | coolify-redis | Redis host |
| REDIS_PORT | 6379 | Redis port |

## API Monitoring Endpoints

### boilerexams-backend-v3
- **Health**: `/health` (to be implemented)
- **Metrics**: `/metrics` (to be implemented)
- **API**: `/api/v1/*`

### Services to Monitor
1. Backend API (boilerexams-backend-v3)
2. Database (PostgreSQL via coolify-db)
3. Cache (Redis via coolify-redis)
4. Status Page (Cachet)
5. Deployment Platform (Coolify)

## Maintenance

### Regular Tasks
- Review Cachet incidents weekly
- Update Grafana dashboards as needed
- Rotate admin passwords quarterly
- Monitor disk usage for /data/coolify

### Backup Strategy
- Database: PostgreSQL dumps from coolify-db
- Configuration: Git version control for all config files
- Cachet: Export components and metrics via API
