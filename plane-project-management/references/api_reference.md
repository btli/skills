# Plane API Reference

Full API documentation: https://planesoftwareinc.mintlify.app/api-reference/introduction

## Base URL

Self-hosted: Use `$PLANE_API_URL` from `~/.claude/.env`
Cloud: `https://api.plane.so/api/`

## Authentication

### Method 1: API Key (Public API)

All public API requests require the `X-API-Key` header with a valid API token.

Generate tokens at: Profile Settings > API Tokens

**Public API uses `/api/v1/` prefix.**

### Method 2: Session-Based (Self-Hosted)

For self-hosted instances, authenticate via CSRF token + credentials:

```bash
# 1. Get CSRF token
curl -c cookies.txt "$PLANE_API_URL/auth/get-csrf-token/" -H "Accept: application/json"

# 2. Extract token
CSRF_TOKEN=$(grep csrftoken cookies.txt | awk '{print $7}')

# 3. Sign in
curl -b cookies.txt -c cookies.txt -X POST "$PLANE_API_URL/api/v1/sign-in/" \
  -H "Content-Type: application/json" -H "X-CSRFToken: $CSRF_TOKEN" \
  -d '{"email": "user@example.com", "password": "password"}'

# 4. Use session cookie (no /v1 prefix)
curl -b cookies.txt "$PLANE_API_URL/api/workspaces/{workspace}/projects/"
```

**Session-based uses `/api/` prefix (no v1).**

## Endpoint Patterns

All workspace-scoped endpoints follow:
```
/api/workspaces/{workspace_slug}/...
```

---

## Projects
- `GET /projects/` - List all projects
- `POST /projects/` - Create project
- `GET /projects/{id}/` - Get project
- `PATCH /projects/{id}/` - Update project
- `DELETE /projects/{id}/` - Delete project

## Issues (Work Items)
- `GET /projects/{project_id}/issues/` - List issues
- `POST /projects/{project_id}/issues/` - Create issue
- `GET /projects/{project_id}/issues/{id}/` - Get issue
- `PATCH /projects/{project_id}/issues/{id}/` - Update issue
- `DELETE /projects/{project_id}/issues/{id}/` - Delete issue

## States
- `GET /projects/{project_id}/states/` - List states
- `POST /projects/{project_id}/states/` - Create state
- `PATCH /projects/{project_id}/states/{id}/` - Update state
- `DELETE /projects/{project_id}/states/{id}/` - Delete state

## Labels
- `GET /projects/{project_id}/labels/` - List labels
- `POST /projects/{project_id}/labels/` - Create label
- `PATCH /projects/{project_id}/labels/{id}/` - Update label
- `DELETE /projects/{project_id}/labels/{id}/` - Delete label

## Cycles (Sprints)
- `GET /projects/{project_id}/cycles/` - List cycles
- `POST /projects/{project_id}/cycles/` - Create cycle
- `GET /projects/{project_id}/cycles/{id}/` - Get cycle
- `PATCH /projects/{project_id}/cycles/{id}/` - Update cycle
- `DELETE /projects/{project_id}/cycles/{id}/` - Delete cycle
- `GET /projects/{project_id}/cycles/archived/` - List archived cycles
- `POST /projects/{project_id}/cycles/{id}/archive/` - Archive cycle
- `DELETE /projects/{project_id}/cycles/{id}/archive/` - Restore cycle
- `POST /projects/{project_id}/cycles/{id}/work-items/` - Add work items
- `GET /projects/{project_id}/cycles/{id}/work-items/` - List cycle work items
- `DELETE /projects/{project_id}/cycles/{id}/work-items/{work_item_id}/` - Remove work item
- `POST /projects/{project_id}/cycles/{id}/transfer-work-items/` - Transfer work items

## Modules
- `GET /projects/{project_id}/modules/` - List modules
- `POST /projects/{project_id}/modules/` - Create module
- `GET /projects/{project_id}/modules/{id}/` - Get module
- `PATCH /projects/{project_id}/modules/{id}/` - Update module
- `DELETE /projects/{project_id}/modules/{id}/` - Delete module
- `GET /projects/{project_id}/modules/archived/` - List archived modules
- `POST /projects/{project_id}/modules/{id}/archive/` - Archive module
- `DELETE /projects/{project_id}/modules/{id}/unarchive/` - Restore module
- `POST /projects/{project_id}/modules/{id}/work-items/` - Add work items
- `GET /projects/{project_id}/modules/{id}/work-items/` - List module work items
- `DELETE /projects/{project_id}/modules/{id}/work-items/{work_item_id}/` - Remove work item

