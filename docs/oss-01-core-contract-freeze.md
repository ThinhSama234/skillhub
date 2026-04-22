# OSS-01 Core Contract Audit and Freeze

## 1. Audit Conclusions

The SkillHub open-source project already has the vast majority of Core capabilities required for the AstronClaw main workflow. The existing interfaces cover skill unique identifier queries, version metadata queries, creation (publishing), and deletion. **No new AstronClaw-specific interfaces need to be added to the open-source Core.** For AstronClaw, both query-type and main workflow capabilities should be uniformly provided by the SaaS-layer `AstronClaw Adapter` after wrapping, rather than directly binding to the open-source Core's interface shapes.

---

## 2. Core Interface Catalog

The following interfaces constitute the Core baseline capabilities, to be uniformly wrapped by the SaaS layer before being provided to AstronClaw; these interfaces themselves should not be considered as AstronClaw's long-term direct contracts.

### 2.1 Skill Unique Identifier and Detail Queries

| Interface | Path | Description |
|------|------|------|
| Skill details | `GET /api/v1/skills/{namespace}/{slug}` | Returns `SkillDetailResponse`, including complete identity and status |
| Version resolution | `GET /api/v1/skills/{namespace}/{slug}/resolve?version=&tag=&hash=` | Returns `ResolveVersionResponse`, resolving a human-readable version selector to an exact version |

### 2.2 Specified Version Installation Metadata Queries

| Interface | Path | Description |
|------|------|------|
| Version details | `GET /api/v1/skills/{namespace}/{slug}/versions/{version}` | Returns `SkillVersionDetailResponse`, including metadata and manifest |
| Version file list | `GET /api/v1/skills/{namespace}/{slug}/versions/{version}/files` | Returns `List<SkillFileResponse>` |
| Version download | `GET /api/v1/skills/{namespace}/{slug}/versions/{version}/download` | Downloads the specified version bundle |
| Version list | `GET /api/v1/skills/{namespace}/{slug}/versions?page=&size=` | Returns paginated version list |

### 2.3 Create (Publish) Personal Skill

| Interface | Path | Description |
|------|------|------|
| Publish skill | `POST /api/v1/skills/{namespace}/publish` | Upload package and publish, returns `PublishResponse` |

### 2.4 Delete Personal Skill

| Interface | Path | Description |
|------|------|------|
| Hard delete (by ID) | `DELETE /api/v1/skills/id/{skillId}` | Requires SUPER_ADMIN permission |
| Hard delete (by coordinates) | `DELETE /api/v1/skills/{namespace}/{slug}` | Requires SUPER_ADMIN permission |
| Archive | `POST /api/v1/skills/{namespace}/{slug}/archive` | Owner or namespace admin can operate |
| Unarchive | `POST /api/v1/skills/{namespace}/{slug}/unarchive` | Restores to ACTIVE |

### 2.5 Version Lifecycle

| Interface | Path | Description |
|------|------|------|
| Delete version | `DELETE /api/v1/skills/{namespace}/{slug}/versions/{version}` | Only DRAFT/REJECTED/SCAN_FAILED can be deleted |
| Withdraw from review | `POST /api/v1/skills/{namespace}/{slug}/versions/{version}/withdraw-review` | PENDING_REVIEW → DRAFT |
| Re-release | `POST /api/v1/skills/{namespace}/{slug}/versions/{version}/rerelease` | Re-publish a version |

### 2.6 ClawHub Compatibility Interfaces (Existing)

| Interface | Path | Description |
|------|------|------|
| Resolve skill | `GET /api/v1/resolve?slug=&version=` | ClawHub protocol compatible |
| Resolve skill (path) | `GET /api/v1/resolve/{canonicalSlug}?version=` | ClawHub protocol compatible |
| Download | `GET /api/v1/download/{canonicalSlug}?version=` | 302 redirect to download URL |
| Delete skill | `DELETE /api/v1/skills/{canonicalSlug}` | Owner can operate |
| Undelete | `POST /api/v1/skills/{canonicalSlug}/undelete` | Owner can operate |
| Publish skill | `POST /api/v1/skills` | ClawHub protocol compatible |
| Publish to namespace | `POST /api/v1/publish` | ClawHub protocol compatible |

---

## 3. Field Semantics Freeze Table

### 3.1 Skill Identity Fields

