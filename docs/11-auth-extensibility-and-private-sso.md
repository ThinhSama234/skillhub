# Authentication Extensibility and Private SSO Compatibility Design

## 1. Goals

Without affecting the current open-source edition's OAuth and local account login capabilities, reserve stable extension points for future private repository integration with enterprise SSO, and keep code differences confined to the provider implementation layer and a small configuration layer.

## 2. Confirmed Constraints

- Private SSO provides a stable, unique UID
- Both username/password validation and Cookie session validation return the same stable UID
- Production deployment is expected to be `skill.xxx.com` and `sso.xxx.com`
- The private edition can call SSO to validate username/password via backend internal interfaces/RPC
- First SSO login automatically creates a skillhub account
- No account merge design; no dependency on email
- Logout propagation can retain an extension point, but is not an immediate goal

## 3. Open-Source Edition Compatibility Strategy

### 3.1 Do Not Change the Existing Main Flow

- Existing OAuth login flow remains unchanged
- Existing local username/password login remains unchanged
- Existing `/api/v1/auth/providers` protocol remains unchanged
- No real private SSO implementation is introduced in the open-source edition

### 3.2 New Public Extension Protocols

The open-source edition adds an explicit passive session bootstrap endpoint:

- `POST /api/v1/auth/session/bootstrap`

Request:

```json
{
  "provider": "private-sso"
}
```

Behavior constraints:

- Disabled by default; controlled by `skillhub.auth.session-bootstrap.enabled=false`
- Returns `403` when disabled
- Returns `400` when the provider does not exist
- Returns `401` when external session validation fails
- On success, establishes a skillhub Session and returns current user information

A disabled-by-default direct-connect auth compatibility endpoint is also added:

- `POST /api/v1/auth/direct/login`

Request:

```json
{
  "provider": "private-sso",
  "username": "alice",
  "password": "secret"
}
```

Behavior constraints:

- Disabled by default; controlled by `skillhub.auth.direct.enabled=false`
- Returns `403` when disabled
- Returns `400` when the provider does not exist
- On success, establishes a skillhub Session and returns current user information
- The open-source edition retains the original `/api/v1/auth/local/login`

### 3.3 Code-Level Extension Points

```java
public interface PassiveSessionAuthenticator {
    String providerCode();
    Optional<PlatformPrincipal> authenticate(HttpServletRequest request);
}
```

```java
public interface DirectAuthProvider {
    String providerCode();
    PlatformPrincipal authenticate(DirectAuthRequest request);
}
```

The private edition only needs to add implementations, for example:

- `private-sso-cookie`: reads a shared Cookie and validates it against SSO
- If needed later, a "direct username/password auth provider" extension point can be added

To reduce frontend hard-coding in private forks, extension providers can additionally declare a display name:

- `DirectAuthProvider.displayName()` defaults to `providerCode()`
- `PassiveSessionAuthenticator.displayName()` defaults to `providerCode()`
- `GET /api/v1/auth/methods` returns this display name, which the login page can render directly

## 4. What Has Been Implemented in This Round

- Added `PassiveSessionAuthenticator` SPI
- Added `DirectAuthProvider` SPI
- Added unified session establishment service `PlatformSessionService`
- Added `POST /api/v1/auth/session/bootstrap` protocol
- Added `POST /api/v1/auth/direct/login` protocol
- Added `skillhub.auth.direct.enabled` toggle, disabled by default
- Added `skillhub.auth.session-bootstrap.enabled` toggle, disabled by default
- Frontend added runtime-config-based username/password compatibility integration layer
- Frontend added runtime-config-based passive session compatibility entry
- Frontend added explicit button and optional auto-attempt logic; both disabled by default
- Added controller integration tests to verify:
  - No impact on the existing system when disabled by default
  - A skillhub Session can be established when enabled and an authenticator is provided

Unified session establishment constraints:

- Local login, OAuth success callback, direct auth, session bootstrap, and mock login bypass all go through `PlatformSessionService`
- Session writes uniformly depend on `HttpSession` attributes: `platformPrincipal` and `SPRING_SECURITY_CONTEXT`
- Therefore, when Spring Session Redis is enabled in production, there is no need to separately handle Session serialization or storage logic for different login methods
- Interactive login defaults to rotating the session ID; OAuth flows already in the Spring Security authentication chain reuse the existing `Authentication`

Frontend runtime configuration:

- `SKILLHUB_WEB_AUTH_DIRECT_ENABLED`
- `SKILLHUB_WEB_AUTH_DIRECT_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_ENABLED`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_AUTO`

Usage:

1. For password direct-connect, enable `skillhub.auth.direct.enabled=true` on the backend
2. Private edition provides a `DirectAuthProvider` implementation
3. Frontend sets `SKILLHUB_WEB_AUTH_DIRECT_*`
4. For passive session, enable `skillhub.auth.session-bootstrap.enabled=true` on the backend
5. Private edition provides a `PassiveSessionAuthenticator` implementation
6. Frontend sets the bootstrap provider and toggle
7. Login page displays the compatibility entry, or automatically attempts bootstrap once when configuration allows

## 5. Follow-up Recommendations

- When the private edition implements `DirectAuthProvider` and/or `PassiveSessionAuthenticator`, extend only the provider layer; do not duplicate session establishment logic
- Private editions should prefer explicit bootstrap over transparent global interceptor auto-login
- If logout propagation is needed later, extend only through `LogoutPropagationHandler`; do not modify the existing main logout flow

## 6. Implementation Playbook

For more detailed private SSO integration steps, best practices, test matrix, and execution constraints for subsequent coding agents, see:

- [12-private-sso-integration-playbook.md](/Users/xudongsun/github/skillhub/docs/12-private-sso-integration-playbook.md)
