# Private SSO Integration Compatibility Layer Implementation Playbook

## 1. Document Purpose

This document is intended for two audiences:

- Developers who will integrate enterprise SSO in a private repository at a later stage
- Coding agents that need to continue development based on the current open-source compatibility layer

This document is not an authentication architecture overview — it is an implementation playbook. The goal is to let future implementers start integration work directly from the current results without needing full historical context, and to keep the differences between the private repository and the open-source repository confined to the provider implementation layer and a small amount of configuration.

Related documents:

- [03-authentication-design.md](/Users/xudongsun/github/skillhub/docs/03-authentication-design.md)
- [06-api-design.md](/Users/xudongsun/github/skillhub/docs/06-api-design.md)
- [08-frontend-architecture.md](/Users/xudongsun/github/skillhub/docs/08-frontend-architecture.md)
- [11-auth-extensibility-and-private-sso.md](/Users/xudongsun/github/skillhub/docs/11-auth-extensibility-and-private-sso.md)

## 2. Current Context and Confirmed Constraints

The true goal of this round of work is not to implement private SSO inside the open-source version, but to first transform the open-source frontend and backend into a stable compatibility integration layer.

The confirmed business premises are as follows:

- The private SSO can return a stable and unique UID
- Both the username/password verification endpoint and the Cookie-based session verification endpoint return the same UID
- SkillHub private edition and the private SSO will be deployed under the same primary domain, for example `skill.xxx.com` and `sso.xxx.com`
- The private edition can call the SSO's username/password verification capability via internal interfaces or RPC
- The first SSO login automatically creates a SkillHub account
- Account merging is not considered
- The `email` field is not relied upon
- Synchronized logout is not required, but a low-priority extension point may be retained

This means the correct way to integrate private SSO going forward is:

- Model SSO as a new authentication source `private-sso`
- Use `providerCode + subject` to represent the external identity, where `subject` is the SSO UID
- Reuse the platform's unified session establishment logic rather than creating a separate login state mechanism

## 3. What the Current Compatibility Layer Already Provides

### 3.1 Backend Extension Points

The current open-source edition already provides the following backend compatibility capabilities:

- `DirectAuthProvider`
  - For the pattern "frontend collects username/password, backend calls external system to verify"
- `PassiveSessionAuthenticator`
  - For the pattern "browser automatically sends SSO Cookie, backend reads the request and verifies with SSO"
- `PlatformSessionService`
  - For establishing a unified SkillHub Web Session
- `LogoutPropagationHandler`
  - For future low-priority logout synchronization

Key code locations:

- [DirectAuthProvider.java](/Users/xudongsun/github/skillhub/server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/direct/DirectAuthProvider.java)
- [PassiveSessionAuthenticator.java](/Users/xudongsun/github/skillhub/server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/bootstrap/PassiveSessionAuthenticator.java)
- [PlatformSessionService.java](/Users/xudongsun/github/skillhub/server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/session/PlatformSessionService.java)

### 3.2 Backend Public Protocol

The current open-source edition already provides the following compatibility endpoints:

- `POST /api/v1/auth/direct/login`
- `POST /api/v1/auth/session/bootstrap`
- `GET /api/v1/auth/methods`

The design principles for these endpoints are:

- Disabled by default
- No private SSO implementation by default
- Driven by provider extensions when enabled
- Upon success, establishes a standard Spring Security Session uniformly
- Does not replace the existing `/api/v1/auth/local/login`
- Does not replace existing OAuth login

### 3.3 Frontend Compatibility Layer

The current open-source frontend already supports enabling compatibility entry points via runtime configuration:

