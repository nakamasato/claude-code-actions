# Project Summary Action - Implementation Plan

**Version:** 1.0.0
**Created:** 2025-10-28
**Status:** Planning Phase

## Overview

This document outlines the implementation plan for the `project-summary` action, breaking down development into manageable phases with clear deliverables and success criteria.

## File Structure

```
project-summary/
├── action.yml                          # Main composite action definition
├── README.md                           # User-facing documentation
├── spec.md                             # Technical specification (existing)
├── implementation-plan.md              # This file
├── templates/
│   ├── monthly-report.yml              # Default template (Japanese)
│   ├── sprint-summary.yml              # Sprint retrospective (English)
│   └── release-notes.yml               # Release notes (English, formal)
├── scripts/
│   ├── collect-github-data.sh          # GitHub data collection
│   ├── collect-slack-data.sh           # Slack data collection (via MCP)
│   ├── validate-inputs.sh              # Input validation
│   └── parse-period.sh                 # Date period parsing
└── examples/
    ├── basic-monthly.yml               # Example workflow: basic usage
    ├── sprint-multi-repo.yml           # Example workflow: sprint with multiple repos
    └── release-notes.yml               # Example workflow: release notes
```

## Development Phases

### Phase 0: Prerequisites & Setup ✓ COMPLETED
- [x] Create spec.md with feature requirements
- [x] Finalize design decisions
- [x] Create implementation-plan.md

### Phase 1: Foundation (Week 1)

**Goal:** Basic infrastructure and input validation

#### Tasks
1. **Create action.yml skeleton** (4 hours)
   - Define all inputs with descriptions and defaults
   - Set up basic composite action structure
   - Add branding configuration

2. **Input validation script** (3 hours)
   - Create `scripts/validate-inputs.sh`
   - Validate required inputs based on selected sources/outputs
   - Check: At least one source, at least one output
   - Check: Required credentials present for selected sources/outputs
   - Return clear error messages

3. **Period parsing script** (4 hours)
   - Create `scripts/parse-period.sh`
   - Support formats: `last-N-days`, `last-month`, `last-quarter`, `YYYY-MM`, `YYYY-MM-DD..YYYY-MM-DD`
   - Handle `start_date` + `end_date` alternative
   - Output: ISO 8601 start and end timestamps
   - Handle edge cases: leap years, month boundaries, timezone (UTC)

4. **Project structure setup** (2 hours)
   - Create all directories
   - Add placeholder files
   - Set up .gitignore if needed

**Deliverables:**
- `action.yml` with complete input definitions
- `scripts/validate-inputs.sh` with comprehensive validation
- `scripts/parse-period.sh` with date parsing logic
- All directories created

**Success Criteria:**
- Action can be referenced (even if not functional)
- Input validation catches invalid configurations
- Period parsing handles all specified formats correctly

---

### Phase 2: GitHub Data Collection (Week 1-2)

**Goal:** Collect PRs and Issues from multiple repositories

#### Tasks
1. **GitHub data collection script** (6 hours)
   - Create `scripts/collect-github-data.sh`
   - Parse comma-separated repository list
   - For each repository:
     - Use `gh search prs` for PRs in date range
     - Use `gh search issues` for Issues in date range
     - Apply 500 item limits per repo
   - Combine into single `github_data.json` matching spec format
   - Handle errors gracefully (repo not found, no access, etc.)

2. **GitHub auth handling** (2 hours)
   - Support `github_token` input (default: `${{ github.token }}`)
   - Support GitHub App tokens for cross-org access
   - Test with GITHUB_TOKEN env var

3. **Add GitHub data step to action.yml** (2 hours)
   - Conditional execution (only if repositories specified)
   - Call collection script with proper env vars
   - Save output file path to step output

4. **Testing** (3 hours)
   - Create test workflow in `.github/workflows/test-github-data.yml`
   - Test single repo
   - Test multiple repos (same org)
   - Test cross-org with GitHub App token
   - Verify JSON output format

**Deliverables:**
- `scripts/collect-github-data.sh` functional script
- GitHub data collection integrated into action.yml
- Test workflow for GitHub data collection

