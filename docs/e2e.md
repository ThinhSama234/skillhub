# SkillHub Web E2E Test Guide (Real-Request Mode)

This document describes the real-request (non-mock) test system, execution methods, and maintenance conventions for the current `web/e2e` suite.

## 1. Current Status

`web/e2e` has completed the API mock migration. The current state is as follows:

- `helpers/route-mocks.ts`, `helpers/api-fixtures.ts`, and `helpers/assertions.ts` are no longer used
- `page.route('**/api/...')` API interception is no longer used in specs
- Real authentication and data interaction with the backend are performed via Playwright `request` (`page.context().request`)
- Key session helper: `web/e2e/helpers/session.ts`

Current Playwright configuration (`web/playwright.config.ts`):

- `baseURL`: `http://localhost:3000`
- Browser: `chromium`
- `workers`: `1` (stability is prioritized in real-request mode)
- `fullyParallel`: `false`
- `reporter`: `html`
- `trace: 'on-first-retry'`
- `screenshot: 'on'`
- `webServer.command`: `pnpm exec vite --host 127.0.0.1 --port 3000 --strictPort`

## 2. Directory Structure

```text
web/
├── e2e/
│   ├── auth-entry.spec.ts
│   ├── dashboard-shell.spec.ts
│   ├── landing-navigation.spec.ts
│   ├── public-pages.spec.ts
│   ├── route-guard.spec.ts
│   ├── settings-pages.spec.ts
│   ├── tokens.spec.ts
│   └── helpers/
│       ├── auth-fixtures.ts
│       ├── session.ts
│       └── test-data-builder.ts
├── playwright.config.ts
└── playwright.smoke.config.ts
```

Responsibility conventions:

- `web/e2e/*.spec.ts`: Tests organized by user business flow
- `web/e2e/helpers/auth-fixtures.ts`: Non-network helpers such as locale
- `web/e2e/helpers/session.ts`: Real authentication session establishment (login/register + worker-level isolation)
- `web/e2e/helpers/test-data-builder.ts`: General test data construction and cleanup (namespace/skill/review)

## 3. Current Coverage

The current real-request E2E suite covers 23 specs:

- `auth-entry.spec.ts`: Login entry, registration entry, `returnTo` preservation
- `landing-navigation.spec.ts`: Landing page navigation and anonymous restricted redirects
- `public-pages.spec.ts`: Public legal pages are accessible
- `search-flow.spec.ts`: Search query state and anonymous favorites filter redirect to login
- `route-guard.spec.ts`: Anonymous blocking and accessing protected routes after login
- `skill-detail-browse.spec.ts`: Non-existent namespace/skill detail scenarios after login
- `dashboard-shell.spec.ts`: Dashboard basic shell and quick access entries
- `dashboard-routes.spec.ts`: Dashboard major sub-routes are accessible and namespace governance pages are accessible
- `workspace-pages.spec.ts`: My skills / My namespaces workspace pages are accessible
- `my-namespaces-data.spec.ts`: Create namespace via request and verify visibility in workspace
- `my-skills-data.spec.ts`: Publish skill via request and verify visibility in workspace
- `my-skills-navigation.spec.ts`: Navigate from my skills list to skill detail and back
- `namespace-members-data.spec.ts`: Prepare namespace via request and verify member management page is accessible
- `namespace-page-data.spec.ts`: Prepare namespace/skill via request and verify namespace public page is accessible
- `namespace-reviews-data.spec.ts`: Create review data via request and verify namespace review page is accessible
- `publish-flow-ui.spec.ts`: Upload a real zip on the publish page and verify return to my skills after publishing
- `dashboard-personal-modules.spec.ts`: `/dashboard/stars` and `/dashboard/notifications` personal modules are accessible
- `settings-pages.spec.ts`: Basic behavior of Profile/Security/Notifications pages
- `settings-routing.spec.ts`: `/settings/accounts` redirects to `/settings/security`
- `tokens.spec.ts`: Token management entry is accessible
- `protected-routes.spec.ts`: Anonymous access to dashboard/admin protected routes redirects to login
- `cli-auth.spec.ts`: CLI Auth missing parameters error path
- `role-access-control.spec.ts`: Logged-in regular user accessing governance/admin restricted routes is blocked

## 4. Execution Commands

Prefer using root-level commands:

```bash
make test-e2e-frontend
make test-e2e-smoke-frontend
```

Can also be run directly in the `web` directory:

```bash
cd web && pnpm test:e2e
cd web && pnpm test:e2e:smoke
cd web && pnpm exec playwright test e2e/<feature>.spec.ts
cd web && pnpm test:e2e:ui
```

Notes:

- When services are already manually started, you can run `cd web && pnpm test:e2e` directly
- In CI or standalone environments, Playwright can automatically start the frontend service based on configuration

## 5. Writing Conventions (Real Requests)

### 5.1 API Mocks Are Forbidden

When adding or modifying E2E tests, do not:

- Introduce `page.route('**/api/...')`
- Introduce page-level API mock helpers
- Fake critical business responses in test cases

### 5.2 Authentication Goes Through `session.ts`

- Test cases requiring an authenticated state should reuse `registerSession(page, testInfo)`
- Use worker-level account isolation to avoid concurrency conflicts
- Do not write login/registration flows inline in specs

### 5.3 Selector Priority

- `getByRole`
- `getByLabel`
- `getByTestId`

Avoid deeply coupled CSS selectors.

### 5.4 No Blind Waiting

Do not add `waitForTimeout`. Prefer:

- `await expect(locator).toBeVisible()`
- `await expect(page).toHaveURL(...)`
- `await expect(locator).toContainText(...)`

## 6. Smoke Rules

The smoke suite only keeps critical paths — the goal is to be fast and stable, not to maximize coverage.

Current recommended smoke suite includes:

- `auth-entry.spec.ts`
- `landing-navigation.spec.ts`
- `route-guard.spec.ts`
- `dashboard-shell.spec.ts`

## 7. Common Troubleshooting

- Authentication failure: first confirm the backend is reachable (`http://localhost:8080`) and that the register/login API is working normally
- Intermittent test failure: prioritize checking for selector ambiguity and assertion timing issues; do not use fixed waits to mask the issue
- Concurrency conflicts: confirm whether test cases reuse the unified helper, and avoid sharing mutable test data

## 8. Acceptance Criteria

The migration is considered complete when all of the following conditions are met:

- `web/e2e/**/*.spec.ts` contains no API mocks
- Real-request paths are reachable and stable
- `cd web && pnpm test:e2e` passes in full
- `cd web && pnpm test:e2e:smoke` passes
