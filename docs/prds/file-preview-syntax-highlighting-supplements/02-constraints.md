---
name: File Preview Syntax Highlighting Constraints Specification
description: Defines feature boundaries, business rules, technical constraints, and dependency relationships
type: constraints
---

# Constraints Specification: File Preview Syntax Highlighting

## 1. Feature Boundaries

### Included in This Release
- Syntax highlighting for common programming languages (Python, Shell, Java, JS/TS, Go, Rust, C/C++, Ruby, PHP)
- Syntax highlighting for configuration files (JSON, YAML, TOML, XML)
- File size threshold control (500KB syntax highlighting threshold, 1MB preview limit)
- Error fallback handling (display plain text when language is unrecognized or rendering fails)
- Automatic theme switching (follows system dark/light mode)
- Copy code button (reuse existing implementation)

### Explicitly Excluded
- ❌ Line number display
- ❌ Code folding/unfolding
- ❌ Syntax error detection and hints
- ❌ Code search and navigation
- ❌ Custom syntax highlighting themes
- ❌ Code editing
- ❌ Code formatting
- ❌ Virtual scrolling (paginated loading for large files)

### Future Possibilities (Not in This Release)
- Line number display (consider after user feedback)
- Code folding (for long file scenarios)
- Custom theme configuration (user preference settings)
- More language support (added on demand)
- Code snippet sharing (generate link)

## 2. Business Rules

| Rule ID | Description | Trigger Condition | Expected Behavior | Priority |
|---------|------|---------|---------|--------|
| BR-001 | File size threshold control | File size > 500KB | Display plain text (no syntax highlighting) | Must |
| BR-002 | File preview limit | File size > 1MB | Show download button only, no preview | Must |
| BR-003 | Language recognition failure fallback | File language cannot be identified | Display plain text, no error | Must |
| BR-004 | Rendering failure fallback | Syntax highlighting rendering fails | Fall back to plain text display | Must |
| BR-005 | Insufficient memory fallback | Browser runs out of memory | Fall back to plain text display, show notice | Should |
| BR-006 | Theme follows system | User switches system theme | Syntax highlighting theme switches automatically | Must |
| BR-007 | Style consistency | All code rendering | Consistent with Markdown code block styles | Must |
| BR-008 | Copy function retained | User clicks copy button | Copy complete file content to clipboard | Must |

## 3. Technical Constraints

### Performance Constraints
- **Render time**: Syntax highlighting render time for a 500KB file < 500ms (P95)
- **First load**: File preview first load time < 1s (P95, including network request)
- **Memory usage**: Single file render memory usage < 50MB
- **Bundle size**: New code bundle size increase < 100KB (gzipped)

### Compatibility Constraints
- **Browser support**:
  - Chrome 90+
  - Firefox 88+
  - Safari 14+
  - Edge 90+
- **Mobile**: Responsive layout supported; touch interaction not optimized
- **Screen readers**: Basic accessibility support (code content is readable)

### Security Constraints
- **XSS protection**: When using `dangerouslySetInnerHTML`, ensure highlight.js output is escaped
- **Path traversal protection**: Reuse existing path validation (disallow `..` and absolute paths)
- **Content security policy**: Do not allow users to customize syntax highlighting rules
- **Sensitive information**: Do not cache file content on the frontend

### Extensibility Constraints
- **Language extension**: Extend by importing language packages on demand; does not affect initial bundle size
- **Theme extension**: Reserve a theme-switching interface; currently only system theme is supported
- **Renderer extension**: CodeRenderer component is designed to be replaceable (can switch to another engine in the future)

## 4. Dependency Relationships

### Upstream Dependencies
| Dependency | Version | Purpose | Risk |
|--------|------|------|------|
| highlight.js | ^11.x | Syntax highlighting engine | Low (mature and stable) |
| rehype-highlight | ^7.0.2 | Markdown code block highlighting (already in use) | Low (already in use) |
| react-markdown | ^10.1.0 | Markdown rendering (already in use) | Low (already in use) |

### Downstream Impact
| Impacted Module | Impact Type | Impact Description | Mitigation |
|---------|---------|---------|---------|
| File preview dialog | Feature enhancement | New syntax highlighting render logic | Backward compatible, does not affect existing functionality |
| File type utilities | Feature extension | New language mapping function | Pure addition, does not modify existing functions |
| Style system | Style reuse | Reuses Markdown code block styles | No impact; only reads existing styles |

### External Dependencies
- **Cloud storage service**: File content reading depends on ObjectStorageService
- **Backend API**: `GET /api/v1/reviews/{id}/file?path={filePath}`
- **Redis**: For caching in a future optimization phase (not implemented in this release)

## 5. Non-Functional Requirements

### Usability
- **Error messages**: Display friendly error messages when rendering fails
- **Loading state**: Show loading state to prevent user anxiety during waits
- **Fallback experience**: Falling back to plain text does not affect core reading functionality

### Maintainability
- **Code organization**: CodeRenderer component is independent, easy to test and replace
- **Language configuration**: Language mapping table is centrally managed and easy to extend
- **Style management**: Reuse existing styles to reduce maintenance cost

### Testability
- **Unit tests**: CodeRenderer component and language mapping function can be tested independently
- **Integration tests**: File preview flow can be tested end-to-end
- **Performance tests**: Render time and memory usage can be quantifiably tested

### Observability
- **Error logs**: Record error information for syntax highlighting failures
- **Performance metrics**: Record render time (via RUM)
- **User behavior**: Record file preview usage (basis for future optimizations)

---

## Changelog
| Date | Section | Change | Reason | Author |
|------|------|------|------|--------|
| 2026-03-22 | Initial version | Created constraints specification document | Requirements clarification complete | requirements-clarity |
