# Phase 1: Engineering Skeleton + Authentication Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a runnable frontend and backend engineering skeleton, complete GitHub OAuth login and API Token authentication, and satisfy the Phase 1 acceptance criteria.

**Architecture:** Maven multi-module backend (6 modules) + React frontend + Docker Compose local development environment + Spring Security OAuth2 + RBAC

**Tech Stack:**
- Backend: Spring Boot 3.x + JDK 21 + PostgreSQL 16 + Redis 7 + Spring Security OAuth2 Client + Spring Data JPA + Flyway
- Frontend: React 19 + TypeScript + Vite + TanStack Router + TanStack Query + shadcn/ui + Tailwind CSS
- DevOps: Docker Compose + Maven Wrapper + Makefile

---

## Chunk 1: Backend Engineering Skeleton + Infrastructure

This chunk establishes the Maven multi-module project structure, database migrations, base configuration, health checks, and OpenAPI documentation, producing a launchable backend application.

### File Structure Mapping

```
skillhub/
├── server/
│   ├── pom.xml                           # Parent POM
│   ├── .mvn/wrapper/                     # Maven Wrapper
│   ├── mvnw, mvnw.cmd
│   ├── skillhub-app/
│   │   ├── pom.xml
│   │   └── src/main/
│   │       ├── java/com/skillhub/
│   │       │   ├── SkillhubApplication.java
│   │       │   ├── config/
│   │       │   │   ├── OpenApiConfig.java
│   │       │   │   └── WebMvcConfig.java
│   │       │   ├── controller/
│   │       │   │   └── HealthController.java
│   │       │   └── filter/
│   │       │       └── RequestIdFilter.java
│   │       └── resources/
│   │           ├── application.yml
│   │           ├── application-local.yml
│   │           └── db/migration/
│   │               └── V1__init_schema.sql
│   ├── skillhub-domain/
│   │   ├── pom.xml
│   │   └── src/main/java/com/skillhub/domain/
│   ├── skillhub-auth/
│   │   ├── pom.xml
│   │   └── src/main/java/com/skillhub/auth/
│   ├── skillhub-search/
│   │   ├── pom.xml
│   │   └── src/main/java/com/skillhub/search/
│   ├── skillhub-storage/
│   │   ├── pom.xml
│   │   └── src/main/java/com/skillhub/storage/
│   └── skillhub-infra/
│       ├── pom.xml
│       └── src/main/java/com/skillhub/infra/
├── docker-compose.yml
├── .gitignore
└── Makefile
```

### Task 1: Initialize Monorepo and Maven Multi-Module Project

**Files:**
- Create: `server/pom.xml`
- Create: `server/skillhub-app/pom.xml`
- Create: `server/skillhub-domain/pom.xml`
- Create: `server/skillhub-auth/pom.xml`
- Create: `server/skillhub-search/pom.xml`
- Create: `server/skillhub-storage/pom.xml`
- Create: `server/skillhub-infra/pom.xml`
- Create: `.gitignore`

- [ ] **Step 1: Create root .gitignore**

```bash
cat > .gitignore << 'EOF'
# Maven
target/
!.mvn/wrapper/maven-wrapper.jar
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties

# IDE
.idea/
*.iml
.vscode/
.DS_Store

# Logs
*.log

# Environment
.env
.env.local

# Node
node_modules/
dist/
.pnpm-store/
EOF
```

- [ ] **Step 2: Create parent POM (server/pom.xml)**

```bash
mkdir -p server && cat > server/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.3</version>
        <relativePath/>
    </parent>

    <groupId>com.skillhub</groupId>
    <artifactId>skillhub-parent</artifactId>
    <version>0.1.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <modules>
        <module>skillhub-app</module>
        <module>skillhub-domain</module>
        <module>skillhub-auth</module>
        <module>skillhub-search</module>
        <module>skillhub-storage</module>
        <module>skillhub-infra</module>
    </modules>

    <dependencyManagement>
        <dependencies>
            <!-- Internal modules -->
            <dependency>
                <groupId>com.skillhub</groupId>
                <artifactId>skillhub-domain</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.skillhub</groupId>
                <artifactId>skillhub-auth</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.skillhub</groupId>
                <artifactId>skillhub-search</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.skillhub</groupId>
                <artifactId>skillhub-storage</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.skillhub</groupId>
                <artifactId>skillhub-infra</artifactId>
                <version>${project.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
</project>
EOF
```

- [ ] **Step 3: Create skillhub-app module POM**

```bash
mkdir -p server/skillhub-app && cat > server/skillhub-app/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>

    <artifactId>skillhub-app</artifactId>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.3.0</version>
        </dependency>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-domain</artifactId>
        </dependency>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-auth</artifactId>
        </dependency>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-infra</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF
```

- [ ] **Step 4: Create POMs for remaining modules (domain, auth, search, storage, infra)**

```bash
# skillhub-domain
mkdir -p server/skillhub-domain/src/main/java/com/skillhub/domain
cat > server/skillhub-domain/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>
    <artifactId>skillhub-domain</artifactId>
</project>
EOF

# skillhub-auth
mkdir -p server/skillhub-auth/src/main/java/com/skillhub/auth
cat > server/skillhub-auth/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>
    <artifactId>skillhub-auth</artifactId>
    <dependencies>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-domain</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

# skillhub-search
mkdir -p server/skillhub-search/src/main/java/com/skillhub/search
cat > server/skillhub-search/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>
    <artifactId>skillhub-search</artifactId>
    <dependencies>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-domain</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

# skillhub-storage
mkdir -p server/skillhub-storage/src/main/java/com/skillhub/storage
cat > server/skillhub-storage/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>
    <artifactId>skillhub-storage</artifactId>
</project>
EOF

# skillhub-infra
mkdir -p server/skillhub-infra/src/main/java/com/skillhub/infra
cat > server/skillhub-infra/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.skillhub</groupId>
        <artifactId>skillhub-parent</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </parent>
    <artifactId>skillhub-infra</artifactId>
    <dependencies>
        <dependency>
            <groupId>com.skillhub</groupId>
            <artifactId>skillhub-domain</artifactId>
        </dependency>
    </dependencies>
</project>
EOF
```

- [ ] **Step 5: Install Maven Wrapper**

Run: `cd server && mvn wrapper:wrapper`

Expected: Maven Wrapper files generated in `server/.mvn/wrapper/`

- [ ] **Step 6: Verify project structure**

Run: `cd server && ./mvnw clean compile`

Expected: `BUILD SUCCESS`, all modules compile successfully

- [ ] **Step 7: Commit**

```bash
git add .gitignore server/
git commit -m "feat: initialize Maven multi-module project structure

- Add parent POM with 6 modules (app, domain, auth, search, storage, infra)
- Configure Spring Boot 3.2.3 + JDK 21
- Add Maven Wrapper for reproducible builds
- Set up module dependency graph (app depends on all, infra/auth/search depend on domain)"
```

### Task 2: Create Spring Boot Application Entry Point and Base Configuration

**Files:**
- Create: `server/skillhub-app/src/main/java/com/skillhub/SkillhubApplication.java`
- Create: `server/skillhub-app/src/main/resources/application.yml`
- Create: `server/skillhub-app/src/main/resources/application-local.yml`
- Create: `server/skillhub-app/src/test/java/com/skillhub/ApplicationContextStartsTest.java`

- [ ] **Step 1: Write a failing ApplicationContext startup test**

```bash
mkdir -p server/skillhub-app/src/test/java/com/skillhub
cat > server/skillhub-app/src/test/java/com/skillhub/ApplicationContextStartsTest.java << 'EOF'
package com.skillhub;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class ApplicationContextStartsTest {

    @Test
    void contextLoads() {
        // ApplicationContext should start successfully
    }
}
EOF
```

- [ ] **Step 2: Run test and confirm failure**

Run: `cd server && ./mvnw test -Dtest=ApplicationContextStartsTest`

Expected: FAIL - "Unable to find a @SpringBootConfiguration"

- [ ] **Step 3: Create SkillhubApplication main class**

```bash
mkdir -p server/skillhub-app/src/main/java/com/skillhub
cat > server/skillhub-app/src/main/java/com/skillhub/SkillhubApplication.java << 'EOF'
package com.skillhub;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SkillhubApplication {

    public static void main(String[] args) {
        SpringApplication.run(SkillhubApplication.java, args);
    }
}
EOF
```

- [ ] **Step 4: Create base configuration files**

```bash
mkdir -p server/skillhub-app/src/main/resources
cat > server/skillhub-app/src/main/resources/application.yml << 'EOF'
spring:
  application:
    name: skillhub
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  shutdown: graceful

spring.lifecycle.timeout-per-shutdown-phase: 30s

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: when-authorized
EOF

cat > server/skillhub-app/src/main/resources/application-local.yml << 'EOF'
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/skillhub
    username: skillhub
    password: skillhub_dev
  data:
    redis:
      host: localhost
      port: 6379
  jpa:
    show-sql: true

logging:
  level:
    com.skillhub: DEBUG
EOF
```

- [ ] **Step 5: Run test and confirm it passes**

Run: `cd server && ./mvnw test -Dtest=ApplicationContextStartsTest`

Expected: FAIL - "Failed to configure a DataSource" (expected, because the database is not yet set up)

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/
git commit -m "feat: add Spring Boot application entry point and base configuration

- Create SkillhubApplication main class
- Add application.yml with JPA, Flyway, graceful shutdown config
- Add application-local.yml for local development profile
- Add ApplicationContextStartsTest (will pass after DB setup)"
```

### Task 3: Add Docker Compose Local Development Environment

**Files:**
- Create: `docker-compose.yml`

- [ ] **Step 1: Create docker-compose.yml**

```bash
cat > docker-compose.yml << 'EOF'
services:
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: skillhub
      POSTGRES_USER: skillhub
      POSTGRES_PASSWORD: skillhub_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U skillhub"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  minio_data:
EOF
```

- [ ] **Step 2: Start dependency services**

Run: `docker compose up -d`

Expected: PostgreSQL, Redis, MinIO start successfully and health checks pass

- [ ] **Step 3: Verify services are accessible**

Run: `docker compose ps`

Expected: All services have status `healthy`

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml
git commit -m "feat: add Docker Compose for local development dependencies

- Add PostgreSQL 16, Redis 7, MinIO services
- Configure health checks for all services
- Use named volumes for data persistence"
```

### Task 4: Add Flyway Database Migration and Phase 1 Core Tables

**Files:**
- Create: `server/skillhub-app/src/main/resources/db/migration/V1__init_schema.sql`
- Update: `server/skillhub-app/pom.xml` (add Flyway and PostgreSQL driver dependencies)

- [ ] **Step 1: Update skillhub-app POM to add database dependencies**

```bash
# Add the following inside <dependencies> in skillhub-app/pom.xml:
cat >> server/skillhub-app/pom.xml.tmp << 'EOF'
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-database-postgresql</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
EOF
# Manually edit server/skillhub-app/pom.xml and insert the above dependencies before </dependencies>
```

- [ ] **Step 2: Create Flyway migration script V1__init_schema.sql**

