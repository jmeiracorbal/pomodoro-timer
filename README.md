# Pomodoro Timer

A Pomodoro timer for the terminal, written in Go. Single binary, no runtime required.

[![Tests](https://github.com/jmeiracorbal/pomodoro-timer/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/jmeiracorbal/pomodoro-timer/actions/workflows/test.yml)
[![Release](https://github.com/jmeiracorbal/pomodoro-timer/actions/workflows/release.yml/badge.svg)](https://github.com/jmeiracorbal/pomodoro-timer/actions/workflows/release.yml)
[![Go version](https://img.shields.io/badge/Go-1.26.5-00ADD8?logo=go)](https://go.dev/dl/)
[![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-blue)](https://github.com/jmeiracorbal/pomodoro-timer/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Install

### curl (Linux / macOS)

```bash
curl -sSf https://raw.githubusercontent.com/jmeiracorbal/pomodoro-timer/main/install.sh | bash
```

Installs to `~/.local/bin/pomodoro`. Override with `POMODORO_INSTALL_DIR`:

```bash
POMODORO_INSTALL_DIR=/usr/local/bin curl -sSf https://raw.githubusercontent.com/jmeiracorbal/pomodoro-timer/main/install.sh | bash
```

### Prebuilt binaries

Download from [GitHub Releases](https://github.com/jmeiracorbal/pomodoro-timer/releases) — available for Linux, macOS, and Windows (amd64/arm64).

### From source

```bash
git clone https://github.com/jmeiracorbal/pomodoro-timer
cd pomodoro-timer
go install ./cmd/pomodoro
```

## Usage

```bash
# Default session (25 min work / 5 min break / 15 min long break, 4 cycles)
pomodoro

# Custom timings
pomodoro -w 50 -s 10 -l 25 -c 3

# Silent mode
pomodoro --no-sound --no-notifications

# Show today's stats
pomodoro --stats
```

## Controls

| Key     | Action              |
|---------|---------------------|
| `space` | Pause / Resume      |
| `s`     | Skip current phase  |
| `r`     | Reset current phase |
| `q`     | Quit                |

## Options

```
-w minutes   Work session duration (default 25)
-s minutes   Short break duration (default 5)
-l minutes   Long break duration (default 15)
-c count     Work sessions before a long break (default 4)
--no-sound           Disable sound notifications
--no-notifications   Disable desktop notifications
--stats              Show today's productivity summary
-v                   Print version
```

## Data

| File | Purpose |
|------|---------|
| `~/.config/pomodoro/config.json` | Persisted configuration |
| `~/.local/share/pomodoro/stats.json` | Session history |

## Build from source

```bash
go build -o pomodoro ./cmd/pomodoro

# Cross-compile
GOOS=linux  GOARCH=amd64 go build -o pomodoro-linux  ./cmd/pomodoro
GOOS=darwin GOARCH=arm64 go build -o pomodoro-darwin ./cmd/pomodoro
GOOS=windows GOARCH=amd64 go build -o pomodoro.exe  ./cmd/pomodoro
```

## License

MIT — see [LICENSE](LICENSE).
