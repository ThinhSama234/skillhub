# skillhub Domain Model & Data Model

## 0. User Identity Constraints

- The user identity primary key is uniformly `string` throughout the entire system.
- This constraint covers `user_id`, `owner_id`, `created_by`, `updated_by`, `published_by`, `reviewed_by`, `actor_user_id`, and all equivalent semantic fields.
- Any user-related fields written as `bigint` / `BIGINT` in historical documents should be reinterpreted as strings; those old type descriptions no longer serve as implementation references.
- If the database introduces an internal surrogate key in the future for indexing or storage efficiency, it may only be used as an internal implementation detail and cannot replace the string `userId` as the primary key for authentication, authorization, audit, and API contracts.

## 3.1 Core Entities

### namespace

| Field | Type | Description |
|------|------|------|
| id | bigint | Primary key |
| slug | varchar(64) | URL-friendly identifier |
| display_name | varchar(128) | Display name |
| type | enum | `GLOBAL` / `TEAM` |
| description | text | Description |
| avatar_url | varchar(512) | Avatar |
| status | enum | `ACTIVE` / `FROZEN` / `ARCHIVED` |
| created_by | varchar(128) | Creator |
| created_at | datetime | |
| updated_at | datetime | |

- `GLOBAL` type is globally unique (there is only one `@global`), managed by platform administrators
- `TEAM` type corresponds to departments/teams; multiple can be created
- Full skill address: `@{namespace_slug}/{skill_slug}`
- Unique constraint: `slug`
- Slug format validation: `[a-z0-9]([a-z0-9-]*[a-z0-9])?`, length 2–64, and must not contain two or more consecutive hyphens `--` (reserved for compatibility layer coordinate mapping)
- Slug reserved word list (cannot be used when users create a namespace): `admin`, `api`, `dashboard`, `search`, `auth`, `me`, `global`, `system`, `static`, `assets`, `health`
- The system built-in namespace (`@global`) is pre-populated by a Flyway script during database initialization, bypassing slug validation rules. Reserved word validation only applies to the namespace creation endpoint
- Status semantics:
  - `ACTIVE`: normal operation
  - `FROZEN`: frozen, read-only; new versions cannot be published, but existing skills can still be browsed and downloaded
  - `ARCHIVED`: archived, not visible externally

### namespace_member

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| namespace_id | bigint | |
| user_id | varchar(128) | |
| role | enum | `OWNER` / `ADMIN` / `MEMBER` |
| created_at | datetime | |
| updated_at | datetime | |

- `OWNER`: namespace creator; can be transferred
- `ADMIN`: can review skill publications within this namespace and manage members
- `MEMBER`: can publish skills within this namespace (submit for review)
- Unique constraint: `(namespace_id, user_id)` — a user has only one role in a given namespace

### skill

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| namespace_id | bigint | Owning namespace |
| slug | varchar(128) | URL-friendly identifier |
| display_name | varchar(256) | |
| summary | varchar(512) | |
| owner_id | varchar(128) | Primary maintainer (transferable) |
| source_skill_id | bigint | Derived source (records the original skill ID when a team skill is promoted to global); nullable |
| visibility | enum | `PUBLIC` / `NAMESPACE_ONLY` / `PRIVATE` |
| status | enum | `ACTIVE` / `ARCHIVED` |
| latest_version_id | bigint | Latest published pointer; points only to the most recent `PUBLISHED` version; may be `null` if no published version exists |
| download_count | bigint | |
| star_count | int | |
| rating_avg | decimal(3,2) | Average rating |
| rating_count | int | Number of raters |
| created_by | varchar(128) | |
| created_at | datetime | |
| updated_by | varchar(128) | |
| updated_at | datetime | |

