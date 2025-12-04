#!/bin/bash
# Plane Pages (Documentation) Management Helper
# Requires session-based authentication
#
# Usage:
#   ./plane_pages.sh [-w WORKSPACE] list PROJECT             - List pages in project
#   ./plane_pages.sh [-w WORKSPACE] show PROJECT PAGE_ID     - Show page details
#   ./plane_pages.sh [-w WORKSPACE] content PROJECT PAGE_ID  - Get page content (HTML)
#   ./plane_pages.sh [-w WORKSPACE] create PROJECT NAME [CONTENT] - Create page
#   ./plane_pages.sh [-w WORKSPACE] update PROJECT PAGE_ID CONTENT - Update page content
#   ./plane_pages.sh [-w WORKSPACE] from-file PROJECT FILE   - Create page from markdown file
#   ./plane_pages.sh [-w WORKSPACE] delete PROJECT PAGE_ID   - Delete page

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

# Initialize authentication (required for pages)
plane_init >/dev/null 2>&1

# Convert markdown to HTML (basic conversion)
md_to_html() {
    local md="$1"
    python3 << EOF
import sys
import re

md = '''$md'''

# Basic markdown to HTML conversion
html = md

# Headers
html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

# Bold and italic
html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
html = re.sub(r'\*(.+?)\*', r'<em>\1</em>', html)

# Code blocks
html = re.sub(r'\`\`\`(\w+)?\n(.*?)\`\`\`', r'<pre><code>\2</code></pre>', html, flags=re.DOTALL)
html = re.sub(r'\`(.+?)\`', r'<code>\1</code>', html)

# Lists
html = re.sub(r'^- (.+)$', r'<li>\1</li>', html, flags=re.MULTILINE)
html = re.sub(r'(<li>.*?</li>\n?)+', r'<ul>\g<0></ul>', html, flags=re.DOTALL)

# Paragraphs (lines not already tagged)
lines = html.split('\n')
result = []
for line in lines:
    if line.strip() and not line.strip().startswith('<'):
        result.append(f'<p>{line}</p>')
    else:
        result.append(line)
html = '\n'.join(result)

# Escape for JSON
html = html.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
print(html)
EOF
}

show_help() {
    echo "Plane Pages (Documentation) Management"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list PROJECT                    - List all pages in project"
    echo "  show PROJECT PAGE_ID            - Show page details (JSON)"
    echo "  content PROJECT PAGE_ID         - Get page content (HTML)"
    echo "  create PROJECT NAME [CONTENT]   - Create new page"
    echo "  update PROJECT PAGE_ID CONTENT  - Update page content"
    echo "  from-file PROJECT FILE          - Create page from markdown file"
    echo "  delete PROJECT PAGE_ID          - Delete a page"
    echo ""
    echo "Examples:"
    echo "  $0 list AI"
    echo "  $0 create AI \"API Documentation\" \"<h1>API</h1><p>Docs here</p>\""
    echo "  $0 from-file AI ./docs/README.md"
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
        echo "Pages in $project:"
        plane_list_pages "$project_id"
        ;;

    show)
        project="$1"
        page_id="$2"
        if [ -z "$project" ] || [ -z "$page_id" ]; then
            echo "Error: Project and page ID required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        plane_get_page "$project_id" "$page_id" | python3 -m json.tool
        ;;

    content)
        project="$1"
        page_id="$2"
        if [ -z "$project" ] || [ -z "$page_id" ]; then
            echo "Error: Project and page ID required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        plane_get_page_content "$project_id" "$page_id"
        ;;

    create)
        project="$1"
        name="$2"
        content="${3:-}"

        if [ -z "$project" ] || [ -z "$name" ]; then
            echo "Error: Project and name required" >&2
            echo "Usage: $0 create PROJECT \"PAGE NAME\" [HTML_CONTENT]" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi
        echo "Creating page '$name' in $project..."
        result=$(plane_create_page "$project_id" "$name" "$content")
        page_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','?'))" 2>/dev/null)
        echo "Created page: $page_id"
        ;;

    update)
        project="$1"
        page_id="$2"
        content="$3"

        if [ -z "$project" ] || [ -z "$page_id" ] || [ -z "$content" ]; then
            echo "Error: Project, page ID, and content required" >&2
            echo "Usage: $0 update PROJECT PAGE_ID \"HTML_CONTENT\"" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        echo "Updating page..."
        plane_update_page_content "$project_id" "$page_id" "$content"
        echo "Done"
        ;;

    from-file)
        project="$1"
        file="$2"

        if [ -z "$project" ] || [ -z "$file" ]; then
            echo "Error: Project and file path required" >&2
            echo "Usage: $0 from-file PROJECT /path/to/file.md" >&2
            exit 1
        fi

        if [ ! -f "$file" ]; then
            echo "Error: File not found: $file" >&2
            exit 1
        fi

        project_id=$(plane_get_project_id "$project")
        if [ -z "$project_id" ]; then
            echo "Error: Project '$project' not found" >&2
            exit 1
        fi

        # Get filename without extension for page name
        name=$(basename "$file" | sed 's/\.[^.]*$//')

        # Read and convert file
        content=$(cat "$file")
        html=$(md_to_html "$content")

        echo "Creating page '$name' from $file..."
        result=$(plane_create_page "$project_id" "$name" "$html")
        page_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','?'))" 2>/dev/null)
        echo "Created page: $page_id"
        ;;

    delete)
        project="$1"
        page_id="$2"
        if [ -z "$project" ] || [ -z "$page_id" ]; then
            echo "Error: Project and page ID required" >&2
            exit 1
        fi
        project_id=$(plane_get_project_id "$project")
        echo "Deleting page $page_id..."
        plane_delete_page "$project_id" "$page_id"
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
