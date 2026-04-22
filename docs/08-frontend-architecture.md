# skillhub Frontend Architecture Design

## 1 Technology Stack

| Category | Choice | Notes |
|----------|--------|-------|
| Framework | React 19 + TypeScript | |
| Build | Vite | |
| Routing | TanStack Router | |
| Data Fetching | TanStack Query | Manages all server-side data (API response caching, loading/error states) |
| UI Components | shadcn/ui + Radix UI | |
| Styling | Tailwind CSS | |
| Local State | Zustand | Manages purely client-side state only |
| API Client | openapi-fetch + openapi-typescript | |
| Icons | Lucide React | |

### 1.1 Zustand vs TanStack Query Responsibilities

- **TanStack Query**: Manages all server-side data (API response caching, loading/error states)
- **Zustand**: Manages purely client-side state only (UI preferences, sidebar expansion, theme, currently selected namespace filter, etc.)
- Caching server-side data in Zustand is prohibited

## 2 Page Structure

### 2.1 Portal Area (Public, Anonymous Access)

| Page | Path | Description |
|------|------|-------------|
| Home | `/` | Featured/popular/latest, search entry |
| Search | `/search` | Keyword search + filtering + sorting |
| Namespace Home | `/@{namespace}` | Namespace introduction + skill list |
| Skill Detail | `/@{namespace}/{slug}` | README rendering, versions, rating, star, download |
| Version History | `/@{namespace}/{slug}/versions` | Version list + changelog |

All PUBLIC skills in the portal area can be browsed and downloaded anonymously without login.

### 2.2 Personal Dashboard (Login Required)

| Page | Path | Description |
|------|------|-------------|
| My Skills | `/dashboard/skills` | My published skills + unified lifecycle status |
| Publish Skill | `/dashboard/publish` | Zip upload + preview + submit for review |
| My Stars | `/dashboard/stars` | Starred skills list |
| Token Management | `/dashboard/tokens` | Create/view/revoke |
| My Namespaces | `/dashboard/namespaces` | Namespaces I participate in |

### 2.3 Namespace Management (Requires Namespace ADMIN)

| Page | Path | Description |
|------|------|-------------|
| Member Management | `/dashboard/namespaces/{slug}/members` | Member management |
| Namespace Review | `/dashboard/namespaces/{slug}/reviews` | Pending review list |

### 2.4 Platform Administration (Requires Corresponding Platform Role)

| Page | Path | Required Role | Description |
|------|------|---------------|-------------|
| Review Center | `/admin/reviews` | SKILL_ADMIN | Global pending review list |
| Promotion Review | `/admin/promotions` | SKILL_ADMIN | List of applications to promote to global |
| Skill Management | `/admin/skills` | SKILL_ADMIN | Hide/restore skills, yank published versions |
| User Management | `/admin/users` | USER_ADMIN | User list, role assignment, access approval, ban/unban |
| Audit Logs | `/admin/audit-logs` | AUDITOR | Operation log queries |
| Namespace Management | `/admin/namespaces` | SUPER_ADMIN | Create/archive/freeze |

SUPER_ADMIN can access all admin pages. Route guards check whether the user holds the corresponding role.

## 3 Layout Structure

- Portal area: top navigation + content area, no sidebar, emphasizing browsing experience
- Dashboard / Admin: top navigation + left sidebar, management efficiency first
- Responsive: sidebar collapses to a drawer on mobile

## 3.1 Lifecycle Display Model

The frontend no longer assembles the skill lifecycle from `status + hidden + latestVersionStatus + viewingVersionStatus`; instead, it uniformly consumes projections returned by the backend:

- `headlineVersion`: The primary version displayed on the current page
- `publishedVersion`: The current latest published version
- `ownerPreviewVersion`: A pending-review version visible to the owner / namespace administrator
- `resolutionMode`: `PUBLISHED` / `OWNER_PREVIEW` / `NONE`

Constraints:

- The detail page and "My Skills" list both use `headlineVersion` as the primary display version
- Public distribution-related operations such as install, download, and promotion are only allowed to bind `publishedVersion`
- `hidden` is an independent governance override layer, not part of the version lifecycle state machine

## 4 Login and Authorization

### 4.1 OAuth2 Login Flow (Frontend Perspective)

