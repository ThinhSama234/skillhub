# skillhub Core Business Flows

## 1 Publish Flow

Phase 1 uses a synchronous publish model: upload, validation, storage, and persistence all complete synchronously within a single request. The frontend enhances the user experience with asynchronous upload (with a progress bar), but the backend processing is synchronous.

> **Design Decision**: Asynchronous publishing (uploadId, publishId, status polling, async finalization, etc.) is not considered for Phase 1. Phase 1 skill packages are text resource packages with a limited size (10 MB upper limit); synchronous processing is sufficient. If large files or complex validation flows are introduced later, an asynchronous model will be considered then.

### 1.1 Current Publish Flow Baseline

```
User submits for publish
    │
    ▼
① Identity and permission check (whether the user is at least a MEMBER of the target namespace)
    │
    ▼
② Skill package validation
   - SKILL.md presence, frontmatter format
   - File type allowlist, single-file size limit, total package size limit
   - Version number semver validity, no conflict with existing versions
   - [Extension point] PrePublishValidator chain (no-op implementation in Phase 1)
    │
    ▼
③ Synchronous write to object storage
   - Files uploaded one by one to the official path `skills/{skillId}/{versionId}/{filePath}`, with SHA-256 recorded
   - Pre-packaged zip generated at `packages/{skillId}/{versionId}/bundle.zip`
    │
    ▼
④ Persist data
   - Create or associate skill record (skill is created on the first publish)
   - Create skill_version (ordinary users enter `PENDING_REVIEW`; `SUPER_ADMIN` goes directly to `PUBLISHED`)
   - Create skill_file records
   - Parse SKILL.md frontmatter → parsed_metadata_json
   - Generate manifest_json
   - Update skill.latest_version_id for direct-publish scenarios
    │
    ▼
⑤ Synchronously write audit log
    │
    ▼
⑥ Asynchronously trigger search index write
```

The current version uses a review flow; there is no longer a distinction between a "Phase 2 direct-publish" and "Phase 3 re-enabled review" as two separate real implementations:

- Ordinary user publish requests create `skill_version(status=PENDING_REVIEW)`
- A `review_task(status=PENDING)` is created synchronously
- After review approval, the status transitions to `PUBLISHED`
- After review rejection, the status transitions to `REJECTED`
- On review withdrawal, the `PENDING review_task` is deleted and `skill_version` is reverted to `DRAFT`
- Exception: when the submitter holds the `SUPER_ADMIN` platform role, the publish entry point directly creates `skill_version(status=PUBLISHED)`, skips review_task creation, and no longer requires the submitter to be a member of the target namespace
- The above exception must behave consistently across the Web, `/api/v1/publish`, and `/api/v1/publish`
- If an old `PENDING_REVIEW` version exists when re-uploading a new version, the old version is automatically reverted to `DRAFT`, and a new pending-review version is created

### 1.2 Lifecycle Read Model

The skill lifecycle display and operation evaluation in the current codebase no longer relies on legacy assembled fields such as `latestVersionStatus` or `viewingVersionStatus`. Instead, they are uniformly based on the following projection:

- `headlineVersion`: the primary display version on the skill detail page / my skills list
- `publishedVersion`: the current latest publicly distributable published version
- `ownerPreviewVersion`: a `PENDING_REVIEW` version in the detail projection exposed only to the owner / namespace manager
- `resolutionMode`: `PUBLISHED` / `OWNER_PREVIEW` / `NONE`

Business rules:

- Public entry points only recognize `publishedVersion`
- When an owner visits the detail page, `headlineVersion = ownerPreviewVersion` is only allowed when no `publishedVersion` is available
- Promote to global, install commands, and public downloads can only be bound to `publishedVersion`
- `hidden` is an independent governance override layer and is not part of the skill lifecycle state machine

### 1.3 Skill Visibility and Role Access Matrix

The following matrix reflects the current backend implementation, combining the actual behavior of `VisibilityChecker`, `SkillQueryService`, `SkillDownloadService`, and `ReviewPermissionChecker`.

