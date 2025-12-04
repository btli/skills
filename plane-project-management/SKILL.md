---
name: plane-project-management
description: |
  Interact with Plane project management (self-hosted) via REST API for issue tracking, project planning, sprint management, time tracking, and documentation. This skill should be used when: (1) working in a project directory that needs task tracking, (2) creating implementation plans with trackable issues, (3) managing sprints/cycles and modules, (4) updating issue status as work progresses, (5) logging time spent on tasks, (6) creating project documentation pages. Secrets stored in Phase (claude-code app).
---

# Plane Project Management Skill

Manage projects, issues, cycles, modules, pages, and time tracking in a **self-hosted Plane instance** via the REST API.

## Quick Start - Optimized CLI

Use the `plane` CLI for efficient interaction with caching and minimal API calls:

```bash
# Add to PATH (one-time setup)
export PATH="$PATH:~/.claude/skills/plane-project-management/scripts"

# Or use full path
~/.claude/skills/plane-project-management/scripts/plane <command>
```

### Basic Commands

```bash
plane status              # List all projects
plane status AI           # Show AI project summary
plane todo AI             # List todo items
plane doing AI            # List in-progress items
plane start AI 5          # Move AI-5 to In Progress
plane finish AI 5         # Move AI-5 to Done
plane new AI "Fix bug"    # Create new issue
plane cycles AI           # List cycles
plane pages AI            # List pages
plane refresh             # Clear cache
```

### Output Example

```
$ plane status AI
AI Status:
  Backlog:     1
  Todo:        9
  In Progress: 3
  Done:        2

$ plane todo AI
 17 [M] [CYCLE-2] Add Confidence Thresholds for Extraction
 15 [H] [CYCLE-2] Add Validation Layer for Criteria Extraction
 10 [H] [MVP] Add Conversation Memory Management
```

### Performance Features

- **Caching**: Project and state data cached for 1 hour
- **Session reuse**: Session cookies cached for 30 minutes
- **Minimal output**: Clean, scannable output format
- **Phase integration**: Secrets loaded from Phase automatically

## Available Scripts

| Script | Purpose |
|--------|---------|
| `plane` | **Recommended** - Optimized CLI with caching |
| `plane_lib.sh` | Core library with all API functions |
| `plane_tasks.sh` | Verbose task management |
| `plane_cycles.sh` | Cycle/sprint management |
| `plane_pages.sh` | Documentation pages management |

---

## Configuration

### Secrets (Phase)

Secrets are stored in Phase under the `claude-code` application:

```bash
# View secrets
phase secrets list --app claude-code

# Get a secret
phase secrets get PLANE_API_KEY --app claude-code
```

Required secrets in Phase:
- `PLANE_API_KEY` - API key for authentication
- `PLANE_USERNAME` - Login email
- `PLANE_PASSWORD` - Login password

### Environment (`.env`)

Non-secret configuration in `~/.claude/.env`:

```bash
PLANE_API_URL=https://plane.joyful.house
PLANE_WORKSPACE=kaelyn-ai  # Optional, defaults to kaelyn-ai
```

---

## Authentication Methods

### Method 1: API Key (Public API v1)

Most operations use API key authentication with the `/api/v1/` prefix:

```bash
curl -H "X-API-Key: $PLANE_API_KEY" "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/"
```

### Method 2: Session-Based (Self-Hosted Internal API)

Some endpoints (Pages, Members) require session-based authentication:

```bash
# Use the login script
~/.claude/skills/plane-project-management/scripts/plane_selfhosted_login.sh

# Or manually:
# 1. Get CSRF token
CSRF_RESPONSE=$(curl -s -c /tmp/plane_cookies.txt "$PLANE_API_URL/auth/get-csrf-token/")
CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['csrf_token'])")

# 2. Login with form-urlencoded data (NOT JSON!)
curl -c /tmp/plane_cookies.txt -b /tmp/plane_cookies.txt -X POST "$PLANE_API_URL/auth/sign-in/" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Origin: $PLANE_API_URL" \
  --data-urlencode "csrfmiddlewaretoken=$CSRF_TOKEN" \
  --data-urlencode "email=$PLANE_USERNAME" \
  --data-urlencode "password=$PLANE_PASSWORD"

# 3. Use session cookie for requests (no /v1 prefix!)
curl -b /tmp/plane_cookies.txt "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/"
```

### API Path Differences

| Auth Method | Base Path | Use For |
|-------------|-----------|---------|
| API Key | `/api/v1/workspaces/{slug}/...` | Projects, Issues, States, Labels, Modules |
| Session | `/api/workspaces/{slug}/...` | Pages, Members, Cycles (has extra fields) |

