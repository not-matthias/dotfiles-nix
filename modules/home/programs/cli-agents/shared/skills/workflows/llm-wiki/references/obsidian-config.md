# Obsidian Configuration

Optional `.obsidian/` config files to make the graph view immediately useful when the wiki is opened in Obsidian.

## app.json

```json
{
  "alwaysUpdateLinks": true,
  "newFileLocation": "current",
  "useMarkdownLinks": false,
  "promptDelete": false
}
```

## core-plugins.json

Enable the core plugins that make a codebase wiki navigable:

```json
{
  "file-explorer": true,
  "global-search": true,
  "switcher": true,
  "graph": true,
  "backlink": true,
  "outgoing-link": true,
  "tag-pane": true,
  "page-preview": true,
  "templates": true,
  "command-palette": true,
  "outline": true
}
```

## graph.json

Color-code graph nodes by folder. Adjust the `rgb` values and `query` paths to match the wiki's folder structure:

```json
{
  "collapse-filter": true,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": true,
  "showOrphans": true,
  "collapse-color-groups": true,
  "colorGroups": [
    {"query": "path:architecture/", "color": {"a": 1, "rgb": 6618880}},
    {"query": "path:modules/", "color": {"a": 1, "rgb": 14725422}},
    {"query": "path:concepts/", "color": {"a": 1, "rgb": 16753920}},
    {"query": "path:guides/", "color": {"a": 1, "rgb": 42869}},
    {"query": "path:reference/", "color": {"a": 1, "rgb": 9334700}}
  ],
  "collapse-display": true,
  "showArrow": true,
  "textFadeMultiplier": 0,
  "nodeSizeMultiplier": 1.0,
  "lineSizeMultiplier": 1.0,
  "collapse-forces": true,
  "centerStrength": 0.5,
  "repelStrength": 10,
  "linkStrength": 0.2,
  "linkDistance": 250,
  "scale": 1.0,
  "close": true
}
```

## Color Reference

| Folder | RGB | Approximate color |
|--------|-----|-------------------|
| `architecture/` | 6618880 | Green |
| `modules/` or `crates/` | 14725422 | Blue |
| `concepts/` | 16753920 | Orange |
| `guides/` | 42869 | Yellow |
| `reference/` | 9334700 | Brown |

To generate custom RGB values for Obsidian's color format: `(r << 16) | (g << 8) | b`.
