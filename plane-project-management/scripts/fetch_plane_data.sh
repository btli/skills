#!/bin/bash
# Fetch Plane Data Script
# Fetches all projects and issues from Plane workspace using API key auth
#
# Prerequisites:
#   - ~/.claude/.env with PLANE_API_URL, PLANE_API_KEY
#   - PLANE_WORKSPACE env var or -w flag
#
# Usage:
#   ./fetch_plane_data.sh -w WORKSPACE
#   PLANE_WORKSPACE=your-workspace ./fetch_plane_data.sh
#
# Output:
#   - /tmp/plane_projects.json - All projects in workspace
#   - /tmp/plane_all_issues.json - All issues from all projects

# Parse -w flag
while getopts "w:" opt; do
    case $opt in
        w) export PLANE_WORKSPACE="$OPTARG" ;;
        *) ;;
    esac
done
shift $((OPTIND-1))

# Source the environment file
set -a
source ~/.claude/.env
set +a

# Check workspace is set
if [ -z "$PLANE_WORKSPACE" ]; then
    echo "Error: No workspace specified." >&2
    echo "Use: $0 -w WORKSPACE" >&2
    echo "  or: export PLANE_WORKSPACE=your-workspace" >&2
    exit 1
fi

echo "Fetching Plane projects..."
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/" > /tmp/plane_projects.json

echo "Fetching all issues..."
# Get all projects first
PROJECTS=$(cat /tmp/plane_projects.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
projects = data.get('results', [])
for p in projects:
    print(p['id'])
")

# Fetch issues for each project
> /tmp/plane_all_issues.json
echo "[" >> /tmp/plane_all_issues.json

first=true
for project_id in $PROJECTS; do
  if [ "$first" = false ]; then
    echo "," >> /tmp/plane_all_issues.json
  fi
  first=false

  curl -s -H "X-API-Key: $PLANE_API_KEY" \
    "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/$project_id/issues/" >> /tmp/plane_all_issues.json
done

echo "]" >> /tmp/plane_all_issues.json

echo "Done! Data saved to /tmp/plane_projects.json and /tmp/plane_all_issues.json"
