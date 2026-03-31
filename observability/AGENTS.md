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
- **Admin**: http://10.0.1.15:8001/dashboard/login
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

## Current Status Page Configuration

### Components (4)

| ID | Name | Description | Status | Link |
|----|------|-------------|--------|------|
| 1 | Backend API | boilerexams-backend-v3 - Main API server | Operational | https://api.boilerexams.com/ |
| 2 | Database | PostgreSQL - Primary data store | Operational | - |
| 3 | Redis | Coolify Redis - Session and cache store | Operational | - |
| 4 | Status Page | Cachet - Boilerexams observability status page | Operational | http://10.0.1.15:8001 |

### Metrics (1)

| ID | Name | Suffix | Description | Default Value |
|----|------|--------|-------------|---------------|
| 1 | Backend API Response Time | ms | Response time from api.boilerexams.com/health | 150.00 |

### API Token

An API token has been created for the admin user (`admin@example.com`). To regenerate or create a new token:

```bash
docker compose exec cachet php artisan tinker --execute="
\$user = \App\Models\User::where('email', 'admin@example.com')->first();
\$token = \$user->createToken('automated-setup')->plainTextToken;
echo \$token;
"
```

The API uses Bearer token authentication:
```bash
curl -H "Authorization: Bearer <token>" -H "Accept: application/json" http://10.0.1.15:8001/api/components
```

## Implementation Plan

### Phase 1: Cachet Setup & Database Configuration ✅ COMPLETE

1. **Create the observability network**
   ```bash
   make network
   ```

2. **Start Coolify dependencies** (shared database)
   ```bash
   docker compose up -d coolify-db
   ```

3. **Build and start Cachet**
   ```bash
   make cachet
   ```

4. **Verify Cachet is running**
   ```bash
   docker compose ps cachet
   ```

### Phase 2: API Monitoring Configuration ✅ COMPLETE

Components and metrics have been created via the Cachet API. The following services are tracked:

- **Backend API** - monitors https://api.boilerexams.com/
- **Database** - PostgreSQL (coolify-db)
- **Redis** - Coolify Redis (coolify-redis)
- **Status Page** - self-monitoring Cachet

#### Backend Health Endpoint

The `boilerexams-backend-v3` already exposes a `/health` endpoint at `https://api.boilerexams.com/health`:
```json
{
  "uptime": "2h 34m 12s",
  "active_users": 42,
  "daily_users": 156
}
```
This endpoint is NOT rate-limited and does NOT require authentication.

### Phase 3: Coolify Integration (TODO)

#### How to Configure Coolify as Uptime Monitor

1. **Access Coolify** at http://10.0.1.15:8000
2. **Add monitored services**:
   - Go to "Resources" → "Add Resource" → "External Service"
   - Add the following endpoints:
     - `https://api.boilerexams.com/health` (Backend API)
     - `http://10.0.1.15:8001` (Cachet Status Page)
     - Any frontend URLs
3. **Configure uptime checks**:
   - Set check interval (default: 60s)
   - Configure alert notifications (email, Discord, webhook)
   - Set expected response codes (200)

#### How to Link Coolify to Cachet

Coolify can notify Cachet of status changes via webhooks:

1. In Coolify, go to the monitored service → "Notifications"
2. Add a webhook pointing to Cachet's incident API:
   ```
   POST http://10.0.1.15:8001/api/incidents
   Headers:
     Authorization: Bearer <cachet-api-token>
     Content-Type: application/json
   Body:
     {
       "name": "Service Outage Detected",
       "message": "Coolify detected downtime on {service_name}",
       "status": 3,
       "visible": 1
     }
   ```
3. Configure status codes:
   - Status 1 = Investigating
   - Status 2 = Identified
   - Status 3 = Watching
   - Status 4 = Fixed

Alternatively, use Coolify's Discord notifications and have a separate script bridge Discord → Cachet.

### Phase 4: Prometheus & Grafana Integration (TODO)

1. **Configure Prometheus to scrape backend metrics**
   - Update `prometheus/prometheus.yml` with backend targets
   - Note: backend currently has no `/metrics` endpoint; would need to add Prometheus Go client

2. **Create Grafana dashboards**
   - API response times
   - Error rates
   - Uptime percentages
   - Database performance

## Verification Steps

### Cachet Status Page
```bash
# Verify Cachet container is running
docker compose ps cachet

# Check Cachet logs
make cachet-logs

# Verify database connection
docker compose exec cachet psql -h coolify-db -U coolify -d cachet -c "SELECT 1"

# List components via API
docker compose exec cachet curl -s http://localhost:80/api/components \
  -H "Authorization: Bearer <token>" -H "Accept: application/json"

# List metrics via API
docker compose exec cachet curl -s http://localhost:80/api/metrics \
  -H "Authorization: Bearer <token>" -H "Accept: application/json"
```

### Backend API
```bash
# Test backend health endpoint
curl https://api.boilerexams.com/health

# Expected response:
# {"uptime":"...","active_users":N,"daily_users":N}
```

### Coolify (when configured)
```bash
# Verify Coolify is running
docker compose ps coolify

# Check Coolify health
curl http://10.0.1.15:8000/api/health
```

### Prometheus & Grafana (when configured)
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

# Reset database (WARNING: deletes all data)
docker compose down cachet
docker compose exec coolify-db psql -U coolify -d postgres -c "DROP DATABASE cachet"
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
- **Health**: `https://api.boilerexams.com/health` ✅ Available
- **Metrics**: `/metrics` (not implemented - would need Go Prometheus client)
- **API**: `https://api.boilerexams.com/api/v1/*`

### Services to Monitor
1. Backend API (boilerexams-backend-v3) - https://api.boilerexams.com/
2. Database (PostgreSQL via coolify-db)
3. Cache (Redis via coolify-redis)
4. Status Page (Cachet) - http://10.0.1.15:8001
5. Deployment Platform (Coolify) - http://10.0.1.15:8000

## Maintenance

### Regular Tasks
- Review Cachet incidents weekly
- Update Grafana dashboards as needed
- Rotate admin passwords quarterly
- Monitor disk usage for /data/coolify
- Regenerate API tokens periodically

### Backup Strategy
- Database: PostgreSQL dumps from coolify-db
- Configuration: Git version control for all config files
- Cachet: Export components and metrics via API

### Adding New Components
```bash
# Via API
TOKEN="<your-api-token>"
curl -X POST http://10.0.1.15:8001/api/components \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"name":"New Service","description":"Description here","status":1,"enabled":true}'

# Status values: 1=Operational, 2=Performance Issues, 3=Partial Outage, 4=Major Outage, 0=Unknown
```
