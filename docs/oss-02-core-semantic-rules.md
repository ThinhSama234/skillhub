# OSS-02 Core Semantic Rules Consolidation

## 1. Document Goals

This document codifies the runtime semantic rules of SkillHub Core to ensure that the open-source version and the SaaS version are aligned on rules for deletion, YANKED, name conflicts, package_name, and more — preventing state drift when AstronClaw is onboarded. The rules defined here represent the `Core` rule baseline that can be uniformly wrapped by SaaS and provided to AstronClaw; this does not mean AstronClaw directly interfaces with these open-source interfaces.

---

## 2. Change Summary

### 2.1 New Features

| Feature | Description |
|------|------|
| UPLOADED status | New version status indicating "uploaded, not yet submitted for review" |
| PRIVATE skill auto-publish | After a PRIVATE skill is published, it enters the UPLOADED status and does not automatically enter review |
| Submit for review interface | New `POST /{namespace}/{slug}/submit-review`, allowing versions in UPLOADED status to be submitted for review |
| Withdraw from review enters UPLOADED | After withdrawing from review, the version status becomes UPLOADED instead of DRAFT |

### 2.2 State Machine Changes

**Before:**
```
DRAFT → SCANNING → PENDING_REVIEW → PUBLISHED
                         ↓            ↓
                    REJECTED      YANKED
```

**After:**
```
DRAFT → SCANNING → UPLOADED → PENDING_REVIEW → PUBLISHED
         ↓              ↓           ↓            ↓
    SCAN_FAILED    (deletable)  REJECTED      YANKED
         ↓                       ↓
      (deletable)            (deletable)
```

### 2.3 Permission Model Changes

**Core principle:** Permissions are determined solely by status; visibility only affects state transitions.

---

## 3. Version Status Definitions

### 3.1 Status Enum

```java
public enum SkillVersionStatus {
    DRAFT,           // Draft, being edited
    SCANNING,        // Security scan in progress
    SCAN_FAILED,     // Scan failed
    UPLOADED,        // Uploaded, not yet submitted for review (new)
    PENDING_REVIEW,  // Awaiting review
    PUBLISHED,       // Published
    REJECTED,        // Review rejected
    YANKED           // Yanked
}
```

### 3.2 Status Semantics

| Status | Meaning | File State | Downloadable | Editable | Has Scan Report |
|------|------|---------|-------|-------|----------|
| DRAFT | Draft, being edited | Possibly incomplete | No | Yes | No |
| SCANNING | Security scan in progress | Complete | No | No | No |
| SCAN_FAILED | Scan failed | Complete | No | Yes | Yes (failed) |
| UPLOADED | Uploaded, scan passed | Complete | Owner | No | Yes |
| PENDING_REVIEW | Under review | Complete | Owner | No | Yes |
| PUBLISHED | Published | Complete | By visibility | No | Yes |
| REJECTED | Review rejected | Complete | No | Yes | Yes |
| YANKED | Yanked | Complete | No | No | Yes |

---

## 4. Publishing Workflow Design

### 4.1 Publishing Paths

| Visibility | Initial Status After Publishing | Review Task Created |
|------------|--------------|----------------|
| PRIVATE | UPLOADED | No |
| NAMESPACE_ONLY | PENDING_REVIEW | Yes |
| PUBLIC | PENDING_REVIEW | Yes |

### 4.2 Complete Lifecycle for PRIVATE Skills

```
User publishes a PRIVATE skill
    ↓
Status: SCANNING (security scan in progress)
    ↓
Scan passes
    ↓
Status: UPLOADED
Visibility: PRIVATE
    ↓
Owner can download/install/test
Not visible in market
Visible to admins (for auditing)
Scan report available
    ↓
Owner satisfied with testing, confirms publish (confirm-publish)
    ↓
Status: PUBLISHED
Visibility: PRIVATE (official private version)
    ↓
Owner can download/install
Not visible in market
    ↓
User wants to make it public, submits for review
    ↓
Status: PENDING_REVIEW
requestedVisibility: PUBLIC
    ↓
Owner can still download/test
    ↓
Review approved
    ↓
Status: PUBLISHED
Visibility: PUBLIC (no longer PRIVATE)
    ↓
Visible in market, downloadable by everyone
```

### 4.3 PUBLIC/NAMESPACE_ONLY Skill Lifecycle

```
User publishes a PUBLIC/NAMESPACE_ONLY skill
    ↓
Status: PENDING_REVIEW
    ↓
Owner can download/test
    ↓
Review approved
    ↓
Status: PUBLISHED
Visibility: PUBLIC or NAMESPACE_ONLY
    ↓
Visible in market (controlled by visibility)
```

