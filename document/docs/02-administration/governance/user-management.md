---
title: User Management
sidebar_position: 3
description: Platform user management
---

# User Management

## User Status

| Status | Actual Logic |
|--------|--------------|
| `ACTIVE` | Can log in and use the system normally. OAuth first-time auto-admission and successful local registration both result in this status. |
| `PENDING` | Account created but cannot log in. Under the "requires approval" policy, OAuth creates a `PENDING` user and redirects to the pending-approval page; local login will be directly rejected if this status is encountered. |
| `DISABLED` | Cannot log in. Both OAuth and local login will be rejected; when `/api/v1/auth/me` detects that the user associated with the current session has been disabled, it will immediately clear the session. |
| `MERGED` | Account has been merged into another account and can no longer log in; this status is primarily written by the account-merge flow and is not a target state in the normal user management process. |

## User Admission

You can configure whether new users require approval:
- Auto-admission: new users are automatically activated upon login
- Approval-based admission: new users must be approved by a USER_ADMIN before activation

## Role Assignment

`USER_ADMIN` or `SUPER_ADMIN` can call the user management API to change platform roles. However, there are a few key points about the current implementation:

- The API can only set one target platform role at a time.
- When setting a role, all existing explicit platform roles for that user are removed before the new role is written.
- If the target role is `USER`, no record is written to `user_role_binding`; the runtime default role fallback is used instead.
- `USER_ADMIN` cannot assign `SUPER_ADMIN`; only a `SUPER_ADMIN` can do that.

The target roles that can currently be set through the management API are:

- `USER`
- `SKILL_ADMIN`
- `USER_ADMIN`
- `AUDITOR`
- `SUPER_ADMIN`

## Banning / Unbanning Users

`USER_ADMIN` or `SUPER_ADMIN` can ban or unban users.

The current public management API only supports changing the status to:

- `ACTIVE`
- `DISABLED`

Notes:

- "Approve" essentially also changes the user's status to `ACTIVE`.
- The status cannot be changed directly to `PENDING` or `MERGED` via this API.

## Account Merging

Merging multiple accounts into one is supported, with the operation history preserved.

## Next Steps

- [Create a Skill Package](../../user-guide/publishing/create-skill) - Start publishing skills
