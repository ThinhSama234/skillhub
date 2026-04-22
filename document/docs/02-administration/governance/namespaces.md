---
title: Namespace Management
sidebar_position: 1
description: Namespace creation and management
---

# Namespace Management

A namespace is an isolation boundary and collaboration unit for skills in SkillHub.

## Namespace Types

| Type | Prefix | Description |
|------|--------|-------------|
| Global | `@global` | Platform-level public space, managed by platform administrators |
| Team | `@team-*` | Team/department space, managed by team administrators |

## Creating a Namespace

1. Log in and go to "My Namespaces"
2. Click "Create Namespace"
3. Fill in the details:
   - Identifier (slug): URL-friendly name
   - Display name: The name shown in the UI
   - Description: Purpose of the space
4. Submit to create

## Namespace Member Management

### Adding Members

1. Go to namespace settings
2. Go to "Member Management"
3. Search by username
4. Select a role (OWNER/ADMIN/MEMBER)
5. Confirm to add

### Changing Roles

A namespace OWNER or ADMIN can change member roles.

### Removing Members

A namespace OWNER or ADMIN can remove members.

## Namespace Status

| Status | Description |
|--------|-------------|
| `ACTIVE` | In normal use |
| `FROZEN` | Frozen — read-only, publishing is not allowed |
| `ARCHIVED` | Archived — not visible to the public |

## Next Steps

- [Review Workflow](./review-workflow) - Learn about skill reviews
