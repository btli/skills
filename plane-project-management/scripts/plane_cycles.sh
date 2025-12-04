#!/bin/bash
# Plane Cycle (Sprint) Management Helper
#
# Usage:
#   ./plane_cycles.sh [-w WORKSPACE] list PROJECT          - List cycles in project
#   ./plane_cycles.sh [-w WORKSPACE] show PROJECT CYCLE    - Show cycle details
#   ./plane_cycles.sh [-w WORKSPACE] issues PROJECT CYCLE  - List issues in cycle
#   ./plane_cycles.sh [-w WORKSPACE] create PROJECT NAME START END [DESC] - Create cycle
#   ./plane_cycles.sh [-w WORKSPACE] add PROJECT CYCLE ISSUE1 [ISSUE2...] - Add issues to cycle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse -w flag before sourcing library
while getopts "w:" opt; do
    case $opt in
        w) export PLANE_WORKSPACE="$OPTARG" ;;
        *) ;;
    esac
done
shift $((OPTIND-1))

source "$SCRIPT_DIR/plane_lib.sh"

# Check workspace is set
if [ -z "$PLANE_WORKSPACE" ]; then
    echo "Error: No workspace specified." >&2
    echo "Use: $0 -w WORKSPACE <command>" >&2
    echo "  or: export PLANE_WORKSPACE=your-workspace" >&2
    exit 1
fi

# Initialize authentication
plane_init >/dev/null 2>&1

show_help() {
    echo "Plane Cycle (Sprint) Management"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list PROJECT                    - List all cycles in project"
    echo "  show PROJECT CYCLE_ID           - Show cycle details"
    echo "  issues PROJECT CYCLE_ID         - List issues in cycle"
    echo "  create PROJECT NAME START END   - Create new cycle"
    echo "  add PROJECT CYCLE_ID ISSUE_SEQ1 [ISSUE_SEQ2...] - Add issues to cycle"
    echo ""
    echo "Examples:"
    echo "  $0 list AI                      - List cycles in AI Agents"
    echo "  $0 create AI \"Sprint 4\" 2025-02-01 2025-02-14"
    echo "  $0 add AI <cycle-id> 5 6 7      - Add issues 5,6,7 to cycle"
}

cmd="$1"
shift

case "$cmd" in
    list)
        project="$1"
        if [ -z "$project" ]; then
            echo "Error: Project identifier required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Cycles in $project:"
        plane_list_cycles "$project_id"
        ;;

    show)
        project="$1"
        cycle_id="$2"
        if [ -z "$project" ] || [ -z "$cycle_id" ]; then
            echo "Error: Project and cycle ID required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        plane_get_cycle "$project_id" "$cycle_id" | python3 -m json.tool
        ;;

    issues)
        project="$1"
        cycle_id="$2"
        if [ -z "$project" ] || [ -z "$cycle_id" ]; then
            echo "Error: Project and cycle ID required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        echo "Issues in cycle:"
        plane_list_cycle_issues "$project_id" "$cycle_id"
        ;;

    create)
        project="$1"
        name="$2"
        start_date="$3"
        end_date="$4"
        description="${5:-}"

        if [ -z "$project" ] || [ -z "$name" ] || [ -z "$start_date" ] || [ -z "$end_date" ]; then
            echo "Error: Project, name, start date, and end date required" >&2
            echo "Usage: $0 create PROJECT NAME YYYY-MM-DD YYYY-MM-DD [DESCRIPTION]" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Creating cycle '$name' in $project..."
        result=$(plane_create_cycle "$project_id" "$name" "$start_date" "$end_date" "$description")
        cycle_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','?'))" 2>/dev/null)
        echo "Created cycle: $cycle_id"
        ;;

    add)
        project="$1"
        cycle_id="$2"
        shift 2

        if [ -z "$project" ] || [ -z "$cycle_id" ] || [ $# -eq 0 ]; then
            echo "Error: Project, cycle ID, and issue sequence IDs required" >&2
            echo "Usage: $0 add PROJECT CYCLE_ID SEQ_ID1 [SEQ_ID2...]" >&2
            exit 1
        fi

        project_id=$(plane_get_project_id "$project")

        # Convert sequence IDs to issue UUIDs
        issue_ids=()
        for seq_id in "$@"; do
            issue_id=$(plane_get_issue_by_sequence "$project_id" "$seq_id")
            if [ -n "$issue_id" ]; then
                issue_ids+=("$issue_id")
                echo "  Found $project-$seq_id: $issue_id"
            else
                echo "  Warning: Issue $project-$seq_id not found"
            fi
        done

        if [ ${#issue_ids[@]} -eq 0 ]; then
            echo "Error: No valid issues found" >&2
            exit 1
        fi

        echo "Adding ${#issue_ids[@]} issues to cycle..."
        plane_add_issues_to_cycle "$project_id" "$cycle_id" "${issue_ids[@]}"
        echo "Done"
        ;;

    help|--help|-h|"")
        show_help
        ;;

    *)
        echo "Unknown command: $cmd" >&2
        show_help
        exit 1
        ;;
esac
