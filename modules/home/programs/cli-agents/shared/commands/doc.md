# Documentation Helper

Creates a new documentation entry in `.claude/docs/` following the established patterns.

Usage: `/doc <title>`

This command will:
1. Create a new markdown file with today's date prefix
2. Use the established documentation template
3. Open the file for editing

Example:
```bash
/doc fix-waybar-battery-issue
```

Creates: `.claude/docs/2025-09-26-fix-waybar-battery-issue.md`

## Template Structure
- Date and title header
- Problem/Overview section
- Root Cause Analysis (if applicable)
- Solution Implemented
- Files Modified
- Technical Details
- Testing
- Impact/Future Improvements