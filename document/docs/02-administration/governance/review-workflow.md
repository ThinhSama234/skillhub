---
title: Review Workflow
sidebar_position: 2
description: Skill publishing review workflow configuration
---

# Review Workflow

SkillHub uses a two-tier review mechanism to ensure skill quality.

## Review Process

### Team Space Skills

1. A team member submits for publishing
2. A review task is created (PENDING)
3. The team ADMIN or OWNER reviews it
   - Approved → skill is published (PUBLISHED)
   - Rejected → returned for revision (REJECTED)

### Global Space Skills

1. Submit for publishing
2. A platform SKILL_ADMIN or SUPER_ADMIN reviews it
3. The skill is published after approval

## Promoting a Team Skill to Global

1. The team skill must already be published
2. The team ADMIN or OWNER applies for "Promote to Global"
3. A platform administrator reviews the application
4. A new skill is created in the global space after approval

## Review Permissions

| Review Type | Required Role |
|-------------|---------------|
| Team space skill review | Namespace ADMIN/OWNER |
| Global space skill review | SKILL_ADMIN/SUPER_ADMIN |
| Promotion request review | SKILL_ADMIN/SUPER_ADMIN |

## Next Steps

- [User Management](./user-management) - Manage platform users
