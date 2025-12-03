# Plane API Reference

Full API documentation: https://planesoftwareinc.mintlify.app/api-reference/introduction

## Base URL

Self-hosted: Use `$PLANE_API_URL` from `~/.claude/.env`
Cloud: `https://api.plane.so/api/v1/`

## Authentication

All requests require the `X-API-Key` header with a valid API token.

Generate tokens at: Profile Settings > API Tokens

## Endpoint Patterns

All workspace-scoped endpoints follow:
```
/api/v1/workspaces/{workspace_slug}/...
```

### Projects
- `GET /projects/` - List all projects
- `POST /projects/` - Create project
- `GET /projects/{id}/` - Get project
- `PATCH /projects/{id}/` - Update project
- `DELETE /projects/{id}/` - Delete project

### Issues (Work Items)
- `GET /projects/{project_id}/issues/` - List issues
- `POST /projects/{project_id}/issues/` - Create issue
- `GET /projects/{project_id}/issues/{id}/` - Get issue
- `PATCH /projects/{project_id}/issues/{id}/` - Update issue
- `DELETE /projects/{project_id}/issues/{id}/` - Delete issue

### States
- `GET /projects/{project_id}/states/` - List states
- `POST /projects/{project_id}/states/` - Create state
- `PATCH /projects/{project_id}/states/{id}/` - Update state
- `DELETE /projects/{project_id}/states/{id}/` - Delete state

### Labels
- `GET /projects/{project_id}/labels/` - List labels
- `POST /projects/{project_id}/labels/` - Create label
- `PATCH /projects/{project_id}/labels/{id}/` - Update label
- `DELETE /projects/{project_id}/labels/{id}/` - Delete label

### Cycles (Sprints)
- `GET /projects/{project_id}/cycles/` - List cycles
- `POST /projects/{project_id}/cycles/` - Create cycle
- `GET /projects/{project_id}/cycles/{id}/` - Get cycle
- `PATCH /projects/{project_id}/cycles/{id}/` - Update cycle
- `DELETE /projects/{project_id}/cycles/{id}/` - Delete cycle
- `POST /projects/{project_id}/cycles/{id}/cycle-issues/` - Add issues to cycle

### Modules
- `GET /projects/{project_id}/modules/` - List modules
- `POST /projects/{project_id}/modules/` - Create module
- `GET /projects/{project_id}/modules/{id}/` - Get module
- `PATCH /projects/{project_id}/modules/{id}/` - Update module
- `DELETE /projects/{project_id}/modules/{id}/` - Delete module
- `POST /projects/{project_id}/modules/{id}/module-issues/` - Add issues to module

### Links
- `GET /projects/{project_id}/issues/{issue_id}/links/` - List links
- `POST /projects/{project_id}/issues/{issue_id}/links/` - Create link
- `DELETE /projects/{project_id}/issues/{issue_id}/links/{id}/` - Delete link

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

## State Groups

Default state groups (cannot be changed):
- `backlog` - Items not yet planned
- `unstarted` - Planned but not started
- `started` - Work in progress
- `completed` - Done
- `cancelled` - Won't do

## Priority Values

- `urgent` - Critical, immediate attention
- `high` - Important
- `medium` - Normal priority
- `low` - Can wait
- `none` - No priority set

## Date Formats

All dates use ISO 8601 format: `YYYY-MM-DD`

## Common Errors

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid data) |
| 401 | Invalid or missing API key |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 429 | Rate limit exceeded |
| 500 | Server error |
