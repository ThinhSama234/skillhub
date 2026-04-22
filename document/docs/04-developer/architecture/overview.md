---
title: System Architecture
sidebar_position: 1
description: SkillHub system architecture overview
---

# System Architecture

## Architecture Principles

- **Monolith-first**: Phase 1 uses a modular monolith — no microservices split
- **Dependency inversion**: The domain layer does not depend on infrastructure
- **Replaceable boundaries**: Both search and storage have SPI abstractions

## Module Structure

```
server/
├── skillhub-app/          # Startup, configuration assembly, Controllers
├── skillhub-domain/       # Domain models + domain services + application services
├── skillhub-auth/         # OAuth2 authentication + RBAC + authorization decisions
├── skillhub-search/       # Search SPI + PostgreSQL full-text implementation
├── skillhub-storage/      # Object storage abstraction + LocalFile/S3
└── skillhub-infra/        # JPA, common utilities, configuration base
```

## Module Dependencies

```
app → domain, auth, search, storage, infra
infra → domain
auth → domain
search → domain
storage → (standalone)
```

## Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Runtime | Java | 21 |
| Framework | Spring Boot | 3.2.3 |
| Database | PostgreSQL | 16.x |
| Cache/Session | Redis | 7.x |

## Deployment Architecture

```
┌──────────────┐
│ Browser / CLI│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Web/Nginx   │
└──────┬───────┘
       │ /api/*
       ▼
┌──────────────┐
│ Spring Boot  │
└───┬────┬─────┘
    │    │
    ▼    ▼
PostgreSQL  Redis
```

## Next Steps

- [Domain Model](./domain-model) - Core entities
