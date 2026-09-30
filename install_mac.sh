#!/usr/bin/env bash
#
# dotfiles installer - macOS
#
# Installs the tools listed in README.md (everything except the
# Languages/Package Managers/Runtimes section), then symlinks the configs
# in this repo into the paths each tool expects.
#
# Re-running upgrades. Unlike install_ubuntu.sh, there is no version-comparison
# machinery here: every tool below is in Homebrew and tracks upstream closely,
# so `brew outdated` already answers the question the Ubuntu script has to ask
# the GitHub API. claude code, opencode and herdr are the exception - they
# self-update, so they use their own installers on both platforms.
#
# Output: only progress lines are printed. Everything a command writes goes to
# a log file, which is named for you if a step fails.

set -euo pipefail

# ---------------------------------------------------------------- logging ---

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

LOG="/tmp/install_mac-$(date +%Y%m%d-%H%M%S).log"

# Anything that fails outside run() still points at the log rather than
# vanishing with a bare non-zero exit.
trap 'warn "Aborted. Full output: $LOG"' ERR

# Run a command with its output captured in $LOG instead of on screen. brew is
# noisy and none of it matters until something breaks - at which point the tail
# is printed and the log named.
#
# Anything that may prompt for input is deliberately NOT wrapped: a hidden
# password prompt is indistinguishable from a hang.
run() {
  printf '\n$ %s\n' "$*" >> "$LOG"
  if ! "$@" >> "$LOG" 2>&1; then
    warn "Failed: $*"
    warn "Last 20 lines of $LOG:"
    tail -20 "$LOG" >&2
    die "Full output: $LOG"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# Install a package, or upgrade it when brew has something newer. Pass --cask
# before the name for casks.
#   brew_pkg [--cask] <name>
#
# $kind is deliberately unquoted: empty, it expands to no argument at all. An
# empty array cannot do that under the bash 3.2 macOS ships, and a fresh Mac
# runs this script before Homebrew's newer bash exists.
brew_pkg() {
  local kind=""
  [ "$1" = --cask ] && { kind=--cask; shift; }
  local name="$1"

  if ! brew list $kind "$name" >/dev/null 2>&1; then
    info "$name is not installed - installing"
    run brew install $kind "$name"
  elif [ -n "$(brew outdated $kind "$name" 2>/dev/null)" ]; then
    info "$name is out of date - upgrading"
    run brew upgrade $kind "$name"
  else
    info "$name is already the latest - skipping"
  fi
}

# Add a line to whichever shell rc files exist, once. The shell is not assumed
# to be zsh or bash, and some lines differ between them (fzf), so a second
# argument overrides the line used for zsh.
# ensure_rc_line <line> [zsh line]
ensure_rc_line() {
  local bash_line="$1" zsh_line="${2:-$1}" rc line target

  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -e "$rc" ] || continue      # that shell isn't set up on this machine
    case "$rc" in
      *.bashrc) line="$bash_line" ;;
      *.zshrc)  line="$zsh_line" ;;
    esac

    # Where the line is actually written. ~/.zshrc is normally a symlink to
    # zsh/.zshrc in this repo, and appending to that would edit the repo and
    # carry this machine's setup onto every other one. zsh/.zshrc sources
    # ~/.zshrc.local as its last act for exactly this, so redirect there.
    # ~/.bashrc has no such hook, so a symlinked one still only warns.
    target="$rc"
    if [ "$rc" = "$HOME/.zshrc" ] && [ -L "$rc" ]; then
      target="$HOME/.zshrc.local"
    fi

    # Check both: a line already in the repo's zsh/.zshrc must not be
    # duplicated into the local file alongside it.
    if grep -qxF "$line" "$rc" || { [ -e "$target" ] && grep -qxF "$line" "$target"; }; then
      info "$target already has: $line"
    elif [ -L "$target" ]; then
      # Appending would edit the repo itself and show up as a tracked change.
      warn "$target is a symlink - add this line to it at the source:"
      warn "  $line"
    else
      info "Adding to $target: $line"
      printf '\n%s\n' "$line" >> "$target"
    fi
  done
}

# ------------------------------------------------------------------ setup ---
#
# The symlinks below assume this repo is cloned to ~/dotfiles.

[ "$(uname -s)" = Darwin ] || die "This script is for macOS. On Ubuntu use install_ubuntu.sh."

if ! have brew; then
  info "Installing Homebrew"
  # Not wrapped in run: the installer asks for confirmation and a password.
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Make brew usable for the rest of this run. On Apple Silicon the installer
  # only writes the shellenv line into ~/.zprofile, which this shell has not read.
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
  done
fi

have brew || die "Homebrew installation failed."

