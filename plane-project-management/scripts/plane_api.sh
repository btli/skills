#!/bin/bash
# Plane API Helper Script
# Source this file to use Plane API functions
# Usage: source ~/.claude/skills/plane/scripts/plane_api.sh

# Load credentials
if [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

# Verify required variables
plane_check_config() {
    local missing=()
    [ -z "$PLANE_API_URL" ] && missing+=("PLANE_API_URL")
    [ -z "$PLANE_API_KEY" ] && missing+=("PLANE_API_KEY")
    [ -z "$PLANE_WORKSPACE" ] && missing+=("PLANE_WORKSPACE")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        echo "Please set them in ~/.claude/.env" >&2
        return 1
    fi
    return 0
}

# Base API call
plane_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="$3"

    plane_check_config || return 1

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

# List all projects
plane_projects() {
    plane_api GET "/projects/" | jq -r '.results[] | "\(.identifier): \(.name) (\(.id))"'
}

# Get project ID by identifier
plane_project_id() {
    local identifier="$1"
    plane_api GET "/projects/" | jq -r ".results[] | select(.identifier==\"$identifier\") | .id"
}

# List issues in a project
plane_issues() {
    local project_id="$1"
    plane_api GET "/projects/$project_id/issues/" | jq -r '.results[] | "\(.sequence_id): \(.name) [\(.priority)]"'
}

# Create an issue
plane_create_issue() {
    local project_id="$1"
    local name="$2"
    local description="${3:-}"
    local priority="${4:-none}"

    local data="{\"name\": \"$name\", \"priority\": \"$priority\""
    [ -n "$description" ] && data="${data}, \"description_html\": \"<p>$description</p>\""
    data="${data}}"

    plane_api POST "/projects/$project_id/issues/" "$data"
}

# Update issue state
plane_update_issue_state() {
    local project_id="$1"
    local issue_id="$2"
    local state_id="$3"

    plane_api PATCH "/projects/$project_id/issues/$issue_id/" "{\"state\": \"$state_id\"}"
}

# Get states for a project
plane_states() {
    local project_id="$1"
    plane_api GET "/projects/$project_id/states/" | jq -r '.results[] | "\(.name): \(.id) (\(.group))"'
}

# Get state ID by name
plane_state_id() {
    local project_id="$1"
    local state_name="$2"
    plane_api GET "/projects/$project_id/states/" | jq -r ".results[] | select(.name==\"$state_name\") | .id"
}

# Create a label
plane_create_label() {
    local project_id="$1"
    local name="$2"
    local color="${3:-#3b82f6}"

    plane_api POST "/projects/$project_id/labels/" "{\"name\": \"$name\", \"color\": \"$color\"}"
}

# List cycles
plane_cycles() {
    local project_id="$1"
    plane_api GET "/projects/$project_id/cycles/" | jq -r '.results[] | "\(.name): \(.id)"'
}

# Create a cycle
plane_create_cycle() {
    local project_id="$1"
    local name="$2"
    local start_date="$3"
    local end_date="$4"

    plane_api POST "/projects/$project_id/cycles/" "{\"name\": \"$name\", \"start_date\": \"$start_date\", \"end_date\": \"$end_date\"}"
}

# List modules
plane_modules() {
    local project_id="$1"
    plane_api GET "/projects/$project_id/modules/" | jq -r '.results[] | "\(.name): \(.id)"'
}

# Create a module
plane_create_module() {
    local project_id="$1"
    local name="$2"
    local description="${3:-}"

    local data="{\"name\": \"$name\""
    [ -n "$description" ] && data="${data}, \"description\": \"$description\""
    data="${data}}"

    plane_api POST "/projects/$project_id/modules/" "$data"
}

echo "Plane API helpers loaded. Run 'plane_projects' to list projects."
