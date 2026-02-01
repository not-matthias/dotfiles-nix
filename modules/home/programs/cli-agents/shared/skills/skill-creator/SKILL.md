---
name: skill-creator
description: Guide for creating effective agent skills. Use when users want to create, update, or understand skills that extend AI agent capabilities with specialized knowledge, workflows, or tool integrations. This skill explains the skill format, anatomy, creation process, and best practices.
license: MIT
---

<!--
Sources:
- https://agentskills.io/llms.txt (Agent Skills specification)
- https://github.com/anthropics/skills/raw/refs/heads/main/skills/skill-creator/SKILL.md (Anthropic skill-creator)
-->

# Skill Creator

This skill guides you through creating effective skills that extend agent capabilities.

## What Are Skills?

Skills are modular, self-contained packages that extend agent capabilities by providing specialized knowledge, workflows, and tools. They transform a general-purpose agent into a specialized agent equipped with procedural knowledge.

**Skills Provide:**
- **Specialized workflows** - Multi-step procedures for specific domains
- **Tool integrations** - Instructions for working with file formats or APIs
- **Domain expertise** - Company-specific knowledge, schemas, business logic
- **Bundled resources** - Scripts, references, and assets for complex tasks

## How Skills Work

Skills use **progressive disclosure** to manage context efficiently:

1. **Metadata (name + description)** - Always loaded (~100 tokens)
   - Used to determine when to activate the skill
   - Must be clear and comprehensive

2. **SKILL.md body** - Loaded only when skill triggers (<5000 tokens)
   - Contains instructions and workflows
   - Keep concise - context window is shared

3. **Bundled resources** - Loaded as needed by agent
   - References, scripts, assets
   - Unlimited size because loaded selectively

## Anatomy of a Skill

```
skill-name/
├── SKILL.md                    # Required: YAML frontmatter + instructions
├── scripts/                    # Optional: Executable code
├── references/                 # Optional: Documentation for context
└── assets/                     # Optional: Templates, images, data files
```

### SKILL.md Structure

```yaml
---
name: skill-name                          # Required: lowercase-hyphens
description: What this skill does and    # Required: 1-1024 chars
  when to use it. Include triggers and
  specific use cases.
license: MIT                              # Required if adapted
---

<!-- Source: https://github.com/original/repo/path -->

# Skill Title

Brief overview of what this skill does.

## When to Use

- Scenario 1: When user asks for...
- Scenario 2: When working with...

## Workflow

### Step 1: Action
Clear instructions...

### Step 2: Processing
What to do next...

## Examples

### Example 1: Basic
```bash
command --flag value
```

## Common Issues

**Issue**: Description
- **Solution**: How to fix
```

### Bundled Resources

#### scripts/
Executable code for deterministic reliability.

**When to include:**
- Same code rewritten repeatedly
- Fragile operations requiring precision
- Complex logic better handled by code

**Examples:**
- `scripts/rotate_pdf.py` for PDF manipulation
- `scripts/validate_schema.py` for data validation

