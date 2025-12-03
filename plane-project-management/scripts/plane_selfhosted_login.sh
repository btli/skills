#!/bin/bash
# Plane Self-Hosted Login Script
# Authenticates to a self-hosted Plane instance using session-based auth
#
# Prerequisites:
#   - ~/.claude/.env with PLANE_API_URL, PLANE_USERNAME, PLANE_PASSWORD
#
# Usage:
#   ./plane_selfhosted_login.sh
#
# After running, use the session cookie for API requests:
#   curl -b /tmp/plane_cookies.txt "$PLANE_API_URL/api/workspaces/$PLANE_WORKSPACE/projects/"

source ~/.claude/.env

# Remove old cookies
rm -f /tmp/plane_cookies.txt

# Step 1: Get CSRF token from response AND set cookie
CSRF_RESPONSE=$(curl -s -c /tmp/plane_cookies.txt "$PLANE_API_URL/auth/get-csrf-token/")
CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['csrf_token'])")
echo "CSRF Token: $CSRF_TOKEN"

# Step 2: Login with Origin and Referer headers (required by Django CSRF)
LOGIN_RESPONSE=$(curl -s -c /tmp/plane_cookies.txt -b /tmp/plane_cookies.txt \
  -X POST "$PLANE_API_URL/auth/sign-in/" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Origin: $PLANE_API_URL" \
  -H "Referer: $PLANE_API_URL/" \
  --data-urlencode "csrfmiddlewaretoken=$CSRF_TOKEN" \
  --data-urlencode "email=$PLANE_USERNAME" \
  --data-urlencode "password=$PLANE_PASSWORD")

# Check if login succeeded
if echo "$LOGIN_RESPONSE" | grep -q "CSRF"; then
  echo "Login failed - CSRF issue"
  echo "$LOGIN_RESPONSE" | head -5
  exit 1
elif [ -z "$LOGIN_RESPONSE" ]; then
  echo "Login successful (empty response = redirect)"
else
  echo "Login response: ${LOGIN_RESPONSE:0:200}"
fi

# Check for session cookie
echo ""
echo "Cookies:"
cat /tmp/plane_cookies.txt | grep -E "(session-id|csrftoken)"

echo ""
echo "You can now use the session cookie for API requests:"
echo "  curl -b /tmp/plane_cookies.txt \"\$PLANE_API_URL/api/workspaces/\$PLANE_WORKSPACE/projects/\""
