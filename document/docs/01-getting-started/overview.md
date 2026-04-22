---
title: Product Overview
sidebar_position: 1
description: SkillHub product overview and core feature introduction
---

# Product Overview

SkillHub is an enterprise-grade AI skill registry platform that supports skill publishing, discovery, and management, using a self-hosted architecture to ensure data security.

## Core Features

### Release Management
- Version control with Semantic Versioning
- Custom tags (e.g. `beta`/`stable`)
- `latest` tag automatically tracks the most recent published version

### Discovery Mechanism
- Full-text search
- Multi-dimensional filtering (namespace, downloads, rating)
- Visibility control (public / namespace-scoped / private)

### Organizational Structure
- Namespace isolation
- Role-based access control (RBAC)
- Team and global dual-layer spaces

### Governance
- Two-tier review workflow
- Audit logs
- Separation of permissions

### Storage and Deployment
- Supports S3 / MinIO / local storage
- Docker / Kubernetes deployment
- Enterprise-grade observability

## Technology Stack

### Backend
- **Java 21** - Runtime
- **Spring Boot 3.2.3** - Application framework
- **PostgreSQL 16.x** - Primary database + full-text search
- **Redis 7.x** - Cache and session storage

### Frontend
- **React 19** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling framework

### Deployment
- **Docker Compose** - Single-machine deployment
- **Kubernetes** - Production orchestration

## Core Concepts

### Namespace
Skill isolation boundary, supporting `@global` (global) and `@team-*` (team) prefixes.

### Coordinate System
Skill identifier format is `@{namespace_slug}/{skill_slug}`, with semantic versioning support.

### Compatibility
Provides a REST API and a ClawHub compatibility layer to support integration with existing tooling.

## Next Steps

- [Quick Start](./quick-start) - Launch and experience it with one command
- [Typical Use Cases](./use-cases) - Learn how to apply it in an enterprise
