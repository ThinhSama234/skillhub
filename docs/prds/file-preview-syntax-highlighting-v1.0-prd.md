# File Preview Syntax Highlighting - Product Requirements Document (PRD)

## Requirements Description

### Background
- **Business problem**: The current file preview feature only provides syntax highlighting for Markdown files. Other code files (Python, Shell, Java, TypeScript, etc.) are displayed as plain text, resulting in a poor user experience and making it difficult to quickly understand code structure.
- **Target users**: Skill developers, reviewers, skill users
- **Value proposition**: Provide high-quality syntax highlighting consistent with Markdown code blocks, improving code readability and speeding up code review and comprehension.

### Feature Overview
- **Core features**:
  1. Syntax highlighting for common programming languages (Python, Shell, Java, JS/TS, Go, Rust, C/C++, Ruby, PHP)
  2. Syntax highlighting for configuration files (JSON, YAML, TOML, XML)
  3. Reuse the existing rehype-highlight (based on highlight.js) rendering engine
  4. Maintain visual style consistent with Markdown code blocks
  5. Support automatic dark/light theme switching

- **Feature scope**:
  - **Included**: Syntax highlighting for common programming languages and configuration files, error fallback handling, performance optimization
  - **Excluded**: Line number display, code folding, syntax error detection, custom theme configuration

- **User scenarios**:
  1. A skill reviewer views a submitted Python script and quickly identifies code logic
  2. A developer previews a configuration file (e.g. skill.yaml) in a skill package to verify parameter settings
  3. A user browses skill source code to understand implementation details

### Detailed Requirements
- **Input/Output**:
  - Input: File path, file content (InputStream), file extension
  - Output: HTML with syntax highlighting (rendered via highlight.js)

- **User interaction**:
  1. User clicks on a code file node in the file tree
  2. Frontend displays a loading state
  3. Backend returns file content and metadata (size, type)
  4. Frontend selects a rendering strategy based on file size and type:
     - ≤ 500KB: Syntax highlighted rendering
     - 500KB < size ≤ 1MB: Plain text rendering (no highlighting)
     - > 1MB: Show download button only

- **Data requirements**:
  - File size: Retrieved from the `SkillFile.fileSize` field
  - File type: Inferred from the file extension (`.py` → Python)
  - Language mapping: Uses the mapping table in `file-type-utils.ts`

- **Edge cases**:
  1. **Unrecognized language**: Display plain text (no highlighting); no error
  2. **Syntax highlighting failure**: Fall back to plain text; log the error
  3. **Insufficient memory**: Fall back to plain text; display a notice
  4. **Large file (> 500KB)**: Skip syntax highlighting; display plain text directly
  5. **Very large file (> 1MB)**: No preview; provide download only

## Design Decisions

### Technical Approach
- **Architecture choice**: Reuse the existing rehype-highlight (based on highlight.js)
  - **Rationale**:
    1. Zero additional dependencies; no increase in bundle size
    2. Styles are fully consistent with Markdown code blocks
    3. Existing language support (190+ languages)
    4. Low maintenance cost

- **Key components**:
  1. **CodeRenderer component** (new):
     - Location: `web/src/features/skill/code-renderer.tsx`
     - Responsibility: Accept a code string and language type, then call highlight.js to render
     - Dependencies: `highlight.js/lib/core` + language packages imported on demand

  2. **file-type-utils.ts** (extended):
     - Add `getLanguageForHighlight(extension: string): string | null` function
     - Map file extensions to highlight.js language identifiers

  3. **file-preview-dialog.tsx** (modified):
     - Select the renderer based on file size and type:
       - Markdown → `MarkdownRenderer`
       - Code file (≤ 500KB) → `CodeRenderer`
       - Code file (> 500KB) → Plain text `<pre><code>`
       - Other → Download prompt

- **Data storage**:
  - No new database fields required
  - File content is read from cloud storage (ObjectStorageService)
  - File size is already stored in the `SkillFile.fileSize` field

- **Interface design**:
  - Reuse existing API: `GET /api/v1/reviews/{id}/file?path={filePath}`
  - Response format: `InputStream` (unchanged)
  - Frontend determines file size from the `Content-Length` response header

