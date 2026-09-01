#!/usr/bin/env bash
#
# dotfiles installer
#
# Section 1: install the tools listed in README.md (everything except the
#            Languages/Package Managers/Runtimes section).
#
# Install method per OS:
#   macOS  -> homebrew
#   Ubuntu -> apt when the package exists in the repos
#   else   -> curl (official upstream installers / release tarballs)

set -euo pipefail

# ---------------------------------------------------------------- logging ---

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------- os detection ---

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)
    if have apt-get; then
      OS=ubuntu
    else
      die "Linux detected but apt-get is missing; only Debian/Ubuntu is supported."
    fi
    ;;
  *) die "Unsupported OS: $(uname -s)" ;;
esac

info "Detected OS: $OS"

# ------------------------------------------------- package manager bootstrap -

APT_UPDATED=0

apt_update_once() {
  [ "$APT_UPDATED" -eq 1 ] && return
  info "Updating apt package lists"
  sudo apt-get update -y
  APT_UPDATED=1
}

bootstrap_pkg_manager() {
  if [ "$OS" = macos ]; then
    if ! have brew; then
      info "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Make brew available in this shell for the rest of the run.
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    have brew || die "Homebrew installation failed."
    info "Updating Homebrew"
    brew update
  else
    apt_update_once
    sudo apt-get install -y curl git ca-certificates
  fi
}

# --------------------------------------------------------- install helpers ---

# True if apt knows about the package.
apt_has() { apt-cache show "$1" >/dev/null 2>&1; }

# True if homebrew already has the package. Needed because some packages
# (casks especially) install binaries that are not on a plain PATH, so have()
# alone would think they are missing and reinstall them on every run.
brew_installed() {
  brew list --formula "$1" >/dev/null 2>&1 || brew list --cask "$1" >/dev/null 2>&1
}

# A single tool failing must not abort the run - the symlink section still
# needs to happen. Collect names and report them at the end instead.
FAILED=""
record_failure() {
  FAILED="$FAILED $1"
  warn "Failed to install $1 - continuing."
}

apt_install() {
  apt_update_once
  sudo apt-get install -y "$@"
}

# install_tool <binary> <brew formula|"--cask name"> <apt package> [curl fallback fn]
#
# An empty brew/apt argument means "not available there", which falls through to
# the curl fallback.
install_tool() {
  local bin="$1" brew_pkg="$2" apt_pkg="$3" fallback="${4:-}"
  local name

  if have "$bin"; then
    info "$bin already installed - skipping"
    return
  fi

  case "$OS" in
    macos)
      if [ -n "$brew_pkg" ]; then
        name="${brew_pkg##* }"   # "--cask ghostty" -> "ghostty"
        if brew_installed "$name"; then
          info "$bin already installed via brew - skipping"
          return
        fi
        info "Installing $bin"
        # shellcheck disable=SC2086  # brew_pkg may carry a --cask flag
        brew install $brew_pkg || record_failure "$bin"
        return
      fi
      ;;
    ubuntu)
      if [ -n "$apt_pkg" ] && apt_has "$apt_pkg"; then
        info "Installing $bin"
        apt_install "$apt_pkg" || record_failure "$bin"
        return
      fi
      ;;
  esac

  if [ -n "$fallback" ]; then
    info "Installing $bin"
    "$fallback" || record_failure "$bin"
  else
    warn "No install method for $bin on $OS - skipped."
  fi
}

# Ensure ~/.local/bin exists and is on PATH for this run.
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# Latest release tag for a GitHub repo, e.g. jesseduffield/lazygit -> v0.44.1
gh_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -m1 '"tag_name"' \
    | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

# --------------------------------------------------------- curl fallbacks ----

install_ghostty_curl() {
  # Ghostty has no apt package; use the community Ubuntu build script.
  curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash
}

install_gh_curl() {
  # GitHub's official apt repository.
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  APT_UPDATED=0
  apt_install gh
}

install_lazygit_curl() {
  local tag version tmp
  tag="$(gh_latest_tag jesseduffield/lazygit)"
  version="${tag#v}"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${version}_Linux_x86_64.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  install -m 755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
  rm -rf "$tmp"
}

install_delta_curl() {
  local tag tmp arch
  tag="$(gh_latest_tag dandavison/delta)"
  arch="$(dpkg --print-architecture)"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/delta.deb" \
    "https://github.com/dandavison/delta/releases/download/${tag}/git-delta_${tag}_${arch}.deb"
  sudo dpkg -i "$tmp/delta.deb"
  rm -rf "$tmp"
}

install_eza_curl() {
  # eza's own apt repository (not in older Ubuntu releases).
  sudo mkdir -p -m 755 /etc/apt/keyrings
  # --yes so a re-run overwrites the keyring instead of aborting.
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
  sudo chmod go+r /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  APT_UPDATED=0
  apt_install eza
}

