---
name: atlassian-cli
description: Use when working with Jira or Confluence from command line, including authentication, searching issues with JQL, bulk operations, sprint reports, or creating/updating work items using acli
---

# Atlassian CLI (acli)

## Overview

The Atlassian CLI (`acli`) provides command-line access to Jira, Confluence, and other Atlassian products. **Core principle:** Always check authentication first, use correct command structure, and leverage batch operations.

## When to Use

- Creating, searching, or updating Jira issues
- Managing sprints, boards, or projects
- Working with Confluence spaces
- Bulk operations on multiple items
- Generating reports in CSV/JSON format
- Automating Atlassian workflows

**When NOT to use:**
- When web UI is more appropriate (one-off visual tasks)
- When API tokens/integrations are already available

## Authentication - FIRST STEP ALWAYS

```dot
digraph auth_check {
    "User requests acli command" [shape=doublecircle];
    "Check auth status" [shape=box];
    "Authenticated?" [shape=diamond];
    "Run acli command" [shape=box];
    "Explain: acli auth login" [shape=box];

    "User requests acli command" -> "Check auth status";
    "Check auth status" -> "Authenticated?";
    "Authenticated?" -> "Run acli command" [label="yes"];
    "Authenticated?" -> "Explain: acli auth login" [label="no"];
}
```

**Before ANY acli operation:**
```bash
# Check if authenticated
acli auth status

# If not authenticated, login first
acli auth login
```

## Command Structure

**Format:** `acli <product> <entity> <action> [flags]`

**DO NOT use old-style syntax with `--action` flag.**

```bash
# ❌ WRONG - old syntax that doesn't work
acli jira --action getIssueList --jql "..."

# ✅ CORRECT - modern syntax
acli jira workitem search --jql "..."
```

## Quick Reference

### Common Products
- `auth` - Authentication management
- `jira` - Jira Cloud commands
- `confluence` - Confluence Cloud commands
- `admin` - Admin operations

### Jira Entities & Actions

| Entity | Common Actions | Example |
|--------|---------------|---------|
| `workitem` | search, create, create-bulk, edit, view, transition, assign, delete | `acli jira workitem search --jql "project = TEAM"` |
| `project` | list, view, create, update, delete, archive | `acli jira project list` |
| `sprint` | create, update, view, delete, list-workitems | `acli jira sprint view 123` |
| `board` | search, get, create, delete, list-sprints | `acli jira board list-sprints --board 42` |
| `workitem comment` | create, list, update, delete | `acli jira workitem comment create --key KEY-1 --comment "text"` |

### Confluence Entities

| Entity | Actions | Example |
|--------|---------|---------|
| `space` | list, view, create, update, archive, restore | `acli confluence space list` |

## Batch Operations

**Use JQL, filters, or key lists to operate on multiple items:**

```bash
# Edit multiple issues with JQL
acli jira workitem edit --jql "project = MOBILE AND status = 'In Review'" --assignee "user@example.com" --yes

# Transition multiple issues
acli jira workitem transition --jql "assignee = currentUser() AND status = 'To Do'" --status "In Progress" --yes

# Search with filter
acli jira workitem search --filter 10001 --csv

# Multiple keys
acli jira workitem assign --key "KEY-1,KEY-2,KEY-3" --assignee "@me"
```

**Batch flags:**
- `--jql` - JQL query for multiple items
- `--filter` - Filter ID for saved searches
- `--key` - Comma-separated issue keys
- `--yes` / `-y` - Skip confirmation prompts
- `--ignore-errors` - Continue on errors (useful for bulk ops)

## Output Formats

**Choose the right output format for your use case:**

```bash
# CSV for spreadsheets
acli jira workitem search --jql "sprint = 42" --csv

# JSON for scripts/automation
acli jira workitem search --jql "project = API" --json

# Web browser for viewing
acli jira workitem view KEY-123 --web

# Custom fields (default includes key, summary, status, etc.)
acli jira workitem search --jql "..." --fields "key,summary,assignee,priority"
```

**Common flags:**
- `--csv` - CSV output (NOT --outputFormat 999)
- `--json` - JSON output
- `--web` - Open in web browser
- `--fields` - Specify which fields to display (NOT --columns)
- `--count` - Show count only
- `--paginate` - Fetch all results

## Bulk Creation

**For creating multiple similar issues:**

```bash
# Generate JSON template
acli jira workitem create --generate-json

# Create from JSON file
acli jira workitem create --from-json workitem.json

# Bulk create multiple issues
acli jira workitem create-bulk

# Use file for description
acli jira workitem create --summary "Bug title" --project API --type Bug --from-file description.txt

# Use editor for interactive creation
acli jira workitem create --editor
```

**Don't create bash loops with 10 individual create commands when `create-bulk` or `--from-json` exists.**

## Parent / Hierarchy

**`acli` can only set a parent at creation time. It cannot re-parent an existing work item.** (Verified against acli 1.3.36-stable.)

```bash
# ✅ Works - set parent when creating
acli jira workitem create --summary "Sub-task" --project TEAM --type Task --parent "TEAM-100"

# ❌ Does NOT work - `edit` has no --parent flag
acli jira workitem edit --key TEAM-123 --parent "TEAM-100"
# ✗ Error: unknown flag: --parent

# ❌ Does NOT work - there is no `update` subcommand (the verb is `edit`)
acli jira workitem update TEAM-123 --parent "TEAM-100"
# ✗ Error: unknown flag: --parent
```

`acli jira workitem edit --generate-json` confirms it: the editable fields are
`assignee`, `description`, `issues`, `labelsToAdd`, `labelsToRemove`, `summary`,
`type`. There is no `parent` key, so `--from-json` is not a way around this.