**Success Criteria:**
- Can collect PRs and Issues from single repository
- Can collect from multiple repositories in one run
- Output JSON matches spec format
- Proper error handling for missing repos/access denied

---

### Phase 3: Slack Data Collection (Week 2)

**Goal:** Collect messages from Slack channels via MCP

#### Tasks
1. **Slack data collection script** (8 hours)
   - Create `scripts/collect-slack-data.sh`
   - Use MCP Slack server to read channel history
   - Parse comma-separated channel list
   - For each channel:
     - Fetch messages in date range
     - Filter out bot messages (check `bot_id` field)
     - Fetch thread replies for threaded messages
     - Collect reactions
   - Apply 1000 message limit per channel
   - Combine into single `slack_data.json` matching spec format
   - Handle errors (channel not found, bot not member, etc.)

2. **Slack auth handling** (2 hours)
   - Set up SLACK_BOT_TOKEN and SLACK_TEAM_ID env vars
   - Verify bot has required permissions

3. **Add Slack data step to action.yml** (2 hours)
   - Conditional execution (only if slack_channels specified)
   - Call collection script
   - Save output file path to step output

4. **Testing** (4 hours)
   - Create test workflow in `.github/workflows/test-slack-data.yml`
   - Test single channel
   - Test multiple channels
   - Verify message filtering (bot exclusion)
   - Verify thread replies and reactions captured
   - Verify JSON output format

**Deliverables:**
- `scripts/collect-slack-data.sh` functional script
- Slack data collection integrated into action.yml
- Test workflow for Slack data collection

**Success Criteria:**
- Can collect messages from single Slack channel
- Can collect from multiple channels in one run
- Bot messages properly filtered out
- Thread replies and reactions included
- Output JSON matches spec format

**Note:** This phase may require creating a custom Node.js script if bash scripting with MCP proves difficult. Alternative: small Node.js script that uses MCP client library.

---

### Phase 4: Template System (Week 2-3)

**Goal:** Create template structure and loading mechanism

#### Tasks
1. **Template file format design** (3 hours)
   - Finalize YAML structure (already defined in spec)
   - Document template variables
   - Create template schema validation

2. **Create default templates** (6 hours)
   - `templates/monthly-report.yml`
     - Japanese language
     - Casual tone
     - Categories: 機能開発, バグ修正, テスト・品質, インフラ・運用
     - Slack and Notion format instructions
   - `templates/sprint-summary.yml`
     - English language
     - Professional tone
     - Categories: Completed, In Progress, Blocked, Technical Debt
   - `templates/release-notes.yml`
     - English language
     - Formal, customer-facing tone
     - Categories: New Features, Improvements, Bug Fixes, Breaking Changes

3. **Template loading logic** (4 hours)
   - Add step to action.yml to load template
   - Validate template exists
   - Parse YAML and extract components
   - Apply customizations (custom_instructions, language, tone overrides)
   - Generate final prompt for Claude Code

4. **Testing** (3 hours)
   - Test each template loads correctly
   - Test customization options
   - Test invalid template name handling

**Deliverables:**
- Three functional templates
- Template loading logic in action.yml
- Template documentation in README

**Success Criteria:**
- All three templates load and parse correctly
- Customization options properly override template defaults
- Clear error messages for invalid templates

---

### Phase 5: Claude Code Integration (Week 3)

**Goal:** Integrate Claude Code with MCP for analysis and output

#### Tasks
1. **Build MCP configuration dynamically** (4 hours)
   - Create step that constructs MCP JSON config
   - Include Slack MCP server (if Slack source or output)
   - Include Notion MCP server (if Notion output)
   - Pass required env vars (tokens) to each MCP server

2. **Construct Claude Code prompt** (6 hours)
   - Combine template system prompt with data file paths
   - Include output format instructions
   - Include Slack-specific formatting rules
   - Include Notion-specific formatting rules
   - Add instructions for reading data files
   - Add instructions for posting to specified outputs
   - Handle large datasets (guidance on sampling if >500 items)

