---
name: plane-project-management
description: |
  Interact with Plane project management via REST API for issue tracking, project planning, sprint management, time tracking, initiatives, and documentation. This skill should be used when: (1) working in a project directory that needs task tracking, (2) creating implementation plans with trackable issues, (3) managing sprints/cycles and modules, (4) updating issue status as work progresses, (5) logging time spent on tasks, (6) managing cross-project initiatives, (7) creating project documentation pages. Credentials are stored in ~/.claude/.env.
---

# Plane Project Management Skill

Manage projects, issues, cycles, modules, pages, initiatives, and time tracking in Plane via the REST API.

## Configuration

Load credentials from `~/.claude/.env`:

```bash
source ~/.claude/.env
```

Required environment variables:
- `PLANE_API_URL` - Base URL (e.g., `https://plane.joyful.house`)
- `PLANE_API_KEY` - API key for authentication
- `PLANE_WORKSPACE` - Default workspace slug (e.g., `kaelyn-ai`)

Optional (for session-based auth on self-hosted):
- `PLANE_USERNAME` - Login email
- `PLANE_PASSWORD` - Login password

## Authentication

### Method 1: API Key (Recommended for Public API)

Include the API key in the `X-API-Key` header:

```bash
curl -H "X-API-Key: $PLANE_API_KEY" "$PLANE_API_URL/api/v1/workspaces/..."
```

**Note:** The public API uses `/api/v1/` prefix.

### Method 2: Session-Based (Self-Hosted Only)

For self-hosted Plane instances, you can authenticate via username/password using CSRF tokens and form-encoded data:

```bash
# Step 1: Get CSRF token (sets csrftoken cookie and returns token in JSON)
curl -c cookies.txt "$PLANE_API_URL/auth/get-csrf-token/" \
  -H "Accept: application/json"

# Step 2: Extract CSRF token from cookie file
CSRF_TOKEN=$(grep csrftoken cookies.txt | awk '{print $7}')

# Step 3: Sign in with form-urlencoded data (NOT JSON!)
# Note: The sign-in endpoint expects application/x-www-form-urlencoded
curl -b cookies.txt -c cookies.txt -X POST "$PLANE_API_URL/auth/sign-in/" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Origin: $PLANE_API_URL" \
  -H "Referer: $PLANE_API_URL/" \
  -d "csrfmiddlewaretoken=$CSRF_TOKEN&email=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PLANE_USERNAME'))")&password=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PLANE_PASSWORD'))")"

# Step 4: Use session cookie for subsequent requests (no /v1 prefix!)
curl -b cookies.txt "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/"
```

**Important notes:**
- Sign-in uses `application/x-www-form-urlencoded`, NOT JSON
- The CSRF token must be included in the form body as `csrfmiddlewaretoken`
- Email and password must be URL-encoded (special characters like `@` become `%40`)
- Successful login returns HTTP 302 redirect and sets session cookies

**Key difference:** Session-based requests use `/api/workspaces/...` (no `/v1` prefix), while API key requests use `/api/v1/workspaces/...`.

## API Base Patterns

| Auth Method | Base Path |
|-------------|-----------|
| API Key | `$PLANE_API_URL/api/v1/workspaces/{workspace_slug}/...` |
| Session Cookie (Self-Hosted) | `$PLANE_API_URL/api/workspaces/{workspace_slug}/...` |

**This skill uses session-based authentication** with the internal API path (`/api/workspaces/...`) since we're on a self-hosted instance.

---

## Projects

### List Projects

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/" | jq '.results[]'
```

### Create Project

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/" \
  -d '{
    "name": "Project Name",
    "identifier": "PROJ",
    "description": "Project description"
  }'
```

### Get/Update/Delete Project

```bash
# Get
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/"

# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/" \
  -d '{"name": "New Name"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/"
```

---

## Issues (Work Items)

### List Issues

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" | jq '.results[]'
```

### Create Issue

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" \
  -d '{
    "name": "Issue title",
    "description_html": "<p>Issue description with HTML formatting</p>",
    "priority": "high",
    "state_id": "{state_uuid}",
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
- `state_id`: State UUID (get from states endpoint)
- `assignees`: Array of user UUIDs
- `labels`: Array of label UUIDs
- `parent`: Parent issue UUID (for sub-issues)
- `start_date`: YYYY-MM-DD format
- `target_date`: YYYY-MM-DD format
- `point`: Story points (integer)

### Update Issue

```bash
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/" \
  -d '{"state_id": "{new_state_uuid}", "priority": "medium"}'
