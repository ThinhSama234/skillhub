---
name: File Preview Syntax Highlighting Acceptance Cases
description: Detailed test scenarios including positive path, error path, boundary conditions, and security tests
type: acceptance-cases
---

# Acceptance Test Cases: File Preview Syntax Highlighting

## Naming Conventions
- **AC-P**: Positive Path
- **AC-E**: Error Path
- **AC-B**: Boundary
- **AC-S**: Security

---

## Positive Path Tests

### AC-P-001: Python File Syntax Highlighting
- **Precondition**: User is logged in; skill contains a Python file (< 500KB)
- **Steps**:
  1. Open the skill detail page
  2. Click the `main.py` file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Python code is displayed with syntax highlighting
  - Keywords (`def`, `class`, `import`) are shown in specific colors
  - Strings are shown in specific colors
  - Comments are shown in specific colors
  - Style is consistent with Markdown code blocks
- **Related Constraints**: BR-001, BR-007

### AC-P-002: Shell Script Syntax Highlighting
- **Precondition**: User is logged in; skill contains a Shell script (< 500KB)
- **Steps**:
  1. Open the review detail page
  2. Click the `install.sh` file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Shell code is displayed with syntax highlighting
  - Commands (`echo`, `cd`, `mkdir`) are shown in specific colors
  - Variables (`$VAR`) are shown in specific colors
  - Comments (`#`) are shown in specific colors
- **Related Constraints**: BR-001, BR-007

### AC-P-003: JSON Configuration File Syntax Highlighting
- **Precondition**: User is logged in; skill contains a JSON file (< 500KB)
- **Steps**:
  1. Open the skill detail page
  2. Click the `config.json` file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - JSON code is displayed with syntax highlighting
  - Key names are shown in specific colors
  - String values are shown in specific colors
  - Numeric values are shown in specific colors
  - Boolean values are shown in specific colors
- **Related Constraints**: BR-001, BR-007

### AC-P-004: YAML Configuration File Syntax Highlighting
- **Precondition**: User is logged in; skill contains a YAML file (< 500KB)
- **Steps**:
  1. Open the skill detail page
  2. Click the `skill.yaml` file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - YAML code is displayed with syntax highlighting
  - Key names are shown in specific colors
  - String values are shown in specific colors
  - Indentation structure is clearly visible
- **Related Constraints**: BR-001, BR-007

### AC-P-005: Mixed Language Test
- **Precondition**: User is logged in; skill contains files of multiple languages
- **Steps**:
  1. Open the skill detail page
  2. Click `main.py`, `install.sh`, `config.json`, `README.md` in sequence
  3. Observe the rendering effect of each file
- **Expected Results**:
  - Each file type is correctly rendered
  - Python displays syntax highlighting
  - Shell displays syntax highlighting
  - JSON displays syntax highlighting
  - Markdown displays rich text rendering (existing feature)
- **Related Constraints**: BR-001, BR-007

### AC-P-006: Automatic Language Detection
- **Precondition**: User is logged in; skill contains code files
- **Steps**:
  1. Open the skill detail page
  2. Click the `script.py` file in the file tree
  3. Observe the syntax highlighting effect
- **Expected Results**:
  - Automatically identified as Python based on the `.py` extension
  - Python syntax highlighting rules are applied
  - No manual language selection required from the user
- **Related Constraints**: BR-001

### AC-P-007: Automatic Theme Switching (Light → Dark)
- **Precondition**: User is logged in; system theme is Light mode
- **Steps**:
  1. Open the skill detail page and preview a Python file
  2. Switch the system theme to Dark mode
  3. Observe the syntax highlighting color change
- **Expected Results**:
  - Syntax highlighting theme automatically switches to Dark mode
  - Color contrast is appropriate for a dark background
  - No page refresh required
- **Related Constraints**: BR-006

### AC-P-008: Automatic Theme Switching (Dark → Light)
- **Precondition**: User is logged in; system theme is Dark mode
- **Steps**:
  1. Open the skill detail page and preview a Python file
  2. Switch the system theme to Light mode
  3. Observe the syntax highlighting color change
