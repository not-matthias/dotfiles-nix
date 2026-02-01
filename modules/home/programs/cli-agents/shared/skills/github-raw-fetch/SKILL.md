---
name: github-raw-fetch
description: Fetch and display raw content from GitHub file URLs by automatically converting standard GitHub URLs to raw.githubusercontent.com format and retrieving the file content.
license: MIT
---

<!-- Source: Created based on user request, combining information from multiple sources -->

# GitHub Raw Fetch Skill

This skill enables fetching raw content from GitHub file URLs by automatically converting standard GitHub URLs to their raw form and retrieving the content.

## Key Purpose

"Fetch and display raw content from GitHub file URLs" by converting standard GitHub URLs to raw.githubusercontent.com format and retrieving the file content.

## Core Workflow Steps

1. **Detect GitHub URL pattern** — Identify if the provided URL is a GitHub file URL (contains `github.com/.../blob/...`)
2. **Convert to raw URL** — Transform the URL using one of these methods:
   - Replace `github.com` with `raw.githubusercontent.com`
   - Remove `/blob/` from the path
   - Result: `https://raw.githubusercontent.com/USER/REPO/BRANCH/path/to/file.ext`
3. **Fetch content** — Use WebFetch tool with the converted raw URL
4. **Present content** — Display the fetched content to the user

## URL Conversion Examples

**Standard to Raw:**
- From: `https://github.com/actioncloud/github-raw-url/blob/master/index.js`
- To: `https://raw.githubusercontent.com/actioncloud/github-raw-url/master/index.js`

**Pattern transformation:**
- `github.com/USER/REPO/blob/BRANCH/path/file.ext`
- → `raw.githubusercontent.com/USER/REPO/BRANCH/path/file.ext`

## Alternative Methods

- **Raw button**: If browsing GitHub UI, click the "Raw" button and copy the URL
- **Query parameter**: Append `?raw=true` to the standard URL for automatic redirect
  - `https://github.com/USER/REPO/blob/BRANCH/path/file.ext?raw=true`

## Safety Guidelines
- Validate that the URL is a GitHub file URL before conversion
- Handle edge cases like URLs that are already in raw format
- Preserve the correct branch/tag/commit reference during conversion
- Inform user if the URL pattern is not recognized

This skill streamlines fetching GitHub file content without manual URL manipulation.
