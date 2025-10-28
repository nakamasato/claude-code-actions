#!/bin/bash
# Test GitHub search manually

REPO="${1:-nakamasato/claude-code-actions}"
START_DATE="${2:-2025-09-01}"
END_DATE="${3:-2025-09-30}"

echo "Testing GitHub search for: $REPO"
echo "Date range: $START_DATE to $END_DATE"
echo ""

echo "=== Testing PR search ==="
gh search prs --repo "$REPO" "is:pr is:merged merged:${START_DATE}..${END_DATE}" --json number,title,mergedAt --limit 10
echo ""

echo "=== Testing Issue search ==="
gh search issues --repo "$REPO" "is:issue is:closed closed:${START_DATE}..${END_DATE}" --json number,title,closedAt --limit 10
echo ""

echo "=== Testing alternative: gh pr list ==="
gh pr list --repo "$REPO" --state merged --search "merged:${START_DATE}..${END_DATE}" --json number,title,mergedAt --limit 10
