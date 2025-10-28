#!/bin/bash
# Test GitHub search manually

REPO="${1:-nakamasato/claude-code-actions}"
START_DATE="${2:-2025-09-01}"
END_DATE="${3:-2025-09-30}"

echo "Testing GitHub search for: $REPO"
echo "Date range: $START_DATE to $END_DATE"
echo ""

echo "=== Testing PR search (with repo: in query) ==="
gh search prs repo:${REPO} is:pr is:merged merged:${START_DATE}..${END_DATE} --json number,title,closedAt --limit 10
echo ""

echo "=== Testing Issue search ==="
gh search issues repo:${REPO} is:issue is:closed closed:${START_DATE}..${END_DATE} --json number,title,closedAt --limit 10
echo ""

echo "=== Testing alternative: gh pr list ==="
gh pr list --repo "$REPO" --state merged --limit 10 --json number,title,closedAt,createdAt 2>/dev/null | jq --arg start "$START_DATE" --arg end "$END_DATE" '[.[] | select(.closedAt >= $start and .closedAt <= ($end + "T23:59:59Z"))]'
echo ""

echo "=== Checking repo access ==="
gh api repos/${REPO} --jq '{name: .name, full_name: .full_name, private: .private}' --paginate=false 2>&1 || echo "Cannot access repository"
echo ""

echo "=== List recent merged PRs (last 10) ==="
gh pr list --repo "$REPO" --state merged --limit 10 --json number,title,closedAt 2>/dev/null