---

## Task Management Script

```bash
./plane_tasks.sh <command> [args]

# Commands:
  list [PROJECT]        - List all tasks in project
  todo [PROJECT]        - List To Do tasks (unstarted)
  doing [PROJECT]       - List In Progress tasks (started)
  done [PROJECT]        - List Completed tasks
  backlog [PROJECT]     - List Backlog tasks
  start PROJECT SEQ_ID  - Move task to In Progress
  complete PROJECT SEQ_ID - Move task to Done
  create PROJECT NAME [DESC] - Create new task
  projects              - List all projects

# Examples:
  ./plane_tasks.sh todo AI            # List To Do tasks in AI Agents project
  ./plane_tasks.sh start AI 5         # Move task AI-5 to In Progress
  ./plane_tasks.sh complete AI 5      # Move task AI-5 to Done
  ./plane_tasks.sh create AI "Fix bug" "Description here"
```

---

## Cycles (Sprints) Script

```bash
./plane_cycles.sh <command> [args]

# Commands:
  list PROJECT                    - List all cycles in project
  show PROJECT CYCLE_ID           - Show cycle details
  issues PROJECT CYCLE_ID         - List issues in cycle
  create PROJECT NAME START END   - Create new cycle (dates: YYYY-MM-DD)
  add PROJECT CYCLE_ID SEQ1 [SEQ2...] - Add issues to cycle

# Examples:
  ./plane_cycles.sh list AI
  ./plane_cycles.sh create AI "Sprint 4" 2025-02-01 2025-02-14
  ./plane_cycles.sh add AI <cycle-id> 5 6 7  # Add issues 5,6,7 to cycle
```

---

## Pages (Documentation) Script

```bash
./plane_pages.sh <command> [args]

# Commands:
  list PROJECT                    - List all pages in project
  show PROJECT PAGE_ID            - Show page details (JSON)
  content PROJECT PAGE_ID         - Get page content (HTML)
  create PROJECT NAME [CONTENT]   - Create new page (HTML content)
  update PROJECT PAGE_ID CONTENT  - Update page content
  from-file PROJECT FILE          - Create page from markdown file
  delete PROJECT PAGE_ID          - Delete a page

# Examples:
  ./plane_pages.sh list AI
  ./plane_pages.sh create AI "API Docs" "<h1>API</h1><p>Documentation</p>"
  ./plane_pages.sh from-file AI ./docs/README.md
```

---

## Library Functions

Source the library for programmatic access:

```bash
source ~/.claude/skills/plane-project-management/scripts/plane_lib.sh
plane_init
```

### Projects
```bash
plane_list_projects                  # List all projects
plane_get_project_id IDENTIFIER      # Get project UUID by identifier (e.g., "AI")
plane_get_project PROJECT_ID         # Get project details
```

### Issues
```bash
plane_list_issues PROJECT_ID                    # List all issues
plane_list_issues PROJECT_ID --state unstarted  # Filter by state group
plane_list_todo_issues PROJECT_ID               # List To Do issues
plane_list_in_progress_issues PROJECT_ID        # List In Progress issues
plane_list_backlog_issues PROJECT_ID            # List Backlog issues

plane_get_issue PROJECT_ID ISSUE_ID             # Get issue details
plane_get_issue_by_sequence PROJECT_ID SEQ_ID   # Get issue UUID by sequence #

plane_create_issue PROJECT_ID NAME [DESC] [PRIORITY]  # Create issue
plane_update_issue PROJECT_ID ISSUE_ID JSON_DATA      # Update issue
plane_update_issue_state PROJECT_ID ISSUE_ID STATE_ID # Change state

plane_move_issue_to_todo PROJECT_ID ISSUE_ID          # Move to Todo
plane_move_issue_to_in_progress PROJECT_ID ISSUE_ID   # Move to In Progress
plane_move_issue_to_done PROJECT_ID ISSUE_ID          # Move to Done
```

### States
```bash
plane_list_states PROJECT_ID                    # List states
plane_get_state_id PROJECT_ID STATE_NAME        # Get state UUID by name
plane_get_state_id_by_group PROJECT_ID GROUP    # Get state by group
```

State groups: `backlog`, `unstarted`, `started`, `completed`, `cancelled`

### Cycles
```bash
plane_list_cycles PROJECT_ID                    # List cycles
plane_get_cycle PROJECT_ID CYCLE_ID             # Get cycle details
plane_create_cycle PROJECT_ID NAME START END    # Create cycle
plane_add_issues_to_cycle PROJECT_ID CYCLE_ID ISSUE_ID1 [ISSUE_ID2...]
plane_list_cycle_issues PROJECT_ID CYCLE_ID     # List cycle issues
```

