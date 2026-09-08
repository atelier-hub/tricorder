# tricorder

`tricorder` empowers developers and LLM coding agents working with Haskell by surfacing the right information at each stage: build status, diagnostics, test results, and documentation.

Like `ghcid` and `ghciwatch`, it rebuilds continuously on every change and reports diagnostics — but it runs builds in a background daemon so multiple clients (an interactive TUI, a `tricorder status` CLI, a Claude Code skill) can query a single shared build state without triggering redundant rebuilds. It discovers components across multi-package `cabal.project` workspaces automatically and ships context-friendly output for agentic use.

See the [repository README](https://github.com/tweag/tricorder#readme) for installation (Nix, Home Manager, NixOS), Claude Code plugin setup, configuration, and custom key bindings.

## License

MIT — see [LICENSE](LICENSE).