3. **Add Claude Code step to action.yml** (4 hours)
   - Call `anthropics/claude-code-action@v1.0.14`
   - Pass all parameters:
     - github_token
     - anthropic_api_key or claude_code_oauth_token
     - claude_args with system prompt and allowed tools
     - mcp-config with dynamic configuration
     - prompt with full instructions
   - Set timeout from input parameter

4. **Testing** (4 hours)
   - Test with GitHub data only → Slack output
   - Test with Slack data only → Slack output
   - Test with both sources → Slack output
   - Test with Notion output
   - Verify Claude Code reads data correctly
   - Verify outputs are generated correctly

**Deliverables:**
- MCP configuration builder
- Claude Code integration in action.yml
- Full prompt generation logic

**Success Criteria:**
- Claude Code successfully invoked with correct config
- Can read GitHub and Slack data files
- Generates summaries based on template
- Posts to Slack successfully
- Posts to Notion successfully

**Allowed Tools for Claude Code:**
```
Bash,Grep,Glob,Read,Write,Edit,MultiEdit,LS,Task,TodoRead,TodoWrite,mcp__slack__slack_post_message,mcp__notion__API-post-page,mcp__notion__API-patch-block-children
```

---

### Phase 6: Output Handling (Week 3-4)

**Goal:** Implement independent output destinations with error handling

#### Tasks
1. **Slack output verification** (3 hours)
   - Already handled by Claude Code MCP tool
   - Add verification that message was posted
   - Capture Slack message URL/timestamp
   - Add to action outputs

2. **Notion output implementation** (6 hours)
   - Verify `@modelcontextprotocol/server-notion` MCP server
   - Test Notion page creation in database
   - Verify Notion-specific formatting (blocks)
   - Handle Notion API errors gracefully

3. **Independent output error handling** (4 hours)
   - Wrap each output in try-catch equivalent
   - Record success/failure for each output
   - Continue execution if one output fails
   - Generate summary status report

4. **Fallback error notifications** (3 hours)
   - If entire workflow fails, send error notification
   - Add step with `if: failure()` condition
   - Post to Slack via curl (like current action)
   - Include run URL and error details

5. **Testing** (4 hours)
   - Test Slack success + Notion success
   - Test Slack success + Notion failure (partial success)
   - Test Slack failure + Notion success (partial success)
   - Test complete failure (fallback notification)

**Deliverables:**
- Independent output handling
- Error notification system
- Output status reporting

**Success Criteria:**
- Partial success scenarios work correctly (some outputs succeed)
- Clear status reporting for each output
- Fallback notification on complete failure
- Action doesn't fail if one output fails

---

### Phase 7: Documentation & Examples (Week 4)

**Goal:** Create comprehensive documentation for users

#### Tasks
1. **README.md creation** (6 hours)
   - Overview and features
   - Quick start guide
   - Input parameter reference (table format)
   - Output destinations
   - Template selection guide
   - Authentication setup:
     - GitHub token vs GitHub App
     - Slack bot setup and permissions
     - Notion integration setup
   - Data privacy considerations
   - Troubleshooting guide

2. **Example workflows** (4 hours)
   - `examples/basic-monthly.yml` - Simple monthly report
   - `examples/sprint-multi-repo.yml` - Sprint with multiple repos and Slack
   - `examples/release-notes.yml` - Release notes to Notion
   - Add inline comments explaining each parameter

3. **Template customization guide** (3 hours)
   - Document template YAML structure
   - Explain each template field
   - Provide examples of customizations
   - Show how to use custom_instructions effectively

4. **Migration guide** (2 hours)
   - Document how to migrate from `monthly-project-summary-slack`
   - Show equivalent configurations
   - Highlight new features available

**Deliverables:**
- Comprehensive README.md
- Three example workflows
- Template customization documentation
- Migration guide

**Success Criteria:**
- Users can set up action from README alone
- All inputs clearly documented
- Examples cover common use cases
- Template customization is clear

---

### Phase 8: Testing & Validation (Week 4-5)

