#!/usr/bin/env bash
#
# Builds the `branch` CLI from this checkout and installs it so that typing
# `branch` works in bash and zsh on Linux and macOS.
#
#   ./install.sh                 # installs to ~/.local/bin
#   BIN_DIR=/usr/local/bin ./install.sh
#
set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NAME="branch"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1m%s\033[0m\n' "$*"; }
die()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

case "$(uname -s)" in
  Linux|Darwin) ;;
  *) die "unsupported OS: $(uname -s) (Linux and macOS only)" ;;
esac

command -v go >/dev/null 2>&1 || die "Go is required but was not found. Install it from https://go.dev/dl/ and re-run."
[ -f "$SRC_DIR/go.mod" ] && [ -f "$SRC_DIR/main.go" ] || die "run this script from the project directory (go.mod not found in $SRC_DIR)"

info "Building $NAME..."
mkdir -p "$BIN_DIR"
(cd "$SRC_DIR" && CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o "$BIN_DIR/$NAME" .)
chmod +x "$BIN_DIR/$NAME"
info "Installed $BIN_DIR/$NAME"

# Make sure BIN_DIR is on PATH for bash and zsh.
# Write $HOME literally when BIN_DIR lives under it, so the rc line stays portable.
case "$BIN_DIR" in
  "$HOME"/*) rc_dir="\$HOME${BIN_DIR#"$HOME"}" ;;
  *)         rc_dir="$BIN_DIR" ;;
esac
path_line="export PATH=\"$rc_dir:\$PATH\""
marker="# added by $NAME install.sh"
added_to=()

add_to_rc() {
  local rc="$1"
  # Only touch files that exist, except we always create the primary ones.
  if [ ! -f "$rc" ] && [ "${2:-}" != "create" ]; then
    return
  fi
  if [ -f "$rc" ] && grep -Fq "$marker" "$rc"; then
    return
  fi
  printf '\n%s\n%s\n' "$marker" "$path_line" >> "$rc"
  added_to+=("$rc")
}

case ":$PATH:" in
  *":$BIN_DIR:"*) on_path=1 ;;
  *)              on_path=0 ;;
esac

if [ "$on_path" -eq 0 ]; then
  add_to_rc "$HOME/.bashrc" create
  add_to_rc "$HOME/.zshrc" create
  # macOS Terminal opens bash as a login shell, which reads .bash_profile.
  add_to_rc "$HOME/.bash_profile"
  add_to_rc "$HOME/.profile"
  add_to_rc "$HOME/.zprofile"
fi

echo
if [ "$on_path" -eq 1 ]; then
  info "Done. Type '$NAME' inside any git repository to use it."
else
  info "Done. Added $BIN_DIR to PATH in: ${added_to[*]:-<already configured>}"
  echo "Open a new terminal, or run this in the current one:"
  echo
  echo "  $path_line"
  echo
  echo "Then type '$NAME' inside any git repository."
fi

# Forget any previously cached location of the command in this shell.
hash -r 2>/dev/null || true
