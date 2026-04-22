# Skill Detail and Review Page File Browser Sidebar - Product Requirements Document (PRD)

## Requirements Description

### Background
- The current skill detail page `space/global/skill-writer` and the review detail section both provide "Overview / Files / Versions" three tabs, but the files area only shows a flat file list with no ability to browse directory hierarchy or view file contents directly within the page.
- The skill detail page already has the ability to read individual file content by path, used for README loading; the review detail page currently only returns `files`, `documentationPath`, and `documentationContent`, and does not yet support reading arbitrary file content by path.
- Users need to quickly browse the directory structure and specific file content of a skill package without downloading the entire zip file, improving the efficiency of browsing details and making review decisions.

### Business Problem
- A flat file list cannot reflect directory hierarchy, making it difficult for users to understand the skill package structure.
- Reviewers cannot open arbitrary files on the review page to verify implementation details; they can only rely on the README or download the archive for offline inspection.
- The three existing tabs already serve different purposes, and continuing to push file browsing into the current "Files" tab would increase the cost of cross-file viewing in the "Overview" and "Versions" contexts.

### Target Users
- General users browsing skill details
- Authors / namespace members managing skills
- Reviewers and administrators viewing skill content in the review center

### Value Proposition
- Replace the current flat file list with a unified sidebar file browsing experience, reducing the cost of understanding skill package structure.
- Provide consistent file preview capability on both the skill detail page and the review page, reducing download operations and context switching.
- Keep the main semantics of the three existing tabs unchanged, while allowing users to quickly view file content from any tab.

## Feature Overview

### Core Features
1. Add a persistent file browser sidebar to both the skill detail page and the review detail page.
2. Refactor the existing flat `files` list into a directory tree with expandable/collapsible folders.
3. After clicking a file node, preview file content via a dialog.
4. Support Markdown document rendering, source code preview for common text files, and a "preview not supported" notice for large files or unsupported file types.
5. Provide a download entry for files that cannot be previewed.
6. On desktop, use a right-side sidebar layout; on mobile, move the file browser area below the main content area.

### Scope of This Release
- Skill detail page: All three tabs show the same file browser sidebar based on the current main version.
- Review detail page: All three tabs show the file browser sidebar with support for clicking any file to preview.
- The file tree defaults to expanding the first level of directories; other directories expand on demand.
- The sidebar should display auxiliary information such as file type or file size.
- After clicking a file, use a dialog to preview it without switching the current tab.

### Explicitly Excluded
- In-sidebar file name search / path filtering.
- Independently switching the browsed file version on the skill detail page.
- Design and implementation of permission boundaries for version-level browsing on the review page.
- Inline preview of images, audio/video, and rich binary files.
- Truncated preview of very large files.

### Future Extension Directions
- Browse file trees and file previews by version, with access policies designed around permission controls.
- Enhanced interactions such as sidebar search filtering, recently opened files, and selected file highlighting.
- More complete syntax highlighting for text files such as JSON / YAML / TS / JS.
- Controlled truncated preview of very large text files, based on structured metadata returned by a server-side preview API.

## Detailed Requirements

### User Interaction Flow

#### Skill Detail Page
1. The user enters the skill detail page and sees the three tabs "Overview / Files / Versions" by default.
2. Regardless of which tab the user is on, the page displays the file browser sidebar.
3. The sidebar shows a directory tree based on the current main version, with the first level of directories expanded by default.
4. The user clicks a folder node to expand or collapse that directory.
5. The user clicks a file node to open the file preview dialog.
6. If the file is Markdown, it is rendered in document style.
7. If the file is a common text file, it is displayed in source code block style.
8. If the file is binary, an unsupported type, or too large, the dialog shows a "preview not supported" notice and provides a file download entry.

#### Review Detail Page
1. The reviewer expands the review detail section.
2. In any of the "Overview / Files / Versions" tabs, the file browser sidebar is visible.
3. The reviewer clicks any file to open the same file preview dialog as on the skill detail page.
4. If the review page's existing API cannot provide the target file content, a new or extended API must be added to fill in the capability.

### Page Layout Requirements

#### Desktop
- The main content area and the file browser sidebar form a two-column layout.
- The main content of the three tabs retains its original semantics:
  - Overview: README / documentation body.
  - Files: The file tree itself can serve as a supplementary or explanatory area for the main content, but is no longer the only file entry point.
  - Versions: Version list and lifecycle information.