**Goal:** Comprehensive testing across all features

#### Tasks
1. **Integration tests** (8 hours)
   - Create test workflows for each major scenario
   - Test all template combinations
   - Test all source combinations (GitHub only, Slack only, both)
   - Test all output combinations
   - Test error scenarios
   - Test with different time periods
   - Test with multiple repositories
   - Test with GitHub App tokens

2. **Edge case testing** (4 hours)
   - Empty data sets (no PRs in period)
   - Very large data sets (500+ items)
   - Invalid date ranges
   - Missing credentials
   - Bot not in Slack channel
   - Repository access denied
   - Notion database not found

3. **Performance testing** (3 hours)
   - Measure execution time for different data volumes
   - Test timeout handling
   - Verify data limits enforced

4. **Documentation validation** (2 hours)
   - Test all example workflows
   - Verify README instructions are accurate
   - Fix any discovered issues

**Deliverables:**
- Full test suite in `.github/workflows/`
- Test results documented
- Bug fixes from testing

**Success Criteria:**
- All major scenarios tested and working
- Edge cases handled gracefully
- Documentation matches actual behavior
- No critical bugs

---

### Phase 9: Release Preparation (Week 5)

**Goal:** Prepare for public release

#### Tasks
1. **Version tagging strategy** (2 hours)
   - Decide on initial version (v1.0.0)
   - Document versioning approach
   - Set up release process

2. **Update CLAUDE.md** (2 hours)
   - Add architecture details for project-summary
   - Document key implementation patterns
   - Update with development commands

3. **Create release notes** (2 hours)
   - Document all features
   - Include breaking changes (N/A for v1)
   - Add examples
   - List known limitations

4. **Final review** (3 hours)
   - Code review
   - Documentation review
   - Test coverage review
   - Security review (token handling)

5. **Create release** (1 hour)
   - Tag v1.0.0
   - Create GitHub release
   - Publish release notes

**Deliverables:**
- v1.0.0 release tag
- Release notes
- Updated CLAUDE.md

**Success Criteria:**
- Clean, production-ready code
- Complete documentation
- All tests passing
- Ready for external users

---

## Dependencies & Prerequisites

### Required External Tools
- `gh` (GitHub CLI) - for data collection
- `jq` - for JSON processing
- `curl` - for fallback notifications
- Node.js + npx - for MCP servers

### Required MCP Servers
- `@modelcontextprotocol/server-slack` - Slack integration
- `@modelcontextprotocol/server-notion` - Notion integration

### Required GitHub Actions
- `anthropics/claude-code-action@v1.0.14` - Claude Code execution
- `actions/create-github-app-token@v1` (optional) - for cross-org access

### Development Environment
- GitHub repository with Actions enabled
- Test Slack workspace with:
  - Bot token with permissions: channels:history, channels:read, chat:write
  - Test channels where bot is member
- Test Notion workspace with:
  - Integration token
  - Test database for page creation
- Anthropic API key or Claude Code OAuth token

---

## Testing Strategy

### Unit Tests
- Period parsing: all date formats
- Input validation: all validation rules
- Template loading: all templates + customizations

### Integration Tests
- Data collection scripts: real GitHub/Slack data
- Claude Code integration: end-to-end with MCP
- Output posting: verify Slack and Notion posts

### Scenario Tests
- **Single Source Tests:**
  - GitHub only → Slack
  - GitHub only → Notion
  - Slack only → Slack
  - Slack only → Notion

- **Multi-Source Tests:**
  - GitHub + Slack → Slack
  - GitHub + Slack → Notion
  - GitHub + Slack → Both outputs

- **Multi-Repository Tests:**
  - 2 repos (same org)
  - 3 repos (different orgs with GitHub App)

- **Template Tests:**
  - All three default templates
  - Custom instructions
  - Tone overrides
  - Language overrides

### Error Scenario Tests
- Invalid inputs
- Missing credentials
- Partial failures (one output fails)
- Complete failures
- Rate limiting
- Network errors

---

## Risk Assessment & Mitigation

