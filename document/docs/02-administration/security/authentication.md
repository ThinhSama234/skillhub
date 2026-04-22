---
title: Authentication Configuration
sidebar_position: 1
description: Configure user authentication methods
---

# Authentication Configuration

SkillHub supports multiple authentication methods to meet the security requirements of different enterprises.

## OAuth2 Login

### GitHub OAuth

1. Create an OAuth App on GitHub
2. Configure environment variables:
   ```bash
   OAUTH2_GITHUB_CLIENT_ID=your-client-id
   OAUTH2_GITHUB_CLIENT_SECRET=your-client-secret
   ```

### Extending OAuth Providers

The architecture supports extending to other OAuth providers, such as GitLab, Gitee, etc.

## Local Account Login

Local account login is supported in development environments and is disabled by default in production.

## Enterprise SSO Integration

Integration with enterprise SSO (SAML/OIDC) is supported via extension points.

## Next Steps

- [Authorization](./authorization) - Configure access control
