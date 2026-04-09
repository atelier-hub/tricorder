## Installing locally

1. Register the marketplace in your `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "atelier": {
      "source": {
        "source": "directory",
        "path": "/path/to/ghcib"
      }
    }
  },
  "enabledPlugins": {
    "ghcib@atelier": true
  }
}
```

Replace `/path/to/ghcib` with the absolute path to this repository.

2. In Claude Code, run `/plugin` to install, then `/reload-plugins` to activate.
