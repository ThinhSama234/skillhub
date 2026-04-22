---
title: Installation & Usage
sidebar_position: 2
description: Install and use skills
---

# Installation & Usage

## Install via CLI

### Install the Latest Version

```bash
clawhub install @team/my-skill
```

### Install a Specific Version

```bash
clawhub install @team/my-skill@1.2.0
```

### Install by Tag

```bash
clawhub install @team/my-skill@beta
```

### Install Using the ClawHub CLI

```bash
clawhub install my-skill
clawhub install team-name--my-skill
```

## Installation Directory

Skills are installed according to the following priority order:

| Priority | Path | Description |
|----------|------|-------------|
| 1 | `./.agent/skills/` | Project-level, universal mode |
| 2 | `~/.agent/skills/` | Global-level, universal mode |
| 3 | `./.claude/skills/` | Project-level, Claude default |
| 4 | `~/.claude/skills/` | Global-level, Claude default |

## Using in Claude Code

Once installed, skills are automatically discovered and loaded by Claude Code.

## Next Steps

- [Ratings & Stars](./ratings) - Give feedback and star skills
