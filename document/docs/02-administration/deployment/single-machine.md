---
title: Single-Machine Deployment
sidebar_position: 1
description: Deploy SkillHub on a single machine using Docker Compose
---

# Single-Machine Deployment

This document describes how to deploy SkillHub on a single server using Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose Plugin 2.0+
- At least 4GB available memory
- At least 20GB available disk space

## Quick Deployment

```bash
# 1. Clone the repository
git clone https://github.com/iflytek/skillhub.git
cd skillhub

# 2. Copy the environment variable template
cp .env.release.example .env.release

# 3. Edit configuration
# Modify the configuration options in .env.release, especially passwords and the public URL

# 4. Validate configuration
make validate-release-config

# 5. Start services
docker compose --env-file .env.release -f compose.release.yml up -d
```

## Configuration Reference

See the [Configuration Reference](./configuration) document for details.

## Verify Deployment

```bash
# Check container status
docker compose --env-file .env.release -f compose.release.yml ps

# Check backend health status
curl -i http://127.0.0.1:8080/actuator/health

# Access the Web UI
# Open http://localhost (or the configured public URL) in a browser
```

## Initial Login Setup

1. Log in using `BOOTSTRAP_ADMIN_USERNAME` and `BOOTSTRAP_ADMIN_PASSWORD` (default `admin` / `ChangeMe!2026`)
2. Change the admin password immediately
3. Configure enterprise SSO (optional)
4. Create team namespaces

## Next Steps

- [Configuration Reference](./configuration) - Detailed configuration options
- [Kubernetes Deployment](./kubernetes) - High availability deployment