- Unique constraint: `(namespace_id, slug)`
- `status` represents the skill container lifecycle and no longer carries "hidden" semantics. Hidden is an independent governance override layer, expressed by `hidden` / `hidden_at` / `hidden_by`
- Actual visibility evaluation in the current codebase is governed by `VisibilityChecker`, with the following rules:
  - If `hidden=true`: only the skill owner or the namespace `ADMIN` / `OWNER` can read
  - If `latest_version_id is null`: only the skill owner can read; even if `visibility=PUBLIC`, it will not be exposed publicly
  - `PUBLIC`: any person can read the skill container and published versions
  - `NAMESPACE_ONLY`: any member of the namespace can read (`MEMBER` / `ADMIN` / `OWNER`)
  - `PRIVATE`: only the skill owner or the namespace `ADMIN` / `OWNER` can read; ordinary `MEMBER` cannot read
- `owner_id` semantics represent the "primary maintainer"; it can be transferred. The permission axis is the namespace role, not the owner:
  - Namespace ADMIN has full management rights over all skills within the namespace (archiving, version management, promotion to global) regardless of the owner
  - When the owner is a MEMBER, they can manage only their own created skills (submit for review, edit drafts)
  - After an owner leaves or changes teams, the namespace ADMIN can still fully manage all skills
- `rating_avg` / `rating_count` are denormalized fields to avoid aggregate queries on every lookup
- `slug`: user-facing URL identifier, derived from the `name` field of SKILL.md; immutable after the first publication. Slug format validation follows the same rules as namespace slug: `[a-z0-9]([a-z0-9-]*[a-z0-9])?`, the same reserved word restrictions apply, and it must not contain two or more consecutive hyphens `--` (reserved for compatibility layer coordinate mapping). Under the global namespace (`@global`), skill slugs additionally must not contain `--` to avoid ambiguity with compatibility layer canonical slugs
- `source_skill_id`: populated only in the "team skill promoted to global" scenario; records the original team namespace skill ID for traceability
- The unique source of truth for promotion relationships is the `promotion_request` table; UI queries of "whether promoted" are determined via `SELECT ... FROM promotion_request WHERE source_skill_id=? AND status='APPROVED'`

### skill_version

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | |
| version | varchar(32) | semver |
| version_sort | bigint | Numeric value for sorting |
| changelog | text | |
| manifest_json | json | File manifest |
| parsed_metadata_json | json | SKILL.md frontmatter parse result |
| status | enum | `DRAFT` / `PENDING_REVIEW` / `PUBLISHED` / `REJECTED` / `YANKED` |
| reject_reason | varchar(512) | Rejection reason |
| published_by | varchar(128) | |
| published_at | datetime | |
| created_at | datetime | |

- `status` represents the version publication lifecycle and is separate from the skill container status and review task status
- Actual transition constraints in the current codebase:
  - After an ordinary user uploads or re-uploads a new version, the version directly enters `PENDING_REVIEW`
  - When a `SUPER_ADMIN` publishes directly, the version can go straight to `PUBLISHED`
  - Review approved: `PENDING_REVIEW → PUBLISHED`
  - Review rejected: `PENDING_REVIEW → REJECTED`
  - Withdraw review: `PENDING_REVIEW → DRAFT`
  - Retract published: `PUBLISHED → YANKED`
- Unique constraint: `(skill_id, version)` to prevent duplicate publishing
- `YANKED` status: retracted after being published
- Actual read permission supplements in the current codebase:
  - Ordinary detail / download / resolve / tag / file access only accepts `PUBLISHED`
  - The owner can preview their own `PENDING_REVIEW` version through the standard version detail endpoint
  - The owner / namespace `ADMIN` / `OWNER` can see all five statuses in the version list: `PUBLISHED / PENDING_REVIEW / DRAFT / REJECTED / YANKED`
  - However, the standard version detail endpoint does not allow `DRAFT / REJECTED / YANKED`
  - The review detail page uses an independent review read path and can view pending versions and complete version snapshots

Version immutability rules:

| Version Status | Version Number Handling |
|---------|-----------|
| DRAFT | The version record can be deleted; the same version number can be reused |
| PENDING_REVIEW | Can be withdrawn back to DRAFT |
| REJECTED | The version record can be deleted; the same version number can be reused |
| PUBLISHED | The version number is permanently occupied and cannot be reused |
| YANKED | The version number is permanently occupied and cannot be reused; appears in the version list but marked as not downloadable |

### skill_file

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_version_id | bigint | |
| file_path | varchar(512) | |
| content_type | varchar(128) | |
| size_bytes | bigint | |
| sha256 | varchar(64) | |
| object_key | varchar(512) | |
| is_entry_file | boolean | |
| created_at | datetime | |

### skill_tag

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | |
| tag_name | varchar(64) | |
| target_version_id | bigint | |
| created_by | varchar(128) | |
| created_at | datetime | |
| updated_by | varchar(128) | |
| updated_at | datetime | |

- `latest` is a system-reserved tag; it is read-only and automatically tracks `skill.latest_version_id`. Its semantics are strictly equivalent to "the most recently published version" and cannot be moved manually via the API
- Custom tags (e.g., `beta`, `stable-2026q1`) can be created and moved manually
- Unique constraint: `(skill_id, tag_name)`
- `target_version_id` must point to a version with `status = PUBLISHED`; validated at the application layer

### review_task

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_version_id | bigint | Associated version |
| namespace_id | bigint | Owning namespace (determines who can review) |
| status | enum | `PENDING` / `APPROVED` / `REJECTED` |
| version | int | Optimistic lock version number, default 1 |
| submitted_by | varchar(128) | Submitter |
| reviewed_by | varchar(128) | Reviewer |
| review_comment | text | Review comment |
| submitted_at | datetime | |
| reviewed_at | datetime | |

- Used only for ordinary publish review; "promote to global" uses the separate `promotion_request` table
- The `version` field is used for optimistic locking to prevent concurrent reviews across multiple Pods
- Business constraint: for the same `skill_version_id`, only one record may exist with `status=PENDING`; duplicate submissions return 409 Conflict. On withdrawal, the `PENDING` review_task is deleted and `skill_version` is reverted to `DRAFT`
- PostgreSQL concurrency constraint implementation: achieved via a unique index on `(skill_version_id)` + a soft-delete marker. Add a `deleted` field (bigint, default 0) to the `review_task` table; change the unique index to `(skill_version_id, deleted)`. On withdrawal, set `deleted` to `id` (non-zero); new submissions set `deleted=0`, using the unique index to prevent concurrent duplicate submissions. Alternatively, use a simpler approach: physically delete the review_task record on withdrawal and rely on the `INSERT` unique constraint on `(skill_version_id)` to prevent concurrency. PostgreSQL also supports a partial unique index: `CREATE UNIQUE INDEX ON review_task (skill_version_id) WHERE status = 'PENDING'`, which more elegantly enforces the "uniqueness in PENDING status" constraint

### promotion_request

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| source_skill_id | bigint | Source team skill |
| source_version_id | bigint | Version being requested for promotion |
| target_namespace_id | bigint | Target global namespace |
| target_skill_id | bigint | Global skill ID created after approval; nullable |
| status | enum | `PENDING` / `APPROVED` / `REJECTED` |
| version | int | Optimistic lock version number, default 1 |
| submitted_by | varchar(128) | Submitter |
| reviewed_by | varchar(128) | Reviewer |
| review_comment | text | Review comment |
| submitted_at | datetime | |
| reviewed_at | datetime | |

- Fully expresses "which version of which team skill was requested to be promoted to which global namespace"
- After approval, `target_skill_id` is populated, pointing to the newly created skill in the global namespace
- `promotion_request` is the unique source of truth for promotion relationships; the skill table no longer denormalizes `promoted_to_skill_id`
- Business constraint: for the same `source_version_id`, only one record may exist with `status=PENDING`; duplicate submissions return 409 Conflict
- PostgreSQL concurrency constraint implementation: similar to `review_task`, uses a unique index to prevent concurrent duplicate submissions. Recommended: partial unique index `CREATE UNIQUE INDEX ON promotion_request (source_version_id) WHERE status = 'PENDING'`; or add a `deleted` field + `(source_version_id, deleted)` unique constraint; or use physical delete + `(source_version_id)` unique constraint

