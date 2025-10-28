# Project Summary Action - Specification

**Version:** 1.0.0-draft
**Last Updated:** 2025-10-28

## Overview

A flexible GitHub Action that collects data from multiple sources (GitHub repositories, Slack channels), generates AI-powered project summaries using Claude Code, and posts results to multiple destinations (Slack, Notion).

## Core Features

### 1. Multi-Source Data Collection

#### GitHub Data Sources
- **Repositories:** Multiple repositories in a single run
- **Data Types:** Pull Requests and Issues
- **Cross-Organization:** Support via GitHub App tokens
- **Time Period:** Flexible date range specification

#### Slack Data Sources
- **Channels:** Multiple Slack channels in a single run
- **Data Types:**
  - Messages
  - Thread replies
  - Reactions
  - User participation metrics
- **Filtering:** Non-bot users only (exclude bot messages)
- **Time Period:** Shared with GitHub date range

### 2. Flexible Time Period Configuration

**Supported Formats:**
- Relative periods: `last-7-days`, `last-month`, `last-quarter`, `last-year`
- Absolute date ranges: `2024-01-01..2024-01-31`
- ISO week: `2024-W01`
- Custom: `start_date` and `end_date` parameters

**Default:** `last-month`

### 3. Template-Based Prompt System

**Preset Templates:**
1. `sprint-summary` - Two-week sprint retrospective
2. `monthly-report` - Monthly progress report
3. `release-notes` - Release-focused summary

**Template Structure:**
Each template includes:
- System prompt defining the analysis approach
- Output format specification
- Categorization logic
- Tone and style guidelines

**Customization Options:**
- `custom_instructions`: Additional instructions appended to template
- `language`: Output language (default: auto-detect from template)
- `tone`: `formal`, `casual`, `technical` (overrides template default)
- `categories`: Custom category definitions (extends template defaults)

**Template Location (Phase 1):**
- Built-in templates located in `project-summary/templates/`
- Documentation showing how to create custom templates
- Future: Support for custom template files via HTTPS URL

### 4. Multi-Destination Output

#### Slack Output
- **Format:** Slack mrkdwn (current proven format)
- **Formatting Rules:**
  - Bold: `*text*`
  - Links: `<URL|text>`
  - Lists: `•` or `-`
  - Emojis for structure
- **Support:** Single channel per output configuration
- **Multiple Posts:** Can specify multiple Slack outputs with different channels

#### Notion Output
- **Phase 1:** New page in a database
- **Future Phases:** Append to existing page, standalone page
- **Formatting:** Notion-specific formatting (blocks, not mrkdwn)
  - Headings, callouts, toggle lists, tables
  - Optimized for Notion's rich content model
- **Implementation:** MCP Notion server (`@modelcontextprotocol/server-notion`) with Notion token

#### Output Independence
- **Partial Success Model:** Each output destination operates independently
- **Error Handling:** If Slack succeeds but Notion fails → workflow succeeds with warning
- **Status Reporting:** Clear indication of which outputs succeeded/failed
- **Configuration:** Outputs are statically configured via the `outputs` input parameter (no runtime conditions)

### 5. Integrated Reporting

**Data Combination:**
- GitHub and Slack data combined into single coherent report
- Cross-reference capability (e.g., "PR #123 discussed in #engineering channel")
- Unified timeline view of project activity

## Input Specification

```yaml
inputs:
  # Data Sources
  repositories:
    description: 'Comma-separated list of repositories (owner/repo format)'
    required: false
    example: 'org/repo1,org/repo2,otherorg/repo3'

  slack_channels:
    description: 'Comma-separated list of Slack channel IDs'
    required: false
    example: 'C1234567890,C0987654321'

  # Time Period
  period:
    description: 'Time period (last-7-days, last-month, last-quarter, YYYY-MM, YYYY-MM-DD..YYYY-MM-DD)'
    required: false
    default: 'last-month'

  start_date:
    description: 'Start date (YYYY-MM-DD) - alternative to period'
    required: false

  end_date:
    description: 'End date (YYYY-MM-DD) - alternative to period'
    required: false

  # Prompt Configuration
  template:
    description: 'Template name (sprint-summary, monthly-report, release-notes) or URL to custom template'
    required: false
    default: 'monthly-report'

  custom_instructions:
    description: 'Additional instructions to append to template'
    required: false

  language:
    description: 'Output language (en, ja, es, fr, etc.)'
    required: false

  tone:
    description: 'Output tone (formal, casual, technical)'
    required: false

  # Output Configuration
  outputs:
    description: 'Comma-separated list of outputs (slack, notion)'
    required: true
    example: 'slack,notion'

  # Slack Output Config
  slack_channel:
    description: 'Slack channel ID for posting results'
    required: false # required if outputs contains 'slack'

  slack_bot_token:
    description: 'Slack Bot Token'
    required: false # required if slack is data source or output

  slack_team_id:
    description: 'Slack Team ID'
    required: false # required if slack is data source or output

  # Notion Output Config
  notion_database_id:
    description: 'Notion database ID for creating new page'
    required: false # required if outputs contains 'notion'

  notion_token:
    description: 'Notion Integration Token'
    required: false # required if outputs contains 'notion'

  # Authentication
  github_token:
    description: 'GitHub Token (supports GitHub App tokens for cross-org access)'
    required: false
    default: ${{ github.token }}

  claude_code_oauth_token:
    description: 'Claude Code OAuth Token'
    required: false

  anthropic_api_key:
    description: 'Anthropic API Key'
    required: false

  # Execution Config
  timeout_minutes:
    description: 'Timeout in minutes for Claude Code execution'
    required: false
    default: '10'
```