#### 1.3.1 Skill Container Access

| Role | PUBLIC | NAMESPACE_ONLY | PRIVATE | hidden (any visibility) | No `publishedVersion` (`latest_version_id=null`) |
|------|--------|----------------|---------|------------------------|-----------------------------------------------|
| Anonymous user | Can read | Cannot read | Cannot read | Cannot read | Cannot read |
| Logged-in non-member | Can read | Cannot read | Cannot read | Cannot read | Cannot read |
| Namespace MEMBER | Can read | Can read | Cannot read | Cannot read | Only if the member is also the owner |
| Skill owner | Can read | Can read | Can read | Can read | Can read |
| Namespace ADMIN / OWNER | Can read | Can read | Can read | Can read | Cannot read, unless the user is also the skill owner |
| SKILL_ADMIN / SUPER_ADMIN (platform role only) | Same as ordinary logged-in user; the platform role alone does not automatically bypass private / hidden / unpublished restrictions |

Supplements:
- When `hidden=true`, read access is narrowed to "the skill owner or namespace `ADMIN` / `OWNER`"
- `visibility=PUBLIC` does not mean an unpublished skill is visible; when `latest_version_id` is null, only the owner can read it

#### 1.3.2 Version Status Access

| Scenario / Role | DRAFT | PENDING_REVIEW | PUBLISHED | REJECTED | YANKED |
|------------|-------|----------------|-----------|----------|--------|
| Primary version projection on ordinary skill detail page | Not shown | Owner / namespace manager can display as `ownerPreviewVersion` | Shown | Not shown | Not shown |
| Ordinary `listVersions` visitor | Not visible | Not visible | Visible | Not visible | Not visible |
| `listVersions` for owner / namespace ADMIN / OWNER | Visible | Visible | Visible | Visible | Visible |
| Ordinary `getVersionDetail` | Not readable | Owner-only readable | Readable | Not readable | Not readable |
| Download / resolve / tag / file access | Unavailable | Unavailable | Available | Unavailable | Unavailable |
| Review detail page | Full snapshot visible | Full snapshot visible | Full snapshot visible | Full snapshot visible | Full snapshot visible |

Supplements:
- `YANKED` versions still appear in the management-perspective version list but cannot be downloaded
- When yanking the most recently published version, `latest_version_id` is recalculated to point to the next most recent `PUBLISHED` version; if none exists, it is set to null

#### 1.3.3 Review / Promotion / Governance Actions

| Role | Publish new version | Submit for review | Review team namespace | Review global namespace | Submit promotion | Review promotion | hide / unhide | Yank published version |
|------|------------|----------|--------------|--------------|----------|----------|---------------|----------------|
| Anonymous user | No | No | No | No | No | No | No | No |
| Namespace MEMBER | Can publish to their own namespace; new version enters `PENDING_REVIEW` | Can if they are the owner; cannot submit on behalf of others | No | No | Can if they are the owner | No | No | No |
| Skill owner | Yes | Yes | No | No | Yes | No | No | No |
| Namespace ADMIN / OWNER | Yes | Can submit review for skills in this namespace | Yes | No | Yes | No | No | No |
| SKILL_ADMIN | Can submit and submit on behalf of others; but ordinary publish still goes through review | Yes | Yes | Yes | Yes | Yes, but cannot review their own promotion | No | Yes |
| SUPER_ADMIN | Can publish across namespaces, directly as `PUBLISHED`, bypassing membership check and review task | Yes | Yes | Yes | Yes | Yes; in the review scenario, can also review their own submissions | Yes | Yes |

### Object Storage Write Strategy

Phase 1 writes synchronously to the official path without using a temporary area:
- Files are written directly to `skills/{skillId}/{versionId}/{filePath}`
- If the database transaction fails, the files in object storage become orphan objects
- Scheduled GC task: daily scan of files that exist in object storage but have no corresponding `skill_file` record in the database; orphan objects are cleaned up
- When a DRAFT/REJECTED version is deleted, the corresponding object storage files are cleaned up synchronously