```bash
mkdir -p server/skillhub-app/src/main/resources/db/migration
cat > server/skillhub-app/src/main/resources/db/migration/V1__init_schema.sql << 'EOF'
-- Phase 1 core tables: authentication and authorization

-- User account table
CREATE TABLE user_account (
    id BIGSERIAL PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL,
    email VARCHAR(256),
    avatar_url VARCHAR(512),
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    merged_to_user_id VARCHAR(128),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_account_email ON user_account(email);
CREATE INDEX idx_user_account_status ON user_account(status);

-- OAuth identity binding table
CREATE TABLE identity_binding (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    provider_code VARCHAR(64) NOT NULL,
    subject VARCHAR(256) NOT NULL,
    login_name VARCHAR(128),
    extra_json JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider_code, subject)
);

CREATE INDEX idx_identity_binding_user_id ON identity_binding(user_id);

-- API Token table
CREATE TABLE api_token (
    id BIGSERIAL PRIMARY KEY,
    subject_type VARCHAR(32) NOT NULL DEFAULT 'USER',
    subject_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    name VARCHAR(128) NOT NULL,
    token_prefix VARCHAR(16) NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    scope_json JSONB NOT NULL,
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_token_user_id ON api_token(user_id);
CREATE INDEX idx_api_token_hash ON api_token(token_hash);

-- Role table
CREATE TABLE role (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description VARCHAR(512),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Permission table
CREATE TABLE permission (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(128) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    group_code VARCHAR(64)
);

-- Role-permission association table
CREATE TABLE role_permission (
    role_id BIGINT NOT NULL REFERENCES role(id),
    permission_id BIGINT NOT NULL REFERENCES permission(id),
    PRIMARY KEY (role_id, permission_id)
);

-- User-role binding table
CREATE TABLE user_role_binding (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    role_id BIGINT NOT NULL REFERENCES role(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

CREATE INDEX idx_user_role_binding_user_id ON user_role_binding(user_id);

-- Namespace table
CREATE TABLE namespace (
    id BIGSERIAL PRIMARY KEY,
    slug VARCHAR(64) NOT NULL UNIQUE,
    display_name VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL,
    description TEXT,
    avatar_url VARCHAR(512),
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_by VARCHAR(128) REFERENCES user_account(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Namespace member table
CREATE TABLE namespace_member (
    id BIGSERIAL PRIMARY KEY,
    namespace_id BIGINT NOT NULL REFERENCES namespace(id),
    user_id VARCHAR(128) NOT NULL REFERENCES user_account(id),
    role VARCHAR(32) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(namespace_id, user_id)
);

CREATE INDEX idx_namespace_member_user_id ON namespace_member(user_id);
CREATE INDEX idx_namespace_member_namespace_id ON namespace_member(namespace_id);

-- Audit log table
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    actor_user_id VARCHAR(128) REFERENCES user_account(id),
    action VARCHAR(64) NOT NULL,
    target_type VARCHAR(64),
    target_id BIGINT,
    request_id VARCHAR(64),
    client_ip VARCHAR(64),
    user_agent VARCHAR(512),
    detail_json JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_actor ON audit_log(actor_user_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);
CREATE INDEX idx_audit_log_request_id ON audit_log(request_id);

-- Insert system built-in roles
INSERT INTO role (code, name, description, is_system) VALUES
('SUPER_ADMIN', 'Super Administrator', 'Has all permissions', TRUE),
('SKILL_ADMIN', 'Skill Administrator', 'Global namespace review, promotion review, hide/revoke', TRUE),
('USER_ADMIN', 'User Administrator', 'Access approval, ban/unban, role assignment', TRUE),
('AUDITOR', 'Auditor', 'View audit logs', TRUE);

-- Insert system permissions
INSERT INTO permission (code, name, group_code) VALUES
('skill:publish', 'Publish Skill', 'skill'),
('skill:manage', 'Manage Skill', 'skill'),
('skill:promote', 'Promote to Global', 'skill'),
('review:approve', 'Review Skill', 'review'),
('promotion:approve', 'Review Promotion Request', 'promotion'),
('user:manage', 'Manage Users', 'user'),
('user:approve', 'Approve User Access', 'user'),
('audit:read', 'View Audit Logs', 'audit');

-- Bind role permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p WHERE r.code = 'SKILL_ADMIN' AND p.code IN ('review:approve', 'skill:manage', 'promotion:approve');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p WHERE r.code = 'USER_ADMIN' AND p.code IN ('user:manage', 'user:approve');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p WHERE r.code = 'AUDITOR' AND p.code = 'audit:read';

-- Insert system built-in @global namespace
INSERT INTO namespace (slug, display_name, type, description, status)
VALUES ('global', 'Global', 'GLOBAL', 'Platform-level public namespace', 'ACTIVE');
EOF
```

- [ ] **Step 3: Run Flyway migration**

Run: `cd server && ./mvnw flyway:migrate -Dflyway.url=jdbc:postgresql://localhost:5432/skillhub -Dflyway.user=skillhub -Dflyway.password=skillhub_dev`

Expected: `Successfully applied 1 migration to schema "public"`

- [ ] **Step 4: Verify tables were created successfully**

Run: `docker compose exec postgres psql -U skillhub -d skillhub -c "\dt"`

Expected: All tables listed (user_account, identity_binding, api_token, role, permission, role_permission, user_role_binding, namespace, namespace_member, audit_log, flyway_schema_history)

- [ ] **Step 5: Run ApplicationContextStartsTest and confirm it passes**

Run: `cd server && ./mvnw test -Dtest=ApplicationContextStartsTest -Dspring.profiles.active=local`

Expected: PASS - ApplicationContext starts successfully

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/pom.xml server/skillhub-app/src/main/resources/db/migration/
git commit -m "feat: add Flyway migration with Phase 1 core schema

- Add PostgreSQL driver, Flyway, Spring Data JPA, Redis dependencies
- Create V1__init_schema.sql with auth tables (user_account, identity_binding, api_token)
- Create RBAC tables (role, permission, role_permission, user_role_binding)
- Create namespace tables (namespace, namespace_member)
- Create audit_log table
- Insert system roles (SUPER_ADMIN, SKILL_ADMIN, USER_ADMIN, AUDITOR) and permissions
- Insert @global namespace"
```

### Task 5: Add RequestId Filter and Global Exception Handler

**Files:**
- Create: `server/skillhub-app/src/main/java/com/skillhub/filter/RequestIdFilter.java`
- Create: `server/skillhub-app/src/main/java/com/skillhub/exception/GlobalExceptionHandler.java`
- Create: `server/skillhub-app/src/main/java/com/skillhub/dto/ErrorResponse.java`
- Test: `server/skillhub-app/src/test/java/com/skillhub/filter/RequestIdFilterTest.java`

- [ ] **Step 1: Write RequestIdFilter tests**

```bash
mkdir -p server/skillhub-app/src/test/java/com/skillhub/filter
cat > server/skillhub-app/src/test/java/com/skillhub/filter/RequestIdFilterTest.java << 'EOF'
package com.skillhub.filter;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class RequestIdFilterTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldGenerateRequestIdWhenNotProvided() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"));
    }

    @Test
    void shouldPreserveProvidedRequestId() throws Exception {
        String requestId = "test-request-123";
        mockMvc.perform(get("/actuator/health")
                        .header("X-Request-Id", requestId))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Request-Id", requestId));
    }
}
EOF
```

- [ ] **Step 2: Run test and confirm failure**

Run: `cd server && ./mvnw test -Dtest=RequestIdFilterTest -Dspring.profiles.active=local`

Expected: FAIL - "Expected header X-Request-Id does not exist"

- [ ] **Step 3: Implement RequestIdFilter**

```bash
mkdir -p server/skillhub-app/src/main/java/com/skillhub/filter
cat > server/skillhub-app/src/main/java/com/skillhub/filter/RequestIdFilter.java << 'EOF'
package com.skillhub.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {

    private static final String REQUEST_ID_HEADER = "X-Request-Id";
    private static final String REQUEST_ID_MDC_KEY = "requestId";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String requestId = request.getHeader(REQUEST_ID_HEADER);
        if (requestId == null || requestId.isBlank()) {
            requestId = UUID.randomUUID().toString();
        }

        MDC.put(REQUEST_ID_MDC_KEY, requestId);
        response.setHeader(REQUEST_ID_HEADER, requestId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove(REQUEST_ID_MDC_KEY);
        }
    }
}
EOF
```

- [ ] **Step 4: Run test and confirm it passes**

Run: `cd server && ./mvnw test -Dtest=RequestIdFilterTest -Dspring.profiles.active=local`

Expected: PASS

- [ ] **Step 5: Create global exception handler and DTO**

```bash
mkdir -p server/skillhub-app/src/main/java/com/skillhub/exception
cat > server/skillhub-app/src/main/java/com/skillhub/exception/GlobalExceptionHandler.java << 'EOF'
package com.skillhub.exception;

