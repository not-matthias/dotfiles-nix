# Update Knowledge

Manually trigger the knowledge extraction and CLAUDE.md update process.

Usage: `/update-knowledge`

This command will:
1. Analyze the current session for significant learnings
2. Extract patterns, tools, issues, and module documentation
3. Intelligently update the project's CLAUDE.md with new knowledge
4. Preserve existing documentation while avoiding duplication

## When to Use

- After solving a complex problem to ensure it's captured
- When you discover a new pattern or convention worth documenting
- If you want to explicitly mark important learnings before session ends
- To force an immediate knowledge update (normally happens at SessionEnd)

## What Gets Captured

The system automatically identifies and documents:
- **Discovered Patterns**: Code patterns, architectural decisions, conventions
- **Tool Updates**: New CLI tools, commands, or workflows
- **Common Issues**: Problems encountered and their solutions
- **Module Documentation**: How specific modules, services, or components work
- **NixOS Specifics**: Configuration patterns, flake updates, hardware quirks

## Examples

After fixing a complex NixOS configuration issue:
```
/update-knowledge
```

The system will review your recent changes and suggest updates to CLAUDE.md.

## Smart Filtering

The knowledge extraction system uses smart filtering to avoid noise:
- Skips trivial read-only sessions
- Deduplicates known issues
- Filters out one-off tasks
- Focuses on reusable knowledge

## Manual Knowledge Entry

For knowledge that isn't automatically captured, you can still manually edit CLAUDE.md directly. The auto-update process preserves your manual additions and can build on them.
