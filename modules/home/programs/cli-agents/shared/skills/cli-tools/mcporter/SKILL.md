---
name: mcporter
description: Use the mcporter CLI to discover, inspect, call, authenticate, bridge, and generate CLIs or TypeScript clients for Model Context Protocol servers. Use when working with MCP servers from Cursor, Claude Code/Desktop, Codex, Windsurf, OpenCode, VS Code, hosted MCP URLs, or stdio MCP packages, or when deciding which MCPs to add.
license: MIT
allowed-tools: Bash(npx mcporter:*), Bash(mcporter:*)
---

<!-- Sources:
- https://mcporter.sh/
- https://mcporter.sh/install.html
- https://mcporter.sh/config.html
- https://mcporter.sh/cli-reference.html
- https://mcporter.sh/adhoc.html
- https://mcporter.sh/agent-skills.html
- https://github.com/modelcontextprotocol/servers
- https://github.com/punkpeye/awesome-mcp-servers
-->

# mcporter CLI

Use `mcporter` as the portability layer between agents, scripts, and MCP servers. It can import existing editor MCP configs, inspect tool schemas, call tools directly, expose several MCPs as one bridge server, and generate standalone CLIs or typed TypeScript clients.

Prefer `npx mcporter ...` unless `mcporter` is already installed.

## When to Use

- The user asks to list, inspect, call, authenticate, debug, or configure MCP servers.
- You need to use MCP servers already configured in Cursor, Claude Code/Desktop, Codex, Windsurf, OpenCode, or VS Code.
- You want to try a hosted MCP URL or a stdio MCP command without editing config first.
- You need a small MCP-backed CLI or typed client for scripts, tests, or reusable agent skills.
- The user asks which MCPs are useful or worth adding.

## Core Workflow

### 1. Discover configured servers

```bash
npx mcporter list
npx mcporter config list
npx mcporter config doctor
```

mcporter merges home config, project config, and imports from supported editors. Use `--json` when parsing output.

### 2. Inspect before calling

```bash
npx mcporter list linear --brief
npx mcporter list linear --schema
npx mcporter list linear.create_comment --schema
npx mcporter config get linear
```

Read signatures first. Do not guess required argument names.

### 3. Call a tool

Use the clearest call form for the arguments:

```bash
npx mcporter call linear.create_comment issueId:ENG-123 body:'Looks good'
npx mcporter call 'linear.create_comment(issueId: "ENG-123", body: "Looks good")'
npx mcporter call server.tool query:'Nix flakes module options'
```

Useful flags:

```bash
npx mcporter call server.tool --output json
npx mcporter call server.tool --timeout 60000
npx mcporter call server.tool --save-images .agents/tmp/mcp-images
```

### 4. Read resources

```bash
npx mcporter resource docs
npx mcporter resource docs file:///path/to/spec.md
npx mcporter resource docs file:///path/to/spec.md --output markdown
```

### 5. Try ad-hoc servers

Hosted HTTP MCP:

```bash
npx mcporter list https://mcp.context7.com/mcp
npx mcporter call 'https://mcp.example.com/mcp.toolName({ input: "value" })'
```

Stdio MCP:

```bash
npx mcporter list --stdio 'npx -y @playwright/mcp@latest' --name playwright
npx mcporter call --stdio 'npx -y @playwright/mcp@latest' --name playwright playwright.toolName
```

Persist a working server:

```bash
npx mcporter config add docs https://mcp.context7.com/mcp --scope home
npx mcporter config add playwright --transport stdio --command 'npx -y @playwright/mcp@latest' --scope home
```

Use `--allow-http` only for intentional local/plain-HTTP testing.

### 6. Authenticate hosted MCPs

```bash
npx mcporter auth linear
npx mcporter config login linear
npx mcporter auth https://mcp.example.com/mcp --no-browser
```

- OAuth tokens and cached schemas live under `~/.mcporter/` or XDG mcporter paths.
- Treat printed auth URLs and tokens as sensitive.
- Prefer env placeholders such as `${LINEAR_API_KEY}` or `$env:API_TOKEN` over committed secrets.

Linear's official hosted MCP works cleanly with OAuth, so prefer that over committing an API token header:

```bash
npx mcporter config add linear https://mcp.linear.app/mcp --scope project
npx mcporter auth linear
npx mcporter list linear --schema
npx mcporter call linear.list_issues limit:1
```

If schema discovery returns `401`, run `npx mcporter auth linear` and keep the process alive until the browser callback completes. If the browser does not open, visit the printed URL manually.

Minimal project config:

```json
{
  "mcpServers": {
    "linear": {
      "url": "https://mcp.linear.app/mcp"
    }
  }
}
```

With `mcporter 0.10.2`, place `--scope` after the server name and target. `mcporter config add --scope project linear ...` can be parsed as a server named `--scope`.

### 7. Generate a reusable interface

Standalone CLI:

```bash
npx mcporter generate-cli linear --bundle dist/linear-mcp.js
npx mcporter generate-cli docs --include-tools resolve-library-id,query-docs --bundle dist/docs-mcp.js
```

TypeScript definitions or client:

```bash
npx mcporter emit-ts linear --mode types --out src/linear-mcp.d.ts
npx mcporter emit-ts linear --mode client --out src/linear-client.ts
```

For agent skills, prefer one small skill per MCP server or workflow instead of one huge generic MCP skill.

### 8. Bridge keep-alive MCPs into one server

Use this when a client wants one MCP endpoint but you want mcporter to manage several configured keep-alive servers.

```bash
npx mcporter serve --stdio --servers docs,linear
npx mcporter serve --http 7777 --servers docs,linear
```

Only servers configured with `"lifecycle": "keep-alive"` participate. Published tool names become `server__tool`.