**`acli jira workitem link` is NOT hierarchy.** It creates issue links, whose
types are Blocks, Cloners, Duplicate, Polaris work item link, Problem/Incident,
Relates. Parent/child is a field, not a link type.

### Re-parenting an existing item

`acli` has no generic REST passthrough (`acli jira` exposes only auth, board,
dashboard, field, filter, project, sprint, workitem), so use the API directly:

```bash
# Set parent
curl -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "https://<site>.atlassian.net/rest/api/3/issue/TEAM-123" \
  -d '{"fields":{"parent":{"key":"TEAM-100"}}}'

# Clear parent
curl -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "https://<site>.atlassian.net/rest/api/3/issue/TEAM-123" \
  -d '{"fields":{"parent":null}}'
```

A success is HTTP 204 with an empty body. Add `-w '%{http_code}'` to see it.

**Caveats:**
- The new parent must be a valid type in the project's hierarchy (e.g. Story
  under Epic), and in the same project — otherwise Jira returns 400.
- Team-managed vs company-managed projects differ in what re-parenting they
  allow; a 400 here is usually a hierarchy rule, not a bad request shape.

## Common JQL Patterns

```bash
# Current user's issues
--jql "assignee = currentUser()"

# Specific project and status
--jql "project = TEAM AND status = 'In Progress'"

# Multiple criteria
--jql "project = API AND type = Bug AND status != Done"

# Sprint issues
--jql "project = TEAM AND sprint = 42"

# Recent updates
--jql "project = WEBAPP AND updated >= -7d"
```

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|---------------|-----------------|
| Skipping auth check | Commands fail without authentication | Always run `acli auth status` first |
| Using `--action` flag | Old syntax doesn't work in modern acli | Use `acli <product> <entity> <action>` |
| `--outputFormat 999` | Wrong flag | Use `--csv` |
| `--columns` parameter | Doesn't exist | Use `--fields` |
| Bash loops for creation | Inefficient, built-in features exist | Use `create-bulk`, `--from-json` |
| One-by-one edits | Slow for bulk operations | Use `--jql` or `--filter` with edit/transition |
| Making up commands | Wastes time | Run `acli <product> <entity> --help` to verify |
| `acli jira workitem update` | No such subcommand; it silently prints help | The verb is `edit` |
| Positional issue key | acli takes no positional key | Use `--key KEY-1` |
| `edit --parent` | `edit` cannot re-parent; only `create` takes `--parent` | Use the REST API (see Parent / Hierarchy) |

## Red Flags - STOP and Check Skill

These indicate you're about to make a mistake:

- Skipping authentication check
- Using `--action` in your command
- Writing bash loops for bulk operations
- Suggesting `--outputFormat` instead of `--csv`
- Using `--columns` instead of `--fields`
- Making up command names without checking --help
- "The old syntax probably still works"
- "They're probably already authenticated"
- Reaching for `acli jira workitem update` (there is no `update`)
- Passing an issue key positionally instead of via `--key`
- Trying to re-parent an existing item with `edit --parent`
- "A bash loop is more flexible than built-in commands"

**All of these mean: Stop, re-read this skill, use correct syntax.**

## Workflow Pattern

```dot
digraph workflow {
    "acli request" [shape=doublecircle];
    "Check auth status" [shape=box];
    "Authenticated?" [shape=diamond];
    "Run acli auth login" [shape=box];
    "Verify command with --help" [shape=box];
    "Check for batch operation?" [shape=diamond];
    "Use --jql/--filter/--key" [shape=box];
    "Single operation" [shape=box];
    "Choose output format" [shape=box];
    "Execute command" [shape=box];

    "acli request" -> "Check auth status";
    "Check auth status" -> "Authenticated?";
    "Authenticated?" -> "Run acli auth login" [label="no"];
    "Run acli auth login" -> "Verify command with --help";
    "Authenticated?" -> "Verify command with --help" [label="yes"];
    "Verify command with --help" -> "Check for batch operation?";
    "Check for batch operation?" -> "Use --jql/--filter/--key" [label="multiple items"];
    "Check for batch operation?" -> "Single operation" [label="single item"];
    "Use --jql/--filter/--key" -> "Choose output format";
    "Single operation" -> "Choose output format";
    "Choose output format" -> "Execute command";
}
```

## Example Workflows

### Sprint Report
```bash
# 1. Check auth
acli auth status

# 2. Search sprint issues with CSV output
acli jira workitem search --jql "project = TEAM AND sprint = 42" --fields "key,summary,status,assignee" --csv > sprint-report.csv
```

### Bulk Status Update
```bash
# 1. Check auth
acli auth status

# 2. Verify issues first
acli jira workitem search --jql "project = MOBILE AND status = 'In Review'" --count

# 3. Transition all
acli jira workitem transition --jql "project = MOBILE AND status = 'In Review'" --status "Done" --yes

# 4. Assign all
acli jira workitem assign --jql "project = MOBILE AND status = Done" --assignee "user@example.com" --yes
```

### Create Multiple Issues
```bash
# 1. Check auth
acli auth status

# 2. Generate template
acli jira workitem create --generate-json > template.json

# 3. Edit template.json with your data

# 4. Create from template (repeat for each)
acli jira workitem create --from-json issue1.json
acli jira workitem create --from-json issue2.json

# OR use create-bulk
acli jira workitem create-bulk
```

## Getting Help

```bash
# Top-level help
acli --help

# Product help
acli jira --help

# Entity help
acli jira workitem --help

# Action help
acli jira workitem search --help
```

**When in doubt, check `--help` for exact flags and syntax.**
