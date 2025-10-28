# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains custom GitHub Actions, specifically focused on generating automated monthly project summaries using Claude Code and posting them to Slack via MCP (Model Context Protocol).

## Architecture

### Monthly Project Summary Slack Action

Located in `monthly-project-summary-slack/`, this is a composite GitHub Action that:

1. **Data Collection Phase** (`action.yml:62-89`):
   - Uses GitHub CLI (`gh search prs`) to fetch merged PRs for a specified month
   - Supports cross-repository access via GitHub App tokens
   - Generates JSON file with PR data (title, body, number)

2. **Analysis Phase** (`action.yml:91-195`):
   - Invokes `anthropics/claude-code-action` with:
     - System prompt for Japanese monthly report generation
     - MCP configuration for Slack integration
     - Allowed tools: Bash, Grep, Glob, Read, Write, Edit, MultiEdit, LS, Task, TodoRead, TodoWrite, mcp__slack__slack_post_message
   - Claude Code reads PR data and generates categorized summary in Japanese
   - Output format uses Slack mrkdwn with PR links formatted as `<https://github.com/owner/repo/pull/123|#123>`

3. **Posting Phase** (`action.yml:91-195`):
   - Uses Slack MCP tool (`mcp__slack__slack_post_message`) to post formatted summary
   - Fallback error notification via Slack API if workflow fails (`action.yml:196-207`)

### Key Design Patterns

- **Cross-Repository Support**: Uses GitHub App tokens to access PRs from repositories in different organizations
- **Matrix Strategy Compatible**: Can be used with GitHub Actions matrix strategy to process multiple repositories in parallel
- **Bilingual Documentation**: README in Japanese, action metadata in English
- **MCP Integration**: Demonstrates integration between Claude Code and external services (Slack) via MCP

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
yamllint monthly-project-summary-slack/action.yml
```

### Viewing PR Data Format

To understand the JSON structure the action expects:
```bash
gh search prs --repo owner/repo --merged --merged-at 2024-01-01..2024-02-01 --json title,body,number --limit 100
```

## Important Implementation Details

### Date Calculation Logic

The action calculates date ranges for PR searches using bash date arithmetic (`action.yml:68-83`):
- If month is 12, rolls over to next year
- Uses `printf "%02d"` for zero-padding months
- macOS vs Linux date command differences may affect local testing

### Slack Message Format Requirements

Messages must follow specific Slack mrkdwn conventions (`action.yml:165-195`):
- Bold: `*text*`
- Links: `<URL|text>`
- Lists: `•` or `-`
- Emojis for visual structure

### Authentication Considerations

The action supports two authentication methods for Claude Code:
1. `claude_code_oauth_token` - OAuth token from Claude
2. `anthropic_api_key` - Direct API key

One of these must be provided. GitHub token can be either `GITHUB_TOKEN` (same repo) or GitHub App token (cross-repo).

## Releasing New Versions

This action is tagged and released for external use. Version references in README:
- Current version: `1.13.1`
- Users reference via: `nakamasato/github-actions/monthly-project-summary-slack@1.13.1`

When making changes:
1. Update version in README examples
2. Create and push new git tag
3. Update release notes with changelog
