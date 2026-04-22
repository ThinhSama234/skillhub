# Phase 4: Operations Enhancement + Polish + Open-Source Ready Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the authentication system (local password login + multi-account merge), improve governance (skill hide/revoke + audit log query), enhance observability (Prometheus), optimize performance (indexes + presigned URLs + frontend code splitting), strengthen security, implement Docker one-click startup and K8s deployment, and establish open-source project infrastructure.

**Architecture:** Backend continues with the Spring Boot 3.x layered architecture (skillhub-auth / skillhub-domain / skillhub-app / skillhub-infra / skillhub-storage / skillhub-search); frontend continues with React 19 + TanStack Router + TanStack Query. Local auth is added independently of the OAuth system, using the existence of the `local_credential` table row to determine the auth source. 4 Chunks delivered progressively.

**Identity Primary Key Constraint:** User identity primary keys use `string` end-to-end. All `userId`, `primaryUserId`, `secondaryUserId`, `hiddenBy`, `yankedBy`, `actorUserId` and similar user identifier fields in this plan are implemented as strings; historical `Long` / `BIGINT` descriptions are no longer valid.

**Tech Stack:** Java 21, Spring Boot 3.2, Spring Security, Spring Data JPA, Flyway, PostgreSQL 16, Redis 7, BCrypt, Micrometer/Prometheus, React 19, TypeScript, Vite, TanStack Router/Query, shadcn/ui, Docker, Kubernetes

**Spec:** `docs/superpowers/specs/2026-03-12-phase4-ops-polish-design.md`

---

## File Structure

### Chunk 1: Local Auth + Multi-Account Merge

**New files (backend):**
- `server/skillhub-app/src/main/resources/db/migration/V4__phase4_auth_governance.sql` — Flyway migration
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredential.java` — Local credential entity
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredentialRepository.java` — Credential repository interface
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidator.java` — Password policy validator
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalAuthService.java` — Local auth service
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequest.java` — Merge request entity
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequestRepository.java` — Merge repository interface
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeService.java` — Merge service
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/LocalAuthController.java` — Local auth Controller
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/AccountMergeController.java` — Merge Controller
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalRegisterRequest.java` — Registration request DTO
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalLoginRequest.java` — Login request DTO
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/ChangePasswordRequest.java` — Change password DTO
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeInitiateRequest.java` — Initiate merge DTO
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeVerifyRequest.java` — Verify merge DTO
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/config/SeedDataRunner.java` — Seed data initialization
- `server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/LocalCredentialJpaRepository.java` — JPA 实现
- `server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/AccountMergeRequestJpaRepository.java` — JPA 实现

**New files (backend tests):**
- `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidatorTest.java`
- `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/LocalAuthServiceTest.java`
- `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/merge/AccountMergeServiceTest.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/LocalAuthControllerTest.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/AccountMergeControllerTest.java`

**Modified files (backend):**
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/config/SecurityConfig.java` — Add local auth endpoints to permitAll + BCrypt Bean
- `server/skillhub-app/src/main/resources/messages.properties` — Add i18n messages
- `server/skillhub-app/src/main/resources/messages_zh.properties` — Add Chinese messages

**New files (frontend):**
- `web/src/pages/register.tsx` — Registration page
- `web/src/pages/settings/security.tsx` — Password change page
- `web/src/pages/settings/accounts.tsx` — Account merge page
- `web/src/features/auth/use-local-auth.ts` — Local auth Hook
- `web/src/features/auth/use-account-merge.ts` — Account merge Hook

**Modified files (frontend):**
- `web/src/pages/login.tsx` — Add username/password tab
- `web/src/app/router.tsx` — Add new routes

### Chunk 2: Skill Governance + Audit Logs + Observability

**New files (backend):**
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceService.java` — Governance service
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditLog.java` — Audit log entity (if not present)
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditLogRepository.java` — Audit log repository
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditLogQueryService.java` — Audit log query service
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/admin/AdminSkillController.java` — Skill governance Controller
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/admin/AuditLogController.java` — Audit log Controller
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/config/MetricsConfig.java` — Prometheus metrics configuration

**New files (backend tests):**
- `server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceServiceTest.java`
- `server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/audit/AuditLogQueryServiceTest.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/admin/AdminSkillControllerTest.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/admin/AuditLogControllerTest.java`

**Modified files (backend):**
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/Skill.java` — Add hidden/hiddenAt/hiddenBy fields
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/SkillVersion.java` — Add yankedAt/yankedBy/yankReason fields
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/SkillVersionStatus.java` — Add YANKED enum value
- `server/skillhub-app/src/main/resources/application.yml` — Actuator + Prometheus configuration

**New files (frontend):**
- `web/src/pages/admin/audit-logs.tsx` — Audit log page
- `web/src/features/admin/use-audit-logs.ts` — Audit log Hook
- `web/src/features/skill/skill-governance-actions.tsx` — Hide/revoke action component

### Chunk 3: Performance Optimization + Security Hardening

**Modified files (backend):**
- `server/skillhub-storage/src/main/java/com/iflytek/skillhub/storage/ObjectStorageService.java` — Add generatePresignedUrl method
- `server/skillhub-storage/src/main/java/com/iflytek/skillhub/storage/S3StorageService.java` — Implement presigned URL
- `server/skillhub-storage/src/main/java/com/iflytek/skillhub/storage/LocalFileStorageService.java` — Return null (fallback)
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/portal/SkillController.java` — Download 302 redirect
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/config/SecurityConfig.java` — Security response headers
- `server/skillhub-app/src/main/resources/application.yml` — Session Cookie security configuration

**New files (backend tests):**
- `server/skillhub-storage/src/test/java/com/iflytek/skillhub/storage/S3StorageServicePresignedUrlTest.java`

**Modified files (frontend):**
- `web/src/app/router.tsx` — Lazy routes refactoring
- `web/src/features/skill/markdown-renderer.tsx` — rehype-sanitize integration

### Chunk 4: Docker One-Click Startup + K8s + Open-Source Infrastructure

**New files:**
- `Dockerfile` — Multi-stage build (root directory)
- `deploy/nginx/default.conf` — Nginx SPA configuration
- `deploy/k8s/backend-deployment.yaml`
- `deploy/k8s/frontend-deployment.yaml`
- `deploy/k8s/services.yaml`
- `deploy/k8s/ingress.yaml`
- `deploy/k8s/configmap.yaml`
- `deploy/k8s/secret.yaml.example`
- `README.md` — Project README
- `CONTRIBUTING.md` — Contributing guide
- `LICENSE` — Apache 2.0
- `CODE_OF_CONDUCT.md` — Code of conduct
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/pull_request_template.md`

**Modified files:**
- `docker-compose.yml` — Add backend/frontend services + health check

---

## Chunk 1: Local Auth + Multi-Account Merge

### Task 1.1: Flyway Migration — local_credential + account_merge_request

**Files:**
- Create: `server/skillhub-app/src/main/resources/db/migration/V4__phase4_auth_governance.sql`

- [ ] **Step 1: Write migration script**

```sql
-- V4__phase4_auth_governance.sql

