# Namespace and Team Management

## Feature Description

A Namespace is the core organizational unit in SkillHub. Each namespace represents a team or project and has its own members, permissions, and skill packages.

![Concept diagram](/diagrams/namespace-concept.png)

**What namespaces do**:

- **Isolation**: Skills from different teams do not interfere with each other
- **Permissions**: Role-based access control (RBAC)
- **Collaboration**: Team members can jointly manage skill packages
- **Governance**: Administrators can review, archive, and freeze skill packages

**Role system**:

| Role | Permissions |
|------|------|
| **Owner** | Full control, including deleting the namespace and managing all members |
| **Admin** | Manage members, review skill packages, modify settings |
| **Member** | Publish skill packages, view private skill packages |

**Namespace status**:

- **Active**: Operating normally
- **Frozen**: Frozen state; no new skill packages can be published
- **Archived**: Archived state; hidden from search results

## Use Cases

**Scenario 1: Create a team namespace**

A team lead creates a new namespace to manage the team's skill packages.

![Screenshot](/screenshots/namespace-create.png)

**Scenario 2: Add team members**

An admin invites new members to join the namespace and assigns appropriate roles.

![Screenshot](/screenshots/namespace-members.png)

**Scenario 3: Permission management**

Adjust member roles to control who can publish, review, and manage skill packages.

**Scenario 4: Namespace freeze**

A security issue is discovered in a namespace, so all publish operations are temporarily frozen.

## Usage Steps

**Create a namespace**:

1. Go to `/dashboard/namespaces`
2. Click "Create Namespace"
3. Fill in the details:
   - Name: Team name (e.g. "iFlytek AI Team")
   - Slug: URL identifier (e.g. "iflytek")
   - Description: Brief summary of the team's responsibilities and skill package scope

![Flow diagram](/diagrams/namespace-create-flow.png)

4. Submit to create; the system automatically sets you as the Owner

**Add members**:

1. Go to the namespace detail page
2. Click the "Members" tab
3. Click "Add Member"
4. Search for users (supports searching by username or email)
5. Select a role (Owner / Admin / Member)
6. Confirm the addition

**Manage permissions**:

1. Find the target user in the member list
2. Click "Change Role"
3. Select the new role and confirm
4. The system will record the permission change in the audit log

**Freeze a namespace**:

1. Go to namespace settings
2. Click "Freeze Namespace"
3. Enter a freeze reason (optional)
4. Confirm the freeze

> After freezing, no new versions of skill packages within the namespace can be published, but existing versions can still be downloaded.

## API Reference

**Create namespace**:
```bash
POST /api/v1/namespaces
Content-Type: application/json

{
  "name": "iFlytek AI Team",
  "slug": "iflytek",
  "description": "iFlytek's AI agent skills"
}
```

**Parameter description**:
| Parameter | Type | Description |
|------|------|------|
| name | string | Namespace name (required, 2-50 characters) |
| slug | string | URL identifier (required, unique, 2-64 characters, lowercase letters, digits, and hyphens only) |
| description | string | Description (optional, up to 500 characters) |

**Get namespace detail**:
```bash
GET /api/v1/namespaces/{slug}
```

**Update namespace**:
```bash
PUT /api/v1/namespaces/{slug}
Content-Type: application/json

{
  "name": "iFlytek AI Team (Updated)",
  "description": "Updated description"
}
```

**Add member**:
```bash
POST /api/v1/namespaces/{slug}/members
Content-Type: application/json

{
  "userId": "user-123",
  "role": "MEMBER"
}
```

**Update member role**:
```bash
PUT /api/v1/namespaces/{slug}/members/{userId}/role
Content-Type: application/json

{
  "role": "ADMIN"
}
```

**Remove member**:
```bash
DELETE /api/v1/namespaces/{slug}/members/{userId}
```

**Freeze namespace**:
```bash
POST /api/v1/namespaces/{slug}/freeze
Content-Type: application/json

{
  "reason": "Security investigation"
}
```

**Unfreeze namespace**:
```bash
POST /api/v1/namespaces/{slug}/unfreeze
```

## Notes

> **Slug uniqueness**: The namespace slug must be globally unique and cannot be changed after creation. Use a short identifier for your team or project.

- **Owner permission**: Each namespace requires at least one Owner; the last Owner cannot be removed
- **Role inheritance**: Namespace members automatically have access to all skill packages within that namespace
- **Freeze mechanism**: Admins can freeze a namespace; once frozen, no new skill packages can be published
- **Archive mechanism**: Archived namespaces are hidden from search results, but existing skill packages remain accessible
- **Audit log**: All member changes and permission adjustments are recorded in the audit log
