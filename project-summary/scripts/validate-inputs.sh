#!/bin/bash
set -e

# validate-inputs.sh
# Validates input parameters for project-summary action

echo "::group::Validating inputs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0

# Function to print error
print_error() {
  echo -e "${RED}ERROR: $1${NC}"
  ((error_count++))
}

# Function to print warning
print_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to print success
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Validate at least one data source is specified
if [[ -z "$INPUT_GITHUB_REPOSITORIES" && -z "$INPUT_SLACK_CHANNELS" ]]; then
  print_error "At least one data source must be specified: 'github_repositories' or 'slack_channels'"
fi

# Validate at least one output is specified
if [[ -z "$INPUT_OUTPUTS" ]]; then
  print_error "The 'outputs' parameter is required (e.g., 'slack', 'notion', or 'slack,notion')"
else
  print_success "Output destinations: $INPUT_OUTPUTS"
fi

# Parse outputs into array
IFS=',' read -ra OUTPUTS_ARRAY <<< "$INPUT_OUTPUTS"

# Validate Slack output requirements
if [[ " ${OUTPUTS_ARRAY[*]} " =~ " slack " ]]; then
  echo "Validating Slack output configuration..."

  if [[ -z "$INPUT_NOTIFICATION_SLACK_CHANNEL" ]]; then
    print_error "Slack output requires 'notification_slack_channel' parameter"
  fi

  if [[ -z "$INPUT_SLACK_BOT_TOKEN" ]]; then
    print_error "Slack output requires 'slack_bot_token' parameter"
  fi

  if [[ -z "$INPUT_SLACK_TEAM_ID" ]]; then
    print_error "Slack output requires 'slack_team_id' parameter"
  fi

  if [[ -n "$INPUT_NOTIFICATION_SLACK_CHANNEL" && -n "$INPUT_SLACK_BOT_TOKEN" && -n "$INPUT_SLACK_TEAM_ID" ]]; then
    print_success "Slack output configuration valid"
  fi
fi

# Validate Notion output requirements
if [[ " ${OUTPUTS_ARRAY[*]} " =~ " notion " ]]; then
  echo "Validating Notion output configuration..."

  if [[ -z "$INPUT_NOTION_DATABASE_ID" ]]; then
    print_error "Notion output requires 'notion_database_id' parameter"
  fi

  if [[ -z "$INPUT_NOTION_TOKEN" ]]; then
    print_error "Notion output requires 'notion_token' parameter"
  fi

  if [[ -n "$INPUT_NOTION_DATABASE_ID" && -n "$INPUT_NOTION_TOKEN" ]]; then
    print_success "Notion output configuration valid"
  fi
fi

# Validate Slack source requirements (if used as data source)
if [[ -n "$INPUT_SLACK_CHANNELS" ]]; then
  echo "Validating Slack data source configuration..."

  if [[ -z "$INPUT_SLACK_BOT_TOKEN" ]]; then
    print_error "Slack data source requires 'slack_bot_token' parameter"
  fi

  if [[ -z "$INPUT_SLACK_TEAM_ID" ]]; then
    print_error "Slack data source requires 'slack_team_id' parameter"
  fi

  if [[ -n "$INPUT_SLACK_BOT_TOKEN" && -n "$INPUT_SLACK_TEAM_ID" ]]; then
    print_success "Slack data source configuration valid"
  fi
fi

# Validate Claude Code authentication (one method required)
if [[ -z "$INPUT_ANTHROPIC_API_KEY" && -z "$INPUT_CLAUDE_CODE_OAUTH_TOKEN" ]]; then
  print_error "Either 'anthropic_api_key' or 'claude_code_oauth_token' must be provided"
else
  print_success "Claude Code authentication configured"
fi

# Validate period vs start_date/end_date
if [[ -n "$INPUT_PERIOD" && (-n "$INPUT_START_DATE" || -n "$INPUT_END_DATE") ]]; then
  print_warning "Both 'period' and 'start_date/end_date' specified. 'start_date/end_date' will take precedence."
fi

if [[ -n "$INPUT_START_DATE" && -z "$INPUT_END_DATE" ]]; then
  print_error "'end_date' must be specified when 'start_date' is provided"
fi

if [[ -z "$INPUT_START_DATE" && -n "$INPUT_END_DATE" ]]; then
  print_error "'start_date' must be specified when 'end_date' is provided"
fi

# Validate template
if [[ -n "$INPUT_TEMPLATE" ]]; then
  valid_templates=("monthly-report" "sprint-summary" "release-notes" "weekly-check")
  if [[ ! " ${valid_templates[*]} " =~ " ${INPUT_TEMPLATE} " ]]; then
    print_error "Invalid template: '$INPUT_TEMPLATE'. Valid options: ${valid_templates[*]}"
  else
    print_success "Template: $INPUT_TEMPLATE"
  fi
fi

# Validate tone
if [[ -n "$INPUT_TONE" ]]; then
  valid_tones=("formal" "casual" "technical")
  if [[ ! " ${valid_tones[*]} " =~ " ${INPUT_TONE} " ]]; then
    print_error "Invalid tone: '$INPUT_TONE'. Valid options: ${valid_tones[*]}"
  fi
fi

# Summary
echo ""
echo "=========================================="
if [[ $error_count -eq 0 ]]; then
  print_success "Input validation passed!"
  echo "=========================================="
  echo "::endgroup::"
  exit 0
else
  print_error "Input validation failed with $error_count error(s)"
  echo "=========================================="
  echo "::endgroup::"
  exit 1
fi
