# skillhub Delivery Roadmap

## Phase 0: Design Finalization (Current Phase)

Deliverables: Architecture design documents, database DDL, API OpenAPI spec draft, frontend wireframes

Frozen decisions:
- Skill coordinate system: `@{namespace_slug}/{skill_slug}`, compatibility layer uses `--` double-hyphen mapping (see `00-product-direction.md` section 1.1)
- Phase 1 synchronous publish model; async publish not considered for now
- API Token in Phase 1 inherits all user permissions (not least-privilege); to be refined in future versions
- CLI primary authentication switches to OAuth Device Flow; Bearer Token is used uniformly for CLI API and compatibility layer
- ClawHub CLI compatibility layer base URL `/api/v1`, discovered via `/.well-known/clawhub.json`

## Phase 1: Engineering Skeleton + Authentication Integration

### Backend

- Maven multi-module initialization (6 modules)
- Spring Boot startup, configuration, profile layering
- Flyway + database initialization
- Redis integration (Session + distributed lock)
- Spring Security OAuth2 Client configuration (GitHub OAuth login)
- CustomOAuth2UserService + IdentityBindingService (auto-register/bind)
- Spring Session (Redis) management, API Token issuance and validation
- RBAC foundation (SUPER_ADMIN / SKILL_ADMIN / USER_ADMIN / AUDITOR + namespace roles)
- Global exception handling, requestId propagation, log format
- Springdoc OpenAPI, health check
- CSRF protection (Cookie-to-Header mode, CLI API exempt)
- Local development MockAuthFilter (`local` profile)
- Basic rate limiting: Nginx Ingress `limit-req` per-IP rate limiting (auth/search/download endpoints)

### Frontend

- Vite + React + TypeScript initialization
- shadcn/ui + Tailwind configuration
- TanStack Router routing skeleton, TanStack Query configuration
- openapi-fetch client generation pipeline
- Layout components, OAuth login flow (call `/api/v1/auth/providers` → redirect)
- Login state detection (`/api/v1/auth/me`) + route guards
- Makefile top-level orchestration

### Acceptance Criteria

Frontend and backend are running, GitHub OAuth login is functional, AccessPolicy admission policy is active, `/api/v1/auth/me` is available, Token is available, OpenAPI spec is accessible, Ingress basic rate limiting is active

## Phase 2: Namespace + Skill Core Pipeline

### Backend

- Namespace CRUD + member management
- Object storage integration (LocalFile + S3 dual implementation)
- Skill publishing (upload → validate → store → review / publish, synchronous processing in Phase 1)
- Skill query (detail, versions, files), download (packaging + visibility check, PUBLIC downloadable anonymously)
- Tag management, search (PostgreSQL Full-Text, anonymous search limited to PUBLIC)
- Async event infrastructure
- Rate Limiting upgrade (application-layer fine-grained rate limiting: per-user/endpoint classification, based on Redis sliding window)

### Frontend

- Home page, search page, namespace home page (anonymous access)
- Skill detail page, version history page (PUBLIC anonymously browsable/downloadable)
- Publish page, my skills list
- Namespace management page

### Acceptance Criteria

Full publish → storage → review → query → download pipeline is functional, search is functional, namespace isolation is active, anonymous users can browse/download public skills

## Phase 3: Review Workflow + Rating/Stars + CLI API / ClawHub Compatibility Layer

### Backend

- Review workflow (submit → review → publish, with optimistic locking)
- Team skill promotion to global (`promotion_request` workflow)
- Rating + starring + counters (atomic updates)
- OAuth Device Flow (device code, authorization confirmation, polling to exchange Bearer Token)
- CLI API (whoami, publish, resolve, check)
- ClawHub CLI protocol compatibility layer (`/api/v1` endpoints: search, resolve, download, publish, whoami)
- Compatibility layer canonical slug mapping (`--` double-hyphen rule)
- `/.well-known/clawhub.json` discovery endpoint
- Protocol adapters and compatibility tests (against real ClawHub CLI request/response samples)
- Audit logs (synchronous write to database), idempotent deduplication (`idempotency_record` + Redis)

### Frontend