-- Local password credentials
CREATE TABLE local_credential (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    username VARCHAR(64) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    failed_attempts INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX idx_local_credential_username ON local_credential(username);
CREATE UNIQUE INDEX idx_local_credential_user_id ON local_credential(user_id);

-- Account merge requests
CREATE TABLE account_merge_request (
    id BIGSERIAL PRIMARY KEY,
    primary_user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    secondary_user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    verification_token VARCHAR(255),
    token_expires_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_merge_primary_status ON account_merge_request(primary_user_id, status);
CREATE UNIQUE INDEX idx_merge_secondary_pending ON account_merge_request(secondary_user_id) WHERE status = 'PENDING';
CREATE INDEX idx_merge_token_pending ON account_merge_request(verification_token) WHERE status = 'PENDING';
```

- [ ] **Step 2: Verify migration**

Run: `cd server && mvn flyway:migrate -pl skillhub-app`
Expected: Migration successful, V4 script executed without errors

- [ ] **Step 3: Commit**

```bash
git add server/skillhub-app/src/main/resources/db/migration/V4__phase4_auth_governance.sql
git commit -m "feat(db): add V4 migration for local_credential and account_merge_request"
```

### Task 1.2: PasswordPolicyValidator — Password policy validator

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidator.java`
- Test: `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidatorTest.java`

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.auth.local;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static org.assertj.core.api.Assertions.*;

class PasswordPolicyValidatorTest {
    private final PasswordPolicyValidator validator = new PasswordPolicyValidator();

    @Test
    void validPassword_passes() {
        assertThat(validator.validate("Abcdef1!")).isEmpty();
    }

    @Test
    void tooShort_fails() {
        assertThat(validator.validate("Ab1!xyz")).isNotEmpty();
    }

    @Test
    void tooLong_fails() {
        assertThat(validator.validate("A".repeat(129))).isNotEmpty();
    }

    @Test
    void onlyOneCharType_fails() {
        assertThat(validator.validate("abcdefgh")).isNotEmpty();
    }

    @Test
    void twoCharTypes_fails() {
        assertThat(validator.validate("abcdefg1")).isNotEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {"Abcdefg1", "Abcdef1!", "abcdef1!", "ABCDEF1!"})
    void threeCharTypes_passes(String password) {
        assertThat(validator.validate(password)).isEmpty();
    }
}
```

- [ ] **Step 2: Run tests and confirm failure**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=PasswordPolicyValidatorTest -Dsurefire.failIfNoSpecifiedTests=false`
Expected: FAIL — class does not exist

- [ ] **Step 3: Implement PasswordPolicyValidator

```java
package com.iflytek.skillhub.auth.local;

import java.util.ArrayList;
import java.util.List;

public class PasswordPolicyValidator {
    private static final int MIN_LENGTH = 8;
    private static final int MAX_LENGTH = 128;
    private static final int MIN_CHAR_TYPES = 3;

    public List<String> validate(String password) {
        var errors = new ArrayList<String>();
        if (password == null || password.length() < MIN_LENGTH) {
            errors.add("password.too_short");
            return errors;
        }
        if (password.length() > MAX_LENGTH) {
            errors.add("password.too_long");
            return errors;
        }
        int types = 0;
        if (password.chars().anyMatch(Character::isUpperCase)) types++;
        if (password.chars().anyMatch(Character::isLowerCase)) types++;
        if (password.chars().anyMatch(Character::isDigit)) types++;
        if (password.chars().anyMatch(c -> !Character.isLetterOrDigit(c))) types++;
        if (types < MIN_CHAR_TYPES) {
            errors.add("password.insufficient_complexity");
        }
        return errors;
    }
}
```

- [ ] **Step 4: Run tests and confirm pass**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=PasswordPolicyValidatorTest`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidator.java \
       server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/PasswordPolicyValidatorTest.java
git commit -m "feat(auth): add PasswordPolicyValidator with TDD"
```

### Task 1.3: LocalCredential Entity + Repository

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredential.java`
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredentialRepository.java`
- Create: `server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/LocalCredentialJpaRepository.java`

- [ ] **Step 1: Create LocalCredential entity**

```java
package com.iflytek.skillhub.auth.local;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "local_credential")
public class LocalCredential {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(nullable = false, length = 64)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts = 0;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected LocalCredential() {}

    public LocalCredential(String userId, String username, String passwordHash) {
        this.userId = userId;
        this.username = username;
        this.passwordHash = passwordHash;
    }

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // Getters and setters
    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public int getFailedAttempts() { return failedAttempts; }
    public void setFailedAttempts(int failedAttempts) { this.failedAttempts = failedAttempts; }
    public LocalDateTime getLockedUntil() { return lockedUntil; }
    public void setLockedUntil(LocalDateTime lockedUntil) { this.lockedUntil = lockedUntil; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public boolean isLocked() {
        return lockedUntil != null && lockedUntil.isAfter(LocalDateTime.now());
    }

    public void recordFailedAttempt(int maxAttempts, int lockMinutes) {
        this.failedAttempts++;
        if (this.failedAttempts >= maxAttempts) {
            this.lockedUntil = LocalDateTime.now().plusMinutes(lockMinutes);
        }
    }

    public void resetFailedAttempts() {
        this.failedAttempts = 0;
        this.lockedUntil = null;
    }
}
```

- [ ] **Step 2: Create Repository interface**

```java
package com.iflytek.skillhub.auth.local;

import java.util.Optional;

public interface LocalCredentialRepository {
    Optional<LocalCredential> findByUsername(String username);
    Optional<LocalCredential> findByUserId(String userId);
    LocalCredential save(LocalCredential credential);
    boolean existsByUsername(String username);
}
```

- [ ] **Step 3: Create JPA implementation**

```java
package com.iflytek.skillhub.infra.jpa;

import com.iflytek.skillhub.auth.local.LocalCredential;
import com.iflytek.skillhub.auth.local.LocalCredentialRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface LocalCredentialJpaRepository extends JpaRepository<LocalCredential, Long>, LocalCredentialRepository {
    Optional<LocalCredential> findByUsername(String username);
    Optional<LocalCredential> findByUserId(String userId);
    boolean existsByUsername(String username);
}
```

- [ ] **Step 4: Verify compilation**

Run: `cd server && mvn compile -pl skillhub-auth,skillhub-infra`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredential.java \
       server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalCredentialRepository.java \
       server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/LocalCredentialJpaRepository.java
git commit -m "feat(auth): add LocalCredential entity and repository"
```

### Task 1.4: LocalAuthService — Register/Login/Change Password

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalAuthService.java`
- Test: `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/LocalAuthServiceTest.java`

- [ ] **Step 1: Write registration tests**

```java
package com.iflytek.skillhub.auth.local;

import com.iflytek.skillhub.domain.user.UserAccount;
import com.iflytek.skillhub.domain.user.UserAccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LocalAuthServiceTest {
    @Mock private LocalCredentialRepository credentialRepo;
    @Mock private UserAccountRepository userRepo;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(4); // Low strength to speed up tests
    private final PasswordPolicyValidator policyValidator = new PasswordPolicyValidator();
    private LocalAuthService service;

    @BeforeEach
    void setUp() {
        service = new LocalAuthService(credentialRepo, userRepo, passwordEncoder, policyValidator);
    }

    @Test
    void register_success() {
        when(credentialRepo.existsByUsername("testuser")).thenReturn(false);
        when(userRepo.save(any())).thenAnswer(inv -> {
            var u = inv.getArgument(0, UserAccount.class);
            return u; // Simulate save
        });
        when(credentialRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var result = service.register("testuser", "Test@1234", null);
        assertThat(result).isNotNull();
        verify(credentialRepo).save(argThat(c -> c.getUsername().equals("testuser")));
    }

    @Test
    void register_duplicateUsername_throws() {
        when(credentialRepo.existsByUsername("taken")).thenReturn(true);
        assertThatThrownBy(() -> service.register("taken", "Test@1234", null))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void register_weakPassword_throws() {
        assertThatThrownBy(() -> service.register("user", "weak", null))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
```

- [ ] **Step 2: Run tests and confirm failure**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=LocalAuthServiceTest`
Expected: FAIL — LocalAuthService does not exist

- [ ] **Step 3: Implement LocalAuthService

```java
package com.iflytek.skillhub.auth.local;

import com.iflytek.skillhub.domain.user.UserAccount;
import com.iflytek.skillhub.domain.user.UserAccountRepository;
import com.iflytek.skillhub.domain.user.UserStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

public class LocalAuthService {
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final int LOCK_MINUTES = 15;

    private final LocalCredentialRepository credentialRepo;
    private final UserAccountRepository userRepo;
    private final PasswordEncoder passwordEncoder;
    private final PasswordPolicyValidator policyValidator;

    public LocalAuthService(LocalCredentialRepository credentialRepo,
                            UserAccountRepository userRepo,
                            PasswordEncoder passwordEncoder,
                            PasswordPolicyValidator policyValidator) {
        this.credentialRepo = credentialRepo;
        this.userRepo = userRepo;
        this.passwordEncoder = passwordEncoder;
        this.policyValidator = policyValidator;
    }

    @Transactional
    public UserAccount register(String username, String password, String email) {
        var errors = policyValidator.validate(password);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Password policy violation: " + errors);
        }
        if (credentialRepo.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already taken");
        }
        var user = new UserAccount(username, email, null);
        user.setStatus(UserStatus.ACTIVE);
        user = userRepo.save(user);

        var credential = new LocalCredential(user.getId(), username, passwordEncoder.encode(password));
        credentialRepo.save(credential);
        return user;
    }

    @Transactional
    public UserAccount login(String username, String password) {
        var credential = credentialRepo.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("Invalid username or password"));

        var user = userRepo.findById(credential.getUserId())
            .orElseThrow(() -> new IllegalStateException("User not found"));

        if (user.getStatus() == UserStatus.DISABLED) {
            throw new IllegalStateException("Account is disabled");
        }
        if (credential.isLocked()) {
            throw new IllegalStateException("Account is locked");
        }
        if (!passwordEncoder.matches(password, credential.getPasswordHash())) {
            credential.recordFailedAttempt(MAX_FAILED_ATTEMPTS, LOCK_MINUTES);
            credentialRepo.save(credential);
            throw new IllegalArgumentException("Invalid username or password");
        }
        credential.resetFailedAttempts();
        credentialRepo.save(credential);
        return user;
    }

    @Transactional
    public void changePassword(String userId, String oldPassword, String newPassword) {
        var credential = credentialRepo.findByUserId(userId)
            .orElseThrow(() -> new IllegalStateException("No local credential"));
        if (!passwordEncoder.matches(oldPassword, credential.getPasswordHash())) {
            throw new IllegalArgumentException("Old password is incorrect");
        }
        var errors = policyValidator.validate(newPassword);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Password policy violation: " + errors);
        }
        credential.setPasswordHash(passwordEncoder.encode(newPassword));
        credentialRepo.save(credential);
    }
}
```

- [ ] **Step 4: Add login tests**

Append to `LocalAuthServiceTest`:

```java
@Test
void login_success() {
    var cred = new LocalCredential(1L, "testuser", passwordEncoder.encode("Test@1234"));
    var user = new UserAccount("testuser", null, null);
    when(credentialRepo.findByUsername("testuser")).thenReturn(java.util.Optional.of(cred));
    when(userRepo.findById(1L)).thenReturn(java.util.Optional.of(user));

    var result = service.login("testuser", "Test@1234");
    assertThat(result).isNotNull();
    verify(credentialRepo).save(argThat(c -> c.getFailedAttempts() == 0));
}

@Test
void login_wrongPassword_incrementsFailedAttempts() {
    var cred = new LocalCredential(1L, "testuser", passwordEncoder.encode("Test@1234"));
    var user = new UserAccount("testuser", null, null);
    when(credentialRepo.findByUsername("testuser")).thenReturn(java.util.Optional.of(cred));
    when(userRepo.findById(1L)).thenReturn(java.util.Optional.of(user));

    assertThatThrownBy(() -> service.login("testuser", "wrong"))
        .isInstanceOf(IllegalArgumentException.class);
    verify(credentialRepo).save(argThat(c -> c.getFailedAttempts() == 1));
}

@Test
void login_lockedAccount_throws() {
    var cred = new LocalCredential(1L, "testuser", passwordEncoder.encode("Test@1234"));
    cred.setLockedUntil(LocalDateTime.now().plusMinutes(10));
    var user = new UserAccount("testuser", null, null);
    when(credentialRepo.findByUsername("testuser")).thenReturn(java.util.Optional.of(cred));
    when(userRepo.findById(1L)).thenReturn(java.util.Optional.of(user));

    assertThatThrownBy(() -> service.login("testuser", "Test@1234"))
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("locked");
}
```

- [ ] **Step 5: Run all tests**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=LocalAuthServiceTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/local/LocalAuthService.java \
       server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/local/LocalAuthServiceTest.java
git commit -m "feat(auth): add LocalAuthService with register/login/changePassword"
```

