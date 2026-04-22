---
title: Authorization
sidebar_position: 2
description: RBAC permission system configuration
---

# Authorization

SkillHub uses a Role-Based Access Control (RBAC) system.

In the current codebase there are actually two parallel role systems:

- Platform roles: control platform-level capabilities such as backend governance, user management, and auditing.
- Namespace roles: control operations within a specific team space, such as managing members, publishing, reviewing, and archiving.

Both systems participate in authorization simultaneously, but they are not a parent-child mapping of a single role hierarchy.

## Platform Roles

### Explicit Platform Roles Initialized in Code

The database migration only initializes 4 explicit platform roles:

| Role | Code | Actual Capabilities |
|------|------|---------------------|
| Super Administrator | `SUPER_ADMIN` | Has all permissions; `RbacService#getUserPermissions` returns all permission codes directly; can access all endpoints accessible by `SUPER_ADMIN`/`SKILL_ADMIN`/`USER_ADMIN`/`AUDITOR`; can assign `SUPER_ADMIN`; can bypass namespace membership checks when publishing a skill and auto-publish directly; however, cannot approve a promotion they submitted themselves, and for regular reviews submitted by themselves, only `SUPER_ADMIN` has a special-case allowance to approve. |
| Skill Administrator | `SKILL_ADMIN` | Can access skill governance backend APIs; can hide/unhide skills, yank versions, handle skill reports; can view and process global space reviews, promotion reviews, and review/promotion/report items in the governance workbench inbox; cannot assign platform roles, cannot view audit logs, cannot manage users. |
| User Administrator | `USER_ADMIN` | Can access user management APIs; can list users, approve users, enable/disable users, and modify platform roles; cannot assign `SUPER_ADMIN`; cannot handle skill governance or view audit logs. |
| Auditor | `AUDITOR` | Read-only access to audit logs; can access `/api/v1/admin/audit-logs` and `/actuator/prometheus`; in the governance workbench can only view activity — cannot process review/promotion/report items, and cannot manage users or skills. |

### Runtime Default Platform Role

| Role | Code | Actual Logic |
|------|------|--------------|
| Default User | `USER` | Not an explicitly initialized record in the `role` table. As long as a user has no explicit platform role binding, both the login session and `RbacService#getUserRoleCodes` will automatically fall back to `USER`. It primarily represents "a regular logged-in user" with no additional backend governance permissions. |

### Important Implementation Details

- The "modify user role" management API is a single-value overwrite, not an append: `PUT /api/v1/admin/users/{userId}/role` clears all existing platform roles for the user first, then writes one target role; when the target role is `USER`, no database record is written — the runtime default fallback is used instead.
- The underlying code still supports reading and authorizing "a user with multiple explicit platform roles," because sessions, tokens, and `RbacService` all operate on a set of roles; the current management API simply does not assign them this way.
- `SUPER_ADMIN` is the only role treated as "having all permission codes" during permission queries; all other roles depend on the `role_permission` association table.

## Namespace Roles

| Role | Actual Capabilities |
|------|---------------------|
| `OWNER` | Automatically becomes `OWNER` when a team space is created. Can update namespace information, manage members, freeze/unfreeze the space, archive/restore the space, and transfer ownership; can submit reviews; can approve team space reviews; can access private skills; can manage restricted skill lifecycles (archiving, unarchiving, deleting drafts/rejected versions, etc.). |
| `ADMIN` | Can update namespace information, manage members, and freeze/unfreeze the space; cannot archive/restore the space or directly set someone else as `OWNER`; can submit reviews; can approve team space reviews; can access private skills; can manage restricted skill lifecycles. |
| `MEMBER` | Obtained by default when joining the global space. Can publish skills and submit reviews within their namespace; cannot approve reviews, cannot manage members, cannot freeze/archive the space; private skills are also not accessible solely by virtue of `MEMBER` status — private skills require being the owner or having `ADMIN/OWNER` role. |

### Namespace Role Boundaries

- The `GLOBAL` space is a read-only system space and cannot be modified through namespace governance APIs; processing reviews/promotions/reports in the global space depends on the platform roles `SKILL_ADMIN`/`SUPER_ADMIN`, not on global space membership.
- Skills with `NAMESPACE_ONLY` visibility can be accessed by any member of that namespace.
- Skills with `PRIVATE` visibility can only be accessed by the skill owner or namespace `ADMIN/OWNER` — `MEMBER` cannot access them.

## Permission Configuration

Platform roles are assigned through the admin panel; namespace roles are assigned through namespace membership.

## Next Steps

- [Audit Logs](./audit-logs) - View operation audit logs
