---
title: Configuration Reference
sidebar_position: 3
description: Detailed description of SkillHub configuration options
---

# Configuration Reference

## Environment Variables

SkillHub is configured through environment variables. The main configuration options are as follows:

### Basic Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `SKILLHUB_PUBLIC_BASE_URL` | Public access URL | - |
| `SKILLHUB_VERSION` | Image version | `edge` |

### Database Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `POSTGRES_HOST` | PostgreSQL host | `postgres` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_DB` | Database name | `skillhub` |
| `POSTGRES_USER` | Database user | `skillhub` |
| `POSTGRES_PASSWORD` | Database password | - |

### Redis Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `REDIS_HOST` | Redis host | `redis` |
| `REDIS_PORT` | Redis port | `6379` |
| `REDIS_PASSWORD` | Redis password | - |

### Storage Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `SKILLHUB_STORAGE_PROVIDER` | Storage provider | `local` |
| `SKILLHUB_STORAGE_S3_ENDPOINT` | S3 endpoint | - |
| `SKILLHUB_STORAGE_S3_BUCKET` | S3 bucket name | - |
| `SKILLHUB_STORAGE_S3_ACCESS_KEY` | S3 Access Key | - |
| `SKILLHUB_STORAGE_S3_SECRET_KEY` | S3 Secret Key | - |

### OAuth Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `OAUTH2_GITHUB_CLIENT_ID` | GitHub OAuth Client ID | - |
| `OAUTH2_GITHUB_CLIENT_SECRET` | GitHub OAuth Client Secret | - |

### Bootstrap Admin Configuration

| Environment Variable | Description | Default |
|---------|------|--------|
| `BOOTSTRAP_ADMIN_ENABLED` | Enable bootstrap admin | `true` |
| `BOOTSTRAP_ADMIN_USERNAME` | Bootstrap admin username | `admin` |
| `BOOTSTRAP_ADMIN_PASSWORD` | Bootstrap admin password | `ChangeMe!2026` |

## Configuration Files

Spring Boot configuration files are located at `server/skillhub-app/src/main/resources/`.

## Next Steps

- [Authentication Configuration](../security/authentication) - Configure identity authentication