| Field | Type | Meaning | Stability | Notes |
|------|------|------|--------|------|
| `skill.id` | Long | Global unique primary key for skill | Immutable | Auto-increment, never changes after creation, can be used as external mapping primary key |
| `namespace` (slug) | String(64) | Namespace identifier for the skill | Immutable | Globally unique, cannot be renamed after creation |
| `skill.slug` | String(100) | Unique identifier for the skill within its namespace | Immutable | Cannot be renamed after creation; `namespace + slug` forms the business coordinates |
| `skill.displayName` | String(200) | Display name of the skill | Mutable | For display only, cannot be used as a mapping key |
| `skill.ownerId` | String | Skill creator ID | Immutable | Bound at creation, cannot be transferred |
| `skill.summary` | String(TEXT) | Skill description | Mutable | For display |
| `skill.visibility` | Enum | Visibility | Mutable | `PUBLIC` / `NAMESPACE_ONLY` / `PRIVATE` |
| `skill.status` | Enum | Skill status | Mutable | `ACTIVE` / `HIDDEN` / `ARCHIVED` |
| `skill.hidden` | boolean | Whether hidden by an admin | Mutable | Hidden flag independent of status |
| `skill.latestVersionId` | Long | Latest version pointer | Mutable | Points to the current latest published version; automatically rolls back after yank/deletion |
| `skill.downloadCount` | Long | Download count | Mutable | Cumulative value |
| `skill.starCount` | Integer | Star count | Mutable | Cumulative value |

### 3.2 SkillVersion Fields

| Field | Type | Meaning | Stability | Notes |
|------|------|------|--------|------|
| `version.id` | Long | Global unique primary key for version | Immutable | Auto-increment |
| `version.skillId` | Long | Parent skill ID | Immutable | Foreign key |
| `version.version` | String(64) | Version number | Immutable | e.g., `1.0.0`, cannot be changed after creation |
| `version.status` | Enum | Version status | Mutable | See status semantics table |
| `version.bundleReady` | boolean | Whether the bundle is available | Mutable | `true` means the bundle is built and ready to download and install |
| `version.downloadReady` | boolean | Whether download is allowed | Mutable | Set to `false` after yank |
| `version.publishedAt` | Instant | Publication time | Write-once | Set when first published |
| `version.parsedMetadataJson` | JSONB | Parsed metadata | Write-once | Contains runtime information such as `package_name` |
| `version.manifestJson` | JSONB | Raw manifest content | Write-once | The manifest of the skill package |
| `version.changelog` | String(TEXT) | Changelog | Mutable | For display |
| `version.fileCount` | Integer | File count | Write-once | Determined at publish time |
| `version.totalSize` | Long | Total size (bytes) | Write-once | Determined at publish time |
| `version.yankedAt` | Instant | Yank time | Write-once | Set when yanked |
| `version.yankReason` | String(TEXT) | Yank reason | Write-once | Set when yanked |

### 3.3 Key Field Semantics Freeze

| Field | Frozen Definition |
|------|----------|
| `skill_id` | `skill.id`, Long auto-increment primary key, globally unique, immutable after creation. AstronClaw should use this as the external key for `external_skill_mapping` |
| `namespace` | `namespace.slug`, String(64), globally unique, cannot be renamed. Combined with `slug` to form business coordinates |
| `slug` | `skill.slug`, String(100), unique within namespace, cannot be renamed. `namespace/slug` is the human-readable stable coordinate |
| `version` | `skill_version.version`, String(64), unique within the same skill, immutable. e.g., `1.0.0` |
| `bundle_url` | Obtained via `GET /{namespace}/{slug}/versions/{version}/download`, or via the `downloadUrl` field of the `resolve` interface. Not a database field; a dynamically generated download URL |
| `bundle_ready` | `skill_version.bundleReady`, boolean. `true` means the bundle is built and ready to install. AstronClaw must validate this field before installation |
| `package_name` | Stored in `skill_version.parsedMetadataJson`, parsed from the skill package manifest. Should remain stable across versions of the same skill. Used by AstronClaw for runtime install/uninstall identification |

### 3.4 Namespace Fields

| Field | Type | Meaning | Stability |
|------|------|------|--------|
| `namespace.id` | Long | Namespace primary key | Immutable |
| `namespace.slug` | String(64) | Namespace identifier | Immutable, globally unique |
| `namespace.displayName` | String(128) | Display name | Mutable |
| `namespace.type` | Enum | Type | Immutable, `GLOBAL` / `TEAM` |
| `namespace.status` | Enum | Status | Mutable, `ACTIVE` / `FROZEN` / `ARCHIVED` |

---

## 4. Status Semantics Freeze Table

### 4.1 Skill Status (`SkillStatus`)

