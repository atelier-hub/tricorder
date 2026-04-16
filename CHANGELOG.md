# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

#### tricorder

- Daemon-based GHCi build monitor communicating over a Unix socket
- Commands: `start`, `stop`, `status [--wait]`, `watch`
- `status` outputs structured JSON with build phase, module count, duration, and messages
- Each message includes `severity`, `file`, `line`/`col`, `title` (first line), and `text` (full body)
- Auto-detects cabal/stack projects and builds the `cabal repl --enable-multi-repl` command
- Parses `.cabal` file to resolve `hs-source-dirs` for targeted file watching
- Configurable via `.tricorder.toml` (targets, debounce, log file, etc.)
- File watcher with debouncing; auto-restarts GHCi session on crash (fixes ghcid's crash-on-file-removal bug)
