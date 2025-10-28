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

# Extract template fields using basic parsing (yq would be better, but keeping dependencies minimal)
# For now, we'll just verify the file exists and can be read
# The actual template content will be processed by Claude Code

# Read template content
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# Extract system prompt
SYSTEM_PROMPT=$(awk '/^system_prompt:/ {flag=1; next} /^[a-z_]+:/ {flag=0} flag' "$TEMPLATE_FILE" | sed 's/^  //')

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

# Save template file path for Claude Code to read
echo "TEMPLATE_FILE=$TEMPLATE_FILE" >> "$GITHUB_OUTPUT"

# Create a summary file for Claude Code with template guidance
cat > template_guidance.md <<EOF
# Template: $TEMPLATE_NAME

## Language
$LANGUAGE

## Tone
$TONE

## Custom Instructions
${INPUT_CUSTOM_INSTRUCTIONS:-None}

## Template File
The full template definition is available at: $TEMPLATE_FILE

Please read this file to understand:
- System prompt and guidelines
- Output format structure
- Category definitions
- Slack formatting instructions
- Notion formatting instructions

Apply any custom instructions while maintaining the template's core structure.
EOF

echo "template-guidance-file=template_guidance.md" >> "$GITHUB_OUTPUT"

echo "✓ Template loaded successfully"
echo "  Template: $TEMPLATE_NAME"
echo "  Language: $LANGUAGE"
echo "  Tone: $TONE"
echo "  Custom instructions: ${INPUT_CUSTOM_INSTRUCTIONS:-(none)}"

echo "::endgroup::"