| Status | Market Visible | New Install Allowed | Existing Install Retained | Owner Operable | Notes |
|------|----------|--------|------------|----------------|------|
| `ACTIVE` | Yes (controlled by visibility) | Yes (requires a PUBLISHED version) | Yes | Yes | Normal state |
| `HIDDEN` | No | No | Yes | Restricted | Hidden by admin; independent `hidden` flag from status |
| `ARCHIVED` | No | No | Yes | Can unarchive | Archived by owner or namespace admin |

### 4.2 Version Status (`SkillVersionStatus`)

| Status | Install Allowed | Download Allowed | Market Visible | Can Transition To | Notes |
|------|------------|------------|---------|---------|------|
| `DRAFT` | No | No | No | SCANNING, can delete | Initial state, being edited |
| `SCANNING` | No | No | No | SCAN_FAILED, PENDING_REVIEW, PUBLISHED | Security scan in progress |
| `SCAN_FAILED` | No | No | No | Can delete | Security scan failed |
| `PENDING_REVIEW` | No | No | No | PUBLISHED, REJECTED, → DRAFT (withdraw) | Awaiting review |
| `PUBLISHED` | Yes | Yes | Yes | YANKED | Published, installable |
| `REJECTED` | No | No | No | Can delete | Review rejected |
| `YANKED` | No | No | No (or weakly visible) | Irreversible | Yanked; existing installs unaffected |

### 4.3 Visibility (`SkillVisibility`)

| Visibility | Market List Visible | Who Can View | Who Can Install |
|--------|------------|---------|---------|
| `PUBLIC` | Yes | Everyone | Everyone (requires PUBLISHED + bundleReady) |
| `NAMESPACE_ONLY` | No | Namespace members | Namespace members |
| `PRIVATE` | No | Owner only | Owner only |

### 4.4 Deletion Semantics

| Operation | Type | Reversible | Data Impact | Existing Install Impact |
|------|------|------|---------|------------|
| Hard delete skill | Permanent deletion | No | Deletes all records, files, and storage objects; slug can be reused | No impact; AstronClaw installed snapshots are independent |
| Archive skill | Status change | Yes | No data deleted; status → ARCHIVED | No impact |
| Hide skill | Flag change | Yes | No data deleted; hidden → true | No impact |
| Delete version | Permanent deletion | No | Only deletes DRAFT/REJECTED/SCAN_FAILED versions | No impact (these versions were never installed) |
| Yank version | Status change | No | status → YANKED, downloadReady → false | No impact on existing installs |

### 4.5 AstronClaw Installation Check Rules

For AstronClaw to determine whether a skill version is installable, all of the following must be satisfied:

```
skill.status == ACTIVE
  AND skill.hidden == false
  AND skill.visibility allows access by the current user
  AND version.status == PUBLISHED
  AND version.bundleReady == true
```

Existing installs are not affected by subsequent status changes. Even if a skill is deleted/archived/hidden, or a version is yanked, the AstronClaw local installation snapshot can still be used and uninstalled normally.

## 5. Error Semantics Table

### 5.1 Unified Response Structure

```json
{
  "code": 0,
  "msg": "Operation successful",
  "data": { ... },
  "timestamp": "2026-04-10T08:00:00Z",
  "requestId": "req-xxx"
}
```

- `code = 0` means success
- `code > 0` means an error; value is the HTTP status code

### 5.2 Error Code Mapping

| HTTP Status | Scenario | Exception Type | Description |
|------------|------|---------|------|
| 400 | Invalid parameters | `BadRequestException` / `DomainBadRequestException` | Request parameter validation failure |
| 401 | Unauthenticated | `UnauthorizedException` / `AuthFlowException` | Not logged in or token expired |
| 403 | No permission | `ForbiddenException` / `DomainForbiddenException` | No operation permission |
| 404 | Not found | `DomainNotFoundException` | Skill/version/namespace does not exist |
| 408 | Request timeout | `AsyncRequestTimeoutException` | Async request timeout |
| 503 | Storage unavailable | `StorageAccessException` | Object storage access failure |
| 500 | Service error | `Exception` | Unexpected internal error |

### 5.3 Core Main Workflow Critical Error Scenarios

