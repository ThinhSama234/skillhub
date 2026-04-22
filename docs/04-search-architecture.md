# skillhub Search Architecture

## 1 SPI Interfaces

```java
public interface SearchIndexService {
    void index(SkillSearchDocument doc);
    void batchIndex(List<SkillSearchDocument> docs);
    void remove(Long skillId);
}

public interface SearchQueryService {
    SearchResult search(SearchQuery query);
}

public interface SearchRebuildService {
    void rebuildAll();
    void rebuildByNamespace(Long namespaceId);
    void rebuildBySkill(Long skillId);
}
```

## 2 SearchQuery Model

```java
public record SearchQuery(
    String keyword,
    Long namespaceId,           // Optional; search within a specific namespace
    String namespaceSlug,       // Optional
    SearchVisibilityScope scope, // ACL projection; computed and injected by the application service layer
    SortField sortBy,           // RELEVANCE / DOWNLOADS / RATING / NEWEST
    int page,
    int size
) {}

// Search visibility scope projection; computed by the application service layer based on the current user
public record SearchVisibilityScope(
    boolean includeAllPublic,        // Whether to include all PUBLIC skills
    Set<Long> memberNamespaceIds,    // Namespaces where the user is a MEMBER (can see NAMESPACE_ONLY)
    Set<Long> adminNamespaceIds,     // Namespaces where the user is an ADMIN (can see PRIVATE)
    String userId                    // Current user ID (can see their own PRIVATE skills); null for anonymous
) {}
```

ACL projection computation rules:
- Anonymous users: `includeAllPublic=true`, other sets are empty, `userId=null`
- Authenticated users: `includeAllPublic=true`, `memberNamespaceIds` = namespaces the user belongs to, `adminNamespaceIds` = namespaces where the user is at least ADMIN, `userId` = current user ID

In the Phase 1 PostgreSQL implementation, `SearchVisibilityScope` is translated into a WHERE clause:
```sql
WHERE (visibility = 'PUBLIC')
   OR (visibility = 'NAMESPACE_ONLY' AND namespace_id IN (:memberNamespaceIds))
   OR (visibility = 'PRIVATE' AND (namespace_id IN (:adminNamespaceIds) OR owner_id = :userId))
```

When migrating to ES, `SearchVisibilityScope` can be directly mapped to should/filter sub-clauses of a bool query.

## 3 Search Document Table skill_search_document

One search document per skill, but the semantic source of the document content must be strictly converged to "the current most recently published version." The implementation may still use `latest_version_id` as a cache pointer, but it is only allowed to point to a `PUBLISHED` version; the search layer must not treat it as a generalized "current version."

| Field | Type | Description |
|------|------|------|
| id | bigint | |
| skill_id | bigint | Unique; one record per skill |
| namespace_id | bigint | Used for namespace filtering |
| owner_id | VARCHAR(128) | Used for PRIVATE visibility evaluation |
| title | varchar(256) | |
| summary | varchar(512) | |
| keywords | varchar(512) | |
| search_text | text | `displayName`, `slug`, `summary`, and the expanded result of frontmatter fields excluding `name` / `description` / `version` |
| visibility | enum | Denormalized to avoid joins during search |
| status | enum | |
| updated_at | datetime | |

Unique constraint: `(skill_id)`

PostgreSQL full-text search index: add a `search_vector tsvector` generated column to the table, automatically maintained based on `title`, `summary`, `keywords`, and `search_text`, with a GIN index created. See Section 7 for details.

## 4 Index Write Triggers

The following scenarios trigger a search document update (upsert by skill_id):
- Review approved (`PENDING_REVIEW → PUBLISHED`): recalculate the "most recently published version" pointer and update the search document with the content of that published version
- Published version retracted (`PUBLISHED → YANKED`): recalculate the "most recently published version" pointer; if no published version exists, remove the search document
- Skill status changed (hidden/archived/restored): update the status field in the search document

## 5 Search Evolution Roadmap

### 5.1 Phase 1 Data Modeling Constraints

The Phase 1 design of "one search document per skill, content always from the most recently published version" is an intentional simplification. The current implementation still uses `latest_version_id` as a persistence pointer, but its semantics here have converged to a latest published pointer. This model will be insufficient in the following scenarios:

- Version-level retrieval (searching the content of an old version)
- Custom tag/channel retrieval (searching the content pointed to by the `@beta` tag)
- Vector chunk indexing (a SKILL.md from one skill is split into multiple embedding chunks)

These scenarios cannot be solved by simply swapping the provider; they require changes to the table structure and index write logic.

**Phase 1 search capability boundary (product limitations):**
- Search is based only on the content of the "most recently published version"
- Searching content by version or tag is not supported
- Search results do not differentiate by channel (`beta`, `stable`, etc.)
- The skill content seen when installing via a tag may differ from the content shown in search results (search shows latest; installation uses the version pointed to by the tag)
- Supporting channel-aware search requires upgrading to version-level indexing (Phase 2 ES implementation)

### 5.2 Evolution Stages

| Stage | Implementation | Index Granularity | Switch Method |
|------|------|---------|---------|
| Phase 1 | PostgreSQL Full-Text (tsvector + GIN) | One record per skill (latest published) | Default |
| Phase 1.5 | PostgreSQL Full-Text + semantic vector re-ranking | One record per skill (latest published) | Configure `skillhub.search.semantic.enabled=true` |
| Phase 2 | ES / OpenSearch | One record per skill_version + skill aggregate document | Configure `search.provider=elasticsearch` |
| Phase 3 | Vector search | Multiple records per skill_version (chunk-level) | Configure `search.provider=vector` |
| Phase 4 | Hybrid ranking | Keyword + vector hybrid | Configure `search.provider=hybrid` |

The current code implementation is at "Phase 1.5":
- Still uses PostgreSQL full-text search as the primary recall layer
- The search document table adds a `semantic_vector` cache field
- Under relevance sorting, semantic vector re-ranking is appended to the full-text candidate set
- When the semantic vector is unavailable, it automatically falls back to the existing full-text relevance ranking

### 5.3 SPI Evolution Strategy

The Phase 1 SPI interfaces (`SearchIndexService` / `SearchQueryService`) take `SkillSearchDocument` (skill-level granularity) as input. When switching to ES in Phase 2:

1. Add a `SkillVersionSearchDocument` model (version-level granularity)
2. `SearchIndexService` adds an `indexVersion()` method (backward-compatible; Phase 1 implementation is a no-op)
3. The ES implementation writes both skill aggregate documents and version documents simultaneously
4. The return type of `SearchQueryService.search()` is unchanged (still returns skill-level summaries); internally switches to an ES query

This means the Phase 2 switch is not zero-cost — new models, SPI extensions, and index rebuilding are required. However, Phase 1 does not over-engineer for this; the SPI abstraction ensures that no business-layer code changes are needed during the switch.

Switching is done via `@ConditionalOnProperty` or a custom SPI loading mechanism.

## 6 Distributed Safety

Obtain a Redis distributed lock before executing `rebuildAll()` / `rebuildByNamespace()` (key: `search:rebuild:{scope}`, TTL: 10 minutes); skip if the lock cannot be acquired.

## 7 PostgreSQL Full-Text Search Chinese Support

PostgreSQL full-text search uses `tsvector` + `tsquery` + GIN index:

```sql
-- Add tsvector generated column
ALTER TABLE skill_search_document
ADD COLUMN search_vector tsvector
GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(summary, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(keywords, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(search_text, '')), 'C')
) STORED;

-- Create GIN index
CREATE INDEX idx_search_vector ON skill_search_document USING GIN (search_vector);
```

Chinese language support strategy:
- Phase 1 uses the `simple` tokenization configuration (tokenizes by spaces and punctuation); Chinese support is limited but has zero dependencies
- For better Chinese tokenization, `zhparser` or `pg_jieba` extensions can be installed and their corresponding text search configuration can be used as a replacement
- PostgreSQL's `tsvector` supports weights (A/B/C/D), so `title` can be assigned a higher weight to improve search relevance

Known limitations: the `simple` tokenizer has lower precision for Chinese than a professional search engine. It is recommended to evaluate search effectiveness after Phase 2 is complete; if it does not meet requirements, introduce ES early in Phase 3.
