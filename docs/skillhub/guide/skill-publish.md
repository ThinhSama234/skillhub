# Skill Publishing and Version Management

## Feature Description

Skill publishing is the core feature of SkillHub. Developers can upload locally developed agent skill packages to the registry with a single command, and the system automatically handles versioning, metadata extraction, file indexing, and more.

![Concept diagram](/diagrams/skill-publish-concept.png)

**Problems this solves**:

Traditionally, team members distribute skill packages via Git repositories or file sharing. This approach has several pain points:

- **Version chaos**: Different versions are scattered in various places and are difficult to track
- **Loss of access control**: No fine-grained control over who can access which skill packages
- **Difficulty in discovery**: New members don't know what skill packages are already available in the team

SkillHub provides an npm-like publishing experience, enhanced with enterprise-grade access control and review mechanisms.

**Core features**:

- **Semantic versioning**: Supports `major.minor.patch` version numbering
- **Tag system**: Custom tags like `latest`, `beta`, `stable`, etc.
- **Multi-version coexistence**: A skill package can retain multiple historical versions
- **Version resolution**: Intelligent resolution of version selectors (e.g. `^1.2.0`, `~2.0.0`)
- **File browser**: Browse the file structure inside a skill package online
- **Download distribution**: Supports downloading by version or by tag

## Use Cases

**Scenario 1: Developer publishes a new skill**

You just completed a Claude Code skill package and want other team members to be able to use it.

![Screenshot](/screenshots/homepage.png)

**Scenario 2: Version iteration**

A skill package needs bug fixes or new features; publish a new version while maintaining backward compatibility.

**Scenario 3: Beta testing**

A new feature is not yet stable; publish it with the `beta` tag for a small group of testers, then promote it to `latest` once stable.

**Scenario 4: Version rollback**

A new version has a critical issue; the `latest` tag needs to point back to the previous stable version.

## Usage Steps

1. **Prepare the skill package**

   Ensure the skill package meets SkillHub standards:
   - Contains `skill.md` (skill description)
   - Contains `package.json` or `SKILL.md` (metadata)
   - Clear file structure with no sensitive information

2. **Publish via CLI (recommended)**

```bash
# Configure the registry
export CLAWHUB_REGISTRY=http://localhost:8080

# Publish to the default namespace
npx clawhub publish ./my-skill

# Publish to a specific namespace
npx clawhub publish ./my-skill --namespace my-team
```

3. **Publish via Web UI**

   Go to `http://localhost:3000/dashboard/publish`, select a namespace, upload a zip file, choose a visibility level, and click "Publish".

4. **Publish via REST API**

```bash
POST /api/v1/skills/{namespace}/publish
Content-Type: multipart/form-data

file: skill-package.zip
visibility: PUBLIC
```

![Flow diagram](/diagrams/skill-publish-flow.png)

5. **Security scan**

   After publishing, [Skill Scanner](/guide/scanner) automatically scans the skill package to detect potential security risks. Scan results are displayed on the skill package detail page.

6. **Wait for review** (if the namespace has review enabled)

   Team admins will receive a review notification. The skill package is officially published once approved.

7. **Publication successful**

   The skill package is discoverable via search, and others can download and use it via the CLI or Web UI.

## API Reference

**Publish a skill package**:
```bash
POST /api/v1/skills/{namespace}/publish
Content-Type: multipart/form-data

# Parameters
file: MultipartFile (required)
visibility: PUBLIC | PRIVATE | INTERNAL (optional, defaults to PUBLIC)
```

**Parameter description**:
| Parameter | Type | Description |
|------|------|------|
| namespace | string | Namespace slug (path parameter) |
| file | MultipartFile | Skill package zip file |
| visibility | enum | Visibility level: PUBLIC, PRIVATE, INTERNAL |

**Get skill detail**:
```bash
GET /api/v1/skills/{namespace}/{slug}
```

**List versions**:
```bash
GET /api/v1/skills/{namespace}/{slug}/versions?page=0&size=20
```

**Get version detail**:
```bash
GET /api/v1/skills/{namespace}/{slug}/versions/{version}
```

**Download a specific version**:
```bash
GET /api/v1/skills/{namespace}/{slug}/versions/{version}/download
```

**Download by tag**:
```bash
GET /api/v1/skills/{namespace}/{slug}/tags/{tagName}/download
```

**Version resolution**:
```bash
GET /api/v1/skills/{namespace}/{slug}/resolve?version=^1.2.0
```

## Notes

> **Version numbering**: SkillHub uses Semantic Versioning. The version format is `major.minor.patch`, e.g. `1.2.3`.

- **First publish**: It is recommended to start version numbering at `0.1.0` or `1.0.0`
- **Tag management**: The `latest` tag automatically points to the most recent stable version
- **Review process**: If the namespace has review enabled, new versions must wait for admin approval
- **File size limit**: A single skill package must not exceed 100MB (configurable)
- **Naming convention**: Skill slugs support lowercase letters, digits, hyphens, and Unicode characters
- **Versions are immutable**: Published versions cannot be modified; only new versions can be published
