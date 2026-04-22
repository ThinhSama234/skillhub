---
title: Quick Start
sidebar_position: 2
description: Launch the SkillHub development environment with a single command
---

# Quick Start

## One-command Launch

Use the following command to launch the complete SkillHub environment with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/iflytek/skillhub/main/scripts/runtime.sh | sh -s -- up
```

Or clone the repository and start manually:

```bash
git clone https://github.com/iflytek/skillhub.git
cd skillhub
make dev-all
```

## Default Account

Both startup methods will create a bootstrap admin account by default:

- Username: `admin`
- Password: `ChangeMe!2026`

### `curl` One-click Deployment

| Service | Address |
|---------|---------|
| Web UI | http://localhost |
| Backend API | http://localhost:8080 |

Log in using the default credentials above. **Be sure to change the password in production environments.**

### `make dev-all` Local Development

| Service | Address |
|---------|---------|
| Web UI | http://localhost:3000 |
| Backend API | http://localhost:8080 |
| MinIO Console | http://localhost:9001 |

In addition to the bootstrap admin above, local development also comes with two pre-configured mock users (no password required):

| User | Role | Description |
|------|------|-------------|
| `local-user` | Regular user | Can publish skills and manage namespaces |
| `local-admin` | Super admin | Has all permissions, including review and user management |

Use the `X-Mock-User-Id` request header to switch between mock users.
To disable the bootstrap admin, set `BOOTSTRAP_ADMIN_ENABLED=false` before starting.

## Common Commands

```bash
# Start the full development environment
make dev-all

# Stop all services
make dev-all-down

# Reset and restart
make dev-all-reset

# Start backend only
make dev

# Start frontend only
make dev-web

# Show all available commands
make help
```

## Next Steps

- [Product Overview](./overview) - Dive deeper into product features
- [Typical Use Cases](./use-cases) - Explore enterprise application scenarios
- [Single-machine Deployment](../administration/deployment/single-machine) - Production environment deployment guide
