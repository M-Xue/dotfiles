# dotfiles

This repo contains my dotfiles configurations.

## Tools

The technologies I use (not all have configurations) are:

General

- nvim: text editor
- tmux: terminal multiplexer that lets you manage multiple terminal sessions
- fzf: fuzzy finder for files, command history, git branches
- jq: command-line tool for working with JSON
- gh: GitHub CLI (stacked PRs)
- ghostty: terminal emulator
- oh my zsh: advanced zsh configuration

TUI

- lazygit: interactive git tui
- btop: resource monitor for processor, memory, disks, network and processes

AI Agentic Tools

- herdr
- claude code
- opencode

Improved Tools

- zoxide: improved cd
- ripgrep: improved grep
- bat: improved cat
- delta: improved git diff
- eza: improved ls

Oh My Zsh Plugins

- zsh-autosuggestions
- zsh-syntax-highlighting
- powerlevel10k

## Set up for Ubuntu

Clone this repo to `~/dotfiles` - `install_ubuntu.sh` hardcodes that path - then
run `./install_ubuntu.sh`. It installs every tool listed above and symlinks the
configs into the paths each tool expects.

Run it again to update. Tools that do not update themselves (nvim, tmux,
lazygit, zoxide, ripgrep, bat, jq, fzf, btop, eza, delta) are checked against
the latest upstream release and replaced only if they are behind. gh and git are
left to apt; claude code, opencode and herdr manage their own updates.

ghostty is not installed on Ubuntu - there is no apt package for it.

## Set up for Mac

Clone this repo to `~/dotfiles` - `install_mac.sh` hardcodes that path - then run
`./install_mac.sh`. It installs Homebrew if missing, then every tool listed
above, and symlinks the configs into place.

Run it again to update. Everything comes from Homebrew, so `brew outdated`
decides what gets upgraded - there are no version checks of its own. claude
code, opencode and herdr use their own installers and manage their own updates.

## Zsh (not automated)

Neither script sets up the shell itself: oh my zsh, its plugins
(zsh-autosuggestions, zsh-syntax-highlighting, powerlevel10k) and `zsh/.zshrc`
all have to be installed and linked by hand.

They do append to `~/.bashrc` and `~/.zshrc` where those files already exist -
PATH entries, `zoxide init` and fzf shell integration. If `~/.zshrc` is ever
replaced by a symlink into this repo they warn instead of writing to it, so
those lines then belong in `zsh/.zshrc` at the source.

## Misc

### Future considered tools

- fd: improved find
- tig: alternative git history browser, more minimal

### In-built tools to learn (from Claude)

#### File & text searching

- grep — pattern search in files; grep -r "pattern" . searches recursively
- find — locate files by name, type, size, date; find . -name "*.log" -mtime -1
- which / type — find where a command lives or what it resolves to

#### Text processing

- sed — stream editor for find/replace; sed 's/foo/bar/g' file.txt
- awk — column-based text processing, mini scripting language; great for logs/CSVs
- cut — extract columns; cut -d',' -f1,3 file.csv
- sort / uniq — sort lines, dedupe; often combined: sort file.txt | uniq -c
- tr — translate/delete characters; tr 'a-z' 'A-Z'
- wc — word/line/byte counts; wc -l is the classic "how many lines"
- head / tail — first/last N lines; tail -f log.txt to watch a file live

#### Process & system inspection

- ps — list running processes; ps aux | grep node
- top — live process viewer (the original, before htop)
- kill / killall — terminate processes by PID or name
- lsof — list open files/ports; lsof -i :3000 to find what's using a port
- df — disk space usage
- du — disk usage per file/directory; du -sh * for sizes in current dir

#### Networking

- curl — HTTP requests, downloads
- ping — check connectivity
- netstat or ss — network connections/ports (ss is the modern replacement)
- ssh / scp — remote login and file copy

#### Permissions & file ops

- chmod / chown — change permissions/ownership
- ln -s — create symlinks
- tar — archive/compress; tar -xzvf file.tar.gz
- diff — compare files line by line

#### Shell essentials

- xargs — pass output of one command as arguments to another; find . -name "*.tmp" | xargs rm
- echo / printf — output text, useful for debugging scripts
- history — recall past commands
- man — read documentation for any command (man grep)

The one combo worth memorizing

grep, find, and xargs piped together solve an enormous fraction of "find/modify a bunch of files" problems, e.g.:

```bash
grep -rl "old_function_name" . | xargs sed -i '' 's/old_function_name/new_function_name/g'
```