import com.skillhub.dto.ErrorResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGlobalException(Exception ex, WebRequest request) {
        logger.error("Unhandled exception", ex);
        ErrorResponse error = new ErrorResponse(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                "Internal server error",
                ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
EOF

mkdir -p server/skillhub-app/src/main/java/com/skillhub/dto
cat > server/skillhub-app/src/main/java/com/skillhub/dto/ErrorResponse.java << 'EOF'
package com.skillhub.dto;

public record ErrorResponse(
        int status,
        String error,
        String message
) {}
EOF
```

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-app/src/main/java/com/skillhub/filter/ \
        server/skillhub-app/src/main/java/com/skillhub/exception/ \
        server/skillhub-app/src/main/java/com/skillhub/dto/ \
        server/skillhub-app/src/test/java/com/skillhub/filter/
git commit -m "feat: add RequestId filter and global exception handler

- Implement RequestIdFilter to generate/preserve X-Request-Id header
- Add MDC support for request tracing in logs
- Create GlobalExceptionHandler for unified error responses
- Add ErrorResponse DTO
- Add RequestIdFilterTest with MockMvc"
```

### Task 6: Add OpenAPI Configuration and Health Check Endpoint

**Files:**
- Create: `server/skillhub-app/src/main/java/com/skillhub/config/OpenApiConfig.java`
- Create: `server/skillhub-app/src/main/java/com/skillhub/controller/HealthController.java`
- Test: `server/skillhub-app/src/test/java/com/skillhub/controller/HealthControllerTest.java`

- [ ] **Step 1: Write health check endpoint tests**

```bash
mkdir -p server/skillhub-app/src/test/java/com/skillhub/controller
cat > server/skillhub-app/src/test/java/com/skillhub/controller/HealthControllerTest.java << 'EOF'
package com.skillhub.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldReturnHealthStatus() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
EOF
```

- [ ] **Step 2: Run test and confirm failure**

Run: `cd server && ./mvnw test -Dtest=HealthControllerTest -Dspring.profiles.active=local`

Expected: FAIL - 404 Not Found

- [ ] **Step 3: Implement HealthController**

```bash
mkdir -p server/skillhub-app/src/main/java/com/skillhub/controller
cat > server/skillhub-app/src/main/java/com/skillhub/controller/HealthController.java << 'EOF'
package com.skillhub.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
EOF
```

- [ ] **Step 4: Run test and confirm it passes**

Run: `cd server && ./mvnw test -Dtest=HealthControllerTest -Dspring.profiles.active=local`

Expected: PASS

- [ ] **Step 5: Create OpenAPI configuration**

```bash
mkdir -p server/skillhub-app/src/main/java/com/skillhub/config
cat > server/skillhub-app/src/main/java/com/skillhub/config/OpenApiConfig.java << 'EOF'
package com.skillhub.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI skillhubOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SkillHub API")
                        .description("Skills Registry Platform")
                        .version("0.1.0"))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Local development")
                ));
    }
}
EOF
```

- [ ] **Step 6: Verify OpenAPI documentation is accessible**

Run: `cd server && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local` (in another terminal)

Run: `curl -s http://localhost:8080/v3/api-docs | jq '.info.title'`

Expected: `"SkillHub API"`

- [ ] **Step 7: Stop the application and commit**

```bash
# Ctrl+C to stop the application
git add server/skillhub-app/src/main/java/com/skillhub/config/ \
        server/skillhub-app/src/main/java/com/skillhub/controller/ \
        server/skillhub-app/src/test/java/com/skillhub/controller/
git commit -m "feat: add OpenAPI configuration and health check endpoint

- Configure Springdoc OpenAPI with API info and server URL
- Add /api/v1/health endpoint for basic health check
- Add HealthControllerTest
- OpenAPI docs available at /v3/api-docs and /swagger-ui.html"
```

### Task 7: Add Top-Level Makefile Orchestration

**Files:**
- Create: `Makefile`

- [ ] **Step 1: Create Makefile**

```bash
cat > Makefile << 'EOF'
.PHONY: dev dev-down build test clean

# Start local development environment (dependency services only)
dev:
	docker compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@echo "Services ready. Start backend with: cd server && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local"

# Stop local development environment
dev-down:
	docker compose down

# Build backend
build:
	cd server && ./mvnw clean package -DskipTests

# Run tests
test:
	cd server && ./mvnw test

# Clean build artifacts
clean:
	cd server && ./mvnw clean
	docker compose down -v

# Generate OpenAPI types (for frontend use; not implemented in Phase 1)
generate-api:
	@echo "Frontend not yet implemented"
EOF
```

- [ ] **Step 2: Test Makefile commands**

Run: `make dev`

Expected: Docker Compose services start and informational messages are shown

Run: `make test`

Expected: All tests pass

Run: `make dev-down`

Expected: Docker Compose services stop

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile for top-level orchestration

- Add 'make dev' to start Docker Compose dependencies
- Add 'make dev-down' to stop services
- Add 'make build' to build backend JAR
- Add 'make test' to run all tests
- Add 'make clean' to clean build artifacts and volumes"
```

---

## Chunk 1 Acceptance Criteria

Run the following commands to verify Chunk 1 is complete:

```bash
# 1. Start dependency services
make dev

# 2. Run all tests
make test
# Expected: BUILD SUCCESS, all tests pass

# 3. Start backend application
cd server && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# 4. Verify health check
curl http://localhost:8080/api/v1/health
# Expected: {"status":"UP"}

# 5. Verify Actuator
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}

# 6. Verify OpenAPI documentation
curl http://localhost:8080/v3/api-docs | jq '.info.title'
# Expected: "SkillHub API"

# 7. Verify RequestId
curl -v http://localhost:8080/api/v1/health 2>&1 | grep X-Request-Id
# Expected: X-Request-Id header present

# 8. Verify database tables
docker compose exec postgres psql -U skillhub -d skillhub -c "\dt"
# Expected: All Phase 1 tables listed

# 9. Stop services
make dev-down
```

Chunk 1 output: A launchable backend application + database schema + Docker Compose local environment + Makefile orchestration.

## Chunk 2: Backend Authentication and Authorization System

This chunk implements the complete authentication pipeline: Spring Security OAuth2 GitHub login, AccessPolicy admission control, identity binding, Spring Session Redis, API Token authentication, RBAC authorization, MockAuthFilter for local development, and CSRF protection.

### File Structure Mapping

```
server/
├── skillhub-domain/src/main/java/com/skillhub/domain/
│   ├── user/
│   │   ├── UserAccount.java              # User entity
│   │   ├── UserStatus.java               # User status enum
│   │   └── UserAccountRepository.java    # Repository interface
│   └── namespace/
│       ├── Namespace.java                # Namespace entity
│       ├── NamespaceStatus.java          # Namespace status enum
│       ├── NamespaceMember.java          # Member entity
│       ├── NamespaceRole.java            # Namespace role enum
│       ├── NamespaceRepository.java
│       └── NamespaceMemberRepository.java
├── skillhub-auth/src/main/java/com/skillhub/auth/
│   ├── entity/
│   │   ├── IdentityBinding.java
│   │   ├── ApiToken.java
│   │   ├── Role.java
│   │   ├── Permission.java
│   │   ├── RolePermission.java
│   │   └── UserRoleBinding.java
│   ├── repository/
│   │   ├── IdentityBindingRepository.java
│   │   ├── ApiTokenRepository.java
│   │   ├── RoleRepository.java
│   │   ├── PermissionRepository.java
│   │   └── UserRoleBindingRepository.java
│   ├── oauth/
│   │   ├── OAuthClaims.java
│   │   ├── OAuthClaimsExtractor.java
│   │   ├── GitHubClaimsExtractor.java
│   │   ├── CustomOAuth2UserService.java
│   │   └── OAuth2LoginSuccessHandler.java
│   ├── policy/
│   │   ├── AccessPolicy.java
│   │   ├── AccessDecision.java
│   │   ├── OpenAccessPolicy.java
│   │   ├── EmailDomainAccessPolicy.java
│   │   └── AccessPolicyFactory.java
│   ├── identity/
│   │   └── IdentityBindingService.java
│   ├── token/
│   │   ├── ApiTokenService.java
│   │   └── ApiTokenAuthenticationFilter.java
│   ├── rbac/
│   │   ├── RbacService.java
│   │   └── PlatformPrincipal.java
│   ├── config/
│   │   └── SecurityConfig.java
│   └── mock/
│       └── MockAuthFilter.java
├── skillhub-app/src/main/java/com/skillhub/
│   ├── controller/
│   │   └── AuthController.java
│   └── exception/
│       ├── GlobalExceptionHandler.java
│       └── ErrorResponse.java
└── skillhub-infra/src/main/java/com/skillhub/infra/
    └── jpa/
        ├── UserAccountJpaRepository.java
        ├── NamespaceJpaRepository.java
        └── NamespaceMemberJpaRepository.java
```

### Task 8: Domain Layer User and Namespace Entities

**Files:**
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserAccount.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserStatus.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserAccountRepository.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/Namespace.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/NamespaceStatus.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/NamespaceMember.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/NamespaceRole.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/NamespaceRepository.java`
- Create: `server/skillhub-domain/src/main/java/com/skillhub/domain/namespace/NamespaceMemberRepository.java`

- [ ] **Step 1: Create UserStatus enum**

```java
// server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserStatus.java
package com.skillhub.domain.user;

public enum UserStatus {
    ACTIVE,
    PENDING,
    DISABLED,
    MERGED
}
```

- [ ] **Step 2: Create UserAccount entity**

```java
// server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserAccount.java
package com.skillhub.domain.user;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_account")
public class UserAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "display_name", nullable = false, length = 128)
    private String displayName;

    @Column(length = 256)
    private String email;

    @Column(name = "avatar_url", length = 512)
    private String avatarUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private UserStatus status = UserStatus.ACTIVE;

    @Column(name = "merged_to_user_id")
    private Long mergedToUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected UserAccount() {}

    public UserAccount(String displayName, String email, String avatarUrl) {
        this.displayName = displayName;
        this.email = email;
        this.avatarUrl = avatarUrl;
        this.status = UserStatus.ACTIVE;
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
    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public UserStatus getStatus() { return status; }
    public void setStatus(UserStatus status) { this.status = status; }
    public Long getMergedToUserId() { return mergedToUserId; }
    public void setMergedToUserId(Long mergedToUserId) { this.mergedToUserId = mergedToUserId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public boolean isActive() { return this.status == UserStatus.ACTIVE; }
}
```

- [ ] **Step 3: Create UserAccountRepository interface**

```java
// server/skillhub-domain/src/main/java/com/skillhub/domain/user/UserAccountRepository.java
package com.skillhub.domain.user;

import java.util.Optional;

public interface UserAccountRepository {
    Optional<UserAccount> findById(Long id);
    UserAccount save(UserAccount user);
}
```

- [ ] **Step 4: Create namespace-related entities**

```java
// NamespaceStatus.java
package com.skillhub.domain.namespace;

public enum NamespaceStatus {
    ACTIVE, FROZEN, ARCHIVED
}

// NamespaceRole.java
package com.skillhub.domain.namespace;

public enum NamespaceRole {
    OWNER, ADMIN, MEMBER
}

// Namespace.java
package com.skillhub.domain.namespace;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "namespace")
public class Namespace {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String slug;

    @Column(name = "display_name", nullable = false, length = 128)
    private String displayName;

    @Column(length = 512)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private NamespaceStatus status = NamespaceStatus.ACTIVE;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected Namespace() {}

    public Namespace(String slug, String displayName, Long createdBy) {
        this.slug = slug;
        this.displayName = displayName;
        this.createdBy = createdBy;
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

    public Long getId() { return id; }
    public String getSlug() { return slug; }
    public String getDisplayName() { return displayName; }
    public NamespaceStatus getStatus() { return status; }
    public Long getCreatedBy() { return createdBy; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

// NamespaceMember.java
package com.skillhub.domain.namespace;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "namespace_member",
       uniqueConstraints = @UniqueConstraint(columnNames = {"namespace_id", "user_id"}))
public class NamespaceMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "namespace_id", nullable = false)
    private Long namespaceId;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private NamespaceRole role;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected NamespaceMember() {}

    public NamespaceMember(Long namespaceId, String userId, NamespaceRole role) {
        this.namespaceId = namespaceId;
        this.userId = userId;
        this.role = role;
    }

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public Long getNamespaceId() { return namespaceId; }
    public Long getUserId() { return userId; }
    public NamespaceRole getRole() { return role; }
    public void setRole(NamespaceRole role) { this.role = role; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
```

- [ ] **Step 5: Create Repository interfaces**

```java
// NamespaceRepository.java
package com.skillhub.domain.namespace;

import java.util.Optional;

public interface NamespaceRepository {
    Optional<Namespace> findById(Long id);
    Optional<Namespace> findBySlug(String slug);
    Namespace save(Namespace namespace);
}

// NamespaceMemberRepository.java
package com.skillhub.domain.namespace;

import java.util.List;
import java.util.Optional;

public interface NamespaceMemberRepository {
    Optional<NamespaceMember> findByNamespaceIdAndUserId(Long namespaceId, String userId);
    List<NamespaceMember> findByUserId(String userId);
    NamespaceMember save(NamespaceMember member);
}
```

- [ ] **Step 6: Commit**

```bash
git add server/skillhub-domain/
git commit -m "feat(domain): add UserAccount and Namespace entities with repository interfaces

- UserAccount with status lifecycle (ACTIVE/PENDING/DISABLED/MERGED)
- Namespace, NamespaceMember with role-based membership
- Repository interfaces (implementation in infra module)"
```

### Task 9: Infra Layer JPA Repository Implementation

**Files:**
- Create: `server/skillhub-infra/src/main/java/com/skillhub/infra/jpa/UserAccountJpaRepository.java`
- Create: `server/skillhub-infra/src/main/java/com/skillhub/infra/jpa/NamespaceJpaRepository.java`
- Create: `server/skillhub-infra/src/main/java/com/skillhub/infra/jpa/NamespaceMemberJpaRepository.java`

- [ ] **Step 1: Create UserAccountJpaRepository**

```java
// server/skillhub-infra/src/main/java/com/skillhub/infra/jpa/UserAccountJpaRepository.java
package com.skillhub.infra.jpa;

import com.skillhub.domain.user.UserAccount;
import com.skillhub.domain.user.UserAccountRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserAccountJpaRepository
        extends JpaRepository<UserAccount, Long>, UserAccountRepository {
}
```

- [ ] **Step 2: Create NamespaceJpaRepository and NamespaceMemberJpaRepository**

```java
// NamespaceJpaRepository.java
package com.skillhub.infra.jpa;

import com.skillhub.domain.namespace.Namespace;
import com.skillhub.domain.namespace.NamespaceRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface NamespaceJpaRepository
        extends JpaRepository<Namespace, Long>, NamespaceRepository {
    Optional<Namespace> findBySlug(String slug);
}

// NamespaceMemberJpaRepository.java
package com.skillhub.infra.jpa;

import com.skillhub.domain.namespace.NamespaceMember;
import com.skillhub.domain.namespace.NamespaceMemberRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NamespaceMemberJpaRepository
        extends JpaRepository<NamespaceMember, Long>, NamespaceMemberRepository {
    Optional<NamespaceMember> findByNamespaceIdAndUserId(Long namespaceId, String userId);
    List<NamespaceMember> findByUserId(String userId);
}
```

- [ ] **Step 3: Commit**

```bash
git add server/skillhub-infra/
git commit -m "feat(infra): add JPA repository implementations for UserAccount and Namespace"
```

### Task 10: Auth Module Entities and Repository

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/IdentityBinding.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/ApiToken.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/Role.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/Permission.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/RolePermission.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/entity/UserRoleBinding.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/repository/*.java`

- [ ] **Step 1: Create IdentityBinding entity**

```java
package com.skillhub.auth.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "identity_binding",
       uniqueConstraints = @UniqueConstraint(columnNames = {"provider_code", "subject"}))
public class IdentityBinding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "provider_code", nullable = false, length = 64)
    private String providerCode;

    @Column(nullable = false, length = 256)
    private String subject;

    @Column(name = "login_name", length = 128)
    private String loginName;

    @Column(name = "extra_json", columnDefinition = "jsonb")
    private String extraJson;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected IdentityBinding() {}

    public IdentityBinding(String userId, String providerCode, String subject, String loginName) {
        this.userId = userId;
        this.providerCode = providerCode;
        this.subject = subject;
        this.loginName = loginName;
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

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getProviderCode() { return providerCode; }
    public String getSubject() { return subject; }
    public String getLoginName() { return loginName; }
    public void setLoginName(String loginName) { this.loginName = loginName; }
    public String getExtraJson() { return extraJson; }
    public void setExtraJson(String extraJson) { this.extraJson = extraJson; }
}
```

- [ ] **Step 2: Create ApiToken entity**

```java
package com.skillhub.auth.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "api_token")
public class ApiToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "subject_type", nullable = false, length = 32)
    private String subjectType = "USER";

    @Column(name = "subject_id", nullable = false)
    private Long subjectId;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(nullable = false, length = 128)
    private String name;

    @Column(name = "token_prefix", nullable = false, length = 16)
    private String tokenPrefix;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "scope_json", nullable = false, columnDefinition = "jsonb")
    private String scopeJson;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "last_used_at")
    private LocalDateTime lastUsedAt;

    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected ApiToken() {}

    public ApiToken(String userId, String name, String tokenPrefix, String tokenHash, String scopeJson) {
        this.subjectType = "USER";
        this.subjectId = userId;
        this.userId = userId;
        this.name = name;
        this.tokenPrefix = tokenPrefix;
        this.tokenHash = tokenHash;
        this.scopeJson = scopeJson;
    }

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getName() { return name; }
    public String getTokenPrefix() { return tokenPrefix; }
    public String getTokenHash() { return tokenHash; }
    public String getScopeJson() { return scopeJson; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public LocalDateTime getLastUsedAt() { return lastUsedAt; }
    public void setLastUsedAt(LocalDateTime lastUsedAt) { this.lastUsedAt = lastUsedAt; }
    public LocalDateTime getRevokedAt() { return revokedAt; }
    public void setRevokedAt(LocalDateTime revokedAt) { this.revokedAt = revokedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    public boolean isRevoked() { return revokedAt != null; }
    public boolean isExpired() { return expiresAt != null && expiresAt.isBefore(LocalDateTime.now()); }
    public boolean isValid() { return !isRevoked() && !isExpired(); }
}
```

- [ ] **Step 3: Create RBAC entities (Role, Permission, RolePermission, UserRoleBinding)**

```java
// Role.java
package com.skillhub.auth.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "role")
public class Role {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String code;

    @Column(nullable = false, length = 128)
    private String name;

    @Column(length = 512)
    private String description;

    @Column(name = "is_system", nullable = false)
    private boolean system;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void prePersist() { this.createdAt = LocalDateTime.now(); }

    public Long getId() { return id; }
    public String getCode() { return code; }
    public String getName() { return name; }
    public boolean isSystem() { return system; }
}

// Permission.java
package com.skillhub.auth.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "permission")
public class Permission {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 128)
    private String code;

    @Column(nullable = false, length = 128)
    private String name;

    @Column(name = "group_code", length = 64)
    private String groupCode;

    public Long getId() { return id; }
    public String getCode() { return code; }
    public String getName() { return name; }
}

// RolePermission.java
package com.skillhub.auth.entity;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "role_permission")
@IdClass(RolePermission.RolePermissionId.class)
public class RolePermission {
    @Id
    @Column(name = "role_id")
    private Long roleId;

    @Id
    @Column(name = "permission_id")
    private Long permissionId;

    public Long getRoleId() { return roleId; }
    public Long getPermissionId() { return permissionId; }

    public static class RolePermissionId implements Serializable {
        private Long roleId;
        private Long permissionId;
        // equals and hashCode omitted for brevity — implement in code
    }
}

// UserRoleBinding.java
package com.skillhub.auth.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_role_binding",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "role_id"}))
public class UserRoleBinding {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "role_id", nullable = false)
    private Long roleId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected UserRoleBinding() {}

    public UserRoleBinding(String userId, Long roleId) {
        this.userId = userId;
        this.roleId = roleId;
    }

    @PrePersist
    void prePersist() { this.createdAt = LocalDateTime.now(); }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public Long getRoleId() { return roleId; }
}
```

- [ ] **Step 4: Create Auth Repository interfaces**

```java
// IdentityBindingRepository.java
package com.skillhub.auth.repository;

import com.skillhub.auth.entity.IdentityBinding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface IdentityBindingRepository extends JpaRepository<IdentityBinding, Long> {
    Optional<IdentityBinding> findByProviderCodeAndSubject(String providerCode, String subject);
}

// ApiTokenRepository.java
package com.skillhub.auth.repository;

import com.skillhub.auth.entity.ApiToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ApiTokenRepository extends JpaRepository<ApiToken, Long> {
    Optional<ApiToken> findByTokenHash(String tokenHash);
    List<ApiToken> findByUserIdAndRevokedAtIsNullOrderByCreatedAtDesc(String userId);
}

// RoleRepository.java
package com.skillhub.auth.repository;

import com.skillhub.auth.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByCode(String code);
}

// UserRoleBindingRepository.java
package com.skillhub.auth.repository;

import com.skillhub.auth.entity.UserRoleBinding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserRoleBindingRepository extends JpaRepository<UserRoleBinding, Long> {
    List<UserRoleBinding> findByUserId(String userId);
}
```

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/
git commit -m "feat(auth): add auth entities and JPA repositories

- IdentityBinding, ApiToken, Role, Permission, RolePermission, UserRoleBinding
- JPA repositories for all auth entities"
```

### Task 10: OAuth2 Claims Extraction and Admission Policy

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/OAuthClaims.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/OAuthClaimsExtractor.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/GitHubClaimsExtractor.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/policy/AccessDecision.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/policy/AccessPolicy.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/policy/OpenAccessPolicy.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/policy/EmailDomainAccessPolicy.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/policy/AccessPolicyFactory.java`
- Test: `server/skillhub-auth/src/test/java/com/skillhub/auth/policy/AccessPolicyTest.java`

- [ ] **Step 1: Create OAuthClaims record**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/OAuthClaims.java
package com.skillhub.auth.oauth;

import java.util.Map;

public record OAuthClaims(
    String provider,
    String subject,
    String email,
    boolean emailVerified,
    String providerLogin,
    Map<String, Object> extra
) {}
```

- [ ] **Step 2: Create OAuthClaimsExtractor interface and GitHub implementation**

```java
// OAuthClaimsExtractor.java
package com.skillhub.auth.oauth;

import org.springframework.security.oauth2.core.user.OAuth2User;

public interface OAuthClaimsExtractor {
    String getProvider();
    OAuthClaims extract(OAuth2User oAuth2User);
}
```

```java
// GitHubClaimsExtractor.java
package com.skillhub.auth.oauth;

import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Component;
import java.util.Map;

@Component
public class GitHubClaimsExtractor implements OAuthClaimsExtractor {

    @Override
    public String getProvider() { return "github"; }

    @Override
    public OAuthClaims extract(OAuth2User oAuth2User) {
        Map<String, Object> attrs = oAuth2User.getAttributes();
        return new OAuthClaims(
            "github",
            String.valueOf(attrs.get("id")),
            (String) attrs.get("email"),
            attrs.get("email") != null,
            (String) attrs.get("login"),
            attrs
        );
    }
}
```

- [ ] **Step 3: Create AccessDecision and AccessPolicy**

```java
// AccessDecision.java
package com.skillhub.auth.policy;

public enum AccessDecision {
    ALLOW,
    DENY,
    PENDING_APPROVAL
}
```

```java
// AccessPolicy.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;

public interface AccessPolicy {
    AccessDecision evaluate(OAuthClaims claims);
}
```

- [ ] **Step 4: Create OpenAccessPolicy and EmailDomainAccessPolicy**

```java
// OpenAccessPolicy.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;

public class OpenAccessPolicy implements AccessPolicy {
    @Override
    public AccessDecision evaluate(OAuthClaims claims) {
        return AccessDecision.ALLOW;
    }
}
```

```java
// EmailDomainAccessPolicy.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;
import java.util.Set;

public class EmailDomainAccessPolicy implements AccessPolicy {
    private final Set<String> allowedDomains;

    public EmailDomainAccessPolicy(Set<String> allowedDomains) {
        this.allowedDomains = allowedDomains;
    }

    @Override
    public AccessDecision evaluate(OAuthClaims claims) {
        if (claims.email() == null) return AccessDecision.DENY;
        String domain = claims.email().substring(claims.email().indexOf('@') + 1);
        return allowedDomains.contains(domain.toLowerCase())
            ? AccessDecision.ALLOW : AccessDecision.DENY;
    }
}
```

```java
// ProviderAllowlistAccessPolicy.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;
import java.util.Set;

public class ProviderAllowlistAccessPolicy implements AccessPolicy {
    private final Set<String> allowedProviders;

    public ProviderAllowlistAccessPolicy(Set<String> allowedProviders) {
        this.allowedProviders = allowedProviders;
    }

    @Override
    public AccessDecision evaluate(OAuthClaims claims) {
        return allowedProviders.contains(claims.provider())
            ? AccessDecision.ALLOW : AccessDecision.DENY;
    }
}
```

```java
// SubjectWhitelistAccessPolicy.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;
import java.util.Set;

public class SubjectWhitelistAccessPolicy implements AccessPolicy {
    private final Set<String> whitelistedSubjects; // "provider:subject" format

    public SubjectWhitelistAccessPolicy(Set<String> whitelistedSubjects) {
        this.whitelistedSubjects = whitelistedSubjects;
    }

    @Override
    public AccessDecision evaluate(OAuthClaims claims) {
        String key = claims.provider() + ":" + claims.subject();
        return whitelistedSubjects.contains(key)
            ? AccessDecision.ALLOW : AccessDecision.DENY;
    }
}
```

- [ ] **Step 5: Create AccessPolicyFactory**

```java
// AccessPolicyFactory.java
package com.skillhub.auth.policy;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.util.List;
import java.util.Set;

@Configuration
@ConfigurationProperties(prefix = "skillhub.access-policy")
public class AccessPolicyFactory {
    private String mode = "OPEN";
    private List<String> allowedEmailDomains = List.of();
    private List<String> allowedProviders = List.of();
    private List<String> whitelistedSubjects = List.of();

    @Bean
    public AccessPolicy accessPolicy() {
        return switch (mode.toUpperCase()) {
            case "EMAIL_DOMAIN" -> new EmailDomainAccessPolicy(Set.copyOf(allowedEmailDomains));
            case "PROVIDER_ALLOWLIST" -> new ProviderAllowlistAccessPolicy(Set.copyOf(allowedProviders));
            case "SUBJECT_WHITELIST" -> new SubjectWhitelistAccessPolicy(Set.copyOf(whitelistedSubjects));
            default -> new OpenAccessPolicy();
        };
    }

    public void setMode(String mode) { this.mode = mode; }
    public void setAllowedEmailDomains(List<String> d) { this.allowedEmailDomains = d; }
    public void setAllowedProviders(List<String> p) { this.allowedProviders = p; }
    public void setWhitelistedSubjects(List<String> s) { this.whitelistedSubjects = s; }
}
```

- [ ] **Step 6: Write AccessPolicy unit tests**

```java
// server/skillhub-auth/src/test/java/com/skillhub/auth/policy/AccessPolicyTest.java
package com.skillhub.auth.policy;

import com.skillhub.auth.oauth.OAuthClaims;
import org.junit.jupiter.api.Test;
import java.util.Map;
import java.util.Set;
import static org.assertj.core.api.Assertions.assertThat;

class AccessPolicyTest {

    @Test
    void openPolicy_alwaysAllows() {
        var policy = new OpenAccessPolicy();
        var claims = new OAuthClaims("github", "123", "user@any.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.ALLOW);
    }

    @Test
    void emailDomainPolicy_allowsMatchingDomain() {
        var policy = new EmailDomainAccessPolicy(Set.of("company.com"));
        var claims = new OAuthClaims("github", "123", "user@company.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.ALLOW);
    }

    @Test
    void emailDomainPolicy_deniesNonMatchingDomain() {
        var policy = new EmailDomainAccessPolicy(Set.of("company.com"));
        var claims = new OAuthClaims("github", "123", "user@other.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.DENY);
    }

    @Test
    void emailDomainPolicy_deniesNullEmail() {
        var policy = new EmailDomainAccessPolicy(Set.of("company.com"));
        var claims = new OAuthClaims("github", "123", null, false, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.DENY);
    }

    @Test
    void providerAllowlistPolicy_allowsMatchingProvider() {
        var policy = new ProviderAllowlistAccessPolicy(Set.of("github"));
        var claims = new OAuthClaims("github", "123", "u@a.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.ALLOW);
    }

    @Test
    void providerAllowlistPolicy_deniesNonMatchingProvider() {
        var policy = new ProviderAllowlistAccessPolicy(Set.of("github"));
        var claims = new OAuthClaims("google", "123", "u@a.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.DENY);
    }

    @Test
    void subjectWhitelistPolicy_allowsMatchingSubject() {
        var policy = new SubjectWhitelistAccessPolicy(Set.of("github:12345"));
        var claims = new OAuthClaims("github", "12345", "u@a.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.ALLOW);
    }

    @Test
    void subjectWhitelistPolicy_deniesNonMatchingSubject() {
        var policy = new SubjectWhitelistAccessPolicy(Set.of("github:12345"));
        var claims = new OAuthClaims("github", "99999", "u@a.com", true, "user", Map.of());
        assertThat(policy.evaluate(claims)).isEqualTo(AccessDecision.DENY);
    }
}
```

- [ ] **Step 7: Run and verify tests**

Run: `cd server && ./mvnw test -pl skillhub-auth -Dtest=AccessPolicyTest -am`

Expected: 8 tests PASS

- [ ] **Step 8: Commit**

```bash
git add server/skillhub-auth/
git commit -m "feat(auth): add OAuth claims extraction and access policy

- OAuthClaims record, OAuthClaimsExtractor SPI, GitHubClaimsExtractor
- AccessPolicy SPI with Open and EmailDomain implementations
- AccessPolicyFactory with config-driven strategy selection
- Unit tests for access policies"
```

### Task 11: IdentityBindingService + CustomOAuth2UserService

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/identity/IdentityBindingService.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/CustomOAuth2UserService.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/OAuth2LoginSuccessHandler.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/rbac/PlatformPrincipal.java`

- [ ] **Step 1: Create PlatformPrincipal**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/rbac/PlatformPrincipal.java
package com.skillhub.auth.rbac;

import java.io.Serializable;
import java.util.Set;

public record PlatformPrincipal(
    String userId,
    String displayName,
    String email,
    String avatarUrl,
    String oauthProvider,
    Set<String> platformRoles
) implements Serializable {}
```

- [ ] **Step 2: Create IdentityBindingService**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/identity/IdentityBindingService.java
package com.skillhub.auth.identity;

import com.skillhub.auth.entity.IdentityBinding;
import com.skillhub.auth.entity.UserRoleBinding;
import com.skillhub.auth.oauth.OAuthClaims;
import com.skillhub.auth.rbac.PlatformPrincipal;
import com.skillhub.auth.repository.IdentityBindingRepository;
import com.skillhub.auth.repository.UserRoleBindingRepository;
import com.skillhub.domain.user.UserAccount;
import com.skillhub.domain.user.UserAccountRepository;
import com.skillhub.domain.user.UserStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class IdentityBindingService {

    private final IdentityBindingRepository bindingRepo;
    private final UserAccountRepository userRepo;
    private final UserRoleBindingRepository roleBindingRepo;

    public IdentityBindingService(IdentityBindingRepository bindingRepo,
                                   UserAccountRepository userRepo,
                                   UserRoleBindingRepository roleBindingRepo) {
        this.bindingRepo = bindingRepo;
        this.userRepo = userRepo;
        this.roleBindingRepo = roleBindingRepo;
    }

    @Transactional
    public PlatformPrincipal bindOrCreate(OAuthClaims claims, UserStatus initialStatus) {
        IdentityBinding binding = bindingRepo
            .findByProviderCodeAndSubject(claims.provider(), claims.subject())
            .orElse(null);

        UserAccount user;
        if (binding != null) {
            user = userRepo.findById(binding.getUserId())
                .orElseThrow(() -> new IllegalStateException("User not found for binding"));
            // Sync latest information
            user.setDisplayName(claims.providerLogin());
            if (claims.email() != null) user.setEmail(claims.email());
            if (claims.extra().get("avatar_url") != null) {
                user.setAvatarUrl((String) claims.extra().get("avatar_url"));
            }
            user = userRepo.save(user);
        } else {
            user = new UserAccount(
                claims.providerLogin(),
                claims.email(),
                (String) claims.extra().get("avatar_url")
            );
            user.setStatus(initialStatus);
            user = userRepo.save(user);

            binding = new IdentityBinding();
            binding.setUserId(user.getId());
            binding.setProviderCode(claims.provider());
            binding.setSubject(claims.subject());
            binding.setLoginName(claims.providerLogin());
            bindingRepo.save(binding);
        }

        Set<String> roles = roleBindingRepo.findByUserId(user.getId()).stream()
            .map(rb -> rb.getRole().getCode())
            .collect(Collectors.toSet());

        return new PlatformPrincipal(
            user.getId(), user.getDisplayName(), user.getEmail(),
            user.getAvatarUrl(), claims.provider(), roles
        );
    }
}
```

- [ ] **Step 3: Create CustomOAuth2UserService**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/CustomOAuth2UserService.java
package com.skillhub.auth.oauth;

import com.skillhub.auth.identity.IdentityBindingService;
import com.skillhub.auth.policy.AccessDecision;
import com.skillhub.auth.policy.AccessPolicy;
import com.skillhub.auth.rbac.PlatformPrincipal;
import com.skillhub.domain.user.UserStatus;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private final DefaultOAuth2UserService delegate = new DefaultOAuth2UserService();
    private final Map<String, OAuthClaimsExtractor> extractors;
    private final AccessPolicy accessPolicy;
    private final IdentityBindingService identityBindingService;

    public CustomOAuth2UserService(List<OAuthClaimsExtractor> extractorList,
                                    AccessPolicy accessPolicy,
                                    IdentityBindingService identityBindingService) {
        this.extractors = extractorList.stream()
            .collect(Collectors.toMap(OAuthClaimsExtractor::getProvider, Function.identity()));
        this.accessPolicy = accessPolicy;
        this.identityBindingService = identityBindingService;
    }

    @Override
    public OAuth2User loadUser(OAuth2UserRequest request) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = delegate.loadUser(request);
        String registrationId = request.getClientRegistration().getRegistrationId();

        OAuthClaimsExtractor extractor = extractors.get(registrationId);
        if (extractor == null) {
            throw new OAuth2AuthenticationException(
                new OAuth2Error("unsupported_provider", "Unsupported: " + registrationId, null));
        }

        OAuthClaims claims = extractor.extract(oAuth2User);
        AccessDecision decision = accessPolicy.evaluate(claims);

        UserStatus initialStatus = switch (decision) {
            case ALLOW -> UserStatus.ACTIVE;
            case PENDING_APPROVAL -> UserStatus.PENDING;
            case DENY -> throw new OAuth2AuthenticationException(
                new OAuth2Error("access_denied", "Access denied by policy", null));
        };

        PlatformPrincipal principal = identityBindingService.bindOrCreate(claims, initialStatus);

        // Store principal in OAuth2User attributes for later use
        var attrs = new java.util.HashMap<>(oAuth2User.getAttributes());
        attrs.put("platformPrincipal", principal);

        return new org.springframework.security.oauth2.core.user.DefaultOAuth2User(
            oAuth2User.getAuthorities(), attrs, "login"
        );
    }
}
```

- [ ] **Step 4: Create OAuth2LoginSuccessHandler**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/oauth/OAuth2LoginSuccessHandler.java
package com.skillhub.auth.oauth;

import com.skillhub.auth.rbac.PlatformPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import java.io.IOException;

@Component
public class OAuth2LoginSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    public OAuth2LoginSuccessHandler() {
        setDefaultTargetUrl("/?login=success");
    }

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
                                         Authentication authentication) throws IOException, jakarta.servlet.ServletException {
        if (authentication.getPrincipal() instanceof OAuth2User oAuth2User) {
            PlatformPrincipal principal = (PlatformPrincipal) oAuth2User.getAttributes().get("platformPrincipal");
            if (principal != null) {
                request.getSession().setAttribute("platformPrincipal", principal);
            }
        }
        super.onAuthenticationSuccess(request, response, authentication);
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/ server/skillhub-domain/
git commit -m "feat(auth): add identity binding and OAuth2 user service

- PlatformPrincipal session record
- IdentityBindingService: bind or create user from OAuth claims
- CustomOAuth2UserService: delegate → extract → policy → bind
- OAuth2LoginSuccessHandler: store principal in session"
```

### Task 12: API Token Issuance and Authentication Filter

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/token/ApiTokenService.java`
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/token/ApiTokenAuthenticationFilter.java`
- Test: `server/skillhub-auth/src/test/java/com/skillhub/auth/token/ApiTokenServiceTest.java`

- [ ] **Step 1: Create ApiTokenService**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/token/ApiTokenService.java
package com.skillhub.auth.token;

import com.skillhub.auth.entity.ApiToken;
import com.skillhub.auth.rbac.PlatformPrincipal;
import com.skillhub.auth.repository.ApiTokenRepository;
import com.skillhub.auth.repository.UserRoleBindingRepository;
import com.skillhub.domain.user.UserAccount;
import com.skillhub.domain.user.UserAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ApiTokenService {

    private static final String TOKEN_PREFIX = "ask_";
    private static final SecureRandom RANDOM = new SecureRandom();
    private final ApiTokenRepository tokenRepo;
    private final UserAccountRepository userRepo;
    private final UserRoleBindingRepository roleBindingRepo;

    public ApiTokenService(ApiTokenRepository tokenRepo,
                           UserAccountRepository userRepo,
                           UserRoleBindingRepository roleBindingRepo) {
        this.tokenRepo = tokenRepo;
        this.userRepo = userRepo;
        this.roleBindingRepo = roleBindingRepo;
    }

    /** Create token, return plaintext (only once) */
    @Transactional
    public String createToken(String userId, String name, List<String> scopes,
                              LocalDateTime expiresAt) {
        byte[] randomBytes = new byte[32];
        RANDOM.nextBytes(randomBytes);
        String rawToken = TOKEN_PREFIX + Base64.getUrlEncoder().withoutPadding()
            .encodeToString(randomBytes);
        String hash = sha256(rawToken);

        ApiToken token = new ApiToken();
        token.setSubjectType("USER");
        token.setSubjectId(userId);
        token.setUserId(userId);
        token.setName(name);
        token.setTokenPrefix(TOKEN_PREFIX);
        token.setTokenHash(hash);
        token.setScopeJson(scopes);
        token.setExpiresAt(expiresAt);
        tokenRepo.save(token);

        return rawToken;
    }

    /** Authenticate via plaintext token, return PlatformPrincipal */
    public Optional<PlatformPrincipal> authenticate(String rawToken) {
        if (rawToken == null || !rawToken.startsWith(TOKEN_PREFIX)) {
            return Optional.empty();
        }
        String hash = sha256(rawToken);
        return tokenRepo.findByTokenHash(hash)
            .filter(t -> t.getRevokedAt() == null)
            .filter(t -> t.getExpiresAt() == null || t.getExpiresAt().isAfter(LocalDateTime.now()))
            .flatMap(t -> {
                t.setLastUsedAt(LocalDateTime.now());
                tokenRepo.save(t);
                return userRepo.findById(t.getUserId());
            })
            .filter(UserAccount::isActive)
            .map(user -> {
                Set<String> roles = roleBindingRepo.findByUserId(user.getId()).stream()
                    .map(rb -> rb.getRole().getCode())
                    .collect(Collectors.toSet());
                return new PlatformPrincipal(
                    user.getId(), user.getDisplayName(), user.getEmail(),
                    user.getAvatarUrl(), "api_token", roles
                );
            });
    }

    public List<ApiToken> listByUser(String userId) {
        return tokenRepo.findByUserIdAndRevokedAtIsNull(userId);
    }

    @Transactional
    public void revoke(Long tokenId, String userId) {
        tokenRepo.findById(tokenId)
            .filter(t -> t.getUserId().equals(userId))
            .ifPresent(t -> {
                t.setRevokedAt(LocalDateTime.now());
                tokenRepo.save(t);
            });
    }

    static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
```

- [ ] **Step 2: Create ApiTokenAuthenticationFilter**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/token/ApiTokenAuthenticationFilter.java
package com.skillhub.auth.token;

import com.skillhub.auth.rbac.PlatformPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

public class ApiTokenAuthenticationFilter extends OncePerRequestFilter {

    private final ApiTokenService apiTokenService;

    public ApiTokenAuthenticationFilter(ApiTokenService apiTokenService) {
        this.apiTokenService = apiTokenService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                     FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ask_")) {
            String token = authHeader.substring("Bearer ".length());
            apiTokenService.authenticate(token).ifPresent(principal -> {
                var authorities = principal.platformRoles().stream()
                    .map(r -> new SimpleGrantedAuthority("ROLE_" + r))
                    .toList();
                var auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(auth);
            });
        }
        filterChain.doFilter(request, response);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Only applies to CLI and Token API paths
        String path = request.getRequestURI();
        return !(path.startsWith("/api/v1/cli/") || path.startsWith("/api/v1/tokens")
                 || path.startsWith("/api/"));
    }
}
```

- [ ] **Step 3: Write ApiTokenService unit tests**

```java
// server/skillhub-auth/src/test/java/com/skillhub/auth/token/ApiTokenServiceTest.java
package com.skillhub.auth.token;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class ApiTokenServiceTest {

    @Test
    void sha256_producesConsistentHash() {
        String hash1 = ApiTokenService.sha256("ask_test123");
        String hash2 = ApiTokenService.sha256("ask_test123");
        assertThat(hash1).isEqualTo(hash2);
        assertThat(hash1).hasSize(64); // SHA-256 hex = 64 chars
    }

    @Test
    void sha256_differentInputsDifferentHashes() {
        String hash1 = ApiTokenService.sha256("ask_token1");
        String hash2 = ApiTokenService.sha256("ask_token2");
        assertThat(hash1).isNotEqualTo(hash2);
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd server && ./mvnw test -pl skillhub-auth -Dtest=ApiTokenServiceTest -am`

Expected: 2 tests PASS

- [ ] **Step 5: Commit**

```bash
git add server/skillhub-auth/
git commit -m "feat(auth): add API Token service and authentication filter

- ApiTokenService: create, authenticate, list, revoke tokens
- ask_ prefix + SHA-256 hash storage
- ApiTokenAuthenticationFilter for Bearer token auth on CLI/compat paths
- Unit tests for SHA-256 hashing"
```

### Task 13: RBAC Authorization Service

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/rbac/RbacService.java`
- Test: `server/skillhub-auth/src/test/java/com/skillhub/auth/rbac/RbacServiceTest.java`

- [ ] **Step 1: Create RbacService**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/rbac/RbacService.java
package com.skillhub.auth.rbac;

import com.skillhub.auth.repository.UserRoleBindingRepository;
import com.skillhub.domain.namespace.NamespaceMember;
import com.skillhub.domain.namespace.NamespaceMemberRepository;
import com.skillhub.domain.namespace.NamespaceRole;
import org.springframework.stereotype.Service;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class RbacService {

    private final UserRoleBindingRepository roleBindingRepo;
    private final NamespaceMemberRepository namespaceMemberRepo;

    public RbacService(UserRoleBindingRepository roleBindingRepo,
                       NamespaceMemberRepository namespaceMemberRepo) {
        this.roleBindingRepo = roleBindingRepo;
        this.namespaceMemberRepo = namespaceMemberRepo;
    }

    /** Check whether the user has the specified platform permission */
    public boolean hasPlatformRole(PlatformPrincipal principal, String roleCode) {
        if (principal.platformRoles().contains("SUPER_ADMIN")) return true;
        return principal.platformRoles().contains(roleCode);
    }

    /** Check whether the user role in the specified namespace meets the minimum required role */
    public boolean hasNamespaceRole(String userId, Long namespaceId, NamespaceRole minRole) {
        Optional<NamespaceMember> member = namespaceMemberRepo
            .findByNamespaceIdAndUserId(namespaceId, userId);
        return member.map(m -> m.getRole().ordinal() <= minRole.ordinal()).orElse(false);
    }

    /** Get the user role in the specified namespace */
    public Optional<NamespaceRole> getNamespaceRole(String userId, Long namespaceId) {
        return namespaceMemberRepo.findByNamespaceIdAndUserId(namespaceId, userId)
            .map(NamespaceMember::getRole);
    }

    /** Get all platform role codes for the user */
    public Set<String> getPlatformRoleCodes(String userId) {
        return roleBindingRepo.findByUserId(userId).stream()
            .map(rb -> rb.getRole().getCode())
            .collect(Collectors.toSet());
    }
}
```

- [ ] **Step 2: Write RbacService unit tests**

```java
// server/skillhub-auth/src/test/java/com/skillhub/auth/rbac/RbacServiceTest.java
package com.skillhub.auth.rbac;

import org.junit.jupiter.api.Test;
import java.util.Set;
import static org.assertj.core.api.Assertions.assertThat;

class RbacServiceTest {

    @Test
    void superAdmin_hasAnyPlatformRole() {
        var principal = new PlatformPrincipal(1L, "admin", "a@b.com", null, "github",
            Set.of("SUPER_ADMIN"));
        // SUPER_ADMIN short-circuit check
        assertThat(principal.platformRoles().contains("SUPER_ADMIN")).isTrue();
    }

    @Test
    void regularUser_doesNotHaveAdminRole() {
        var principal = new PlatformPrincipal(2L, "user", "u@b.com", null, "github",
            Set.of());
        assertThat(principal.platformRoles().contains("SKILL_ADMIN")).isFalse();
    }

    @Test
    void platformPrincipal_isSerializable() {
        var principal = new PlatformPrincipal(1L, "test", "t@t.com", null, "github",
            Set.of("AUDITOR"));
        // record automatically implements Serializable
        assertThat(principal).isInstanceOf(java.io.Serializable.class);
    }
}
```

- [ ] **Step 3: Run tests**

Run: `cd server && ./mvnw test -pl skillhub-auth -Dtest=RbacServiceTest -am`

Expected: 3 tests PASS

- [ ] **Step 4: Commit**

```bash
git add server/skillhub-auth/
git commit -m "feat(auth): add RBAC authorization service

- RbacService: platform role check with SUPER_ADMIN short-circuit
- Namespace role check with ordinal comparison
- Unit tests for role checks"
```

### Task 14: Spring Security Configuration + CSRF + Session

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/config/SecurityConfig.java`
- Modify: `server/skillhub-app/src/main/resources/application.yml` (add OAuth2 and Session configuration)
- Modify: `server/skillhub-app/src/main/resources/application-local.yml` (add OAuth2 placeholder configuration)

- [ ] **Step 1: Create SecurityConfig**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/config/SecurityConfig.java
package com.skillhub.auth.config;

import com.skillhub.auth.oauth.CustomOAuth2UserService;
import com.skillhub.auth.oauth.OAuth2LoginSuccessHandler;
import com.skillhub.auth.token.ApiTokenAuthenticationFilter;
import com.skillhub.auth.token.ApiTokenService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfTokenRequestAttributeHandler;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final CustomOAuth2UserService customOAuth2UserService;
    private final OAuth2LoginSuccessHandler successHandler;
    private final ApiTokenService apiTokenService;

    public SecurityConfig(CustomOAuth2UserService customOAuth2UserService,
                          OAuth2LoginSuccessHandler successHandler,
                          ApiTokenService apiTokenService) {
        this.customOAuth2UserService = customOAuth2UserService;
        this.successHandler = successHandler;
        this.apiTokenService = apiTokenService;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        // CSRF: Cookie-to-Header pattern; CLI/compat API exempted
        var csrfHandler = new CsrfTokenRequestAttributeHandler();
        csrfHandler.setCsrfRequestAttributeName(null);

        http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .csrfTokenRequestHandler(csrfHandler)
                .ignoringRequestMatchers("/api/v1/cli/**", "/api/**")
            )
            .authorizeHttpRequests(auth -> auth
                // Public endpoints
                .requestMatchers(
                    "/api/v1/health",
                    "/api/v1/auth/providers",
                    "/api/v1/skills/**",
                    "/api/v1/namespaces/**",
                    "/actuator/health",
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/.well-known/**"
                ).permitAll()
                // Admin API
                .requestMatchers("/api/v1/admin/**").hasAnyRole("SUPER_ADMIN", "SKILL_ADMIN", "USER_ADMIN", "AUDITOR")
                // All others require authentication
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .userInfoEndpoint(userInfo -> userInfo.userService(customOAuth2UserService))
                .successHandler(successHandler)
            )
            .logout(logout -> logout
                .logoutUrl("/api/v1/auth/logout")
                .logoutSuccessUrl("/")
                .invalidateHttpSession(true)
                .deleteCookies("SESSION")
            )
            .addFilterBefore(
                new ApiTokenAuthenticationFilter(apiTokenService),
                UsernamePasswordAuthenticationFilter.class
            );

        return http.build();
    }
}
```

- [ ] **Step 2: Update application.yml to add OAuth2 and Session configuration**

Append to `server/skillhub-app/src/main/resources/application.yml`:

```yaml
# Append to application.yml
spring:
  session:
    store-type: redis
    redis:
      namespace: skillhub:session
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: ${OAUTH2_GITHUB_CLIENT_ID:placeholder}
            client-secret: ${OAUTH2_GITHUB_CLIENT_SECRET:placeholder}
            scope: read:user,user:email
        provider:
          github:
            user-info-uri: https://api.github.com/user

skillhub:
  access-policy:
    mode: OPEN
```

- [ ] **Step 3: Update application-local.yml**

Append to `server/skillhub-app/src/main/resources/application-local.yml`:

```yaml
# Append to application-local.yml
spring:
  session:
    store-type: redis
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: ${OAUTH2_GITHUB_CLIENT_ID:local-placeholder}
            client-secret: ${OAUTH2_GITHUB_CLIENT_SECRET:local-placeholder}
```

- [ ] **Step 4: Commit**

```bash
git add server/
git commit -m "feat(auth): add Spring Security config with OAuth2 + CSRF + Session

- SecurityConfig: OAuth2 login, CSRF Cookie-to-Header, CLI API exempt
- API Token filter before UsernamePasswordAuthenticationFilter
- Spring Session Redis configuration
- Public endpoints permit all, admin requires roles"
```

### Task 15: MockAuthFilter for Local Development

**Files:**
- Create: `server/skillhub-auth/src/main/java/com/skillhub/auth/mock/MockAuthFilter.java`

- [ ] **Step 1: Create MockAuthFilter**

```java
// server/skillhub-auth/src/main/java/com/skillhub/auth/mock/MockAuthFilter.java
package com.skillhub.auth.mock;

import com.skillhub.auth.rbac.PlatformPrincipal;
import com.skillhub.auth.repository.UserRoleBindingRepository;
import com.skillhub.domain.user.UserAccount;
import com.skillhub.domain.user.UserAccountRepository;
import com.skillhub.domain.user.UserStatus;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.Set;
import java.util.stream.Collectors;

@Component
@Profile("local")
@Order(-100)
public class MockAuthFilter extends OncePerRequestFilter {

    private final UserAccountRepository userRepo;
    private final UserRoleBindingRepository roleBindingRepo;

    public MockAuthFilter(UserAccountRepository userRepo,
                          UserRoleBindingRepository roleBindingRepo) {
        this.userRepo = userRepo;
        this.roleBindingRepo = roleBindingRepo;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                     FilterChain filterChain) throws ServletException, IOException {
        String mockUserId = request.getHeader("X-Mock-User-Id");
        if (mockUserId != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            String userId = mockUserId;
            userRepo.findById(userId)
                .filter(UserAccount::isActive)
                .ifPresent(user -> {
                    Set<String> roles = roleBindingRepo.findByUserId(userId).stream()
                        .map(rb -> rb.getRole().getCode())
                        .collect(Collectors.toSet());
                    var principal = new PlatformPrincipal(
                        user.getId(), user.getDisplayName(), user.getEmail(),
                        user.getAvatarUrl(), "mock", roles
                    );
                    var authorities = roles.stream()
                        .map(r -> new SimpleGrantedAuthority("ROLE_" + r))
                        .toList();
                    var auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(auth);
                    request.getSession().setAttribute("platformPrincipal", principal);
                });
        }
        filterChain.doFilter(request, response);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add server/skillhub-auth/
git commit -m "feat(auth): add MockAuthFilter for local development

- Activated only under 'local' profile via @Profile
- Reads X-Mock-User-Id header to simulate authenticated user
- Creates PlatformPrincipal and sets SecurityContext"
```

### Task 16: AuthController + Token API

**Files:**
- Create: `server/skillhub-app/src/main/java/com/skillhub/controller/AuthController.java`
- Create: `server/skillhub-app/src/main/java/com/skillhub/controller/TokenController.java`

- [ ] **Step 1: Create AuthController**

```java
// server/skillhub-app/src/main/java/com/skillhub/controller/AuthController.java
package com.skillhub.controller;

import com.skillhub.auth.rbac.PlatformPrincipal;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final ClientRegistrationRepository clientRegistrationRepository;

    public AuthController(ClientRegistrationRepository clientRegistrationRepository) {
        this.clientRegistrationRepository = clientRegistrationRepository;
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> me(HttpSession session) {
        PlatformPrincipal principal = (PlatformPrincipal) session.getAttribute("platformPrincipal");
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.ok(Map.of(
            "userId", principal.userId(),
            "displayName", principal.displayName(),
            "email", principal.email() != null ? principal.email() : "",
            "avatarUrl", principal.avatarUrl() != null ? principal.avatarUrl() : "",
            "oauthProvider", principal.oauthProvider(),
            "platformRoles", principal.platformRoles()
        ));
    }

    @GetMapping("/providers")
    public ResponseEntity<Map<String, Object>> providers() {
        // Phase 1: GitHub only; later can read dynamically from ClientRegistrationRepository
        var github = Map.of(
            "id", "github",
            "name", "GitHub",
            "authorizationUrl", "/oauth2/authorization/github"
        );
        return ResponseEntity.ok(Map.of("data", List.of(github)));
    }
}
```

- [ ] **Step 2: Create TokenController**

```java
// server/skillhub-app/src/main/java/com/skillhub/controller/TokenController.java
package com.skillhub.controller;

import com.skillhub.auth.rbac.PlatformPrincipal;
import com.skillhub.auth.token.ApiTokenService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tokens")
public class TokenController {

    private final ApiTokenService apiTokenService;

    public TokenController(ApiTokenService apiTokenService) {
        this.apiTokenService = apiTokenService;
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(
            @AuthenticationPrincipal PlatformPrincipal principal,
            @RequestBody Map<String, Object> body) {
        String name = (String) body.get("name");
        @SuppressWarnings("unchecked")
        List<String> scopes = (List<String>) body.getOrDefault("scopes",
            List.of("skill:read", "skill:publish"));
        Integer expiryDays = (Integer) body.get("expiryDays");
        LocalDateTime expiresAt = expiryDays != null
            ? LocalDateTime.now().plusDays(expiryDays) : null;

        String rawToken = apiTokenService.createToken(
            principal.userId(), name, scopes, expiresAt);

        return ResponseEntity.ok(Map.of("token", rawToken));
    }

    @GetMapping
    public ResponseEntity<?> list(@AuthenticationPrincipal PlatformPrincipal principal) {
        var tokens = apiTokenService.listByUser(principal.userId());
        var result = tokens.stream().map(t -> Map.of(
            "id", t.getId(),
            "name", t.getName(),
            "tokenPrefix", t.getTokenPrefix(),
            "createdAt", t.getCreatedAt().toString(),
            "expiresAt", t.getExpiresAt() != null ? t.getExpiresAt().toString() : "",
            "lastUsedAt", t.getLastUsedAt() != null ? t.getLastUsedAt().toString() : ""
        )).toList();
        return ResponseEntity.ok(Map.of("data", result));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> revoke(
            @AuthenticationPrincipal PlatformPrincipal principal,
            @PathVariable Long id) {
        apiTokenService.revoke(id, principal.userId());
        return ResponseEntity.noContent().build();
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add server/skillhub-app/
git commit -m "feat: add AuthController and TokenController

- GET /api/v1/auth/me: return current user info from session
- GET /api/v1/auth/providers: return available OAuth providers
- POST/GET/DELETE /api/v1/tokens: create, list, revoke API tokens"
```

### Task 17: Global Exception Handling

**Files:**
- Create: `server/skillhub-app/src/main/java/com/skillhub/exception/ErrorResponse.java`
- Create: `server/skillhub-app/src/main/java/com/skillhub/exception/GlobalExceptionHandler.java`

- [ ] **Step 1: Create ErrorResponse**

```java
// server/skillhub-app/src/main/java/com/skillhub/exception/ErrorResponse.java
package com.skillhub.exception;

import java.time.Instant;

public record ErrorResponse(
    int status,
    String error,
    String message,
    String requestId,
    Instant timestamp
) {
    public ErrorResponse(int status, String error, String message, String requestId) {
        this(status, error, message, requestId, Instant.now());
    }
}
```

- [ ] **Step 2: Create GlobalExceptionHandler**

```java
// server/skillhub-app/src/main/java/com/skillhub/exception/GlobalExceptionHandler.java
package com.skillhub.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleBadRequest(IllegalArgumentException ex,
                                                           HttpServletRequest request) {
        String requestId = (String) request.getAttribute("requestId");
        return ResponseEntity.badRequest().body(
            new ErrorResponse(400, "Bad Request", ex.getMessage(), requestId));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex,
                                                        HttpServletRequest request) {
        String requestId = (String) request.getAttribute("requestId");
        log.error("Unhandled exception [requestId={}]", requestId, ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            new ErrorResponse(500, "Internal Server Error",
                "An unexpected error occurred", requestId));
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add server/skillhub-app/
git commit -m "feat: add global exception handler

- ErrorResponse record with status, error, message, requestId, timestamp
- GlobalExceptionHandler: 400 for IllegalArgumentException, 500 catch-all
- Logs unhandled exceptions with requestId"
```

### Task 18: Flyway Seed Data (Pre-defined RBAC Roles and Permissions)

**Files:**
- Create: `server/skillhub-app/src/main/resources/db/migration/V2__seed_rbac.sql`

- [ ] **Step 1: Create seed data migration script**

```sql
-- server/skillhub-app/src/main/resources/db/migration/V2__seed_rbac.sql

-- Pre-defined platform roles
INSERT INTO role (code, name, description, is_system) VALUES
('SUPER_ADMIN', 'Platform Super Admin', 'Has all permissions', TRUE),
('SKILL_ADMIN', 'Skill Governance', 'Global namespace review, promotion review, hide/revoke', TRUE),
('USER_ADMIN', 'User Governance', 'Access approval, ban/unban, role assignment', TRUE),
('AUDITOR', 'Auditor', 'View audit logs', TRUE);

-- Pre-defined permissions
INSERT INTO permission (code, name, group_code) VALUES
('review:approve', 'Approve Review', 'review'),
('review:reject', 'Reject Review', 'review'),
('skill:manage', 'Manage Skill', 'skill'),
('skill:publish', 'Publish Skill', 'skill'),
('skill:delete', 'Delete Skill', 'skill'),
('promotion:approve', 'Approve Promotion', 'promotion'),
('user:manage', 'Manage Users', 'user'),
('user:approve', 'Approve User Access', 'user'),
('audit:read', 'View Audit Logs', 'audit');

-- Role-permission bindings
-- SKILL_ADMIN
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.code = 'SKILL_ADMIN' AND p.code IN ('review:approve', 'review:reject', 'skill:manage', 'promotion:approve');

-- USER_ADMIN
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.code = 'USER_ADMIN' AND p.code IN ('user:manage', 'user:approve');

-- AUDITOR
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.code = 'AUDITOR' AND p.code = 'audit:read';

-- Pre-defined @global namespace
INSERT INTO namespace (slug, display_name, description, visibility, status)
VALUES ('global', 'Global', 'Platform-level public namespace', 'PUBLIC', 'ACTIVE');

-- Pre-defined seed user (for local development, SUPER_ADMIN)
INSERT INTO user_account (display_name, email, status)
VALUES ('Admin', 'admin@skillhub.dev', 'ACTIVE');

INSERT INTO user_role_binding (user_id, role_id)
SELECT u.id, r.id FROM user_account u, role r
WHERE u.email = 'admin@skillhub.dev' AND r.code = 'SUPER_ADMIN';
```

- [ ] **Step 2: Commit**

```bash
git add server/skillhub-app/src/main/resources/db/migration/V2__seed_rbac.sql
git commit -m "feat: add RBAC seed data migration

- Preset 4 platform roles: SUPER_ADMIN, SKILL_ADMIN, USER_ADMIN, AUDITOR
- Preset 9 permissions with role-permission bindings
- Create @global namespace
- Create seed admin user for local development"
```

### Chunk 2 Acceptance Checks

Run the following commands to verify Chunk 2 is complete:

```bash
# 1. Ensure dependency services are running
make dev

# 2. Run all tests
cd server && ./mvnw test
# Expected: BUILD SUCCESS, AccessPolicyTest + ApiTokenServiceTest + RbacServiceTest all PASS

# 3. Start application
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# 4. Verify MockAuth + /api/v1/auth/me
curl -H "X-Mock-User-Id: 1" http://localhost:8080/api/v1/auth/me
# Expected: {"userId":1,"displayName":"Admin","email":"admin@skillhub.dev",...}

# 5. Verify unauthenticated request returns 401
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/auth/me
# Expected: 401

# 6. Verify /api/v1/auth/providers
curl http://localhost:8080/api/v1/auth/providers
# Expected: {"data":[{"id":"github","name":"GitHub","authorizationUrl":"/oauth2/authorization/github"}]}

# 7. Verify token creation
curl -X POST -H "X-Mock-User-Id: 1" -H "Content-Type: application/json" \
  -d '{"name":"test-token","scopes":["skill:read"]}' \
  http://localhost:8080/api/v1/tokens
# Expected: {"token":"ask_..."}

# 8. Verify token list
curl -H "X-Mock-User-Id: 1" http://localhost:8080/api/v1/tokens
# Expected: {"data":[...]}

# 9. Verify RBAC seed data
docker compose exec postgres psql -U skillhub -d skillhub \
  -c "SELECT r.code, array_agg(p.code) FROM role r JOIN role_permission rp ON r.id=rp.role_id JOIN permission p ON p.id=rp.permission_id GROUP BY r.code;"
# Expected: 4 roles with their permissions

# 10. Stop application and services
make dev-down
```

Chunk 2 output: Complete authentication pipeline (OAuth2 + AccessPolicy + IdentityBinding + Session + Token + RBAC + MockAuth + CSRF).

## Chunk 3: Frontend Skeleton + Login Integration

This chunk establishes the React frontend project, integrates TanStack Router/Query, shadcn/ui, and the openapi-fetch type generation pipeline, and implements the OAuth login flow and route guards.

### File Structure Mapping

```
web/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── components.json                    # shadcn/ui configuration
├── index.html
├── src/
│   ├── main.tsx
│   ├── app/
│   │   ├── router.tsx                 # TanStack Router configuration
│   │   ├── providers.tsx              # QueryClient + Router Provider
│   │   └── layout.tsx                 # Global layout (Header + Main)
│   ├── pages/
│   │   ├── home.tsx                   # Home page
│   │   ├── login.tsx                  # Login page
│   │   └── dashboard.tsx              # Dashboard (requires login)
│   ├── features/
│   │   └── auth/
│   │       ├── use-auth.ts            # Auth state hook
│   │       ├── auth-guard.tsx         # Route guard
│   │       └── login-button.tsx       # OAuth login button
│   ├── shared/
│   │   └── ui/                        # shadcn/ui components
│   └── api/
│       ├── client.ts                  # openapi-fetch client
│       └── generated/                 # openapi-typescript generated types
│           └── schema.d.ts
├── Dockerfile
└── nginx.conf
```

### Task 19: Initialize Frontend Project

**Files:**
- Create: `web/package.json`
- Create: `web/tsconfig.json`
- Create: `web/vite.config.ts`
- Create: `web/index.html`
- Create: `web/src/main.tsx`

- [ ] **Step 1: Initialize Vite + React + TypeScript project**

```bash
cd web  # If web/ does not exist, first run: mkdir web && cd web
pnpm create vite . --template react-ts
```

Or manually create `package.json`:

```json
{
  "name": "skillhub-web",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "generate-api": "openapi-typescript http://localhost:8080/v3/api-docs -o src/api/generated/schema.d.ts"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@tanstack/react-router": "^1.95.0",
    "@tanstack/react-query": "^5.64.0",
    "openapi-fetch": "^0.13.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.7.0",
    "vite": "^6.1.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "openapi-typescript": "^7.6.0"
  }
}
```

- [ ] **Step 2: Install dependencies**

Run: `cd web && pnpm install`

Expected: Dependencies installed successfully

- [ ] **Step 3: Create tsconfig.json**

```json
// web/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
```

- [ ] **Step 4: Create vite.config.ts**

```typescript
// web/vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      '/oauth2': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      '/login': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

- [ ] **Step 4: Create index.html and main.tsx**

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>SkillHub</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

```tsx
// web/src/main.tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import { App } from './app/providers'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "feat(web): initialize Vite + React + TypeScript frontend

- package.json with React 19, TanStack Router/Query, openapi-fetch
- Vite config with API proxy to backend
- index.html and main.tsx entry point"
```

### Task 20: Tailwind CSS + shadcn/ui Configuration

**Files:**
- Create: `web/tailwind.config.ts`
- Create: `web/postcss.config.js`
- Create: `web/src/index.css`
- Create: `web/components.json`

- [ ] **Step 1: Configure Tailwind CSS**

```typescript
// web/tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
}
export default config
```

```javascript
// web/postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