- `SKILLHUB_WEB_AUTH_DIRECT_ENABLED`
- `SKILLHUB_WEB_AUTH_DIRECT_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_ENABLED`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_AUTO`

Frontend design principles:

- No private login entry points are enabled by default
- When enabled, switching is done via the compatibility layer without breaking the default behavior of the existing login page
- Prioritizes the unified directory endpoint `/api/v1/auth/methods`
- Passive session login prefers explicit bootstrap rather than silently attempting multiple times on page load

## 4. Recommended Integration Approach for Private SSO

### 4.1 Recommended Overall Strategy

The best practice is not to choose just one approach, but to support both paths simultaneously:

1. Primary path: `DirectAuthProvider`
   - The login page displays an enterprise SSO username/password form
   - The backend calls the private SSO for verification via internal interfaces or RPC
   - Upon successful verification, a SkillHub Session is established for the user

2. Supplementary path: `PassiveSessionAuthenticator`
   - When the user has already logged into the SSO system and the browser will automatically send the shared Cookie
   - The login page allows the user to actively click "Sign in with Enterprise SSO"
   - Or, under very careful conditions, automatically attempt one bootstrap

The rationale:

- Covers both "not yet logged into SSO" and "already logged into SSO" user states
- Does not depend on the browser already having the Cookie
- Does not place all login success rates on Cookie domain, SameSite, expiration policy, and other details
- Does not change the original open-source login logic

### 4.2 Discouraged Approaches

The following approaches are not recommended for the private edition:

- Automatically attempting SSO login for all anonymous requests in a global servlet filter
- Directly writing `HttpSession` and `SecurityContext` logic inside controllers, filters, or providers
- Mapping the private SSO UID to a temporary integer ID and using that as the primary user identifier
- Automatically merging accounts by email
- Having the frontend directly call the private SSO's internal verification endpoints
- Adding a completely parallel "private login session mechanism" to the private edition alongside the open-source one

## 5. Minimum-Difference Implementation Plan for the Private Edition

### 5.1 What the Backend Should Add

It is recommended that the private repository only add the following implementation classes without modifying the main chain:

1. One `DirectAuthProvider` implementation
2. One `PassiveSessionAuthenticator` implementation
3. An optional `LogoutPropagationHandler` implementation
4. Private configuration properties class or private configuration items
5. If the SSO returns an external UID rather than an existing platform user, add a private service for "looking up or creating a platform user by SSO UID"

Suggested naming examples:

- `PrivateSsoDirectAuthProvider`
- `PrivateSsoPassiveSessionAuthenticator`
- `PrivateSsoLogoutPropagationHandler`
- `PrivateSsoProperties`
- `PrivateSsoIdentityService`

The following public classes' responsibilities should not be modified:

- `PlatformSessionService`
- `LocalAuthController`
- `AuthController`
- `SecurityConfig`

### 5.2 Recommended Backend Implementation Steps

#### Step 1: Define the provider code

The private edition uses a stable provider code uniformly:

```text
private-sso
```

Requirements:

- `DirectAuthProvider.providerCode()` and `PassiveSessionAuthenticator.providerCode()` must return the same value
- Do not define two different provider codes for "username/password login" and "Cookie login"
- If a more user-friendly login page label is needed, override the provider's `displayName()` at the same time, to avoid the frontend maintaining a separate private display name mapping

#### Step 2: Encapsulate the SSO client

Do not scatter HTTP or RPC calls directly inside provider implementations. It is recommended to first abstract a private client layer:

```java
public interface PrivateSsoClient {
    PrivateSsoUser verifyPassword(String username, String password);
    Optional<PrivateSsoUser> verifySession(HttpServletRequest request);
}
```

`PrivateSsoUser` should contain at minimum:

- `uid`
- `username`
- `displayName`

Best practices:

- All timeouts, retries, log desensitization, and error code translation belong in the client layer
- The provider layer is only responsible for mapping external results into the platform's required identity object
- Recording plaintext passwords is prohibited

#### Step 3: Implement the user mapping service

Private SSO does not rely on email and does not perform account merging, so it is recommended that the private edition implement a dedicated service:

```java
public interface PrivateSsoIdentityService {
    PlatformPrincipal resolveOrCreate(PrivateSsoUser ssoUser);
}
```

Recommended logic:

1. Look up existing bindings by `providerCode=private-sso` and `subject=ssoUid`
2. If it exists, load the corresponding platform user
3. If it does not exist, automatically create a platform user
4. Create a new identity binding
5. Return `PlatformPrincipal`

Requirements:

- Automatically created users should default to `ACTIVE` status
- Do not attempt to merge with existing local accounts or OAuth accounts by email

#### Step 4: Implement `DirectAuthProvider`

Pseudocode:

```java
@Component
public class PrivateSsoDirectAuthProvider implements DirectAuthProvider {