---

## 5. Permission Matrix

### 5.1 Status Determines Download Permission

| Status | Market Visible | Downloadable |
|--------|---------|-------|
| DRAFT | No | No |
| SCANNING | No | No |
| SCAN_FAILED | No | No |
| UPLOADED | No | Owner |
| PENDING_REVIEW | No | Owner |
| PUBLISHED | By visibility | By visibility |
| REJECTED | No | No |
| YANKED | No | No |

### 5.2 In PUBLISHED Status, Visibility Determines Accessibility

| Visibility | Market Visible | Downloadable |
|------------|---------|-------|
| PUBLIC | Yes | Everyone |
| NAMESPACE_ONLY | Within namespace | Namespace members |
| PRIVATE | No | Owner |

### 5.3 AstronClaw Installation Check Rules

```
Installable = 
  skill.status == ACTIVE
  AND skill.hidden == false
  AND at least one downloadable version exists
  AND that version's bundleReady == true

Downloadable version check:
  - UPLOADED/PENDING_REVIEW: owner only
  - PUBLISHED: by visibility rules
```

---

## 6. State Transition Detailed Design

### 6.1 State Transition Table

| Current Status | Operation | Target Status | Notes |
|---------|------|---------|------|
| DRAFT | Upload package | SCANNING | Begin security scan |
| SCANNING | Scan passes | UPLOADED or PENDING_REVIEW | Depends on visibility |
| SCANNING | Scan fails | SCAN_FAILED | - |
| SCAN_FAILED | Re-upload | SCANNING | - |
| UPLOADED | Submit for review | PENDING_REVIEW | New operation |
| UPLOADED | Confirm publish | PUBLISHED | PRIVATE skill official publish, does not trigger new scan |
| UPLOADED | Re-upload | SCANNING | Re-upload allowed |
| UPLOADED | Delete | (deleted) | Deletion allowed; not yet officially published |
| PENDING_REVIEW | Review approved | PUBLISHED | - |
| PENDING_REVIEW | Review rejected | REJECTED | - |
| PENDING_REVIEW | Withdraw from review | UPLOADED | Changed: was previously DRAFT |
| PUBLISHED | Yank | YANKED | - |
| REJECTED | Re-upload | SCANNING | - |

### 6.2 State Machine Diagram

```
                    ┌─────────────────────────────────────────┐
                    │              Upload Package              │
                    └─────────────────────────────────────────┘
                                      ↓
                              ┌───────────────┐
                              │   SCANNING    │
                              └───────────────┘
                               /            \
                  Scan passes /              \ Scan fails
                             /                \
               ┌────────────────────────┐  ┌───────────────┐
               │ visibility=PRIVATE     │  │ SCAN_FAILED   │
               │ → UPLOADED             │  └───────────────┘
               │ visibility=PUBLIC/     │         │
               │   NAMESPACE_ONLY       │         │ Re-upload
               │ → PENDING_REVIEW       │         ↓
               └────────────────────────┘  ┌───────────────┐
                             │             │   SCANNING    │
                             ↓             └───────────────┘
               ┌────────────────────────┐
               │       UPLOADED         │◄────────────────────────┐
               │  (PRIVATE skill only)  │                         │
               │  Scan report available │                         │
               └────────────────────────┘                         │
                    /           \                                 │
       Confirm pub /             \ Submit for review              │
  (no new scan)  /               \                               │
                /                 \                              │
               ↓                   ↓                             │
    ┌───────────────────┐  ┌───────────────────┐                 │
    │ PUBLISHED         │  │  PENDING_REVIEW   │                 │
    │ visibility=PRIVATE│  └───────────────────┘                 │
    └───────────────────┘           │                           │
              │                     │                           │
              │ Submit for review   │ Review approved            │
              ↓                     ↓                           │
    ┌───────────────────┐  ┌───────────────────┐                 │
    │  PENDING_REVIEW   │  │    PUBLISHED      │                 │
    └───────────────────┘  │ visibility=PUBLIC │                 │
              │            │ or NAMESPACE_ONLY │                 │
              │            └───────────────────┘                 │
              │ Withdraw from review  │                          │
              └──────────────────────┘                          │
                      (enters UPLOADED)                          │
                                                                  │
    ┌───────────────────┐                                        │
    │     REJECTED      │────────────────────────────────────────┘
    └───────────────────┘              Re-upload
              │
              │ Delete
              ↓
           (deleted)
```