- **Expected Results**:
  - Syntax highlighting theme automatically switches to Light mode
  - Color contrast is appropriate for a light background
  - No page refresh required
- **Related Constraints**: BR-006

### AC-P-009: Copy Code Feature
- **Precondition**: User is logged in and is previewing a Python file
- **Steps**:
  1. Open the file preview dialog
  2. Click the "Copy" button
  3. Paste into a text editor
- **Expected Results**:
  - Complete file content is copied to clipboard
  - Copied content is plain text (no HTML tags)
  - "Copied to clipboard" notice is displayed
  - Copy button shows animation effect (spinning → ✅)
- **Related Constraints**: BR-008

### AC-P-010: Download Code Feature
- **Precondition**: User is logged in and is previewing a Python file
- **Steps**:
  1. Open the file preview dialog
  2. Click the "Download" button
- **Expected Results**:
  - File is downloaded to local storage
  - File name is the original file name (e.g. `main.py`)
  - File content is complete
- **Related Constraints**: BR-008

---

## Error Path Tests

### AC-E-001: Unrecognized Language (Custom Extension)
- **Precondition**: User is logged in; skill contains a file with a custom extension (e.g. `.custom`)
- **Steps**:
  1. Open the skill detail page
  2. Click the `script.custom` file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Plain text is displayed (no syntax highlighting)
  - No error message is shown
  - Copy and download functions work normally
- **Related Constraints**: BR-003

### AC-E-002: Syntax Highlighting Rendering Failure
- **Precondition**: Simulate a highlight.js rendering exception
- **Steps**:
  1. Open the skill detail page
  2. Click a Python file in the file tree
  3. Trigger a rendering exception (via test mock)
- **Expected Results**:
  - Falls back to plain text display
  - Friendly error message is shown: "Syntax highlighting failed to load, switched to plain text mode"
  - Copy and download functions work normally
  - Error is logged to the console
- **Related Constraints**: BR-004

### AC-E-003: Memory Insufficient Causes Rendering Failure
- **Precondition**: Simulate browser running out of memory
- **Steps**:
  1. Open the skill detail page
  2. Click a large file in the file tree (close to 500KB)
  3. Trigger an out-of-memory exception (via test mock)
- **Expected Results**:
  - Falls back to plain text display
  - Notice is shown: "File is large, switched to plain text mode to save memory"
  - Copy and download functions work normally
- **Related Constraints**: BR-005

### AC-E-004: Network Request Failure
- **Precondition**: Simulate a network request failure
- **Steps**:
  1. Open the skill detail page
  2. Click a Python file in the file tree
  3. Trigger a network request failure (via test mock)
- **Expected Results**:
  - Error message is shown: "File failed to load, please try again"
  - A "Retry" button is provided
  - File content is not displayed
- **Related Constraints**: None (existing error handling)

### AC-E-005: File Content Is Empty
- **Precondition**: User is logged in; skill contains an empty file
- **Steps**:
  1. Open the skill detail page
  2. Click an empty file (0 bytes) in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - An empty content area is displayed
  - No error message is shown
  - Copy button is disabled or shows "File is empty"
- **Related Constraints**: None

---

## Boundary Condition Tests

### AC-B-001: File Size Exactly 500KB
- **Precondition**: User is logged in; skill contains a 500KB Python file
- **Steps**:
  1. Open the skill detail page
  2. Click the 500KB Python file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Syntax highlighting is displayed (500KB is within the threshold)
  - Render time < 500ms
  - No performance issues
- **Related Constraints**: BR-001

### AC-B-002: File Size 501KB (Exceeds Syntax Highlighting Threshold)
- **Precondition**: User is logged in; skill contains a 501KB Python file
- **Steps**:
  1. Open the skill detail page
  2. Click the 501KB Python file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Plain text is displayed (no syntax highlighting)
  - Notice is shown: "File is large (501KB), switched to plain text mode"
  - Copy and download functions work normally
- **Related Constraints**: BR-001

