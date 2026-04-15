#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"
BREW_PREFIX="/opt/homebrew"
BREW_BIN="$BREW_PREFIX/bin/brew"
MISE_BIN="$BREW_PREFIX/bin/mise"

info() { printf '[dotfiles] %s\n' "$1"; }
warn() { printf '[dotfiles] WARN: %s\n' "$1" >&2; }
fail() {
  printf '[dotfiles] ERROR: %s\n' "$1" >&2
  exit 1
}

require_supported_host() {
  [ "$OS" = "Darwin" ] || fail "This bootstrap only supports macOS."
  [ "$ARCH" = "arm64" ] || fail "This bootstrap only supports Apple Silicon Macs."
}

require_repo_file() {
  local path="$1"
  [ -e "$path" ] || fail "Missing required file: $path"
}

ensure_xcode_cli_tools() {
  if xcode-select -p &>/dev/null; then
    return
  fi

  info "Xcode Command Line Tools are required."
  info "Opening the installer dialog..."
  xcode-select --install >/dev/null 2>&1 || true
  fail "Finish installing Xcode Command Line Tools, then rerun ./install.sh."
}

ensure_homebrew() {
  if [ -x "$BREW_BIN" ]; then
    return
  fi

  if command -v brew &>/dev/null; then
    fail "Found brew at $(command -v brew), but expected Apple Silicon Homebrew at $BREW_BIN."
  fi

  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x "$BREW_BIN" ] || fail "Expected Homebrew at $BREW_BIN after installation."
}

load_homebrew() {
  eval "$("$BREW_BIN" shellenv)"
}

install_brew_bundle() {
  info "Installing brew packages..."
  "$BREW_BIN" bundle --file="$DOTFILES_DIR/Brewfile"
}

link_file() {
  local src="$1"
  local dst="$2"
  local backup_path

  require_repo_file "$src"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_path="${dst}.backup.$(date +%s)"
    info "Backing up $dst to $backup_path"
    mv "$dst" "$backup_path"
  fi

  ln -s "$src" "$dst"
  info "Linked $dst"
}

copy_gitconfig_local() {
  local src="$DOTFILES_DIR/git/.gitconfig.local.example"
  local dst="$HOME/.gitconfig.local"

  require_repo_file "$src"

  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    cp "$src" "$dst"
    warn "Created $dst from template. Update your name and email before committing."
    return
  fi

  if grep -qE 'Your Name|you@example\.com' "$dst"; then
    warn "Update $dst with your real git identity before committing."
  fi
}

install_mise_tools() {
  [ -x "$MISE_BIN" ] || fail "Expected mise at $MISE_BIN after brew bundle."
  info "Installing runtimes with mise..."
  "$MISE_BIN" install --yes
}

main() {
  require_supported_host
  require_repo_file "$DOTFILES_DIR/Brewfile"

  ensure_xcode_cli_tools
  ensure_homebrew
  load_homebrew
  install_brew_bundle

  link_file "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"
  link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

  copy_gitconfig_local
  install_mise_tools

  info "Done. Restart your terminal and open OrbStack once to finish setup."
}

main "$@"