### Constraints
- **Performance requirements**:
  - Syntax highlighting render time: < 500ms (for a 500KB file)
  - First load time: < 1s (including network request)
  - Memory usage: < 50MB per file render

- **Compatibility**:
  - Browsers: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
  - Mobile: Responsive layout supported; touch interaction not optimized

- **Security**:
  - When using `dangerouslySetInnerHTML`, ensure highlight.js output is escaped
  - Prevent XSS attacks: do not allow users to customize syntax highlighting rules
  - File path validation: reuse existing path traversal protection (disallow `..` and absolute paths)

- **Extensibility**:
  - Language support: Extend by importing language packages on demand without affecting initial bundle size
  - Theme support: Reserve a theme-switching interface; currently only system theme is supported

### Risk Assessment
- **Technical risk**:
  - **Risk**: Large file syntax highlighting causes browser lag
  - **Probability**: Medium
  - **Impact**: High
  - **Mitigations**:
    1. Set 500KB threshold; do not highlight files above this size
    2. Add loading state to notify the user
    3. Provide a "Cancel loading" button (future optimization)

- **Dependency risk**:
  - **Risk**: highlight.js cannot recognize certain languages
  - **Probability**: Low
  - **Impact**: Low
  - **Mitigation**: Fall back to plain text; does not affect core functionality

- **Schedule risk**:
  - **Risk**: Backend caching and rate limiting implementation is delayed
  - **Probability**: Medium
  - **Impact**: Medium
  - **Mitigations**:
    1. Frontend feature can be released independently
    2. Backend optimization is a separate task to be implemented in stages

## Acceptance Criteria

### Functional Acceptance
- [ ] Feature 1: Python files (.py) display syntax highlighting (keywords, strings, comments colored)
- [ ] Feature 2: Shell scripts (.sh, .bash) display syntax highlighting
- [ ] Feature 3: Configuration files (JSON, YAML, TOML, XML) display syntax highlighting
- [ ] Feature 4: Java/TypeScript/JavaScript files display syntax highlighting
- [ ] Feature 5: Unrecognized languages display plain text (no error)
- [ ] Feature 6: Large files (> 500KB) display plain text (no highlighting)
- [ ] Feature 7: Very large files (> 1MB) show download button only
- [ ] Feature 8: Syntax highlighting style is consistent with Markdown code blocks
- [ ] Feature 9: Automatic dark/light theme switching works
- [ ] Feature 10: Copy code button works correctly

### Quality Standards
- [ ] Code quality: Passes ESLint and TypeScript type checks
- [ ] Test coverage: Core logic (CodeRenderer, getLanguageForHighlight) unit test coverage > 80%
- [ ] Performance metrics:
  - 500KB file render time < 500ms (P95)
  - First load time < 1s (P95)
  - Lighthouse performance score does not decrease
- [ ] Security review: Code review confirms no XSS risk

### User Acceptance
- [ ] User experience: Reviewers report improved code readability
- [ ] Documentation: Update user documentation to describe supported file types
- [ ] Accessibility: Keyboard navigation works; screen reader accessible

## Execution Phases

### Phase 1: Preparation
**Goal**: Environment preparation and technical validation
- [ ] Task 1: Research highlight.js language package on-demand import approach
- [ ] Task 2: Verify CSS style reusability of rehype-highlight
- [ ] Task 3: Confirm that the file size field (`SkillFile.fileSize`) already exists
- [ ] Task 4: Design CodeRenderer component API
- **Deliverables**: Technical solution document, component API design
- **Time**: 0.5 days

### Phase 2: Core Development
**Goal**: Implement core syntax highlighting functionality
- [ ] Task 1: Create CodeRenderer component
  - Import highlight.js core library
  - Import common language packages on demand (Python, Shell, Java, JS/TS, Go, Rust, C/C++, Ruby, PHP)
  - Import configuration file language packages on demand (JSON, YAML, TOML, XML)
  - Implement `highlightCode(code: string, language: string)` function
  - Reuse Markdown code block CSS styles
