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

## CI framework (errores grandes)

This project now includes automated CI to catch major issues on every push/PR.

Workflow file:
- `.github/workflows/flutter_ci.yml`

What it runs:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- `flutter build web --release`

Artifacts generated in GitHub Actions:
- `app-release-apk`
- `web-build`

How to view errors:
1. Push changes to GitHub.
2. Open the **Actions** tab in your repository.
3. Open the latest **Flutter CI** run.
4. Review the failed step logs.
