# dotfiles

A minimal set of dotfiles for setting up my Apple Silicon Mac.

Right now this covers `zsh`, Homebrew, `mise`, git config, Claude Code, and VS Code user settings.

## Target

- macOS
- Apple Silicon
- `zsh`

## Install

```sh
./install.sh
```

This script will:

- install Xcode Command Line Tools
- install Homebrew
- install packages from `Brewfile`
- symlink `zsh`, `git`, `mise`, `claude`, and `vscode` config
- install runtimes from `mise/config.toml`

If Xcode Command Line Tools are not installed yet, the script opens the installer and exits.
After that, finish the install and run `./install.sh` again.

## After Install

Restart the terminal, then open OrbStack once to initialize it.

The git identity template is created automatically at `~/.gitconfig.local`.
Just update the name and email with real values.

Only static config files are tracked in this repo.
Runtime state such as Claude session history, caches, credentials, backups, and VS Code backup files are intentionally excluded.

## Files

- [install.sh](./install.sh): main bootstrap entrypoint
- [Brewfile](./Brewfile): brew/cask list
- [mise/config.toml](./mise/config.toml): language runtime versions
- [zsh/.zprofile](./zsh/.zprofile): Homebrew initialization
- [zsh/.zshrc](./zsh/.zshrc): `mise` activation
- [git/.gitconfig](./git/.gitconfig): shared git config
- [claude/settings.json](./claude/settings.json): Claude Code settings linked to `~/.claude/settings.json`
- [claude/plugins/config.json](./claude/plugins/config.json): Claude plugin repository config
- [vscode/keybindings.json](./vscode/keybindings.json): VS Code keybindings linked to `~/Library/Application Support/Code/User/keybindings.json`