| Scenario | HTTP Status | Example msg | AstronClaw Handling Recommendation |
|------|-----------|---------|-------------------|
| Skill does not exist | 404 | `error.skill.notFound` | Mapping failure, prompt user |
| Version does not exist | 404 | `error.skill.notFound` | Install/upgrade failure, prompt user |
| Version not installable (non-PUBLISHED) | 400 | `error.badRequest` | Reject install, indicate version status |
| Bundle not ready | 400 | `error.badRequest` | Reject install, suggest retrying later |
| No access permission (PRIVATE skill) | 403 | `error.forbidden` | Indicate no permission |
| Namespace does not exist | 404 | `error.namespace.notFound` | Mapping failure |
| Storage service unavailable | 503 | `error.storage.unavailable` | Graceful degradation; existing installs unaffected |
| Deletion not allowed (non-owner) | 403 | `error.forbidden` | Indicate no permission |

---

## 6. Core vs SaaS Adapter Capability Boundary

### 6.1 Capabilities Already Satisfied by Core

Note:

The table below indicates capabilities that "the open-source Core already has and can be wrapped by SaaS", and does not imply that AstronClaw should directly call these open-source interfaces.

| PRD Requirement | Core Interface | Satisfied | Notes |
|---------|----------|---------|------|
| Skill unique identifier query | `GET /{namespace}/{slug}` | Fully satisfied | Returns `id`, `namespace`, `slug` |
| Specified version installation metadata | `GET /{namespace}/{slug}/versions/{version}` | Mostly satisfied | Returns status, metadata; `package_name` is in `parsedMetadataJson` |
| Version resolution | `GET /{namespace}/{slug}/resolve` | Fully satisfied | Supports version/tag/hash resolution |
| Bundle download | `GET /{namespace}/{slug}/versions/{version}/download` | Fully satisfied | Direct download |
| Create (publish) personal skill | `POST /{namespace}/publish` | Fully satisfied | Returns skillId, namespace, slug, version, status |
| Delete personal skill | `DELETE /{namespace}/{slug}` (ClawHub compatible) | Fully satisfied | Owner can operate |
| Archive skill | `POST /{namespace}/{slug}/archive` | Fully satisfied | Reversible operation |
| Version status query | `headlineVersion/publishedVersion` in `GET /{namespace}/{slug}` | Fully satisfied | Includes version status |
| Labels data | `labels` field in `GET /{namespace}/{slug}` | Fully satisfied | Returns `List<SkillLabelDto>` |

### 6.2 Capabilities Requiring New SaaS Adapter

| PRD Requirement | Reason | Adapter Recommendation |
|---------|------|-------------|
| Market list query (search/filter/sort) | Core does not provide page-oriented aggregated lists | `GET /api/v1/astronclaw/adapter/skills/market` |
| Market details (AstronClaw DTO) | Core's returned DTO includes Core-internal fields that need adaptation | `GET /api/v1/astronclaw/adapter/skills/{id}` |
| Owner-dimension "created by me" query | Core's `/me/skills` returns Core DTOs that need adaptation | `GET /api/v1/astronclaw/adapter/skills/mine` |
| `is_installed` population | Installation relationship is on the AstronClaw side | AstronClaw populates locally, not in Adapter |
| `package_name` as top-level field | Currently nested in `parsedMetadataJson`, needs extraction | Adapter parses JSON and returns it as a flat field |
| `bundle_url` returned directly | Currently requires fetching via the download interface | Adapter can return a pre-signed URL directly |
| Unified `can_install` determination | Requires combining status + visibility + bundleReady | Adapter computes and returns a boolean |
| Unified `can_delete` determination | Requires combining owner + status | Adapter computes and returns a boolean |

### 6.3 Boundary Principles

```
Core is responsible for: skill lifecycle source of truth (identity, version, status, artifact)
Adapter is responsible for: DTO adaptation for AstronClaw (field flattening, status aggregation, pre-computed permissions)
```

Supplementary principles:

1. Even when the open-source `Core` already has a main workflow capability, `AstronClaw` should still consume it uniformly through the SaaS Adapter.
2. This principle applies equally to unique identifier queries, version metadata, creating personal skills, and deleting personal skills.
3. The interface catalog in the open-source documentation is for explaining `Core` capability boundaries, and should not be interpreted as a direct integration recommendation for AstronClaw.

---

## 7. Success / Failure / Edge Case Examples

### 7.1 Query Skill Identity — Success

```
GET /api/v1/skills/my-namespace/my-skill
```

```json
{
  "code": 0,
  "data": {
    "id": 42,
    "slug": "my-skill",
    "displayName": "My Skill",
    "ownerId": "user-123",
    "status": "ACTIVE",
    "visibility": "PUBLIC",
    "namespace": "my-namespace",
    "labels": [{"slug": "nlp", "type": "CATEGORY", "displayName": "NLP"}],
    "headlineVersion": {"id": 100, "version": "1.2.0", "status": "PUBLISHED"},
    "publishedVersion": {"id": 100, "version": "1.2.0", "status": "PUBLISHED"}
  }
}
```