### skill_star

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | |
| user_id | varchar(128) | |
| created_at | datetime | |

Unique constraint: `(skill_id, user_id)`

### skill_rating

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | |
| user_id | varchar(128) | |
| score | tinyint | 1–5 |
| created_at | datetime | |
| updated_at | datetime | |

Unique constraint: `(skill_id, user_id)` — one record per user per skill; can be updated

### user_account

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| display_name | varchar(128) | |
| email | varchar(256) | |
| avatar_url | varchar(512) | |
| status | enum | `ACTIVE` / `PENDING` / `DISABLED` / `MERGED` |
| merged_to_user_id | varchar(128) | Merge target user ID; only populated in MERGED status |
| created_at | datetime | |
| updated_at | datetime | |

- Status semantics:
  - `ACTIVE`: normal operation
  - `PENDING`: awaiting admin approval (created when AccessPolicy returns PENDING_APPROVAL)
  - `DISABLED`: banned by admin; login is denied for all operations, returning 403
  - `MERGED`: merged into another account; the record is retained without physical deletion; login automatically redirects to the merge target account
- The authorization layer checks user status on every request; non-`ACTIVE` users are denied all write operations

### identity_binding

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| user_id | varchar(128) | |
| provider_code | varchar(64) | e.g., `github` |
| subject | varchar(256) | Unique user identifier returned by the OAuth provider |
| login_name | varchar(128) | e.g., GitHub login |
| extra_json | json | Raw extension fields |
| created_at | datetime | |
| updated_at | datetime | |

- Unique constraint: `(provider_code, subject)`
- Phase 1 integrates only GitHub OAuth, but the table structure supports future extension to multiple OAuth providers

### api_token

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| subject_type | varchar(32) | `USER` (Phase 1) / `SERVICE_ACCOUNT` (reserved) |
| subject_id | varchar(128) | Associated principal ID (same as user_id in Phase 1) |
| user_id | varchar(128) | Compatibility field; same as subject_id in Phase 1 |
| name | varchar(128) | Token name (required), e.g., "CI/CD", "Local Development" |
| token_prefix | varchar(16) | |
| token_hash | varchar(64) | |
| scope_json | json | |
| expires_at | datetime | |
| last_used_at | datetime | |
| revoked_at | datetime | |
| created_at | datetime | |

### audit_log

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| actor_user_id | varchar(128) | |
| action | varchar(64) | |
| target_type | varchar(64) | |
| target_id | bigint | |
| request_id | varchar(64) | |
| client_ip | varchar(64) | |
| user_agent | varchar(512) | |
| detail_json | json | |
| created_at | datetime | |

## 3.2 RBAC Entities

The full RBAC system is launched in Phase 1. Platform roles are split by least-privilege to avoid concentrating all governance capabilities in a single super-admin role.

Platform roles (built-in for Phase 1, pre-populated by Flyway):

| Role Code | Description | Typical Permissions |
|-----------|------|---------|
| `SUPER_ADMIN` | Platform super-admin with all permissions | All |
| `SKILL_ADMIN` | Skill governance: global namespace review, promotion review, hide/restore, retract published versions | `review:approve`, `skill:manage`, `promotion:approve` |
| `USER_ADMIN` | User governance: access approval, ban/unban, role assignment (cannot assign SUPER_ADMIN) | `user:manage`, `user:approve` |
| `AUDITOR` | Audit read-only: view audit logs | `audit:read` |

- Namespace permissions are still determined by `namespace_member.role` (OWNER / ADMIN / MEMBER) and do not go through the RBAC table
- A user can hold multiple platform roles (multiple `user_role_binding` records)
- `SUPER_ADMIN` implicitly has all permissions; code uses a hard short-circuit evaluation