### Risk 1: MCP Server Complexity
**Risk:** Slack/Notion MCP servers may be complex to integrate
**Likelihood:** Medium
**Impact:** High
**Mitigation:**
- Test MCP servers early in Phase 3 & 6
- Have fallback plan to use direct APIs if MCP proves problematic
- Allocate extra time for MCP troubleshooting

### Risk 2: Large Data Volumes
**Risk:** 1000+ PRs or 10000+ messages may exceed Claude context limits
**Likelihood:** Medium
**Impact:** Medium
**Mitigation:**
- Implement strict limits (500 PRs/issues per repo, 1000 messages per channel)
- Add guidance in prompt for Claude to sample/summarize if data is large
- Document limitations clearly

### Risk 3: Cross-Org GitHub Access
**Risk:** GitHub App token setup may be confusing for users
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Provide clear documentation with step-by-step guide
- Include example workflow
- Link to GitHub's official docs

### Risk 4: Notion MCP Server Maturity
**Risk:** `@modelcontextprotocol/server-notion` may not exist or be immature
**Likelihood:** Medium
**Impact:** High
**Mitigation:**
- Research Notion MCP servers in Phase 0/1
- If no good MCP server, consider direct Notion API integration
- Document which approach was chosen and why

### Risk 5: Template Design Complexity
**Risk:** Users may find template customization too complex
**Likelihood:** Medium
**Impact:** Low
**Mitigation:**
- Provide excellent default templates that work out-of-box
- Make customization optional
- Provide clear examples in docs
- Consider user feedback for v2 improvements

---

## Success Metrics

### Phase Completion
- [ ] Phase 0: Prerequisites & Setup
- [ ] Phase 1: Foundation (input validation, period parsing)
- [ ] Phase 2: GitHub Data Collection
- [ ] Phase 3: Slack Data Collection
- [ ] Phase 4: Template System
- [ ] Phase 5: Claude Code Integration
- [ ] Phase 6: Output Handling
- [ ] Phase 7: Documentation & Examples
- [ ] Phase 8: Testing & Validation
- [ ] Phase 9: Release Preparation

### Quality Metrics
- All test scenarios passing
- Documentation complete and accurate
- Example workflows functional
- No P0/P1 bugs
- Code reviewed and approved

### User Experience Metrics
- Setup time < 15 minutes for basic use case
- Clear error messages for all failure modes
- Example workflows work without modification

---

## Timeline Summary

| Phase | Duration | Dependencies | Key Deliverables |
|-------|----------|--------------|------------------|
| Phase 0 | Done | None | Spec, Implementation Plan |
| Phase 1 | Week 1 (13h) | Phase 0 | Input validation, period parsing |
| Phase 2 | Week 1-2 (13h) | Phase 1 | GitHub data collection |
| Phase 3 | Week 2 (16h) | Phase 1 | Slack data collection |
| Phase 4 | Week 2-3 (16h) | Phase 1 | Template system |
| Phase 5 | Week 3 (18h) | Phases 2,3,4 | Claude Code integration |
| Phase 6 | Week 3-4 (20h) | Phase 5 | Output handling |
| Phase 7 | Week 4 (15h) | Phase 6 | Documentation |
| Phase 8 | Week 4-5 (17h) | Phase 7 | Testing & validation |
| Phase 9 | Week 5 (10h) | Phase 8 | Release preparation |

**Total Estimated Time:** ~138 hours (~3.5 weeks full-time or 5 weeks part-time)

---

## Next Steps

1. **Immediate:** Review this implementation plan and make adjustments
2. **Before starting:**
   - Verify Notion MCP server exists and works
   - Set up test environments (Slack workspace, Notion workspace)
   - Gather test credentials
3. **Phase 1 Start:** Create action.yml skeleton and validation scripts

---

## Notes

- This plan assumes familiarity with GitHub Actions, bash scripting, and YAML
- Time estimates are approximate and may vary based on experience level
- MCP integration is the highest risk/complexity area - allocate extra time if needed
- Consider weekly checkpoints to track progress and adjust plan
- Document learnings and gotchas as you go for future reference
