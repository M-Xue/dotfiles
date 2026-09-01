#!/usr/bin/env bash
#
# dotfiles installer - Ubuntu
#
# Installs the tools listed in README.md (everything except the
# Languages/Package Managers/Runtimes section), then symlinks the configs
# in this repo into the paths each tool expects.
#
# Re-running upgrades: every tool that does not manage its own updates is
# compared against the latest upstream release and replaced only if it differs.
# The exceptions are gh and git (apt keeps them current) and claude code,
# opencode and herdr, which each self-update.
#
# Output: only progress lines are printed. Everything a command writes goes to
# a log file, which is named for you if a step fails.

set -euo pipefail

# ---------------------------------------------------------------- logging ---

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

LOG="/tmp/install_ubuntu-$(date +%Y%m%d-%H%M%S).log"

# Anything that fails outside run() still points at the log rather than
# vanishing with a bare non-zero exit.
trap 'warn "Aborted. Full output: $LOG"' ERR

# Run a command with its output captured in $LOG instead of on screen. Builds,
# dpkg and apt are all noisy and none of it matters until something breaks - at
# which point the tail is printed and the log named.
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

# Latest release version for a GitHub repo, leading "v" stripped:
# BurntSushi/ripgrep -> 14.1.1, tmux/tmux -> 3.5a
gh_latest_version() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1
}

# First version-looking number in a tool's own --version output, or empty if it
# is not installed. No two of these agree on a format - btop even wraps it in
# ANSI codes - so match the number rather than a fixed field.
#   tool_version <command...>
tool_version() {
  "$@" 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?[a-z]*' | head -1 || true
}

# Whether a tool needs installing: either absent, or not on the latest release.
# Returns 0 to install, 1 to skip.
#
# Replacing a .deb or a single binary leaves nothing of the old version behind,
# so only the installs shaped like a directory - neovim, btop's themes - delete
# first, and they do it inline below.
#   needs_install <name> <installed version> <latest version>
needs_install() {
  local name="$1" current="$2" latest="$3"

  if [ -z "$latest" ]; then
    warn "Could not look up the latest $name release - leaving it alone"
    return 1
  elif [ -z "$current" ]; then
    info "$name is not installed - installing $latest"
    return 0
  elif [ "$current" = "$latest" ]; then
    info "$name $current is already the latest - skipping"
    return 1
  else
    info "$name $current is out of date - replacing with $latest"
    return 0
  fi
}

# True if an apt source for this host is already configured anywhere. Matching
# on content rather than filename matters: a repo added by an older installer
# under a different filename, or with its key in /usr/share/keyrings, still
# counts - adding a second entry makes apt fail with a Signed-By conflict.
#   apt_source_exists <host or path fragment>
apt_source_exists() {
  grep -rqs -- "$1" /etc/apt/sources.list /etc/apt/sources.list.d/
}

# Add a line to whichever shell rc files exist, once. The shell is not assumed
# to be zsh or bash, and some lines differ between them (fzf), so a second
# argument overrides the line used for zsh.
# ensure_rc_line <line> [zsh line]
ensure_rc_line() {
  local bash_line="$1" zsh_line="${2:-$1}" rc line

  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -e "$rc" ] || continue      # that shell isn't set up on this machine
    case "$rc" in
      *.bashrc) line="$bash_line" ;;
      *.zshrc)  line="$zsh_line" ;;
    esac

    if grep -qxF "$line" "$rc"; then
      info "$rc already has: $line"
    elif [ -L "$rc" ]; then
      # Appending would edit the repo itself and show up as a tracked change.
      warn "$rc is a symlink - add this line to it at the source:"
      warn "  $line"
    else
      info "Adding to $rc: $line"
      printf '\n%s\n' "$line" >> "$rc"
    fi
  done
}

# ------------------------------------------------------------------ setup ---
#
# Both of these are needed by more than one section below, so they run once
# here instead of being repeated. The symlinks below assume this repo is
# cloned to ~/dotfiles.

info "Updating apt package lists"
run sudo apt update

mkdir -p ~/.config    # ln won't create parents; -p is a no-op if it exists