- File preview uses a standalone dialog to avoid changing the main content layout or switching the current tab.

#### Mobile
- Do not enforce a two-column layout.
- The file browser area moves below the main content area, remaining visible in all three tabs.
- The file preview dialog should prioritize a near-fullscreen mobile drawer experience.
- Avoid horizontal scrolling as the primary interaction method.

### File Tree Behavior
- The input data source is the existing flat `SkillFile[]` list; the frontend is responsible for building tree nodes.
- Node types are divided into directory nodes and file nodes.
- Directory nodes support expand/collapse.
- File nodes support clicking to open the preview dialog.
- The sidebar displays file type or file size information to help users judge the nature of a file.
- The first level of directories is expanded by default; deeper directories are collapsed by default.

### File Preview Behavior
- Markdown files: Reuse existing Markdown rendering capability.
- Text files: Preferably rendered as source code / plain text, preserving a scrollable reading experience.
- Binary files: Show "Preview not supported for this file type."
- Very large files: Show "File too large to preview," with a download entry.
- All non-previewable files must provide an accessible download option.
- The preview dialog must display the current file path so users can confirm what they are viewing.

### Data and Interface Requirements

#### Skill Detail Page
- Continue to reuse the current ability to read file content by path.
- The current single-file read capability used specifically for README needs to be abstracted into a general "read any file" query logic for use by the preview dialog.

#### Review Detail Page
- The ability to read any file content by path needs to be added.
- Acceptable implementation approaches:
  1. Add a new file reading API specific to the review context.
  2. Extend the current review detail data-fetching pipeline to add the ability to read any file by path.
- The goal is to align the file preview capability of the review page with that of the skill detail page, not just support the README.

### Open-Source Component Strategy
- Before implementation, first evaluate whether mature open-source components can meet the file tree or code preview requirements.
- Evaluation prerequisite: The styles must be able to naturally integrate with the current React + Tailwind + existing UI system.
- If a third-party component does not meet requirements in style consistency, bundle size, mobile adaptation, or maintenance cost, fall back to a lightweight custom implementation.
- The current project already has `react-markdown`, `rehype-highlight`, and existing Dialog capabilities; these should be reused first to avoid introducing heavily conflicting heavyweight components.

## Design Decisions

### Interaction Decision
- Adopt a "persistent file navigation + dialog preview" model, rather than switching the main content tab or reading content directly within the sidebar.
- Rationale:
  - Maintains the semantic stability of the three existing tabs.
  - Allows users to quickly view files within the "Overview" or "Versions" context.
  - Better suited for mobile, handling reading behavior independently in a dialog layer.

### Responsive Decision
- Desktop: Persistent right-side sidebar.
- Mobile: File browser area below main content + near-fullscreen preview drawer.
- Must ensure no abnormal horizontal scrolling at common widths such as 320 / 375 / 414 / 768 / 1024 / 1440.

### Style and Usability Decision
- Continue the current data-dense management interface style; do not introduce third-party visual language that conflicts with the existing design system.
- File tree nodes, dialog close buttons, and download buttons must have clear hover/focus states.
- Interaction animations should be within 150-300ms and respect `prefers-reduced-motion`.
- Mobile tap targets must meet the minimum touchable size.

## Technical Constraints

### Frontend Constraints
- Must be compatible with the existing skill detail page and review detail page structure, without breaking the main content or existing operations of the three tabs.
- Reuse existing Dialog, MarkdownRenderer, i18n, and TanStack Query patterns.
- The file tree is built on the frontend from the flat file list; the backend is not required to return a nested directory structure.
- Introducing new components must not cause noticeable drift in the existing styling system.

### Backend Constraints
- In this release, it is acceptable to add new APIs or extend existing response structures for the review page, but changes to the database schema should be avoided.
- File reading capability should be limited to the skill version accessible in the current review context and must not expand permission boundaries.
- For very large files or unsupported preview types, the backend should be able to return a clear error or metadata so the frontend can distinguish the reason a file cannot be previewed.

### Performance Constraints
- Opening the file tree must not block the initial page render.
- File previews are loaded on demand; all file content must not be fetched at once.
- Expanding/collapsing directory tree nodes should remain instantly responsive, with no noticeable lag from large-scale re-renders.

