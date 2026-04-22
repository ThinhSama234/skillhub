# Skill Lifecycle

Date: 2026-03-18
Status: current code-aligned reference

This document is the single authoritative reference for the skill lifecycle. Conclusions are based on the current code implementation and have been synchronized to the domain model, business flows, API, frontend, search, and compatibility layer documentation.

## 1. Design Principles

- The skill lifecycle is no longer modeled as a mixed state machine. Instead it is split into container state, version state, review workflow state, and a visibility override layer.
- The frontend no longer assembles state from `status + hidden + latestVersionStatus + viewingVersionStatus`. It uniformly consumes the backend lifecycle projection.
- Destructive actions and reversible actions must be separated. `withdraw-review` means only withdrawing a pending review submission, not deleting a version.
- The `latest` protocol vocabulary may still be exposed externally, but its internal semantics must be strictly equivalent to "latest published."

## 2. State Model

### 2.1 Skill Container State

- `ACTIVE`
- `ARCHIVED`

Notes:

- `hidden` is an independent governance override layer and is not part of `Skill.status`.
- `SkillStatus.HIDDEN` is no longer treated as a valid lifecycle semantic.

### 2.2 SkillVersion Version State

- `DRAFT`
- `PENDING_REVIEW`
- `PUBLISHED`
- `REJECTED`
- `YANKED`

State meanings:

- `DRAFT`: A non-public version that can be re-submitted for review or deleted.
- `PENDING_REVIEW`: A frozen version awaiting review.
- `PUBLISHED`: The currently distributable version.
- `REJECTED`: A version retained after being rejected by review.
- `YANKED`: A version that was previously published and has since been withdrawn from distribution.

### 2.3 ReviewTask Workflow State

- `PENDING`
- `APPROVED`
- `REJECTED`

`ReviewTask` expresses only the review process and is no longer used by the frontend as a display state source.

## 3. Core Semantics

### 3.1 Latest

- The sole semantic of `Skill.latestVersionId` is the latest published pointer.
- It can only point to a `PUBLISHED` version.
- If the skill has no published versions, it is allowed to be `null`.
- The `latest` system-reserved tag automatically follows this pointer.

### 3.2 Lifecycle Projection

Read models for the detail page, my skills, my favorites, search, and similar views are all based on the following projection:

- `headlineVersion`: The primary version displayed on the current page.
- `publishedVersion`: The latest published version.
- `ownerPreviewVersion`: A pending-review preview version visible to the owner or namespace manager.
- `resolutionMode`: `PUBLISHED` / `OWNER_PREVIEW` / `NONE`

Constraints:

- Public browsing, installation, download, and search recognize only `publishedVersion`.
- The owner detail page is only allowed to set `headlineVersion = ownerPreviewVersion` when no `publishedVersion` exists.
- Public distribution behaviors such as promotion, compat latest, and default download can only be bound to `publishedVersion`.

## 4. Actual Code Path

### 4.1 First Upload

- When a regular user uploads, a `PENDING_REVIEW` version is created directly.
- A `PENDING` review task is created at the same time.
- An initial `DRAFT` is not created.
- `latestVersionId` is not updated.

### 4.2 Review Approved

- `PENDING_REVIEW -> PUBLISHED`
- The review task is marked `APPROVED`.
- `Skill.latestVersionId` points to that version.
- The skill's display metadata is refreshed from the published version.

### 4.3 Review Rejected

- `PENDING_REVIEW -> REJECTED`
- The review task is marked `REJECTED`.
- The version is retained and can be deleted later.

### 4.4 Withdraw Review

- The unified semantic of `withdraw-review` is `PENDING_REVIEW -> DRAFT`.
- The associated `PENDING review_task` is deleted at the same time.
- This operation is reversible and non-destructive.
- The current code only allows the submitter themselves to withdraw.

### 4.5 Uploading a New Version

- If an old `PENDING_REVIEW` version is found, it is first automatically demoted back to `DRAFT`.
- Then a new pending-review version is created.
- Automatic withdrawal and manual withdrawal must maintain the same semantics.

### 4.6 Re-releasing a Published Version

- A rerelease is currently essentially copying from a published version and going through the publish flow again.
- The current implementation allows a privileged path to directly produce a new `PUBLISHED` version.
- This capability should be understood as a special case in the publish path, not a lifecycle display state.

### 4.7 Hide / Restore / Archive / Withdraw Published Version

- Hide: only changes `hidden=true`
- Restore: only changes `hidden=false`
- Archive: `Skill.status = ARCHIVED`
- Unarchive: `Skill.status = ACTIVE`
- Yank: `PUBLISHED -> YANKED`

### 4.8 Pointer Correction After Yank

- When a published version is yanked and it matches the current `latestVersionId`, the latest published pointer must be recalculated.
- If there are still other `PUBLISHED` versions, point to the most recent one.
- If there are no longer any `PUBLISHED` versions, set `latestVersionId = null`.

## 5. External Protocol Constraints

### 5.1 Public / Search / Compat

- External protocols may continue to expose concepts such as `latestVersion`, `latest`, and default download.
- But they must all strictly represent "the latest published version."
- The internal implementation of the compat layer must map from the `publishedVersion` of the unified lifecycle projection. It is not allowed to derive the "current version" independently.

### 5.2 Frontend

- Page state display uniformly consumes the projection.
- No new dependencies on old compatibility fields are to be added.
- `hidden` is only displayed as a governance flag and does not participate in version state assembly.

## 6. Permission Boundaries

- `withdraw-review`: submitter only
- Delete version: owner or namespace manager, and only for `DRAFT` / `REJECTED`
- Archive / unarchive: owner or namespace manager
- Hide / restore skill, withdraw published version: platform skill governance permission

## 7. Current Final Constraints

- This document is the single authoritative reference for the skill lifecycle.
- Other documents such as `02-domain-model`, `05-business-flows`, `06-api-design`, and `08-frontend-architecture` must remain consistent with this document.
- If the code changes lifecycle semantics again in the future, the code should be updated first, then this document and related sub-documents should be synchronized.
