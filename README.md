# salefulbo

Flutter app + Dockerized local infrastructure.

## Docker Stack (recommended)

This repository includes a container stack to keep dependencies stable across machines.

Services:
- `api` (Node/Express bootstrap)
- `postgres` (PostgreSQL 16)
- `redis` (Redis 7)
- `adminer` (DB UI)

### 1) Prepare env file

```powershell
Copy-Item .env.example .env
```

### 2) Start containers

```powershell
docker compose up -d --build
```

### 3) Check status

```powershell
docker compose ps
```

### Useful URLs

- API health: `http://localhost:8080/health`
- Adminer: `http://localhost:8081`
	- Server: `postgres`
	- User: value from `.env`
	- Password: value from `.env`
	- Database: value from `.env`

### Stop everything

```powershell
docker compose down
```

To remove volumes too:

```powershell
docker compose down -v
```