### Pages
```bash
plane_list_pages PROJECT_ID                     # List pages
plane_get_page PROJECT_ID PAGE_ID               # Get page details
plane_get_page_content PROJECT_ID PAGE_ID       # Get page HTML content
plane_create_page PROJECT_ID NAME [HTML] [ACCESS]  # Create page (ACCESS: 0=private, 1=public)
plane_update_page_content PROJECT_ID PAGE_ID HTML  # Update page content
plane_delete_page PROJECT_ID PAGE_ID            # Delete page
```

### Members
```bash
plane_list_members                              # List workspace members
plane_get_member_id EMAIL                       # Get member UUID by email
```

---

## Direct API Usage

### Projects
```bash
# List projects
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/" | jq '.results[]'
```

### Issues
```bash
# List issues in project
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/"

# Create issue
curl -s -X POST -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/" \
  -d '{
    "name": "Issue title",
    "description_html": "<p>Description</p>",
    "priority": "high"
  }'

# Update issue state (note: use "state" not "state_id" for API v1)
curl -s -X PATCH -H "X-API-Key: $PLANE_API_KEY" -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/issues/{issue_id}/" \
  -d '{"state": "{state_uuid}"}'
```

### States
```bash
# List states for project
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/{project_id}/states/"
```

### Cycles (Session Auth Required for Full Data)
```bash
# List cycles (session auth gets more fields like status)
curl -s -b /tmp/plane_cookies.txt \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/"

# Create cycle
curl -s -X POST -b /tmp/plane_cookies.txt -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/" \
  -d '{
    "name": "Sprint 1",
    "start_date": "2025-01-01T00:00:01Z",
    "end_date": "2025-01-14T23:59:00Z"
  }'

# Add issues to cycle
curl -s -X POST -b /tmp/plane_cookies.txt -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/cycles/{cycle_id}/cycle-issues/" \
  -d '{"issues": ["{issue_id_1}", "{issue_id_2}"]}'
```

### Pages (Session Auth Required)
```bash
# List pages
curl -s -b /tmp/plane_cookies.txt \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/"

# Create page
curl -s -X POST -b /tmp/plane_cookies.txt -H "Content-Type: application/json" \
  "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/{project_id}/pages/" \
  -d '{
    "name": "Documentation",
    "description_html": "<h1>Title</h1><p>Content</p>",
    "access": 0
  }'
```

---

## Field Values Reference

### Issue Priority
- `urgent` - Critical, immediate attention
- `high` - Important
- `medium` - Normal priority
- `low` - Can wait
- `none` - No priority set

### State Groups
- `backlog` - Items not yet planned
- `unstarted` - Planned but not started (typically "Todo")
- `started` - Work in progress
- `completed` - Done
- `cancelled` - Won't do

### Cycle Status
- `UPCOMING` - Not yet started
- `CURRENT` - Currently active
- `COMPLETED` - Finished
- `DRAFT` - Not finalized

### Page Access
- `0` - Private (default)
- `1` - Public

---

## Workflow Examples

### Start Working on a Task
```bash
# List available tasks
./plane_tasks.sh todo AI

# Start working on task 5
./plane_tasks.sh start AI 5

# When done
./plane_tasks.sh complete AI 5
```

### Create a New Sprint
```bash
# Create cycle
./plane_cycles.sh create AI "Sprint 5" 2025-02-15 2025-02-28

# Add issues to the cycle
./plane_cycles.sh add AI <cycle-id> 10 11 12
```

### Create Documentation
```bash
# From command line
./plane_pages.sh create AI "API Reference" "<h1>API</h1><p>Endpoints...</p>"

# From markdown file
./plane_pages.sh from-file AI ./docs/api.md
```

### Reference Issues in Commits
```bash
git commit -m "[AI-5] Implement search parser

Closes issue AI-5 by adding property search intent parsing."
```

---

## Troubleshooting

### Session Authentication Issues
- Ensure `PLANE_USERNAME` and `PLANE_PASSWORD` are set in `~/.claude/.env`
- Run `./plane_selfhosted_login.sh` to re-authenticate
- Check cookies exist: `cat /tmp/plane_cookies.txt`

### API Returns Empty or 401
- Verify `PLANE_API_KEY` is valid
- Check workspace slug is correct
- Ensure API key has permissions for the workspace

### State Updates Not Working
- Use `state` field (not `state_id`) for API v1 updates
- Get state UUIDs with `plane_list_states PROJECT_ID`

### Rate Limiting
- API is rate-limited to 60 requests per minute
- Check `X-RateLimit-Remaining` header
- HTTP 429 = rate limit exceeded

---

## Response Format

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
