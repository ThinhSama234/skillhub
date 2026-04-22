# skillhub Product Direction & MVP Scope

## 1. Positioning

A single-instance shared skill registry (Skills Hub / Registry), not a multi-tenant platform.

- The platform has only one shared registry instance
- The isolation boundary is the namespace, not the tenant
- `@global` is the platform-level public space, managed by platform administrators
- `@team-*` is a collaboration and governance boundary (department/team), not a tenant boundary
- Public skills (visibility=PUBLIC) can be browsed and downloaded anonymously

ClawHub is used as the product reference (inheriting the product model, not copying the technical implementation), and OpenSkills is referenced for its SKILL.md format and directory structure conventions (without compatibility with its client runtime behavior).

Additionally, the first phase must provide a ClawHub CLI protocol compatibility layer: the server must expose a set of registry APIs compatible with the ClawHub CLI, enabling existing ClawHub CLI clients to perform core registry operations—search, resolve, download, publish, and validate—without modification or with only minimal configuration changes.

## 1.2 Identity Primary Key Constraints (Frozen)

- The user identity primary key must use `string` throughout the entire system; `int` / `long` / `bigint` must not be used as the formal contract type for platform user identifiers.
- This constraint covers all user-related fields: authentication principal, API input/output parameters, permission evaluation, audit logs, resource owner, creator, updater, reviewer, actor, submittedBy, and all equivalent fields.
- Rationale: The platform must be compatible with external SSO / OAuth / OIDC / SCIM identity providers. External UIDs are typically stable strings and should not be compressed into local auto-increment integers to be propagated as system primary keys.
- Any "integer user identifier" found in older draft documents is now invalid. The only current valid constraint is: "platform user identifiers use string primary keys throughout the entire system."

### 1.1 Skill Coordinate System (Frozen)

skillhub uses a namespace coordinate model internally: `@{namespace_slug}/{skill_slug}`.

The ClawHub CLI uses a single-slug model where the slug validation rule is `[a-z0-9]([a-z0-9-]*[a-z0-9])?`, and `/` is not permitted.

To satisfy both models simultaneously, the following bidirectional mapping rules are defined:

**Mapping Rules:**

| skillhub Coordinate | Compatibility Layer Canonical Slug | Description |
|---|---|---|
| `@global/my-skill` | `my-skill` | Global namespace omits the prefix; skill slug is used directly |
| `@team-name/my-skill` | `team-name--my-skill` | Team namespace uses the `{namespace_slug}--{skill_slug}` format |

**Constraint Rules:**
- The separator is a double hyphen `--`
- Both skill slugs and namespace slugs must not contain `--` (this restriction is added to the validation rules)
- The slug format validation is updated to: `[a-z0-9]([a-z0-9-]*[a-z0-9])?`, and must not contain two or more consecutive hyphens `--`
- When the compatibility layer parses a canonical slug: if it contains `--`, it is split into `namespace_slug` + `skill_slug`; otherwise, it is treated as `@global/{slug}`
- Conflict rule: if `@global/team-name--my-skill` conflicts with `@team-name/my-skill`, the `--` split takes priority (i.e., it is parsed as a team namespace skill first). Global namespace skill slugs must not contain `--` to avoid ambiguity
- Reserved word rule: the namespace slug reserved word list also applies to the namespace portion of a canonical slug

**Display Rules:**
- The web UI always displays the full coordinate: `@global/my-skill`, `@team-name/my-skill`
- The ClawHub CLI compatibility layer returns canonical slugs: `my-skill`, `team-name--my-skill`
- The skillhub native CLI supports both formats as input; internally they are uniformly converted to namespace coordinates

**Well-known Discovery:**
- The skillhub server provides `/.well-known/clawhub.json`, returning `{ "apiBase": "/api/v1" }`
- The ClawHub CLI uses this mechanism to automatically discover the base address of the compatibility layer API

## 2. Reference Project Trade-offs

### 2.1 What is Inherited from ClawHub

- Overall product boundary of the Skill Registry
- Business model for skill versions, tags, and downloads
- Post-publish governance mechanisms (reporting, flagging, hiding, withdrawal)
- Feature breakdown for web browsing, detail pages, upload/publish, and admin console
- Dual-channel design for public query API and CLI API
- Registry API protocol surface on which the ClawHub CLI depends
- Skill metadata extraction and server-side validation approach
- Extension points for audit, favorites, ratings, statistics, and operational tags

Not directly inherited:
- Convex data model and runtime
- Phase 1 implementation of vector search

### 2.2 What is Borrowed from OpenSkills

- `SKILL.md` format compatibility (frontmatter + markdown body)
- Skill package directory structure conventions (SKILL.md + references/ + scripts/ + assets/)
- Four-level directory priority (`.agent/skills` → `~/.agent/skills` → `.claude/skills` → `~/.claude/skills`)
- Directory name as lookup key (after installation, directory name = skill slug)
- AGENTS.md `<skill>` description block format compatibility
- Goal: skills installed by the skillhub CLI can be discovered and used by OpenSkills/Claude-compatible clients

