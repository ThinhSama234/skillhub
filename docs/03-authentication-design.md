# skillhub Authentication & Authorization Design

## 0. Identity Identifier Constraints

- `PlatformPrincipal.userId` must be a stable string identifier, not a `Long`.
- The primary contract for user identity within the system is the string `userId`; authentication, authorization, audit, and resource owner evaluation are all performed against this string.
- The `subject` from external identity providers, enterprise SSO UIDs, and employee ID strings must all be able to enter the system as-is or through a deterministic mapping, and must not be compressed into auto-increment integers to be propagated as formal user primary keys throughout the system.
- All integer user primary key descriptions in historical drafts are deprecated; the current authentication and authorization design only recognizes string identity primary keys.

## 1. Authentication Architecture

```
Request arrives
  │
  ▼
┌─────────────────────────────┐
│  Layer 1: OAuth2 Login      │  Spring Security OAuth2 Client
│  (Phase 1: GitHub; extensible)│  Authorization Code flow
│  Layer 1b: Session Bootstrap│  Explicit passive session bootstrap (disabled by default)
└─────────────┬───────────────┘
              │ OAuth2User
              ▼
┌─────────────────────────────┐
│  Layer 2: Access Policy     │  Access control decision
│  (authentication ≠ access)  │  Allowlist / email domain / open registration
└─────────────┬───────────────┘
              │ Access granted
              ▼
┌─────────────────────────────┐
│  Layer 3: Identity Mapping  │  OAuth2 user → Platform user
│  (query/create identity_binding)│  Auto-registration + info sync
└─────────────┬───────────────┘
              │ PlatformPrincipal
              ▼
┌─────────────────────────────┐
│  Layer 4: Session / Token   │  Web: Spring Session (Redis)
│                             │  CLI: Device Flow + Bearer Token
└─────────────┬───────────────┘
              │ SecurityContext
              ▼
┌─────────────────────────────┐
│  Layer 5: Authorization     │  RBAC + resource-level evaluation
└─────────────────────────────┘
```

## 2. Access Policy

A successful OAuth authentication only confirms that the identity is trustworthy; it does not grant access to the platform. The access layer executes after a successful authentication and before a platform user is created.

```java
// Claims-based access policy, provider-agnostic
public interface AccessPolicy {
    AccessDecision evaluate(OAuthClaims claims);
}

public record OAuthClaims(
    String provider,          // github, google, wechat
    String subject,           // provider's unique ID
    String email,             // nullable (WeChat etc. may have no email)
    boolean emailVerified,    // whether verified
    String providerLogin,     // e.g., GitHub login
    Map<String, Object> extra
) {}

public enum AccessDecision {
    ALLOW,              // Access granted; continue creating/binding the platform user
    DENY,               // Denied; no Session is created; redirect to rejection page
    PENDING_APPROVAL    // Awaiting admin approval; no business Session is created
}
```

### 2.1 Supported Policies in Phase 1 (switched via configuration)

```yaml
astron:
  access-policy:
    mode: EMAIL_DOMAIN   # OPEN / PROVIDER_ALLOWLIST / EMAIL_DOMAIN / SUBJECT_WHITELIST
    allowed-providers:
      - github
    allowed-email-domains:
      - company.com
      - subsidiary.com
```

| Policy | Evaluation Basis | Description |
|------|---------|------|
| `OPEN` | None | All OAuth login users are automatically admitted |
| `PROVIDER_ALLOWLIST` | `claims.provider` | Only logins from specified providers are allowed |
| `EMAIL_DOMAIN` | `claims.email` + `claims.emailVerified` | Only verified emails with a matching domain are allowed (DENY if email is empty or unverified) |
| `SUBJECT_WHITELIST` | `claims.provider` + `claims.subject` | Based on `provider:subject` allowlist; pre-added by an admin |

### 2.2 Access Failure Handling

