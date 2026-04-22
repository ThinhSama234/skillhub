# Skill Label System Design

> Date: 2026-03-20
> Status: Draft
> Scope: Phase 1 — System-recommended labels + Privileged labels

## 1. Overview

This document introduces a label system for SkillHub that provides classification and tagging capabilities for skills. Labels are attached at the skill level (independent of versions), and support multilingual display and search.

Note: This system uses "label" rather than "tag" because `skill_tag` is already occupied by the version distribution channel feature.

### 1.1 Phase 1 Scope

**Included:**
- System-recommended labels (RECOMMENDED): Admin CRUD + multilingual translations + ordering, used for category filtering on the search page
- Privileged labels (PRIVILEGED): Exclusively granted by admins, e.g., "Official Recommendation", "Official Certification", "Mirrored from Clawhub"
- Label display and management on the skill detail page
- Category section on the search page (single-select mutually exclusive filtering)
- Multilingual search matching (all language translations written into the search document)

**Not included (reserved for compatibility):**
- User-defined labels
- User-defined label review workflow

### 1.2 Key Decisions

- `label_*` is an entirely new model, completely isolated from the existing `skill_tag`; `skill_tag` continues to serve only as a "version distribution alias" — no reuse of tables, Service, Controller, DTO, or API paths
- `skill_search_document.keywords` is a shared aggregated field of the search document, not a label-exclusive field; in Phase 1, when rebuilding the search document, the "existing business keywords sources" and "label translation text" are combined as two independent sources
- Label search integration only allows "full rebuild of a single skill's search document from the authoritative source" — incremental append by reading the existing `skill_search_document.keywords` is not allowed
- Promotion in the current system creates a new target skill rather than moving the source skill to a new namespace; therefore, the label lifecycle must be modeled as "two independent skill records: source skill / target skill"

## 2. Data Model

Note: All new tables use `TIMESTAMPTZ` as the standard timestamp type (existing legacy tables use `TIMESTAMP` and will be migrated uniformly later).

### 2.1 label_definition (Label Definition Table)