AstronClaw maps key fields: `id=42`, `namespace=my-namespace`, `slug=my-skill`.

### 7.2 Query Skill Identity — Not Found

```
GET /api/v1/skills/my-namespace/nonexistent
```

```json
{
  "code": 404,
  "msg": "Skill not found",
  "data": null
}
```

### 7.3 Query Specified Version Metadata — Success

```
GET /api/v1/skills/my-namespace/my-skill/versions/1.2.0
```

```json
{
  "code": 0,
  "data": {
    "id": 100,
    "version": "1.2.0",
    "status": "PUBLISHED",
    "changelog": "Bug fixes",
    "fileCount": 3,
    "totalSize": 102400,
    "publishedAt": "2026-04-01T10:00:00Z",
    "parsedMetadataJson": "{\"name\":\"my-skill\",\"package_name\":\"my_namespace__my_skill\",\"version\":\"1.2.0\"}",
    "manifestJson": "{...}"
  }
}
```

`package_name` is extracted from `parsedMetadataJson`.

### 7.4 Query a YANKED Version

```
GET /api/v1/skills/my-namespace/my-skill/versions/1.0.0
```

```json
{
  "code": 0,
  "data": {
    "id": 98,
    "version": "1.0.0",
    "status": "YANKED",
    "publishedAt": "2026-03-01T10:00:00Z"
  }
}
```

AstronClaw determines `status != PUBLISHED` and rejects new installations. Existing installs are unaffected.

### 7.5 Publish (Create) Personal Skill — Success

```
POST /api/v1/skills/my-namespace/publish
Content-Type: multipart/form-data
file: <skill-package.tar.gz>
visibility: PRIVATE
```

```json
{
  "code": 0,
  "data": {
    "skillId": 43,
    "namespace": "my-namespace",
    "slug": "new-skill",
    "version": "0.1.0",
    "status": "DRAFT",
    "fileCount": 2,
    "totalSize": 51200
  }
}
```

### 7.6 Delete Personal Skill — Success

```
DELETE /api/v1/skills/my-namespace/my-skill
```

```json
{
  "code": 0,
  "data": {
    "ok": true
  }
}
```

### 7.7 Delete Personal Skill — No Permission

```
DELETE /api/v1/skills/other-namespace/other-skill
```

```json
{
  "code": 403,
  "msg": "Forbidden",
  "data": null
}
```

### 7.8 Edge Case: Querying an Archived Skill

```
GET /api/v1/skills/my-namespace/archived-skill
```

```json
{
  "code": 0,
  "data": {
    "id": 44,
    "slug": "archived-skill",
    "status": "ARCHIVED",
    "visibility": "PUBLIC"
  }
}
```

The skill is still queryable, but AstronClaw should determine from `status=ARCHIVED` that new installations are not allowed.

---

## 8. Outstanding Issues and Recommendations

### 8.1 `package_name` Extraction

`package_name` is currently nested in the `parsedMetadataJson` JSONB field and is not a top-level field.

Recommendation: When the SaaS Adapter returns AstronClaw DTOs, parse the JSON and extract `package_name` as a top-level field. No changes are needed to Core.

### 8.2 `bundle_url` Access Method

There is currently no field that directly returns `bundle_url`; it must be obtained via the download interface. The `ResolveVersionResponse` has a `downloadUrl` field.

Recommendation: The SaaS Adapter can obtain `downloadUrl` through the `resolve` interface, or generate a pre-signed URL directly to return to AstronClaw.

### 8.3 Delete Interface Permissions

The current `DELETE /api/v1/skills/{namespace}/{slug}` (portal path) requires SUPER_ADMIN permission. The ClawHub-compatible interface `DELETE /api/v1/skills/{canonicalSlug}` allows owner operation.

Recommendation: The SaaS Adapter should uniformly wrap an owner-operable delete interface to expose a stable contract to AstronClaw; AstronClaw should not directly depend on the open-source delete interface paths.

### 8.4 Relationship Between `hidden` and `status`

Currently `hidden` is a boolean flag independent of `status` (an admin operation), while `HIDDEN` is one of the `SkillStatus` enum values — but in practice the skill's status enum contains `ACTIVE`, `HIDDEN`, and `ARCHIVED`.

Recommendation: The SaaS Adapter should provide AstronClaw with a unified `is_visible` aggregated field that shields the complex relationship between the internal `hidden` flag and `status`.