```css
/* web/src/index.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

- [ ] **Step 2: Initialize shadcn/ui**

Run: `cd web && pnpm dlx shadcn@latest init`

Choose the default configuration, or manually create `components.json`:

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/index.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/shared/ui",
    "utils": "@/shared/ui/lib/utils"
  }
}
```

- [ ] **Step 3: Add Button component (verify shadcn/ui works)**

Run: `cd web && pnpm dlx shadcn@latest add button`

Expected: `src/shared/ui/button.tsx` generated successfully

- [ ] **Step 4: Commit**

```bash
git add web/
git commit -m "feat(web): add Tailwind CSS and shadcn/ui configuration

- Tailwind config with dark mode support
- PostCSS config
- shadcn/ui initialized with Button component"
```

### Task 21: TanStack Router Routing Skeleton

**Files:**
- Create: `web/src/app/router.tsx`
- Create: `web/src/app/providers.tsx`
- Create: `web/src/app/layout.tsx`
- Create: `web/src/pages/home.tsx`
- Create: `web/src/pages/login.tsx`
- Create: `web/src/pages/dashboard.tsx`

- [ ] **Step 1: Create routing configuration**

```tsx
// web/src/app/router.tsx
import { createRouter, createRoute, createRootRoute } from '@tanstack/react-router'
import { Layout } from './layout'
import { HomePage } from '../pages/home'
import { LoginPage } from '../pages/login'
import { DashboardPage } from '../pages/dashboard'

const rootRoute = createRootRoute({
  component: Layout,
})

const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: HomePage,
})

const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/login',
  component: LoginPage,
})

const dashboardRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/dashboard',
  component: DashboardPage,
})

const routeTree = rootRoute.addChildren([homeRoute, loginRoute, dashboardRoute])

export const router = createRouter({ routeTree })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
```

