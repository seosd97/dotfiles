#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"
BREW_PREFIX="/opt/homebrew"
BREW_BIN="$BREW_PREFIX/bin/brew"
MISE_BIN="$BREW_PREFIX/bin/mise"
CLAUDE_DIR="$HOME/.claude"
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

step() { printf '\n[dotfiles] -> %s\n' "$1"; }
info() { printf '[dotfiles]    %s\n' "$1"; }
warn() { printf '[dotfiles] WARN %s\n' "$1" >&2; }
fail() {
  printf '[dotfiles] ERROR %s\n' "$1" >&2
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
  step "Checking Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    info "Already installed."
    return
  fi

  info "Required before Homebrew can be installed."
  info "Opening the installer dialog."
  xcode-select --install >/dev/null 2>&1 || true
  fail "Finish installing Xcode Command Line Tools, then run ./install.sh again."
}

ensure_homebrew() {
  step "Checking Homebrew"

  if [ -x "$BREW_BIN" ]; then
    info "Found at $BREW_BIN."
    return
  fi

  if command -v brew &>/dev/null; then
    fail "Found brew at $(command -v brew), but this setup expects Apple Silicon Homebrew at $BREW_BIN."
  fi

  info "Installing Homebrew to $BREW_PREFIX."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x "$BREW_BIN" ] || fail "Expected Homebrew at $BREW_BIN after installation."
  info "Homebrew installation finished."
}

load_homebrew() {
  step "Loading Homebrew environment"
  eval "$("$BREW_BIN" shellenv)"
  info "brew is available in the current shell."
}

install_brew_bundle() {
  step "Installing packages from Brewfile"
  "$BREW_BIN" bundle --file="$DOTFILES_DIR/Brewfile"
  info "Brewfile install finished."
}

link_file() {
  local src="$1"
  local dst="$2"
  local backup_path

  require_repo_file "$src"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    info "Already linked: $dst"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_path="${dst}.backup.$(date +%s)"
    info "Backing up $dst -> $backup_path"
    mv "$dst" "$backup_path"
  fi

  ln -s "$src" "$dst"
  info "Linked $dst -> $src"
}

copy_gitconfig_local() {
  local src="$DOTFILES_DIR/git/.gitconfig.local.example"
  local dst="$HOME/.gitconfig.local"

  step "Checking local git identity"
  require_repo_file "$src"

  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    cp "$src" "$dst"
    warn "Created $dst from the template. Update your name and email before committing."
    return
  fi

  if grep -qE 'Your Name|you@example\.com' "$dst"; then
    warn "Update $dst with your real git identity before committing."
  else
    info "Using existing $dst."
  fi
}

install_mise_tools() {
  step "Installing runtimes with mise"
  [ -x "$MISE_BIN" ] || fail "Expected mise at $MISE_BIN after brew bundle."
  "$MISE_BIN" install --yes
  info "mise install finished."
}

main() {
  step "Starting bootstrap"
  info "Target: Apple Silicon macOS"

  require_supported_host
  require_repo_file "$DOTFILES_DIR/Brewfile"

  ensure_xcode_cli_tools
  ensure_homebrew
  load_homebrew
  install_brew_bundle

  step "Linking dotfiles"
  link_file "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"
  link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
  link_file "$DOTFILES_DIR/claude/plugins/config.json" "$CLAUDE_DIR/plugins/config.json"
  link_file "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

  copy_gitconfig_local
  install_mise_tools

  step "Bootstrap complete"
  info "Restart the terminal."
  info "Open OrbStack once to initialize it."
}

main "$@"
