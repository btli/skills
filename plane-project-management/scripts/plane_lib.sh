#!/bin/bash
# Plane API Library for Self-Hosted Instances
# Provides functions for both API key and session-based authentication
#
# Usage:
#   source ~/.claude/skills/plane-project-management/scripts/plane_lib.sh
#   plane_init  # Initialize and authenticate
#
# Required environment variables (~/.claude/.env):
#   PLANE_API_URL      - Base URL (e.g., https://plane.joyful.house)
#   PLANE_API_KEY      - API key for v1 endpoints
#   PLANE_WORKSPACE    - Workspace slug (e.g., kaelyn-ai)
#   PLANE_USERNAME     - Login email (for session auth)
#   PLANE_PASSWORD     - Login password (for session auth)

set -o pipefail

# Cookie file for session-based auth
PLANE_COOKIE_FILE="/tmp/plane_cookies.txt"

# Load environment
if [ -f ~/.claude/.env ]; then
    set -a
    source ~/.claude/.env
    set +a
fi

# =============================================================================
# INITIALIZATION & AUTHENTICATION
# =============================================================================

plane_check_env() {
    local missing=()
    [ -z "$PLANE_API_URL" ] && missing+=("PLANE_API_URL")
    [ -z "$PLANE_WORKSPACE" ] && missing+=("PLANE_WORKSPACE")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        echo "Please set them in ~/.claude/.env" >&2
        return 1
    fi
    return 0
}

plane_session_login() {
    # Authenticate with username/password for session-based API access
    # Required for: Pages, some internal endpoints

    if [ -z "$PLANE_USERNAME" ] || [ -z "$PLANE_PASSWORD" ]; then
        echo "Error: PLANE_USERNAME and PLANE_PASSWORD required for session auth" >&2
        return 1
    fi

    rm -f "$PLANE_COOKIE_FILE"

    # Get CSRF token
    local csrf_response
    csrf_response=$(curl -s -c "$PLANE_COOKIE_FILE" "$PLANE_API_URL/auth/get-csrf-token/")
    local csrf_token
    csrf_token=$(echo "$csrf_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('csrf_token',''))" 2>/dev/null)

    if [ -z "$csrf_token" ]; then
        echo "Error: Failed to get CSRF token" >&2
        return 1
    fi

    # Login with form-urlencoded data
    local login_response
    login_response=$(curl -s -c "$PLANE_COOKIE_FILE" -b "$PLANE_COOKIE_FILE" \
        -X POST "$PLANE_API_URL/auth/sign-in/" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Origin: $PLANE_API_URL" \
        -H "Referer: $PLANE_API_URL/" \
        --data-urlencode "csrfmiddlewaretoken=$csrf_token" \
        --data-urlencode "email=$PLANE_USERNAME" \
        --data-urlencode "password=$PLANE_PASSWORD")

    # Check for session cookie
    if grep -q "session-id" "$PLANE_COOKIE_FILE" 2>/dev/null; then
        echo "Session authentication successful"
        return 0
    else
        echo "Error: Session authentication failed" >&2
        echo "Response: ${login_response:0:200}" >&2
        return 1
    fi
}

plane_init() {
    # Initialize Plane API access
    plane_check_env || return 1

    # Test API key auth
    if [ -n "$PLANE_API_KEY" ]; then
        local test_response
        test_response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "X-API-Key: $PLANE_API_KEY" \
            "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/")
        if [ "$test_response" = "200" ]; then
            echo "API key authentication verified"
        else
            echo "Warning: API key auth returned HTTP $test_response" >&2
        fi
    fi

    # Establish session auth for internal endpoints
    if [ -n "$PLANE_USERNAME" ] && [ -n "$PLANE_PASSWORD" ]; then
        plane_session_login
    fi
}

# =============================================================================
# LOW-LEVEL API CALLS
# =============================================================================