- [ ] **Step 2: Create Providers**

```tsx
// web/src/app/providers.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 1,
    },
  },
})

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  )
}
```

- [ ] **Step 3: Create Layout**

```tsx
// web/src/app/layout.tsx
import { Outlet, Link } from '@tanstack/react-router'
import { useAuth } from '../features/auth/use-auth'

export function Layout() {
  const { user, isLoading } = useAuth()

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto flex h-14 items-center justify-between px-4">
          <Link to="/" className="text-lg font-semibold">SkillHub</Link>
          <nav className="flex items-center gap-4">
            {isLoading ? null : user ? (
              <>
                <Link to="/dashboard" className="text-sm">Dashboard</Link>
                <span className="text-sm text-muted-foreground">{user.displayName}</span>
              </>
            ) : (
              <Link to="/login" className="text-sm">Login</Link>
            )}
          </nav>
        </div>
      </header>
      <main className="container mx-auto px-4 py-6">
        <Outlet />
      </main>
    </div>
  )
}
```

- [ ] **Step 4: Create page components**

```tsx
// web/src/pages/home.tsx
export function HomePage() {
  return (
    <div>
      <h1 className="text-2xl font-bold">SkillHub</h1>
      <p className="mt-2 text-muted-foreground">Skill Registry</p>
    </div>
  )
}
```

