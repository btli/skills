#!/bin/bash
# Plane Cache Manager
# Caches project, state, and member data to reduce API calls
#
# Cache files stored in /tmp/plane_cache/
# Cache expires after 1 hour (configurable)

CACHE_DIR="/tmp/plane_cache"
CACHE_TTL=3600  # seconds

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Load environment
if [ -f ~/.claude/.env ]; then
    set -a
    source ~/.claude/.env
    set +a
fi

cache_is_valid() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return 1
    fi
    local age=$(($(date +%s) - $(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)))
    [ "$age" -lt "$CACHE_TTL" ]
}

cache_projects() {
    local cache_file="$CACHE_DIR/projects.json"
    if ! cache_is_valid "$cache_file"; then
        curl -s -H "X-API-Key: $PLANE_API_KEY" \
            "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/" > "$cache_file"
    fi
    cat "$cache_file"
}

cache_states() {
    local project_id="$1"
    local cache_file="$CACHE_DIR/states_${project_id}.json"
    if ! cache_is_valid "$cache_file"; then
        curl -s -H "X-API-Key: $PLANE_API_KEY" \
            "$PLANE_API_URL/api/v1/workspaces/$PLANE_WORKSPACE/projects/$project_id/states/" > "$cache_file"
    fi
    cat "$cache_file"
}

cache_clear() {
    rm -rf "$CACHE_DIR"/*
    echo "Cache cleared"
}

# Build lookup table: writes a simple key=value file for fast lookups
build_lookup_table() {
    local cache_file="$CACHE_DIR/lookup.env"

    if cache_is_valid "$cache_file"; then
        return 0
    fi

    echo "# Plane Lookup Table - Generated $(date)" > "$cache_file"
    echo "" >> "$cache_file"

    # Projects
    echo "# Projects: IDENTIFIER=UUID" >> "$cache_file"
    cache_projects | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('results', []):
    print(f\"PROJECT_{p['identifier']}={p['id']}\")" >> "$cache_file"

    # States for each project
    echo "" >> "$cache_file"
    echo "# States: PROJECT_STATENAME=UUID" >> "$cache_file"

    cache_projects | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('results', []):
    print(p['id'], p['identifier'])" | while read project_id identifier; do
        cache_states "$project_id" | python3 -c "
import sys, json
data = json.load(sys.stdin)
identifier = '$identifier'
for s in data.get('results', []):
    name = s['name'].upper().replace(' ', '_')
    print(f\"STATE_{identifier}_{name}={s['id']}\"
    print(f\"STATE_{identifier}_{s['group'].upper()}={s['id']}\")" >> "$cache_file" 2>/dev/null
    done

    echo "Lookup table built: $cache_file"
}

# Fast lookup using cached table
lookup() {
    local key="$1"
    local cache_file="$CACHE_DIR/lookup.env"

    if [ ! -f "$cache_file" ]; then
        build_lookup_table >/dev/null 2>&1
    fi

    grep "^${key}=" "$cache_file" 2>/dev/null | cut -d= -f2
}

# Quick project ID lookup
project_id() {
    lookup "PROJECT_$1"
}

# Quick state ID lookup
state_id() {
    local project="$1"
    local state="$2"
    lookup "STATE_${project}_${state}"
}
