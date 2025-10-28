#!/bin/bash
set -e

# collect-github-data.sh
# Collects PRs and Issues from multiple GitHub repositories

echo "::group::Collecting GitHub data"

# Check if repositories are specified
if [[ -z "$INPUT_REPOSITORIES" ]]; then
  echo "No repositories specified, skipping GitHub data collection"
  echo "::endgroup::"
  exit 0
fi

# Get time period from parse-period step outputs
START_DATE="${START_DATE}"
END_DATE="${END_DATE}"

if [[ -z "$START_DATE" || -z "$END_DATE" ]]; then
  echo "::error::START_DATE and END_DATE must be set by parse-period step"
  exit 1
fi

echo "Collecting data for period: $START_DATE to $END_DATE"

# Parse comma-separated repository list
IFS=',' read -ra REPOS <<< "$INPUT_REPOSITORIES"

echo "Repositories to process: ${#REPOS[@]}"
for repo in "${REPOS[@]}"; do
  echo "  - $repo"
done

# Initialize JSON structure
cat > github_data.json <<EOF
{
  "repositories": [],
  "period": {
    "start": "${START_DATE}T00:00:00Z",
    "end": "${END_DATE}T23:59:59Z"
  }
}
EOF

# Temporary directory for individual repo data
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Process each repository
for repo in "${REPOS[@]}"; do
  # Trim whitespace
  repo=$(echo "$repo" | xargs)

  echo ""
  echo "=========================================="
  echo "Processing repository: $repo"
  echo "=========================================="

  # Fetch PRs
  echo "Fetching PRs..."
  PR_COUNT=0
  if gh search prs \
    --repo "$repo" \
    --merged \
    --merged-at "${START_DATE}..${END_DATE}" \
    --json number,title,body,createdAt,mergedAt,author,labels \
    --limit 500 > "$TMP_DIR/${repo//\//_}_prs.json" 2>/dev/null; then

    PR_COUNT=$(jq 'length' "$TMP_DIR/${repo//\//_}_prs.json")
    echo "✓ Found $PR_COUNT PRs"

    if [[ $PR_COUNT -ge 500 ]]; then
      echo "::warning::Repository $repo has 500+ PRs. Only the most recent 500 will be included."
    fi
  else
    echo "::warning::Failed to fetch PRs for $repo (may not exist or no access)"
    echo "[]" > "$TMP_DIR/${repo//\//_}_prs.json"
  fi

  # Fetch Issues
  echo "Fetching Issues..."
  ISSUE_COUNT=0
  if gh search issues \
    --repo "$repo" \
    --closed \
    --closed-at "${START_DATE}..${END_DATE}" \
    --json number,title,body,createdAt,closedAt,author,labels \
    --limit 500 > "$TMP_DIR/${repo//\//_}_issues.json" 2>/dev/null; then

    ISSUE_COUNT=$(jq 'length' "$TMP_DIR/${repo//\//_}_issues.json")
    echo "✓ Found $ISSUE_COUNT Issues"

    if [[ $ISSUE_COUNT -ge 500 ]]; then
      echo "::warning::Repository $repo has 500+ Issues. Only the most recent 500 will be included."
    fi
  else
    echo "::warning::Failed to fetch Issues for $repo (may not exist or no access)"
    echo "[]" > "$TMP_DIR/${repo//\//_}_issues.json"
  fi

  # Transform data to match spec format
  jq -n \
    --arg repo "$repo" \
    --argjson prs "$(cat "$TMP_DIR/${repo//\//_}_prs.json")" \
    --argjson issues "$(cat "$TMP_DIR/${repo//\//_}_issues.json")" \
    '{
      name: $repo,
      pull_requests: ($prs | map({
        number: .number,
        title: .title,
        body: .body,
        created_at: .createdAt,
        merged_at: .mergedAt,
        author: .author.login,
        labels: [.labels[].name]
      })),
      issues: ($issues | map({
        number: .number,
        title: .title,
        body: .body,
        created_at: .createdAt,
        closed_at: .closedAt,
        author: .author.login,
        labels: [.labels[].name]
      }))
    }' > "$TMP_DIR/${repo//\//_}_combined.json"

  echo "Repository $repo: $PR_COUNT PRs, $ISSUE_COUNT Issues"
done

# Combine all repository data into final JSON
echo ""
echo "=========================================="
echo "Combining data from all repositories..."
echo "=========================================="

# Build repositories array
REPO_JSONS=""
for repo in "${REPOS[@]}"; do
  repo=$(echo "$repo" | xargs)
  if [[ -f "$TMP_DIR/${repo//\//_}_combined.json" ]]; then
    if [[ -z "$REPO_JSONS" ]]; then
      REPO_JSONS=$(cat "$TMP_DIR/${repo//\//_}_combined.json")
    else
      REPO_JSONS="$REPO_JSONS,$(cat "$TMP_DIR/${repo//\//_}_combined.json")"
    fi
  fi
done

# Update github_data.json with all repositories
jq \
  --argjson repos "[$REPO_JSONS]" \
  '.repositories = $repos' \
  github_data.json > github_data_tmp.json && mv github_data_tmp.json github_data.json

# Calculate totals
TOTAL_PRS=$(jq '[.repositories[].pull_requests | length] | add' github_data.json)
TOTAL_ISSUES=$(jq '[.repositories[].issues | length] | add' github_data.json)

echo "✓ GitHub data collection complete"
echo "  Total PRs: $TOTAL_PRS"
echo "  Total Issues: $TOTAL_ISSUES"
echo "  Output file: github_data.json"

# Set output for next steps
echo "github-data-file=github_data.json" >> "$GITHUB_OUTPUT"
echo "total-prs=$TOTAL_PRS" >> "$GITHUB_OUTPUT"
echo "total-issues=$TOTAL_ISSUES" >> "$GITHUB_OUTPUT"

# Display sample of collected data
echo ""
echo "Sample of collected data:"
jq '.repositories[] | {name, pr_count: (.pull_requests | length), issue_count: (.issues | length)}' github_data.json

echo "::endgroup::"
