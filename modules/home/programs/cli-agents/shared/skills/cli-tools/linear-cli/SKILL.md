---
name: linear-cli
description: Use when working with the Linear CLI (`linear`) to browse and manage
  issues, projects, teams, cycles, labels, documents, and GraphQL queries.
---

# Linear CLI

Use this skill when the user asks to use or debug the `linear` command-line tool.
Assume authentication is already configured.

## Quick checks

```bash
linear --version
linear --help
```

## Core workflows

### 1) Look up issues

List your issues with filters:

```bash
linear issue list --all-states --team <TEAM_KEY> --project <PROJECT_NAME> --limit 50
linear issue list --state started --state unstarted --label bug --updated-after 2026-01-01
```

View one issue (text or JSON):

```bash
linear issue view <ISSUE_ID>
linear issue view <ISSUE_ID> --json --no-comments
```

Structured issue queries:

```bash
linear issue query --help
```

### 2) Work with projects

```bash
linear project list --all-teams
linear project list --team <TEAM_KEY> --status "In Progress" --json
linear project view <PROJECT_ID>
```

### 3) Explore teams and cycles

```bash
linear team list
linear team members <TEAM_KEY>
linear cycle list --team <TEAM_KEY>
linear cycle view <CYCLE_REF>
```

### 4) Find labels and documents

```bash
linear label list --all
linear label list --team <TEAM_KEY> --json
linear document list --project <PROJECT_NAME> --limit 50
linear document list --issue <TEAM-123> --json
linear document view <DOCUMENT_ID>
```

### 5) Open items in Linear/web

```bash
linear issue view <ISSUE_ID> --web
linear project list --app
linear team list --web
```

### 6) Run raw GraphQL API queries

Inline query:

```bash
linear api 'query { viewer { id name email } }'
```

With variables and pagination:

```bash
linear api 'query($first:Int!,$after:String){ issues(first:$first, after:$after){ nodes { identifier title } pageInfo { hasNextPage endCursor } } }' \
  --variable first=50 \
  --paginate
```

## Command discovery

```bash
linear issue --help
linear project --help
linear team --help
linear cycle --help
linear label --help
linear document --help
linear api --help
```

