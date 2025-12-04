#!/bin/bash
# Plane Task Management Helper
# Quick access to task status and updates
#
# Usage:
#   ./plane_tasks.sh list [PROJECT_IDENTIFIER]     - List all tasks
#   ./plane_tasks.sh todo [PROJECT_IDENTIFIER]     - List To Do tasks
#   ./plane_tasks.sh doing [PROJECT_IDENTIFIER]    - List In Progress tasks
#   ./plane_tasks.sh done [PROJECT_IDENTIFIER]     - List Completed tasks
#   ./plane_tasks.sh backlog [PROJECT_IDENTIFIER]  - List Backlog tasks
#   ./plane_tasks.sh start PROJECT SEQ_ID          - Move task to In Progress
#   ./plane_tasks.sh complete PROJECT SEQ_ID       - Move task to Done
#   ./plane_tasks.sh create PROJECT "NAME" [DESC]  - Create new task

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plane_lib.sh"

# Initialize authentication
plane_init >/dev/null 2>&1

show_help() {
    echo "Plane Task Management"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list [PROJECT]        - List all tasks in project"
    echo "  todo [PROJECT]        - List To Do tasks (unstarted)"
    echo "  doing [PROJECT]       - List In Progress tasks (started)"
    echo "  done [PROJECT]        - List Completed tasks"
    echo "  backlog [PROJECT]     - List Backlog tasks"
    echo "  start PROJECT SEQ_ID  - Move task to In Progress"
    echo "  complete PROJECT SEQ_ID - Move task to Done"
    echo "  create PROJECT NAME [DESC] - Create new task"
    echo "  projects              - List all projects"
    echo ""
    echo "Examples:"
    echo "  $0 todo AI            - List To Do tasks in AI Agents project"
    echo "  $0 start AI 5         - Move task AI-5 to In Progress"
    echo "  $0 complete AI 5      - Move task AI-5 to Done"
}

cmd="$1"
shift

case "$cmd" in
    list)
        project="${1:-}"
        if [ -z "$project" ]; then
            echo "Projects:"
            plane_list_projects
        else
            project_id=$(plane_get_project_id "$project")
            if [ -z "$project_id" ]; then
                echo "Error: Project '$project' not found" >&2
                exit 1
            fi
            echo "All tasks in $project:"
            plane_list_issues "$project_id"
        fi
        ;;

    todo)
        project="${1:-}"
        if [ -z "$project" ]; then
            echo "Error: Project identifier required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "To Do tasks in $project:"
        plane_list_todo_issues "$project_id"
        ;;

    doing|inprogress)
        project="${1:-}"
        if [ -z "$project" ]; then
            echo "Error: Project identifier required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "In Progress tasks in $project:"
        plane_list_in_progress_issues "$project_id"
        ;;

    done)
        project="${1:-}"
        if [ -z "$project" ]; then
            echo "Error: Project identifier required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Completed tasks in $project:"
        plane_list_issues_by_state "$project_id" "completed"
        ;;

    backlog)
        project="${1:-}"
        if [ -z "$project" ]; then
            echo "Error: Project identifier required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Backlog tasks in $project:"
        plane_list_backlog_issues "$project_id"
        ;;

    start)
        project="$1"
        seq_id="$2"
        if [ -z "$project" ] || [ -z "$seq_id" ]; then
            echo "Error: Project and sequence ID required" >&2
            echo "Usage: $0 start PROJECT SEQ_ID" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        issue_id=$(plane_get_issue_by_sequence "$project_id" "$seq_id")
        if [ -z "$issue_id" ]; then
            echo "Error: Issue $project-$seq_id not found" >&2
            exit 1
        fi
        echo "Moving $project-$seq_id to In Progress..."
        plane_move_issue_to_in_progress "$project_id" "$issue_id"
        echo "Done"
        ;;

    complete|finish)
        project="$1"
        seq_id="$2"
        if [ -z "$project" ] || [ -z "$seq_id" ]; then
            echo "Error: Project and sequence ID required" >&2
            echo "Usage: $0 complete PROJECT SEQ_ID" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        issue_id=$(plane_get_issue_by_sequence "$project_id" "$seq_id")
        if [ -z "$issue_id" ]; then
            echo "Error: Issue $project-$seq_id not found" >&2
            exit 1
        fi
        echo "Moving $project-$seq_id to Done..."
        plane_move_issue_to_done "$project_id" "$issue_id"
        echo "Done"
        ;;

    create)
        project="$1"
        name="$2"
        desc="${3:-}"
        if [ -z "$project" ] || [ -z "$name" ]; then
            echo "Error: Project and name required" >&2
            echo "Usage: $0 create PROJECT \"TASK NAME\" [DESCRIPTION]" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Creating task in $project..."
        result=$(plane_create_issue "$project_id" "$name" "$desc")
        seq_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sequence_id','?'))" 2>/dev/null)
        echo "Created: $project-$seq_id: $name"
        ;;

    projects)
        echo "Available projects:"
        plane_list_projects
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