install_zoxide_curl() {
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_herdr_curl() {
  curl -fsSL https://herdr.dev/install | bash
}

install_opencode_curl() {
  curl -fsSL https://opencode.ai/install | bash
}

install_claude_code() {
  # Claude Code ships its own installer and self-updates from there.
  curl -fsSL https://claude.ai/install.sh | bash
}

# ================================================================= install ===

bootstrap_pkg_manager

# --- General ---------------------------------------------------------------

install_tool nvim    neovim          neovim
install_tool ghostty "--cask ghostty" ""     install_ghostty_curl
install_tool tmux    tmux            tmux
install_tool gh      gh              ""      install_gh_curl
install_tool fzf     fzf             fzf
install_tool jq      jq              jq

# zsh itself, then oh-my-zsh (no package in either manager).
install_tool zsh zsh zsh

# Pin ZSH rather than letting the installer default it: an interactive zsh
# exports ZSH from .zshrc, so it would otherwise leak in from the parent shell
# and disagree with the directory check below.
ZSH="$HOME/.oh-my-zsh"

if [ -d "$ZSH" ]; then
  info "oh-my-zsh already installed - skipping"
else
  info "Installing oh-my-zsh"
  ZSH="$ZSH" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || record_failure oh-my-zsh
fi

# --- Oh My Zsh plugins (git clones into $ZSH_CUSTOM) -----------------------

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

clone_zsh_plugin() {
  local repo="$1" dest="$2"
  if [ -d "$dest" ]; then
    info "$(basename "$dest") already installed - updating"
    git -C "$dest" pull --ff-only --quiet || warn "Could not update $dest"
  else
    info "Installing $(basename "$dest")"
    git clone --depth=1 "$repo" "$dest" || record_failure "$(basename "$dest")"
  fi
}

if [ -d "$ZSH" ]; then
  clone_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_zsh_plugin https://github.com/romkatv/powerlevel10k \
    "$ZSH_CUSTOM/themes/powerlevel10k"
else
  warn "oh-my-zsh missing - skipping zsh plugins."
fi

# --- TUI -------------------------------------------------------------------

install_tool lazygit lazygit lazygit install_lazygit_curl
install_tool btop    btop    btop

# --- AI agentic tools ------------------------------------------------------

install_tool herdr    herdr    "" install_herdr_curl
install_tool opencode opencode "" install_opencode_curl

install_tool claude "--cask claude-code" "" install_claude_code

# --- Improved tools --------------------------------------------------------

install_tool zoxide zoxide    zoxide    install_zoxide_curl
install_tool rg     ripgrep   ripgrep
install_tool bat    bat       bat
install_tool delta  git-delta git-delta install_delta_curl
install_tool eza    eza       eza       install_eza_curl

# On Ubuntu the bat binary is named batcat; expose it as `bat`.
if [ "$OS" = ubuntu ] && have batcat && ! have bat; then
  info "Linking batcat -> bat"
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
fi

info "Tool installation complete."

# ================================================================ symlinks ===
#
# Section 2: link configs from this repo into the paths each tool expects.
#
# Directory links are used where the whole folder is ours (nvim, ghostty,
# tmux, git). File links are used where the target directory also holds state
# we must not clobber - ~/.claude keeps sessions and history, and
# ~/.config/herdr keeps sockets, logs and session.json alongside config.toml.

# Absolute path to this repo, resolved from the script's own location.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

# link <path relative to repo> <absolute target>
link() {
  local src="$DOTFILES/$1" dest="$2"

  if [ ! -e "$src" ]; then
    warn "Missing in repo: $1 - skipping"
    return
  fi

  # Already pointing where we want it. -ef compares the resolved file, so an
  # existing relative symlink counts as correct and is not needlessly redone.
  if [ -L "$dest" ] && [ "$dest" -ef "$src" ]; then
    info "$dest -> $1 (already linked)"
    return
  fi

  # Something else is in the way: move it aside rather than delete it.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "$dest exists - backing up to $dest.$BACKUP_SUFFIX"
    mv "$dest" "$dest.$BACKUP_SUFFIX"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  info "$dest -> $1"
}

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

info "Linking configs from $DOTFILES"

# Whole-directory links.
link nvim    "$XDG_CONFIG_HOME/nvim"
link ghostty "$XDG_CONFIG_HOME/ghostty"
link tmux    "$XDG_CONFIG_HOME/tmux"
link git     "$XDG_CONFIG_HOME/git"
link bat     "$XDG_CONFIG_HOME/bat"
link eza     "$XDG_CONFIG_HOME/eza"

# Single-file links.
link zsh/.zshrc "$HOME/.zshrc"

# ~/.claude also holds sessions, history and projects - link files only.
link claude/settings.local.json "$HOME/.claude/settings.local.json"
link claude/statusline.sh       "$HOME/.claude/statusline.sh"

# ~/.config/herdr also holds sockets and logs - link the config file only.
link herdr/config.toml "$XDG_CONFIG_HOME/herdr/config.toml"

info "Symlinks complete."

if [ -n "$FAILED" ]; then
  warn "Finished, but these failed to install:$FAILED"
  exit 1
fi

info "All done."
