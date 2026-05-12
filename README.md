# Tricorder

`tricorder` aims to empower users developing programs with Haskell and LLM coding agents. It does so by providing operations to surface the right information required at a given stage: documentation, build status, diagnostics, etc.

Like similar tools (`ghcid`, `ghciwatch`), it builds the code continuously on every change, presents diagnostics, and runs the tests afterwards. However, `tricorder` offers other advantages:

- **Designed for humans** - A `tricorder ui` interactive TUI mode that presents stats in real time for developers.
- **Designed for agents** - A `SKILL` is provided to inform agentic usage via the `tricorder` CLI.
- **Background builds** - Building in the background using a daemon allows different clients to query the build state simultaneously without triggering multiple rebuilds. For instance, we ship the `tricorder ui` TUI and the `tricorder status` CLI command that communicate witha single daemon via a socket.
- **Sane defaults** - Running `tricorder start` should Just Work™ for most cabal-based Haskell projects.
  - Daemon restarts automatically when cabal files change
  - If customization is needed it can be provided at different levels via a `.tricorder.yaml` or CLI args.
    - Optional config includes which cabal packages to watch, which exact command to use to enter a GHCi session, [customizable key bindings](#custom-key-bindings), etc.
- **Project context** - Tools like `tricorder source Some.Module` will attempt to find and provide the source code for a given dependency from disk, which allows exploring library APIs more easily.
- **Machine-readable output** - Using `tricorder status --json` we can get build information in a format appropriate for programmatic usage.

## Using with Nix

> [!TIP]
> Configure the binary cache to avoid building GHC from scratch:
>
> ```nix
> nix.settings = {
>   extra-substituters = [ "https://atelier.cachix.org" ];
>   extra-trusted-public-keys = [ "atelier.cachix.org-1:rEyd/Z4TiXZbBVuU/lDnKZ/7WtnFTwJ17OKHGcahVUo=" ];
> };
> ```

### Try it out

```bash
nix run --accept-flake-config github:atelier-hub/tricorder -- ui
```

`--accept-flake-config` tells Nix to use the binary caches declared in this flake. Without it, Nix will build the entire Haskell toolchain from source.

### Dev shell

To make `tricorder` available in a project's dev shell without installing it system-wide:

```nix
inputs.tricorder.url = "github:atelier-hub/tricorder";

devShells.default = pkgs.mkShell {
  packages = [ inputs.tricorder.packages.${system}.tricorder ];
};
```

### Installing

Add the flake input and apply the overlay:

```nix
inputs.tricorder.url = "github:atelier-hub/tricorder";

nixpkgs.overlays = [ inputs.tricorder.overlays.default ];
```

### Home Manager

```nix
imports = [ inputs.tricorder.homeManagerModules.default ];
programs.tricorder.enable = true;
```

### NixOS (without Home Manager)

```nix
imports = [ inputs.tricorder.nixosModules.default ];
programs.tricorder.enable = true;
```

## Using with Claude Code

Tricorder ships a [Claude Code](https://claude.ai/code) plugin that gives agents real-time GHCi build status via a skill.

### Install the plugin

Add the `atelier` marketplace to your Claude Code `settings.json` (either project-level `.claude/settings.json` or user-level `~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "atelier": {
      "source": {
        "source": "github",
        "repo": "atelier-hub/tricorder"
      }
    }
  },
  "enabledPlugins": {
    "tricorder@atelier": true
  }
}
```

### (Optional) Allow tricorder commands

The skill uses `tricorder status` and `tricorder status --wait`. Add them to your `permissions.allow` list to avoid being prompted on every invocation:

```json
{
  "permissions": {
    "allow": [
      "Bash(tricorder status)",
      "Bash(tricorder status --wait)",
      "Skill(tricorder:tricorder)"
    ]
  }
}
```

Once enabled, Claude Code will automatically check GHCi build status and diagnostics when working on Haskell code in projects running the tricorder daemon.

## Custom Key Bindings

You can specify custom key bindings for `tricorder ui`'s TUI in your
`.tricorder.yaml` file.

The format is as follows:

```yaml
keybindings:
  <event>: <keybind>[, <keybind>, <keybind>, ...]
```

`keybindings` is an object whose keys are event names and whose values are
strings of key bindings, each key binding in the string separated by a comma.

The following event names are recognized:

- `toggle_daemon_info_view`: Toggle displaying daemon info.
- `quit`: Exit the TUI.
- `scroll_up`: Scroll up in the diagnostic list.
- `scroll_down`: Scroll down in the diagnostic list.
- `toggle_help`: Toggle displaying the available key bindings. This includes
  your custom key bindings.

Key binds are specified in the format `<modifiers>-<key>`, where `<modifiers>`
is an optional `-`-separated list of modifier keys, and `<key>` is any
non-modifier key on your keyboard.

Alternatively, the key bind can be `unbound`, which removes default key
bindings for the given event.

The following modifiers are recognized:

- `s`, `shift`
- `m`, `meta`
- `a`, `alt`
- `c`, `ctrl`, `control`

The following non-modifier keys are recognized:

- `f1`, `f2`, ...
- `esc`
- `backspace`
- `enter`
- `left`
- `right`
- `up`
- `down`
- `upleft`
- `upright`
- `downleft`
- `downright`
- `center`
- `backtab`
- `printscreen`
- `pause`
- `insert`
- `home`
- `pgup`
- `del`
- `end`
- `pgdown`
- `begin`
- `menu`
- `space`
- `tab`
- All letter, symbol and number keys.

### Example

```yaml
keybindings:
  quit: c-q
  scroll_up: k, up
  scroll_down: j, down
  toggle_daemon_info_view: unbound
```

## Development

```bash
nix develop
tricorder ui
```

## Libraries

This repository also contains [Atelier](atelier/README.md), a Haskell library providing foundational infrastructure for effect-based applications (to be extracted into its own repository).
