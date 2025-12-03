#!/bin/bash
# Fetch Plane Data Script
# Fetches all projects and issues from Plane workspace using API key auth
#
# Prerequisites:
#   - ~/.claude/.env with PLANE_API_URL, PLANE_API_KEY, PLANE_WORKSPACE
#
# Usage:
#   ./fetch_plane_data.sh
#
# Output:
#   - /tmp/plane_projects.json - All projects in workspace
#   - /tmp/plane_all_issues.json - All issues from all projects

# Source the environment file
set -a
source ~/.claude/.env
set +a

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