- `DENY`: throws `OAuth2AccessDeniedException`; the `failureHandler` redirects to the `/access-denied` page. No user is created; no Session is established.
- `PENDING_APPROVAL`: creates a `user_account` (status=`PENDING`) but does not establish a business Session. Throws `AccountPendingException`; the `failureHandler` redirects to the `/pending-approval` page (a static information page, no login state required). After the admin approves in the backend, the status changes to `ACTIVE`; the user will only have a normal Session established on their next OAuth login.

Security boundary: PENDING / DISABLED users will never have a valid business Session, eliminating the risk of "pending-approval accounts already being authenticated" at the root.

### 2.3 Extensibility

When adding a new OAuth provider (Google, GitLab, WeChat) in the future, the access policy is provider-agnostic. It is evaluated uniformly in the AccessPolicy layer without needing to redo the onboarding logic.

## 3. Web Authentication Flow (OAuth2 Authorization Code)

```
Browser clicks "Login"
    │
    ▼
Frontend redirects to: /oauth2/authorization/github
    │
    ▼
Spring Security redirects to GitHub authorization page
    │
    ▼
User authorizes on GitHub
    │
    ▼
GitHub callback: /login/oauth2/code/github?code=xxx&state=xxx
    │
    ▼
Spring Security automatically:
  ① Exchanges code for access_token
  ② Calls GitHub API to fetch user info
  ③ Triggers the custom OAuth2UserService
    │
    ▼
CustomOAuth2UserService:
  ① Extracts provider + externalId from OAuth2User → builds OAuthClaims
  ② AccessPolicy.evaluate(claims) → access decision
  │
  ├── DENY → throws OAuth2AccessDeniedException → failureHandler redirects to /access-denied (no Session created)
  ├── PENDING_APPROVAL → creates PENDING user → throws AccountPendingException → failureHandler redirects to /pending-approval (no Session created)
  └── ALLOW ↓
  │
  ③ Checks whether identity_binding already exists
  ├── Already bound → loads platform user, checks user status (DISABLED → throw exception), syncs latest avatar/nickname
  └── Not bound → creates user_account(ACTIVE) + identity_binding
    │
    ▼
AuthenticationSuccessHandler:
  ① Creates Spring Session (Redis)
  ② Redirects to the frontend page (configurable redirect_uri)
```

### 3.1 Unified Session Creation Constraints

All web login entry points must create the login state through the unified `PlatformSessionService`, including:

- Local username/password login
- OAuth login success callback
- `POST /api/v1/auth/direct/login`
- `POST /api/v1/auth/session/bootstrap`
- Local development `MockAuthFilter`

Unified constraints:

- Uniformly write `platformPrincipal`
- Uniformly write `SPRING_SECURITY_CONTEXT`
- Uniformly persist via `HttpSession` to ensure Spring Session Redis can seamlessly take over
- Interactive logins call `changeSessionId()` by default to reduce session fixation risk
- Entry points where Spring Security has already completed authentication can reuse the existing `Authentication` to avoid reconstructing the authentication result

This means that when a new enterprise SSO provider is added in a future private version, only the authentication source itself can be extended; the unified session creation service cannot be bypassed by directly manipulating the Session.

## 3.3 Session Bootstrap Extension Point

To support passive enterprise SSO login in future private deployments, the open-source version reserves an explicit session bootstrap protocol:

- Endpoint: `POST /api/v1/auth/session/bootstrap`
- Purpose: the frontend explicitly triggers a "read external session and attempt to exchange for a skillhub Session" flow in same-domain scenarios
- Default state: disabled; the open-source version provides no `PassiveSessionAuthenticator` implementation
- Security boundary: no global automatic login filter is applied by default, to avoid implicit session creation on anonymous access, and to reduce CSRF and audit complexity

Extension interface:

```java
public interface PassiveSessionAuthenticator {
    String providerCode();
    Optional<PlatformPrincipal> authenticate(HttpServletRequest request);
}
```

Constraints:

- `authenticate()` is only responsible for validating the external passive session and returning the principal needed for platform login
- Whether this entry point is enabled is controlled by `skillhub.auth.session-bootstrap.enabled`; default is `false`
- Returns `403` when not enabled
- Returns `400` when enabled but the provider is not supported
- Returns `401` when enabled but no valid external session exists in the request
- On success, establishes a standard Spring Security Session and returns the same user structure as `/api/v1/auth/me`

## 3.4 Direct Authentication Extension Point

To support future private deployment modes where "the frontend collects credentials and the backend calls enterprise SSO / RPC for validation," the open-source version adds a disabled-by-default direct authentication abstraction:

```java
public interface DirectAuthProvider {
    String providerCode();
    PlatformPrincipal authenticate(DirectAuthRequest request);
}
```

Corresponding public protocol:

- `POST /api/v1/auth/direct/login`

Constraints:

- Disabled by default in the open-source version; controlled by `skillhub.auth.direct.enabled`
- Returns `403` when disabled
- Returns `400` when the provider is not supported
- When the provider's authentication fails, the exception semantics of the provider itself apply
- On success, establishes a standard Session and returns the same user structure as `/api/v1/auth/me`
- The existing `/api/v1/auth/local/login` remains unchanged; the compatibility layer only adds an optional new entry point

### 3.5 Spring Security Configuration Key Points

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .oauth2Login(oauth2 -> oauth2
                .userInfoEndpoint(info -> info
                    .userService(customOAuth2UserService))
                .successHandler(oAuth2SuccessHandler)
                .failureHandler(oAuth2FailureHandler)
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED))
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .ignoringRequestMatchers("/api/v1/**"))
            // ...
        ;
    }
}
```

### 3.6 OAuth2 Provider Extension Design

Only GitHub is implemented in Phase 1, but the architecture supports future extension:

```yaml
# application.yml
spring:
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: ${OAUTH2_GITHUB_CLIENT_ID}
            client-secret: ${OAUTH2_GITHUB_CLIENT_SECRET}
            scope: read:user,user:email
          # Phase 2 extension example:
          # gitlab:
          #   client-id: ...
          #   authorization-grant-type: authorization_code
          # google:
          #   client-id: ...
```

Spring Security OAuth2 Client natively supports multiple providers coexisting. Adding a new provider only requires:
1. Adding a registration configuration in `application.yml`
2. Handling user attribute mapping by `registrationId` branch in `CustomOAuth2UserService`
3. Adding a corresponding button on the frontend login page (auto-discovered via `/api/v1/auth/providers`)

## 4. Core Interface Design

```java
// Custom OAuth2 user service handling access control + user mapping
@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    @Override
    public OAuth2User loadUser(OAuth2UserRequest request) {
        OAuth2User oAuth2User = super.loadUser(request);
        String registrationId = request.getClientRegistration().getRegistrationId();

        // Extract normalized claims (accessToken is passed for calling Provider APIs, e.g., GitHub /user/emails)
        OAuthClaims claims = OAuthClaimsExtractor.extract(registrationId, oAuth2User, request.getAccessToken());

        // Access policy evaluation (based on claims, provider-agnostic)
        AccessDecision decision = accessPolicy.evaluate(claims);
        if (decision == AccessDecision.DENY) {
            throw new OAuth2AccessDeniedException("Access denied by policy");
        }
        if (decision == AccessDecision.PENDING_APPROVAL) {
            // Creates a PENDING user but does not return a valid principal; no business Session is created
            identityBindingService.createPendingUser(registrationId, claims);
            throw new AccountPendingException("Account pending approval");
        }

        // Bind or create the platform user (only reaches here on ALLOW)
        UserAccount account = identityBindingService.bindOrCreate(registrationId, claims);
        if (account.getStatus() == UserStatus.DISABLED) {
            throw new AccountDisabledException("Account is disabled");
        }

        return new PlatformOAuth2User(account, oAuth2User.getAuthorities());
    }
}

