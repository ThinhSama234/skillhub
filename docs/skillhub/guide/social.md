# User Interaction and Social Features

## Feature Description

SkillHub provides rich social features that allow team members to interact, share, and recommend skill packages.

![Concept diagram](/diagrams/social-concept.png)

**Core features**:

- **Stars**: Bookmark favorite skill packages for easy reference later
- **Ratings**: Rate skill packages (1–5 stars) to help others gauge quality
- **Download statistics**: Track download counts to highlight popular skill packages
- **Notification system**: Receive timely notifications for review results, comments, and more

**Social metrics**:

| Metric | Description |
|------|------|
| **Star count** | How many people have bookmarked this skill package |
| **Average rating** | The average of all user ratings |
| **Download count** | Cumulative number of downloads |
| **Activity** | Time of last update, publish frequency |

## Use Cases

**Scenario 1: Bookmark a useful skill package**

A developer discovers a useful skill package and clicks the star button to bookmark it.

![Screenshot](/screenshots/skill-detail-star.png)

**Scenario 2: Rate and recommend**

After using a skill package, leave a rating to help other team members.

**Scenario 3: View notifications**

Receive a notification that a review was approved, or that someone commented on your skill package.

![Screenshot](/screenshots/notifications.png)

**Scenario 4: Browse popular packages**

View the skill packages with the most stars and highest ratings to learn best practices.

## Usage Steps

**Star a skill package**:

1. Go to the skill package detail page
2. Click the "Star" button
3. The skill package will appear in your "My Stars" list
4. Click again to remove the star

**Rate a skill package**:

1. Go to the skill package detail page
2. Click the star icons to select a rating (1–5 stars)
3. The rating takes effect immediately and influences the skill package's average rating
4. You can change your rating at any time

**View notifications**:

1. Click the notification icon in the top navigation bar
2. View the list of unread notifications
3. Click a notification to navigate to the related page
4. Mark individual notifications as read or mark all as read

**View my stars**:

1. Go to `/dashboard/stars`
2. View all starred skill packages
3. Sort by star date or update time
4. Quickly access frequently used skill packages

## API Reference

**Star a skill package**:
```bash
PUT /api/v1/skills/{skillId}/star
```

**Remove a star**:
```bash
DELETE /api/v1/skills/{skillId}/star
```

**Check star status**:
```bash
GET /api/v1/skills/{skillId}/star
```

**Response example**:
```json
{
  "starred": true,
  "starredAt": "2026-03-15T10:30:00Z"
}
```

**Rate a skill package**:
```bash
PUT /api/v1/skills/{skillId}/rating
Content-Type: application/json

{
  "score": 5
}
```

**Parameter description**:
| Parameter | Type | Description |
|------|------|------|
| skillId | string | Skill package ID (path parameter) |
| score | number | Rating (1–5, required) |

**Get my stars**:
```bash
GET /api/v1/me/stars?page=0&size=20
```

**Get my rating**:
```bash
GET /api/v1/skills/{skillId}/rating
```

**Response example**:
```json
{
  "score": 5,
  "ratedAt": "2026-03-15T10:30:00Z"
}
```

## Notes

> **Rating rules**: Each user can rate each skill package only once. Ratings can be changed but not deleted.

- **Star count**: The star count for a skill package is shown in search results and on the detail page
- **Average rating**: A skill package's average rating influences search ranking
- **Notification settings**: Users can disable certain types of notifications in settings
- **Download statistics**: Each download increments the download counter, which is used for popularity ranking