---

## 7. New Interface Design

Note:

The following interfaces are Core open-source state machine capabilities provided for the SaaS wrapper layer. For `AstronClaw`, these capabilities should still be consumed uniformly through the `SkillHub SaaS` `AstronClaw Adapter`, rather than directly binding to these open-source interface paths.

### 7.1 Submit for Review Interface

**Interface:** `POST /api/v1/skills/{namespace}/{slug}/submit-review`

**Request Parameters:**
```json
{
  "version": "1.0.0",
  "targetVisibility": "PUBLIC"
}
```

**Preconditions:**
- Version status is UPLOADED
- Operator is the skill owner or namespace ADMIN/OWNER

**Effect:**
- Version status → PENDING_REVIEW
- `requestedVisibility` is set to the target visibility
- A review task is created

**Response:**
```json
{
  "code": 0,
  "data": {
    "versionId": 100,
    "status": "PENDING_REVIEW",
    "requestedVisibility": "PUBLIC"
  }
}
```

### 7.2 Confirm Publish Interface (PRIVATE Skill)

**Interface:** `POST /api/v1/skills/{namespace}/{slug}/confirm-publish`

**Request Parameters:**
```json
{
  "version": "1.0.0"
}
```

**Preconditions:**
- Version status is UPLOADED
- skill.visibility = PRIVATE
- Operator is the skill owner

**Effect:**
- Version status → PUBLISHED
- Visibility remains PRIVATE
- **Does not trigger a new scan**; reuses the scan result from the UPLOADED stage
- Future extensibility: add a "publish scan" feature

**Response:**
```json
{
  "code": 0,
  "data": {
    "skillId": 42,
    "versionId": 100,
    "status": "PUBLISHED",
    "visibility": "PRIVATE"
  }
}
```

---

## 8. Delete / Hide / Archive / YANKED Semantic Rules

### 8.1 Operation Semantics Summary Table

| Operation | Trigger | Reversible | Market Visible | New Install | Existing Install Retained | Uninstallable | Slug Reusable |
|------|---------|------|---------|-------|---------|-------|-----------|
| **Hard delete skill** | Owner or SUPER_ADMIN | No | No | No | Yes | Yes | Yes |
| **Archive skill** | Owner / namespace admin | Yes | No | No | Yes | Yes | No |
| **Hide skill** | Admin | Yes | No | No | Yes | Yes | No |
| **Yank version** | Owner / namespace admin | No | No | No | Yes | Yes | N/A |

### 8.2 Yank Version

**Definition:** YANK is the operation of "retracting a published version", removing a published version from the available state.

**Trigger conditions:**
- Owner or namespace ADMIN/OWNER yanks a version in PUBLISHED status

**Effect:**
- `version.status` → `YANKED` (irreversible; no un-yank operation)
- `version.downloadReady` → `false`
- Records `yankedAt`, `yankedBy`, `yankReason`
- If this version is the version pointed to by `skill.latestVersionId`:
  - Automatically rolls back to the previous PUBLISHED version
  - If there are no other PUBLISHED versions, `latestVersionId` → `null`

**Impact on AstronClaw:**
- Existing installs are unaffected
- Cannot install this version anew
- Upgrade scenario: if the target version is yanked → upgrade fails

Interface principles:
- The above semantics should be inherited as-is by the SaaS Adapter and stably exposed externally
- AstronClaw perceives these states through the Adapter, without directly binding to the open-source return format

**Remediation:**
- Cannot un-yank
- Must publish a new version (rerelease or re-upload)

---

## 9. Name Conflict Rules

### 9.1 Uniqueness Constraint

Database constraint: `UNIQUE(namespace_id, slug, owner_id)`

Meaning:
- Within the same namespace, different owners can have the same slug
- Within the same namespace, the same owner can only have one skill with the same slug

### 9.2 Conflict Rule Design Principles

**Core principle:** Only PUBLISHED status blocks same-name publishing, but distinguished by visibility.

| Other Party's Status | I Publish Same-Name PRIVATE | I Publish Same-Name PUBLIC | Notes |
|---------|-------------------|------------------|------|
| UPLOADED | Allowed | Allowed | Multiple UPLOADED can coexist |
| PENDING_REVIEW | Allowed | Allowed | Not yet officially published |
| PRIVATE + PUBLISHED | Rejected | Rejected | Only one official private version allowed |
| PUBLIC + PUBLISHED | Rejected | Rejected | Market is already occupied |

### 9.3 Conflict Rules Table (Detailed)

