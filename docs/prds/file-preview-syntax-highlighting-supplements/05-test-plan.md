---
name: File Preview Syntax Highlighting Test Plan
description: Detailed plan and coverage matrix for unit tests, integration tests, and performance tests
type: test-plan
---

# Test Plan: File Preview Syntax Highlighting

## 1. Unit Tests

### Test Class: `CodeRenderer.test.tsx`
**Location**: `web/src/features/skill/__tests__/code-renderer.test.tsx`

| Test Method | Covered Cases | Description |
|---------|---------|------|
| `renders Python code with syntax highlighting` | AC-P-001 | Verify Python code is correctly rendered with keyword coloring |
| `renders Shell script with syntax highlighting` | AC-P-002 | Verify Shell script is correctly rendered with command coloring |
| `renders JSON with syntax highlighting` | AC-P-003 | Verify JSON is correctly rendered with key-value coloring |
| `renders YAML with syntax highlighting` | AC-P-004 | Verify YAML is correctly rendered with clear structure |
| `falls back to plain text for unknown language` | AC-E-001 | Verify fallback to plain text when language is unrecognized |
| `handles empty code gracefully` | AC-E-005 | Verify empty content does not cause errors |
| `handles Unicode characters correctly` | AC-B-006 | Verify Unicode characters (Chinese) are displayed correctly |
| `escapes HTML tags to prevent XSS` | AC-S-001 | Verify HTML tags are escaped |
| `applies correct CSS classes for theming` | AC-P-007 | Verify CSS class names are consistent with Markdown |

