---
title: Security Architecture
sidebar_position: 3
description: Security architecture design
---

# Security Architecture

## Authentication Architecture

### OAuth2 Login

- Based on Spring Security OAuth2 Client
- Phase 1 supports GitHub
- Architecture supports extending to multiple providers

### CLI Authentication

- OAuth Device Flow
- CLI credentials issued after web authorization
- Supports API Tokens

### Session Management

- Spring Session + Redis
- Distributed session sharing
- Supports multi-pod deployment

## Authorization Architecture

### Platform Roles

| Role | Permissions |
|------|-------------|
| `SUPER_ADMIN` | All permissions |
| `SKILL_ADMIN` | Skill governance |
| `USER_ADMIN` | User governance |
| `AUDITOR` | Audit read-only |

### Namespace Roles

| Role | Permissions |
|------|-------------|
| `OWNER` | Namespace owner |
| `ADMIN` | Review, member management |
| `MEMBER` | Publish skills |

### Visibility Rules

| Visibility | Who Can Access |
|------------|----------------|
| `PUBLIC` | Anyone (anonymous) |
| `NAMESPACE_ONLY` | Namespace members |
| `PRIVATE` | Owner + namespace ADMIN |

## Audit

All key operations are written synchronously to the audit log:
- Publish, download, delete
- Review approval, rejection
- Permission changes
- Configuration changes

## Rate Limiting

- Ingress-level basic rate limiting (Nginx)
- Application-level fine-grained rate limiting (Redis sliding window)

## Next Steps

- [Skill Protocol](../plugins/skill-protocol) - Skill package specification
