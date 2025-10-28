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
  echo "Available templates: monthly-report, sprint-summary, release-notes"
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

# output_format
if [[ -n "$INPUT_OUTPUT_FORMAT" ]]; then
  echo "Using custom output_format (overriding template)"
  OUTPUT_FORMAT="$INPUT_OUTPUT_FORMAT"
else
  echo "Extracting output_format from template"
  OUTPUT_FORMAT=$(awk '/^output_format:/ {flag=1; next} /^[a-z_]+:/ {flag=0} flag' "$TEMPLATE_FILE" | sed 's/^  //')
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

# Save system_prompt to output (multiline)
{
  echo "SYSTEM_PROMPT<<EOF_SYSTEM_PROMPT"
  echo "$SYSTEM_PROMPT"
  echo "EOF_SYSTEM_PROMPT"
} >> "$GITHUB_OUTPUT"

# Save output_format to output (multiline)
{
  echo "OUTPUT_FORMAT<<EOF_OUTPUT_FORMAT"
  echo "$OUTPUT_FORMAT"
  echo "EOF_OUTPUT_FORMAT"
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
if [[ -n "$INPUT_OUTPUT_FORMAT" ]]; then
  echo "  Output format: Custom (overridden)"
else
  echo "  Output format: From template"
fi

echo "::endgroup::"
