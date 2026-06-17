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
- **Multi-package projects** - In a `cabal.project` workspace, `tricorder` discovers every package's components automatically, building and running tests across all of them — no manual target configuration needed.
- **Project context** - Tools like `tricorder source Some.Module` will attempt to find and provide the source code for a given dependency from disk, which allows exploring library APIs more easily.
- **Machine-readable output** - Using `tricorder status --json` we can get build information in a format appropriate for programmatic usage.

## Installing with cabal

`tricorder` is published on [Hackage](https://hackage.haskell.org/package/tricorder). With a GHC and `cabal` toolchain available, install the executable from source:

```bash
cabal update
cabal install tricorder
```

This builds and installs the `tricorder` binary into cabal's install directory (typically `~/.local/bin`, or `~/.cabal/bin` on older setups); make sure it is on your `PATH`.

`tricorder` runs on both Linux and macOS.

## Using with Nix

> [!TIP]
> Configure the binary cache to avoid building GHC from scratch:
>
> ```nix
> nixConfig = {
>   extra-substituters = [
>     "https://cache.iog.io"
>     "https://atelier.cachix.org"
>   ];
>   extra-trusted-public-keys = [
>     "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
>     "atelier.cachix.org-1:rEyd/Z4TiXZbBVuU/lDnKZ/7WtnFTwJ17OKHGcahVUo="
>   ];
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

## Configuring

Tricorder is designed to work for most codebases and users out-of-the-box
without any extra configuration. Despite this, sometimes there is a need to
change the behavior of Tricorder for a given repo.

Tricorder uses the same configuration file for both the daemon running the
build in the background as well as the CLI used to interact with the daemon:
`.tricorder.yaml` in your repository of choice.

### Daemon configuration

The Tricorder daemon is configured using the following options under the
`session` map in `.tricorder.yaml`:

```yaml
session:
  command: cabal repl --enable-multi-repl
  targets: [lib:foo, exe:bar]
  watch_dirs: [foo/src]
  test_targets: [test:foo]
  repl_build_dir: /tmp
  test_timeout: 10
```

- `command`: Build command to use to enter the cabal repl. If not specified,
  Tricorder will attempt to check whether `stack` is used, and also whether it
  is running in a multi-package repository. Specify this option if you think
  Tricorder is incorrect in the command it picks.
- `targets`: Build components to compile in the `cabal repl`. If not specified,
  Tricorder will build all components detected in the `.cabal` file for the
  repository.
- `watch_dirs`: Directories to watch. When a file is changed in a watched
  directory, Tricorder will attempt to rebuild all targets. If not specified,
  Tricorder will add all `hs-source-dirs` for the configured or detected
  targets as `watch_dirs`.
- `watch_exclusion_patterns`: POSIX-compliant regular expressions to match
  files you do _not_ want to watch in `watch_dirs`. Tricorder will always
  ignore files in `dist-newstyle`. Defaults to no patterns, meaning all files
  (except those in `dist-newstyle`) will be watched.
- `test_targets`: Targets to treat as test suites. If not specified, all
  targets in `targets` starting with `test:` are treated as `test_targets`.
  Specify `test_targets: []` to disable running tests with Tricorder.
- `repl_build_dir`: Directory to keep compiled files from the repl. Defaults to
  `dist-newstyle/tricorder` in the repository.
- `test_timeout`: Number of seconds each test target is granted before it is
  considered "timed out". Defaults to `10` seconds. Set to `0` to disable the
  timeout.

### CLI configuration

The CLI can be configured through some options in `.tricorder.yaml`, but is
mostly configured through the commandline itself. See `tricorder --help` for
information on commandline options you can pass to Tricorder.

#### Custom Key Bindings

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

- `toggle_daemon_info_view`: Toggle displaying the daemon info tab.
- `toggle_help`: Toggle displaying the help tab. This tab shows available key
  bindings, including your custom key bindings.
- `cycle_test_view`: Toggle the tests tab and cycle through test results views.
  Cycle past the end to go back to the dashboard.
- `exit_view`: Exit the current view, going back to the dashboard. If you are
  at the dashboard already, this exits the TUI.
- `scroll_up`: Scroll up in the diagnostic list.
- `scroll_down`: Scroll down in the diagnostic list.
- `quit`: Exit the TUI.

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

##### Example

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

This repository also contains [Atelier](atelier-core/README.md), a set of Haskell libraries providing foundational infrastructure for effect-based applications (to be extracted into their own repository).
