# skillhub System Architecture Design

## 1. Technology Baseline

- JDK: 21
- Framework: Spring Boot 3.x (latest stable version)
- Security: Spring Security + spring-boot-starter-oauth2-client
- Database: PostgreSQL 16.x
- Cache/Session: Redis 7.x (required in Phase 1; used for Session storage + distributed locks + idempotency deduplication)
- Object Storage: `LocalFile` + dual implementation compatible with S3 protocol
- Search: PostgreSQL Full-Text Search (Phase 1)
- Future Search: Elasticsearch / OpenSearch / Vector Search

## 2. Overall Architecture

A monolith-first, modular monolith design is adopted. Business domains are clearly separated; the Phase 1 scale does not require microservice decomposition.

## 3. Backend Module Structure

```
server/
├── skillhub-app                 # Startup, configuration assembly, Controller aggregation
├── skillhub-domain              # Domain model + domain services + application services
├── skillhub-auth                # OAuth2 authentication + RBAC + authorization evaluation
├── skillhub-search              # Search SPI + PostgreSQL full-text implementation
├── skillhub-storage             # Object storage abstraction + LocalFile/S3 dual implementation
└── skillhub-infra               # JPA, common utilities, configuration infrastructure
```

## 4. Module Dependency Direction (Dependency Inversion; domain layer must not depend on infrastructure)

```
app → domain, auth, search, storage, infra
infra → domain          # infra implements Repository interfaces defined in domain
auth → domain           # auth references domain entities such as UserAccount
search → domain         # search references domain models such as SkillSearchDocument
storage → (independent abstraction)  # pure SPI, no dependency on domain
```

Core principles:
- domain is the innermost layer; it depends on no other modules and only defines interfaces and entities
- infra implements the Repository interfaces defined in domain (Spring Data JPA)
- app is responsible for assembling all modules; Spring dependency injection wires infra implementations into domain interfaces
- The domain → infra dependency direction is forbidden, to prevent the domain layer from being tightly coupled to JPA or event implementations

## 5. Module Responsibilities

### skillhub-app
- Spring Boot startup class
- Controller aggregation: public query endpoints, authenticated write endpoints, CLI API, compatibility layer, admin console
- Global exception handling, request logging, OpenAPI configuration
- Configuration files and environment profiles
- Application layer boundary conventions:
  - Controllers are responsible only for transport: extracting the authorization context, binding request parameters, and wrapping responses
  - App Services are responsible for workflow orchestration: coordinating across domain services, pagination entry points, passing audit fields, and calling dedicated query repositories
  - App Services do not directly handle complex read-model assembly; when a response requires joining multiple aggregates, snapshot fields, JSON parsing, or display-state projections, a query repository should be extracted first
  - Query repositories in the `skillhub-app/repository` package serve application-layer read models only and do not carry domain write rules

### skillhub-domain
- Core entities: Skill, SkillVersion, SkillFile, SkillTag, Namespace, NamespaceMember, ReviewTask, PromotionRequest, AuditLog, SkillStar, SkillRating, IdempotencyRecord
- Domain services: publish workflow orchestration, review state machine, namespace management, tag management
- Application services: focused on domain rules and use-case orchestration
- Repository interface definitions (implementations in infra)

### skillhub-auth
- Spring Security OAuth2 Client configuration (Phase 1: GitHub; extensible to multiple providers)
- `CustomOAuth2UserService`: OAuth2 user → platform user mapping
- `IdentityBindingService`: external identity → platform user binding
- Spring Session (Redis) management
- CLI Device Flow authorization, polling, and credential issuance
- API Token issuance, validation, and revocation
- RBAC: role definitions, permission points, resource-level authorization evaluation
- User entities: UserAccount, IdentityBinding, ApiToken, Role, Permission, UserRoleBinding

### skillhub-search
- SPI interfaces: `SearchIndexService`, `SearchQueryService`, `SearchRebuildService`
- Phase 1 implementation: `PostgresFullTextIndexService`, `PostgresFullTextQueryService`
- Separate search document table `skill_search_document`
- Future extension points: ES / vector search implementations

### skillhub-storage
- SPI interface: `ObjectStorageService`
- Phase 1 implementation: `LocalFileStorageService` (local development / zero dependencies) + `S3StorageService` (integration testing / production)
- File hash validation, packaged download
- Object key rules (using immutable IDs to prevent key invalidation caused by namespace renames):
  - Official path: `skills/{skillId}/{versionId}/{filePath}`
  - Package path: `packages/{skillId}/{versionId}/bundle.zip`

### skillhub-infra
- Spring Data JPA Repository implementations
- Repository implementations
- Common utilities (ID generation, time, JSON, etc.)
- Spring Events asynchronous event infrastructure

## 6. Frontend Project Structure

```
web/
├── src/
│   ├── app/              # Routing, global Providers, layout
│   ├── pages/            # Page entry points
│   ├── features/         # Business features: search, upload, version management, review, etc.
│   ├── entities/         # Display logic for domain objects: skill, user, namespace, etc.
│   ├── shared/           # Common components, hooks, utilities
│   └── api/              # Types generated by openapi-typescript + openapi-fetch client
├── package.json
└── vite.config.ts
```

Tech stack: React 19 + TypeScript + Vite + shadcn/ui + Tailwind CSS + TanStack Query + TanStack Router + openapi-fetch

## 7. Monorepo Top-Level Structure

