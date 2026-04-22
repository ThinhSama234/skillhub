---
title: API Overview
sidebar_position: 1
description: SkillHub API overview
---

# API Overview

SkillHub provides a RESTful API for integration and automation.

## API Categories

### Public API
- Skill search
- Skill details
- Version listing
- Skill download
- No authentication required (PUBLIC skills)

### Authenticated API
- Publish skills
- Star / rate
- Namespace management
- Requires login or Bearer Token

### CLI Compatibility Layer
- Compatible with the ClawHub CLI protocol
- Existing tools can migrate seamlessly

## Response Format

### Unified Response Structure

```json
{
  "code": 0,
  "msg": "success",
  "data": {},
  "timestamp": "2026-03-15T06:00:00Z",
  "requestId": "req-123"
}
```

### Paginated Response

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "items": [],
    "total": 100,
    "page": 1,
    "size": 20
  },
  "timestamp": "2026-03-15T06:00:00Z",
  "requestId": "req-123"
}
```

## Authentication Methods

### Session Cookie
Web clients authenticate using Session Cookies.

### Bearer Token
CLI and API integrations use Bearer Tokens:

```bash
Authorization: Bearer <token>
```

### API Token
Long-lived API Tokens can be created for automation.

## Idempotency

All write operations support the `X-Request-Id` header for idempotency:

```bash
X-Request-Id: <uuid-v4>
```

## Next Steps

- [Public API](./public) - View public endpoints
