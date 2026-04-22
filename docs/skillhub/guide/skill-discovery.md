# Skill Search and Discovery

## Feature Description

SkillHub provides powerful full-text search capabilities that allow users to quickly find the skill packages they need.

Search supports not only keyword matching, but also multi-dimensional filtering and sorting by namespace, tag, download count, rating, and more.

![Concept diagram](/diagrams/skill-discovery-concept.png)

**Core features**:

- **Full-text search**: Search skill package names, descriptions, tags, and authors
- **Smart filtering**: Filter by namespace, tags, and visibility
- **Multiple sort orders**: Sort by relevance, download count, rating, or update time
- **Permission-aware**: Only shows skill packages the user has access to
- **Real-time updates**: Newly published skill packages appear in search results immediately

**Search algorithm**:

SkillHub uses PostgreSQL full-text search, supporting:
- Chinese and English word segmentation
- Fuzzy matching
- Weighted ranking (title weight > description weight > tag weight)

## Use Cases

**Scenario 1: New member exploration**

A developer who just joined a team wants to see what skill packages the team already has available.

![Screenshot](/screenshots/skill-discovery-search.png)

**Scenario 2: Search on demand**

A developer needs a skill package for handling PDFs, and searches for the keyword "pdf".

**Scenario 3: Browse popular packages**

View the skill packages with the highest download count and best ratings within the team to learn best practices.

**Scenario 4: Filter by tag**

View only skill packages with the `data-processing` tag.

## Usage Steps

### Search and Install via CLI (Recommended)

```bash
# Configure the registry
export CLAWHUB_REGISTRY=http://localhost:8080

# Search for skill packages
npx clawhub search pdf

# Install a skill package
npx clawhub install pdf-parser

# Install a skill package from a specific namespace
npx clawhub install my-team--pdf-parser
```

### Search via Web UI

1. **Access the search page**

   Go to `http://localhost:3000/search` or use the search box on the home page.

2. **Enter keywords**

   Type keywords in the search box, e.g. "pdf parser".

3. **Apply filters**

   - Select a namespace (e.g. show only the `iflytek` namespace)
   - Select tags (e.g. `data-processing`)
   - Select a sort order (e.g. sort by download count descending)

![Flow diagram](/diagrams/skill-discovery-flow.png)

4. **View results**

   Search results update in real time, showing the list of matching skill packages.

5. **View details**

   Click a skill package card to view detailed information, version history, and file list.

6. **Install and use**

   Once you find a suitable skill package, install it using the CLI command or click the "Download" button.

## API Reference

**Search skill packages**:
```bash
GET /api/web/skills?q=pdf&namespace=iflytek&label=data-processing&sort=downloads&page=0&size=20
```

**Parameter description**:
| Parameter | Type | Description |
|------|------|------|
| q | string | Search keyword (optional) |
| namespace | string | Namespace filter (optional) |
| label | string[] | Tag filter (optional, multiple values allowed) |
| sort | enum | Sort order: relevance, downloads, rating, updated |
| page | number | Page number (starting from 0) |
| size | number | Items per page (default 20, max 100) |

**Response example**:
```json
{
  "content": [
    {
      "id": "skill-123",
      "namespace": "iflytek",
      "slug": "pdf-parser",
      "name": "PDF Parser",
      "description": "Extract text and metadata from PDF files",
      "downloads": 1234,
      "rating": 4.5,
      "starCount": 56,
      "latestVersion": "1.2.3",
      "updatedAt": "2026-03-15T10:30:00Z",
      "labels": ["data-processing", "pdf"]
    }
  ],
  "totalElements": 42,
  "totalPages": 3,
  "number": 0,
  "size": 20
}
```

## Notes

> **Access control**: Search results are automatically filtered based on user permissions. PRIVATE skill packages are only visible to namespace members; INTERNAL skill packages are only visible to logged-in users.

- **Search performance**: SkillHub uses PostgreSQL full-text search with Chinese and English word segmentation
- **Real-time updates**: Newly published skill packages appear in search results immediately
- **Tag standards**: It is recommended to use consistent tag naming conventions to facilitate filtering
- **Search suggestions**: Supports search suggestions and auto-completion (implemented on the frontend)