## Initiatives (Workspace Level)
- `GET /initiatives/` - List initiatives
- `POST /initiatives/` - Create initiative
- `GET /initiatives/{id}/` - Get initiative
- `PATCH /initiatives/{id}/` - Update initiative
- `DELETE /initiatives/{id}/` - Delete initiative

## Pages (Documentation)

### Workspace Pages (Wiki)
- `POST /pages/` - Create wiki page
- `GET /pages/{id}/` - Get wiki page

### Project Pages
- `POST /projects/{project_id}/pages/` - Create project page
- `GET /projects/{project_id}/pages/{id}/` - Get project page

## Time Tracking (Worklogs)
- `POST /projects/{project_id}/work-items/{work_item_id}/worklogs/` - Create worklog
- `GET /projects/{project_id}/work-items/{work_item_id}/worklogs/` - List worklogs
- `GET /projects/{project_id}/work-items/{work_item_id}/worklogs/total-time/` - Get total time
- `PATCH /projects/{project_id}/work-items/{work_item_id}/worklogs/{id}/` - Update worklog
- `DELETE /projects/{project_id}/work-items/{work_item_id}/worklogs/{id}/` - Delete worklog

## Intake (Incoming Requests)
- `GET /projects/{project_id}/intake-issues/` - List intake issues
- `POST /projects/{project_id}/intake-issues/` - Create intake issue
- `GET /projects/{project_id}/intake-issues/{id}/` - Get intake issue
- `PATCH /projects/{project_id}/intake-issues/{id}/` - Update intake issue
- `DELETE /projects/{project_id}/intake-issues/{id}/` - Delete intake issue

## Comments
- `GET /projects/{project_id}/work-items/{work_item_id}/comments/` - List comments
- `POST /projects/{project_id}/work-items/{work_item_id}/comments/` - Create comment
- `GET /projects/{project_id}/work-items/{work_item_id}/comments/{id}/` - Get comment
- `PATCH /projects/{project_id}/work-items/{work_item_id}/comments/{id}/` - Update comment
- `DELETE /projects/{project_id}/work-items/{work_item_id}/comments/{id}/` - Delete comment

## Links
- `GET /projects/{project_id}/work-items/{work_item_id}/links/` - List links
- `POST /projects/{project_id}/work-items/{work_item_id}/links/` - Create link
- `GET /projects/{project_id}/work-items/{work_item_id}/links/{id}/` - Get link
- `PATCH /projects/{project_id}/work-items/{work_item_id}/links/{id}/` - Update link
- `DELETE /projects/{project_id}/work-items/{work_item_id}/links/{id}/` - Delete link

## Activity
- `GET /projects/{project_id}/work-items/{work_item_id}/activities/` - List activities
- `GET /projects/{project_id}/work-items/{work_item_id}/activities/{id}/` - Get activity

---

## Response Format

All list endpoints return paginated responses:

```json
{
  "grouped_by": null,
  "sub_grouped_by": null,
  "total_count": 100,
  "next_cursor": "1000:1:20",
  "prev_cursor": "1000:-1:1",
  "next_page_results": true,
  "prev_page_results": false,
  "count": 20,
  "total_pages": 5,
  "total_results": 100,
  "results": [...]
}
```

## Query Parameters

- `cursor` - Pagination cursor
- `fields` - Comma-separated fields to include
- `expand` - Include related resources

## Rate Limiting

- 60 requests per minute
- Check `X-RateLimit-Remaining` header
- 429 status when exceeded

---

## Field Values Reference

### State Groups
- `backlog` - Items not yet planned
- `unstarted` - Planned but not started
- `started` - Work in progress
- `completed` - Done
- `cancelled` - Won't do

### Priority Values
- `urgent` - Critical, immediate attention
- `high` - Important
- `medium` - Normal priority
- `low` - Can wait
- `none` - No priority set

### Module Status Values
- `backlog`
- `planned`
- `in-progress`
- `paused`
- `completed`
- `cancelled`

### Initiative State Values
- `DRAFT`
- `PLANNED`
- `ACTIVE`
- `COMPLETED`
- `CLOSED`

### Date Formats
All dates use ISO 8601 format: `YYYY-MM-DD`

### Time Duration
Worklogs use seconds (3600 = 1 hour)

---

## Common Errors

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid data) |
| 401 | Invalid or missing API key |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 429 | Rate limit exceeded |
| 500 | Server error |