### CLI Publish Request Specification

```
POST /api/v1/publish
Content-Type: multipart/form-data
Parts:
  - file: zip package (required)
  - namespace: target namespace slug (required)
```

Phase 1 synchronous response: the server synchronously completes upload, validation, storage, and persistence, returning `200 OK` + skill_version info.

Current CLI default behavior: upload → enters review.
If the caller holds `SUPER_ADMIN`, the skill is published directly as `PUBLISHED`.
The web frontend and CLI maintain the same publish semantics; the web UI can provide a more explicit review notification.

`/api/v1/publish` response:

```json
{
  "data": {
    "skillId": 456,
    "skillVersionId": 123,
    "version": "1.2.0",
    "status": "PUBLISHED",
    "namespace": "team-name",
    "slug": "my-skill"
  }
}
```

## 2 Promote Team Skill to Global Namespace (Derived Publish)

Rather than directly modifying the original skill's `namespace_id`, a new skill is created in the global namespace while preserving source traceability. The original team skill continues to exist; its installation coordinate `@team/skill` is unaffected.

```
Team namespace skill (published)
    │
    ▼
① Skill owner or namespace admin initiates a "Promote to Global" request
    │
    ▼
② Create promotion_request (source_skill_id, source_version_id, target_namespace_id, status=PENDING)
    │
    ▼
③ Platform administrator reviews
   ├── Approved →
   │   ① Create a new skill in the global namespace (source_skill_id = original skill ID)
   │   ② Copy the files and metadata of the version specified in source_version_id to the new skill (strictly uses the version specified at the time of the request, not the latest)
   │   ③ New skill.visibility = PUBLIC
   │   ④ promotion_request.target_skill_id = new skill ID, status → APPROVED
   │   ⑤ Write new skill to search index, write audit log synchronously
   │   (The unique source of truth for promotion relationships is promotion_request; UI queries of "whether promoted" are determined through this table)
   │
   └── Rejected → reason recorded; original skill is unaffected
```

Subsequent version updates:
- The new skill in the global namespace is independently version-managed by its owner
- The original team skill can continue to iterate independently
- The versions of the two are not automatically synchronized; if synchronization is needed, the owner must do it manually

The promotion flow is currently strictly bound to the published version:

- The `source_version_id` of a promotion request must point to `publishedVersion.id`
- Promoting `ownerPreviewVersion` directly is not allowed

## 3 Download Flow

```
Download request
    │
    ▼
① Validate skill status (ACTIVE) and version status (PUBLISHED)
    │
    ▼
② Visibility check
   - PUBLIC: anyone (including anonymous users)
   - NAMESPACE_ONLY: members of the namespace (login required)
   - PRIVATE: owner themselves + at least namespace ADMIN (login required)
    │
    ▼
③ Return pre-generated package or package by file manifest
    │
    ▼
④ Audit and statistics
   - audit_log written synchronously (records downloader/IP/version)
   - download_count updated asynchronously (atomic SQL: download_count = download_count + 1)
   - Anonymous download: audit records IP + User-Agent; not linked to a user
   - Authenticated download: audit records user ID
```

### download_count Hot Row Mitigation Plan

Phase 1 uses atomic SQL for direct updates; this is acceptable. If hot row bottlenecks appear, switch to:
1. Redis `INCR` for real-time counting (key: `skill:downloads:{skillId}`)
2. Scheduled task batch write-back to PostgreSQL every 5 minutes
3. Query merges PostgreSQL stored count + Redis increment

## 4 Search Flow

```
Search request (keyword, namespaceSlug?, sortBy)
    │
    ▼
① Build SearchQuery
   - Anonymous user: visibility restricted to PUBLIC
   - Authenticated user: compute visible scope based on namespace membership
    │
    ▼
② SearchQueryService.search(query)
    │
    ▼
③ Return paginated results (skill summary + namespace info + rating + download count)
```

## 5 Favorites Flow

