# WoodpeckerBar

[Woodpecker CI](https://woodpecker-ci.org/) pipeline monitor for [DankMaterialShell](https://github.com/nicko-coder/DankMaterialShell) (DMS/niri).

![Bun](https://img.shields.io/badge/runtime-Bun-f9f1e1?logo=bun)
![TypeScript](https://img.shields.io/badge/lang-TypeScript-3178c6?logo=typescript&logoColor=white)

## What it does

- Shows pipeline status across all your Woodpecker CI repos
- **Adaptive polling** — 5s when builds are running, configurable interval (default 60s) when idle
- **Live elapsed time** — ticking duration counter for active builds
- Per-repo status with commit message, branch, hash, and build duration

## Pill

Rocket icon + live status text:
- **Building**: `pronto 2m 15s` (repo name + ticking elapsed)
- **Failing**: `1 failing` (red)
- **All green**: `all green` (green)

## Popout

Per-repo cards with status icon, build number, duration badge, commit message, branch, short hash, and relative time.

## Setup

```bash
bun install
```

You need a Woodpecker CI API token. Get one from your Woodpecker instance under User Settings → API tokens.

### CLI

```bash
# Fetch all repos
bun run src/index.ts --token YOUR_TOKEN --url https://ci.example.com

# Fetch recent pipelines for a specific repo
bun run src/index.ts --token YOUR_TOKEN --pipelines --repo 2
```

### DMS Plugin

Copy `plugin/` to `~/.config/DankMaterialShell/plugins/WoodpeckerBar/` and add the widget to your bar.

Set your Woodpecker URL and API token in the plugin settings.

## Architecture

Bun TypeScript backend hits the Woodpecker REST API and outputs JSON to stdout, consumed by the QML plugin via `Proc.runCommand`. The widget uses two timers: a fetch timer (adaptive interval) and a 1-second clock timer (only active during builds) for live elapsed time display.