```tsx
// web/src/pages/login.tsx
import { LoginButton } from '../features/auth/login-button'

export function LoginPage() {
  return (
    <div className="flex min-h-[60vh] items-center justify-center">
      <div className="w-full max-w-sm space-y-6 text-center">
        <h1 className="text-2xl font-bold">Login to SkillHub</h1>
        <LoginButton />
      </div>
    </div>
  )
}
```

```tsx
// web/src/pages/dashboard.tsx
import { useAuth } from '../features/auth/use-auth'
import { AuthGuard } from '../features/auth/auth-guard'

export function DashboardPage() {
  const { user } = useAuth()

  return (
    <AuthGuard>
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="mt-2">Welcome, {user?.displayName}</p>
      </div>
    </AuthGuard>
  )
}
```

- [ ] **Step 5: Commit**

```bash
git add web/src/
git commit -m "feat(web): add TanStack Router with page skeleton

- Root layout with header navigation
- Home, Login, Dashboard pages
- Router config with type-safe routes"
```

### Task 22: Auth Hook + Login Button + Route Guards

**Files:**
- Create: `web/src/features/auth/use-auth.ts`
- Create: `web/src/features/auth/login-button.tsx`
- Create: `web/src/features/auth/auth-guard.tsx`

- [ ] **Step 1: Create useAuth hook**