```
User clicks "Login" button
    │
    ▼
Frontend calls GET /api/v1/auth/providers
    │
    ▼
Renders available OAuth Provider buttons (Phase 1: GitHub only)
    │
    ▼
User clicks "Sign in with GitHub"
    │
    ▼
window.location.href = "/oauth2/authorization/github"
    │
    ▼
(Browser redirects to GitHub → authorize → callback to backend → backend creates Session)
    │
    ▼
Backend redirects back to frontend page (e.g., / or the page the user was previously on)
    │
    ▼
Frontend detects Session Cookie, calls GET /api/v1/auth/me
    │
    ▼
Retrieves user info, renders logged-in UI
```

The frontend requires no OAuth library; login is handled entirely by the backend Spring Security. The frontend is only responsible for:
1. Calling `/api/v1/auth/providers` to get the list of available providers
2. Redirecting to the corresponding `authorizationUrl`
3. After callback, detecting login state via `/api/v1/auth/me`

### 4.2 Reserved Passive Session Bootstrap

For future enterprise SSO compatibility in private deployments, the frontend can explicitly call the following during the login page or application initialization phase:

- `POST /api/v1/auth/session/bootstrap`

This endpoint is disabled by default in the open-source edition; when enabled in the private edition, the frontend can call it once upon detecting an unauthenticated user to attempt to exchange an external SSO Cookie for a skillhub Session. This flow must remain explicitly triggered and must not rely on a globally transparent interceptor by default.

Frontend compatibility integration layer constraints:

- Disabled by default; when the runtime configuration is not enabled, the login page and global behavior are identical to the open-source edition
- The username/password login compatibility layer and the passive session compatibility layer are independent of each other and can be enabled separately
- When enabled, an "Enterprise SSO" compatibility entry appears on the login page
- When the password compatibility layer is enabled, the login page username/password form switches to calling the generic direct-connect auth endpoint
- The frontend should prefer consuming `/api/v1/auth/methods` as the unified login method directory; `/api/v1/auth/providers` is retained for compatibility only
- Optional automatic attempt, but still confined to execution within the login page; not auto-detected on every anonymous visit site-wide
- When bootstrap fails, it should silently fall back to existing local login and OAuth login without interrupting the normal flow

Frontend runtime configuration items:

- `SKILLHUB_WEB_AUTH_DIRECT_ENABLED`
- `SKILLHUB_WEB_AUTH_DIRECT_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_ENABLED`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_PROVIDER`
- `SKILLHUB_WEB_AUTH_SESSION_BOOTSTRAP_AUTO`

Recommended strategies:

- Private edition password direct-connect: `auth_direct_enabled=true`, `auth_direct_provider=private-sso`
- Private edition early stage: `enabled=true`, `provider=private-sso`, `auto=false`
- After validation is stable: reassess whether to switch to `auto=true`

### 4.3 Login State Detection

```
Page loads → GET /api/v1/auth/me
              │
    ┌─────────┴──────────┐
    │ 200: Logged in       │ 401: Not logged in
    │ Store in global state│ Portal pages display normally (anonymous browsing)
    │ Render logged-in UI  │ Dashboard/Admin redirects to login
    └────────────────────┘
```

- TanStack Router `beforeLoad` handles route guards
- Admin routes additionally check roles
- Frontend permission control granularity: see [03-authentication-design.md](./03-authentication-design.md) frontend permission control granularity section

## 5 API Integration Workflow

```
Backend Springdoc → openapi.json
    → openapi-typescript generates types
    → openapi-fetch creates client
    → TanStack Query wraps as hooks
```

## 6 File Upload

Phase 1 Web: zip upload → backend unzips and validates → returns preview → user confirms → submits for review.
Supports drag-and-drop + progress bar.

## 7 Key Interactions

**Skill Detail Page**: SKILL.md Markdown rendering, right-side info panel (version/downloads/rating/stars/tags/namespace), version switching, one-click copy of install command (displays both skillhub CLI format `install @namespace/slug` and ClawHub CLI format `install canonical-slug`). Anonymous users can browse and download; star/rating buttons prompt login.

**Search Page**: Real-time search (debounce 300ms), skill cards, sorting (relevance/downloads/rating/latest), namespace filter. Anonymous users can search PUBLIC skills. Note: Phase 1 search is based on latest version content only; search by tag/version is not supported (see `04-search-architecture.md` section 5.1).

**Review Page**: Left list + right content preview (Markdown + file tree), approve/reject + comment input.