## Technical Architecture

### Execution Flow

```
1. Input Validation
   ├─> Validate at least one data source specified
   ├─> Validate at least one output specified
   ├─> Validate required credentials for selected sources/outputs
   └─> Parse and validate time period

2. Data Collection Phase
   ├─> GitHub Data
   │   ├─> For each repository:
   │   │   ├─> Fetch PRs in date range
   │   │   └─> Fetch Issues in date range
   │   └─> Save as github_data.json
   │
   └─> Slack Data
       ├─> For each channel:
       │   ├─> Fetch messages in date range
       │   ├─> Filter out bot messages
       │   └─> Collect thread replies and reactions
       └─> Save as slack_data.json

3. Analysis Phase (Claude Code)
   ├─> Load template
   ├─> Apply customizations
   ├─> Read collected data files
   ├─> Generate unified summary
   └─> Prepare output-specific formats

4. Output Distribution Phase
   ├─> Slack Output (if enabled)
   │   ├─> Format as mrkdwn
   │   ├─> Post via MCP slack tool
   │   └─> Record success/failure
   │
   └─> Notion Output (if enabled)
       ├─> Format as Notion blocks
       ├─> Create page in database
       └─> Record success/failure

5. Result Reporting
   └─> Return status summary with all output results
```

### MCP Server Configuration

**Required MCP Servers:**
- `@modelcontextprotocol/server-slack` (if Slack is source or output)
- `@modelcontextprotocol/server-notion` (if Notion is output)

**Auto-Configuration:**
The action automatically configures MCP servers based on selected sources/outputs. Users only need to provide the required tokens/credentials as inputs. MCP configuration is constructed dynamically in the action.yml file.

### Data File Formats

**github_data.json:**
```json
{
  "repositories": [
    {
      "name": "owner/repo1",
      "pull_requests": [
        {
          "number": 123,
          "title": "Add feature X",
          "body": "Description...",
          "created_at": "2024-01-15T10:00:00Z",
          "merged_at": "2024-01-16T15:30:00Z",
          "author": "username",
          "labels": ["enhancement", "frontend"]
        }
      ],
      "issues": [
        {
          "number": 456,
          "title": "Bug in Y",
          "body": "Description...",
          "created_at": "2024-01-10T09:00:00Z",
          "closed_at": "2024-01-20T11:00:00Z",
          "author": "username",
          "labels": ["bug"]
        }
      ]
    }
  ],
  "period": {
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-01-31T23:59:59Z"
  }
}
```

**slack_data.json:**
```json
{
  "channels": [
    {
      "id": "C1234567890",
      "name": "engineering",
      "messages": [
        {
          "ts": "1705320000.123456",
          "user": "U1234567890",
          "text": "Message content...",
          "thread_ts": null,
          "reply_count": 3,
          "reactions": [
            {"name": "thumbsup", "count": 5}
          ]
        }
      ]
    }
  ],
  "period": {
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-01-31T23:59:59Z"
  }
}
```

## Templates

### Template Format

Templates are defined in `project-summary/templates/{name}.yml`:

```yaml
name: monthly-report
description: Monthly progress report for team updates
language: ja # default language
tone: casual # default tone

system_prompt: |
  You are an AI assistant generating monthly project reports.
  Analyze the provided GitHub and Slack data to create a comprehensive
  summary of project activities.

output_format: |
  {month}月もお疲れ様です！ プロジェクトサマリーです。

  *GitHub活動*
  合計{pr_count}のPRと{issue_count}のIssueが処理されました。

  *主な成果*
  • [カテゴリ1]
    - [具体的な内容] (関連PR/Issue)

  *Slack活動*
  {channel_count}チャンネルで{message_count}件のディスカッションがありました。

  *注目のトピック*
  • [トピック1]

  {closing_message}

categories:
  - name: "機能開発"
    keywords: ["feature", "add", "implement", "新機能"]
  - name: "バグ修正"
    keywords: ["bug", "fix", "修正"]
  - name: "テスト・品質"
    keywords: ["test", "quality", "refactor", "リファクタリング"]
  - name: "インフラ・運用"
    keywords: ["infra", "ci", "deploy", "インフラ"]

slack_format:
  enabled: true
  instructions: |
    Use Slack mrkdwn format:
    - Bold: *text*
    - Links: <URL|text>
    - Lists: • or -

notion_format:
  enabled: true
  instructions: |
    Use Notion blocks:
    - heading_2 for main sections
    - callout for highlights
    - bulleted_list_item for items
    - Add emojis to headings for visual appeal
```

### Provided Templates

1. **monthly-report.yml** - Casual monthly team update (Japanese)
2. **sprint-summary.yml** - Sprint retrospective (English)
3. **release-notes.yml** - Customer-facing release notes (English, formal)

## Limitations (Phase 1)

1. **Data Volume Limits:**
   - Maximum 500 PRs per repository
   - Maximum 500 Issues per repository
   - Maximum 1000 Slack messages per channel
   - If limits exceeded, action will warn and use most recent items

2. **Notion Output:**
   - Phase 1 only supports creating new page in database
   - Appending to existing pages: future phase
   - Standalone pages: future phase

3. **Template Customization:**
   - Phase 1 supports only built-in templates in `project-summary/templates/`
   - Custom template support (HTTPS URLs) planned for future phase

4. **Slack Channel Access:**
   - Bot must be member of all specified channels
   - Private channels require explicit bot invitation

5. **Data Privacy:**
   - Slack messages and GitHub data are sent to Claude (Anthropic) for analysis
   - Users are responsible for ensuring appropriate data handling compliance
   - Recommendation: Use dedicated project channels, avoid channels with sensitive/confidential discussions
   - See README for detailed privacy considerations

## Example Usage

### Basic Monthly Report

```yaml
- name: Generate monthly summary
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: myorg/backend,myorg/frontend
    slack_channels: C1234567890
    outputs: slack
    slack_channel: C1234567890
    slack_bot_token: ${{ secrets.SLACK_BOT_TOKEN }}
    slack_team_id: ${{ secrets.SLACK_TEAM_ID }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Sprint Summary with Custom Instructions

```yaml
- name: Generate sprint summary
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: myorg/api
    slack_channels: C1234567890,C0987654321
    period: last-14-days
    template: sprint-summary
    custom_instructions: |
      Focus on:
      - Velocity metrics
      - Blocked items
      - Technical debt addressed
    outputs: slack,notion
    slack_channel: C1234567890
    notion_database_id: ${{ secrets.NOTION_DB_ID }}
    slack_bot_token: ${{ secrets.SLACK_BOT_TOKEN }}
    slack_team_id: ${{ secrets.SLACK_TEAM_ID }}
    notion_token: ${{ secrets.NOTION_TOKEN }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Multi-Repository Release Notes

```yaml
- name: Generate release notes
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: myorg/backend,myorg/frontend,myorg/mobile
    start_date: 2024-01-01
    end_date: 2024-01-31
    template: release-notes
    language: en
    tone: formal
    outputs: notion
    notion_database_id: ${{ secrets.PUBLIC_CHANGELOG_DB }}
    notion_token: ${{ secrets.NOTION_TOKEN }}
    github_token: ${{ steps.app-token.outputs.token }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Design Decisions

All major design questions have been resolved:

1. ✅ **MCP Server Setup:** Auto-configure based on selected sources/outputs
2. ✅ **Notion Integration:** Use `@modelcontextprotocol/server-notion` with Notion token
3. ✅ **Template Discovery:** Phase 1 supports built-in templates only, custom HTTPS templates in future
4. ✅ **Data Privacy:** Document considerations in README, trust users to select appropriate channels

## Future Enhancements (Post-v1)

- Additional data sources: Jira, Linear, Discord
- Additional outputs: Email, GitHub Discussions, Confluence
- Advanced filtering: Include/exclude patterns for messages, PR labels
- Analytics: Trend analysis, velocity metrics, contributor insights
- Scheduling: Built-in scheduling without cron syntax
- Interactive summaries: Slack buttons to drill into specific sections