| Scenario | Allowed | Notes |
|------|---------|------|
| Same namespace, same slug, same owner | Allowed (reuse) | New version is attached to the existing skill |
| Same namespace, same slug, different owner, other party has only UPLOADED | Allowed | Multiple UPLOADED can coexist for testing |
| Same namespace, same slug, different owner, other party has only PENDING_REVIEW | Allowed | Not yet officially published |
| Same namespace, same slug, different owner, other party has PRIVATE + PUBLISHED | Rejected | Only one official private version allowed |
| Same namespace, same slug, different owner, other party has PUBLIC/NAMESPACE_ONLY + PUBLISHED | Rejected | Market is already occupied |
| Different namespace, same slug | Allowed | Namespace isolation |

### 9.4 Complete Flow Example

```
User A publishes PRIVATE `ns/my-skill`
    ↓
Status: UPLOADED
    ↓
User B publishes PRIVATE `ns/my-skill`
    ↓
Status: UPLOADED ✅ Allowed (multiple UPLOADED can coexist)
    ↓
User A confirms publish → PRIVATE + PUBLISHED ✅ Allowed
    ↓
User B confirms publish → ❌ Rejected
    ↓
Error: error.skill.publish.nameConflict.private
    ↓
User B can:
  1. Rename and publish
  2. Wait for User A to delete/archive, then publish
  3. Submit for review to become PUBLIC (if A is PRIVATE)
```

### 9.5 Code Changes

**File:** `SkillPublishService.java`

```java
// Conflict check logic (lines 230-242)
for (Skill existing : existingSkills) {
    if (!existing.getOwnerId().equals(publisherId)) {
        // Check if there is a PUBLISHED version
        boolean hasPublished = !skillVersionRepository
                .findBySkillIdAndStatus(existing.getId(), SkillVersionStatus.PUBLISHED)
                .isEmpty();
        
        if (hasPublished) {
            // PUBLISHED version exists; reject regardless of visibility
            // because only one PRIVATE + PUBLISHED or PUBLIC + PUBLISHED is allowed
            if (existing.getVisibility() == SkillVisibility.PRIVATE) {
                throw new DomainBadRequestException("error.skill.publish.nameConflict.private", skillSlug);
            } else {
                throw new DomainBadRequestException("error.skill.publish.nameConflict", skillSlug);
            }
        }
    }
}
```

### 9.6 Error Messages

| Error Code | Description |
|-------|------|
| `error.skill.publish.nameConflict` | A same-name PUBLIC/NAMESPACE_ONLY skill is already published |
| `error.skill.publish.nameConflict.private` | A same-name PRIVATE skill is already officially published |

---

## 10. package_name / Runtime Rules

### 10.1 Current Implementation

- `package_name` is not a structured field in Core
- Stored in the `skill_version.parsedMetadataJson` JSONB field
- Defined by the skill author in the SKILL.md frontmatter

### 10.2 SaaS Adapter Responsibilities

- Extract `package_name` from `parsedMetadataJson`
- Return it as a top-level field to AstronClaw
- Optional: check `package_name` uniqueness across skills
- Uniformly wrap Core capabilities such as `submit-review`, `confirm-publish`, delete, and query, exposing stable interfaces to AstronClaw

### 10.3 Rule Recommendations

| Rule | Recommendation |
|------|------|
| Format | Recommend using `namespace__slug` format to avoid conflicts |
| Cross-version stability | The same skill should maintain a consistent `package_name` across versions |
| Uniqueness | SaaS Adapter can check and warn about conflicts, but not force rejection |

---

## 11. Code Change Checklist

Note:

The following changes are rule implementations in the open-source `Core`, for providing a stable capability baseline to the SaaS wrapper layer; this does not equate to directly exposing these open-source interfaces to AstronClaw.

### 11.1 Enum Addition

**File:** `SkillVersionStatus.java`

```java
public enum SkillVersionStatus {
    DRAFT,
    SCANNING,
    SCAN_FAILED,
    UPLOADED,      // New
    PENDING_REVIEW,
    PUBLISHED,
    REJECTED,
    YANKED
}
```

### 11.2 Publish Logic Changes

**File:** `SkillPublishService.java`

```java
// Lines 279-285, changed to
if (visibility == SkillVisibility.PRIVATE) {
    version.setStatus(SkillVersionStatus.UPLOADED);
    version.setPublishedAt(currentTime());
    // Do not create a review task
} else if (autoPublish) {
    version.setStatus(SkillVersionStatus.PUBLISHED);
    version.setPublishedAt(currentTime());
} else {
    version.setStatus(SkillVersionStatus.PENDING_REVIEW);
    // Create a review task
}
```

