---
title: Version Management
sidebar_position: 3
description: Managing skill versions and tags
---

# Version Management

## Semantic Versioning

SkillHub uses Semantic Versioning: `MAJOR.MINOR.PATCH`

- `MAJOR`: Incompatible API changes
- `MINOR`: Backward-compatible new features
- `PATCH`: Backward-compatible bug fixes

Examples: `1.0.0`, `1.1.0`, `2.0.0`

## The latest Tag

`latest` is a system-reserved tag that automatically follows the most recently published version and cannot be moved manually.

## Custom Tags

You can create custom tags for version channel management:

- `beta` - Beta release
- `stable` - Stable release
- `stable-2026q1` - Quarterly stable release

### Create / Move a Tag

```bash
clawhub tag set @team/my-skill beta 1.2.0
```

### Delete a Tag

```bash
clawhub tag delete @team/my-skill beta
```

## Yanking a Version

If a problem is found in a published version, it can be yanked:

1. Go to the skill detail page
2. Locate the target version
3. Click "Yank Version"
4. Confirm the action

A yanked version remains visible but is marked as not recommended for use.

## Next Steps

- [Search Skills](../discovery/search) - Discover skills
