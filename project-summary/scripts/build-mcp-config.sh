#!/bin/bash
set -e

# build-mcp-config.sh
# Dynamically builds MCP configuration based on selected sources and outputs

echo "::group::Building MCP configuration"

# Parse outputs
IFS=',' read -ra OUTPUTS_ARRAY <<< "$INPUT_OUTPUTS"

# Initialize MCP servers object
MCP_SERVERS="{}"

# Add Slack MCP server if Slack is source or output
if [[ -n "$INPUT_SLACK_CHANNELS" ]] || [[ " ${OUTPUTS_ARRAY[*]} " =~ " slack " ]]; then
  echo "Adding Slack MCP server..."

  MCP_SERVERS=$(jq -n \
    --arg bot_token "$INPUT_SLACK_BOT_TOKEN" \
    --arg team_id "$INPUT_SLACK_TEAM_ID" \
    '{
      "slack": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-slack"],
        "env": {
          "SLACK_BOT_TOKEN": $bot_token,
          "SLACK_TEAM_ID": $team_id
        }
      }
    }')

  echo "✓ Slack MCP server configured"
fi

# Add Notion MCP server if Notion is output
if [[ " ${OUTPUTS_ARRAY[*]} " =~ " notion " ]]; then
  echo "Adding Notion MCP server..."

  if [[ -n "$MCP_SERVERS" ]] && [[ "$MCP_SERVERS" != "{}" ]]; then
    # Merge with existing servers
    MCP_SERVERS=$(echo "$MCP_SERVERS" | jq \
      --arg notion_token "$INPUT_NOTION_TOKEN" \
      '. + {
        "notion": {
          "command": "npx",
          "args": ["-y", "@notionhq/notion-mcp-server"],
          "env": {
            "NOTION_API_KEY": $notion_token
          }
        }
      }')
  else
    MCP_SERVERS=$(jq -n \
      --arg notion_token "$INPUT_NOTION_TOKEN" \
      '{
        "notion": {
          "command": "npx",
          "args": ["-y", "@notionhq/notion-mcp-server"],
          "env": {
            "NOTION_API_KEY": $notion_token
          }
        }
      }')
  fi

  echo "✓ Notion MCP server configured"
fi

# Build full MCP config
MCP_CONFIG=$(jq -n \
  --argjson servers "$MCP_SERVERS" \
  '{
    "mcpServers": $servers
  }')

# Save to output
echo "mcp-config<<EOF" >> "$GITHUB_OUTPUT"
echo "$MCP_CONFIG" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"

# Also save to file for debugging
echo "$MCP_CONFIG" > mcp_config.json

echo "✓ MCP configuration built successfully"
echo "$MCP_CONFIG" | jq '.'

echo "::endgroup::"
