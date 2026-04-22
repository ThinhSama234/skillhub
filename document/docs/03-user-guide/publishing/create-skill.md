---
title: Create a Skill Package
sidebar_position: 1
description: Learn how to create a well-structured skill package
---

# Create a Skill Package

## Skill Package Structure

A standard SkillHub skill package has the following structure:

```
my-skill/
├── SKILL.md              # Main entry file (required)
├── references/           # Reference materials (optional)
├── scripts/              # Scripts (optional)
└── assets/               # Static assets (optional)
```

## SKILL.md Format

SKILL.md is the main entry file of the skill package, using YAML frontmatter + Markdown body format:

```markdown
---
name: my-skill
description: A one-line description of what this skill does
x-astron-category: code-review
---

# Skill Description

Detailed description of the skill goes here...
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier, kebab-case format |
| `description` | Yes | Short description of the skill |
| `x-astron-category` | No | Category tag |
| `x-astron-runtime` | No | Runtime requirements |
| `x-astron-min-version` | No | Minimum version requirement |

## File Limits

- Single file size: 1 MB maximum
- Total package size: 10 MB maximum
- Number of files: 100 maximum
- Allowed file types: `.md`, `.txt`, `.json`, `.yaml`, `.yml`, `.js`, `.ts`, `.py`, `.sh`, `.png`, `.jpg`, `.svg`

## Next Steps

- [Publishing Process](./publish) - Publish the skill package
