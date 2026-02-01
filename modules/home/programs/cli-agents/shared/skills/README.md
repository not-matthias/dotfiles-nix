# Claude Agent Skills

This directory contains reusable skills for Claude-based CLI agents (OpenCode, Claude CLI, Amp, etc.). Skills extend agent capabilities with specialized knowledge and workflows.

## About Agent Skills

Skills follow the [Agent Skills specification](https://agentskills.io/llms.txt) - a simple, open format for giving agents new capabilities and expertise.

**Key Resources:**
- **Format Specification**: https://agentskills.io/specification
- **Overview**: https://agentskills.io/llms.txt
- **GitHub Repository**: https://github.com/agentskills/agentskills

## Skill Format

Each skill is a Markdown file (`.md`) with YAML frontmatter containing metadata and instructions.

### Required Structure

```yaml
---
name: skill-name
description: What this skill does and when to use it (1-1024 characters)
---

<!-- Source: https://github.com/original/repo/path/to/skill.md -->

# Skill Title

Detailed instructions, workflows, and examples go here...
```

### Required Fields

| Field | Required | Format | Description |
|-------|----------|--------|-------------|
| `name` | ✅ | `lowercase-with-hyphens` | 1-64 characters, no leading/trailing hyphens |
| `description` | ✅ | string (1-1024 chars) | Clear description of purpose and use cases |
| `license` | ⚠️ | string | Required if adapting external content (e.g., `MIT`) |

### Optional Fields

| Field | Format | Purpose |
|-------|--------|---------|
| `compatibility` | string | Environment requirements (packages, network access) |
| `metadata` | object | Additional properties (author, version, etc.) |
| `allowed-tools` | string | Space-delimited list of pre-approved tools (experimental) |

## Creating a New Skill

### Step 1: Plan Your Skill

Ask yourself:
- **What capability does this add?** (e.g., "Process PDFs", "Search code with AST patterns")
- **When should agents use it?** (e.g., "When user mentions PDFs", "When searching for code patterns")
- **What tools/dependencies does it need?** (e.g., Python packages, CLI tools, network access)

### Step 2: Write the Skill File

Create a new `.md` file in this directory:

```bash
# Create skill file with lowercase-hyphenated name
touch my-new-skill.md
```

### Step 3: Add Frontmatter

Start with proper YAML frontmatter:

```yaml
---
name: my-new-skill
description: Processes data using XYZ algorithm. Use when user requests XYZ processing or mentions [specific keywords].
license: MIT  # If adapting external content
---

<!-- Source: https://github.com/original/source if adapted, or "Original work" -->
```

**Description Best Practices:**
- ✅ **Good**: "Extracts text and tables from PDF files. Use when working with PDF documents or when user mentions PDFs, forms, or document extraction."
- ❌ **Poor**: "Helps with PDFs."

### Step 4: Write Instructions

Structure your skill content clearly:

```markdown
# Skill Name

Brief overview of what this skill does.

## When to Use This Skill

- Scenario 1: When user asks for...
- Scenario 2: When working with...
- Scenario 3: When you need to...

## Workflow

### Step 1: Initial Action
Clear instructions for the first step.

### Step 2: Processing
What to do next.

### Step 3: Completion
How to finish and present results.

## Examples

### Example 1: Basic Usage
\`\`\`bash
command-example --flag value
\`\`\`

### Example 2: Advanced Usage
\`\`\`bash
complex-command | processing
\`\`\`

## Common Issues

**Issue**: Problem description
- **Solution**: How to fix it

## Tips and Best Practices

- Keep instructions clear and actionable
- Include examples for common use cases
- Document edge cases and gotchas
```

### Step 5: Follow Best Practices

**Progressive Disclosure:**
- Keep main skill file under 5000 tokens (~500 lines)
- Move detailed reference material to `references/` subdirectory if needed
- Use `scripts/` for executable code
- Use `assets/` for templates, data files, etc.

**Content Quality:**
- ✅ Clear, step-by-step instructions
- ✅ Real examples with expected inputs/outputs
- ✅ Edge cases and error handling
- ✅ When to use (and when NOT to use) this skill
- ❌ Vague or incomplete instructions
- ❌ Placeholder text like "TODO: add details"

**Naming Conventions:**
- File: `my-skill.md` (lowercase with hyphens)
- Frontmatter name: `my-skill` (must match filename without .md)
- No spaces, underscores, or uppercase letters

## Validation

While there's no official validator available yet, manually check:

### Frontmatter Checklist
- [ ] Valid YAML syntax (no tabs, proper indentation)
- [ ] `name` field present and matches filename
- [ ] `name` is lowercase with hyphens only
- [ ] `description` is clear and under 1024 characters
- [ ] `license` included if adapting external work
- [ ] Source attribution in HTML comment after frontmatter

### Content Checklist
- [ ] Clear overview of skill purpose
- [ ] "When to Use" section explains triggers
- [ ] Step-by-step workflow or instructions
- [ ] Examples with realistic inputs/outputs
- [ ] Common issues and solutions documented
- [ ] Under ~500 lines (if longer, consider splitting into references)

## Examples in This Directory

### Simple Skill: `github-raw-fetch.md`
- **Purpose**: Convert GitHub URLs to raw format and fetch content
- **Structure**: Straightforward workflow with URL transformation patterns
- **Good for**: Learning basic skill structure

### Comprehensive Skill: `rust.md`
- **Purpose**: Rust/Cargo development best practices
- **Structure**: Multiple workflows, command references, troubleshooting
- **Good for**: Learning detailed instruction organization

### Complex Skill: `ast-grep.md`
- **Purpose**: Structural code search using AST patterns
- **Structure**: Multi-phase workflow, rewriting capabilities, validation
- **Good for**: Learning how to handle complex, multi-step processes

### Research Skill: `technical-researcher.md`
- **Purpose**: Systematic technical research methodology
- **Structure**: Recursive exploration, source hierarchy, synthesis
- **Good for**: Learning how to guide complex reasoning processes

## Directory Structure

```
shared/
├── INSTRUCTIONS.md      # System-level agent instructions
├── AGENTS.md           # Agent definitions and roles
├── commands/           # Slash commands for agents
│   ├── doc.md
│   ├── gemini-search.md
│   ├── save.md
│   └── update-knowledge.md
└── skills/            # Reusable agent skills
    ├── README.md                  # This file
    ├── ast-grep.md               # Code search with AST patterns
    ├── cmkr-build.md             # cmkr.build CMake/TOML build system
    ├── fact-checker.md           # Technical content verification
    ├── github-raw-fetch.md       # Fetch raw GitHub files
    ├── humanizer.md              # Humanize technical content
    ├── rust.md                   # Rust/Cargo development
    ├── technical-researcher.md   # Research methodology
    └── worktree-parallel.md      # Git worktree management
```

## Contributing Guidelines

### Adding Skills from External Sources

1. **Verify License**: Ensure the source allows reuse (MIT, Apache, CC, etc.)
2. **Include Attribution**: Add source URL in HTML comment after frontmatter
3. **Add License Field**: Include `license: MIT` (or appropriate) in frontmatter
4. **Preserve Author Intent**: Don't significantly modify content without noting changes

### Creating Original Skills

1. **Document Sources**: If combining information from multiple sources, list them all
2. **Test Instructions**: Verify the workflow actually works as described
3. **Be Specific**: Prefer concrete examples over abstract explanations
4. **Consider Edge Cases**: Document what can go wrong and how to handle it

### Updating Existing Skills

1. **Verify Changes**: Ensure updates don't break existing functionality
2. **Update Examples**: Keep code examples current with latest versions
3. **Note Deprecations**: If tools/commands change, update accordingly
4. **Preserve Structure**: Maintain consistent formatting and organization

## Integration with Agents

Skills in this directory are automatically loaded by configured agents through the NixOS configuration:

```nix
# modules/home/programs/cli-agents/opencode/default.nix
home.file = {
  ".opencode/skills" = {
    source = ../shared/skills;
    recursive = true;
  };
};
```

Agents will:
1. Load skill metadata (`name` and `description`) at startup (~100 tokens each)
2. Load full skill instructions when activated (varies by skill size)
3. Have access to all skills for context-aware assistance

## Additional Resources

- **Agent Skills Documentation**: https://agentskills.io
- **Example Skills Repository**: https://github.com/0avx/claude-skills
- **Amp Contrib Skills**: https://github.com/ampcode/amp-contrib
- **Community Skills**: Search GitHub for "claude-skills" or "agent-skills"

## Questions?

If you're unsure about:
- **Format**: Check https://agentskills.io/specification
- **Examples**: Review existing skills in this directory
- **Structure**: Look at `rust.md` or `ast-grep.md` for comprehensive examples
- **Simple Skills**: Check `github-raw-fetch.md` for a minimal but complete skill

---

**Last Updated**: 2026-01-18
**Format Version**: Agent Skills 1.0 (agentskills.io)
