# SkillHub Backend Time Field Inventory

## 1. Scan Scope

This inventory is based on the current production code and Flyway migrations in `server/skillhub-app`, `server/skillhub-auth`, `server/skillhub-domain`, `server/skillhub-infra`, and `server/skillhub-storage`.

The goal has shifted from "mapping the distribution of issues" to "recording the current real progress and remaining tail items."

## 2. Current Code Distribution

### 2.1 `LocalDateTime` in Production Code Is Largely Cleared

Only 1 compatibility parsing instance of `LocalDateTime` remains in current production code:

- `ApiTokenService`
  - Used for compatibility with bare time strings passed in by legacy endpoints
  - Currently explicitly interpreted as UTC and converted to `Instant`

Main chain areas that previously used `LocalDateTime` heavily have completed migration or convergence:

- Authentication and accounts:
  - `api_token`
  - `account_merge_request`
  - `user_account`
  - `identity_binding`
  - `role`
  - `user_role_binding`
  - `local_credential`
- Core domain:
  - `namespace`
  - `namespace_member`
  - `skill`
  - `skill_version`
  - `skill_file`
  - `skill_tag`
  - `skill_version_stats`
  - `skill_report`
  - `skill_star`
  - `skill_rating`
- Service layer:
  - `AccountMergeService`
  - `LocalAuthService`
  - `SkillPublishService`
  - `SkillGovernanceService`
  - `ReviewService`
  - `PromotionService`
  - `SkillReportService`
- DTOs and API output:
  - `NamespaceResponse`
  - `MemberResponse`
  - `SkillSummaryResponse`
  - `SkillVersionResponse`
  - `SkillVersionDetailResponse`
  - `TagResponse`
  - `AdminUserSummaryResponse`
  - `AdminSkillReportSummaryResponse`

Conclusion:

- Core "event occurrence time" in the main system has been largely converged to UTC absolute time
- The remaining work is mainly compatibility policy, database tail-item review, and anti-regression constraints

### 2.2 `Instant` Has Become the Mainstream Absolute Time Type

Representative areas currently using `Instant` stably:

- Audit:
  - `AuditLog`
  - `AuditLogItemResponse`
- Notifications:
  - `UserNotification`
- Review workflow:
  - `ReviewTask`
  - `PromotionRequest`
  - `ReviewTaskResponse`
  - `PromotionResponseDto`
- Idempotency:
  - `IdempotencyRecord`
  - `IdempotencyInterceptor`
  - `IdempotencyCleanupTask`
- Skill main chain:
  - `Skill`
  - `SkillVersion`
  - `SkillTag`
  - `SkillFile`
  - `SkillVersionStats`
- Authentication main chain:
  - `ApiToken`
  - `AccountMergeRequest`
  - `UserAccount`
  - `IdentityBinding`
  - `Role`
  - `UserRoleBinding`
  - `LocalCredential`

## 3. Database Layer Distribution

### 3.1 Completed `TIMESTAMPTZ` Migrations

- `V12__governance_notifications.sql`
  - `user_notification.created_at / read_at`
- `V24__api_token_timestamptz.sql`
  - `api_token.expires_at / last_used_at / revoked_at / created_at`
- `V25__account_merge_request_timestamptz.sql`
  - `account_merge_request.token_expires_at / completed_at / created_at`
- `V26__skill_version_timestamptz.sql`
  - `skill_version.published_at / created_at / yanked_at`
- `V16__skill_hidden_at_timestamptz.sql`
  - `skill.hidden_at`
- `V17__skill_created_updated_timestamptz.sql`
  - `skill.created_at / updated_at`
- `V18__namespace_timestamptz.sql`
  - `namespace.created_at / updated_at`
  - `namespace_member.created_at / updated_at`
- `V19__skill_secondary_timestamptz.sql`
  - `skill_tag.created_at / updated_at`
  - `skill_file.created_at`
  - `skill_version_stats.updated_at`
- `V20__social_and_skill_report_timestamptz.sql`
  - `skill_star.created_at`
  - `skill_rating.created_at / updated_at`
  - `skill_report.created_at / handled_at`
- `V21__user_account_timestamptz.sql`
  - `user_account.created_at / updated_at`
- `V22__auth_supporting_tables_timestamptz.sql`
  - `identity_binding.created_at / updated_at`
  - `role.created_at`
  - `user_role_binding.created_at`
  - `local_credential.locked_until / created_at / updated_at`
- `V23__review_and_idempotency_timestamptz.sql`
  - `review_task.submitted_at / reviewed_at`
  - `promotion_request.submitted_at / reviewed_at`
  - `idempotency_record.created_at / expires_at`

### 3.2 Current Status

- Main chain core event time columns have largely completed `TIMESTAMPTZ` convergence
- Initial table-creation migrations still show old `TIMESTAMP` definitions, but these have been covered by subsequent Flyway upgrades
- The next focus is not "large-scale migration" but gap-filling and adding new constraints

## 4. Resolved High-Risk Hotspots

### 4.1 Compatibility Layer Timezone Interpretation Conflict

Previously:

- `ClawHubCompatController` converted epoch using `ZoneOffset.UTC`
- `ClawHubRegistryFacade` interpreted using the system default timezone

Currently:

- All absolute times are uniformly interpreted as UTC
- The `LocalDateTime` epoch conversion overload in `ClawHubRegistryFacade` has been removed

### 4.2 Scattered `now()` Calls in the Service Layer

Previous hotspots included:

- `ApiTokenService`
- `AccountMergeService`
- `LocalAuthService`
- `SkillPublishService`
- `SkillGovernanceService`
- `ReviewService`
- `PromotionService`
- `SkillReportService`
- Multiple entity `@PrePersist` / `@PreUpdate` callbacks

Currently:

- Service-layer current time has been largely unified to use an injected `Clock`
- Entity callbacks have been largely unified to use explicit UTC

## 5. Batch Migration Progress

### Batch 1: Infrastructure and Governance Chain

Completed:

- UTC `Clock` bean
- Hibernate UTC configuration
- Jackson UTC configuration
- `ApiResponseFactory`
- `IdempotencyInterceptor`
- `IdempotencyCleanupTask`
- Audit, notification, review, and idempotency chains

### Batch 2: Authentication and Account Chain

Completed:

- `ApiToken` / `ApiTokenService`
- `AccountMergeRequest` / `AccountMergeService`
- `LocalCredential`
- `UserAccount`
- `IdentityBinding`
- `Role`
- `UserRoleBinding`
- `LocalAuthService`

### Batch 3: Skill Core Domain

Completed:

- `Skill`
- `SkillVersion`
- `SkillFile`
- `SkillTag`
- `SkillVersionStats`
- `Namespace`
- `NamespaceMember`
- `SkillPublishService`
- `SkillGovernanceService`
- `ReviewService`
- `PromotionService`
- `SkillReport`
- `SkillStar`
- `SkillRating`

### Batch 4: DTO and API Contract Convergence

Completed:

- `NamespaceResponse`
- `MemberResponse`
- `SkillSummaryResponse`
- `SkillVersionResponse`
- `SkillVersionDetailResponse`
- `TagResponse`
- `AdminUserSummaryResponse`
- `AdminSkillReportSummaryResponse`
- UTC output convergence in `TokenController`

## 6. Current Remaining Tail Items

- `ApiTokenService` still retains compatibility parsing for bare `LocalDateTime` strings
- Static scan or ArchUnit constraints need to be added to prevent new `LocalDateTime.now()` calls
- A cross-timezone regression pass needs to be done, incorporating `UTC` / `Asia/Shanghai` into key tests