```sql
CREATE TABLE label_definition (
    id          BIGSERIAL PRIMARY KEY,
    slug        VARCHAR(64) UNIQUE NOT NULL,   -- English identifier, required, e.g., code-generation
    type        VARCHAR(16) NOT NULL CHECK (type IN ('RECOMMENDED', 'PRIVILEGED')),
    visible_in_filter BOOLEAN NOT NULL DEFAULT true, -- whether to show in the search page category section
    sort_order  INTEGER NOT NULL DEFAULT 0,    -- display order in the category section
    created_by  VARCHAR(128) REFERENCES user_account(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

- `slug` is the English name, serving as a language-agnostic unique identifier
- `type` distinguishes system-recommended labels from privileged labels and determines the permission control strategy. The DDL layer limits valid values via CHECK constraint; the application-layer permission check uses a deny-by-default policy for unknown types
- `visible_in_filter` controls whether the label appears in the search page category section; both RECOMMENDED and PRIVILEGED can be configured

### 2.2 label_translation (Label Translation Table)

```sql
CREATE TABLE label_translation (
    id          BIGSERIAL PRIMARY KEY,
    label_id    BIGINT NOT NULL REFERENCES label_definition(id) ON DELETE CASCADE,
    locale      VARCHAR(16) NOT NULL,          -- language code, e.g., en, zh, ja
    display_name VARCHAR(128) NOT NULL,        -- display name in that language
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(label_id, locale)
);
```

- Supports dynamic languages: admins can add translations for any language, not limited to the system's currently supported language list
- Frontend display fallback order: current language → en → slug
- When the backend returns `displayName`, the "current language" is determined by the request locale; implemented using Spring's locale resolution (equivalent to based on `Accept-Language` / request locale), then falling back to `en` and `slug`

### 2.3 skill_label (Skill-to-Label Association Table)

```sql
CREATE TABLE skill_label (
    id          BIGSERIAL PRIMARY KEY,
    skill_id    BIGINT NOT NULL REFERENCES skill(id) ON DELETE CASCADE,
    label_id    BIGINT NOT NULL REFERENCES label_definition(id) ON DELETE CASCADE,
    created_by  VARCHAR(128) REFERENCES user_account(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(skill_id, label_id)
);

CREATE INDEX idx_skill_label_label_id ON skill_label(label_id);
```

- Labels are attached at the skill level, independent of versions
- Cascade delete: automatically cleans up associations when label_definition is deleted
- The `(label_id)` index is a performance optimization for finding skills associated with a label during category filtering
- A single skill can be associated with at most 10 labels (enforced at the application layer)

### 2.5 Relationship with Existing `skill_tag`

The existing `skill_tag` is already used for version distribution channels, e.g., `latest`, `beta`, and other tags that point to a published version. It has the following characteristics:
- Its semantic meaning is "version alias", not skill classification
- `version_id` is required; a tag must resolve to a specific skill version
- The API and frontend mental model are already built around "installing/downloading a specific version alias"

Therefore:
- The new label system must not reuse the `skill_tag` table structure
- The new label system must not reuse `/tags`-related API paths
- The code implementation must use independent naming: `LabelDefinition` / `SkillLabel` / `LabelTranslation`

### 2.4 Compatibility Design: User-Defined Labels

Future user-defined labels can be extended in the following ways without creating new tables:

1. Add `USER_DEFINED` enum value to `label_definition.type`
2. Add fields to `label_definition`:
   - `status VARCHAR(16)` — `PENDING_REVIEW` / `APPROVED` / `REJECTED`, for the review workflow
   - `submitted_by VARCHAR(128)` — submitter
3. `label_translation` for user-defined labels only needs to store the user's original input language; multilingual translation is not required
4. Search behavior: user-defined labels are written into the search document keywords as raw text, and can only be searched in the user's input language

This design ensures:
- No breaking changes to the existing table structure
- The permission model naturally extends (`USER_DEFINED` type has independent permission rules)
- Consistent search integration (all via the keywords field)

## 3. Permission Model

| Operation | Object | Super Admin | Namespace Admin | Skill Owner | Regular User |
|------|------|:---:|:---:|:---:|:---:|
| CRUD label definitions | label_definition | ✅ | ❌ | ❌ | ❌ |
| Manage translations | label_translation | ✅ | ❌ | ❌ | ❌ |
| Assign/remove RECOMMENDED label | skill_label | ✅ | ✅ (own namespace, only search-visible RECOMMENDED labels) | ✅ (own skill, only search-visible RECOMMENDED labels) | ❌ |
| Assign/remove PRIVILEGED label | skill_label | ✅ | ❌ | ❌ | ❌ |
| View labels | All tables | ✅ | ✅ | ✅ | ✅ (subject to skill visibility constraints) |

- Managing label definitions and translations is a global operation, super admins only
- Permission to assign a label to a skill depends on the label's type
- View permission follows the skill's own visibility rules, no additional control
- The implementation must extract a unified `LabelPermissionChecker`; `SUPER_ADMIN` can always bypass namespace membership to directly perform label management operations, avoiding duplication of permission logic across controllers and services

### 3.1 Cross-Namespace Permission Boundary

- Namespace admins can only manage labels for skills within the namespaces they manage

### 3.2 Label Lifecycle After Promotion

The current factual model of promotion is "create a new target skill in the target global namespace after approval", rather than migrating the source skill to the global namespace.

Phase 1 adopts the following rules:
- Promotion does not automatically copy any labels from the source skill to the target skill
- The source skill and target skill each maintain independent `skill_label` records
- The source namespace admin's label permissions on the source skill remain unchanged
- The target skill's labels are controlled by the target skill's current permission model; source namespace admins do not automatically gain label management rights on the target skill by virtue of their management rights on the source skill

Rationale:
- Avoids introducing the additional complexity of "label copy/write-back/sync on promotion" in Phase 1
- Consistent with the current promotion domain model of "creating a new skill copy"
- If a copy strategy is needed later, it can be explicitly extended in the promotion approval workflow without breaking the existing table structure

## 4. Search Integration

Uses the approach of expanding translation text into the search document.

### 4.1 Current Search Architecture

The current search is based on PostgreSQL Full-Text Search:
- The `skill_search_document` table has a `search_vector` column of type `tsvector GENERATED ALWAYS AS ... STORED`
- Weight system: title (A) > summary/keywords (B) > search_text (C)
- `search_vector` is automatically regenerated when fields like keywords are updated, requiring no manual maintenance
- Queries use `d.search_vector @@ to_tsquery('simple', :tsQuery)` for full-text matching

### 4.2 Writing to the Keywords Field

When building a `SkillSearchDocument`, write all translation texts of all languages for all labels associated with the skill into the `keywords` field.

**Important:** `skill_search_document.keywords` is not a label-exclusive field — it is a shared aggregated field of the search document. In the current system, this field already carries keywords/tag information from skill metadata/frontmatter. Label translation text is just one new source and must not overwrite or break existing sources.

Implementation requirements:
- When rebuilding the search document, fully recalculate `keywords` from the authoritative source
- Existing business keywords sources and label translation text are combined as two independent sources
- Incremental append by reading the old `skill_search_document.keywords` is not allowed
- After a label is deleted, a translation is modified, or a label is removed from a skill, the old label text must be completely removed through a rebuild and must not remain

Recommended combination order in the implementation:
1. Retain the original keywords content produced by the existing search rebuild logic
2. Append all translation texts of labels associated with the skill
3. Write the final result back as the new `SkillSearchDocument.keywords`

Example:
```
[original keywords content] Code Generation Official
```

### 4.3 Search Document Rebuild Trigger Events

| Event | Affected Scope | Handling |
|------|---------|---------|
| Skill is assigned/removed a label | Single skill | Synchronously rebuild that skill's search document |
| label_translation is modified | All skills associated with that label | Asynchronous batch rebuild |
| label_definition is deleted | All skills associated with that label | Asynchronous batch rebuild |

#### Asynchronous Batch Rebuild Strategy

- Use Spring `@Async` to execute asynchronous tasks
- Implement the label-related search sync entry point in the application service at the `skillhub-app` layer (not in `SearchRebuildService` in the `skillhub-search` module, to avoid the search module having a direct dependency on the `skill_label` table and to maintain clear module boundaries)
- For changes that affect multiple skills — such as `label_translation` modifications or `label_definition` deletions — collect the list of affected `skill_id`s within the transaction, then trigger the asynchronous task in the `AFTER_COMMIT` phase
- In the `label_definition` deletion scenario, it is strictly forbidden to look up `skill_label` after deletion, because `skill_label` has already been cascade-deleted; the affected `skill_id`s must be snapshotted before deletion
- The asynchronous task calls `SearchRebuildService.rebuildBySkill(Long)` in batches
- Batch size: 50 skills per batch, no delay between batches (database write pressure is manageable, and the number of system-recommended labels is limited)
- Failure isolation: the batch rebuild loop must individually `try/catch` each skill and log errors, ensuring a single skill failure does not affect subsequent skills
- Error handling: log the error for a single skill rebuild failure, no automatic retry (it will be fixed on the next label change or manual rebuildAll)
- If the number of affected skills in a single event is very large, allow backend operators to manually trigger a full search rebuild as a fallback
- For the scenario of "popular labels causing a large number of skills to be rebuilt in bulk", Phase 1 does not introduce a dedicated task table; prioritize the existing async thread pool, handle small-scale batches directly, and use a backend manual `rebuildAll` as the fallback for extremely large batches

### 4.4 Category Filtering

The category section filtering on the search page does not go through full-text search. Instead, it filters via a case-insensitive match on slug by joining `skill_label` and `label_definition`, then intersects with the search results. This avoids the ambiguity issues of full-text search.

The current search entry point is:
```
GET /api/web/skills?q=xxx
```

In Phase 1, an optional query parameter `label` is added to the existing entry point, supporting multiple values to reserve future combined filtering capability (Phase 1 frontend only implements single selection):
```
GET /api/web/skills?q=xxx&label=code-generation
GET /api/web/skills?q=xxx&label=code-generation&label=official  (future)
```

#### SearchQuery Changes

`SearchQuery` needs a new `labelSlugs` field:
```java
public record SearchQuery(
    String keyword,
    Long namespaceId,
    SearchVisibilityScope visibilityScope,
    String sortBy,
    int page,
    int size,
    List<String> labelSlugs
) {}
```

Note:
- This is not a "zero-cost field addition"; the controller, application service, query service, and test code all need to be updated simultaneously
- When implementing, explicitly enumerate the following change points: HTTP parameter parsing, `SkillSearchAppService` parameter forwarding, `PostgresFullTextQueryService` SQL conditions, and related unit/controller tests
- If more search filter conditions are added later, consider evolving `SearchQuery` from a positional parameter record to a more extensible request object

In the SQL assembly logic of `PostgresFullTextQueryService`, when `labelSlugs` is non-empty, append:
```sql
AND d.skill_id IN (
    SELECT sl.skill_id FROM skill_label sl
    JOIN label_definition ld ON ld.id = sl.label_id
    WHERE ld.slug IN (:labelSlugs)
)
```

The count query should have the same condition appended. Semantic re-ranking is executed on the candidate set after label filtering, requiring no additional handling.

The current multi-label filtering uses OR semantics (matching any label counts as a hit). If AND semantics are needed in the future (requiring all labels simultaneously), this can be extended with `GROUP BY skill_id HAVING COUNT(*) = :labelCount`, and the API layer can add a `labelMode=any|all` parameter to distinguish.

### 4.5 tsvector Weights

The existing weight system is not changed. `search_vector` is a `GENERATED ALWAYS AS ... STORED` column that is automatically regenerated when the keywords field is updated, requiring no manual maintenance:
- Weight A: title (displayName)
- Weight B: summary / keywords (including label translation text)
- Weight C: searchText

## 5. API Design

### 5.1 Admin Backend API (Super Admin)

All responses follow the project's unified response specification `{ code, msg, data, timestamp, requestId }`.

#### List All Label Definitions
```
GET /api/v1/admin/labels
```
Response `data`:
```json
[
  {
    "slug": "code-generation",
    "type": "RECOMMENDED",
    "visibleInFilter": true,
    "sortOrder": 10,
    "translations": [
      { "locale": "en", "displayName": "Code Generation" },
      { "locale": "zh", "displayName": "Code Generation" }
    ],
    "createdAt": "2026-03-20T10:00:00Z"
  }
]
```
No pagination; the number of system labels is limited (recommended upper limit of 100 label_definitions).

#### Create Label Definition
```
POST /api/v1/admin/labels
```
```json
{
  "slug": "code-generation",
  "type": "RECOMMENDED",
  "visibleInFilter": true,
  "sortOrder": 10,
  "translations": [
    { "locale": "en", "displayName": "Code Generation" },
    { "locale": "zh", "displayName": "Code Generation" }
  ]
}
```

#### Update Label Definition
```
PUT /api/v1/admin/labels/{slug}
```
Body does not include the slug field (slug is immutable, determined by the path parameter):
```json
{
  "type": "RECOMMENDED",
  "visibleInFilter": true,
  "sortOrder": 10,
  "translations": [
    { "locale": "en", "displayName": "Code Generation" },
    { "locale": "zh", "displayName": "Code Generation" }
  ]
}
```
Translations use a full-replacement strategy: the translations list in the request completely replaces existing translations. If a translation for a language is removed, an asynchronous search document rebuild is triggered for associated skills.

#### Delete Label Definition
```
DELETE /api/v1/admin/labels/{slug}
```
Hard delete. Cascades to delete associated translations and skill_label records, triggering an asynchronous search document rebuild. The delete operation is recorded in audit_log.

#### Batch Update Sort Order
```
PUT /api/v1/admin/labels/sort-order
```
```json
{
  "items": [
    { "slug": "code-generation", "sortOrder": 1 },
    { "slug": "official", "sortOrder": 2 }
  ]
}
```

### 5.2 Skill Label Management API

Routing convention:
- To maintain consistency with the existing skill read interface style, skill detail read-type label APIs are exposed via dual routes: `/api/v1/...` and `/api/web/...`
- Admin backend label definition APIs continue to be exposed only at `/api/v1/admin/...`
- The public labels list API needed by the search page is exposed at both `/api/v1/labels` and `/api/web/labels` in Phase 1; the frontend defaults to using `/api/web/labels`

#### Get All Labels for a Skill
```
GET /api/v1/skills/{namespace}/{slug}/labels
GET /api/web/skills/{namespace}/{slug}/labels
```
Response `data`:
```json
[
  {
    "slug": "code-generation",
    "type": "RECOMMENDED",
    "displayName": "Code Generation"
  },
  {
    "slug": "official",
    "type": "PRIVILEGED",
    "displayName": "Official Recommendation"
  }
]
```
`displayName` is returned based on the request language; fallback order: current language → en → slug.

DTO conventions:
- Phase 1 uniformly returns `slug`, `type`, `displayName`
- If visual style differentiation is needed later, the frontend can determine this based on `type`

#### Assign Label
```
PUT /api/v1/skills/{namespace}/{slug}/labels/{labelSlug}
PUT /api/web/skills/{namespace}/{slug}/labels/{labelSlug}
```
Permission check: RECOMMENDED → owner / namespace admin / super admin; PRIVILEGED → super admin only.

#### Remove Label
```
DELETE /api/v1/skills/{namespace}/{slug}/labels/{labelSlug}
DELETE /api/web/skills/{namespace}/{slug}/labels/{labelSlug}
```
Permission check same as assignment.

### 5.3 Public Query API

#### Get Available Label List (Search Page Category Section)
```
GET /api/v1/labels
GET /api/web/labels
```
Returns labels with `visible_in_filter=true` and `type='RECOMMENDED'`, sorted by `sort_order`. `PRIVILEGED` labels do not appear in the search page category filter in Phase 1, to avoid confusion between operational/privileged labels and functional categories. Response `data`:
```json
[
  {
    "slug": "code-generation",
    "type": "RECOMMENDED",
    "displayName": "Code Generation"
  }
]
```
`displayName` is returned based on the request language; fallback order: current language → en → slug. No pagination.

## 6. ClawHub Compatibility Layer

The ClawHub CLI compatibility layer's search interface `GET /api/v1/search` does not support label filtering in Phase 1. The ClawHub protocol has no concept of labels, so no compatibility is needed.

## 7. Frontend Design

### 7.1 Search Page

- Add a category section below the search box, displaying the label list horizontally (data from `GET /api/v1/labels`)
- Each label displays the display_name in the current language; fallback order: current language → en → slug
- Clicking a label highlights it as selected, and the search request appends the `label` parameter; clicking again deselects it
- Labels are mutually exclusive (single selection): clicking another label switches the selection; combined filtering is not supported
- Selected state is synced via URL query parameter, supporting shareable links

### 7.2 Skill Detail Page

- Display all labels for the skill as chips/badges in the skill information area
- Privileged labels use a different visual style (different color or icon)
- Users with permission (owner / namespace admin / super admin) see an edit entry point
- Edit interaction: a popup panel; super admins can check/uncheck from all label definitions; owners / namespace admins can only operate search-visible RECOMMENDED labels
- The privileged labels area is only visible and operable by super admins

Additional notes:
- This capability cannot be completed simply by adding an independent label API; the skill detail DTO / OpenAPI / frontend types / detail page query chain all need to add the labels field
- It is recommended that the skill detail first screen directly return labels, to avoid an extra label query on the detail page causing fragmented display and permission state
- Phase 1 only requires `SkillDetailResponse` to add `labels: List<SkillLabelDto>`; `SkillSummaryResponse` does not add labels for now, keeping changes to search results and list cards minimal
- `SkillLabelDto` fields are fixed as `slug`, `type`, `displayName`

### 7.3 Admin Backend

- Label management page: list all label definitions with support for drag-and-drop ordering
- Create/edit label: form includes slug (entered at creation, immutable), type selection, visible_in_filter toggle, and dynamic translation entries (any number of language translations can be added)
- Deleting a label requires secondary confirmation, with a prompt that it will affect associated skills

## 8. Testing

Phase 1 must add at least the following tests:
- `PostgresSearchRebuildService`: verify the combined result of existing keywords sources and label translations
- `PostgresSearchRebuildService`: verify that after a label is deleted or a translation is modified, the old label text does not remain
- `PostgresFullTextQueryService`: verify that `labelSlugs` filter SQL takes effect, and that the count query is also updated
- `SkillSearchController` / `SkillSearchAppService`: verify `label` parameter forwarding
- Promotion-related tests: verify that the source skill and target skill labels are independent and no implicit copying occurs

## 9. Audit

The following actions must be recorded in `audit_log` for backend tracking:
- `LABEL_CREATE`
- `LABEL_UPDATE`
- `LABEL_DELETE`
- `LABEL_SORT_ORDER_UPDATE`
- `SKILL_LABEL_ATTACH`
- `SKILL_LABEL_DETACH`