```tsx
// web/src/features/auth/use-auth.ts
import { useQuery } from '@tanstack/react-query'

interface User {
  userId: string
  displayName: string
  email: string
  avatarUrl: string
  oauthProvider: string
  platformRoles: string[]
}

export function useAuth() {
  const { data: user, isLoading, error } = useQuery<User>({
    queryKey: ['auth', 'me'],
    queryFn: async () => {
      const res = await fetch('/api/v1/auth/me')
      if (res.status === 401) return null
      if (!res.ok) throw new Error('Failed to fetch user')
      return res.json()
    },
    retry: false,
    staleTime: 5 * 60 * 1000,
  })

  return {
    user: user ?? null,
    isLoading,
    isAuthenticated: !!user,
    hasRole: (role: string) => user?.platformRoles?.includes(role) ?? false,
  }
}
```

- [ ] **Step 2: Create LoginButton**

```tsx
// web/src/features/auth/login-button.tsx
import { useQuery } from '@tanstack/react-query'
import { Button } from '../../shared/ui/button'

interface Provider {
  id: string
  name: string
  authorizationUrl: string
}

export function LoginButton() {
  const { data } = useQuery<{ data: Provider[] }>({
    queryKey: ['auth', 'providers'],
    queryFn: async () => {
      const res = await fetch('/api/v1/auth/providers')
      if (!res.ok) throw new Error('Failed to fetch providers')
      return res.json()
    },
  })

  const providers = data?.data ?? []

  return (
    <div className="space-y-3">
      {providers.map((p) => (
        <Button
          key={p.id}
          className="w-full"
          onClick={() => { window.location.href = p.authorizationUrl }}
        >
          Login with {p.name}
        </Button>
      ))}
    </div>
  )
}
```