```

### Delete Issue

```bash
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/"
```

---

## States (Workflow)

### List States

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/" | jq '.results[]'
```

**Default state groups:** `backlog`, `unstarted`, `started`, `completed`, `cancelled`

### Create State

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/" \
  -d '{"name": "In Review", "color": "#8B5CF6", "group": "started"}'
```

---

## Labels

### List Labels

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/labels/"
```

### Create Label

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/labels/" \
  -d '{"name": "bug", "color": "#FF0000"}'
```

---

## Cycles (Sprints)

Time-boxed iterations for sprint planning.

### List Cycles

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/"
```

### Create Cycle

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/" \
  -d '{
    "name": "Sprint 1",
    "description": "First sprint",
    "start_date": "2025-01-01",
    "end_date": "2025-01-14"
  }'
```

**Cycle Fields:**
- `name` (required): Cycle name
- `description`: Optional description
- `start_date`, `end_date`: Date boundaries (YYYY-MM-DD)
- `owned_by`: Cycle owner UUID

### Update/Delete Cycle

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/" \
  -d '{"name": "Sprint 1 - Extended"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/"
```

### Add/Remove Work Items to Cycle

```bash
# Add work items
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/work-items/" \
  -d '{"issues": ["{issue_id_1}", "{issue_id_2}"]}'

# List cycle work items
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/work-items/"

# Remove work item
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/work-items/{work_item_id}/"

# Transfer work items to another cycle
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/transfer-work-items/" \
  -d '{"new_cycle_id": "{target_cycle_id}"}'
```

### Archive/Restore Cycle

```bash
# Archive
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/archive/"

# List archived
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/archived/"

# Restore
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/archive/"
```

---

## Modules

Group related features or functionality.

### List Modules

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/"
```

### Create Module

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/" \
  -d '{
    "name": "Authentication Module",
    "description": "User auth features",
    "status": "planned",
    "start_date": "2025-01-01",
    "target_date": "2025-02-01",
    "lead": "{user_id}",
    "members": ["{user_id_1}", "{user_id_2}"]
  }'
```

**Module Status Values:** `backlog`, `planned`, `in-progress`, `paused`, `completed`, `cancelled`

### Add/Remove Work Items to Module

```bash
# Add work items
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/work-items/" \
  -d '{"issues": ["{issue_id_1}", "{issue_id_2}"]}'

# List module work items
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/work-items/"

# Remove work item
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/work-items/{work_item_id}/"
```

### Archive/Restore Module

```bash
# Archive
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/archive/"

# List archived
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/archived/"

# Restore (note: unarchive endpoint)
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/modules/{module_id}/unarchive/"
```

---

## Initiatives

Cross-project strategic objectives at the workspace level.

### List Initiatives

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/initiatives/"
```

### Create Initiative

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/initiatives/" \
  -d '{
    "name": "Q1 2025 Product Launch",
    "description_html": "<p>Launch new product features</p>",
    "lead": "{user_id}",
    "start_date": "2025-01-01",
    "end_date": "2025-03-31",
    "state": "PLANNED"
  }'
```

**Initiative State Values:** `DRAFT`, `PLANNED`, `ACTIVE`, `COMPLETED`, `CLOSED`

### Update/Delete Initiative

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/initiatives/{initiative_id}/" \
  -d '{"state": "ACTIVE"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/initiatives/{initiative_id}/"
```

---

## Pages (Documentation)

Create documentation at workspace or project level.

**Page Fields:**
- `name`: Page title
- `description_html`: HTML content (e.g., `<p>Content</p>`)
- `access`: `0` = private, `1` = public (default: 0)
- `color`: Optional color code
- `parent`: Parent page UUID (for nested pages)
- `is_locked`: Boolean to prevent editing

### List Project Pages

```bash
# List all pages in a project (requires session auth, no /v1)
curl -b /tmp/plane_cookies.txt \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/"
```

### Create Project Page

```bash
# Create a blank page (minimal - returns page with ID)
curl -b /tmp/plane_cookies.txt -X POST \
  -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/" \
  -d '{"access": 0}'