### 11.3 Withdraw from Review Changes

**File:** `SkillGovernanceService.java`

```java
// withdrawPendingVersion method, changed to
skillVersion.setStatus(SkillVersionStatus.UPLOADED);  // Was previously DRAFT
```

### 11.4 Download Permission Changes

**Files:** `SkillDownloadService.java`, `SkillQueryService.java`

```java
// UPLOADED and PENDING_REVIEW statuses allow owner download
private boolean canDownload(SkillVersion version, Skill skill, String currentUserId) {
    return switch (version.getStatus()) {
        case UPLOADED, PENDING_REVIEW -> skill.getOwnerId().equals(currentUserId);
        case PUBLISHED -> true;  // By visibility rules
        default -> false;
    };
}
```

### 11.5 New Service

**File:** `SkillReviewSubmitService.java` (new)

- Implements the logic for submitting an UPLOADED version for review

### 11.6 New Controller

**File:** `SkillReviewSubmitController.java` (new)

- Exposes `POST /{namespace}/{slug}/submit-review` interface
- Exposes `POST /{namespace}/{slug}/confirm-publish` interface

### 11.7 Admin Visibility

**File:** `VisibilityChecker.java`

- SUPER_ADMIN can see all skills, including those in UPLOADED status

### 11.8 Database Migration

**File:** New migration script

- Update the `skill_version_status` enum type to add the UPLOADED value

---

## 12. Blocking Release Conditions

| Issue | Severity | Status |
|------|---------|------|
| Add UPLOADED status | High | Done |
| PRIVATE skill publish logic changes | High | Done |
| Submit for review interface | High | Done |
| Withdraw from review enters UPLOADED | Medium | Done |
| Name conflict check completion | Medium | Done |
| Admin visibility for UPLOADED skills | Low | Done |
| package_name uniqueness check | Low | Optional (SaaS Adapter responsibility) |

---

## 13. Impact on Older Versions

### 13.1 Data Compatibility

| Impact Point | Analysis | Action Required |
|--------|------|---------|
| Old version data | Unaffected; statuses remain unchanged | No |
| Database enum | Need to add UPLOADED value | Yes |
| API compatibility | New interfaces are additions; existing interfaces are unaffected | No |

### 13.2 State Transition Impact

| Scenario | Old Logic | New Logic | Impact |
|------|--------|--------|------|
| Old version withdraw from review | PENDING_REVIEW → DRAFT | PENDING_REVIEW → UPLOADED | Frontend needs to adapt to the new status |
| Old version delete | DRAFT/REJECTED/SCAN_FAILED can be deleted | UPLOADED can also be deleted | Code check needs to be updated |

### 13.3 Code Change Points

**File:** `SkillGovernanceService.java`

**1. Delete version logic** (lines 163-166):
```java
// Original code
if (version.getStatus() != SkillVersionStatus.DRAFT
        && version.getStatus() != SkillVersionStatus.REJECTED
        && version.getStatus() != SkillVersionStatus.SCAN_FAILED) {
    throw new DomainBadRequestException("error.skill.version.delete.unsupported", version.getVersion());
}

// Changed to: allow deleting UPLOADED status
if (version.getStatus() != SkillVersionStatus.DRAFT
        && version.getStatus() != SkillVersionStatus.REJECTED
        && version.getStatus() != SkillVersionStatus.SCAN_FAILED
        && version.getStatus() != SkillVersionStatus.UPLOADED) {
    throw new DomainBadRequestException("error.skill.version.delete.unsupported", version.getVersion());
}
```

**2. Withdraw from review logic** (line 245):
```java
// Original code
version.setStatus(SkillVersionStatus.DRAFT);

// Changed to
version.setStatus(SkillVersionStatus.UPLOADED);
```

### 13.4 Frontend Adaptation

| Status | Frontend Display Recommendation |
|------|-------------|
| UPLOADED | "Uploaded" or "Pending Confirmation" |
| Deletable statuses | DRAFT, SCAN_FAILED, REJECTED, UPLOADED |
| Editable statuses | DRAFT, SCAN_FAILED, REJECTED |

### 13.5 Migration Strategy

1. **Database migration:** Add the UPLOADED enum value
2. **Code deployment:** Deploy backend first, then deploy frontend
3. **Old data handling:** No action needed; old version statuses remain unchanged
4. **Rollback plan:** If rollback is needed, treat UPLOADED status versions as DRAFT