**Benefits:**
- Token efficient (don't load into context)
- Deterministic execution
- May run without agent reading

#### references/
Documentation for agent to reference while working.

**When to include:**
- Detailed documentation (API specs, schemas)
- Domain knowledge (policies, guidelines)
- Multiple variants/frameworks (aws.md, gcp.md)

**Examples:**
- `references/api_docs.md` - API specifications
- `references/schema.md` - Database schemas
- `references/policies.md` - Company policies

**Best practices:**
- Keep SKILL.md lean; move details here
- Organize by domain (finance.md, sales.md)
- Include grep patterns for large files (>10k words)
- All references must link directly from SKILL.md

#### assets/
Files used in final output, not loaded into context.

**When to include:**
- Templates for output generation
- Brand assets (logos, fonts)
- Boilerplate code to copy/modify

**Examples:**
- `assets/logo.png` for brand assets
- `assets/frontend-template/` for React boilerplate
- `assets/slides.pptx` for PowerPoint templates

## Skill Creation Process

### Step 1: Understand with Concrete Examples

Gather concrete usage examples:
- "What functionality should this skill support?"
- "Can you give examples of how this skill would be used?"
- "What would trigger this skill?"

### Step 2: Plan Reusable Contents

Analyze each example to identify:
1. Scripts needed (repeatedly rewritten code)
2. References needed (schemas, documentation)
3. Assets needed (templates, boilerplate)

### Step 3: Create the Skill File

**File naming:**
- Use lowercase with hyphens: `skill-name.md`
- Must match `name` in frontmatter

**Frontmatter (YAML):**
```yaml
---
name: skill-name
description: Clear description of what this skill does and
  when to use it. Include specific triggers like:
  "Use when working with X files, Y workflows, or Z APIs."
license: MIT  # If adapting external content
---

<!-- Source: https://original-source-url -->
```

**Description best practices:**
- ✅ Good: "Extracts text from PDFs. Use when working with PDF documents, forms, or document extraction."
- ❌ Poor: "Helps with PDFs."

### Step 4: Write Instructions

**Content structure:**
```markdown
# Skill Name

Brief overview.

## When to Use

List scenarios that trigger this skill.

## Workflow

### Step 1: Initial Action
Clear instructions.

### Step 2: Processing
Next steps.

### Step 3: Completion
How to finish.

## Examples

### Basic Usage
```bash
example command
```

## Common Issues

**Problem**: Description
- **Solution**: Fix steps

## Tips

- Actionable guidance
- Edge cases to handle
```

**Writing guidelines:**
- Use imperative/infinitive form
- Challenge each piece: "Does agent need this?"
- Prefer concise examples over verbose explanations
- Keep under ~500 lines
- Set appropriate degrees of freedom for the task

### Step 5: Add Bundled Resources (Optional)

**Progressive disclosure patterns:**

**Pattern 1: High-level guide with references**
```markdown
# PDF Processing

## Quick start
[Basic workflow]

## Advanced features
- **Forms**: See [FORMS.md](references/FORMS.md)
- **API reference**: See [REFERENCE.md](references/REFERENCE.md)
```

**Pattern 2: Domain-specific organization**
```
bigquery-skill/
├── SKILL.md
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

**Pattern 3: Conditional details**
```markdown
## Creating documents
Use docx-js. See [DOCX-JS.md](references/DOCX-JS.md).

**For tracked changes**: See [REDLINING.md](references/REDLINING.md)
```

### Step 6: Validate

**Frontmatter checklist:**
- [ ] Valid YAML syntax (no tabs)
- [ ] `name` matches filename
- [ ] `name` is lowercase-hyphens only
- [ ] `description` clear and under 1024 chars
- [ ] `license` included if adapted
- [ ] Source attribution in HTML comment

**Content checklist:**
- [ ] Clear overview of purpose
- [ ] "When to Use" explains triggers
- [ ] Step-by-step workflow
- [ ] Examples with inputs/outputs
- [ ] Common issues documented
- [ ] Under ~500 lines

## Best Practices

### Concise is Key

The context window is a public good. Skills share space with system prompt, conversation history, and user requests.

**Default assumption:** The agent is already smart. Only add context it doesn't have.

### Set Appropriate Degrees of Freedom

Match specificity to task fragility:

| Freedom Level | Use When | Format |
|--------------|----------|--------|
| **High** | Multiple approaches valid, context-dependent | Text instructions |
| **Medium** | Preferred pattern exists, some variation OK | Pseudocode/scripts with params |
| **Low** | Fragile operations, consistency critical | Specific scripts, few parameters |

### Progressive Disclosure Principles

- Keep SKILL.md essentials only
- Move variant details to references/
- Link all references from SKILL.md
- Avoid deeply nested references
- Include table of contents for large reference files (>100 lines)

### What NOT to Include

Do NOT create extraneous documentation:
- ❌ README.md
- ❌ INSTALLATION_GUIDE.md
- ❌ CHANGELOG.md
- ❌ QUICK_REFERENCE.md

Include only what the agent needs to do the job.

### File Organization

**Information should live in ONE place:**
- SKILL.md: Core workflow and triggers
- references/: Detailed docs, schemas, examples
- scripts/: Executable code
- assets/: Output templates

Avoid duplication between SKILL.md and references.

## Quick Reference

### Frontmatter Template

```yaml
---
name: skill-name
description: What this skill does and when to use it.
  Include specific triggers and use cases.
license: MIT  # If adapting external work
---

<!-- Source: https://github.com/original/source -->
```

### Skill Structure Template

```markdown
# [Skill Name]

[Overview paragraph]

## When to Use

- [Scenario 1]
- [Scenario 2]

## Prerequisites

[List any requirements]

## Workflow

### Step 1: [Action]
[Instructions]

### Step 2: [Action]
[Instructions]

## Examples

### [Example Name]
```
[Code example]
```

## Resources

- [reference/file.md] - [When to use]
- [scripts/script.py] - [What it does]

## Common Issues

**[Issue]**: [Description]
- [Solution]

## See Also

- https://agentskills.io/specification
- https://agentskills.io/llms.txt
```

## Additional Resources

- **Agent Skills Specification**: https://agentskills.io/specification
- **Overview**: https://agentskills.io/llms.txt
- **Integration Guide**: https://agentskills.io/integrate-skills.md
- **GitHub Repository**: https://github.com/agentskills/agentskills
- **Example Skills**: https://github.com/0avx/claude-skills
- **Amp Contrib Skills**: https://github.com/ampcode/amp-contrib

## Examples in This Directory

| Skill | Purpose | Structure |
|-------|---------|-----------|
| `github-raw-fetch.md` | URL transformation | Simple workflow |
| `rust.md` | Development practices | Multiple workflows |
| `ast-grep.md` | Code search | Multi-phase workflow |
| `technical-researcher.md` | Research methodology | Complex reasoning |