- Review center, namespace review page, promotion review page
- Rating component + star button (prompts login for anonymous users), my stars page
- Token management page
- Admin backend (user management, role assignment, access approval, ban/unban)
- Frontend API layer consolidation: uniformly migrate to OpenAPI-generated types + `openapi-fetch` client, deprecate hand-written `fetch` in business pages
- Establish a frontend sync mechanism after API changes: run `generate-api` after backend OpenAPI updates; generated types and actual responses must not drift apart long-term

### Acceptance Criteria

Team namespace self-governance review and global namespace platform review are active, skillhub CLI Device Flow is functional, ClawHub CLI can complete core registry operations via the compatibility layer, rating and starring are functional

## Phase 4: Operations Enhancement + Polish + Open Source Ready

### Backend

- Local authentication system (username/password registration/login + BCrypt + password policy + account lockout)
- Multi-account merge flow (initiate → verify → confirm → data migration)
- Skill governance (hide/restore + yank published versions)
- Audit log query API (multi-condition filtering + pagination)
- Prometheus metrics exposure (Actuator + Micrometer custom business metrics)
- Performance optimization (database indexes + S3 pre-signed URLs + connection pool tuning)
- Security hardening (Session Cookie security + security response headers + XSS protection)

### Frontend

- Registration page, login page extension (username/password + OAuth dual mode)
- Password change page, account merge page
- Audit log query page
- Skill hide/restore/yank operations (admin-visible)
- Frontend code splitting (TanStack Router lazy routes)
- rehype-sanitize XSS protection
- OpenAPI SDK engineering: generated files included in CI checks to prevent new endpoints from falling back to hand-written calls

### Deployment & Open Source

- Docker one-click startup (multi-stage Dockerfile + docker-compose + seed data)
- K8s basic deployment manifests (Deployment + Service + Ingress)
- README.md, CONTRIBUTING.md, GitHub Issue/PR templates
- LICENSE (Apache 2.0), CODE_OF_CONDUCT.md

### Acceptance Criteria

Local authentication is functional, multi-account merge is functional, skill hide/restore/yank is functional, audit logs are queryable, Prometheus metrics are scrapable, `docker compose up` starts in one click, K8s manifests are deployable, open source infrastructure is complete

## Phase 5: Governance Closure + Social Features

- Comments
- Report/flag mechanism (user reports → admin handles → hide/yank)
- Automated pre-publish security checks (`PrePublishValidator` extended from current `NoOp` to a real validation chain)
- Webhook/event notifications (publish notifications, review result notifications)
- Additional OAuth Provider support (GitLab, Google, etc.)
- Vector search Phase 2 enhancement (current Phase 1 only does search enhancement, not recommendations)

## Key Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| GitHub OAuth callback configuration complexity | Use MockAuthFilter locally to decouple; OAuth integration testing can proceed in parallel |
| Review workflow requirement changes | Lifecycle state machine is converged to `DRAFT / PENDING_REVIEW / PUBLISHED / REJECTED / YANKED`; read model exposed via unified projection |
| Poor search quality | SPI architecture allows switching implementations at any time |
| Frequent frontend-backend interface changes | OpenAPI spec first; types auto-generated |
| Adding new OAuth Providers | Spring Security OAuth2 native multi-provider support; only configuration + property mapping needed |
| ClawHub CLI protocol details not fully consistent with existing model | Compatibility layer uses `--` double-hyphen canonical slug mapping, independent controller layer adapter, protocol regression tests coverage |

## Testing Evolution Strategy

- Current phase (Phase 2 validation-first): Start PostgreSQL, Redis, MinIO locally via `docker-compose.yml`; backend and integration tests connect directly to real dependencies, prioritizing validation of publish, search, download, rate limiting, and other infrastructure-related pipelines
- Later phases (engineering consolidation): Gradually migrate backend integration tests to Testcontainers, where test code spins up PostgreSQL, Redis, MinIO on demand, reducing dependency on manually started local services, and integrate into CI
- Frontend phased requirements: After backend API contracts stabilize, the frontend must synchronously refresh OpenAPI-generated types and validate key pages; unified response structure changes cannot be applied only on the backend without updating the frontend
- Principle: Unit tests can continue using mocks/in-memory stubs, but Phase 2/3 core acceptance must retain a set of integration tests based on real middleware to avoid Redis Lua, object storage, Flyway, and search SQL issues being masked by fake implementations
