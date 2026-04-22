# SkillHub Backend Date-Time Governance Plan

## 1. Current Conclusions

The main system has largely completed converging on UTC semantics:

- Most core business time fields have been migrated to `Instant`
- Most core event time columns have been migrated to `TIMESTAMPTZ`
- Most service-layer "current time" calls have been unified to use an injected `Clock`
- Absolute times in ordinary APIs and admin DTOs have been largely unified to output UTC ISO-8601

What the system currently retains is not a wide mixture but a small number of compatibility tail items. The remaining risks are primarily:

- A few legacy endpoints still allow timezone-free string input
- If new code reintroduces `LocalDateTime.now()`, it may pull the system back to a default-timezone dependency
- Without cross-timezone automated regression, boundary issues may still be missed

## 2. Goals

The governance goal is not "use only one type everywhere" but to unify time semantics:

- Absolute points in time: use UTC semantics uniformly; Java uses `Instant`
- Business-input local time: `LocalDateTime` is allowed only when requirements explicitly call for "local calendar time"
- When storing absolute points in time in the database, use `TIMESTAMPTZ` uniformly
- When returning absolute points in time in external APIs, output ISO-8601 UTC strings uniformly, for example `2026-03-18T06:30:00Z`
- Stop propagating timezone-semantics-free `LocalDateTime` further into the domain layer

A clear distinction must be made here:

- i18n addresses language, text, and localized display
- Unifying time to UTC addresses cross-timezone consistency

## 3. Target Model

It is recommended to manage backend time fields in three categories:

### 3.1 System Event Times

Applicable fields:

- `createdAt`
- `updatedAt`
- `publishedAt`
- `submittedAt`
- `reviewedAt`
- `hiddenAt`
- `yankedAt`
- `lastUsedAt`
- `revokedAt`
- `readAt`
- `handledAt`
- `tokenExpiresAt`

Constraints:

- Java type is uniformly `Instant`
- Database column is uniformly `TIMESTAMPTZ`
- All reads and writes are treated as UTC absolute times

### 3.2 Business-Input Times

Applicable scenarios:

- A user manually inputs a "deadline by a certain date and time" field
- A rule is explicitly bound to a specific business timezone rather than the system timezone

Constraints:

- If the time represents a real absolute moment, the entry point should require a timezone or a declared timezone source, then immediately convert to `Instant` in the service layer
- It is not allowed to long-term store a bare `yyyy-MM-ddTHH:mm:ss` user input in core domain models

### 3.3 Pure Date Fields

Applicable scenarios:

- Date of birth
- Billing period
- Settlement date
- Natural-day statistics

Constraints:

- Use `LocalDate`
- Not involved in UTC/timezone conversion

## 4. Current State of Issues

### 4.1 Historical Issues Are Largely Resolved

The main historical issues in the system included:

- Heavy use of `LocalDateTime` in the domain layer
- Scattered `LocalDateTime.now()` calls in the service layer
- Heavy use of `TIMESTAMP` in database DDL
- Implicit UTC assumptions and conflicting interpretations in the compatibility layer

These issues have been largely governed in the main chain code. They are documented primarily to explain why the migration order must start with infrastructure, then domain models, then the database.

### 4.2 Issues That Still Exist Today

- `ApiTokenService` still accepts bare time strings for compatibility
- No static constraints have been established to prevent future reintroduction of `LocalDateTime.now()`
- No systematic cross-timezone regression baseline has been established

## 5. Governance Principles

- Unify new code first, then migrate existing code
- Unify domain models first, then migrate the database, then converge APIs
- All "current time" retrieval must be uniformly injected via `Clock`; scattered `now()` calls are prohibited
- During migration, prioritize API compatibility to avoid breaking the frontend and CLI simultaneously
- Expose only time formats with explicit semantics externally; do not expose a gray state that is "timezone-free but assumed to be UTC"

## 6. Phased Plan

### Phase 0: Baseline Audit

Deliverables:

