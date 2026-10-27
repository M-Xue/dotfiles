# branch

Interactive `git branch` switcher.

## Install

Requires Go.

```sh
./install.sh
```

Builds to `~/.local/bin/branch` and adds it to PATH for bash and zsh. Rerun to update. Set `BIN_DIR` to install elsewhere.

## Usage

```sh
branch
```

| Key | Action |
| --- | --- |
| type | fuzzy filter (case-insensitive), best match first |
| Tab / ↓ | next (wraps) |
| Shift-Tab / ↑ | previous (wraps) |
| Enter | quit and run `git switch` on the branch, printing git's usual output |
| Ctrl-D | quit and run `git branch -d` on the branch |
| Shift-D | quit and run `git branch -D` (force delete) on the branch |
| Esc | quit |

`*` green = current branch, `+` cyan = checked out in another worktree.

Branches are listed most recently checked out first (from HEAD's reflog), with the current branch on top.
