# AGENTS.md - Boilerexams Observability Stack

This document describes the observability infrastructure for Boilerexams.

## Overview

The observability stack provides monitoring, logging, and status page capabilities.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Prometheus** | 9090 | Metrics collection & monitoring |
| **Grafana** | 3000 | Metrics visualization & dashboards |
| **Loki** | 3100 | Log aggregation |
| **Promtail** | N/A | Log shipping to Loki |
| **cAdvisor** | 8080 | Container metrics |
| **Casvisor** | 16001 | Casbin access control visualization |
| **Cachet** | 8001 | Status page (Boilerexams observability) |

## Quick Commands

```bash
cd observability

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
- **Location**: `observability/cachet/`

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