// Extracts normalized claims per provider (each provider has its own trusted field contract)
public class OAuthClaimsExtractor {
    public static OAuthClaims extract(String registrationId, OAuth2User user,
                                      OAuth2AccessToken accessToken) {
        return switch (registrationId) {
            case "github" -> extractGitHub(user, accessToken);
            // Future extension for other providers
            default -> throw new OAuth2AuthenticationException("Unsupported provider: " + registrationId);
        };
    }

    // GitHub: the public email may be empty; the /user/emails API must be called to get the verified email
    private static OAuthClaims extractGitHub(OAuth2User user, OAuth2AccessToken accessToken) {
        String verifiedEmail = GitHubEmailFetcher.fetchVerifiedEmail(accessToken);
        return new OAuthClaims(
            "github",
            String.valueOf(user.getAttribute("id")),
            verifiedEmail,                    // Verified email from /user/emails; may be null
            verifiedEmail != null,            // Only true when verified is confirmed
            user.getAttribute("login"),
            Map.of("avatar_url", user.getAttribute("avatar_url"))
        );
    }

    // GitHubEmailFetcher: calls the GitHub /user/emails API,
    // returns the primary + verified email, or null if not found
}
```

### 4.1 Multi-Provider Account Merge Strategy

When the same employee logs in through different OAuth providers, multiple `user_account` records may be created.

Phase 1 strategy: automatic merging is disabled by default; only admin-initiated manual merging is supported.

- Phase 1 is GitHub-only: no automatic merging needed; each provider login creates an independent user
- When multiple providers are launched, an explicit binding/merging flow will be introduced (user-initiated + email verification confirmation)
- Admins can manually merge two user_accounts in the backend (merge identity_bindings, migrate skill ownership, merge roles by union)

Merge operation rules:
- Merge operations are written to the audit log
- After merging, the original user_account is marked as `MERGED`; the record is retained without physical deletion
- Extension point reserved: in the future, `astron.identity.auto-merge-on-verified-email=true` can be configured to enable automatic merging based on verified emails

## 5. CLI Authentication (OAuth Device Flow + Platform Credentials)

The CLI primary authentication baseline is adjusted to OAuth Device Flow. The user initiates authorization from the CLI, completes login and confirmation on the browser side, and the CLI polls for and obtains credentials issued by the platform to access CLI APIs.

- Initiate: CLI requests a device code and displays the `user_code` and verification URL
- Authorize: the user completes GitHub OAuth login in the browser and confirms the binding
- Poll: the CLI uses the `device_code` to poll for the authorization result
- Complete: the server issues credentials usable by the CLI; the CLI calls subsequent endpoints with `Authorization: Bearer <token>`

API Tokens are retained, but their role is adjusted from "the only CLI authentication method" to "a general-purpose platform credential capability":

- Uses: automation scripts, compatibility layer calls, manual token management, future system integrations
- Storage: only the SHA-256 hash is stored; the plaintext is displayed only once
- Validation: extracted from `Authorization: Bearer <token>` → hash comparison → load associated user → check user status
- Scopes: `skill:read`, `skill:publish`, `skill:delete`, `token:manage`

> **Phase 1 Scope Note (Non-Least-Privilege)**: In Phase 1, Token scopes are coarse-grained action-level and are not bound to a namespace. Tokens inherit the user's full permissions — if the user is a MEMBER of a namespace, any of that user's Tokens (as long as they include the `skill:publish` scope) can publish skills to that namespace. This is an intentional Phase 1 simplification that does not satisfy the least-privilege principle. Future versions plan to introduce namespace-level Token scope restrictions (e.g., `namespace:ai-team:skill:publish`), or implement Token-to-namespace binding via an `api_token_scope` sub-table.

## 6. RBAC Authorization Evaluation

```
Permission decision = platform role permissions (role → permission query) ∪ namespace role (namespace_member.role)
```

The full RBAC system is launched in Phase 1 with platform roles split by least privilege:

| Platform Role | Responsibility |
|---------|------|
| `SUPER_ADMIN` | All permissions; hard short-circuit evaluation |
| `SKILL_ADMIN` | Global namespace review, promotion review, hide/restore skills, retract published versions |
| `USER_ADMIN` | Access approval, ban/unban, role assignment (cannot assign SUPER_ADMIN) |
| `AUDITOR` | Audit log read-only |

- Namespace permissions are still determined by `namespace_member.role` (OWNER / ADMIN / MEMBER)
- A user can hold multiple platform roles
- Ordinary users have no platform roles and only gain operation permissions through namespace membership

Evaluation logic:
1. Get the current user from the SecurityContext
2. Check user status (`DISABLED` → deny all operations)
3. Query the user's platform roles (`user_role_binding` → `role` → `role_permission`)
4. `SUPER_ADMIN` short-circuit: passes all permission checks directly
5. If a namespace resource is involved, query the user's role in that namespace (`namespace_member.role`)
6. Check namespace status (`FROZEN` → deny write operations)
7. Merge platform permissions + namespace role, evaluate whether the requirement is met

| Operation | Required Permission | Evaluation Logic |
|------|---------|---------|
| Publish a skill package | `skill:publish` | Ordinary users must be members of the target namespace; `SUPER_ADMIN` can bypass membership check and publish directly |
| Submit an existing version for review | `review:submit` | The owner themselves, or namespace `ADMIN` / `OWNER`, or `SKILL_ADMIN` / `SUPER_ADMIN` |
| Manage a skill (archive/version management) | `skill:manage` | At least namespace ADMIN, or the owner themselves |
| Promote to global | `skill:promote` | At least namespace ADMIN, or the owner themselves |
| Review skill publication | `review:approve` | Namespace `ADMIN` / `OWNER`, or `SKILL_ADMIN` / `SUPER_ADMIN`; only `SUPER_ADMIN` can review their own review task |
| Review a promotion request | `promotion:approve` | SKILL_ADMIN / SUPER_ADMIN |
| Hide/restore a skill | `skill:manage` | `SUPER_ADMIN` only |
| Retract a published version (YANK) | `skill:manage` | `SKILL_ADMIN` / `SUPER_ADMIN` |
| Manage user roles | `user:manage` | USER_ADMIN / SUPER_ADMIN |
| Approve user access | `user:approve` | USER_ADMIN / SUPER_ADMIN |
| View audit logs | `audit:read` | AUDITOR / SUPER_ADMIN |

Permission axis notes:
- The namespace role is the permission axis; namespace ADMIN has full management rights over all skills within the namespace, regardless of the owner
- `owner_id` semantics represent the "primary maintainer"; when the owner is a MEMBER, they can only manage skills they created
- In enterprise settings with frequent personnel changes, namespace ADMIN can still fully manage all skills after an owner leaves

### 6.1 Review and Promotion API Path Scope

| API Path | Scope | Permission Required |
|----------|---------|---------|
| `POST /api/v1/reviews/{id}/approve` | Skill publish review | Namespace `ADMIN` / `OWNER`, or `SKILL_ADMIN` / `SUPER_ADMIN` |
| `POST /api/v1/promotions/{id}/approve` | Promote to global review | `SKILL_ADMIN` / `SUPER_ADMIN` |
| `GET /api/v1/admin/audit-logs` | Audit log query | AUDITOR / SUPER_ADMIN |
| `PUT /api/v1/admin/users/{id}/roles` | User role management | USER_ADMIN / SUPER_ADMIN |
| `POST /api/v1/admin/users/{id}/approve` | User access approval | USER_ADMIN / SUPER_ADMIN |

In the current implementation, both review and promotion go through a unified portal API; whether an operation is permitted is determined by the service layer based on a combined evaluation of namespace role and platform role, not by a forked routing table.

## 7. Session Design

- Storage: Spring Session + Redis (required; essential for multi-Pod environments)
- Serialization: JSON
- Expiration: 8 hours by default; automatically cleaned up by Redis TTL

### 7.1 Session Contents

The Session stores the following fields:
- `userId`: platform user ID
- `displayName`: display name
- `oauthProvider`: OAuth provider used for login
- `currentNamespaceId`: currently selected namespace (optional)
- `platformRoles`: list of platform roles (e.g., `["SKILL_ADMIN", "AUDITOR"]`), queried from `user_role_binding` → `role` and written at login time
- `roleVersion`: role version number for cache consistency

### 7.2 Role Cache Consistency Mechanism

Platform role changes must take effect immediately (e.g., revoking review permissions); they cannot wait for the Session to expire:

1. Read `roleVersion` from the Session on each request
2. Compare with `user:{userId}:roleVersion` in Redis
3. Version matches → use `platformRoles` from the Session directly
4. Version mismatch → reload roles from the database, update the Session

When an admin modifies a user's roles, increment that user's `roleVersion` in Redis.

## 8. CSRF Protection

Using the Cookie-to-Header pattern:
- The backend sets the `XSRF-TOKEN` Cookie (`HttpOnly=false`)
- The frontend reads the Token from the Cookie and puts it in the request header `X-XSRF-TOKEN`
- The backend verifies that the header and cookie match
- The CLI API (`/api/v1/**`) and the compatibility layer (`/api/v1/**`) are exempt from CSRF (they use Bearer Tokens without cookies)

## 9. Frontend Permission Control

### 9.1 `/api/v1/auth/me` Response Structure

```json
{
  "code": 0,
  "msg": "Fetched successfully",
  "data": {
    "userId": 42,
    "displayName": "zhangsan",
    "email": "zhangsan@company.com",
    "avatarUrl": "https://...",
    "oauthProvider": "github",
    "platformRoles": ["SKILL_ADMIN", "AUDITOR"],
    "namespaces": [
      { "slug": "ai-team", "role": "ADMIN" },
      { "slug": "global", "role": "MEMBER" }
    ]
  },
  "timestamp": "2026-03-12T06:00:00Z",
  "requestId": "req-123"
}
```

Frontend permission evaluation is based on `platformRoles` + `namespaces[].role`; the backend queries permission codes through the `role_permission` table.

Unified constraints:
- Responses from `/api/v1/auth/me`, `/api/v1/auth/providers`, and similar endpoints must uniformly use the `code/msg/data/timestamp/requestId` outer structure.
- `/api/v1/auth/session/bootstrap` must also follow the same unified response structure.
- `msg` must go through Spring Boot's standard `MessageSource` i18n mechanism.
- The locale must be automatically obtained from the request context; it must not be explicitly passed in the controller.
- Authentication failures return `401`, but the JSON outer structure remains consistent, e.g., `{"code":401,"msg":"Login required","data":null,...}`.

### 9.2 usePermission() Hook

```typescript
function usePermission() {
  const { data: me } = useQuery({ queryKey: ['auth', 'me'], queryFn: fetchMe })

  const hasRole = (role: string) => me?.platformRoles.includes(role) ?? false
  const isSuperAdmin = () => hasRole('SUPER_ADMIN')
  const isSkillAdmin = () => hasRole('SKILL_ADMIN') || isSuperAdmin()
  const isUserAdmin = () => hasRole('USER_ADMIN') || isSuperAdmin()
  const isAuditor = () => hasRole('AUDITOR') || isSuperAdmin()

  return {
    isLoggedIn: !!me,
    isSuperAdmin,
    isSkillAdmin,
    isUserAdmin,
    isAuditor,

    // Namespace role evaluation
    getNamespaceRole: (slug: string) =>
      me?.namespaces.find(n => n.slug === slug)?.role,
    isNamespaceAdmin: (slug: string) =>
      ['OWNER', 'ADMIN'].includes(me?.namespaces.find(n => n.slug === slug)?.role ?? ''),
    isNamespaceMember: (slug: string) =>
      ['OWNER', 'ADMIN', 'MEMBER'].includes(me?.namespaces.find(n => n.slug === slug)?.role ?? ''),
  }
}
```

### 9.3 Route-Level Guards

Evaluated in TanStack Router's `beforeLoad`:

| Route | Condition |
|------|------|
| `/dashboard/*` | Logged in |
| `/dashboard/namespaces/{slug}/reviews` | Logged in + at least namespace ADMIN |
| `/admin/*` | Logged in + holds at least one platform role (SUPER_ADMIN / SKILL_ADMIN / USER_ADMIN / AUDITOR) |

When conditions are not met: not logged in → redirect to login; logged in but no permission → display 403 page.

### 9.4 Operation-Level Control

| Scenario | Evaluation Logic | UI Behavior |
|------|---------|---------|
| "Submit for publish" button on skill detail page | `isNamespaceMember(namespace)` | Hidden for non-members |
| "Approve/Reject" button in review list | Team namespace: `isNamespaceAdmin(namespace)`; Global namespace: `isSkillAdmin()` | Hidden when no permission |
| User management page | `isUserAdmin()` | Hidden when no permission |
| "Set as SUPER_ADMIN" on user management page | `isSuperAdmin()` | Visible to super-admins only |
| Audit log page | `isAuditor()` | Hidden when no permission |
| "Archive" button on skill detail page | `isNamespaceAdmin(namespace)` or current user is owner | Otherwise hidden |
| "Add member" button in namespace | `isNamespaceAdmin(namespace)` | Hidden for non-admins |
| Favorite/rating buttons | `isLoggedIn` | Prompt to log in when clicked if not logged in |

### 9.5 Login Interaction

```
Frontend login button
    │
    ▼
window.location.href = '/oauth2/authorization/github'
    │
    ▼
(Backend OAuth2 flow, transparent to user)
    │
    ▼
Redirect to frontend after callback (e.g., /?login=success)
    │
    ▼
Frontend detects URL parameter → calls /api/v1/auth/me → updates login state
```

The frontend does not need to introduce any additional OAuth library; the login flow is entirely handled by the backend Spring Security. The frontend only needs to:
- Call `/api/v1/auth/providers` to get the list of available providers and render login buttons dynamically
- Handle the post-login redirect
- Detect login state via `/api/v1/auth/me`

### 9.6 Security Boundary Principles

- Frontend permission control is a UX optimization, not a security boundary
- Each backend write endpoint independently validates permissions; it does not trust frontend evaluations
- Hiding buttons on the frontend ≠ security; users can call the API directly, and the backend must intercept

## 10. Permission Matrix (Complete)

The following matrix lists the permission evaluation source for each API endpoint and serves as the sole reference for backend implementation.

### 10.1 Public API (anonymously accessible)

| Endpoint | Anonymous | Authenticated | Evaluation Logic |
|------|------|--------|---------|
| `GET /api/v1/skills` (search) | `PUBLIC` only, and only searches `ACTIVE`, non-hidden, indexed skills | `PUBLIC + NAMESPACE_ONLY (member namespaces) + PRIVATE (owner/admin)` | `SearchVisibilityScope` + search index status |
| `GET /api/v1/skills/{ns}/{slug}` | Only published and visible `PUBLIC` skills | Same as left, plus owner can read unpublished skill, namespace `ADMIN` / `OWNER` can read hidden | `visibility + latest_version_id + hidden + namespace membership` |
| `GET /api/v1/skills/{ns}/{slug}/versions` | `PUBLISHED` versions only | Owner / namespace `ADMIN` / `OWNER` can see all five statuses | Same as above + version status filter |
| `GET /api/v1/skills/{ns}/{slug}/download` | Anonymous download only for `PUBLIC` skills in the global namespace | After login, evaluated by visibility; download target version must be `PUBLISHED` | visibility + namespace type + version status |
| `GET /api/v1/skills/{ns}/{slug}/resolve` | Anonymous access only for `PUBLIC` skills in the global namespace | Same as above | visibility + namespace type + version status |
| `GET /api/v1/namespaces` | All | All | No restriction |

### 10.2 Authenticated API

| Endpoint | Permission Required | Evaluation Source |
|------|---------|---------|
| `POST /api/v1/skills/{ns}/{slug}/star` | Logged in | Session/Token |
| `POST /api/v1/skills/{ns}/{slug}/rating` | Logged in | Session/Token |
| `POST /api/v1/reviews` | Owner themselves, or namespace `ADMIN` / `OWNER`, or `SKILL_ADMIN` / `SUPER_ADMIN` | `skill.owner_id` / `namespace_member.role` / platform roles |
| `POST .../versions/{ver}/withdraw-review` | Submitter themselves | `review_task.submitted_by` |
| `PUT /api/v1/skills/{ns}/{slug}/tags/{tag}` | At least namespace ADMIN or owner | `namespace_member.role` or `skill.owner_id` |
| `POST /api/v1/skills/{ns}/{slug}/archive` | At least namespace ADMIN or owner | `namespace_member.role` or `skill.owner_id` |
| `POST .../versions/{ver}/rerelease` | At least namespace ADMIN or owner; source version must be `PUBLISHED` | `namespace_member.role` or `skill.owner_id` + `skill_version.status` |
| `DELETE .../versions/{ver}` | At least namespace ADMIN or owner (only `DRAFT` / `REJECTED`) | `namespace_member.role` or `skill.owner_id` + `skill_version.status` |

### 10.3 CLI API

| Endpoint | Credential Required | Additional Evaluation |
|------|---------|---------|
| `GET /api/v1/whoami` | Any valid Bearer Token | None |
| `POST /api/v1/publish` | Bearer Token + `skill:publish` | Ordinary users must be members of the target namespace; `SUPER_ADMIN` can bypass |

### 10.4 Admin API

| Endpoint | Required Platform Role | Evaluation Source |
|------|------------|---------|
| `POST /api/v1/admin/skills/{id}/hide` | SUPER_ADMIN | `user_role_binding` → `role_permission` |
| `POST /api/v1/admin/skills/{id}/unhide` | SUPER_ADMIN | Same as above |
| `POST /api/v1/admin/skills/versions/{versionId}/yank` | SKILL_ADMIN / SUPER_ADMIN | Same as above |
| `PUT /api/v1/admin/users/{id}/roles` | USER_ADMIN / SUPER_ADMIN | Same as above; USER_ADMIN cannot assign SUPER_ADMIN |
| `POST /api/v1/admin/users/{id}/approve` | USER_ADMIN / SUPER_ADMIN | Same as above |
| `POST /api/v1/admin/users/{id}/ban` | USER_ADMIN / SUPER_ADMIN | Same as above |
| `GET /api/v1/admin/audit-logs` | AUDITOR / SUPER_ADMIN | Same as above |

### 10.5 Namespace API

| Endpoint | Required Namespace Role | Evaluation Source |
|------|-------------------|---------|
| `POST /api/v1/namespaces/{slug}/members` | At least namespace ADMIN | `namespace_member.role` |
| `DELETE /api/v1/namespaces/{slug}/members/{userId}` | At least namespace ADMIN | `namespace_member.role` |
| `POST /api/v1/promotions` | At least namespace ADMIN or owner | `namespace_member.role` or `skill.owner_id` |

### 10.6 Compatibility API (Bearer Token authentication)

| Endpoint | Credential Required | Additional Evaluation |
|------|---------|---------|
| `GET /api/v1/whoami` | Any valid Bearer Token | None |
| `GET /api/v1/search` | Optional (anonymous limited to PUBLIC) | `SearchVisibilityScope` |
| `GET /api/v1/resolve` | Optional (anonymous limited to PUBLIC in global namespace) | visibility + namespace type + version status |
| `GET /api/v1/download/{slug}/{version}` | Optional (anonymous limited to PUBLIC in global namespace) | visibility + namespace type + version status |
| `POST /api/v1/publish` | Bearer Token + `skill:publish` | Ordinary users must be members of the target namespace; `SUPER_ADMIN` can bypass (namespace resolved from canonical slug) |