### role

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| code | varchar(64) | `SUPER_ADMIN` / `SKILL_ADMIN` / `USER_ADMIN` / `AUDITOR` |
| name | varchar(128) | Display name |
| description | varchar(512) | |
| is_system | boolean | System built-in roles cannot be deleted |
| created_at | datetime | |

### permission

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| code | varchar(128) | e.g., `skill:publish`, `review:approve`, `user:manage` |
| name | varchar(128) | |
| group_code | varchar(64) | Permission group |

### role_permission

| Field | Type | Description |
|------|------|------|
| role_id | bigint | |
| permission_id | bigint | |

### user_role_binding

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| user_id | varchar(128) | |
| role_id | bigint | |
| created_at | datetime | |

## 3.3 Search Document Table

### skill_search_document

One search document per skill; content is taken from the "most recently published version." The implementation may use `latest_version_id` as a cache pointer, but its semantics can only be that of a latest published pointer.

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | Unique; one record per skill |
| namespace_id | bigint | Used for namespace filtering |
| owner_id | varchar(128) | Used for PRIVATE visibility evaluation |
| title | varchar(256) | |
| summary | varchar(512) | |
| keywords | varchar(512) | |
| search_text | text | `displayName`, `slug`, `summary`, and the expanded result of frontmatter fields excluding `name` / `description` / `version` |
| visibility | enum | Denormalized to avoid joins during search |
| status | enum | |
| updated_at | datetime | |

PostgreSQL Full-Text Index: add a `search_vector tsvector` column to the `skill_search_document` table; automatically maintained via a trigger or `GENERATED ALWAYS AS`, with a GIN index created on it.

## 3.4 Idempotency Record Table

### idempotency_record

| Field | Type | Description |
|------|------|------|
| request_id | varchar(64) | Primary key; UUID v4 provided by the client |
| resource_type | varchar(64) | e.g., `skill_version`, `api_token` |
| resource_id | bigint | Resource ID produced by the business operation |
| status | enum | `PROCESSING` / `COMPLETED` / `FAILED` |
| response_status_code | int | Original response status code |
| created_at | datetime | |
| expires_at | datetime | Expiration time (default 24h) |

- Flow: receive request → insert record (PROCESSING) → execute business logic → update to COMPLETED + resource_id → return existing result on duplicate requests
- Redis is used as a fast deduplication cache (SETNX); PostgreSQL is used as a persistent fallback
- A scheduled task cleans up expired records

## 3.5 Key Index Design

| Table | Index | Purpose |
|------|------|------|
| namespace | `(slug)` UNIQUE | Unique constraint |
| skill | `(namespace_id, status)` | Skill list within a namespace |
| skill | `(namespace_id, slug)` UNIQUE | Unique constraint |
| skill_version | `(skill_id, status)` | Version list |
| skill_version | `(skill_id, version)` UNIQUE | Unique constraint |
| skill_tag | `(skill_id, tag_name)` UNIQUE | Tag unique constraint |
| review_task | `(namespace_id, status)` | Review list |
| review_task | `(submitted_by, status)` | My submissions |
| promotion_request | `(source_skill_id)` | Query by source skill |
| promotion_request | `(status)` | Pending review list |
| idempotency_record | `(expires_at)` | Expiration cleanup |
| audit_log | `(created_at)` | Audit queries |
| audit_log | `(actor_user_id, created_at)` | User operation history |
| skill_star | `(user_id)` | My favorites |
| skill_star | `(skill_id)` | Skill favorite count |
| skill_rating | `(skill_id)` | Rating aggregation |
| namespace_member | `(namespace_id, user_id)` UNIQUE | Member unique constraint |
| namespace_member | `(user_id)` | Namespaces a user belongs to |
| identity_binding | `(provider_code, subject)` UNIQUE | Identity lookup |
| api_token | `(token_hash)` | Token validation |