# ================================================================== neovim ===
#
# apt's neovim is too old - nvim/lua/plugins/lsp/init.lua calls vim.lsp.config,
# which needs 0.11+. Use the official release tarball instead.

NVIM_DIR=/opt/nvim-linux-x86_64

# Check the binary we manage rather than whatever `nvim` resolves to, so an
# apt-installed copy elsewhere on PATH can't make this look up to date.
if needs_install neovim \
     "$(tool_version "$NVIM_DIR/bin/nvim" --version)" \
     "$(gh_latest_version neovim/neovim)"; then

  # Download into a temp dir so the tarball doesn't land in the repo.
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/nvim-linux-x86_64.tar.gz" \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  # Unpacking over the old tree would leave files from the previous version
  # behind, so clear it out first.
  run sudo rm -rf "$NVIM_DIR"
  run sudo tar -C /opt -xzf "$tmp/nvim-linux-x86_64.tar.gz"
  rm -rf "$tmp"
fi

# Put nvim on PATH for whichever shells are set up here.
ensure_rc_line "export PATH=\"\$PATH:$NVIM_DIR/bin\""

export PATH="$PATH:$NVIM_DIR/bin"

info "Linking ~/dotfiles/nvim -> ~/.config/nvim"
ln -sfn ~/dotfiles/nvim ~/.config/nvim    # -f replaces an old link, -n avoids linking inside it

# ================================================================ lazygit ===
#
# lazygit only reached the Ubuntu repos in 24.10, so take the release tarball
# instead - that works on every release. This is lazygit's own documented
# install method.

# The asset filename carries the version, so /releases/latest/download/ can't
# be used the way it can for neovim - ask the API for the tag first.
LAZYGIT_LATEST="$(gh_latest_version jesseduffield/lazygit)"

if needs_install lazygit "$(tool_version lazygit --version)" "$LAZYGIT_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_LATEST}/lazygit_${LAZYGIT_LATEST}_Linux_x86_64.tar.gz"
  run tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  run sudo install -m 755 "$tmp/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmp"
fi

# =================================================================== tmux ===
#
# tmux ships source tarballs only - there are no official binaries - so the
# latest release means compiling it. The build is the noisiest thing here; -q
# and -s keep it quiet, and the log has the rest.

TMUX_LATEST="$(gh_latest_version tmux/tmux)"

if needs_install tmux "$(tool_version tmux -V)" "$TMUX_LATEST"; then
  info "Installing build dependencies"
  run sudo apt install -y build-essential bison pkg-config libevent-dev libncurses-dev

  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/tmux.tar.gz" \
    "https://github.com/tmux/tmux/releases/download/${TMUX_LATEST}/tmux-${TMUX_LATEST}.tar.gz"
  run tar -xzf "$tmp/tmux.tar.gz" -C "$tmp"
  info "Compiling tmux $TMUX_LATEST (this takes a minute)"
  run bash -c "cd '$tmp/tmux-${TMUX_LATEST}' && ./configure -q && make -s -j$(nproc) && sudo make install"
  rm -rf "$tmp"
fi

info "Linking ~/dotfiles/tmux -> ~/.config/tmux"
ln -sfn ~/dotfiles/tmux ~/.config/tmux

# ================================================================= zoxide ===
#
# zoxide, ripgrep, bat and delta all publish a .deb on their release pages,
# which is always ahead of the one in the Ubuntu repos. dpkg -i replaces the
# installed package, so there is nothing to remove first.

ZOXIDE_LATEST="$(gh_latest_version ajeetdsouza/zoxide)"

if needs_install zoxide "$(tool_version zoxide --version)" "$ZOXIDE_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/zoxide.deb" \
    "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_LATEST}/zoxide_${ZOXIDE_LATEST}-1_amd64.deb"
  run sudo dpkg -i "$tmp/zoxide.deb"
  rm -rf "$tmp"
fi

# zoxide is a shell function, not just a binary - without this there is no `z`.
ensure_rc_line 'eval "$(zoxide init bash)"' 'eval "$(zoxide init zsh)"'

# ================================================================ ripgrep ===

RIPGREP_LATEST="$(gh_latest_version BurntSushi/ripgrep)"

