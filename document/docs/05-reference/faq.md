---
title: FAQ
sidebar_position: 1
description: Frequently asked questions
---

# FAQ

## Deployment

### How do I change the default port?

Modify the port configuration in `.env.release`.

### How do I configure HTTPS?

It is recommended to use a reverse proxy (Nginx/Ingress) to handle TLS termination.

### How do I back up the database?

Use the standard PostgreSQL backup tool (`pg_dump`).

## Usage

### How do I reset the admin password?

If you forget the admin password, you can re-set the initial admin via environment variables, or modify the database directly.

### What should I do if a skill package upload fails?

Check:
1. Whether the file size exceeds the limit
2. Whether the file type is on the allowlist
3. Whether the required `SKILL.md` is included
4. Whether the `SKILL.md` frontmatter format is correct

## Development

### How do I extend the OAuth Provider?

Refer to the existing GitHub implementation and add configuration for the new OAuth Provider.

### How do I customize the search implementation?

Implement the `SearchIndexService` and `SearchQueryService` interfaces.

## Next Steps

- [Troubleshooting](./troubleshooting) - Problem diagnosis
