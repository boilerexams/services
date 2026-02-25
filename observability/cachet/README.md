**Status Page:** http://10.0.1.15:8001

**Admin Login:** http://10.0.1.15:8001/login
- Email: admin@example.com
- Password: admin123

## Quick Start

```bash
cd observability

# Create network (if not exists)
docker network create observability

# Start database and Redis first
docker compose up -d coolify-db coolify-redis

# Build and start Cachet
docker compose build cachet
docker compose up -d cachet
```

## Available Commands

```bash
make network     # Create observability Docker network
make up          # Start all containers
make down        # Stop all containers
make logs        # View logs (follow mode)
make ps          # Show container status
make clean       # Remove containers and volumes
make cachet      # Build and start only Cachet
make cachet-logs # View Cachet logs
```

## Architecture

- **Database**: Shares coolify 
- **Port**: 8001

## Configuration

Environment variables (in `docker-compose.override.yml`):

| Variable | Value |
|----------|-------|
| APP_URL | http://10.0.1.15:8001 |
| DB_CONNECTION | pgsql |
| DB_HOST | coolify-db |
| DB_PORT | 5432 |
| DB_DATABASE | cachet |
| DB_USERNAME | coolify |
| DB_PASSWORD | coolify |

## Troubleshooting

View logs:
```bash
docker compose logs -f cachet
```

Restart:
```bash
docker compose restart cachet
```

Recreate:
```bash
docker compose down cachet
docker compose build cachet
docker compose up -d cachet
```
