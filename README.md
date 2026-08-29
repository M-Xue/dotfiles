# dotfiles

This repo contains my dotfiles configurations. 

## Tools

The technologies I use (not all have configurations) are:

General
- nvim: text editor
- ghostty: terminal emulator
- oh my zsh: advanced zsh configuration
- tmux: terminal multiplexer that lets you  manage multiple terminal sessions
- gh: GitHub CLI (stacked PRs)

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

## Set up

Some of these tools require their configurations in specific paths relative to 
your root directory. The `install.sh` script will apply simlinks to all folders 
and files and place them in the correct location.

**This requires the repo to be placed in the root repository because the script 
uses absolute paths.**

The script will also install all the relevant programs using the package manager 
associated with your OS. Homebrew for MacOS. `sudo apt` for Ubuntu. Some 
programs will also be directly cloned from GitHub, as per their offical 
installation instructions.

You can run `install.sh` again to get the latest versions or get any new tools.

## Misc

### Future considered tools

- fd: improved find
- fzf: fuzzy finder for files, command history, git branches
- tig: alternative git history browser, more minimal
- jq: command-line tool for working with JSON

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