### Task 1.5: DTO Classes — Request/Response Objects

**Files:**
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalRegisterRequest.java`
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalLoginRequest.java`
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/ChangePasswordRequest.java`

- [ ] **Step 1: Create LocalRegisterRequest

```java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record LocalRegisterRequest(
    @NotBlank @Size(min = 3, max = 64)
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Username must contain only letters, digits, underscores")
    String username,

    @NotBlank @Size(min = 8, max = 128)
    String password,

    String email
) {}
```

- [ ] **Step 2: Create LocalLoginRequest

```java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotBlank;

public record LocalLoginRequest(
    @NotBlank String username,
    @NotBlank String password
) {}
```

- [ ] **Step 3: Create ChangePasswordRequest

```java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
    @NotBlank String oldPassword,
    @NotBlank @Size(min = 8, max = 128) String newPassword
) {}
```

- [ ] **Step 4: Verify compilation**

Run: `cd server && mvn compile -pl skillhub-app`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalRegisterRequest.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/LocalLoginRequest.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/ChangePasswordRequest.java
git commit -m "feat(auth): add local auth request DTOs"
```

### Task 1.6: LocalAuthController — Local Auth Endpoints

**Files:**
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/LocalAuthController.java`
- Test: `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/LocalAuthControllerTest.java`

- [ ] **Step 1: Write Controller tests**

```java
package com.iflytek.skillhub.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.iflytek.skillhub.auth.local.LocalAuthService;
import com.iflytek.skillhub.domain.user.UserAccount;
import com.iflytek.skillhub.dto.LocalRegisterRequest;
import com.iflytek.skillhub.dto.LocalLoginRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(LocalAuthController.class)
class LocalAuthControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @MockBean private LocalAuthService localAuthService;

    @Test
    void register_success_returns200() throws Exception {
        var user = new UserAccount("testuser", null, null);
        when(localAuthService.register(eq("testuser"), eq("Test@1234"), isNull()))
            .thenReturn(user);

        mockMvc.perform(post("/api/v1/auth/local/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new LocalRegisterRequest("testuser", "Test@1234", null))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(0));
    }

    @Test
    void register_invalidUsername_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/auth/local/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"\",\"password\":\"Test@1234\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void login_success_returns200() throws Exception {
        var user = new UserAccount("testuser", null, null);
        when(localAuthService.login("testuser", "Test@1234")).thenReturn(user);

        mockMvc.perform(post("/api/v1/auth/local/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new LocalLoginRequest("testuser", "Test@1234"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(0));
    }

    @Test
    void login_wrongPassword_returns401() throws Exception {
        when(localAuthService.login("testuser", "wrong"))
            .thenThrow(new IllegalArgumentException("Invalid username or password"));

        mockMvc.perform(post("/api/v1/auth/local/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new LocalLoginRequest("testuser", "wrong"))))
            .andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 2: Run tests and confirm failure**

Run: `cd server && mvn test -pl skillhub-app -Dtest=LocalAuthControllerTest -Dsurefire.failIfNoSpecifiedTests=false`
Expected: FAIL — LocalAuthController does not exist

- [ ] **Step 3: Implement LocalAuthController

```java
package com.iflytek.skillhub.controller;

import com.iflytek.skillhub.auth.local.LocalAuthService;
import com.iflytek.skillhub.dto.ChangePasswordRequest;
import com.iflytek.skillhub.dto.LocalLoginRequest;
import com.iflytek.skillhub.dto.LocalRegisterRequest;
import com.iflytek.skillhub.domain.user.UserAccount;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth/local")
public class LocalAuthController {
    private final LocalAuthService localAuthService;

    public LocalAuthController(LocalAuthService localAuthService) {
        this.localAuthService = localAuthService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody LocalRegisterRequest req,
                                       HttpSession session) {
        try {
            var user = localAuthService.register(req.username(), req.password(), req.email());
            session.setAttribute("userId", user.getId());
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Registration successful", "data", Map.of(
                "userId", user.getId(), "displayName", user.getDisplayName())));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LocalLoginRequest req,
                                    HttpSession session) {
        try {
            var user = localAuthService.login(req.username(), req.password());
            session.setAttribute("userId", user.getId());
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Login successful", "data", Map.of(
                "userId", user.getId(), "displayName", user.getDisplayName())));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("code", 401, "msg", e.getMessage()));
        } catch (IllegalStateException e) {
            if (e.getMessage().contains("locked")) {
                return ResponseEntity.status(423)
                    .body(Map.of("code", 423, "msg", e.getMessage()));
            }
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(Map.of("code", 403, "msg", e.getMessage()));
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@Valid @RequestBody ChangePasswordRequest req,
                                             HttpSession session) {
        var userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("code", 401, "msg", "Please login first"));
        }
        try {
            localAuthService.changePassword(userId, req.oldPassword(), req.newPassword());
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Password changed successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }
}
```

- [ ] **Step 4: Modify SecurityConfig — Add local auth endpoints to permitAll + BCrypt Bean

Append to `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/config/SecurityConfig.java`:

1. Add imports:
```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
```

2. Add to the `.permitAll()` list in `authorizeHttpRequests`:
```java
.requestMatchers(
    "/api/v1/health",
    "/api/v1/auth/providers",
    "/api/v1/auth/me",
    "/api/v1/auth/local/register",  // new
    "/api/v1/auth/local/login",     // new
    "/actuator/health",
    // ... rest unchanged
).permitAll()
```

3. Add BCrypt Bean:
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12);
}
```

- [ ] **Step 5: Run tests**

Run: `cd server && mvn test -pl skillhub-app -Dtest=LocalAuthControllerTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/LocalAuthController.java \
       server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/LocalAuthControllerTest.java \
       server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/config/SecurityConfig.java
git commit -m "feat(auth): add LocalAuthController + SecurityConfig local auth endpoints"
```

### Task 1.7: AccountMergeRequest Entity + Repository

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequest.java`
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequestRepository.java`
- Create: `server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/AccountMergeRequestJpaRepository.java`

- [ ] **Step 1: Create AccountMergeRequest entity**

```java
package com.iflytek.skillhub.auth.merge;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "account_merge_request")
public class AccountMergeRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "primary_user_id", nullable = false)
    private Long primaryUserId;

    @Column(name = "secondary_user_id", nullable = false)
    private Long secondaryUserId;

    @Column(nullable = false, length = 32)
    private String status = "PENDING";

    @Column(name = "verification_token")
    private String verificationToken;

    @Column(name = "token_expires_at")
    private LocalDateTime tokenExpiresAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected AccountMergeRequest() {}

    public AccountMergeRequest(Long primaryUserId, Long secondaryUserId) {
        this.primaryUserId = primaryUserId;
        this.secondaryUserId = secondaryUserId;
    }

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
    }

    // Getters
    public Long getId() { return id; }
    public Long getPrimaryUserId() { return primaryUserId; }
    public Long getSecondaryUserId() { return secondaryUserId; }
    public String getStatus() { return status; }
    public String getVerificationToken() { return verificationToken; }
    public LocalDateTime getTokenExpiresAt() { return tokenExpiresAt; }
    public LocalDateTime getCompletedAt() { return completedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    // Status transitions
    public void setVerificationToken(String token, LocalDateTime expiresAt) {
        this.verificationToken = token;
        this.tokenExpiresAt = expiresAt;
    }

    public void verify() {
        this.status = "VERIFIED";
    }

    public void complete() {
        this.status = "COMPLETED";
        this.completedAt = LocalDateTime.now();
    }

    public void cancel() {
        this.status = "CANCELLED";
    }

    public boolean isExpired() {
        return tokenExpiresAt != null && tokenExpiresAt.isBefore(LocalDateTime.now());
    }
}
```

- [ ] **Step 2: Create Repository interface**

```java
package com.iflytek.skillhub.auth.merge;

import java.util.List;
import java.util.Optional;

public interface AccountMergeRequestRepository {
    AccountMergeRequest save(AccountMergeRequest request);
    Optional<AccountMergeRequest> findById(Long id);
    List<AccountMergeRequest> findByPrimaryUserId(Long primaryUserId);
    Optional<AccountMergeRequest> findBySecondaryUserIdAndStatus(Long secondaryUserId, String status);
}
```

- [ ] **Step 3: Create JPA implementation**

```java
package com.iflytek.skillhub.infra.jpa;

import com.iflytek.skillhub.auth.merge.AccountMergeRequest;
import com.iflytek.skillhub.auth.merge.AccountMergeRequestRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AccountMergeRequestJpaRepository
        extends JpaRepository<AccountMergeRequest, Long>, AccountMergeRequestRepository {
    List<AccountMergeRequest> findByPrimaryUserId(Long primaryUserId);
    Optional<AccountMergeRequest> findBySecondaryUserIdAndStatus(Long secondaryUserId, String status);
}
```

- [ ] **Step 4: Verify compilation**

Run: `cd server && mvn compile -pl skillhub-auth,skillhub-infra`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequest.java \
       server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeRequestRepository.java \
       server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/AccountMergeRequestJpaRepository.java
git commit -m "feat(auth): add AccountMergeRequest entity and repository"
```

### Task 1.8: AccountMergeService — Merge service

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeService.java`
- Test: `server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/merge/AccountMergeServiceTest.java`

- [ ] **Step 1: Write tests — initiate merge**

```java
package com.iflytek.skillhub.auth.merge;

import com.iflytek.skillhub.auth.local.LocalCredentialRepository;
import com.iflytek.skillhub.domain.user.UserAccount;
import com.iflytek.skillhub.domain.user.UserAccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AccountMergeServiceTest {
    @Mock private AccountMergeRequestRepository mergeRepo;
    @Mock private UserAccountRepository userRepo;
    @Mock private LocalCredentialRepository credentialRepo;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(4);
    private AccountMergeService service;

    @BeforeEach
    void setUp() {
        service = new AccountMergeService(mergeRepo, userRepo, credentialRepo, passwordEncoder);
    }

    @Test
    void initiate_success() {
        when(userRepo.findById(2L)).thenReturn(Optional.of(new UserAccount("secondary", null, null)));
        when(mergeRepo.findBySecondaryUserIdAndStatus(2L, "PENDING")).thenReturn(Optional.empty());
        when(mergeRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var result = service.initiate(1L, 2L);
        assertThat(result).isNotNull();
        assertThat(result.getPrimaryUserId()).isEqualTo(1L);
        assertThat(result.getSecondaryUserId()).isEqualTo(2L);
        assertThat(result.getStatus()).isEqualTo("PENDING");
    }

    @Test
    void initiate_selfMerge_throws() {
        assertThatThrownBy(() -> service.initiate(1L, 1L))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Cannot merge");
    }

    @Test
    void initiate_duplicatePending_throws() {
        when(userRepo.findById(2L)).thenReturn(Optional.of(new UserAccount("secondary", null, null)));
        when(mergeRepo.findBySecondaryUserIdAndStatus(2L, "PENDING"))
            .thenReturn(Optional.of(new AccountMergeRequest(3L, 2L)));

        assertThatThrownBy(() -> service.initiate(1L, 2L))
            .isInstanceOf(IllegalStateException.class);
    }
}
```

- [ ] **Step 2: Run tests and confirm failure**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=AccountMergeServiceTest -Dsurefire.failIfNoSpecifiedTests=false`
Expected: FAIL — AccountMergeService does not exist

- [ ] **Step 3: Implement AccountMergeService

```java
package com.iflytek.skillhub.auth.merge;

import com.iflytek.skillhub.auth.local.LocalCredentialRepository;
import com.iflytek.skillhub.domain.user.UserAccountRepository;
import com.iflytek.skillhub.domain.user.UserStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.UUID;

public class AccountMergeService {
    private static final int TOKEN_EXPIRY_MINUTES = 30;

    private final AccountMergeRequestRepository mergeRepo;
    private final UserAccountRepository userRepo;
    private final LocalCredentialRepository credentialRepo;
    private final PasswordEncoder passwordEncoder;

    public AccountMergeService(AccountMergeRequestRepository mergeRepo,
                               UserAccountRepository userRepo,
                               LocalCredentialRepository credentialRepo,
                               PasswordEncoder passwordEncoder) {
        this.mergeRepo = mergeRepo;
        this.userRepo = userRepo;
        this.credentialRepo = credentialRepo;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AccountMergeRequest initiate(Long primaryUserId, Long secondaryUserId) {
        if (primaryUserId.equals(secondaryUserId)) {
            throw new IllegalArgumentException("Cannot merge account with itself");
        }
        userRepo.findById(secondaryUserId)
            .orElseThrow(() -> new IllegalArgumentException("Secondary user not found"));

        mergeRepo.findBySecondaryUserIdAndStatus(secondaryUserId, "PENDING")
            .ifPresent(r -> { throw new IllegalStateException("Pending merge already exists"); });

        var rawToken = UUID.randomUUID().toString();
        var request = new AccountMergeRequest(primaryUserId, secondaryUserId);
        request.setVerificationToken(
            passwordEncoder.encode(rawToken),
            LocalDateTime.now().plusMinutes(TOKEN_EXPIRY_MINUTES));
        return mergeRepo.save(request);
    }

    @Transactional
    public void verify(Long requestId, String token) {
        var request = mergeRepo.findById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Merge request not found"));
        if (!"PENDING".equals(request.getStatus())) {
            throw new IllegalStateException("Request is not pending");
        }
        if (request.isExpired()) {
            request.cancel();
            mergeRepo.save(request);
            throw new IllegalStateException("Verification token expired");
        }
        if (!passwordEncoder.matches(token, request.getVerificationToken())) {
            throw new IllegalArgumentException("Invalid verification token");
        }
        request.verify();
        mergeRepo.save(request);
    }

    @Transactional
    public void confirm(Long requestId) {
        var request = mergeRepo.findById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Merge request not found"));
        if (!"VERIFIED".equals(request.getStatus())) {
            throw new IllegalStateException("Request is not verified");
        }
        // Data migration logic (skills, stars, roles, etc.) extended here
        var secondaryUser = userRepo.findById(request.getSecondaryUserId())
            .orElseThrow(() -> new IllegalStateException("Secondary user not found"));
        secondaryUser.setStatus(UserStatus.MERGED);
        secondaryUser.setMergedToUserId(request.getPrimaryUserId());
        userRepo.save(secondaryUser);

        request.complete();
        mergeRepo.save(request);
    }

    @Transactional
    public void cancel(Long requestId, String userId) {
        var request = mergeRepo.findById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Merge request not found"));
        if (!request.getPrimaryUserId().equals(userId)) {
            throw new IllegalArgumentException("Only primary user can cancel");
        }
        if ("COMPLETED".equals(request.getStatus())) {
            throw new IllegalStateException("Cannot cancel completed merge");
        }
        request.cancel();
        mergeRepo.save(request);
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd server && mvn test -pl skillhub-auth -Dtest=AccountMergeServiceTest`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/merge/AccountMergeService.java \
       server/skillhub-auth/src/test/java/com/iflytek/skillhub/auth/merge/AccountMergeServiceTest.java
git commit -m "feat(auth): add AccountMergeService with initiate/verify/confirm/cancel"
```

### Task 1.9: AccountMergeController + Merge DTOs

**Files:**
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeInitiateRequest.java`
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeVerifyRequest.java`
- Create: `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/AccountMergeController.java`
- Test: `server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/AccountMergeControllerTest.java`

- [ ] **Step 1: Create merge DTOs**

```java
// MergeInitiateRequest.java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotNull;

public record MergeInitiateRequest(
    @NotNull Long secondaryUserId
) {}
```

```java
// MergeVerifyRequest.java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotBlank;

public record MergeVerifyRequest(
    @NotBlank String token
) {}
```

- [ ] **Step 2: Write Controller tests**

```java
package com.iflytek.skillhub.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.iflytek.skillhub.auth.merge.AccountMergeRequest;
import com.iflytek.skillhub.auth.merge.AccountMergeService;
import com.iflytek.skillhub.dto.MergeInitiateRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.web.servlet.MockMvc;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AccountMergeController.class)
class AccountMergeControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @MockBean private AccountMergeService mergeService;

    @Test
    void initiate_success() throws Exception {
        var session = new MockHttpSession();
        session.setAttribute("userId", 1L);
        var mergeReq = new AccountMergeRequest(1L, 2L);
        when(mergeService.initiate(1L, 2L)).thenReturn(mergeReq);

        mockMvc.perform(post("/api/v1/auth/merge/initiate")
                .session(session)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new MergeInitiateRequest(2L))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(0));
    }

    @Test
    void initiate_notLoggedIn_returns401() throws Exception {
        mockMvc.perform(post("/api/v1/auth/merge/initiate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new MergeInitiateRequest(2L))))
            .andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 3: Run tests and confirm failure**

Run: `cd server && mvn test -pl skillhub-app -Dtest=AccountMergeControllerTest -Dsurefire.failIfNoSpecifiedTests=false`
Expected: FAIL — AccountMergeController does not exist

- [ ] **Step 4: Implement AccountMergeController

```java
package com.iflytek.skillhub.controller;

import com.iflytek.skillhub.auth.merge.AccountMergeService;
import com.iflytek.skillhub.dto.MergeInitiateRequest;
import com.iflytek.skillhub.dto.MergeVerifyRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth/merge")
public class AccountMergeController {
    private final AccountMergeService mergeService;

    public AccountMergeController(AccountMergeService mergeService) {
        this.mergeService = mergeService;
    }

    @PostMapping("/initiate")
    public ResponseEntity<?> initiate(@Valid @RequestBody MergeInitiateRequest req,
                                       HttpSession session) {
        var userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("code", 401, "msg", "Please login first"));
        }
        try {
            var result = mergeService.initiate(userId, req.secondaryUserId());
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Merge request created",
                "data", Map.of("requestId", result.getId())));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }

    @PostMapping("/{requestId}/verify")
    public ResponseEntity<?> verify(@PathVariable Long requestId,
                                     @Valid @RequestBody MergeVerifyRequest req) {
        try {
            mergeService.verify(requestId, req.token());
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Verification successful"));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }

    @PostMapping("/{requestId}/confirm")
    public ResponseEntity<?> confirm(@PathVariable Long requestId, HttpSession session) {
        var userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("code", 401, "msg", "Please login first"));
        }
        try {
            mergeService.confirm(requestId);
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Merge complete"));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }

    @PostMapping("/{requestId}/cancel")
    public ResponseEntity<?> cancel(@PathVariable Long requestId, HttpSession session) {
        var userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("code", 401, "msg", "Please login first"));
        }
        try {
            mergeService.cancel(requestId, userId);
            return ResponseEntity.ok(Map.of("code", 0, "msg", "Merge cancelled"));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "msg", e.getMessage()));
        }
    }
}
```

- [ ] **Step 5: Run tests**

Run: `cd server && mvn test -pl skillhub-app -Dtest=AccountMergeControllerTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeInitiateRequest.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/MergeVerifyRequest.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/AccountMergeController.java \
       server/skillhub-app/src/test/java/com/iflytek/skillhub/controller/AccountMergeControllerTest.java
git commit -m "feat(auth): add AccountMergeController with initiate/verify/confirm/cancel"
```

---

### Task 1.10: SeedDataRunner — Docker Environment Seed Data

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/config/SeedDataRunner.java`

**Steps:**

- [ ] **Step 1: Implement SeedDataRunner

```java
package com.iflytek.skillhub.config;

import com.iflytek.skillhub.domain.user.UserAccount;
import com.iflytek.skillhub.domain.user.UserAccountRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile("docker")
public class SeedDataRunner implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(SeedDataRunner.class);
    private final UserAccountRepository userRepo;
    private final PasswordEncoder encoder;

    public SeedDataRunner(UserAccountRepository userRepo, PasswordEncoder encoder) {
        this.userRepo = userRepo;
        this.encoder = encoder;
    }

    @Override
    public void run(String... args) {
        if (userRepo.count() > 0) {
            log.info("Seed data already exists, skipping.");
            return;
        }
        UserAccount admin = new UserAccount();
        admin.setUsername("admin");
        admin.setPasswordHash(encoder.encode("Admin@2026"));
        admin.setDisplayName("Administrator");
        admin.setStatus("ACTIVE");
        userRepo.save(admin);

        UserAccount demo = new UserAccount();
        demo.setUsername("demo");
        demo.setPasswordHash(encoder.encode("Demo@2026"));
        demo.setDisplayName("Demo User");
        demo.setStatus("ACTIVE");
        userRepo.save(demo);

        log.info("Seed data created: admin, demo");
    }
}
```

- [ ] **Step 2: Add docker profile configuration**

Add to `application.yml`:
```yaml
---
spring:
  config:
    activate:
      on-profile: docker
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:skillhub}
    username: ${DB_USER:skillhub}
    password: ${DB_PASS:skillhub}
```

- [ ] **Step 3: Verify compilation passes**

Run: `cd server && mvn compile -pl skillhub-app`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/config/SeedDataRunner.java \
       server/skillhub-app/src/main/resources/application.yml
git commit -m "feat(ops): add SeedDataRunner for docker profile with admin/demo users"
```

---

## Chunk 2: Skill Governance + Audit Logs + Prometheus Metrics

### Task 2.1: AuditLog Entity + Repository

**Files:**
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditLog.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditLogRepository.java`
- `server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/AuditLogJpaRepository.java`
- `server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/audit/AuditLogTest.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.domain.audit;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class AuditLogTest {

    @Test
    void shouldCreateAuditLog() {
        AuditLog log = AuditLog.of("user-1", "SKILL_PUBLISH",
                "skill-1", "Skill", "Published version 1.0.0");
        assertThat(log.getUserId()).isEqualTo("user-1");
        assertThat(log.getAction()).isEqualTo("SKILL_PUBLISH");
        assertThat(log.getTargetId()).isEqualTo("skill-1");
        assertThat(log.getTargetType()).isEqualTo("Skill");
        assertThat(log.getDetail()).isEqualTo("Published version 1.0.0");
        assertThat(log.getCreatedAt()).isNotNull();
    }

    @Test
    void shouldCreateWithoutDetail() {
        AuditLog log = AuditLog.of("user-1", "USER_LOGIN", null, null, null);
        assertThat(log.getAction()).isEqualTo("USER_LOGIN");
        assertThat(log.getTargetId()).isNull();
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=AuditLogTest`
Expected: COMPILATION FAILURE

- [ ] **Step 3: Implement AuditLog Entity

```java
package com.iflytek.skillhub.domain.audit;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_log")
public class AuditLog {
    @Id
    private String id;
    private String userId;
    private String action;
    private String targetId;
    private String targetType;

    @Column(length = 2000)
    private String detail;
    private Instant createdAt;

    protected AuditLog() {}

    public static AuditLog of(String userId, String action,
                               String targetId, String targetType, String detail) {
        AuditLog log = new AuditLog();
        log.id = UUID.randomUUID().toString();
        log.userId = userId;
        log.action = action;
        log.targetId = targetId;
        log.targetType = targetType;
        log.detail = detail;
        log.createdAt = Instant.now();
        return log;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getAction() { return action; }
    public String getTargetId() { return targetId; }
    public String getTargetType() { return targetType; }
    public String getDetail() { return detail; }
    public Instant getCreatedAt() { return createdAt; }
}
```

- [ ] **Step 4: Implement Repository

```java
package com.iflytek.skillhub.domain.audit;

import java.time.Instant;
import java.util.List;

public interface AuditLogRepository {
    AuditLog save(AuditLog log);
    List<AuditLog> findByUserId(String userId);
    List<AuditLog> findByTargetId(String targetId);
    List<AuditLog> findByActionAndCreatedAtAfter(String action, Instant after);
}
```

JPA implementation:
```java
package com.iflytek.skillhub.infra.jpa;

import com.iflytek.skillhub.domain.audit.AuditLog;
import com.iflytek.skillhub.domain.audit.AuditLogRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface AuditLogJpaRepository
        extends JpaRepository<AuditLog, String>, AuditLogRepository {
    List<AuditLog> findByUserId(String userId);
    List<AuditLog> findByTargetId(String targetId);
    List<AuditLog> findByActionAndCreatedAtAfter(String action, Instant after);
}
```

- [ ] **Step 5: Run tests**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=AuditLogTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/ \
       server/skillhub-infra/src/main/java/com/iflytek/skillhub/infra/jpa/AuditLogJpaRepository.java \
       server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/audit/AuditLogTest.java
git commit -m "feat(audit): add AuditLog entity and repository"
```

---

### Task 2.2: AuditService + Key Operation Instrumentation

**Files:**
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditService.java`
- `server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/audit/AuditServiceTest.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.domain.audit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class AuditServiceTest {

    private AuditLogRepository repo;
    private AuditService service;

    @BeforeEach
    void setUp() {
        repo = mock(AuditLogRepository.class);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        service = new AuditService(repo);
    }

    @Test
    void shouldLogAction() {
        service.log("user-1", "SKILL_PUBLISH", "skill-1", "Skill", "v1.0");
        ArgumentCaptor<AuditLog> cap = ArgumentCaptor.forClass(AuditLog.class);
        verify(repo).save(cap.capture());
        assertThat(cap.getValue().getAction()).isEqualTo("SKILL_PUBLISH");
    }

    @Test
    void shouldLogWithoutTarget() {
        service.log("user-1", "USER_LOGIN", null, null, null);
        verify(repo).save(any());
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=AuditServiceTest`
Expected: COMPILATION FAILURE

- [ ] **Step 3: Implement AuditService

```java
package com.iflytek.skillhub.domain.audit;

import org.springframework.stereotype.Service;

@Service
public class AuditService {

    private final AuditLogRepository repository;

    public AuditService(AuditLogRepository repository) {
        this.repository = repository;
    }

    public void log(String userId, String action,
                    String targetId, String targetType, String detail) {
        repository.save(AuditLog.of(userId, action, targetId, targetType, detail));
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=AuditServiceTest`
Expected: ALL PASS

- [ ] **Step 5: Add instrumentation to key Controllers**

Add `auditService.log(...)` calls at the following locations:
- `LocalAuthController.register()` → action: `USER_REGISTER`
- `LocalAuthController.login()` → action: `USER_LOGIN`
- `SkillPublishController.publish()` → action: `SKILL_PUBLISH`
- `AccountMergeController.confirm()` → action: `ACCOUNT_MERGE`

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/audit/AuditService.java \
       server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/audit/AuditServiceTest.java
git commit -m "feat(audit): add AuditService and embed audit logging in key operations"
```

---

### Task 2.3: Flyway V4 — audit_log + skill_deprecation Tables

**Files:**
- `server/skillhub-app/src/main/resources/db/migration/V4__phase4_audit_governance.sql`

**Steps:**

- [ ] **Step 1: Create migration script**

```sql
-- V4__phase4_audit_governance.sql

-- Audit log table
CREATE TABLE audit_log (
    id          VARCHAR(36) PRIMARY KEY,
    user_id     VARCHAR(36),
    action      VARCHAR(64)  NOT NULL,
    target_id   VARCHAR(36),
    target_type VARCHAR(64),
    detail      VARCHAR(2000),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_user    ON audit_log(user_id);
CREATE INDEX idx_audit_log_action  ON audit_log(action, created_at);
CREATE INDEX idx_audit_log_target  ON audit_log(target_id);

-- Skill deprecation marker fields
ALTER TABLE skill ADD COLUMN IF NOT EXISTS deprecated    BOOLEAN DEFAULT FALSE;
ALTER TABLE skill ADD COLUMN IF NOT EXISTS deprecated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE skill ADD COLUMN IF NOT EXISTS deprecated_by VARCHAR(36);
ALTER TABLE skill ADD COLUMN IF NOT EXISTS deprecation_reason VARCHAR(500);

-- Account merge requests表
CREATE TABLE account_merge_request (
    id                VARCHAR(36) PRIMARY KEY,
    primary_user_id   VARCHAR(36) NOT NULL,
    secondary_user_id VARCHAR(36) NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verification_token VARCHAR(255),
    token_expires_at  TIMESTAMP WITH TIME ZONE,
    completed_at      TIMESTAMP WITH TIME ZONE,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User table extension: local auth fields
ALTER TABLE user_account ADD COLUMN IF NOT EXISTS password_hash    VARCHAR(255);
ALTER TABLE user_account ADD COLUMN IF NOT EXISTS failed_attempts  INT DEFAULT 0;
ALTER TABLE user_account ADD COLUMN IF NOT EXISTS locked_until     TIMESTAMP WITH TIME ZONE;
ALTER TABLE user_account ADD COLUMN IF NOT EXISTS merged_to_user_id VARCHAR(36);
```

- [ ] **Step 2: Verify migration**

Run: `cd server && mvn flyway:migrate -pl skillhub-app -Dflyway.configFiles=src/main/resources/application.yml`
Or execute automatically on application startup.

- [ ] **Step 3: Commit**

```bash
git add server/skillhub-app/src/main/resources/db/migration/V4__phase4_audit_governance.sql
git commit -m "feat(db): add V4 migration for audit_log, skill deprecation, account merge"
```

---

### Task 2.4: Skill Deprecation Feature

**Files:**
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceService.java`
- `server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceServiceTest.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/portal/SkillGovernanceController.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.domain.skill.service;

import com.iflytek.skillhub.domain.skill.Skill;
import com.iflytek.skillhub.domain.skill.SkillRepository;
import com.iflytek.skillhub.domain.audit.AuditService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class SkillGovernanceServiceTest {

    private SkillRepository skillRepo;
    private AuditService auditService;
    private SkillGovernanceService service;

    @BeforeEach
    void setUp() {
        skillRepo = mock(SkillRepository.class);
        auditService = mock(AuditService.class);
        service = new SkillGovernanceService(skillRepo, auditService);
    }

    @Test
    void shouldDeprecateSkill() {
        Skill skill = mock(Skill.class);
        when(skill.getId()).thenReturn("s1");
        when(skillRepo.findById("s1")).thenReturn(Optional.of(skill));
        service.deprecate("s1", "user-1", "Replaced by new-skill");
        verify(skill).deprecate("user-1", "Replaced by new-skill");
        verify(skillRepo).save(skill);
        verify(auditService).log(eq("user-1"), eq("SKILL_DEPRECATE"),
                eq("s1"), eq("Skill"), anyString());
    }

    @Test
    void shouldUndeprecateSkill() {
        Skill skill = mock(Skill.class);
        when(skill.getId()).thenReturn("s1");
        when(skillRepo.findById("s1")).thenReturn(Optional.of(skill));
        service.undeprecate("s1", "user-1");
        verify(skill).undeprecate();
        verify(skillRepo).save(skill);
    }

    @Test
    void shouldThrowWhenSkillNotFound() {
        when(skillRepo.findById("s1")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.deprecate("s1", "u1", "reason"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=SkillGovernanceServiceTest`
Expected: COMPILATION FAILURE

- [ ] **Step 3: Add deprecation methods to Skill Entity**

Add to `Skill.java`:
```java
private boolean deprecated;
private Instant deprecatedAt;
private String deprecatedBy;
private String deprecationReason;

public void deprecate(String userId, String reason) {
    this.deprecated = true;
    this.deprecatedAt = Instant.now();
    this.deprecatedBy = userId;
    this.deprecationReason = reason;
}

public void undeprecate() {
    this.deprecated = false;
    this.deprecatedAt = null;
    this.deprecatedBy = null;
    this.deprecationReason = null;
}

public boolean isDeprecated() { return deprecated; }
public String getDeprecationReason() { return deprecationReason; }
```

- [ ] **Step 4: Implement SkillGovernanceService

```java
package com.iflytek.skillhub.domain.skill.service;

import com.iflytek.skillhub.domain.audit.AuditService;
import com.iflytek.skillhub.domain.skill.Skill;
import com.iflytek.skillhub.domain.skill.SkillRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SkillGovernanceService {

    private final SkillRepository skillRepo;
    private final AuditService auditService;

    public SkillGovernanceService(SkillRepository skillRepo, AuditService auditService) {
        this.skillRepo = skillRepo;
        this.auditService = auditService;
    }

    @Transactional
    public void deprecate(String skillId, String userId, String reason) {
        Skill skill = skillRepo.findById(skillId)
                .orElseThrow(() -> new IllegalArgumentException("Skill not found: " + skillId));
        skill.deprecate(userId, reason);
        skillRepo.save(skill);
        auditService.log(userId, "SKILL_DEPRECATE", skillId, "Skill", reason);
    }

    @Transactional
    public void undeprecate(String skillId, String userId) {
        Skill skill = skillRepo.findById(skillId)
                .orElseThrow(() -> new IllegalArgumentException("Skill not found: " + skillId));
        skill.undeprecate();
        skillRepo.save(skill);
        auditService.log(userId, "SKILL_UNDEPRECATE", skillId, "Skill", null);
    }
}
```

- [ ] **Step 5: Run tests**

Run: `cd server && mvn test -pl skillhub-domain -Dtest=SkillGovernanceServiceTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/Skill.java \
       server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceService.java \
       server/skillhub-domain/src/test/java/com/iflytek/skillhub/domain/skill/service/SkillGovernanceServiceTest.java
git commit -m "feat(governance): add skill deprecation/undeprecation with audit logging"
```

---

### Task 2.5: Prometheus Metrics + Actuator Configuration

**Files:**
- `server/skillhub-app/pom.xml` (add micrometer dependency)
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/metrics/SkillHubMetrics.java`
- `server/skillhub-app/src/main/resources/application.yml` (actuator configuration)

**Steps:**

- [ ] **Step 1: Add Maven dependency**

Add to `<dependencies>` in `skillhub-app/pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

- [ ] **Step 2: Configure Actuator

Add to `application.yml`:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  endpoint:
    health:
      show-details: when-authorized
  metrics:
    tags:
      application: skillhub
```

- [ ] **Step 3: Implement custom metrics**

```java
package com.iflytek.skillhub.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class SkillHubMetrics {

    private final Counter skillPublishCounter;
    private final Counter userRegisterCounter;
    private final Counter loginSuccessCounter;
    private final Counter loginFailureCounter;

    public SkillHubMetrics(MeterRegistry registry) {
        this.skillPublishCounter = Counter.builder("skillhub.skill.publish")
                .description("Number of skill publications")
                .register(registry);
        this.userRegisterCounter = Counter.builder("skillhub.user.register")
                .description("Number of user registrations")
                .register(registry);
        this.loginSuccessCounter = Counter.builder("skillhub.auth.login.success")
                .description("Successful logins")
                .register(registry);
        this.loginFailureCounter = Counter.builder("skillhub.auth.login.failure")
                .description("Failed logins")
                .register(registry);
    }

    public void incrementSkillPublish() { skillPublishCounter.increment(); }
    public void incrementUserRegister() { userRegisterCounter.increment(); }
    public void incrementLoginSuccess() { loginSuccessCounter.increment(); }
    public void incrementLoginFailure() { loginFailureCounter.increment(); }
}
```

- [ ] **Step 4: Add instrumentation to Controllers**

Call the corresponding metrics methods in the `LocalAuthController` login/register methods.
Call `metrics.incrementSkillPublish()` in the `SkillPublishController` publish method.

- [ ] **Step 5: Verify Actuator endpoint**

After starting the application, access: `GET /actuator/prometheus`
Expected: Returns Prometheus-format metrics data including `skillhub_skill_publish_total` etc.

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/pom.xml \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/metrics/SkillHubMetrics.java \
       server/skillhub-app/src/main/resources/application.yml
git commit -m "feat(ops): add Prometheus metrics with Actuator and custom counters"
```

---

### Task 2.6: SkillGovernanceController REST API

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/portal/SkillGovernanceController.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/DeprecateRequest.java`

**Steps:**

- [ ] **Step 1: Implement DTO

```java
package com.iflytek.skillhub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record DeprecateRequest(
    @NotBlank @Size(max = 500) String reason
) {}
```

- [ ] **Step 2: Implement Controller

```java
package com.iflytek.skillhub.controller.portal;

import com.iflytek.skillhub.controller.BaseApiController;
import com.iflytek.skillhub.dto.DeprecateRequest;
import com.iflytek.skillhub.domain.skill.service.SkillGovernanceService;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/skills/{skillId}/governance")
public class SkillGovernanceController extends BaseApiController {

    private final SkillGovernanceService governanceService;

    public SkillGovernanceController(SkillGovernanceService governanceService) {
        this.governanceService = governanceService;
    }

    @PostMapping("/deprecate")
    public ResponseEntity<Map<String, Object>> deprecate(
            @PathVariable String skillId,
            @Valid @RequestBody DeprecateRequest req,
            HttpSession session) {
        String userId = (String) session.getAttribute("userId");
        governanceService.deprecate(skillId, userId, req.reason());
        return ok(Map.of("deprecated", true));
    }

    @PostMapping("/undeprecate")
    public ResponseEntity<Map<String, Object>> undeprecate(
            @PathVariable String skillId,
            HttpSession session) {
        String userId = (String) session.getAttribute("userId");
        governanceService.undeprecate(skillId, userId);
        return ok(Map.of("deprecated", false));
    }
}
```

- [ ] **Step 3: Verify compilation**

Run: `cd server && mvn compile -pl skillhub-app`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/dto/DeprecateRequest.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/controller/portal/SkillGovernanceController.java
git commit -m "feat(governance): add SkillGovernanceController with deprecate/undeprecate endpoints"
```

---

## Chunk 3: Performance Optimization + Security Hardening

### Task 3.1: HTTP Cache Headers + ETag Support

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/filter/CacheControlFilter.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/filter/CacheControlFilterTest.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.Test;
import static org.mockito.Mockito.*;

class CacheControlFilterTest {

    @Test
    void shouldAddCacheHeadersForSkillDownload() throws Exception {
        CacheControlFilter filter = new CacheControlFilter();
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse resp = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        when(req.getRequestURI()).thenReturn("/api/v1/skills/s1/versions/1.0/download");
        when(req.getMethod()).thenReturn("GET");
        filter.doFilterInternal(req, resp, chain);
        verify(resp).setHeader("Cache-Control", "public, max-age=86400, immutable");
        verify(chain).doFilter(req, resp);
    }

    @Test
    void shouldNotCacheApiMutations() throws Exception {
        CacheControlFilter filter = new CacheControlFilter();
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse resp = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        when(req.getRequestURI()).thenReturn("/api/v1/skills");
        when(req.getMethod()).thenReturn("POST");
        filter.doFilterInternal(req, resp, chain);
        verify(resp, never()).setHeader(eq("Cache-Control"), anyString());
        verify(chain).doFilter(req, resp);
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-app -Dtest=CacheControlFilterTest`
Expected: COMPILATION FAILURE

- [ ] **Step 3: Implement CacheControlFilter

```java
package com.iflytek.skillhub.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class CacheControlFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                     HttpServletResponse resp,
                                     FilterChain chain)
            throws ServletException, IOException {
        String uri = req.getRequestURI();
        String method = req.getMethod();
        if ("GET".equals(method) && uri.contains("/download")) {
            resp.setHeader("Cache-Control", "public, max-age=86400, immutable");
        } else if ("GET".equals(method) && uri.startsWith("/api/")) {
            resp.setHeader("Cache-Control", "no-cache");
        }
        chain.doFilter(req, resp);
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd server && mvn test -pl skillhub-app -Dtest=CacheControlFilterTest`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/filter/CacheControlFilter.java \
       server/skillhub-app/src/test/java/com/iflytek/skillhub/filter/CacheControlFilterTest.java
git commit -m "feat(perf): add CacheControlFilter with immutable download caching"
```

---

### Task 3.2: CORS Configuration + Security Headers

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/config/CorsConfig.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/filter/SecurityHeadersFilter.java`
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/filter/SecurityHeadersFilterTest.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.Test;
import static org.mockito.Mockito.*;

class SecurityHeadersFilterTest {

    @Test
    void shouldAddSecurityHeaders() throws Exception {
        SecurityHeadersFilter filter = new SecurityHeadersFilter();
        HttpServletRequest req = mock(HttpServletRequest.class);
        HttpServletResponse resp = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        filter.doFilterInternal(req, resp, chain);
        verify(resp).setHeader("X-Content-Type-Options", "nosniff");
        verify(resp).setHeader("X-Frame-Options", "DENY");
        verify(resp).setHeader("X-XSS-Protection", "1; mode=block");
        verify(resp).setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        verify(chain).doFilter(req, resp);
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-app -Dtest=SecurityHeadersFilterTest`
Expected: COMPILATION FAILURE

- [ ] **Step 3: Implement SecurityHeadersFilter

```java
package com.iflytek.skillhub.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class SecurityHeadersFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                     HttpServletResponse resp,
                                     FilterChain chain)
            throws ServletException, IOException {
        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("X-Frame-Options", "DENY");
        resp.setHeader("X-XSS-Protection", "1; mode=block");
        resp.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        chain.doFilter(req, resp);
    }
}
```

- [ ] **Step 4: Implement CorsConfig

```java
package com.iflytek.skillhub.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
public class CorsConfig {

    @Value("${skillhub.cors.allowed-origins:http://localhost:5173}")
    private String allowedOrigins;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of(allowedOrigins.split(",")));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
```

- [ ] **Step 5: Run tests**

Run: `cd server && mvn test -pl skillhub-app -Dtest=SecurityHeadersFilterTest`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/config/CorsConfig.java \
       server/skillhub-app/src/main/java/com/iflytek/skillhub/filter/SecurityHeadersFilter.java \
       server/skillhub-app/src/test/java/com/iflytek/skillhub/filter/SecurityHeadersFilterTest.java
git commit -m "feat(security): add CORS config and security response headers"
```

---

### Task 3.3: Redis RateLimiter Enhancement + Configuration Externalization

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/ratelimit/RateLimitConfig.java`
- `server/skillhub-app/src/main/resources/application.yml` (rate limit configuration)

**Steps:**

- [ ] **Step 1: Implement RateLimitConfig

```java
package com.iflytek.skillhub.ratelimit;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;

@Configuration
@ConfigurationProperties(prefix = "skillhub.rate-limit")
public class RateLimitConfig {

    private int defaultMaxRequests = 60;
    private int defaultWindowSeconds = 60;
    private int publishMaxRequests = 10;
    private int publishWindowSeconds = 3600;

    @Bean
    public RateLimiter rateLimiter(StringRedisTemplate redisTemplate) {
        try {
            redisTemplate.getConnectionFactory().getConnection().ping();
            return new RedisSlidingWindowRateLimiter(redisTemplate);
        } catch (Exception e) {
            return new InMemorySlidingWindowRateLimiter();
        }
    }

    public int getDefaultMaxRequests() { return defaultMaxRequests; }
    public void setDefaultMaxRequests(int v) { this.defaultMaxRequests = v; }
    public int getDefaultWindowSeconds() { return defaultWindowSeconds; }
    public void setDefaultWindowSeconds(int v) { this.defaultWindowSeconds = v; }
    public int getPublishMaxRequests() { return publishMaxRequests; }
    public void setPublishMaxRequests(int v) { this.publishMaxRequests = v; }
    public int getPublishWindowSeconds() { return publishWindowSeconds; }
    public void setPublishWindowSeconds(int v) { this.publishWindowSeconds = v; }
}
```

- [ ] **Step 2: Add configuration items**

Add to `application.yml`:
```yaml
skillhub:
  rate-limit:
    default-max-requests: 60
    default-window-seconds: 60
    publish-max-requests: 10
    publish-window-seconds: 3600
  cors:
    allowed-origins: http://localhost:5173
```

- [ ] **Step 3: Verify compilation**

Run: `cd server && mvn compile -pl skillhub-app`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/ratelimit/RateLimitConfig.java \
       server/skillhub-app/src/main/resources/application.yml
git commit -m "feat(ops): externalize rate limit config with Redis/InMemory fallback"
```

---

### Task 3.4: Request Parameter Validation + Enhanced Global Exception Handling

**Files:**
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/exception/GlobalExceptionHandler.java` (enhance)
- `server/skillhub-app/src/test/java/com/iflytek/skillhub/exception/GlobalExceptionHandlerTest.java`

**Steps:**

- [ ] **Step 1: Write failing tests**

```java
package com.iflytek.skillhub.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import java.util.List;
import java.util.Map;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void shouldHandleValidationErrors() {
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult br = mock(BindingResult.class);
        when(ex.getBindingResult()).thenReturn(br);
        when(br.getFieldErrors()).thenReturn(List.of(
                new FieldError("req", "username", "must not be blank")
        ));
        ResponseEntity<Map<String, Object>> resp = handler.handleValidation(ex);
        assertThat(resp.getStatusCode().value()).isEqualTo(400);
        Map<String, Object> body = resp.getBody();
        assertThat(body.get("code")).isEqualTo(400);
        assertThat(body.get("msg")).asString().contains("username");
    }

    @Test
    void shouldHandleDomainBadRequest() {
        var ex = new com.iflytek.skillhub.domain.shared.exception.DomainBadRequestException("bad");
        ResponseEntity<Map<String, Object>> resp = handler.handleDomainBadRequest(ex);
        assertThat(resp.getStatusCode().value()).isEqualTo(400);
    }

    @Test
    void shouldHandleDomainForbidden() {
        var ex = new com.iflytek.skillhub.domain.shared.exception.DomainForbiddenException("forbidden");
        ResponseEntity<Map<String, Object>> resp = handler.handleDomainForbidden(ex);
        assertThat(resp.getStatusCode().value()).isEqualTo(403);
    }
}
```

- [ ] **Step 2: Verify test failure**

Run: `cd server && mvn test -pl skillhub-app -Dtest=GlobalExceptionHandlerTest`
Expected: COMPILATION FAILURE (new methods do not exist)

- [ ] **Step 3: Enhance GlobalExceptionHandler**

Add to existing `GlobalExceptionHandler.java`:
```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
    String errors = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .collect(Collectors.joining("; "));
    return ResponseEntity.badRequest().body(Map.of(
            "code", 400, "msg", errors, "timestamp", Instant.now().toString()));
}

@ExceptionHandler(DomainBadRequestException.class)
public ResponseEntity<Map<String, Object>> handleDomainBadRequest(DomainBadRequestException ex) {
    return ResponseEntity.badRequest().body(Map.of(
            "code", 400, "msg", ex.getMessage(), "timestamp", Instant.now().toString()));
}

@ExceptionHandler(DomainForbiddenException.class)
public ResponseEntity<Map<String, Object>> handleDomainForbidden(DomainForbiddenException ex) {
    return ResponseEntity.status(403).body(Map.of(
            "code", 403, "msg", ex.getMessage(), "timestamp", Instant.now().toString()));
}

@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
    log.error("Unhandled exception", ex);
    return ResponseEntity.status(500).body(Map.of(
            "code", 500, "msg", "Internal server error", "timestamp", Instant.now().toString()));
}
```

- [ ] **Step 4: Run tests**

Run: `cd server && mvn test -pl skillhub-app -Dtest=GlobalExceptionHandlerTest`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-app/src/main/java/com/iflytek/skillhub/exception/GlobalExceptionHandler.java \
       server/skillhub-app/src/test/java/com/iflytek/skillhub/exception/GlobalExceptionHandlerTest.java
git commit -m "feat(security): enhance GlobalExceptionHandler with validation and domain errors"
```

---

### Task 3.5: Database Query Optimization — Indexes + Pagination

**Files:**
- `server/skillhub-app/src/main/resources/db/migration/V5__performance_indexes.sql`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/SkillRepository.java` (add pagination methods)

**Steps:**

- [ ] **Step 1: Create index migration script**

```sql
-- V5__performance_indexes.sql

-- Skill query optimization
CREATE INDEX IF NOT EXISTS idx_skill_namespace_id ON skill(namespace_id);
CREATE INDEX IF NOT EXISTS idx_skill_name ON skill(name);
CREATE INDEX IF NOT EXISTS idx_skill_deprecated ON skill(deprecated) WHERE deprecated = true;

-- SkillVersion query optimization
CREATE INDEX IF NOT EXISTS idx_skill_version_skill_id ON skill_version(skill_id);
CREATE INDEX IF NOT EXISTS idx_skill_version_created ON skill_version(created_at DESC);

-- NamespaceMember query optimization
CREATE INDEX IF NOT EXISTS idx_ns_member_user ON namespace_member(user_id);
CREATE INDEX IF NOT EXISTS idx_ns_member_ns ON namespace_member(namespace_id);

-- ReviewTask query optimization
CREATE INDEX IF NOT EXISTS idx_review_task_status ON review_task(status);
CREATE INDEX IF NOT EXISTS idx_review_task_reviewer ON review_task(reviewer_id);

-- ApiToken query optimization
CREATE INDEX IF NOT EXISTS idx_api_token_user ON api_token(user_id);
CREATE INDEX IF NOT EXISTS idx_api_token_hash ON api_token(token_hash);

-- Full-text search optimization
CREATE INDEX IF NOT EXISTS idx_search_doc_tsv ON skill_search_document USING gin(search_vector);
```

- [ ] **Step 2: Add pagination support to SkillRepository**

```java
// Add to SkillRepository interface:
Page<Skill> findByNamespaceId(String namespaceId, Pageable pageable);
Page<Skill> findByDeprecatedFalse(Pageable pageable);
```

- [ ] **Step 3: Verify migration**

Run: `cd server && mvn compile -pl skillhub-app`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add server/skillhub-app/src/main/resources/db/migration/V5__performance_indexes.sql \
       server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/skill/SkillRepository.java
git commit -m "feat(perf): add database indexes and pagination support"
```

---

## Chunk 4: Docker One-Click Startup + Open-Source Infrastructure

### Task 4.1: Dockerfile — Multi-Stage Build

**Files:**
- `server/Dockerfile`

**Steps:**

- [ ] **Step 1: Create Dockerfile

```dockerfile
# ---- Build Stage ----
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY skillhub-domain/pom.xml skillhub-domain/
COPY skillhub-auth/pom.xml skillhub-auth/
COPY skillhub-search/pom.xml skillhub-search/
COPY skillhub-infra/pom.xml skillhub-infra/
COPY skillhub-app/pom.xml skillhub-app/
RUN mvn dependency:go-offline -B

COPY . .
RUN mvn package -DskipTests -B

# ---- Runtime Stage ----
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /app/skillhub-app/target/skillhub-app-*.jar app.jar

RUN chown -R app:app /app
USER app

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 2: Create .dockerignore

```
**/target/
**/.idea/
**/*.iml
.git/
```

- [ ] **Step 3: Verify build**

Run: `cd server && docker build -t skillhub-server:dev .`
Expected: Build successful

- [ ] **Step 4: Commit**

```bash
git add server/Dockerfile server/.dockerignore
git commit -m "feat(ops): add multi-stage Dockerfile for server"
```

---

### Task 4.2: Web Frontend Dockerfile

**Files:**
- `web/Dockerfile`
- `web/nginx.conf`

**Steps:**

- [ ] **Step 1: Create nginx.conf

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://server:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /actuator/ {
        deny all;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}
```

- [ ] **Step 2: Create Dockerfile

```dockerfile
# ---- Build Stage ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Runtime Stage ----
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost/ || exit 1
```

- [ ] **Step 3: Verify build**

Run: `cd web && docker build -t skillhub-web:dev .`
Expected: Build successful

- [ ] **Step 4: Commit**

```bash
git add web/Dockerfile web/nginx.conf
git commit -m "feat(ops): add multi-stage Dockerfile for web frontend with nginx"
```

---

### Task 4.3: docker-compose.yml — One-Click Startup

**Files:**
- `docker-compose.yml`

**Steps:**

- [ ] **Step 1: Create docker-compose.yml

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: skillhub
      POSTGRES_USER: skillhub
      POSTGRES_PASSWORD: skillhub
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U skillhub"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  server:
    build: ./server
    environment:
      SPRING_PROFILES_ACTIVE: docker
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: skillhub
      DB_USER: skillhub
      DB_PASS: skillhub
      SPRING_DATA_REDIS_HOST: redis
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  web:
    build: ./web
    ports:
      - "80:80"
    depends_on:
      - server

volumes:
  pgdata:
```

- [ ] **Step 2: Verify startup**

Run: `docker compose up -d --build`
Expected: All services start successfully, `docker compose ps` shows 4 running containers

- [ ] **Step 3: Verify health check**

Run: `curl http://localhost:8080/actuator/health`
Expected: `{"status":"UP"}`

Run: `curl http://localhost/`
Expected: Returns frontend HTML page

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(ops): add docker-compose for one-click local deployment"
```

---

### Task 4.4: Makefile — Common Command Wrappers

**Files:**
- `Makefile`

**Steps:**

- [ ] **Step 1: Create Makefile

```makefile
.PHONY: help dev up down test build clean

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## Start development environment (postgres + redis only)
	docker compose up -d postgres redis

up: ## One-click start all services
	docker compose up -d --build

down: ## Stop all services
	docker compose down

test: ## Run all backend tests
	cd server && mvn test

build: ## Build backend
	cd server && mvn package -DskipTests

clean: ## Clean build artifacts
	cd server && mvn clean
	docker compose down -v

logs: ## View service logs
	docker compose logs -f server

db-reset: ## Reset database
	docker compose down -v
	docker compose up -d postgres
	@echo "Waiting for postgres..."
	@sleep 3
	cd server && mvn flyway:migrate -pl skillhub-app
```

- [ ] **Step 2: Verify**

Run: `make help`
Expected: Shows all available commands

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat(ops): add Makefile with dev/up/down/test/build commands"
```

---

### Task 4.5: README.md — Project Documentation

**Files:**
- `README.md`

**Steps:**

- [ ] **Step 1: Create README.md

```markdown
# SkillHub

AI Skill sharing platform — publish, discover, and manage AI skill packages.

## Quick Start

### Prerequisites
- Docker & Docker Compose
- JDK 21+ (development mode)
- Node.js 20+ (frontend development)

### One-Click Startup

```bash
make up
```

Access:
- Frontend: http://localhost
- API: http://localhost:8080
- Prometheus metrics: http://localhost:8080/actuator/prometheus

### Development Mode

```bash
# Start infrastructure
make dev

# Start backend
cd server && mvn spring-boot:run

# Start frontend
cd web && npm run dev
```

### Default Accounts

| Username | Password | Role |
|--------|------|------|
| admin  | Admin@2026 | Admin |
| demo   | Demo@2026  | Regular User |

## Project Structure

```
skillhub/
├── server/                 # Spring Boot backend
│   ├── skillhub-app/       # Application layer (Controller, DTO, Config)
│   ├── skillhub-domain/    # Domain layer (Entity, Service, Repository)
│   ├── skillhub-auth/      # Auth/authorization module
│   ├── skillhub-search/    # Search module
│   └── skillhub-infra/     # Infrastructure layer (JPA implementations)
├── web/                    # React frontend
├── docker-compose.yml      # One-click deployment
└── Makefile                # Common commands
```

## Common Commands

```bash
make help      # View all commands
make test      # Run tests
make build     # Build project
make logs      # View logs
make db-reset  # Reset database
```

## Tech Stack

- **Backend:** Spring Boot 3, JDK 21, PostgreSQL, Redis, Flyway
- **Frontend:** React, TypeScript, Vite
- **DevOps:** Docker, Prometheus, Actuator

## License

MIT
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README with quickstart guide"
```

---

### Task 4.6: Prometheus + Grafana Monitoring Stack (Optional)

**Files:**
- `monitoring/prometheus.yml`
- `monitoring/docker-compose.monitoring.yml`

**Steps:**

- [ ] **Step 1: Create Prometheus configuration**

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'skillhub-server'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['server:8080']
```

- [ ] **Step 2: Create monitoring compose file**

```yaml
# monitoring/docker-compose.monitoring.yml
version: "3.9"

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    depends_on:
      - prometheus
```

- [ ] **Step 3: Verify**

Run: `cd monitoring && docker compose -f docker-compose.monitoring.yml up -d`
Expected: Prometheus and Grafana start successfully

Access:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

- [ ] **Step 4: Commit**

```bash
git add monitoring/
git commit -m "feat(ops): add Prometheus + Grafana monitoring stack"
```

---

### Task 4.7: End-to-End Smoke Test Script

**Files:**
- `scripts/smoke-test.sh`

**Steps:**

- [ ] **Step 1: Create smoke test script**

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
PASS=0
FAIL=0

check() {
    local desc="$1" url="$2" expected="$3"
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$status" = "$expected" ]; then
        echo "  PASS: $desc (HTTP $status)"
        ((PASS++))
    else
        echo "  FAIL: $desc (expected $expected, got $status)"
        ((FAIL++))
    fi
}

echo "=== SkillHub Smoke Test ==="
echo "Target: $BASE_URL"
echo ""

# Health
check "Health endpoint" "$BASE_URL/actuator/health" "200"

# Prometheus metrics
check "Prometheus metrics" "$BASE_URL/actuator/prometheus" "200"

# Public API
check "Skill search" "$BASE_URL/api/v1/skills/search?q=test" "200"

# Auth required
check "Auth required (401)" "$BASE_URL/api/v1/me" "401"

# Register
REG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/auth/local/register" \
    -H "Content-Type: application/json" \
    -d '{"username":"smoketest","password":"Smoke@2026"}')
if [ "$REG_STATUS" = "200" ] || [ "$REG_STATUS" = "409" ]; then
    echo "  PASS: Register (HTTP $REG_STATUS)"
    ((PASS++))
else
    echo "  FAIL: Register (got $REG_STATUS)"
    ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

- [ ] **Step 2: Set executable permissions**

Run: `chmod +x scripts/smoke-test.sh`

- [ ] **Step 3: Commit**

```bash
git add scripts/smoke-test.sh
git commit -m "feat(ops): add end-to-end smoke test script"
```

---

## Completion Markers

After all chunks are complete, execute the final verification:

- [ ] `make up` — One-click start all services
- [ ] `make test` — All backend tests pass
- [ ] `./scripts/smoke-test.sh` — Smoke test passes
- [ ] `curl localhost:8080/actuator/prometheus` — Metrics are normal
- [ ] Frontend pages can be accessed and operated normally

```bash
git tag v0.4.0
git push origin feature/project-init --tags
```