### AC-B-003: File Size Exactly 1MB
- **Precondition**: User is logged in; skill contains a 1MB Python file
- **Steps**:
  1. Open the skill detail page
  2. Click the 1MB Python file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Plain text is displayed (no syntax highlighting)
  - Notice is shown: "File is large (1MB), switched to plain text mode"
  - Copy and download functions work normally
- **Related Constraints**: BR-001, BR-002

### AC-B-004: File Size 1.1MB (Exceeds Preview Limit)
- **Precondition**: User is logged in; skill contains a 1.1MB Python file
- **Steps**:
  1. Open the skill detail page
  2. Click the 1.1MB Python file in the file tree
  3. Observe the file preview dialog
- **Expected Results**:
  - File content is not displayed
  - Only a download button is shown
  - Notice is shown: "File too large (1.1MB), please download to view"
- **Related Constraints**: BR-002

### AC-B-005: File Name Contains Special Characters
- **Precondition**: User is logged in; skill contains a file with a special character name (e.g. `my-script (1).py`)
- **Steps**:
  1. Open the skill detail page
  2. Click the special character file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Syntax highlighting is displayed normally
  - File name is displayed correctly (including special characters)
  - File name is preserved as-is when downloading
- **Related Constraints**: None

### AC-B-006: File Content Contains Unicode Characters
- **Precondition**: User is logged in; skill contains a Python file with Unicode characters (e.g. Chinese comments)
- **Steps**:
  1. Open the skill detail page
  2. Click the Python file in the file tree
  3. Wait for the file preview dialog to load
- **Expected Results**:
  - Syntax highlighting is displayed normally
  - Unicode characters (Chinese comments) are displayed correctly
  - Unicode characters are preserved when copying
- **Related Constraints**: None

### AC-B-007: Very Long Single Line of Code (> 1000 Characters)
- **Precondition**: User is logged in; skill contains a file with an extremely long single line of code
- **Steps**:
  1. Open the skill detail page
  2. Click the file in the file tree
  3. Observe the rendering effect
- **Expected Results**:
  - Syntax highlighting is displayed normally
  - A horizontal scrollbar appears
  - Page layout is not affected
- **Related Constraints**: None

---

## Security Tests

### AC-S-001: XSS Protection (Malicious HTML Tags)
- **Precondition**: User is logged in; skill contains a code file with HTML tags
- **Steps**:
  1. Upload a Python file containing `<script>alert('XSS')</script>`
  2. Open the skill detail page
  3. Click the file in the file tree
  4. Observe whether the script is executed
- **Expected Results**:
  - HTML tags are escaped and displayed as plain text
  - No scripts are executed
  - Syntax highlighting works normally
- **Related Constraints**: Security constraints

### AC-S-002: XSS Protection (Malicious Event Handlers)
- **Precondition**: User is logged in; skill contains a code file with event handlers
- **Steps**:
  1. Upload a file containing `<img src=x onerror=alert('XSS')>`
  2. Open the skill detail page
  3. Click the file in the file tree
  4. Observe whether the script is executed
- **Expected Results**:
  - Event handlers are escaped and displayed as plain text
  - No scripts are executed
  - No external resources are loaded
- **Related Constraints**: Security constraints

### AC-S-003: Path Traversal Protection
- **Precondition**: User is logged in
- **Steps**:
  1. Attempt to access `/api/v1/reviews/1/file?path=../../../etc/passwd`
  2. Observe the response
- **Expected Results**:
  - Returns 400 Bad Request
  - No file content is returned
  - Security log is recorded
- **Related Constraints**: Security constraints (existing protection)

---

## Coverage Matrix

| Type | Count | Covered Constraints |
|------|------|-----------|
| Positive Path (AC-P) | 10 | BR-001, BR-006, BR-007, BR-008 |
| Error Path (AC-E) | 5 | BR-003, BR-004, BR-005 |
| Boundary Conditions (AC-B) | 7 | BR-001, BR-002 |
| Security Tests (AC-S) | 3 | Security constraints |
| **Total** | **25** | **All constraints** |

---

## Changelog
| Date | Section | Change | Reason | Author |
|------|------|------|------|--------|
| 2026-03-22 | Initial version | Created acceptance cases document | Requirements clarification complete | requirements-clarity |
