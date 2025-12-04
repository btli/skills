# Plane API Reference (Self-Hosted)

## Overview

This reference documents the Plane API endpoints for self-hosted instances. The API has two authentication methods with different endpoint patterns.

## Authentication

### API Key (Public API v1)
- Header: `X-API-Key: {api_key}`
- Base path: `/api/v1/workspaces/{workspace_slug}/...`
- Used for: Projects, Issues, States, Labels, Modules

### Session-Based (Internal API)
- Cookie: Session cookie from login
- Base path: `/api/workspaces/{workspace_slug}/...` (no `/v1`)
- Used for: Pages, Members, Cycles (with full data)

## Key Differences

| Feature | API Key (v1) | Session |
|---------|--------------|---------|
| Issues field for state | `state` (UUID) | `state_id` + `state__group` |
| Cycles | Basic data | Full data with `status` field |
| Pages | Not available | Full CRUD |
| Members | Not available | Full access |

---

## Endpoints

### Projects
```
GET    /projects/                    List projects
POST   /projects/                    Create project
GET    /projects/{id}/               Get project
PATCH  /projects/{id}/               Update project
DELETE /projects/{id}/               Delete project
```

### Issues
```
GET    /projects/{project_id}/issues/            List issues
POST   /projects/{project_id}/issues/            Create issue
GET    /projects/{project_id}/issues/{id}/       Get issue
PATCH  /projects/{project_id}/issues/{id}/       Update issue
DELETE /projects/{project_id}/issues/{id}/       Delete issue
```

**Important:** When updating issue state via API v1, use `"state": "{uuid}"` not `"state_id"`.

### States
```
GET    /projects/{project_id}/states/            List states
POST   /projects/{project_id}/states/            Create state
PATCH  /projects/{project_id}/states/{id}/       Update state
DELETE /projects/{project_id}/states/{id}/       Delete state
```

### Labels
```
GET    /projects/{project_id}/labels/            List labels
POST   /projects/{project_id}/labels/            Create label
PATCH  /projects/{project_id}/labels/{id}/       Update label
DELETE /projects/{project_id}/labels/{id}/       Delete label
```

### Cycles (Session Auth Recommended)
```
GET    /projects/{project_id}/cycles/                        List cycles
POST   /projects/{project_id}/cycles/                        Create cycle
GET    /projects/{project_id}/cycles/{id}/                   Get cycle
PATCH  /projects/{project_id}/cycles/{id}/                   Update cycle
DELETE /projects/{project_id}/cycles/{id}/                   Delete cycle
POST   /projects/{project_id}/cycles/{id}/cycle-issues/      Add issues
GET    /projects/{project_id}/cycles/{id}/cycle-issues/      List cycle issues
DELETE /projects/{project_id}/cycles/{id}/cycle-issues/{work_item_id}/  Remove issue
```

### Modules
```
GET    /projects/{project_id}/modules/                       List modules
POST   /projects/{project_id}/modules/                       Create module
GET    /projects/{project_id}/modules/{id}/                  Get module
PATCH  /projects/{project_id}/modules/{id}/                  Update module
DELETE /projects/{project_id}/modules/{id}/                  Delete module
POST   /projects/{project_id}/modules/{id}/module-issues/    Add issues
GET    /projects/{project_id}/modules/{id}/module-issues/    List module issues
```

### Pages (Session Auth Required)
```
GET    /projects/{project_id}/pages/             List pages
POST   /projects/{project_id}/pages/             Create page
GET    /projects/{project_id}/pages/{id}/        Get page
PATCH  /projects/{project_id}/pages/{id}/        Update page
DELETE /projects/{project_id}/pages/{id}/        Delete page
GET    /projects/{project_id}/pages/{id}/description/  Get page content
```

### Workspace Members (Session Auth Required)
```
GET    /members/                     List workspace members
```

---

## Request/Response Examples

### Create Issue
```bash
curl -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" \
  -d '{
    "name": "Issue title",
    "description_html": "<p>Description</p>",
    "priority": "high",
    "state": "{state_uuid}",
    "assignees": ["{user_uuid}"],
    "labels": ["{label_uuid}"]
  }'
```

### Update Issue State
```bash
curl -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/" \
  -d '{"state": "{state_uuid}"}'
```

### Create Cycle
```bash
curl -X POST -b /tmp/plane_cookies.txt -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/" \
  -d '{
    "name": "Sprint 1",
    "start_date": "2025-01-01T00:00:01Z",
    "end_date": "2025-01-14T23:59:00Z",
    "description": "First sprint"
  }'
```

### Create Page
```bash
curl -X POST -b /tmp/plane_cookies.txt -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/" \
  -d '{
    "name": "Documentation",
    "description_html": "<h1>Title</h1><p>Content</p>",
    "access": 0
  }'
```

---

## Field Values

### Priority
- `urgent`, `high`, `medium`, `low`, `none`

### State Groups
- `backlog` - Not yet planned
- `unstarted` - Planned (Todo)
- `started` - In progress
- `completed` - Done
- `cancelled` - Won't do

### Cycle Status (from session API)
- `UPCOMING`, `CURRENT`, `COMPLETED`, `DRAFT`

### Module Status
- `backlog`, `planned`, `in-progress`, `paused`, `completed`, `cancelled`

### Page Access
- `0` - Private
- `1` - Public

---

## Pagination

List responses include pagination info:
```json
{
  "total_count": 50,
  "next_cursor": "1000:1:20",
  "prev_cursor": "1000:-1:1",
  "next_page_results": true,
  "prev_page_results": false,
  "count": 20,
  "total_pages": 3,
  "total_results": 50,
  "results": [...]
}
```

Use `?cursor={next_cursor}` for next page.

---

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid data) |
| 401 | Invalid or missing authentication |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 429 | Rate limit exceeded (60 req/min) |
| 500 | Server error |
