# OpenClaw Integration Guide

This document explains how to configure the OpenClaw CLI to connect to a SkillHub private registry for publishing, searching, and downloading skills.
> Not limited to OpenClaw — by specifying the installation directory, this also applies to other CLI Coding Agents (Claude Code, OpenCode, Qcoder, etc.) or Agent assistants (Nanobot, CoPaw, etc.).

## Overview

SkillHub provides a ClawHub-compatible API layer that allows the OpenClaw CLI to seamlessly connect to a private registry. With a simple configuration, you can:

- Search for private skills within your organization
- Download and install skill packages
- Publish new skills to the private registry
- Star and rate skills

## Quick Start

### 1. Configure the Registry Address

Set the SkillHub registry address in the OpenClaw configuration file:

```bash
# Configure via environment variable (temporary)
export CLAWHUB_REGISTRY=https://skillhub.your-company.com
```

### 2. Authentication (Optional)

For **public skills (PUBLIC) in the global namespace (@global)**, no login is required to download. Authentication is required for:

- Skills in team namespaces (regardless of visibility)
- NAMESPACE_ONLY or PRIVATE skills
- Write operations such as publishing or starring

```bash
# Log in with an API Token
npx clawhub login --token YOUR_API_TOKEN
# If clawhub is installed via npm i -g clawhub, all npx clawhub commands in this document can be run directly as clawhub commands

# View the currently logged-in user
npx clawhub whoami

# Log out the current user
npx clawhub logout

# View help
npx clawhub --help
```

#### Obtaining an API Token

1. Log in to the SkillHub Web UI
2. Go to **Personal Settings → API Tokens**
3. Click **Create New Token**
4. Set the token name and permission scope
5. Copy the generated token

### 3. Search / Browse / View Skills

```bash
# Search, display all matching skills
npx clawhub search <skill-name>
# Search, display the top 5 results
npx clawhub search <skill-name> --limit 5  
# Display skill details
npx clawhub inspect <skill-name>
# Browse the latest skills
npx clawhub explore
npx clawhub explore --limit 20    # top 20

# Examples
npx clawhub search find-skills
npx clawhub search find-skills --limit 5 
npx clawhub inspect find-skills

# Help
npx clawhub search --help
npx clawhub inspect --help
```

### 4. Install / Update / Uninstall Skills

```bash
# Install
npx clawhub install <skill-name>
npx clawhub install <skill-name> --version <version number>   # specify version
npx clawhub install <skill-name> --force                      # overwrite existing
npx clawhub --dir <install-path> install <skill-name>         # specify directory

# Update
npx clawhub update <skill-name>
npx clawhub update --all

# Uninstall
npx clawhub uninstall <skill-name>

# View installed skills
npx clawhub list

# Claude Code skill installation examples
npx clawhub --dir ~/.claude/skills install find-skills
CLAWHUB_WORKDIR=~/.claude/skills npx clawhub install find-skills

# Help
npx clawhub install --help
npx clawhub update --help
npx clawhub uninstall --help
npx clawhub list --help
```

### 5. Publish Skills

```bash
# Publish to the global namespace (requires appropriate permissions)
npx clawhub publish ./my-skill --slug my-skill --name "My Skill" --version 1.0.0

# Publish to a team namespace such as my-space
npx clawhub publish ./my-skill --slug my-space--my-skill --name "My Skill" --version 1.0.0
npx clawhub sync --all # upload all skills in the current directory

# Help
npx clawhub publish --help
npx clawhub sync --help
```

Notes:
- `my-space--my-skill` is the compatibility layer canonical slug; SkillHub will parse it into namespace `my-space` and skill slug `my-skill`
- To avoid inconsistencies between CLI display and the server's final coordinates, it is recommended to keep the `name` in `SKILL.md` consistent with the second part of the canonical slug

## API Endpoint Reference

SkillHub's compatibility layer provides the following endpoints:

| Endpoint | Method | Description | Auth Required |
|------|------|------|----------|
| `/api/v1/whoami` | GET | Get current user info | Required |
| `/api/v1/search` | GET | Search skills | Optional |
| `/api/v1/resolve` | GET | Resolve skill version | Optional |
| `/api/v1/download/{slug}` | GET | Download skill (redirect) | Optional* |
| `/api/v1/download` | GET | Download skill (query params) | Optional* |
| `/api/v1/skills/{slug}` | GET | Get skill details | Optional |
| `/api/v1/skills/{slug}/star` | POST | Star a skill | Required |
| `/api/v1/skills/{slug}/unstar` | DELETE | Unstar a skill | Required |
| `/api/v1/publish` | POST | Publish a skill | Required |

Notes:
- The compatibility layer continues to use "latest" semantics externally, but this strictly refers to "the latest published version"
- The compatibility layer's internal implementation should map from the `publishedVersion` of a unified lifecycle projection, not infer "current version" independently

\* Download endpoint auth requirements:
- **PUBLIC skills in the global namespace (@global)**: No auth required
- **All skills in team namespaces**: Auth required
- **NAMESPACE_ONLY and PRIVATE skills**: Auth required

## Skill Visibility Explained

SkillHub supports three skill visibility levels, with the following download permission rules:

### PUBLIC
- Any person can search and view
- **Global namespace (@global)**: Can be downloaded without login
- **Team namespaces**: Login authentication required to download
- Suitable for universally usable, publicly shareable skills within the organization

### NAMESPACE_ONLY
- Namespace members can search and view
- Login and namespace membership required to download
- Suitable for team-internal skills

### PRIVATE
- Only the owner can view
- Login and ownership required to download
- Suitable for skills under personal development

**Important notes:**
- PUBLIC skills in the global namespace (`@global`) support anonymous download for broad distribution within the organization
- All skills in team namespaces (including PUBLIC) require authentication to ensure team boundary security

## Canonical Slug Mapping Rules

SkillHub uses the `@{namespace}/{skill}` format internally, but the compatibility layer automatically converts to ClawHub-style canonical slugs:

| SkillHub Internal Coordinates | Canonical Slug | Description |
|-------------------|----------------|------|
| `@global/my-skill` | `my-skill` | Global namespace skill |
| `@my-team/my-skill` | `my-team--my-skill` | Team namespace skill |

The OpenClaw CLI uses canonical slug format; SkillHub handles the conversion automatically.

## Configuration Examples

### ClawHub CLI Environment Variable Configuration

The ClawHub CLI is configured via environment variables:

```bash
# Registry configuration
export CLAWHUB_REGISTRY=https://skillhub.your-company.com

# If auth is needed, log in once first
clawhub login --token sk_your_api_token_here
```

### Environment Variable Configuration

```bash
# Registry configuration
export CLAWHUB_REGISTRY=https://skillhub.your-company.com

# Optional: log in before running commands that require auth
clawhub login --token sk_your_api_token_here
```

## Frequently Asked Questions

### Q: How do I switch back to the public ClawHub?

```bash
# Unset the custom registry
unset CLAWHUB_REGISTRY

# The ClawHub CLI will use the default public registry
```

### Q: Getting a 403 Forbidden when downloading a skill?

Possible causes:
1. The skill belongs to a team namespace and requires login
2. The skill is NAMESPACE_ONLY or PRIVATE and requires login
3. You are not a member of that namespace
4. The API Token has expired

Solution:
```bash
# Set a new token and log in again
clawhub login --token YOUR_NEW_TOKEN

# Test the connection
curl https://skillhub.your-company.com/api/v1/whoami \
  -H "Authorization: Bearer YOUR_NEW_TOKEN"
```

**Tip**: PUBLIC skills in the global namespace (@global) can be downloaded anonymously without authentication.

### Q: How do I view all skills I have access to?

```bash
# Search all skills (filtered by your permissions)
npx clawhub search ""
```

### Q: Getting "insufficient permissions" when publishing a skill?

- Publishing to the global namespace (`@global`) requires `SUPER_ADMIN` permission
- Publishing to a team namespace requires being an OWNER or ADMIN of that namespace
- Contact your administrator to be assigned the appropriate permissions

### Q: Which OpenClaw versions are supported?

SkillHub's compatibility layer is designed to be compatible with tools using the ClawHub CLI. The ClawHub CLI is distributed via npm:

```bash
# Install the ClawHub CLI
npm install -g clawhub

# Or run directly with npx
npx clawhub install my-skill
```

If you encounter compatibility issues, please submit an issue.

## API Response Formats

### Search Response Example

```json
{
  "results": [
    {
      "slug": "my-team--email-sender",
      "name": "Email Sender",
      "description": "Send emails via SMTP",
      "author": {
        "handle": "user123",
        "displayName": "John Doe"
      },
      "version": "1.2.0",
      "downloadCount": 150,
      "starCount": 25,
      "createdAt": "2026-01-15T10:00:00Z",
      "updatedAt": "2026-03-10T14:30:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20
}
```

### Version Resolution Response Example

```json
{
  "slug": "my-skill",
  "version": "1.2.0",
  "downloadUrl": "/api/v1/skills/global/my-skill/versions/1.2.0/download"
}
```

### Publish Response Example

```json
{
  "id": "12345",
  "version": {
    "id": "67890"
  }
}
```

## Security Recommendations

1. **Use HTTPS**: Always use HTTPS connections in production environments
2. **Token management**:
   - Rotate API tokens regularly
   - Do not hardcode tokens in your code
   - Use environment variables or secrets management tools
3. **Principle of least privilege**: Assign the minimum required permissions to tokens
4. **Audit logs**: Regularly review SkillHub audit logs

## Troubleshooting

### Enable Debug Logging

```bash
# View detailed request logs
DEBUG=clawhub:* npx clawhub search my-skill

# Or use verbose mode
npx clawhub --verbose install my-skill
```

### Test Connectivity

```bash
# Test registry connection
curl https://skillhub.your-company.com/api/v1/whoami \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test search
curl "https://skillhub.your-company.com/api/v1/search?q=test"
```

## Further Reading

- [SkillHub API Design Document](./06-api-design.md)
- [Skill Protocol Specification](./07-skill-protocol.md)
- [Authentication and Authorization](./03-authentication-design.md)
- [Deployment Guide](./09-deployment.md)

## Support

For questions or suggestions:
- View the full documentation: https://zread.ai/iflytek/skillhub
- GitHub Discussions: https://github.com/iflytek/skillhub/discussions
- Submit an Issue: https://github.com/iflytek/skillhub/issues