# Keep brew on PATH for future shells too - on a fresh Apple Silicon machine
# nothing else puts /opt/homebrew/bin there.
ensure_rc_line "eval \"\$($(brew --prefix)/bin/brew shellenv)\""

info "Updating Homebrew"
run brew update

mkdir -p ~/.config    # ln won't create parents; -p is a no-op if it exists

# ================================================================== neovim ===

brew_pkg neovim

info "Linking ~/dotfiles/nvim -> ~/.config/nvim"
ln -sfn ~/dotfiles/nvim ~/.config/nvim    # -f replaces an old link, -n avoids linking inside it

# ================================================================ ghostty ===
#
# The one GUI app here, so it is a cask. It self-updates, which is why brew
# does not report it as outdated - that is correct, not a bug.

if brew list --cask ghostty >/dev/null 2>&1; then
  info "ghostty is already installed - skipping"
else
  info "ghostty is not installed - installing"
  # Not wrapped in run: installing an app bundle can prompt for a password.
  brew install --cask ghostty
fi

info "Linking ~/dotfiles/ghostty -> ~/.config/ghostty"
ln -sfn ~/dotfiles/ghostty ~/.config/ghostty

# ================================================================ lazygit ===

brew_pkg lazygit

# =================================================================== tmux ===

brew_pkg tmux

info "Linking ~/dotfiles/tmux -> ~/.config/tmux"
ln -sfn ~/dotfiles/tmux ~/.config/tmux

# ================================================================= zoxide ===

brew_pkg zoxide

# zoxide is a shell function, not just a binary - without this there is no `z`.
ensure_rc_line 'eval "$(zoxide init bash)"' 'eval "$(zoxide init zsh)"'

# ================================================================ ripgrep ===

brew_pkg ripgrep

# ==================================================================== bat ===

brew_pkg bat

info "Linking ~/dotfiles/bat -> ~/.config/bat"
ln -sfn ~/dotfiles/bat ~/.config/bat

# bat does not read .tmTheme files at runtime - it compiles them into a binary
# cache under ~/.cache/bat, which is bat-version specific and so cannot be
# committed. Rebuild it here, once the themes are linked into place.
if [ -n "$(ls -A ~/dotfiles/bat/themes 2>/dev/null)" ]; then
  info "Building bat theme cache"
  run bat cache --build
fi

# ===================================================================== jq ===

brew_pkg jq

# ==================================================================== fzf ===

brew_pkg fzf

# Shell integration: Ctrl-R history, Ctrl-T files, Alt-C cd, ** completion.
ensure_rc_line 'eval "$(fzf --bash)"' 'eval "$(fzf --zsh)"'

# nf: fuzzy-find a file and open it in nvim. Same line for both shells; the
# zsh copy lives in zsh/.zshrc, which the grep in ensure_rc_line finds.
ensure_rc_line "nf() { local f; f=\$(fzf --preview 'bat --color=always --style=numbers {}') && nvim \"\$f\"; }"

# =================================================================== btop ===

brew_pkg btop

mkdir -p ~/.config/btop

# Themes are only ever read, so they can be linked.
info "Linking ~/dotfiles/btop/themes -> ~/.config/btop/themes"
ln -sfn ~/dotfiles/btop/themes ~/.config/btop/themes

# btop.conf is different: btop rewrites it on exit, so a symlink would leave
# btop editing this repo. Copy it once and leave any local edits alone.
if [ -e ~/.config/btop/btop.conf ]; then
  info "~/.config/btop/btop.conf already exists - leaving it alone"
else
  info "Copying btop.conf to ~/.config/btop/btop.conf"
  cp ~/dotfiles/btop/btop.conf ~/.config/btop/btop.conf
fi

# ==================================================================== eza ===

brew_pkg eza

info "Linking ~/dotfiles/eza -> ~/.config/eza"
ln -sfn ~/dotfiles/eza ~/.config/eza

ensure_rc_line "alias eza='eza -la --git --header --git-repos'"

# ================================================================== delta ===
#
# The formula is git-delta; the binary it installs is `delta`.

brew_pkg git-delta

# ===================================================================== gh ===

brew_pkg gh

# ==================================================================== git ===
#
# macOS ships an Xcode git that lags well behind; brew's is current and takes
# precedence once /opt/homebrew/bin is ahead of /usr/bin on PATH.

brew_pkg git

# git reads ~/.config/git/config natively, so this needs no extra wiring. It is
# what points core.pager at delta.
info "Linking ~/dotfiles/git -> ~/.config/git"
ln -sfn ~/dotfiles/git ~/.config/git

# ====================================================== AI agentic tools ===
#
# claude code, opencode and herdr are all self-updating, and each ships its own
# installer that agrees with its updater - herdr's reads the same latest.json
# that `herdr update` does. brew has casks for two of them, but a brew-managed
# copy fights the built-in updater, so use the vendor installers on macOS too.
#
# All three default to installing in ~/.local/bin, which no shell puts on PATH
# by default.