- [ ] Task 2: Extend file-type-utils.ts
  - Add `getLanguageForHighlight(extension: string)` function
  - Map file extensions to highlight.js language identifiers
- [ ] Task 3: Modify file-preview-dialog.tsx
  - Select renderer based on file size and type
  - Implement 500KB and 1MB threshold logic
  - Integrate CodeRenderer component
- [ ] Task 4: Theme adaptation
  - Ensure syntax highlighting styles follow dark/light theme
  - Test visual consistency during theme switching
- **Deliverables**: Working syntax highlighting feature
- **Time**: 1.5 days

### Phase 3: Integration and Testing
**Goal**: Integration testing and quality assurance
- [ ] Task 1: Unit tests
  - CodeRenderer component tests (different languages, edge cases)
  - getLanguageForHighlight function tests
- [ ] Task 2: Integration tests
  - Skill detail page file preview tests
  - Review detail page file preview tests
- [ ] Task 3: Performance tests
  - Test 500KB file render time
  - Test memory usage
- [ ] Task 4: Browser compatibility tests
  - Chrome, Firefox, Safari, Edge
- [ ] Task 5: User acceptance testing
  - Invite reviewers to try it out and collect feedback
- **Deliverables**: Test report, performance benchmark data
- **Time**: 1 day

### Phase 4: Deployment and Monitoring
**Goal**: Production release and effect monitoring
- [ ] Task 1: Code review
  - Security review (XSS risk)
  - Performance review (bundle size, render performance)
- [ ] Task 2: Deploy to production
  - Frontend build and deploy
  - Verify production functionality
- [ ] Task 3: Monitoring metrics
  - File preview API response time
  - Frontend render performance (via RUM)
  - Error rate monitoring
- [ ] Task 4: Documentation updates
  - Update user documentation to describe supported file types
  - Update developer documentation on how to add new language support
- **Deliverables**: Production deployment, monitoring dashboard, user documentation
- **Time**: 0.5 days

---

**Document version**: 1.0
**Created**: 2026-03-22
**Clarification rounds**: 3
**Quality score**: 95/100

## Appendix: Backend Optimization Plan (Future Implementation)

The following optimization plans are documented but are not within the current implementation scope. They will be implemented as separate tasks in the future.

### 1. Backend Caching Strategy
- **Goal**: Reduce cloud storage read frequency and lower response time
- **Approach**:
  - Use Redis to cache file content
  - Cache key: `file:content:{storageKey}`
  - TTL: 1 hour
  - Cache policy: LRU (Least Recently Used)
- **Expected outcome**:
  - Cache hit rate > 60%
  - Response time reduced by 50%

### 2. Rate Limiting Strategy
- **Goal**: Prevent the file preview API from being abused and protect backend services
- **Approach**:
  - Use `@RateLimit` annotation
  - Configuration:
    ```java
    @RateLimit(
        category = "file-preview",
        authenticated = 60,    // Authenticated users: 60 requests/minute
        anonymous = 20,        // Anonymous users: 20 requests/minute
        windowSeconds = 60
    )
    ```
  - Rate limit granularity: by user ID (authenticated users) or IP (anonymous users)
  - Response when rate limit exceeded: return 429 + `{"code": 429, "message": "error.rateLimit.exceeded"}`
- **Expected outcome**:
  - Prevent excessive requests from a single user/IP
  - Protect cloud storage API quota

### 3. Monitoring Metrics
- **Goal**: Real-time monitoring of file preview feature health
- **Metrics**:
  - File preview API response time (P50, P95, P99)
  - File preview API error rate
  - Cache hit rate
  - Rate limit trigger count
  - Cloud storage API call count
- **Alert rules**:
  - P95 response time > 2s: Warning
  - Error rate > 5%: Critical
  - Cache hit rate < 40%: Warning

### 4. Implementation Priority
1. **P0 (current implementation)**: Frontend syntax highlighting feature
2. **P1 (next iteration)**: Backend caching strategy
3. **P2 (future optimization)**: Rate limiting strategy, monitoring metrics
