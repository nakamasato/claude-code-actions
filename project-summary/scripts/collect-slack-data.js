#!/usr/bin/env node

/**
 * collect-slack-data.js
 * Collects messages, threads, and reactions from Slack channels
 */

import { WebClient } from '@slack/web-api';
import { writeFileSync } from 'fs';

// Configuration from environment variables
const SLACK_BOT_TOKEN = process.env.INPUT_SLACK_BOT_TOKEN || process.env.SLACK_BOT_TOKEN;
const SLACK_CHANNELS = process.env.INPUT_SLACK_CHANNELS || '';
const START_DATE = process.env.START_DATE;
const END_DATE = process.env.END_DATE;

const MAX_MESSAGES_PER_CHANNEL = 1000;

// Initialize Slack client
const client = new WebClient(SLACK_BOT_TOKEN);

/**
 * Convert date string to Unix timestamp
 */
function dateToTimestamp(dateString) {
  return Math.floor(new Date(dateString + 'T00:00:00Z').getTime() / 1000);
}

/**
 * Check if message is from a bot
 */
function isBotMessage(message) {
  return !!(message.bot_id || message.bot_profile || message.subtype === 'bot_message');
}

/**
 * Collect messages from a single channel
 */
async function collectChannelMessages(channelId, startTs, endTs) {
  console.log(`\nCollecting messages from channel: ${channelId}`);

  try {
    // Get channel info
    let channelName = channelId;
    try {
      const channelInfo = await client.conversations.info({ channel: channelId });
      channelName = channelInfo.channel.name || channelId;
      console.log(`  Channel name: ${channelName}`);
    } catch (error) {
      console.warn(`  Warning: Could not get channel info: ${error.message}`);
    }

    const messages = [];
    let cursor = undefined;
    let totalFetched = 0;

    // Fetch messages with pagination
    do {
      const result = await client.conversations.history({
        channel: channelId,
        oldest: startTs.toString(),
        latest: endTs.toString(),
        limit: 100,
        cursor: cursor,
      });

      if (result.messages && result.messages.length > 0) {
        // Filter out bot messages
        const userMessages = result.messages.filter(msg => !isBotMessage(msg));

        for (const message of userMessages) {
          // Fetch thread replies if message has replies
          if (message.reply_count && message.reply_count > 0) {
            try {
              const repliesResult = await client.conversations.replies({
                channel: channelId,
                ts: message.ts,
              });

              // Filter out bot replies
              const userReplies = repliesResult.messages
                .filter(msg => !isBotMessage(msg))
                .slice(1); // Skip the parent message

              message.replies = userReplies;
            } catch (error) {
              console.warn(`  Warning: Could not fetch replies for message ${message.ts}: ${error.message}`);
              message.replies = [];
            }
          }

          messages.push(message);
          totalFetched++;

          // Check limit
          if (totalFetched >= MAX_MESSAGES_PER_CHANNEL) {
            console.log(`  ⚠️  Reached limit of ${MAX_MESSAGES_PER_CHANNEL} messages`);
            break;
          }
        }
      }

      cursor = result.response_metadata?.next_cursor;

      // Break if we've reached the limit
      if (totalFetched >= MAX_MESSAGES_PER_CHANNEL) {
        break;
      }

    } while (cursor);

    console.log(`  ✓ Collected ${messages.length} messages (${totalFetched} total, bots filtered out)`);

    // Transform to spec format
    return {
      id: channelId,
      name: channelName,
      messages: messages.map(msg => ({
        ts: msg.ts,
        user: msg.user,
        text: msg.text || '',
        thread_ts: msg.thread_ts || null,
        reply_count: msg.reply_count || 0,
        replies: (msg.replies || []).map(reply => ({
          ts: reply.ts,
          user: reply.user,
          text: reply.text || '',
        })),
        reactions: (msg.reactions || []).map(reaction => ({
          name: reaction.name,
          count: reaction.count,
          users: reaction.users || [],
        })),
      })),
    };

  } catch (error) {
    console.error(`  ✗ Error collecting from channel ${channelId}: ${error.message}`);
    return {
      id: channelId,
      name: channelId,
      messages: [],
      error: error.message,
    };
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('========================================');
  console.log('Collecting Slack data');
  console.log('========================================');

  // Validate inputs
  if (!SLACK_BOT_TOKEN) {
    console.error('Error: SLACK_BOT_TOKEN is required');
    process.exit(1);
  }

  if (!SLACK_CHANNELS) {
    console.log('No Slack channels specified, skipping Slack data collection');
    process.exit(0);
  }

  if (!START_DATE || !END_DATE) {
    console.error('Error: START_DATE and END_DATE must be set');
    process.exit(1);
  }

  console.log(`Period: ${START_DATE} to ${END_DATE}`);

  // Parse channels
  const channels = SLACK_CHANNELS.split(',').map(ch => ch.trim()).filter(ch => ch);
  console.log(`Channels to process: ${channels.length}`);
  channels.forEach(ch => console.log(`  - ${ch}`));

  // Convert dates to timestamps
  const startTs = dateToTimestamp(START_DATE);
  const endTs = dateToTimestamp(END_DATE) + 86400; // Add one day to include end date

  // Collect from all channels
  const channelData = [];
  for (const channelId of channels) {
    const data = await collectChannelMessages(channelId, startTs, endTs);
    channelData.push(data);
  }

  // Build output JSON
  const output = {
    channels: channelData,
    period: {
      start: `${START_DATE}T00:00:00Z`,
      end: `${END_DATE}T23:59:59Z`,
    },
  };

  // Write to file
  const outputFile = 'slack_data.json';
  writeFileSync(outputFile, JSON.stringify(output, null, 2));

  // Calculate totals
  const totalMessages = channelData.reduce((sum, ch) => sum + ch.messages.length, 0);
  const totalReplies = channelData.reduce((sum, ch) =>
    sum + ch.messages.reduce((s, msg) => s + (msg.replies?.length || 0), 0), 0
  );

  console.log('\n========================================');
  console.log('✓ Slack data collection complete');
  console.log(`  Total messages: ${totalMessages}`);
  console.log(`  Total replies: ${totalReplies}`);
  console.log(`  Output file: ${outputFile}`);
  console.log('========================================');

  // Set GitHub Actions output
  if (process.env.GITHUB_OUTPUT) {
    const fs = require('fs');
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `slack-data-file=${outputFile}\n`);
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `total-messages=${totalMessages}\n`);
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `total-replies=${totalReplies}\n`);
  }
}

// Run main function
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
