---
title: Skill Protocol
sidebar_position: 1
description: SKILL.md specification and skill package protocol
---

# Skill Protocol

## SKILL.md Specification

### Basic Format

```markdown
---
name: my-skill
description: When to use this skill
---

# Markdown Body

Skill instruction content...
```

### Required Fields

| Field | Description |
|-------|-------------|
| `name` | Skill identifier, kebab-case |
| `description` | Short description of the skill |

### Extended Fields

| Field | Description |
|-------|-------------|
| `x-astron-category` | Category tag |
| `x-astron-runtime` | Runtime requirements |
| `x-astron-min-version` | Minimum version requirement |

## Skill Package Structure

```
my-skill/
├── SKILL.md              # Main entry file (required)
├── references/           # Reference materials (optional)
├── scripts/              # Scripts (optional)
└── assets/               # Static assets (optional)
```

## File Validation

- The root directory must contain `SKILL.md`
- File type allowlist
- Single file size limit: 1MB
- Total package size limit: 10MB
- File count limit: 100 files

## Client Installation Directory

Installed in the following priority order:

1. `./.agent/skills/`
2. `~/.agent/skills/`
3. `./.claude/skills/`
4. `~/.claude/skills/`

## Next Steps

- [Storage SPI](./storage-spi) - Extend the storage backend
