#!/bin/bash
set -e

# build-prompt.sh
# Builds comprehensive prompt for Claude Code based on template and data

echo "::group::Building Claude Code prompt"

# Get template information
TEMPLATE_FILE="${TEMPLATE_FILE}"
TEMPLATE_NAME="${TEMPLATE_NAME}"
LANGUAGE="${LANGUAGE}"
TONE="${TONE}"
SYSTEM_PROMPT="${SYSTEM_PROMPT}"
SLACK_OUTPUT_FORMAT="${SLACK_OUTPUT_FORMAT:-}"
NOTION_TITLE_FORMAT="${NOTION_TITLE_FORMAT:-Project Summary - {period}}"
NOTION_OUTPUT_FORMAT="${NOTION_OUTPUT_FORMAT:-}"

# Get data file paths
GITHUB_DATA_FILE="${GITHUB_DATA_FILE:-}"
SLACK_DATA_FILE="${SLACK_DATA_FILE:-}"

# Get period information
PERIOD_DESCRIPTION="${PERIOD_DESCRIPTION}"
START_DATE="${START_DATE}"
END_DATE="${END_DATE}"

# Get outputs
IFS=',' read -ra OUTPUTS_ARRAY <<< "$INPUT_OUTPUTS"

echo "Building prompt for template: $TEMPLATE_NAME"
echo "Language: $LANGUAGE, Tone: $TONE"
echo "Data files: GitHub=${GITHUB_DATA_FILE:-none}, Slack=${SLACK_DATA_FILE:-none}"
echo "Outputs: ${INPUT_OUTPUTS}"

# Build the prompt
cat > claude_prompt.md <<'PROMPT_START'
# Project Summary Generation Task

You are tasked with generating a comprehensive project summary based on the provided data and template.

## Template Information

PROMPT_START

# Add template information
cat >> claude_prompt.md <<EOF
- **Template**: $TEMPLATE_NAME
- **Language**: $LANGUAGE
- **Tone**: $TONE

## System Prompt

$SYSTEM_PROMPT

EOF

# Add data sources section
cat >> claude_prompt.md <<'EOF'
## Data Sources

EOF

if [[ -n "$GITHUB_DATA_FILE" ]]; then
  cat >> claude_prompt.md <<EOF
### GitHub Data

**File**: \`$GITHUB_DATA_FILE\`

This file contains PRs and Issues from the specified repositories for the period $START_DATE to $END_DATE.

Please read this file and analyze:
- PR titles and descriptions
- Issue titles and descriptions
- Labels and metadata
- Authors and timestamps

Use the Read tool to load this data.

EOF
fi

if [[ -n "$SLACK_DATA_FILE" ]]; then
  cat >> claude_prompt.md <<EOF
### Slack Data

**File**: \`$SLACK_DATA_FILE\`

This file contains messages, threads, and reactions from Slack channels for the period $START_DATE to $END_DATE.

Please read this file and analyze:
- Message content and context
- Thread discussions
- Reactions and engagement
- Key topics and decisions

Use the Read tool to load this data.

EOF
fi

# Add processing instructions
cat >> claude_prompt.md <<'EOF'
## Processing Steps

1. **Load Data**: Use the Read tool to load all available data files (GitHub and/or Slack)

2. **Analyze Content**:
   - Categorize PRs and Issues according to template categories
   - Identify key themes and topics from Slack discussions
   - Extract important metrics (counts, participation, etc.)
   - Cross-reference GitHub activity with Slack discussions if both are available

3. **Generate Summary**:
   - Follow the output format specified above
   - Apply the specified language and tone
   - Include relevant links and references
   - Keep the content clear, concise, and actionable

4. **Format for Outputs**: Prepare formatted versions for each output destination

EOF

# Add output instructions
cat >> claude_prompt.md <<'EOF'
## Output Destinations

EOF

for output in "${OUTPUTS_ARRAY[@]}"; do
  output=$(echo "$output" | xargs) # trim whitespace

  if [[ "$output" == "slack" ]]; then
    cat >> claude_prompt.md <<EOF
### Slack Output

**Channel**: $INPUT_NOTIFICATION_SLACK_CHANNEL

**Action Required**: Post the summary to Slack using the MCP tool \`mcp__slack__slack_post_message\`

**Output Format**:

$SLACK_OUTPUT_FORMAT

**Important**: Follow the format structure and requirements specified above. Use Slack mrkdwn format with proper formatting for links, bold text, and emojis.

EOF
  fi

  if [[ "$output" == "notion" ]]; then
    # Check if title format contains variables (format mode) or is a direct title
    if [[ "$NOTION_TITLE_FORMAT" == *"{"* ]]; then
      # Format mode: LLM should generate title based on format and data
      cat >> claude_prompt.md <<EOF
### Notion Output

**Database ID**: $INPUT_NOTION_DATABASE_ID

**Page Title Format**: $NOTION_TITLE_FORMAT

**Available Data for Title Generation**:
- period: $PERIOD_DESCRIPTION
- start_date: $START_DATE
- end_date: $END_DATE
- template: $TEMPLATE_NAME

**Instructions**: Generate the page title based on the format pattern above and the available data. Interpret the format pattern and replace any variables (like {period}, {start_date}, {year_month}, etc.) or follow natural language instructions to create an appropriate title.

**Action Required**: Create a new page in the Notion database using the MCP tool \`mcp__notion__API-post-page\`

**Output Format**:

$NOTION_OUTPUT_FORMAT

**Important**: Follow the format structure and requirements specified above. Use appropriate Notion blocks (heading_2, heading_3, bulleted_list_item, callout, paragraph) with proper markdown formatting.

EOF
    else
      # Direct mode: use title as-is
      cat >> claude_prompt.md <<EOF
### Notion Output

**Database ID**: $INPUT_NOTION_DATABASE_ID
**Page Title**: $NOTION_TITLE_FORMAT

**Action Required**: Create a new page in the Notion database using the MCP tool \`mcp__notion__API-post-page\`

**Output Format**:

$NOTION_OUTPUT_FORMAT

**Important**: Follow the format structure and requirements specified above. Use appropriate Notion blocks (heading_2, heading_3, bulleted_list_item, callout, paragraph) with proper markdown formatting.

EOF
    fi
  fi
done

# Add final instructions
cat >> claude_prompt.md <<EOF
## Important Notes

- **Period**: $PERIOD_DESCRIPTION ($START_DATE to $END_DATE)
- **Be thorough**: Read all data files completely before generating summary
- **Handle empty data**: If a data source has no items, acknowledge this gracefully
- **Cross-reference**: If both GitHub and Slack data are available, look for connections
- **Error handling**: If posting to an output fails, report the error but continue with other outputs
- **Verification**: After posting, verify the output was successful

## Success Criteria

- All data files have been read and analyzed
- Summary generated according to template specifications
- Successfully posted to all specified output destinations
- Content is clear, accurate, and actionable

Good luck! 🚀
EOF

# Save prompt content to GitHub output using heredoc
{
  echo "prompt<<PROMPT_EOF"
  cat claude_prompt.md
  echo "PROMPT_EOF"
} >> "$GITHUB_OUTPUT"

# Also save file path
echo "prompt-file=claude_prompt.md" >> "$GITHUB_OUTPUT"

echo "✓ Claude Code prompt built successfully"
echo "  Prompt file: claude_prompt.md"
echo "  Lines: $(wc -l < claude_prompt.md)"

# Display prompt preview
echo ""
echo "Prompt preview (first 30 lines):"
head -30 claude_prompt.md

echo "::endgroup::"
