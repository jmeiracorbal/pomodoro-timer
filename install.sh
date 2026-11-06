#!/bin/bash
# pomodoro-timer installer
# Usage: curl -sSf https://raw.githubusercontent.com/jmeiracorbal/pomodoro-timer/main/install.sh | bash
#
# Environment overrides:
#   POMODORO_VERSION=v2.0.0 bash install.sh
#   POMODORO_INSTALL_DIR=/usr/local/bin bash install.sh
#   POMODORO_DRY_RUN=true bash install.sh

set -e

REPO="jmeiracorbal/pomodoro-timer"
INSTALL_DIR="${POMODORO_INSTALL_DIR:-$HOME/.local/bin}"
DRY_RUN="${POMODORO_DRY_RUN:-false}"
POMODORO_VERSION="${POMODORO_VERSION:-}"

# ── helpers ────────────────────────────────────────────────────────────────────

info() { printf "\033[1;34m[pomodoro]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[pomodoro]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[pomodoro]\033[0m %s\n" "$*" >&2; exit 1; }
warn() { printf "\033[1;33m[pomodoro]\033[0m %s\n" "$*"; }

dry() {
  if [ "$DRY_RUN" = "true" ]; then
    printf "\033[2m  (dry-run) %s\033[0m\n" "$*"
  else
    eval "$@"
  fi
}

# ── detect platform ────────────────────────────────────────────────────────────

detect_platform() {
  local os arch

  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux)  os="linux"  ;;
    *)      err "Unsupported OS: $(uname -s). Download manually from https://github.com/${REPO}/releases" ;;
  esac

  case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64)        arch="amd64" ;;
    *)             err "Unsupported architecture: $(uname -m)" ;;
  esac

  echo "${os}-${arch}"
}

# ── http helpers ───────────────────────────────────────────────────────────────

fetch() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -sSfL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    err "curl or wget required"
  fi
}

fetch_stdout() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -sSfL "$url"
  else
    wget -qO- "$url"
  fi
}

# ── fetch latest release version ──────────────────────────────────────────────

fetch_latest_version() {
  local version
  version=$(fetch_stdout "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
  [ -z "$version" ] && err "Could not fetch latest release version from GitHub API"
  echo "$version"
}

# ── verify checksum ────────────────────────────────────────────────────────────

verify_checksum() {
  local dir="$1" filename="$2"
  local sha_file="${filename}.sha256"

  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$dir" && sha256sum -c "$sha_file") >/dev/null 2>&1 \
      || err "Checksum verification failed"
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$dir" && shasum -a 256 -c "$sha_file") >/dev/null 2>&1 \
      || err "Checksum verification failed"
  else
    warn "sha256sum / shasum not found — skipping checksum verification"
  fi
}

# ── check PATH ─────────────────────────────────────────────────────────────────

check_path() {
  case ":$PATH:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
      warn "${INSTALL_DIR} is not in your PATH."
      warn "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
      warn "  export PATH=\"\$PATH:${INSTALL_DIR}\""
      ;;
  esac
}

# ── download and install ───────────────────────────────────────────────────────

download_and_install() {
  local version="$1" platform="$2"
  local binary_name="pomodoro-${platform}"
  local base_url="https://github.com/${REPO}/releases/download/${version}"

  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  info "Downloading ${binary_name} ${version}..."
  dry fetch "${base_url}/${binary_name}" "${tmp}/${binary_name}"
  dry fetch "${base_url}/${binary_name}.sha256" "${tmp}/${binary_name}.sha256"

  if [ "$DRY_RUN" != "true" ]; then
    info "Verifying checksum..."
    verify_checksum "$tmp" "$binary_name"
    ok "Checksum OK"
  fi

  dry mkdir -p "${INSTALL_DIR}"
  dry install -m 755 "${tmp}/${binary_name}" "${INSTALL_DIR}/pomodoro"
}

# ── main ───────────────────────────────────────────────────────────────────────

main() {
  [ "$DRY_RUN" = "true" ] && info "Dry-run mode — no changes will be made"

  local platform version
  platform=$(detect_platform)
  version="${POMODORO_VERSION:-$(fetch_latest_version)}"

  info "Platform : ${platform}"
  info "Version  : ${version}"
  info "Install  : ${INSTALL_DIR}/pomodoro"

  download_and_install "$version" "$platform"
  check_path

  if [ "$DRY_RUN" != "true" ]; then
    ok "Installed pomodoro ${version} → ${INSTALL_DIR}/pomodoro"
    ok "Run: pomodoro --help"
  else
    ok "Done (dry-run)."
  fi
}

main "$@"