# Create page with content
curl -b /tmp/plane_cookies.txt -X POST \
  -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/" \
  -d '{
    "name": "API Documentation",
    "description_html": "<h1>API Reference</h1><p>Endpoint documentation...</p>",
    "access": 0
  }'
```

### Get/Update/Delete Project Page

```bash
# Get page
curl -b /tmp/plane_cookies.txt \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/{page_id}/"

# Update page
curl -b /tmp/plane_cookies.txt -X PATCH \
  -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/{page_id}/" \
  -d '{"name": "Updated Title", "description_html": "<p>New content</p>"}'

# Delete page
curl -b /tmp/plane_cookies.txt -X DELETE \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/{page_id}/"
```

### Workspace Pages (Wiki)

```bash
# Create wiki page
curl -b /tmp/plane_cookies.txt -X POST \
  -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/pages/" \
  -d '{
    "name": "Architecture Overview",
    "description_html": "<h1>System Architecture</h1><p>Documentation content...</p>",
    "access": 0
  }'

# Get wiki page
curl -b /tmp/plane_cookies.txt \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/pages/{page_id}/"
```

---

## Time Tracking (Worklogs)

Log time spent on work items.

### Create Worklog

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/worklogs/" \
  -d '{
    "duration": 3600,
    "description": "Implemented authentication flow"
  }'
```

**Duration is in seconds** (3600 = 1 hour)

### List Worklogs

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/worklogs/"
```

### Get Total Time

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/worklogs/total-time/"
```

### Update/Delete Worklog

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/worklogs/{worklog_id}/" \
  -d '{"duration": 7200}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/worklogs/{worklog_id}/"
```

---

## Intake (Incoming Requests)

Manage incoming requests that can be converted to work items.

### List Intake Issues

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/intake-issues/"
```

### Create Intake Issue

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/intake-issues/" \
  -d '{
    "name": "Feature Request: Dark Mode",
    "description_html": "<p>User requested dark mode support</p>"
  }'
```

### Update/Delete Intake Issue

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/intake-issues/{intake_issue_id}/" \
  -d '{"name": "Updated request title"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/intake-issues/{intake_issue_id}/"
```

---

## Comments

Add comments to work items.

### List Comments

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/comments/"
```

### Create Comment

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/comments/" \
  -d '{
    "comment_html": "<p>This is a comment with <strong>formatting</strong></p>"
  }'
```

### Update/Delete Comment

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/comments/{comment_id}/" \
  -d '{"comment_html": "<p>Updated comment</p>"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/comments/{comment_id}/"
```

---

## Links

Attach external references to work items.

### List Links

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/links/"
```

### Create Link

```bash
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/links/" \
  -d '{
    "title": "Design Document",
    "url": "https://figma.com/file/xxx"
  }'
```

### Update/Delete Link

```bash
# Update
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/links/{link_id}/" \
  -d '{"title": "Updated title"}'

# Delete
curl -s -X DELETE -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/links/{link_id}/"
```

---

## Activity

View work item activity history.

### List Activities

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/activities/"
```

### Get Activity Detail

```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/work-items/{work_item_id}/activities/{activity_id}/"
```

---

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

---

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
8. **Create initiative** if part of larger cross-project effort
9. **Create pages** for technical documentation

---

## Issue Tracking During Development

When working on tasks:

1. **Before starting work**: Move issue to "In Progress" state
2. **Log time**: Create worklogs for time spent
3. **Add comments**: Document decisions and blockers
4. **Reference issues in commits**: Include `[PROJ-{sequence_id}]` in commit messages
5. **After completing work**: Move issue to "Done" state
6. **For blockers**: Add comments or create linked blocking issues

---

## Helper: Get State ID by Name

```bash
STATE_ID=$(curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/" \
  | jq -r '.results[] | select(.name=="In Progress") | .id')
```

---

## Rate Limiting

API is rate-limited to 60 requests per minute. Check `X-RateLimit-Remaining` header.

## Error Handling

Common error responses:
- `400`: Bad request (invalid data)
- `401`: Invalid API key
- `403`: Insufficient permissions
- `404`: Resource not found
- `429`: Rate limit exceeded
