#!/bin/bash
set -e

# load-template.sh
# Loads and processes template files with customizations

echo "::group::Loading template"

TEMPLATE_NAME="${INPUT_TEMPLATE:-monthly-report}"
TEMPLATE_DIR="$GITHUB_ACTION_PATH/templates"
TEMPLATE_FILE="$TEMPLATE_DIR/${TEMPLATE_NAME}.yml"

echo "Loading template: $TEMPLATE_NAME"

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "::error::Template not found: $TEMPLATE_FILE"
  echo "Available templates: monthly-report, sprint-summary, release-notes, weekly-check"
  exit 1
fi

echo "✓ Template file found: $TEMPLATE_FILE"

# Extract template fields
# system_prompt
if [[ -n "$INPUT_SYSTEM_PROMPT" ]]; then
  echo "Using custom system_prompt (overriding template)"
  SYSTEM_PROMPT="$INPUT_SYSTEM_PROMPT"
else
  echo "Extracting system_prompt from template"
  SYSTEM_PROMPT=$(awk '/^system_prompt:/ {flag=1; next} /^[a-z_]+:/ {flag=0} flag' "$TEMPLATE_FILE" | sed 's/^  //')
fi

# slack_output_format
if [[ -n "$INPUT_SLACK_OUTPUT_FORMAT" ]]; then
  echo "Using custom slack_output_format (overriding template)"
  SLACK_OUTPUT_FORMAT="$INPUT_SLACK_OUTPUT_FORMAT"
else
  echo "Extracting slack_output_format from template"
  SLACK_OUTPUT_FORMAT=$(awk '/^slack_output_format:/ {flag=1; next} /^[a-z_]+:/ {flag=0} flag' "$TEMPLATE_FILE" | sed 's/^  //')
fi

# notion_title_format
if [[ -n "$INPUT_NOTION_TITLE_FORMAT" ]]; then
  echo "Using custom notion_title_format (overriding template)"
  NOTION_TITLE_FORMAT="$INPUT_NOTION_TITLE_FORMAT"
else
  echo "Extracting notion_title_format from template"
  NOTION_TITLE_FORMAT=$(grep "^notion_title_format:" "$TEMPLATE_FILE" | cut -d':' -f2- | xargs)
  if [[ -z "$NOTION_TITLE_FORMAT" ]]; then
    NOTION_TITLE_FORMAT="Project Summary - {period}"
  fi
fi

# notion_output_format
if [[ -n "$INPUT_NOTION_OUTPUT_FORMAT" ]]; then
  echo "Using custom notion_output_format (overriding template)"
  NOTION_OUTPUT_FORMAT="$INPUT_NOTION_OUTPUT_FORMAT"
else
  echo "Extracting notion_output_format from template"
  NOTION_OUTPUT_FORMAT=$(awk '/^notion_output_format:/ {flag=1; next} /^[a-z_]+:/ {flag=0} flag' "$TEMPLATE_FILE" | sed 's/^  //')
fi

# Extract language
LANGUAGE=$(grep "^language:" "$TEMPLATE_FILE" | cut -d':' -f2 | xargs)
if [[ -n "$INPUT_LANGUAGE" ]]; then
  echo "Language override: $INPUT_LANGUAGE (template default: $LANGUAGE)"
  LANGUAGE="$INPUT_LANGUAGE"
else
  echo "Language: $LANGUAGE"
fi

# Extract tone
TONE=$(grep "^tone:" "$TEMPLATE_FILE" | cut -d':' -f2 | xargs)
if [[ -n "$INPUT_TONE" ]]; then
  echo "Tone override: $INPUT_TONE (template default: $TONE)"
  TONE="$INPUT_TONE"
else
  echo "Tone: $TONE"
fi

# Save processed values to output
echo "TEMPLATE_NAME=$TEMPLATE_NAME" >> "$GITHUB_OUTPUT"
echo "LANGUAGE=$LANGUAGE" >> "$GITHUB_OUTPUT"
echo "TONE=$TONE" >> "$GITHUB_OUTPUT"
echo "NOTION_TITLE_FORMAT=$NOTION_TITLE_FORMAT" >> "$GITHUB_OUTPUT"

# Save system_prompt to output (multiline)
{
  echo "SYSTEM_PROMPT<<EOF_SYSTEM_PROMPT"
  echo "$SYSTEM_PROMPT"
  echo "EOF_SYSTEM_PROMPT"
} >> "$GITHUB_OUTPUT"

# Save slack_output_format to output (multiline)
{
  echo "SLACK_OUTPUT_FORMAT<<EOF_SLACK_OUTPUT_FORMAT"
  echo "$SLACK_OUTPUT_FORMAT"
  echo "EOF_SLACK_OUTPUT_FORMAT"
} >> "$GITHUB_OUTPUT"

# Save notion_output_format to output (multiline)
{
  echo "NOTION_OUTPUT_FORMAT<<EOF_NOTION_OUTPUT_FORMAT"
  echo "$NOTION_OUTPUT_FORMAT"
  echo "EOF_NOTION_OUTPUT_FORMAT"
} >> "$GITHUB_OUTPUT"

# Save template file path for Claude Code to read
echo "TEMPLATE_FILE=$TEMPLATE_FILE" >> "$GITHUB_OUTPUT"

echo "✓ Template loaded successfully"
echo "  Template: $TEMPLATE_NAME"
echo "  Language: $LANGUAGE"
echo "  Tone: $TONE"
if [[ -n "$INPUT_SYSTEM_PROMPT" ]]; then
  echo "  System prompt: Custom (overridden)"
else
  echo "  System prompt: From template"
fi
if [[ -n "$INPUT_SLACK_OUTPUT_FORMAT" ]]; then
  echo "  Slack output format: Custom (overridden)"
else
  echo "  Slack output format: From template"
fi
echo "  Notion title format: $NOTION_TITLE_FORMAT"
if [[ -n "$INPUT_NOTION_OUTPUT_FORMAT" ]]; then
  echo "  Notion output format: Custom (overridden)"
else
  echo "  Notion output format: From template"
fi

echo "::endgroup::"
