# skillhub Deployment Architecture and Operations

## 1 Runtime Model

The current repository maintains only two runtime modes:

- Development environment: `make dev-all`
  - Frontend and backend run on the host machine
  - `docker-compose.yml` is responsible only for PostgreSQL, Redis, and MinIO
- Single-machine delivery environment: `docker compose --env-file .env.release -f compose.release.yml up -d`
  - Frontend and backend both run inside containers
- Images are published to GHCR via GitHub Actions
- By default, multi-architecture images for `linux/amd64` and `linux/arm64` are published
  - PostgreSQL, Redis, and application containers are all started together via Compose

The intermediate mode of building a full local demo container set is no longer maintained, and `docker-compose.prod.yml` is no longer retained.

## 2 Single-Machine Delivery Topology

```
┌──────────────┐
│ Browser / CLI│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Web/Nginx  │  published image
└──────┬───────┘
       │ /api/*
       ▼
┌──────────────┐
│ Spring Boot  │  published image
└───┬────┬─────┘
    │    │
    ▼    ▼
 PostgreSQL  Redis
```

Notes:
- The Web container serves static assets and reverse-proxies `/api/*`, `/oauth2/*`, and `/.well-known/*` to the backend
- The backend runs the `docker` profile by default; local mock login is no longer enabled
- PostgreSQL / Redis bind only to `127.0.0.1` by default
- Object storage is recommended to use external S3 / OSS, injected via environment variables

## 3 Profile Conventions

| Profile | Purpose | Notes |
|---------|---------|-------|
| `local` | Local source code development capabilities | Enables mock login, development seed accounts, debug logging |
| `docker` | Container runtime capabilities | Enables container runtime-related capabilities; does not automatically open the first-login admin account |

The single-machine delivery environment uses `SPRING_PROFILES_ACTIVE=docker`, for the following reasons:

- Production environments should not enable `X-Mock-User-Id` and similar local development bypass capabilities
- Container environments still retain the `docker` profile runtime capabilities; first admin account initialization does not depend on this profile and is controlled via environment variables
- Database, Redis, OSS, and site public URL are all environment variable-first

To enable the first-login admin account, use the following environment variables:

- `BOOTSTRAP_ADMIN_ENABLED=true` (enabled by default in the release template)
- `BOOTSTRAP_ADMIN_USERNAME` (default: `admin`)
- `BOOTSTRAP_ADMIN_PASSWORD` (default: `ChangeMe!2026`)

Recommendations:

- In production environments, always change `BOOTSTRAP_ADMIN_PASSWORD` (`validate-release-config.sh` will reject the default value)
- Change the admin password immediately after the first login
- If an external identity provider is already available, the bootstrap admin typically does not need to be enabled
- `SKILLHUB_PUBLIC_BASE_URL` should be configured as the final HTTPS domain to avoid OAuth / Cookie / device code link issues

## 4 Development Environment

The development entry point remains unchanged:

```bash
make dev-all
```

Behavior:

- `docker-compose.yml` starts PostgreSQL, Redis, MinIO
- `server` starts on the host machine via Maven Wrapper
- `web` starts on the host machine via Vite

Common commands:

```bash
make dev
make dev-all
make dev-down
make dev-all-down
make dev-all-reset
```

## 5 Single-Machine Delivery Environment

### 5.1 Startup

```bash
cp .env.release.example .env.release
make validate-release-config
docker compose --env-file .env.release -f compose.release.yml up -d
```

Default access URLs:

- Web UI: `SKILLHUB_PUBLIC_BASE_URL`
- Backend API: `http://localhost:8080`

### 5.2 Key Files

- `compose.release.yml`
  - Uses published images; does not perform local builds on the user's machine
  - Responsible for starting PostgreSQL, Redis, server, web
  - PostgreSQL, Redis bind to `127.0.0.1` only by default
  - Both Web and backend support runtime environment variable injection; no image rebuild is needed per environment
- `.env.release.example`
  - Runtime variable template
  - Contains image name, image version, ports, database credentials, external OSS, site public URL, and first-login admin parameters
- `scripts/validate-release-config.sh`
  - Validates `.env.release` before startup
  - Can catch placeholder values, URL format errors, missing OSS credentials, and dangerous plaintext default values early

### 5.3 Image Tag Conventions

- `edge`
  - Latest build from the `main` branch
  - Used for internal continuous validation
- `vX.Y.Z`
  - Corresponds to a Git tag
  - Used for stable version delivery
- `latest`
  - Updated only when a semantic version tag is released

Recommendations:

- Default quick start: `SKILLHUB_VERSION=latest`
- Internal team trial: `SKILLHUB_VERSION=edge`
- External demos or strictly reproducible environments: pin to a specific `vX.Y.Z`

## 6 GitHub Actions Release Process

Release workflow file: `.github/workflows/publish-images.yml`

Trigger conditions:

- `release.published`
- Manual `workflow_dispatch`

Process:

1. Checkout code
2. Log in to GHCR
3. Build `server/Dockerfile` and `web/Dockerfile` separately
4. Push images:
   - `ghcr.io/iflytek/skillhub-server`
   - `ghcr.io/iflytek/skillhub-web`