```
skillhub/
├── server/               # Maven multi-module Java backend
│   └── Dockerfile        # Backend multi-stage build
├── web/                  # React frontend
│   ├── Dockerfile        # Frontend multi-stage build
│   ├── nginx.conf.template        # Nginx runtime template
│   └── runtime-config.js.template # Frontend runtime environment variable template
├── docker-compose.yml    # Local development dependency services (PostgreSQL/Redis/MinIO)
├── compose.release.yml   # Single-machine runtime orchestration (release images + PostgreSQL + Redis)
├── .env.release.example  # Single-machine runtime environment variable template
├── .github/workflows/    # GitHub Actions image publishing workflow
├── Makefile              # Top-level development orchestration (dev / dev-all / build)
├── docs/                 # Design documents
└── README.md
```

Simple directory layout; each part builds independently, with a Makefile to chain them together.

## 8. Deployment Architecture

The deployment model converges to two paths:

- Development path: `make dev-all`. The frontend and backend run on the host machine; `docker-compose.yml` is responsible only for PostgreSQL, Redis, and MinIO.
- Delivery path: GitHub Actions builds and publishes `server` / `web` images; users use `compose.release.yml` to launch frontend and backend containers along with infrastructure services with a single command.
- Published images are multi-architecture manifests covering at least `linux/amd64` and `linux/arm64`.

Single-machine runtime unified entry point:
- `http://localhost/` → Web container (Nginx)
- `http://localhost/api/*` → Web container reverse-proxies to Spring Boot
- `http://localhost:8080/actuator/health` → Backend health check

The single-machine runtime defaults to using the `docker` profile:
- `docker` is responsible for container runtime initialization, such as creating the first admin account
- Database, Redis, object storage, and the public site URL are all injected via environment variables
- The `local` profile is not enabled in production, so the mock login bypass is not exposed

## 9. Distributed Environment Requirements

This service is deployed as multiple Pods in Kubernetes; all components must be designed to be stateless.

| Component | Phase 1 Requirement | Responsibility |
|------|---------|------|
| PostgreSQL 16.x | Primary-replica | Primary storage |
| Redis 7.x | Sentinel or Cluster | Session storage + distributed locks + idempotency deduplication |
| Object Storage | LocalFile (development) / MinIO / Cloud S3 | Skill package files + pre-packaged zip |
| Ingress | Nginx Ingress Controller | Routing + TLS termination |

## 10. Recommended Phase 1 Technology Decisions

- ORM: Spring Data JPA (Hibernate)
- API Documentation: Springdoc OpenAPI
- Object Storage: LocalFile by default for development; MinIO / AWS S3-compatible interface for integration testing and production
- Async Tasks: Spring Events + async thread pool; introduce MQ later depending on complexity
- Cache/Session: Spring Session + Redis
- Database Migration: Flyway
- Authentication: Spring Security OAuth2 Client (Phase 1: GitHub)
- Image Publishing: GitHub Actions pushes to GHCR; maintains `edge` and semantic version tags by default
- Runtime Compatibility: Published images output multi-architecture manifests for `linux/amd64` + `linux/arm64` by default

## 11. Repository / Query Boundary Conventions

To reduce the cognitive overhead caused by "application layer directly assembling read models" and "mixed repository styles," the backend consolidates according to the following rules:

### 11.1 Domain Repository Port

- Located in `skillhub-domain`
- Serves aggregate reads/writes, state transitions, and rule evaluation
- Can be directly depended on by domain services
- Return values are primarily domain objects and domain query semantics; the current codebase allows continued use of Spring Data's `Page` / `Pageable`, but this is an accepted compromise for the current stage and does not mean all new read models should continue to expand this pattern

Applicable scenarios:

- `SkillRepository`, `ReviewTaskRepository`, `PromotionRequestRepository`
- Domain rules require reading or persisting aggregates themselves
- The core value of a use case lies in "changing state" rather than "assembling a response"

### 11.2 App Query Repository

- Located in `skillhub-app/repository`
- Serves the read models required by controllers and app services, not domain write rules
- Input is typically a list of domain objects, paginated result content, or a stable set of IDs
- Output is typically display-state models such as DTOs, summary cards, inbox items, or admin list rows

Applicable scenarios:

- When joining results from multiple repositories or services is required
- When display-state projections, compatibility layer mappings, legacy field snapshot backfilling, or JSON extraction are needed
- When the same read-model assembly logic is reused across multiple app services or controllers

Current examples:

- `GovernanceQueryRepository`
- `MySkillQueryRepository`
- `ProfileReviewQueryRepository`

### 11.3 App Service

- Located in `skillhub-app/service`
- Responsible for the "workflow owner" semantics, not low-level data assembly details
- Can simultaneously call domain services, domain repository ports, and app query repositories
- Should prioritize expressing "what this entry point does" rather than "how this entry point assembles a DTO"

Allowed:

- Parsing filter conditions, pagination parameters, and platform roles
- Choosing which domain workflow to invoke
- Calling query repositories to assemble the final read model

Discouraged:

- Repeating batch user lookup, namespace join, version projection, or JSON field extraction inside app services
- Having multiple app services each copy the same summary/inbox/list row assembly code

### 11.4 Direct Persistence Access

- Only permitted in a small number of scenarios, such as highly specialized search SQL, admin-side special queries, or compatibility layer transitional adapters
- Such entry points should be centralized as much as possible, with naming or package documentation clearly explaining "why this did not go through the domain repository port or app query repository"

### 11.5 Selection Rules

When facing a new read use case, evaluate in the following order:

1. If it primarily serves state transitions or domain rule evaluation, prefer placing it in the domain repository port / domain service.
2. If it primarily serves page, list, or detail response assembly and requires joining multiple sources, prefer creating an app query repository.
3. If it is a very thin single-aggregate read that requires no additional projection or joins, it can be directly called by the app service using an existing domain repository/query service.
4. If writing SQL or `EntityManager` directly is necessary, explain the reason and boundary in a class comment to prevent it from becoming the default pattern.