```
Favorite / unfavorite (login required) → validate permissions → write/delete skill_star
→ asynchronously update skill.star_count (atomic SQL)
```

## 6 Rating Flow

```
Submit rating (score: 1–5) (login required) → validate permissions → write/update skill_rating
→ asynchronously recalculate skill.rating_avg and rating_count (SELECT AVG + Redis distributed lock to prevent duplicate recalculation)
```

## 7 Async Events Summary

| Event | Trigger | Consumer |
|------|---------|--------|
| `SkillPublishedEvent` | Review approved | Search index write |
| `SkillYankedEvent` | Version retracted | Search index removal |
| `SkillDownloadedEvent` | Download complete | Download count update |
| `SkillStarredEvent` | Favorite / unfavorite | Favorite count update |
| `SkillRatedEvent` | Rating submitted | Rating recalculation |
| `ReviewCompletedEvent` | Review complete | Reserved for future notification capability (can be left unconsumed for now) |
| `SkillPromotedEvent` | Promoted to global | Search index write (new skill) |

Phase 1 uses Spring ApplicationEvent + `@Async`; can be replaced with a message queue later.

### Audit Log Write Strategy

Audit logs are written synchronously to the database, within the same request as the business operation; they do not go through async events. Auditing is a hard requirement for enterprise internal platforms and cannot tolerate data loss.

Async events are used only for scenarios where some delay is tolerable, such as search indexing and counters. If stronger consistency is required in the future, the outbox pattern should be introduced; Spring ApplicationEvent + @Async should not be relied upon for reliability.

### Async Event Reliability Guarantee

Spring ApplicationEvent + @Async carries the risk of event loss when a Pod is killed. The following fallback mechanisms are added:

- Search index: a scheduled task runs hourly to check for versions with `skill_version.status = PUBLISHED` that have no corresponding `skill_search_document` record, and builds the missing index entries
- Counters: a small amount of loss is acceptable; a scheduled task runs nightly to recalculate and correct counts from the `skill_star` / `skill_rating` tables
- Graceful shutdown: `@Async` thread pool configured with `awaitTerminationSeconds=25`, paired with a 30-second shutdown timeout

## 8 Distributed Concurrency Safety Measures

| Operation | Concurrency Control Method |
|------|-------------|
| Review approval / rejection | Optimistic lock: `UPDATE review_task SET status=? WHERE id=? AND version=?` |
| Version publish | Unique constraint: `(skill_id, version)` |
| Counter update | Atomic SQL: `SET count = count + 1` |
| Rating recalculation | Async + Redis distributed lock to prevent duplicate recalculation |
| Write operation idempotency | Redis stores `X-Request-Id`, TTL 24h |

### Idempotency Deduplication Specification

Full idempotency implemented based on the `idempotency_record` table:

- `X-Request-Id` is generated by the client (UUID v4 format)
- If the client does not provide one, the server generates one automatically but does not perform idempotency deduplication

Deduplication flow:
1. Redis `SETNX` key=`idempotent:{requestId}` (fast deduplication cache, TTL=24h)
   - Key already exists: query `idempotency_record` table and return the original result
2. Key does not exist: insert `idempotency_record` (status=`PROCESSING`)
3. Execute business logic
4. Success: update record to `COMPLETED`, populate `resource_type` + `resource_id` + `response_status_code`
5. Failure: update record to `FAILED`
6. On duplicate request: query record; COMPLETED returns the original resource ID; PROCESSING returns `409 Conflict`; FAILED allows retry

Applicable scope: all POST/PUT/DELETE write operations (publish, submit for review, create Token, etc.)

Exception recovery strategy:
- Redis key exists but `idempotency_record` has no record (process crashed between the two steps): treat as dirty state; delete the Redis key; allow the request to re-enter normally
- `idempotency_record.status = FAILED`: delete the corresponding Redis key; allow the client to retry with the same `request_id`
- `idempotency_record.status = PROCESSING` not updated for more than 5 minutes: treat as a dead record; mark as FAILED; delete the Redis key; allow retry