if needs_install ripgrep "$(tool_version rg --version)" "$RIPGREP_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/ripgrep.deb" \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_LATEST}/ripgrep_${RIPGREP_LATEST}-1_amd64.deb"
  run sudo dpkg -i "$tmp/ripgrep.deb"
  rm -rf "$tmp"
fi

# ==================================================================== bat ===
#
# Upstream's .deb installs the binary as `bat`, so the batcat shim the Ubuntu
# package needs is not required here.

BAT_LATEST="$(gh_latest_version sharkdp/bat)"

if needs_install bat "$(tool_version bat --version)" "$BAT_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/bat.deb" \
    "https://github.com/sharkdp/bat/releases/download/v${BAT_LATEST}/bat_${BAT_LATEST}_amd64.deb"
  run sudo dpkg -i "$tmp/bat.deb"
  rm -rf "$tmp"
fi

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
#
# jq's asset name carries no version, so it can be fetched by /latest/download.
# Its tags read jq-1.8.2 rather than v1.8.2, so trim the prefix to compare.

JQ_LATEST="$(gh_latest_version jqlang/jq)"
JQ_LATEST="${JQ_LATEST#jq-}"

if needs_install jq "$(tool_version jq --version)" "$JQ_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/jq" \
    https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64
  run sudo install -m 755 "$tmp/jq" /usr/local/bin/jq
  rm -rf "$tmp"
fi

# ==================================================================== fzf ===
#
# Upstream is far ahead of both LTS releases - notably `fzf --zsh` (0.48+) and
# `--tmux` (0.53+), neither of which the Ubuntu package has.

FZF_LATEST="$(gh_latest_version junegunn/fzf)"

if needs_install fzf "$(tool_version fzf --version)" "$FZF_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/fzf.tar.gz" \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_LATEST}/fzf-${FZF_LATEST}-linux_amd64.tar.gz"
  run tar -xzf "$tmp/fzf.tar.gz" -C "$tmp" fzf
  run sudo install -m 755 "$tmp/fzf" /usr/local/bin/fzf
  rm -rf "$tmp"
fi

# Shell integration: Ctrl-R history, Ctrl-T files, Alt-C cd, ** completion.
# `fzf --bash` and `fzf --zsh` are 0.48+, so the apt build cannot do this.
ensure_rc_line 'eval "$(fzf --bash)"' 'eval "$(fzf --zsh)"'

# =================================================================== btop ===
#
# The release tarball has no version in its name, so /latest/download/ works.
# It unpacks to btop/bin/btop plus a themes directory; the binary is installed
# by hand rather than via the bundled make target, which would need build tools.

BTOP_LATEST="$(gh_latest_version aristocratos/btop)"

if needs_install btop "$(tool_version btop --version)" "$BTOP_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/btop.tar.gz" \
    https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-unknown-linux-musl.tar.gz
  run tar -xzf "$tmp/btop.tar.gz" -C "$tmp"
  run sudo install -m 755 "$tmp/btop/bin/btop" /usr/local/bin/btop
  # Themes are a directory, so clear the old set out rather than copying over
  # it and leaving themes that upstream has since dropped.
  run sudo rm -rf /usr/local/share/btop/themes
  run sudo mkdir -p /usr/local/share/btop
  run sudo cp -r "$tmp/btop/themes" /usr/local/share/btop/
  rm -rf "$tmp"
fi

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
#
# eza is absent from the Ubuntu repos before 25.04. The release tarball carries
# no version in its name, so it can be fetched by /latest/download/.

EZA_LATEST="$(gh_latest_version eza-community/eza)"

if needs_install eza "$(tool_version eza --version)" "$EZA_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/eza.tar.gz" \
    https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
  run tar -xzf "$tmp/eza.tar.gz" -C "$tmp" ./eza
  run sudo install -m 755 "$tmp/eza" /usr/local/bin/eza
  rm -rf "$tmp"
fi

info "Linking ~/dotfiles/eza -> ~/.config/eza"
ln -sfn ~/dotfiles/eza ~/.config/eza

ensure_rc_line "alias eza='eza -la --git --header --git-repos'"

# ================================================================== delta ===
#
# git-delta only reached the Ubuntu repos in 24.04. The .deb on the release
# page is newer and works on every release.

