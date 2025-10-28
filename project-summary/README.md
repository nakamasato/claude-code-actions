# Project Summary Action

AI-powered project summaries from multiple data sources (GitHub, Slack), posted to multiple destinations (Slack, Notion).

## Features

- **Multi-Source Data Collection**
  - GitHub: PRs and Issues from multiple repositories
  - Slack: Messages, threads, reactions from multiple channels
- **Flexible Time Periods**: `last-7-days`, `last-month`, `last-quarter`, `YYYY-MM`, custom date ranges
- **Template-Based Summaries**: Pre-built templates (monthly-report, sprint-summary, release-notes)
- **Multi-Destination Output**: Post to Slack and/or Notion
- **Cross-Organization Support**: GitHub App tokens for accessing repositories across organizations

## Inputs

### Data Sources

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `repositories` | No | - | Comma-separated repositories (`owner/repo,owner/repo2`) |
| `slack_channels` | No | - | Comma-separated Slack channel IDs (`C123,C456`) |

### Time Period

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `period` | No | `last-month` | Time period: `last-7-days`, `last-month`, `last-quarter`, `YYYY-MM`, `YYYY-MM-DD..YYYY-MM-DD` |
| `start_date` | No | - | Start date (`YYYY-MM-DD`) - alternative to `period` |
| `end_date` | No | - | End date (`YYYY-MM-DD`) - required with `start_date` |

### Prompt Configuration

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `template` | No | `monthly-report` | Template: `monthly-report`, `sprint-summary`, `release-notes` |
| `custom_instructions` | No | - | Additional instructions for the AI |
| `language` | No | - | Output language (`en`, `ja`, etc.) |
| `tone` | No | - | Tone: `formal`, `casual`, `technical` |

### Output Configuration

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `outputs` | **Yes** | - | Outputs: `slack`, `notion`, or `slack,notion` |
| `slack_channel` | No* | - | Slack channel ID for posting |
| `slack_bot_token` | No* | - | Slack Bot Token |
| `slack_team_id` | No* | - | Slack Team ID |
| `notion_database_id` | No* | - | Notion database ID |
| `notion_token` | No* | - | Notion Integration Token |

*Required based on selected outputs and sources

### Authentication

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github_token` | No | `${{ github.token }}` | GitHub Token (supports GitHub App tokens) |
| `anthropic_api_key` | No* | - | Anthropic API Key |
| `claude_code_oauth_token` | No* | - | Claude Code OAuth Token |
| `timeout_minutes` | No | `10` | Claude Code execution timeout |

*Either `anthropic_api_key` or `claude_code_oauth_token` required

## Outputs

| Output | Description |
|--------|-------------|
| `github-data-file` | Path to collected GitHub data JSON |
| `slack-data-file` | Path to collected Slack data JSON |
| `total-prs` | Total number of PRs collected |
| `total-issues` | Total number of Issues collected |

## Example Usage

### Basic Monthly Report

```yaml
- name: Generate monthly summary
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: myorg/backend,myorg/frontend
    outputs: slack
    slack_channel: C1234567890
    slack_bot_token: ${{ secrets.SLACK_BOT_TOKEN }}
    slack_team_id: ${{ secrets.SLACK_TEAM_ID }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Sprint Summary with Slack Data

```yaml
- name: Generate sprint summary
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: myorg/api
    slack_channels: C1234567890,C0987654321
    period: last-14-days
    template: sprint-summary
    outputs: slack,notion
    slack_channel: C1234567890
    notion_database_id: ${{ secrets.NOTION_DB_ID }}
    slack_bot_token: ${{ secrets.SLACK_BOT_TOKEN }}
    slack_team_id: ${{ secrets.SLACK_TEAM_ID }}
    notion_token: ${{ secrets.NOTION_TOKEN }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Cross-Organization with GitHub App

```yaml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.APP_ID }}
    private-key: ${{ secrets.PRIVATE_KEY }}
    owner: target-org

- name: Generate release notes
  uses: nakamasato/claude-code-actions/project-summary@v1
  with:
    repositories: target-org/repo1,target-org/repo2
    start_date: 2024-01-01
    end_date: 2024-01-31
    template: release-notes
    outputs: notion
    notion_database_id: ${{ secrets.NOTION_DB_ID }}
    notion_token: ${{ secrets.NOTION_TOKEN }}
    github_token: ${{ steps.app-token.outputs.token }}
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Scheduled Monthly Report

```yaml
name: Monthly Project Summary
on:
  schedule:
    - cron: '0 9 1 * *'  # 1st day of month at 9:00 UTC
  workflow_dispatch:

jobs:
  summary:
    runs-on: ubuntu-latest
    steps:
      - name: Generate monthly summary
        uses: nakamasato/claude-code-actions/project-summary@v1
        with:
          repositories: ${{ github.repository }}
          slack_channels: C1234567890
          outputs: slack
          slack_channel: C1234567890
          slack_bot_token: ${{ secrets.SLACK_BOT_TOKEN }}
          slack_team_id: ${{ secrets.SLACK_TEAM_ID }}
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Templates

### monthly-report (Default)
- **Language**: Japanese
- **Tone**: Casual
- **Use Case**: Regular team updates, monthly progress reports

### sprint-summary
- **Language**: English
- **Tone**: Professional
- **Use Case**: Sprint retrospectives, two-week summaries

### release-notes
- **Language**: English
- **Tone**: Formal
- **Use Case**: Customer-facing release notes, changelogs

## Setup Requirements

### Slack Bot
1. Create Slack App at https://api.slack.com/apps
2. Add bot scopes: `channels:history`, `channels:read`, `chat:write`
3. Install app to workspace
4. Invite bot to channels: `/invite @YourBot`
5. Get Bot Token and Team ID

### Notion Integration
1. Create integration at https://www.notion.so/my-integrations
2. Share target database with integration
3. Get Integration Token and Database ID

### GitHub App (Optional, for Cross-Org)
1. Create GitHub App with permissions: `Contents: Read`, `Pull requests: Read`
2. Install app to target organizations
3. Use `actions/create-github-app-token` to generate token

## Limitations

- Maximum 500 PRs per repository
- Maximum 500 Issues per repository
- Maximum 1000 Slack messages per channel
- Bot messages automatically filtered from Slack data
- Templates are built-in only (custom templates: future enhancement)

## Privacy Considerations

GitHub and Slack data are sent to Claude (Anthropic) for AI-powered analysis. Ensure:
- Use appropriate channels (avoid sensitive/confidential data)
- Review your organization's data handling policies
- Bot has access only to necessary channels/repositories

## License

MIT