ensure_rc_line 'export PATH="$HOME/.local/bin:$PATH"'

export PATH="$HOME/.local/bin:$PATH"    # and for the rest of this run

# Aliases. ensure_rc_line appends, which matters for more than tidiness: under
# oh-my-zsh, theme-and-appearance.zsh defines its own `ls` and the git plugin
# its own `g`, so an alias set before `source $ZSH/oh-my-zsh.sh` is silently
# overwritten. Landing at the end of the file puts these after it.
ensure_rc_line 'alias ls="ls -laG"'   # -G is BSD ls color; GNU --color=auto on Ubuntu
ensure_rc_line 'alias g="git"'
ensure_rc_line 'alias p="pnpm"'

# `git log` -> `git log --stat`. Has to be a shell function: git refuses to
# let an [alias] shadow a builtin command, and zsh aliases cannot span two
# words. `g log` also lands here, since `g` expands back to `git`.
ensure_rc_line 'git() { if [[ $1 == log ]]; then command git log --stat "${@:2}"; else command git "$@"; fi }'

# --- claude code -----------------------------------------------------------
#
# claude code, opencode and herdr all update themselves. Re-running their
# installers on a machine that already has them just re-downloads a version
# they would have fetched on their own, so each one is installed only once.

if have claude; then
  info "claude code is already installed - skipping"
else
  info "Installing claude code"
  run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

# Force Fable 5 - Canva org policy otherwise resets the default to Sonnet 5.
# No [1m] suffix as on opus: Fable 5's context window is 1M by default.
ensure_rc_line 'alias claude="claude --model fable"'

# ~/.claude also holds sessions, history and projects, so the directory itself
# cannot be linked - that would hide all of it.
mkdir -p ~/.claude

# statusline.sh is only ever read, so it can be a link.
info "Linking ~/dotfiles/claude/statusline.sh -> ~/.claude/statusline.sh"
ln -sfn ~/dotfiles/claude/statusline.sh ~/.claude/statusline.sh

# settings.json cannot be linked, and is not kept in this repo at all. Claude
# Code reads exactly one settings file per user, ~/.claude/settings.json -
# settings.local.json is a *project*-level file, ignored at user level - and
# other tooling writes to that same file (hooks, enabledPlugins). So set the
# keys in place and leave everything else in there alone.
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
[ -s "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
jq -e . "$CLAUDE_SETTINGS" >/dev/null 2>&1 ||
  die "$CLAUDE_SETTINGS is not valid JSON. Fix or move it, then re-run."

info "Setting Claude Code preferences in $CLAUDE_SETTINGS"
claude_tmp="$(mktemp)"
jq '
    .model                    = "fable"
  | .effortLevel              = "high"
  | .theme                    = "auto"
  | .permissions.defaultMode  = "auto"
  | .statusLine               = { type: "command",
                                  command: "bash \"$HOME/.claude/statusline.sh\"" }
' "$CLAUDE_SETTINGS" > "$claude_tmp"
mv "$claude_tmp" "$CLAUDE_SETTINGS"

# Earlier versions of this script linked settings.local.json here. Claude Code
# never read it; clear it away rather than leave a dangling link behind.
if [ -L ~/.claude/settings.local.json ] &&
   case "$(readlink ~/.claude/settings.local.json)" in "$HOME"/dotfiles/*) true ;; *) false ;; esac
then
  info "Removing stale ~/.claude/settings.local.json link"
  rm -f ~/.claude/settings.local.json
fi

# --- opencode --------------------------------------------------------------

# opencode installs into ~/.opencode/bin, which nothing here adds to PATH, so
# `have` alone would report a perfectly good install as missing.
if have opencode || [ -x "$HOME/.opencode/bin/opencode" ]; then
  info "opencode is already installed - skipping"
else
  info "Installing opencode"
  run bash -c 'curl -fsSL https://opencode.ai/install | bash'
fi

# No config is linked: opencode reads ~/.config/opencode/opencode.jsonc, which
# is not tracked here.

# --- herdr -----------------------------------------------------------------

if have herdr; then
  info "herdr is already installed - skipping"
else
  info "Installing herdr"
  run bash -c 'curl -fsSL https://herdr.dev/install | bash'
fi

# ~/.config/herdr also holds sockets, logs and session.json - link the config
# file only, for the same reason as ~/.claude above.
mkdir -p ~/.config/herdr
info "Linking ~/dotfiles/herdr/config.toml -> ~/.config/herdr/config.toml"
ln -sfn ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml

trap - ERR
info "All done. Full output: $LOG"