    @Override
    public String providerCode() {
        return "private-sso";
    }

    @Override
    public PlatformPrincipal authenticate(DirectAuthRequest request) {
        PrivateSsoUser ssoUser = privateSsoClient.verifyPassword(
            request.username(),
            request.password()
        );
        return privateSsoIdentityService.resolveOrCreate(ssoUser);
    }
}
```

Requirements:

- Only return the `PlatformPrincipal` after successful authentication
- Do not establish a Session here
- Do not write `SecurityContext` here

#### Step 5: Implement `PassiveSessionAuthenticator`

Pseudocode:

```java
@Component
public class PrivateSsoPassiveSessionAuthenticator implements PassiveSessionAuthenticator {

    @Override
    public String providerCode() {
        return "private-sso";
    }

    @Override
    public Optional<PlatformPrincipal> authenticate(HttpServletRequest request) {
        return privateSsoClient.verifySession(request)
            .map(privateSsoIdentityService::resolveOrCreate);
    }
}
```

Requirements:

- Only consume Cookies or other passive credentials that the current request already carries
- Do not actively redirect to SSO
- Do not create a Session here directly

#### Step 6: Enable configuration

Enable in the private edition deployment:

```yaml
skillhub:
  auth:
    direct:
      enabled: true
    session-bootstrap:
      enabled: true
