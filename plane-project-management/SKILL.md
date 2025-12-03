---
name: plane-project-management
description: |
  Interact with Plane project management via REST API for issue tracking, project planning, and sprint management. This skill should be used when: (1) working in a project directory that needs task tracking, (2) creating implementation plans with trackable issues, (3) managing sprints/cycles and modules, (4) updating issue status as work progresses, (5) querying project status and metrics. Credentials are stored in ~/.claude/.env.
---

# Plane Project Management Skill

Manage projects, issues, cycles, and modules in Plane via the REST API.

## Configuration

Load credentials from `~/.claude/.env`:

```bash
source ~/.claude/.env
```

Required environment variables:
- `PLANE_API_URL` - Base URL (e.g., `https://plane.joyful.house`)
- `PLANE_API_KEY` - API key for authentication
- `PLANE_WORKSPACE` - Default workspace slug (e.g., `kaelyn-ai`)

## Authentication

Include the API key in the `X-API-Key` header for all requests:

```bash
curl -H "X-API-Key: $PLANE_API_KEY" "$PLANE_API_URL/api/v1/..."
```

## API Base Pattern

All endpoints follow: `$PLANE_API_URL/api/v1/workspaces/{workspace_slug}/...`

## Core Operations

### List Projects

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/" | jq '.results[]'
```

### Get Project Details

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/"
```

### Create Project

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/" \
  -d '{
    "name": "Project Name",
    "identifier": "PROJ",
    "description": "Project description"
  }'
```

### List Issues

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" | jq '.results[]'
```

### Create Issue

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" \
  -d '{
    "name": "Issue title",
    "description_html": "<p>Issue description with HTML formatting</p>",
    "priority": "high",
    "state": "{state_id}",
    "assignees": ["{user_id}"],
    "labels": ["{label_id}"],
    "start_date": "2025-01-01",
    "target_date": "2025-01-15"
  }'
```

**Issue Fields:**
- `name` (required): Issue title
- `description_html`: HTML-formatted description
- `priority`: `urgent`, `high`, `medium`, `low`, `none`
- `state`: State UUID (get from states endpoint)
- `assignees`: Array of user UUIDs
- `labels`: Array of label UUIDs
- `parent`: Parent issue UUID (for sub-issues)
- `start_date`: YYYY-MM-DD format
- `target_date`: YYYY-MM-DD format
- `point`: Story points (integer)

### Update Issue

```bash
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/" \
  -d '{"state": "{new_state_id}", "priority": "medium"}'
```

### Delete Issue

```bash
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/"
```

### List States (Workflow)

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/" | jq '.results[]'
```

Default state groups: `backlog`, `unstarted`, `started`, `completed`, `cancelled`

### List Labels

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/labels/"
```

### Create Label

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/labels/" \
  -d '{"name": "bug", "color": "#FF0000"}'
```

### List Cycles (Sprints)

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/"
```

### Create Cycle

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/" \
  -d '{
    "name": "Sprint 1",
    "start_date": "2025-01-01",
    "end_date": "2025-01-14"
  }'
```

### Add Issues to Cycle

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/cycle-issues/" \
  -d '{"issues": ["{issue_id_1}", "{issue_id_2}"]}'
```

### List Modules

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/"
```

### Create Module

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/" \
  -d '{
    "name": "Authentication Module",
    "description": "User auth features",
    "start_date": "2025-01-01",
    "target_date": "2025-02-01"
  }'
```

### Add Issues to Module

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/module-issues/" \
  -d '{"issues": ["{issue_id_1}", "{issue_id_2}"]}'
```

## Response Pagination

API responses use cursor-based pagination:

```json
{
  "total_count": 50,
  "next_cursor": "1000:1:20",
  "prev_cursor": "1000:-1:1",
  "next_page_results": true,
  "results": [...]
}
```

To paginate, add `?cursor={next_cursor}` to the request.

## Project Planning Workflow

When starting work in a new project directory:

1. **Check for existing Plane project** matching the directory/repo name
2. **Create project if needed** with appropriate identifier (3-5 uppercase letters)
3. **Analyze codebase** to identify components, features, and technical debt
4. **Create implementation plan** as hierarchical issues:
   - Epic-level issues for major features/components
   - Task issues as children of epics
   - Bug issues for identified problems
5. **Create labels** for categorization: `feature`, `bug`, `tech-debt`, `documentation`, `testing`
6. **Set up modules** for major feature areas
7. **Create initial cycle/sprint** if using time-boxed iterations

## Issue Tracking During Development

When working on tasks:

1. **Before starting work**: Move issue to "In Progress" state
2. **Reference issues in commits**: Include `[PROJ-{sequence_id}]` in commit messages
3. **After completing work**: Move issue to "Done" state
4. **For blockers**: Add comments or create linked blocking issues

## Helper: Get State ID by Name

```bash
# Get the "In Progress" state ID
STATE_ID=$(curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/" \
  | jq -r '.results[] | select(.name=="In Progress") | .id')
```

## Helper: Create Issue and Get ID

```bash
ISSUE_ID=$(curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" \
  -d '{"name": "Issue title"}' | jq -r '.id')
```

## Rate Limiting

API is rate-limited to 60 requests per minute. Check `X-RateLimit-Remaining` header.

## Error Handling

Common error responses:
- `401`: Invalid API key
- `403`: Insufficient permissions
- `404`: Resource not found
- `429`: Rate limit exceeded

Always check response status and handle errors appropriately.