DELTA_LATEST="$(gh_latest_version dandavison/delta)"

if needs_install delta "$(tool_version delta --version)" "$DELTA_LATEST"; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/git-delta.deb" \
    "https://github.com/dandavison/delta/releases/download/${DELTA_LATEST}/git-delta_${DELTA_LATEST}_amd64.deb"
  run sudo dpkg -i "$tmp/git-delta.deb"
  rm -rf "$tmp"
fi

# ===================================================================== gh ===
#
# gh is absent from the 22.04 repos and frozen at whatever shipped with 24.04,
# so use GitHub's own apt repo - their documented install method. apt keeps it
# current from then on, so no version check is needed here.

if apt_source_exists cli.github.com; then
  info "GitHub CLI apt repository already configured - skipping"
else
  info "Adding the GitHub CLI apt repository"
  run sudo mkdir -p -m 755 /etc/apt/keyrings
  run bash -c 'curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null'
  run sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  run bash -c "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null"
  run sudo apt update    # the repo just added is not in the lists from setup yet
fi

info "Installing gh"
run sudo apt install -y gh    # upgrades in place when the repo has something newer

# ==================================================================== git ===
#
# Ubuntu's git trails upstream by a release or two. ppa:git-core/ppa is the
# Ubuntu Git Maintainers' own archive and tracks the latest release, and apt
# keeps it current from then on.

if apt_source_exists git-core/ppa; then
  info "git-core PPA already configured - skipping"
else
  info "Adding the git-core PPA"
  run sudo apt install -y software-properties-common    # provides add-apt-repository
  run sudo add-apt-repository -y ppa:git-core/ppa       # runs apt update itself
fi

info "Installing git"
run sudo apt install -y git

# git reads ~/.config/git/config natively, so this needs no extra wiring. It is
# what points core.pager at delta.
info "Linking ~/dotfiles/git -> ~/.config/git"
ln -sfn ~/dotfiles/git ~/.config/git

# ====================================================== AI agentic tools ===
#
# claude code, opencode and herdr are all self-updating, and each ships its own
# installer that agrees with its updater - herdr's reads the same latest.json
# that `herdr update` does. Pinning them to a GitHub release would drift the
# moment they update themselves, so use the vendor installers and let them
# manage their own versions. Re-running an installer is how they upgrade.
#
# All three default to installing in ~/.local/bin, which is not on PATH in
# either shell by default: Ubuntu wires it up in ~/.profile, which zsh never
# reads and bash reads only for login shells.

ensure_rc_line 'export PATH="$HOME/.local/bin:$PATH"'

export PATH="$HOME/.local/bin:$PATH"    # and for the rest of this run

# --- claude code -----------------------------------------------------------

info "Installing claude code"
run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'

# ~/.claude also holds sessions, history and projects, so link the two config
# files rather than the directory - a directory link would hide all of that.
mkdir -p ~/.claude
info "Linking ~/dotfiles/claude/settings.local.json -> ~/.claude/settings.local.json"
ln -sfn ~/dotfiles/claude/settings.local.json ~/.claude/settings.local.json
info "Linking ~/dotfiles/claude/statusline.sh -> ~/.claude/statusline.sh"
ln -sfn ~/dotfiles/claude/statusline.sh ~/.claude/statusline.sh

# --- opencode --------------------------------------------------------------

info "Installing opencode"
run bash -c 'curl -fsSL https://opencode.ai/install | bash'

# ~/.config/opencode also holds agents/, commands/, plugins/, themes/ and
# tui.json, so link the config file only - same reasoning as ~/.claude.
mkdir -p ~/.config/opencode
info "Linking ~/dotfiles/opencode/opencode.json -> ~/.config/opencode/opencode.json"
ln -sfn ~/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json

# --- herdr -----------------------------------------------------------------

info "Installing herdr"
run bash -c 'curl -fsSL https://herdr.dev/install | bash'

# ~/.config/herdr also holds sockets, logs and session.json - link the config
# file only, for the same reason as ~/.claude above.
mkdir -p ~/.config/herdr
info "Linking ~/dotfiles/herdr/config.toml -> ~/.config/herdr/config.toml"
ln -sfn ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml

trap - ERR
info "All done. Full output: $LOG"