```

Recommendations:

- In the pre-release environment, first enable only direct auth
- Enable passive bootstrap only after confirming that Cookie domain and SameSite behavior are reliable

## 6. Frontend Best Practices

### 6.1 Recommended Login Page Strategy

The private edition is recommended to keep the current open-source login page structure but add an enterprise SSO entry point:

- Keep the OAuth button
- Whether to retain local account login is up to the private edition to decide
- Add an enterprise SSO username/password form, or switch the existing password form to the direct auth compatibility endpoint
- Add a "Sign in with Enterprise SSO" button corresponding to `session/bootstrap`

Recommended priority:

1. First, provide a clearly visible enterprise username/password login
2. Second, provide a "Sign in with Enterprise SSO" button
3. Only then consider automatic bootstrap

### 6.2 Recommendations for Automatic Bootstrap

Only enable `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_AUTO=true` when all of the following conditions are met simultaneously:

- It has been confirmed that the browser can reliably send the SSO Cookie under `skill.xxx.com`
- The UI will not freeze or repeatedly retry on failure
- The page will only attempt it automatically once
- The frontend will not block normal password login due to a failed automatic attempt

If the above conditions are not met, it is recommended to only show an explicit button and let the user trigger it manually.

### 6.3 Frontend Prohibitions

- Do not submit passwords to non-SkillHub backend addresses
- Do not parse or manipulate private SSO internal Cookie details in the browser
- Do not treat a bootstrap failure as a page-level fatal error

## 7. Spring Session Redis Related Constraints

The platform's unified web login state is Spring Session.

When the private edition continues integration, the following rules must be followed:

- All successful logins must go through `PlatformSessionService`
- All web sessions are persisted via `HttpSession`
- Do not manually maintain a second "private SSO session"
- Do not define another set of authentication cache structures in Redis to replace Sessions

What the unified service currently does:

- Writes `platformPrincipal`
- Writes `SPRING_SECURITY_CONTEXT`
- Rotates session ID during interactive login flows

## 8. Security Best Practices

### 8.1 Username/Password Direct Connection Scenario

- Communication between the SkillHub backend and the private SSO must go through the internal network or trusted RPC
- Plaintext passwords are only allowed to exist in the transient path from browser submission to backend SSO call
- Passwords must not appear in logs, tracing, or exception messages
- Timeout and circuit-breaker policies should be set for downstream SSO calls

### 8.2 Cookie Passive Session Scenario

- First confirm that the Cookie domain, path, SameSite, and Secure policies can satisfy `skill.xxx.com` usage
- The bootstrap endpoint should retain CSRF protection
- On failure, only return authentication failure — do not leak excessive Cookie verification details
- Unless there is a clear product requirement, do not implement a transparent site-wide auto-login filter

### 8.3 Identity Mapping Scenario

- Only trust the stable UID; do not use display names as the primary identity basis
- Do not merge by email
- Do not merge by username

## 9. Recommended Test Matrix

### 9.1 Backend Unit Tests

- `DirectAuthProvider` successful authentication
- `DirectAuthProvider` authentication failure
- `PassiveSessionAuthenticator` successfully returns principal with a valid Cookie
- `PassiveSessionAuthenticator` returns empty or failure with an invalid Cookie
- `PrivateSsoIdentityService` automatically creates an account on first login
- `PrivateSsoIdentityService` reuses an existing binding on subsequent login

### 9.2 Backend Integration Tests

- `POST /api/v1/auth/direct/login` can establish a Session after configuration is enabled
- `POST /api/v1/auth/session/bootstrap` can establish a Session after configuration is enabled
- After a successful login, `/api/v1/auth/me` returns the correct user
- Direct auth and the existing `/api/v1/auth/local/login` do not interfere with each other
- Returns `403` when bootstrap is disabled
- Returns `403` when direct auth is disabled

### 9.3 Frontend Tests

- When the runtime switch is not enabled, the login page behavior is consistent with the open-source default
- After enabling direct auth, the password form request goes to `/api/v1/auth/direct/login`
- After enabling the bootstrap button, clicking it triggers a bootstrap request
- After automatic bootstrap failure, users can still use other login entry points normally

### 9.4 Manual Acceptance

- In a browser already logged into SSO, bootstrap can successfully establish a SkillHub login state
- In a browser not logged into SSO, bootstrap fails but does not affect password login
- After a successful direct auth login, the login state is maintained after page refresh
- In a multi-Pod environment, using Spring Session Redis, sessions remain valid after switching instances

## 10. Recommended Development Order

If integration in a private repository is to begin in earnest, it is recommended to proceed in the following order:

1. Implement `PrivateSsoClient`
2. Implement `PrivateSsoIdentityService`
3. Implement `PrivateSsoDirectAuthProvider`
4. First enable `skillhub.auth.direct.enabled=true`
5. Connect the frontend direct auth entry point and complete testing
6. Then implement `PrivateSsoPassiveSessionAuthenticator`
7. Confirm Cookie scope and browser behavior
8. Enable `session-bootstrap`
9. Decide whether to enable automatic bootstrap based on need

## 11. Execution Instructions for Coding Agents

If an AI continues integration work in a private repository, it is recommended to strictly follow these execution rules:

- First read [11-auth-extensibility-and-private-sso.md](/Users/xudongsun/github/skillhub/docs/11-auth-extensibility-and-private-sso.md) and this document
- Do not refactor the existing public authentication main chain unless a clear bug is found
- Implement private SSO specifics first as providers, authenticators, clients, and identity services
- Do not copy `PlatformSessionService` logic
- Do not write Session establishment code repeatedly across multiple controllers or filters
- Any new frontend behavior must ensure that it has absolutely no impact on the open-source edition when the runtime configuration is disabled
- All new endpoints and runtime configurations must be synchronized with documentation updates
- Run backend tests after completing each phase; run `pnpm typecheck` and `pnpm build` when frontend changes are involved

## 12. Definition of Done

When the private edition SSO integration is complete, the following criteria should be met:

- The open-source edition's default login method remains unchanged
- The private edition integrates only through extension points, without copying an independent login architecture
- Direct auth is functional
- Session bootstrap is functional
- The first SSO login automatically creates an account
- Spring Session Redis is uniformly used to carry the web login state
- `/api/v1/auth/me`, RBAC, and existing business endpoints are unaware of the login source
- Documentation, configuration, and tests are complete