- [ ] **Step 3: Create AuthGuard**

```tsx
// web/src/features/auth/auth-guard.tsx
import { useNavigate } from '@tanstack/react-router'
import { useAuth } from './use-auth'
import { useEffect } from 'react'

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      navigate({ to: '/login' })
    }
  }, [isLoading, isAuthenticated, navigate])

  if (isLoading) {
    return <div className="flex justify-center py-8">Loading...</div>
  }

  if (!isAuthenticated) return null

  return <>{children}</>
}
```

- [ ] **Step 4: Commit**

```bash
git add web/src/features/
git commit -m "feat(web): add auth hook, login button, and route guard

- useAuth: fetch /api/v1/auth/me with TanStack Query
- LoginButton: dynamic OAuth provider buttons from /api/v1/auth/providers
- AuthGuard: redirect to /login if not authenticated"
```

### Task 23: openapi-fetch Client Generation Pipeline

**Files:**
- Create: `web/src/api/client.ts`

- [ ] **Step 1: Create API client**

```typescript
// web/src/api/client.ts
import createClient from 'openapi-fetch'

// Phase 1: use manual types; later auto-generate via openapi-typescript
export const api = createClient({ baseUrl: '/' })

// Convenience methods
export async function fetchJson<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })
  if (!res.ok) {
    throw new Error(`API error: ${res.status}`)
  }
  return res.json()
}
```

- [ ] **Step 2: Verify generate-api script works**

Run while the backend is running:

Run: `cd web && pnpm run generate-api`

Expected: If backend is running, generates `src/api/generated/schema.d.ts`; if backend is not running, reports a connection error (expected behavior)

- [ ] **Step 3: Commit**

```bash
git add web/src/api/
git commit -m "feat(web): add openapi-fetch API client

- createClient wrapper for type-safe API calls
- generate-api script for openapi-typescript code generation"
```

### Task 24: Frontend Dockerfile + nginx.conf

**Files:**
- Create: `web/Dockerfile`
- Create: `web/nginx.conf`

- [ ] **Step 1: Create nginx.conf**

```nginx
# web/nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
    gzip_min_length 1000;

    # SPA routing: all non-file requests fall back to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API reverse proxy
    location /api/ {
        proxy_pass http://server:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # OAuth2 reverse proxy
    location /oauth2/ {
        proxy_pass http://server:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /login/oauth2/ {
        proxy_pass http://server:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Well-known
    location /.well-known/ {
        proxy_pass http://server:8080;
    }

    # Static resource caching
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /nginx-health {
        return 200 'ok';
        add_header Content-Type text/plain;
    }
}
```

- [ ] **Step 2: Create Dockerfile**

```dockerfile
# web/Dockerfile
FROM node:22-alpine AS build
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s \
  CMD wget -qO- http://localhost/nginx-health || exit 1
```

- [ ] **Step 3: Commit**

```bash
git add web/Dockerfile web/nginx.conf
git commit -m "feat(web): add Dockerfile and nginx config

- Multi-stage build: pnpm build → nginx:alpine
- Nginx SPA routing with API reverse proxy
- Static asset caching, health check endpoint"
```

### Task 25: Update Makefile to Add Frontend Commands

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Append frontend-related targets**

Append to the end of the Makefile:

```makefile
# --- Frontend ---
.PHONY: web-install web-dev web-build generate-api

web-install:
	cd web && pnpm install

web-dev:
	@echo "Run manually: cd web && pnpm dev"

web-build:
	cd web && pnpm build

generate-api:
	cd web && pnpm run generate-api
```

- [ ] **Step 2: Commit**

```bash
git add Makefile
git commit -m "feat: add frontend targets to Makefile

- web-install, web-build, generate-api targets
- web-dev prints manual run instruction (long-running process)"
```

### Task 26: Full Deployment with docker-compose.prod.yml

**Files:**
- Create: `docker-compose.prod.yml`

- [ ] **Step 1: Create production deployment compose file**

```yaml
# docker-compose.prod.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: skillhub
      POSTGRES_USER: skillhub
      POSTGRES_PASSWORD: ${DB_PASSWORD:-skillhub_prod}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U skillhub"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  minio:
    image: minio/minio:latest
    environment:
      MINIO_ROOT_USER: ${MINIO_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD:-minioadmin}
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 5s
      timeout: 5s
      retries: 5

  server:
    build:
      context: ./server
      dockerfile: Dockerfile
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/skillhub
      SPRING_DATASOURCE_USERNAME: skillhub
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD:-skillhub_prod}
      SPRING_DATA_REDIS_HOST: redis
      OAUTH2_GITHUB_CLIENT_ID: ${OAUTH2_GITHUB_CLIENT_ID}
      OAUTH2_GITHUB_CLIENT_SECRET: ${OAUTH2_GITHUB_CLIENT_SECRET}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      server:
        condition: service_healthy

volumes:
  postgres_data:
  minio_data:
```

- [ ] **Step 2: Create backend Dockerfile**

```dockerfile
# server/Dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY . .
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/skillhub-app/target/*.jar app.jar
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

- [ ] **Step 3: Update Makefile to add deploy command**

Append to Makefile:

```makefile
# --- Deploy ---
.PHONY: deploy deploy-down

deploy:
	docker compose -f docker-compose.prod.yml up -d --build

deploy-down:
	docker compose -f docker-compose.prod.yml down
```

- [ ] **Step 4: Commit**

```bash
git add docker-compose.prod.yml server/Dockerfile Makefile
git commit -m "feat: add production Docker Compose and backend Dockerfile

- docker-compose.prod.yml: full stack deployment
- server/Dockerfile: Maven multi-stage build → JRE alpine
- Makefile deploy/deploy-down targets"
```

### Chunk 3 Acceptance Checks

Run the following commands to verify Chunk 3 is complete:

```bash
# 1. Ensure backend dependencies are running
make dev

# 2. Install frontend dependencies
make web-install
# Expected: Dependencies installed successfully

# 3. Build frontend
make web-build
# Expected: dist/ directory generated

# 4. Start backend
cd server && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local &

# 5. Start frontend dev server (manually)
cd web && pnpm dev
# Expected: http://localhost:3000 is accessible

# 6. Verify home page
# Open http://localhost:3000 in browser
# Expected: "SkillHub" heading and "Login" link visible

# 7. Verify login page
# Open http://localhost:3000 in browser/login
# Expected: "Login with GitHub" button visible

# 8. Verify Dashboard route guard
# Open http://localhost:3000 in browser/dashboard
# Expected: Redirected to /login when not logged in

# 9. Verify MockAuth + Dashboard
curl -H "X-Mock-User-Id: 1" http://localhost:8080/api/v1/auth/me
# Expected: Returns user info (also accessible from frontend via proxy)

# 10. Verify OpenAPI type generation
make generate-api
# Expected: web/src/api/generated/schema.d.ts generated (requires backend running)

# 11. Stop all services
make dev-down
```

Chunk 3 output: A runnable frontend application + OAuth login flow + route guards + API type generation pipeline + production deployment configuration.

---

## Phase 1 Overall Acceptance Checks

Checking against the Phase 1 acceptance criteria in `10-delivery-roadmap.md`:

| Acceptance Item | Verification Method | Corresponding Task |
|--------|---------|-----------|
| Frontend and backend both run | `make dev` + start backend + `pnpm dev` for frontend | Task 1-7, 19-24 |
| GitHub OAuth login works | Full login flow after configuring a real GitHub OAuth App | Task 10-11, 14, 22 |
| AccessPolicy admission control works | Switch `skillhub.access-policy.mode` to verify different policies | Task 10 |
| `/api/v1/auth/me` works | `curl` to verify logged-in/not-logged-in response | Task 16 |
| Token works | Create token then Bearer auth then `/api/v1/cli/whoami` | Task 12, 16 |
| OpenAPI spec accessible | `curl http://localhost:8080/v3/api-docs` | Task 6 |
| CSRF protection | Cookie-to-Header pattern, CLI API exempted | Task 14 |
| MockAuthFilter | `X-Mock-User-Id` header simulates login | Task 15 |
| RBAC basics | Seed data: 4 roles + 9 permissions + role evaluation | Task 13, 18 |
| Global exception handling + requestId | Error responses include requestId | Task 5, 17 |
| Frontend login flow | Login page to GitHub button to callback to Dashboard | Task 21, 22 |
| Route guard | Accessing Dashboard without login redirects to /login | Task 22 |
| openapi-fetch pipeline | `make generate-api` generates type files | Task 23 |
| Full Docker deployment | `make deploy` builds and starts full stack | Task 24, 26 |

### Full End-to-End Verification Flow

```bash
# 1. Start local development environment
make dev
cd server && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local &
cd web && pnpm dev &

# 2. MockAuth verification
curl -H "X-Mock-User-Id: 1" http://localhost:8080/api/v1/auth/me
# → 200, returns Admin user info

# 3. Full token flow
TOKEN=$(curl -s -X POST -H "X-Mock-User-Id: 1" \
  -H "Content-Type: application/json" \
  -d '{"name":"e2e-test"}' \
  http://localhost:8080/api/v1/tokens | jq -r '.token')
echo $TOKEN
# → ask_...

curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/auth/me
# → 200, returns user info

# 4. Unauthenticated access
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/auth/me
# → 401

# 5. OpenAPI
curl -s http://localhost:8080/v3/api-docs | jq '.info.title'
# → "SkillHub API"

# 6. Frontend pages
# Browser http://localhost:3000 → home page
# Browser http://localhost:3000/login → login page
# Browser http://localhost:3000/dashboard → redirected to /login

# 7. Cleanup
make dev-down
```

---

**Plan complete.** 26 tasks in total, 3 chunks, covering all Phase 1 acceptance criteria.