## Useful MCPs to Try

Use this as a shortlist when the user asks what MCPs are worth adding. Verify current package names and provider endpoints before committing config.

| MCP | Use for | Typical setup |
| --- | --- | --- |
| Filesystem | Read/write bounded local directories | `npx -y @modelcontextprotocol/server-filesystem <allowed-dir>` |
| Fetch | Fetch web pages and convert them for LLM use | `uvx mcp-server-fetch` or current official package |
| Git | Inspect and operate on local repositories | `uvx mcp-server-git --repository <path>` or current official package |
| Memory | Persistent knowledge graph memory | `npx -y @modelcontextprotocol/server-memory` |
| Sequential Thinking | Step-by-step planning and reasoning scratchpad | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| Time | Timezone and time conversion | `uvx mcp-server-time` |
| Playwright | Browser automation and page interaction | `npx -y @playwright/mcp@latest` |
| Chrome DevTools | Inspect and automate Chromium through DevTools | `npx -y chrome-devtools-mcp@latest` |
| Context7 | Current library/framework documentation | `https://mcp.context7.com/mcp` |
| GitHub | Repos, issues, PRs, code, Actions | GitHub's official MCP server or configured editor import |
| GitLab | Projects, merge requests, issues, CI | GitLab MCP server from provider/community docs |
| Linear | Issues, comments, projects, cycles | `https://mcp.linear.app/mcp` |
| Sentry | Errors, traces, projects, issue context | `https://mcp.sentry.dev/mcp?agent=1` |
| Slack | Channels, messages, team context | Slack MCP server with bot/user token env vars |
| Notion | Notes, databases, pages | Notion MCP server with integration token or OAuth |
| Google Drive | Docs, sheets, drive files | Google Drive MCP server with OAuth |
| PostgreSQL | Read/query database schema and rows | Postgres MCP server with `DATABASE_URL` |
| SQLite | Query local SQLite databases | SQLite MCP server with `--db-path <file>` |
| Supabase | Projects, database, Edge Functions | Supabase hosted MCP endpoint from Supabase docs |
| Neon | Database branches, SQL, project metadata | Neon MCP server from Neon docs |
| Redis | Cache/key inspection and operations | Redis MCP server with `REDIS_URL` |
| Docker | Containers, images, compose state | Docker MCP server for local daemon access |
| Kubernetes | Cluster resources and diagnostics | Kubernetes MCP server scoped to the active kubeconfig |
| Cloudflare | Workers, KV, R2, DNS, logs | Cloudflare MCP server with scoped API token |
| Vercel | Projects, deployments, env vars, logs | Vercel hosted MCP endpoint from Vercel docs |
| AWS | Cloud resources and operations | AWS MCP servers with profile/role-scoped credentials |
| Exa | Web and neural search | Exa MCP server with `EXA_API_KEY` |
| Brave Search | Web/local search | Brave Search MCP server with `BRAVE_API_KEY` |
| Tavily | Search and crawl results for agents | Tavily MCP server with `TAVILY_API_KEY` |
| Firecrawl | Crawl/scrape sites into markdown | Firecrawl MCP server with `FIRECRAWL_API_KEY` |
| Obsidian | Vault notes and knowledge base tasks | Obsidian MCP server pointed at a vault |
| Browserbase | Cloud browser automation | Browserbase MCP server with project/API keys |
| Apify | Actors, scraping, web automation | Apify MCP server with API token |
| Stripe | Customers, charges, subscriptions | Stripe MCP server with restricted API key |
| Figma | Design files, components, inspect data | Figma MCP server with scoped token/OAuth |

## Config Patterns

Project config lives at `config/mcporter.json`; home config lives under `~/.mcporter/mcporter.json[c]` or `$XDG_CONFIG_HOME/mcporter/mcporter.json[c]`.

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/steipete/mcporter/main/mcporter.schema.json",
  "imports": ["cursor", "claude-code", "claude-desktop", "codex", "windsurf", "opencode", "vscode"],
  "mcpServers": {
    "docs": {
      "description": "Context7 docs",
      "baseUrl": "https://mcp.context7.com/mcp"
    },
    "linear": {
      "description": "Linear issues",
      "baseUrl": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    },
    "filesystem": {
      "description": "Project filesystem",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
    }
  }
}
```

## Safety Rules

- Inspect with `list --brief` or `--schema` before calling mutating tools.
- Do not commit secrets, OAuth tokens, generated credentials, or `~/.mcporter` cache files.
- Prefer read-only or least-privilege tokens for database, GitHub, Slack, Stripe, Cloud, and production systems.
- Use `allowedTools` or `blockedTools` in `mcporter.json` when exposing a broad server to agents.
- Keep filesystem and shell-like MCPs restricted to specific directories and non-dangerous workflows.
- Be explicit with hosted MCP URLs. Avoid sending private repo/database/customer data to third-party MCPs unless the user approved that provider.

## Troubleshooting

**No servers listed**
- Run `npx mcporter config list` and check imported editor configs.
- Add one with `npx mcporter config add <name> <url-or-command> --scope home`.

**Missing environment variable**
- mcporter fails fast on unresolved `${VAR}` placeholders. Export the variable or use `${VAR:-fallback}` for non-secret defaults.

**OAuth on a headless machine**
- Run `npx mcporter auth <name-or-url> --no-browser` and complete the URL manually. Keep the mcporter process alive until redirect completion.

**Plain HTTP endpoint rejected**
- Use HTTPS. For deliberate local testing, pass `--allow-http`.

**Stdio command prompts or hangs**
- Run the command manually first.
- Add `--yes` for trusted ad-hoc stdio commands.
- Check required env vars and working directory.
