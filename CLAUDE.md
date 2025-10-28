# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains custom GitHub Actions for automated project workflows, focusing on AI-powered project summaries using Claude Code.

## Architecture

### Project Summary Action

Located in `project-summary/`, this is a composite GitHub Action that generates AI-powered project summaries from multiple data sources:

1. **Data Collection Phase**:
   - **GitHub Data**: Uses GitHub CLI (`gh search prs`, `gh search issues`) to fetch PRs and issues from multiple repositories
   - **Slack Data**: Uses MCP Slack tool to fetch messages, threads, and reactions from multiple channels
   - Supports cross-repository/cross-organization access via GitHub App tokens
   - Generates JSON files with collected data

2. **Analysis Phase**:
   - Invokes `anthropics/claude-code-action` with:
     - Template-based or custom system prompts
     - MCP configuration for Slack and Notion integrations
     - Allowed tools for data processing and output
   - Claude Code analyzes collected data and generates summaries based on templates:
     - `monthly-report`: Japanese casual monthly updates
     - `sprint-summary`: English professional sprint retrospectives
     - `release-notes`: English formal customer-facing notes
     - `weekly-check`: Japanese professional progress tracking

3. **Output Phase**:
   - **Slack**: Posts formatted summary using MCP Slack tool (`mcp__slack__slack_post_message`)
   - **Notion**: Creates page in database using MCP Notion tool
   - Supports multiple output destinations simultaneously

### Key Design Patterns

- **Multi-Source Data Collection**: Combines GitHub and Slack data for comprehensive context
- **Template System**: Pre-built templates with customization options via `system_prompt` and `output_format` overrides
- **Multi-Destination Output**: Flexible output to Slack and/or Notion
- **Cross-Organization Support**: GitHub App tokens for accessing repositories across organizations
- **Flexible Time Periods**: Supports `last-7-days`, `last-month`, `last-quarter`, `YYYY-MM`, and custom date ranges
- **MCP Integration**: Demonstrates integration between Claude Code and external services (Slack, Notion) via MCP

## Development Commands

### Testing the Action Locally

Since this is a composite action without code to build/test locally, testing requires:

1. Create a test workflow in `.github/workflows/` that calls the action
2. Push to GitHub and run via Actions UI or:
   ```bash
   gh workflow run <workflow-name>
   ```

### Validating Action Definition

```bash
# Check YAML syntax
yamllint project-summary/action.yml
```

### Viewing Data Collection Format

To understand the JSON structure for data collection:

**GitHub PRs**:
```bash
gh search prs --repo owner/repo --merged --merged-at 2024-01-01..2024-02-01 --json title,body,number --limit 100
```

**GitHub Issues**:
```bash
gh search issues --repo owner/repo --created 2024-01-01..2024-02-01 --json title,body,number,state --limit 100
```

## Important Implementation Details

### Template System

Templates are defined in `project-summary/templates/` and contain:
- `system_prompt`: Base instructions for Claude Code
- `output_format`: Structure for the generated summary
- `language`: Default language (en/ja)
- `tone`: Communication style (formal/casual/technical)

Users can override `system_prompt` and/or `output_format` via action inputs for customization.

### Date Period Parsing

The action supports flexible date period specifications:
- Relative: `last-7-days`, `last-month`, `last-quarter`
- Month: `YYYY-MM` (e.g., `2024-01`)
- Custom range: `YYYY-MM-DD..YYYY-MM-DD`
- Explicit: `start_date` and `end_date` inputs

Date calculations are handled in bash scripts with proper timezone handling (UTC).

### Multi-Source Data Collection

**GitHub**: Limited to 500 PRs and 500 issues per repository to prevent excessive API usage.

**Slack**: Limited to 1000 messages per channel. Bot messages are automatically filtered out to focus on human communications.

### Output Format Requirements

**Slack**: Messages must follow Slack mrkdwn conventions:
- Bold: `*text*`
- Links: `<URL|text>`
- Lists: `•` or `-`
- Code blocks: triple backticks

**Notion**: Uses Notion's block API with markdown-style formatting.

### Authentication Considerations

**Claude Code**: Requires either `claude_code_oauth_token` or `anthropic_api_key`.

**GitHub**: Can use `GITHUB_TOKEN` (same repo) or GitHub App token (cross-org/cross-repo).

**Slack**: Requires `slack_bot_token` and `slack_team_id` for MCP integration.

**Notion**: Requires `notion_token` with appropriate database permissions.

## Releasing New Versions

This action is tagged and released for external use. Users reference via:
- `nakamasato/claude-code-actions/project-summary@v1`
- Or specific version: `nakamasato/claude-code-actions/project-summary@v1.x.x`

When making changes:
1. Update version in README examples if needed
2. Create and push new git tag
3. Update release notes with changelog
4. Test with workflow runs before promoting to users