### Security Constraints
- Continue to follow the existing authorization boundaries of the skill detail page and review page.
- When adding file content reading capability to the review page, ensure that only audit-related roles can access the corresponding resources.
- Arbitrary path construction must not be used to access content outside the skill package.

### Internationalization Constraints
- Both Chinese and English require new copy for file browsing, preview, preview-not-supported, large file notices, and download actions.

## Risk Assessment

### Technical Risks
1. The review page lacks the ability to read arbitrary file content by path; if the backend API design is unclear, it may lead to rework during frontend-backend integration.
2. Third-party file tree / code viewer components may not match the existing Tailwind style, creating style integration costs.
3. If file type detection and large file handling policies are inconsistent, it may cause behavioral differences between the detail page and the review page.

### Interaction Risks
1. If the layout boundary between the desktop two-column and mobile single-column layouts is not well controlled, horizontal scrolling or content crowding may occur.
2. If the dialog preview does not handle long text properly, the scroll area may be difficult to use or the reading experience may be poor.

### Mitigations
- Prioritize reusing existing Markdown, Dialog, and query patterns to reduce the surface area of new introductions.
- Abstract "read content by path" into a shared model used uniformly by both the detail page and the review page.
- First define a unified "previewable / non-previewable / downloadable" determination rule before starting implementation.
- Treat third-party component inclusion as an optional path, not a prerequisite dependency.

## Acceptance Criteria

### Functional Acceptance
- The file browser sidebar is visible in all three tabs of the skill detail page.
- The file browser sidebar is visible in all three tabs of the review detail page.
- The flat file list is correctly converted to a directory tree, supporting folder expand/collapse.
- Clicking a file node opens the preview dialog.
- Markdown files render correctly.
- Common text files are displayed as source code / plain text.
- Binary files or very large files show a "preview not supported" notice.
- Non-previewable files provide a download entry.
- The review page supports clicking any file and previewing it, not just the README.

### Quality Acceptance
- Desktop uses a right-side sidebar layout; mobile moves the file browser area below the main content.
- No abnormal horizontal scrolling at common breakpoints.
- Does not affect the existing content and operations of the "Overview / Files / Versions" tabs.
- New copy is covered by both Chinese and English internationalization.

## Execution Phases

### Phase 1: Shared Model and Interaction Design
- Define the file tree node model, previewable type rules, and non-previewable notice rules.
- Evaluate whether there are reusable open-source file tree / text preview capabilities, and finalize the component selection decision.

### Phase 2: Skill Detail Page Integration
- Abstract the "read any file" query logic.
- Upgrade the flat file list on the skill detail page to a directory tree sidebar.
- Integrate dialog preview and download capability.

### Phase 3: Review Page Capability Gap Filling
- Add a new API or data pipeline for reading arbitrary file content on the review page.
- Integrate the shared file tree and preview dialog into the review detail section.

### Phase 4: Regression and Experience Refinement
- Add Chinese and English copy.
- Verify desktop / mobile layout, dialog scrolling, and non-previewable scenarios.
- Add regression tests to ensure existing tab content and review workflow are not affected.

## Out-of-Scope Requirements
- File browser version switching requires a separate design of permission boundaries, interaction entry points, and constraints that do not affect existing features; this is noted but not implemented in this release.

## Related Documents

### Requirements Documents
- [API Interface Contract](../requirements/2026-03-20-skill-file-browser-sidebar/05-api-contract.md) - Defines frontend-backend interface specifications
- [Acceptance Cases](../requirements/2026-03-20-skill-file-browser-sidebar/04-acceptance-cases.md) - Functional acceptance test cases

### Execution Plan
- [Implementation Plan](../superpowers/plans/2026-03-22-skill-file-browser-sidebar.md) - Detailed development task breakdown and execution steps

### Technical References
- Existing components:
  - `web/src/features/skill/file-tree.tsx` - Current flat file list implementation
  - `web/src/features/skill/markdown-renderer.tsx` - Markdown renderer
  - `web/src/shared/ui/dialog.tsx` - Dialog component
- Existing APIs:
  - `GET /api/v1/skills/{namespace}/{slug}/versions/{version}/file?path=...` - Skill file read API
  - `GET /api/v1/reviews/{id}` - Review detail API (needs extension)
