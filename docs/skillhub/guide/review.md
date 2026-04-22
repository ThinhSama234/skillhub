# Review and Governance

## Feature Description

SkillHub provides a complete review workflow to ensure that skill packages published to the registry comply with team standards.

The review mechanism has two levels:
- **Namespace review**: Team admins review skill packages within their namespace
- **Platform review**: Platform admins review skill packages promoted to the global level

![Concept diagram](/diagrams/review-concept.png)

**Review workflow**:

1. Developer publishes a skill package → enters "Pending Review" status
2. Admin receives a notification → views skill package details
3. Admin makes a decision → approve or reject
4. After approval → the skill package is officially published
5. After rejection → the developer receives feedback and can revise and resubmit

**Review statuses**:

| Status | Description |
|------|------|
| **PENDING** | Awaiting review |
| **APPROVED** | Approved |
| **REJECTED** | Rejected |
| **WITHDRAWN** | Withdrawn |

**Governance features**:

- **Review workflow**: Multi-level review, batch review
- **Report system**: Users can report inappropriate skill packages
- **Promotion management**: Promote namespace skill packages to the global level
- **Audit log**: Records all governance operations

## Use Cases

**Scenario 1: Namespace admin reviews submissions**

A team admin reviews skill packages submitted by members to ensure they meet team standards.

![Screenshot](/screenshots/review-list.png)

**Scenario 2: Platform admin reviews promotions**

A platform admin reviews skill packages being promoted from a namespace to the global level.

**Scenario 3: Handling reports**

A user reports an inappropriate skill package; an admin investigates and takes action.

**Scenario 4: Batch review**

An admin approves multiple compliant skill packages at once.

## Usage Steps

**Submit for review**:

1. When a skill package is published, the system automatically creates a review task
2. The developer can check the review status in "My Submissions"
3. Wait for the admin to complete the review

**Review a skill package**:

1. Go to `/dashboard/reviews`
2. View the pending review list
3. Click a skill package to view details:
   - View metadata (name, description, version)
   - Browse the file list
   - View file content online
   - Download the full package for local testing

![Flow diagram](/diagrams/review-flow.png)

4. Make a decision:
   - **Approve**: The skill package is officially published; the developer receives a notification
   - **Reject**: Provide a rejection reason; the developer can revise and resubmit

5. Add review comments (optional)

**Withdraw a review**:

If a developer discovers an issue, they can withdraw a submission before it is approved:

1. Go to "My Submissions"
2. Find the pending skill package
3. Click "Withdraw"
4. Confirm the withdrawal

**Handle reports**:

1. Go to `/dashboard/reports`
2. View the report list
3. Investigate the reported content
4. Take action (archive the skill package, warn the user, etc.)

## API Reference

**Submit for review**:
```bash
POST /api/v1/reviews
Content-Type: application/json

{
  "skillVersionId": "version-123"
}
```

**Approve a review**:
```bash
POST /api/v1/reviews/{id}/approve
Content-Type: application/json

{
  "comment": "Looks good! Approved."
}
```

**Reject a review**:
```bash
POST /api/v1/reviews/{id}/reject
Content-Type: application/json

{
  "comment": "Please fix the documentation and add more examples."
}
```

**Parameter description**:
| Parameter | Type | Description |
|------|------|------|
| id | string | Review task ID (path parameter) |
| comment | string | Review comment (optional, up to 1000 characters) |

**List pending review tasks**:
```bash
GET /api/v1/reviews/pending?namespaceId=ns-123&page=0&size=20
```

**List my submissions**:
```bash
GET /api/v1/reviews/my-submissions?page=0&size=20
```

**Get review detail**:
```bash
GET /api/v1/reviews/{id}
```

**Get skill detail under review**:
```bash
GET /api/v1/reviews/{id}/skill-detail
```

**Download review package**:
```bash
GET /api/v1/reviews/{id}/download
```

**Withdraw a review**:
```bash
POST /api/v1/reviews/{id}/withdraw
```

**Report a skill package**:
```bash
POST /api/v1/skills/{namespace}/{slug}/reports
Content-Type: application/json

{
  "reason": "INAPPROPRIATE_CONTENT",
  "details": "This skill contains malicious code"
}
```

## Notes

> **Review permissions**: Only Admins and Owners of a namespace can review skill packages within that namespace. Platform admins can review all skill packages.

- **Review timeliness**: Reviews should ideally be completed within 24 hours to avoid blocking developers
- **Review records**: All review operations are recorded in the audit log
- **Batch review**: Admins can approve multiple skill packages at once
- **Review comments**: Detailed improvement suggestions are recommended when rejecting
- **Withdrawal restriction**: Only skill packages in the pending review status can be withdrawn
