# Project Introduction

SkillHub is a self-hosted Agent Skill registry built for enterprises.

In the era of AI Agents, every team is accumulating its own skill packages (Skills). But these skill packages are scattered everywhere: some are on developers' local machines, some are in Git repositories, and some are in internal documentation. Team members have a hard time discovering each other's work, and reusing existing capabilities is even harder.

SkillHub solves this problem. It provides a **private, controlled, and easy-to-use** skill package registry so that teams can manage Agent Skills the same way they use npm or PyPI.

![Project Architecture Diagram](/diagrams/architecture.png)

## Core Value

- **Publish in 3 minutes**: From local development to global distribution with a single command
- **Enterprise-grade permissions**: Namespace-based RBAC supporting team collaboration and review workflows
- **Complete lifecycle**: Version management, label system, review workflow, and archiving mechanism
- **Out of the box**: Start a complete environment with a single curl command
- **Security scanning**: Built-in Skill Scanner to automatically detect security risks
- **Data sovereignty**: Fully self-hosted; all data stays within your firewall

## Technology Stack

![Technology Stack Diagram](/diagrams/tech-stack.png)

| Layer | Technology | Description |
|------|------|------|
| **Frontend** | React 19 + Vite + TanStack Router | Modern SPA with English/Chinese language switching |
| **Backend** | Java 21 + Spring Boot 3.2 | Enterprise-grade REST API |
| **Database** | PostgreSQL 16 | Full-text search, Flyway auto-migration |
| **Cache** | Redis 7 | Session management, hot data caching |
| **Storage** | MinIO / S3 | Skill package file storage, supports local and cloud |
| **Deployment** | Docker Compose / K8s | One-command startup, supports self-hosting |

## Core Features Overview

| Feature | Description |
|------|------|
| [Skill Publishing and Version Management](/guide/skill-publish) | One-command skill package publishing, semantic versioning |
| [Skill Search and Discovery](/guide/skill-discovery) | Full-text search, intelligent filtering, permission-aware |
| [Namespace and Team Management](/guide/namespace) | Namespace-based RBAC permission system |
| [Review and Governance](/guide/review) | Multi-level review workflow, reporting system |
| [Security Scanning](/guide/scanner) | Built-in Skill Scanner with multi-engine security analysis |
| [User Interaction and Social](/guide/social) | Stars, ratings, notification system |