5. Write `edge` / `vX.Y.Z` / `latest` / `sha-*` tags
6. Publish `linux/amd64` and `linux/arm64` manifests simultaneously to avoid requiring emulation on Apple Silicon / ARM hosts

## 7 Configuration Management

Frontend runtime configuration is injected via `web/runtime-config.js.template`. New variables related to the auth compatibility layer are as follows:

- `SKILLHUB_WEB_AUTH_DIRECT_ENABLED`
  - Whether to enable the username/password compatibility integration layer on the frontend
  - Default should be `false`
- `SKILLHUB_WEB_AUTH_DIRECT_PROVIDER`
  - The provider used by the frontend when calling `/api/v1/auth/direct/login`, e.g., `private-sso`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_ENABLED`
  - Whether to enable the enterprise SSO passive session compatibility entry on the frontend
  - Default should be `false`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_PROVIDER`
  - The provider used by the frontend when calling `/api/v1/auth/session/bootstrap`, e.g., `private-sso`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_AUTO`
  - Whether to automatically attempt a bootstrap once after the login page loads
  - Recommended to keep `false` in the early stages of a private deployment

Notes:

- Before enabling the frontend password compatibility layer, the backend must also enable `skillhub.auth.direct.enabled=true`
- Before enabling the frontend toggle, the backend must also enable `skillhub.auth.session-bootstrap.enabled=true`
- If either side is not enabled, it will not break the original login method; only that compatibility entry will be unavailable or hidden

Development environment:

- Local commands and `docker-compose.yml`
- Non-sensitive default values can be committed directly or written into local configuration

Single-machine delivery environment:

- Use `.env.release` to manage Compose variables
- If the GHCR package is kept private, users need to `docker login ghcr.io` first
- Recommended to store sensitive variables in CI/CD Secrets or a controlled `.env.release` on the host machine
- External object storage is injected via `SKILLHUB_STORAGE_S3_*`
- Frontend reverse proxy and runtime API address are injected via `SKILLHUB_API_UPSTREAM` / `SKILLHUB_WEB_API_BASE_URL`
- To enable real login, add `OAUTH2_GITHUB_CLIENT_ID` / `OAUTH2_GITHUB_CLIENT_SECRET`
- To enable password reset verification code emails, see: `docs/19-smtp-password-reset-email-setup.md`

## 8 Bare Metal Launch Checklist

Recommended order:

1. Prepare server base environment
   - Install Docker Engine and Docker Compose Plugin
   - Configure public HTTPS entry point; ensure the final access domain is determined
   - Open ports `80` / `443`; avoid directly exposing `5432` / `6379`
2. Fill in `.env.release`
   - Set `SKILLHUB_PUBLIC_BASE_URL` to the final HTTPS domain without a trailing `/`
   - `SKILLHUB_STORAGE_PROVIDER=s3`
   - Fill in `SKILLHUB_STORAGE_S3_*` according to cloud provider OSS / S3 compatible parameters
   - Set a non-default `POSTGRES_PASSWORD`
   - The template has first-login admin enabled by default; be sure to change `BOOTSTRAP_ADMIN_PASSWORD` to a strong password
3. Pre-launch validation
   - Run `make validate-release-config`
   - Confirm there are no placeholder values like `replace-me`, `change-this-*`, `ChangeMe!2026`
4. First launch
   - Run `docker compose --env-file .env.release -f compose.release.yml up -d`
   - Check `docker compose --env-file .env.release -f compose.release.yml ps`
   - Check `curl -i http://127.0.0.1:8080/actuator/health`
5. First-login wrap-up
   - Only if `BOOTSTRAP_ADMIN_ENABLED=true` was set, log in with `BOOTSTRAP_ADMIN_USERNAME` / `BOOTSTRAP_ADMIN_PASSWORD`
   - Change the admin password immediately
   - If fully using OAuth afterward, set `BOOTSTRAP_ADMIN_ENABLED=false`

## 9 Observability

| Dimension | Solution |
|-----------|---------|
| Health Check | `web/nginx-health`, `server/actuator/health` |
| Logging | Container stdout / stderr |
| Metrics | Spring Boot Actuator; Prometheus integration available in future |

## 10 Security Scanning Service

To enable the `skill-scanner` backend pipeline, the current repository recommends the following deployment approach:

- Local shared directory scenarios can use `local` mode
- Kubernetes or separated deployment scenarios should use `upload` mode

The current `deploy/k8s` is modeled for separated deployment, so the recommendation is:

- `SKILLHUB_SECURITY_SCANNER_ENABLED=true`
- `SKILLHUB_SECURITY_SCANNER_URL=http://skillhub-scanner:8000`
- `SKILLHUB_SECURITY_SCANNER_MODE=upload`

Related files:

- `deploy/k8s/scanner-deployment.yaml`
- `deploy/k8s/services.yaml`
- `deploy/k8s/backend-deployment.yaml`
- `scripts/verify-scanner.sh`
- `docs/security-scanning.md`

## 11 Data Migration

Flyway remains the only schema change entry point:

- Path: `server/skillhub-app/src/main/resources/db/migration/`
- Naming: `V{version}__{description}.sql`
- Startup strategy: migrations are automatically executed when the application container starts
