# dotfiles

A minimal set of dotfiles for setting up my Apple Silicon Mac.

Right now this only covers `zsh`, Homebrew, `mise`, and git config.

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
- symlink `zsh`, `git`, and `mise` config
- install runtimes from `mise/config.toml`

If Xcode Command Line Tools are not installed yet, the script opens the installer and exits.
After that, finish the install and run `./install.sh` again.

## After Install

Restart the terminal, then open OrbStack once to initialize it.

The git identity template is created automatically at `~/.gitconfig.local`.
Just update the name and email with real values.

## Files

- [install.sh](./install.sh): main bootstrap entrypoint
- [Brewfile](./Brewfile): brew/cask list
- [mise/config.toml](./mise/config.toml): language runtime versions
- [zsh/.zprofile](./zsh/.zprofile): Homebrew initialization
- [zsh/.zshrc](./zsh/.zshrc): `mise` activation
- [git/.gitconfig](./git/.gitconfig): shared git config
