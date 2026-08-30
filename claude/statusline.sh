#!/usr/bin/env bash
# Claude Code status line.
# Receives a JSON payload on stdin; prints a single line to stdout.

input=$(cat)

# --- colors (24-bit truecolor) ---
RESET=$'\033[0m'
C_TEXT=$'\033[38;2;202;211;245m'    # #cad3f5 (path + model)
C_GIT=$'\033[38;2;245;169;127m'     # #f5a97f
C_ADD=$'\033[38;2;166;218;149m'     # #a6da95
C_DEL=$'\033[38;2;237;135;150m'     # #ed8796
C_SEP=$'\033[38;2;91;96;120m'       # #5b6078
C_EFFORT=$'\033[38;2;244;219;214m'  # #f4dbd6
C_CTX=$'\033[38;2;238;212;159m'     # #eed49f

# separator between top-level sections
sep() { printf ' %s│%s ' "$C_SEP" "$RESET"; }

# --- section: current working directory (home collapsed to ~) ---
dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
[ -z "$dir" ] && dir="$PWD"
cwd="$dir"
case "$cwd" in
  "$HOME") cwd="~" ;;
  "$HOME"/*) cwd="~${cwd#"$HOME"}" ;;
esac

printf '%s%s%s' "$C_TEXT" "$cwd" "$RESET"

# --- section: git branch (omitted outside a repo) ---
branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) \
  || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  printf ' %s(%s)%s' "$C_GIT" "$branch" "$RESET"

  # --- section: lines added/deleted vs HEAD (staged + unstaged) ---
  numstat=$(git -C "$dir" diff --numstat HEAD 2>/dev/null) \
    || numstat=$(git -C "$dir" diff --numstat --cached 2>/dev/null)
  # binary files report "-" instead of a count, so only sum numeric fields
  read -r added deleted <<<"$(
    awk '$1 ~ /^[0-9]+$/ { a += $1 } $2 ~ /^[0-9]+$/ { d += $2 } END { print a+0, d+0 }' <<<"$numstat"
  )"
  if [ "$added" -gt 0 ] || [ "$deleted" -gt 0 ]; then
    printf ' '
    [ "$added" -gt 0 ] && printf '%s+%s%s' "$C_ADD" "$added" "$RESET"
    [ "$deleted" -gt 0 ] && printf '%s-%s%s' "$C_DEL" "$deleted" "$RESET"
  fi
fi

sep

# --- section: current model ---
model=$(jq -r '.model.display_name // .model.id // empty' <<<"$input")
printf '%s%s%s' "$C_TEXT" "$model" "$RESET"

# --- section: reasoning effort (only sent for models that support it) ---
effort=$(jq -r '.effort.level // empty' <<<"$input")
if [ -n "$effort" ]; then
  printf ' %s(%s)%s' "$C_EFFORT" "$effort" "$RESET"
fi

sep

# --- section: context window usage ---
CTX_CELLS=10
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
if [ -n "$pct" ]; then
  pct=$(printf '%.0f' "$pct")
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( pct * CTX_CELLS / 100 ))

  bar=''
  for ((i = 0; i < CTX_CELLS; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+='█'; else bar+='░'; fi
  done

  printf '%sContext%s %s%s %s%%%s' "$C_TEXT" "$RESET" "$C_CTX" "$bar" "$pct" "$RESET"
fi