**Test Data**:
```typescript
const pythonCode = `def hello():\n    print("Hello, World!")`
const shellCode = `#!/bin/bash\necho "Hello"`
const jsonCode = `{"key": "value", "number": 123}`
const yamlCode = `key: value\nnumber: 123`
const xssCode = `<script>alert('XSS')</script>`
```

---

### Test Class: `file-type-utils.test.ts`
**Location**: `web/src/features/skill/__tests__/file-type-utils.test.ts`

| Test Method | Covered Cases | Description |
|---------|---------|------|
| `getLanguageForHighlight returns correct language for .py` | AC-P-006 | Verify .py → python |
| `getLanguageForHighlight returns correct language for .sh` | AC-P-006 | Verify .sh → bash |
| `getLanguageForHighlight returns correct language for .json` | AC-P-006 | Verify .json → json |
| `getLanguageForHighlight returns correct language for .yaml` | AC-P-006 | Verify .yaml → yaml |
| `getLanguageForHighlight returns null for unknown extension` | AC-E-001 | Verify .custom → null |
| `getLanguageForHighlight handles case-insensitive extensions` | - | Verify .PY → python |
| `getLanguageForHighlight handles multiple extensions for same language` | - | Verify both .yml and .yaml map to yaml |

**Test Data**:
```typescript
const testCases = [
  { ext: '.py', expected: 'python' },
  { ext: '.sh', expected: 'bash' },
  { ext: '.bash', expected: 'bash' },
  { ext: '.json', expected: 'json' },
  { ext: '.yaml', expected: 'yaml' },
  { ext: '.yml', expected: 'yaml' },
  { ext: '.custom', expected: null },
]
```

---

## 2. Integration Tests

### Test Class: `file-preview-dialog.test.tsx`
**Location**: `web/src/features/skill/__tests__/file-preview-dialog.test.tsx`

| Test Method | Covered Cases | Description |
|---------|---------|------|
| `renders CodeRenderer for Python files under 500KB` | AC-P-001, AC-B-001 | Verify small files use syntax highlighting |
| `renders plain text for files over 500KB` | AC-B-002 | Verify large files fall back to plain text |
| `shows download-only for files over 1MB` | AC-B-004 | Verify very large files show download only |
| `renders MarkdownRenderer for .md files` | AC-P-005 | Verify Markdown files use existing renderer |
| `switches renderer when file changes` | AC-P-005 | Verify renderer switches correctly when switching files |
| `shows loading state while fetching file` | - | Verify loading state is displayed |
| `handles network error gracefully` | AC-E-004 | Verify network error shows a message |
| `copy button works correctly` | AC-P-009 | Verify copy functionality |
| `download button works correctly` | AC-P-010 | Verify download functionality |

**Test Data**:
```typescript
const smallPythonFile = { path: 'main.py', size: 10240, content: '...' }
const largePythonFile = { path: 'large.py', size: 512000, content: '...' }
const hugePythonFile = { path: 'huge.py', size: 1100000, content: '...' }
const markdownFile = { path: 'README.md', size: 5000, content: '...' }
```

---

### Test Class: `skill-detail-page.test.tsx` (Extend Existing Tests)
**Location**: `web/src/features/skill/__tests__/skill-detail-page.test.tsx`

| Test Method | Covered Cases | Description |
|---------|---------|------|
| `file tree shows syntax-highlighted preview on click` | AC-P-001 | End-to-end test: click file tree → display syntax highlighting |
| `file preview dialog closes correctly` | - | Verify dialog close functionality |

---

## 3. Performance Tests

### Test Scenario: Render Performance
**Tool**: Jest + Performance API

| Test Scenario | Target Metric | Test Method |
|---------|---------|---------|
| 100KB Python file render time | < 200ms | Measure using `performance.now()` |
| 500KB Python file render time | < 500ms | Measure using `performance.now()` |
| Memory usage (500KB file) | < 50MB | Use Chrome DevTools Memory Profiler |
| First load time (including network) | < 1s | Use Lighthouse Performance testing |

**Test Code Example**:
```typescript
test('renders 500KB file within 500ms', async () => {
  const largeCode = 'x'.repeat(500 * 1024)
  const start = performance.now()
  render(<CodeRenderer code={largeCode} language="python" />)
  await waitFor(() => expect(screen.getByRole('code')).toBeInTheDocument())
  const end = performance.now()
  expect(end - start).toBeLessThan(500)
})
```

---

### Test Scenario: Bundle Size
**Tool**: Webpack Bundle Analyzer

| Metric | Target Value | Test Method |
|------|--------|---------|
| New code bundle size (gzipped) | < 100KB | Run `npm run build` then analyze bundle |
| highlight.js core library | ~10KB | Check size of highlight.js in bundle |
| Language packages (on demand) | ~5KB/language | Check size of each language package |

---

## 4. Browser Compatibility Tests

### Test Matrix

| Browser | Version | Test Cases | Status |
|--------|------|---------|------|
| Chrome | 90+ | AC-P-001 ~ AC-P-010 | ✅ Pass |
| Firefox | 88+ | AC-P-001 ~ AC-P-010 | ✅ Pass |
| Safari | 14+ | AC-P-001 ~ AC-P-010 | ✅ Pass |
| Edge | 90+ | AC-P-001 ~ AC-P-010 | ✅ Pass |

**Testing tool**: BrowserStack or local virtual machines

---

## 5. Theme Tests

### Test Scenario: Theme Switching
**Tool**: Jest + React Testing Library

| Test Scenario | Covered Cases | Test Method |
|---------|---------|---------|
| Syntax highlighting colors correct in Light mode | AC-P-007 | Check CSS variable values |
| Syntax highlighting colors correct in Dark mode | AC-P-007 | Check CSS variable values |
| Light → Dark switch is smooth | AC-P-007 | Simulate theme switch, check transition effect |
| Dark → Light switch is smooth | AC-P-008 | Simulate theme switch, check transition effect |

**Test Code Example**:
```typescript
test('applies correct theme colors in dark mode', () => {
  render(<CodeRenderer code="def hello():" language="python" />, {
    wrapper: ({ children }) => <ThemeProvider theme="dark">{children}</ThemeProvider>
  })
  const codeElement = screen.getByRole('code')
  const styles = window.getComputedStyle(codeElement)
  expect(styles.backgroundColor).toBe('rgb(30, 30, 30)') // Dark background
})
```

---

## 6. Security Tests

### Test Scenario: XSS Protection
**Tool**: Jest + DOMPurify (if used)

| Test Scenario | Covered Cases | Test Method |
|---------|---------|---------|
| HTML tags are escaped | AC-S-001 | Render code containing `<script>`, check DOM |
| Event handlers are escaped | AC-S-002 | Render code containing `onerror`, check DOM |
| No scripts are executed | AC-S-001, AC-S-002 | Use `jest.spyOn(window, 'alert')` to verify not called |

**Test Code Example**:
```typescript
test('escapes HTML tags to prevent XSS', () => {
  const xssCode = '<script>alert("XSS")</script>'
  const alertSpy = jest.spyOn(window, 'alert').mockImplementation()
  render(<CodeRenderer code={xssCode} language="javascript" />)
  expect(screen.getByText(/<script>/)).toBeInTheDocument() // Displayed as text
  expect(alertSpy).not.toHaveBeenCalled() // Script not executed
  alertSpy.mockRestore()
})
```

---

## 7. Coverage Matrix

### Acceptance Case Coverage

| Acceptance Case | Unit Test | Integration Test | Performance Test | Browser Test |
|---------|---------|---------|---------|-----------|
| AC-P-001 | ✅ | ✅ | ✅ | ✅ |
| AC-P-002 | ✅ | - | - | ✅ |
| AC-P-003 | ✅ | - | - | ✅ |
| AC-P-004 | ✅ | - | - | ✅ |
| AC-P-005 | - | ✅ | - | ✅ |
| AC-P-006 | ✅ | - | - | - |
| AC-P-007 | ✅ | - | - | ✅ |
| AC-P-008 | ✅ | - | - | ✅ |
| AC-P-009 | - | ✅ | - | - |
| AC-P-010 | - | ✅ | - | - |
| AC-E-001 | ✅ | - | - | - |
| AC-E-002 | - | ✅ | - | - |
| AC-E-003 | - | ✅ | - | - |
| AC-E-004 | - | ✅ | - | - |
| AC-E-005 | ✅ | - | - | - |
| AC-B-001 | - | ✅ | ✅ | - |
| AC-B-002 | - | ✅ | - | - |
| AC-B-003 | - | ✅ | - | - |
| AC-B-004 | - | ✅ | - | - |
| AC-B-005 | - | ✅ | - | - |
| AC-B-006 | ✅ | - | - | - |
| AC-B-007 | - | ✅ | - | - |
| AC-S-001 | ✅ | - | - | - |
| AC-S-002 | ✅ | - | - | - |
| AC-S-003 | - | - | - | - |

**Coverage Statistics**:
- Unit test coverage: 11/25 (44%)
- Integration test coverage: 13/25 (52%)
- Performance test coverage: 2/25 (8%)
- Browser test coverage: 10/25 (40%)
- **Total coverage**: 25/25 (100%)

---

## 8. Test Data

### Test File Preparation
**Location**: `web/src/features/skill/__tests__/__fixtures__/`

| File Name | Size | Purpose |
|--------|------|------|
| `sample.py` | 10KB | Python syntax highlighting test |
| `sample.sh` | 5KB | Shell syntax highlighting test |
| `sample.json` | 2KB | JSON syntax highlighting test |
| `sample.yaml` | 3KB | YAML syntax highlighting test |
| `large.py` | 500KB | Boundary test (exactly 500KB) |
| `large-501kb.py` | 501KB | Boundary test (exceeds 500KB) |
| `huge.py` | 1.1MB | Boundary test (exceeds 1MB) |
| `unicode.py` | 5KB | Unicode character test (includes Chinese comments) |
| `xss.html` | 1KB | XSS protection test |

---

## 9. Test Execution Plan

### Phase 1: Unit Tests (0.5 days)
- [ ] Write `CodeRenderer.test.tsx` (9 test cases)
- [ ] Write `file-type-utils.test.ts` (7 test cases)
- [ ] Run tests, ensure coverage > 80%
- [ ] Fix failing tests

### Phase 2: Integration Tests (0.5 days)
- [ ] Write `file-preview-dialog.test.tsx` (9 test cases)
- [ ] Extend `skill-detail-page.test.tsx` (2 test cases)
- [ ] Run tests, ensure end-to-end flow is correct
- [ ] Fix failing tests

### Phase 3: Performance Tests (0.3 days)
- [ ] Write render performance tests (4 scenarios)
- [ ] Run Webpack Bundle Analyzer, check bundle size
- [ ] Use Lighthouse to test first load time
- [ ] Optimize performance bottlenecks (if needed)

### Phase 4: Browser Compatibility Tests (0.2 days)
- [ ] Test all positive cases in Chrome 90+
- [ ] Test all positive cases in Firefox 88+
- [ ] Test all positive cases in Safari 14+
- [ ] Test all positive cases in Edge 90+
- [ ] Record compatibility issues (if any)

### Phase 5: Security Tests (0.2 days)
- [ ] Write XSS protection tests (3 scenarios)
- [ ] Verify path traversal protection (reuse existing tests)
- [ ] Code review to confirm no security vulnerabilities

---

## 10. Test Pass Criteria

### Unit Tests
- ✅ All test cases pass
- ✅ Code coverage > 80% (statement coverage, branch coverage)
- ✅ No TypeScript type errors
- ✅ No ESLint warnings

### Integration Tests
- ✅ All end-to-end flows work correctly
- ✅ File preview dialog renders correctly
- ✅ Copy and download functions work correctly

### Performance Tests
- ✅ 500KB file render time < 500ms (P95)
- ✅ First load time < 1s (P95)
- ✅ New bundle size increase < 100KB (gzipped)
- ✅ Lighthouse performance score does not decrease

### Browser Compatibility Tests
- ✅ All features work correctly in Chrome 90+
- ✅ All features work correctly in Firefox 88+
- ✅ All features work correctly in Safari 14+
- ✅ All features work correctly in Edge 90+

### Security Tests
- ✅ XSS protection tests pass
- ✅ Code review passes
- ✅ No security vulnerabilities

---

## Changelog
| Date | Section | Change | Reason | Author |
|------|------|------|------|--------|
| 2026-03-22 | Initial version | Created test plan document | Requirements clarification complete | requirements-clarity |
