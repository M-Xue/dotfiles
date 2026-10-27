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
| type | filter |
| Tab / ↓ | next (wraps) |
| Shift-Tab / ↑ | previous (wraps) |
| Enter | quit and run `git switch` on the branch, printing git's usual output |
| Esc | quit |

`*` green = current branch, `+` cyan = checked out in another worktree.