plane_api_v1() {
    # Make API call using API key (v1 endpoints)
    # Usage: plane_api_v1 METHOD ENDPOINT [DATA]
    local method="${1:-GET}"
    local endpoint="$2"
    local data="$3"

    local url="$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE$endpoint"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-API-Key: $PLANE_API_KEY" \
            -H "Content-Type: application/json" \
            "$url" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "X-API-Key: $PLANE_API_KEY" \
            "$url"
    fi
}

plane_api_session() {
    # Make API call using session cookie (internal endpoints)
    # Usage: plane_api_session METHOD ENDPOINT [DATA]
    local method="${1:-GET}"
    local endpoint="$2"
    local data="$3"

    local url="$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE$endpoint"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -b "$PLANE_COOKIE_FILE" \
            -H "Content-Type: application/json" \
            "$url" \
            -d "$data"
    else
        curl -s -X "$method" \
            -b "$PLANE_COOKIE_FILE" \
            "$url"
    fi
}

# =============================================================================
# PROJECTS
# =============================================================================

plane_list_projects() {
    # List all projects in workspace
    # Output: identifier: name (id)
    plane_api_v1 GET "/projects/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('results', []):
    print(f\"{p['identifier']}: {p['name']} ({p['id']})\")"
}

plane_get_project_id() {
    # Get project ID by identifier
    # Usage: plane_get_project_id IDENTIFIER
    local identifier="$1"
    plane_api_v1 GET "/projects/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('results', []):
    if p['identifier'] == '$identifier':
        print(p['id'])
        break"
}

plane_get_project() {
    # Get project details
    # Usage: plane_get_project PROJECT_ID
    local project_id="$1"
    plane_api_v1 GET "/projects/$project_id/"
}

# =============================================================================
# STATES
# =============================================================================

plane_list_states() {
    # List states for a project
    # Usage: plane_list_states PROJECT_ID
    local project_id="$1"
    plane_api_v1 GET "/projects/$project_id/states/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('results', []):
    print(f\"{s['name']}: {s['id']} (group: {s['group']})\")"
}

plane_get_state_id() {
    # Get state ID by name
    # Usage: plane_get_state_id PROJECT_ID STATE_NAME
    local project_id="$1"
    local state_name="$2"
    plane_api_v1 GET "/projects/$project_id/states/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('results', []):
    if s['name'].lower() == '$state_name'.lower():
        print(s['id'])
        break"
}

plane_get_state_id_by_group() {
    # Get first state ID in a state group
    # Usage: plane_get_state_id_by_group PROJECT_ID GROUP
    # Groups: backlog, unstarted, started, completed, cancelled
    local project_id="$1"
    local group="$2"
    plane_api_v1 GET "/projects/$project_id/states/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('results', []):
    if s['group'] == '$group':
        print(s['id'])
        break"
}

# =============================================================================
# ISSUES
# =============================================================================

plane_list_issues() {
    # List issues in a project (uses session auth for state__group field)
    # Usage: plane_list_issues PROJECT_ID [--state STATE_GROUP] [--priority PRIORITY]
    local project_id="$1"
    shift

    local state_filter=""
    local priority_filter=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --state) state_filter="$2"; shift 2 ;;
            --priority) priority_filter="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Use session auth to get state__group field
    plane_api_session GET "/projects/$project_id/issues/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('results', []) if isinstance(data, dict) else data
state_filter = '$state_filter'
priority_filter = '$priority_filter'
for issue in results:
    if state_filter and issue.get('state__group') != state_filter:
        continue
    if priority_filter and issue.get('priority') != priority_filter:
        continue
    state_group = issue.get('state__group', '?')
    print(f\"{issue['sequence_id']:4}: [{state_group:10}] [{issue.get('priority','none'):6}] {issue['name']}\")"
}

plane_list_issues_by_state() {
    # List issues by state group
    # Usage: plane_list_issues_by_state PROJECT_ID STATE_GROUP
    # Groups: backlog, unstarted, started, completed, cancelled
    local project_id="$1"
    local state_group="$2"
    plane_list_issues "$project_id" --state "$state_group"
}

plane_list_todo_issues() {
    # List issues in Todo/Unstarted state
    # Usage: plane_list_todo_issues PROJECT_ID
    plane_list_issues_by_state "$1" "unstarted"
}

plane_list_in_progress_issues() {
    # List issues in progress
    # Usage: plane_list_in_progress_issues PROJECT_ID
    plane_list_issues_by_state "$1" "started"
}

plane_list_backlog_issues() {
    # List issues in backlog
    # Usage: plane_list_backlog_issues PROJECT_ID
    plane_list_issues_by_state "$1" "backlog"
}

plane_get_issue() {
    # Get issue details
    # Usage: plane_get_issue PROJECT_ID ISSUE_ID
    local project_id="$1"
    local issue_id="$2"
    plane_api_v1 GET "/projects/$project_id/issues/$issue_id/"
}

plane_get_issue_by_sequence() {
    # Get issue ID by sequence number
    # Usage: plane_get_issue_by_sequence PROJECT_ID SEQUENCE_ID
    local project_id="$1"
    local sequence_id="$2"
    plane_api_v1 GET "/projects/$project_id/issues/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for issue in data.get('results', []):
    if issue['sequence_id'] == $sequence_id:
        print(issue['id'])
        break"
}

plane_create_issue() {
    # Create a new issue
    # Usage: plane_create_issue PROJECT_ID NAME [DESCRIPTION] [PRIORITY]
    local project_id="$1"
    local name="$2"
    local description="${3:-}"
    local priority="${4:-none}"

    local data="{\"name\": \"$name\", \"priority\": \"$priority\""
    [ -n "$description" ] && data="$data, \"description_html\": \"<p>$description</p>\""
    data="$data}"

    plane_api_v1 POST "/projects/$project_id/issues/" "$data"
}

plane_update_issue() {
    # Update an issue
    # Usage: plane_update_issue PROJECT_ID ISSUE_ID JSON_DATA
    local project_id="$1"
    local issue_id="$2"
    local data="$3"

    plane_api_v1 PATCH "/projects/$project_id/issues/$issue_id/" "$data"
}

plane_update_issue_state() {
    # Update issue state
    # Usage: plane_update_issue_state PROJECT_ID ISSUE_ID STATE_ID
    local project_id="$1"
    local issue_id="$2"
    local state_id="$3"

    # Note: API v1 uses "state" field, not "state_id"
    plane_update_issue "$project_id" "$issue_id" "{\"state\": \"$state_id\"}"
}

plane_move_issue_to_todo() {
    # Move issue to Todo state
    local project_id="$1"
    local issue_id="$2"
    local state_id
    state_id=$(plane_get_state_id "$project_id" "Todo")
    plane_update_issue_state "$project_id" "$issue_id" "$state_id"
}

plane_move_issue_to_in_progress() {
    # Move issue to In Progress state
    local project_id="$1"
    local issue_id="$2"
    local state_id
    state_id=$(plane_get_state_id "$project_id" "In Progress")
    plane_update_issue_state "$project_id" "$issue_id" "$state_id"
}

plane_move_issue_to_done() {
    # Move issue to Done state
    local project_id="$1"
    local issue_id="$2"
    local state_id
    state_id=$(plane_get_state_id "$project_id" "Done")
    plane_update_issue_state "$project_id" "$issue_id" "$state_id"
}

plane_delete_issue() {
    # Delete an issue
    # Usage: plane_delete_issue PROJECT_ID ISSUE_ID
    local project_id="$1"
    local issue_id="$2"
    plane_api_v1 DELETE "/projects/$project_id/issues/$issue_id/"
}

# =============================================================================
# CYCLES (SPRINTS)
# =============================================================================

plane_list_cycles() {
    # List cycles in a project (uses session auth)
    # Usage: plane_list_cycles PROJECT_ID
    local project_id="$1"
    plane_api_session GET "/projects/$project_id/cycles/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cycles = data if isinstance(data, list) else data.get('results', [])
for c in cycles:
    status = c.get('status', '?')
    print(f\"{c['name']}: {c['id']} [{status}] ({c.get('start_date','?')[:10]} - {c.get('end_date','?')[:10]})\")"
}

plane_get_cycle() {
    # Get cycle details
    # Usage: plane_get_cycle PROJECT_ID CYCLE_ID
    local project_id="$1"
    local cycle_id="$2"
    plane_api_session GET "/projects/$project_id/cycles/$cycle_id/"
}

plane_create_cycle() {
    # Create a new cycle
    # Usage: plane_create_cycle PROJECT_ID NAME START_DATE END_DATE [DESCRIPTION]
    local project_id="$1"
    local name="$2"
    local start_date="$3"
    local end_date="$4"
    local description="${5:-}"

    local data="{\"name\": \"$name\", \"start_date\": \"${start_date}T00:00:01Z\", \"end_date\": \"${end_date}T23:59:00Z\""
    [ -n "$description" ] && data="$data, \"description\": \"$description\""
    data="$data}"

    plane_api_session POST "/projects/$project_id/cycles/" "$data"
}

plane_update_cycle() {
    # Update a cycle
    # Usage: plane_update_cycle PROJECT_ID CYCLE_ID JSON_DATA
    local project_id="$1"
    local cycle_id="$2"
    local data="$3"

    plane_api_session PATCH "/projects/$project_id/cycles/$cycle_id/" "$data"
}

plane_delete_cycle() {
    # Delete a cycle
    # Usage: plane_delete_cycle PROJECT_ID CYCLE_ID
    local project_id="$1"
    local cycle_id="$2"
    plane_api_session DELETE "/projects/$project_id/cycles/$cycle_id/"
}

plane_add_issues_to_cycle() {
    # Add issues to a cycle
    # Usage: plane_add_issues_to_cycle PROJECT_ID CYCLE_ID ISSUE_ID1 [ISSUE_ID2 ...]
    local project_id="$1"
    local cycle_id="$2"
    shift 2

    # Build JSON array of issue IDs
    local issues_json="["
    local first=true
    for issue_id in "$@"; do
        [ "$first" = "false" ] && issues_json="$issues_json,"
        issues_json="$issues_json\"$issue_id\""
        first=false
    done
    issues_json="$issues_json]"

    plane_api_session POST "/projects/$project_id/cycles/$cycle_id/cycle-issues/" \
        "{\"issues\": $issues_json}"
}

plane_list_cycle_issues() {
    # List issues in a cycle
    # Usage: plane_list_cycle_issues PROJECT_ID CYCLE_ID
    local project_id="$1"
    local cycle_id="$2"
    plane_api_session GET "/projects/$project_id/cycles/$cycle_id/cycle-issues/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('results', [])
for ci in issues:
    issue = ci.get('issue_detail', ci)
    print(f\"{issue.get('sequence_id',0):4}: {issue.get('name','?')}\")"
}

# =============================================================================
# PAGES (DOCUMENTATION) - Requires Session Auth
# =============================================================================

plane_list_pages() {
    # List pages in a project
    # Usage: plane_list_pages PROJECT_ID
    local project_id="$1"
    plane_api_session GET "/projects/$project_id/pages/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
pages = data if isinstance(data, list) else data.get('results', [])
for p in pages:
    access = 'public' if p.get('access') == 1 else 'private'
    print(f\"{p['name']}: {p['id']} [{access}]\")"
}

plane_get_page() {
    # Get page details
    # Usage: plane_get_page PROJECT_ID PAGE_ID
    local project_id="$1"
    local page_id="$2"
    plane_api_session GET "/projects/$project_id/pages/$page_id/"
}

plane_get_page_content() {
    # Get page content as HTML
    # Usage: plane_get_page_content PROJECT_ID PAGE_ID
    local project_id="$1"
    local page_id="$2"
    plane_api_session GET "/projects/$project_id/pages/$page_id/description/"
}

plane_create_page() {
    # Create a new page
    # Usage: plane_create_page PROJECT_ID NAME [CONTENT_HTML] [ACCESS]
    # ACCESS: 0 = private (default), 1 = public
    local project_id="$1"
    local name="$2"
    local content="${3:-}"
    local access="${4:-0}"

    local data="{\"name\": \"$name\", \"access\": $access"
    [ -n "$content" ] && data="$data, \"description_html\": \"$content\""
    data="$data}"

    plane_api_session POST "/projects/$project_id/pages/" "$data"
}

plane_update_page() {
    # Update a page
    # Usage: plane_update_page PROJECT_ID PAGE_ID JSON_DATA
    local project_id="$1"
    local page_id="$2"
    local data="$3"

    plane_api_session PATCH "/projects/$project_id/pages/$page_id/" "$data"
}

plane_update_page_content() {
    # Update page content
    # Usage: plane_update_page_content PROJECT_ID PAGE_ID CONTENT_HTML
    local project_id="$1"
    local page_id="$2"
    local content="$3"

    plane_update_page "$project_id" "$page_id" "{\"description_html\": \"$content\"}"
}

plane_delete_page() {
    # Delete a page
    # Usage: plane_delete_page PROJECT_ID PAGE_ID
    local project_id="$1"
    local page_id="$2"
    plane_api_session DELETE "/projects/$project_id/pages/$page_id/"
}

# =============================================================================
# MODULES
# =============================================================================

plane_list_modules() {
    # List modules in a project
    # Usage: plane_list_modules PROJECT_ID
    local project_id="$1"
    plane_api_v1 GET "/projects/$project_id/modules/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data.get('results', []):
    status = m.get('status', '?')
    print(f\"{m['name']}: {m['id']} [{status}]\")"
}

plane_create_module() {
    # Create a new module
    # Usage: plane_create_module PROJECT_ID NAME [DESCRIPTION] [STATUS]
    # STATUS: backlog, planned, in-progress, paused, completed, cancelled
    local project_id="$1"
    local name="$2"
    local description="${3:-}"
    local status="${4:-planned}"

    local data="{\"name\": \"$name\", \"status\": \"$status\""
    [ -n "$description" ] && data="$data, \"description\": \"$description\""
    data="$data}"

    plane_api_v1 POST "/projects/$project_id/modules/" "$data"
}

# =============================================================================
# LABELS
# =============================================================================

plane_list_labels() {
    # List labels in a project
    # Usage: plane_list_labels PROJECT_ID
    local project_id="$1"
    plane_api_v1 GET "/projects/$project_id/labels/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for l in data.get('results', []):
    print(f\"{l['name']}: {l['id']} ({l.get('color','#000')})\")"
}

plane_create_label() {
    # Create a new label
    # Usage: plane_create_label PROJECT_ID NAME [COLOR]
    local project_id="$1"
    local name="$2"
    local color="${3:-#3b82f6}"

    plane_api_v1 POST "/projects/$project_id/labels/" \
        "{\"name\": \"$name\", \"color\": \"$color\"}"
}

# =============================================================================
# WORKSPACE MEMBERS
# =============================================================================

plane_list_members() {
    # List workspace members
    plane_api_session GET "/members/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
members = data if isinstance(data, list) else data.get('results', [])
for m in members:
    member = m.get('member', {})
    print(f\"{member.get('display_name','?')}: {member.get('id','?')} ({member.get('email','?')})\")"
}

plane_get_member_id() {
    # Get member ID by email
    # Usage: plane_get_member_id EMAIL
    local email="$1"
    plane_api_session GET "/members/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
members = data if isinstance(data, list) else data.get('results', [])
for m in members:
    member = m.get('member', {})
    if member.get('email') == '$email':
        print(member.get('id'))
        break"
}

# =============================================================================
# HELPERS
# =============================================================================

plane_json_pretty() {
    # Pretty print JSON
    python3 -m json.tool
}

plane_summary() {
    # Print summary of workspace
    echo "=== Plane Workspace Summary: $PLANE_WORKSPACE ==="
    echo ""
    echo "Projects:"
    plane_list_projects
    echo ""
}

# Print help when sourced
echo "Plane API library loaded. Run 'plane_init' to authenticate."
echo "Available commands: plane_list_projects, plane_list_issues, plane_list_cycles, etc."
