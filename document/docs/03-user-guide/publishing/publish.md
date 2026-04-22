---
title: Publishing Process
sidebar_position: 2
description: Publish a skill to SkillHub
---

# Publishing Process

## Publish via Web

1. Log in to SkillHub
2. Click "Publish Skill"
3. Select the target namespace
4. Upload the skill package ZIP file
5. Fill in version information (changelog, etc.)
6. Submit for publishing
7. Wait for review (if required)
8. Once approved, the skill is published successfully

## Publish via CLI

```bash
# 1. Log in
clawhub login

# 2. Publish
clawhub publish ./my-skill.zip --namespace @team-myteam
```

## Publish via ClawHub CLI

After configuring the registry:

```bash
clawhub publish ./my-skill.zip
```

## Publication Status

| Status | Description |
|--------|-------------|
| `DRAFT` | Draft; not yet submitted for review |
| `PENDING_REVIEW` | Awaiting review |
| `PUBLISHED` | Published; discoverable and downloadable |
| `REJECTED` | Rejected; must be revised and resubmitted |
| `YANKED` | Yanked; no longer recommended for use |

## Next Steps

- [Version Management](./versioning) - Manage skill versions