Not directly inherited:
- CLI-centric product positioning
- "No server" premise

## 3. Product Principles

- Hub First: the server is the core; CLI and agent integration are entry-point capabilities
- Compatibility First: compatible with `SKILL.md` and common directory conventions
- CLI Compatibility First: in addition to the skillhub CLI, the first phase explicitly requires a ClawHub CLI protocol compatibility layer
- Layered First: both search and object storage must have replaceable boundaries
- Open Authentication: based on standard OAuth2 protocol; Phase 1 uses GitHub login, with architecture supporting future extension to multiple providers
- Audit First: enterprise internal distribution platforms must retain audit trails for publish, download, delete, and authorization operations

## 4. Phase 1 MVP Features

Core capabilities:
- Skill publishing (current version uses "submit → review → publish"; `SUPER_ADMIN` retains direct-publish capability)
- Skill version management (semver + tags)
- Skill browsing, detail pages, and downloads (public skills accessible anonymously)
- Tag management (`latest` is a system-reserved read-only tag + custom tags maintained manually)
- Skill package file validation and SKILL.md metadata extraction
- Search based on PostgreSQL full-text indexing

Namespaces and organization:
- Single global namespace (`@global/skill-name`), managed by platform administrators; multiple platform-level namespaces are not supported
- Team/department namespaces (`@team-slug/skill-name`)
- Namespace member management
- Selecting the owning namespace when creating a skill

Review workflow:
- Current version: ordinary users submit for review; the skill goes live after approval
- `SUPER_ADMIN` publishing goes directly to `PUBLISHED`
- Tiered review: team namespaces are reviewed by team administrators; the global namespace is reviewed by platform administrators
- Promoting a team skill to global requires a secondary review by the platform administrator
- Platform administrators are responsible only for global namespace review and promotion review; they do not intervene in team namespace review
- Automated review is not introduced in the current version; `PrePublishValidator` is retained only as a future extension point, with the default implementation being `NoOp`
- The semantics of withdrawing a review are unified as `PENDING_REVIEW → DRAFT`; this no longer involves deleting version records
- The skill lifecycle read model is unified as `headlineVersion / publishedVersion / ownerPreviewVersion / resolutionMode`
- `hidden` is an independent governance override layer and is not part of the skill container state machine

Authentication and permissions:
- OAuth2 standard login (Phase 1: GitHub OAuth)
- CLI authentication uses OAuth Device Flow; after authorization via the web, credentials usable by the CLI are issued
- API Tokens are retained as a general-purpose platform credential capability for automation, the compatibility layer, and future extensions
- ClawHub CLI protocol compatibility layer (Phase 1 focuses on core endpoints: search, resolve, download, publish, whoami, etc.)
- RBAC role permission system (platform roles: SUPER_ADMIN / SKILL_ADMIN / USER_ADMIN / AUDITOR + namespace roles)
- Admin console: user role management, publish review

Social features:
- Favorites (star)
- Ratings (1–5 stars)

Audit:
- Audit of key operations: publishing, review, download, deletion, etc.

## 5. Explicitly Out of Scope for Phase 1 (with Future Planning)

- Comments → Phase 5 launch, including a reporting mechanism
- Automated security scanning → Phase 5 launch, integrating with the `PrePublishValidator` extension point
- Reporting/flagging mechanism → Phase 5 launch, paired with comments and governance loop
- Vector search → currently entering the Phase 1 planning stage; only as a search enhancement, no recommendation system
- Online editor → not currently planned
- Webhook/event notifications → Phase 5 (extension point reserved)
- Skill dependency/compatibility declarations → not currently planned (the `parsed_metadata_json` field is reserved)

### Notes on `latest` Semantics

This is an intentional product decision, not inherited from ClawHub's rollback model:

- `latest` automatically follows the most recently published version; it is read-only and cannot be moved manually
- Rollback and stable channel management are handled through custom tags (e.g., `stable`, `beta`, `stable-2026q1`)
- ClawHub's ability to "rollback by moving latest" is replaced by "channel management through custom tags"

## 6. Phase 1 Core Constraints

- Skill packages are treated as "text resource packages"; large binary files are not accepted
- The main entry file of a skill package is fixed as `SKILL.md`
- Metadata uses the `SKILL.md` frontmatter as the primary source; parsed results are persisted in the database
- File content is stored as-is in object storage; retrieval targets derived fields and indexable text stored in the database
- Web authentication, CLI Device Flow, and API Token credentials are all unified into the platform user system
- Public skills (visibility=PUBLIC) can be browsed and downloaded anonymously without login