- Complete inventory of time fields
- Inventory of `LocalDateTime` / `Instant` / `LocalDate` usage
- Inventory of `TIMESTAMP` / `TIMESTAMPTZ` columns
- Inventory of time fields in API requests and responses
- Inventory of all epoch conversion points in the compatibility layer

Current status:

- Initial inventory completed
- Synchronized with current real code progress

### Phase 1: Unified Standards and Infrastructure

Actions:

- Add a global UTC `Clock`
- Configure Hibernate JDBC timezone to UTC
- Configure Jackson UTC output
- Establish "use `Instant` for absolute times" standard

Current status:

- Complete

### Phase 2: Code-Layer Migration to `Instant`

Actions:

- Change entity fields to `Instant`
- Change `LocalDateTime.now()` to `Instant.now(clock)`
- Unify comparison logic to `Instant`
- Migrate DTOs and services in tandem

Current status:

- Main chain is largely complete
- Only a very small number of compatibility parsing code paths in production code still retain `LocalDateTime`

### Phase 3: Database Migration to `TIMESTAMPTZ`

Actions:

- Add Flyway migrations for core tables
- Explicitly interpret historical `TIMESTAMP` data as UTC

Current status:

- Main chain core event time columns are largely complete
- Migrations `V13` through `V23` have been applied

### Phase 4: API Contract Convergence

Actions:

- Unify all absolute time fields in ordinary JSON APIs to output UTC strings
- Prohibit endpoints from returning bare `LocalDateTime.toString()`
- Gradually retire timezone-free input

Current status:

- Ordinary APIs and admin DTOs have largely completed UTC output convergence
- The remaining compatibility focus is the policy for handling bare time string input in legacy endpoints

### Phase 5: Cleanup and Hard Constraints

Actions:

- Clean up residual compatibility timezone assumptions
- Add ArchUnit or static scan rules
- Add cross-timezone tests, for example `UTC` and `Asia/Shanghai`

Current status:

- Not yet complete
- This is the most valuable work for the next phase

## 7. Key Technical Decisions

### 7.1 Why Use `Clock` Instead of Just `Instant.now()`

- `Instant` solves "how time is expressed"
- `Clock` solves "where the current time comes from"
- The recommended combination is `Instant.now(clock)`

This makes the service layer testable, allows time to be fixed, and avoids interference from the machine's local timezone.

### 7.2 Whether to Uniformly Introduce `OffsetDateTime`

This project is better suited to use `Instant` as the core absolute time type, for the following reasons:

- Most fields express the moment an event occurred
- The business side usually does not need to retain the original offset
- `Instant` is better at preventing the misunderstanding of "looks like local time"

`OffsetDateTime` should only be considered in scenarios where the caller's original offset must be retained.

### 7.3 How to Handle User-Input Fields Like `expiresAt`

Long-term goal:

- API contract requires input as RFC 3339 / ISO-8601 time with timezone
- After parsing in the service layer, immediately convert to `Instant`

Short-term compatibility:

- Legacy endpoints that still accept bare strings should centralize the fallback handling at the controller or service boundary
- This must be explicitly documented as compatibility logic, not a long-term contract

## 8. Risks and Mitigations

| Risk | Mitigation |
|------|------|
| Historical `TIMESTAMP` data semantics are inconsistent | Sample and profile the data first; migrate in batches if needed |
| Frontend or CLI already depends on the old timezone-free format | Retain short-term compatibility parsing while declaring a clear deprecation plan |
| New code continues to introduce `LocalDateTime.now()` | Add static scan and review rules to block it |
| Missing cross-timezone regression causes boundary issues to go undetected | Add a `UTC` / `Asia/Shanghai` dual-timezone test matrix |

## 9. Recommended Follow-Up Order

1. Add static constraints for `LocalDateTime.now()` and entity-layer `LocalDateTime`
2. Add cross-timezone regression tests
3. Review and gradually retire bare time string input compatibility
4. Perform a sampling verification of production historical data to confirm that all `TIMESTAMPTZ` migrations comply with the UTC interpretation assumption
