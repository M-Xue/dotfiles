# My NeoVim Configuration

## TL;DR

NeoVim sucks dont use it ive wasted so much time im in despair

## Dependencies

### Git
- Git 
- LazyGit

### Go 
- Go toolchain (`go`)
- Delve and gotestsum are installed by mason (`delve`, `gotestsum`)

### JavaScript / TypeScript
- Node (vscode-js-debug is installed by mason as `js-debug-adapter`)
- Jest, Vitest or Playwright in the project being tested. The neotest adapters run the project's own
  `node_modules/.bin/{jest,vitest,playwright}`. Which adapter owns a file is decided in
  `lua/plugins/neotest/paths.lua`: files under `e2e/`, `e2e-tests/`, `playwright/` or `__e2e__/` go to
  playwright, everything else to vitest (if the package depends on vitest) or jest.

### Rust 
- Rust 

## Features

### Core

Core handles basic functionality you would expect from a code editor. 

This includes: 

- File tree (nvim-tree)
- LSP 
    - This is for diagnostics, like errors and warnings, as well as autocomplete and allowing you to jump around your project to see where functions are called etc.
    - This works in tandem with cmp.nvim which is just what handles the autocomplete. There is also another plugin called LuaSnips and this feeds cmp.nvim snippets (LSP only provides basic autocomplete)
- Debugger (nvim-dap + nvim-dap-ui, `<leader>d`)
- Test runner (neotest with jest, vitest, playwright and go adapters, `<leader>a`)
- Fuzzy finder (telescope)
- Syntax highlighting and analysis (treesitter)
    - This just provides better syntax highlighting over NeoVim's default capability and also lets you jump around the syntax tree (e.g., go to the next function or for loop etc)
- Terminal (toggleterm)
    - This just allows you to pull up a terminal in your NeoVim (similar to how you can have a terminal below your code file in VSCode)
- Git workflow 
    - Git workflow is handled by gitsigns, vim-fuGITive and LazyGit

And more.

### Misc 

Misc is a collection of helpful quality of life features that are not super necessary for writing code but help a lot. They are grouped in folders that describe their general purpose. 

These are: 

- **Editing**: a collection of plugins that help with edition, such as commenting or automatically adding the corresponding closing bracket when you type an opening bracket
- **LSP**: this is just for some additional helpful features that work together with the LSP functionality form core 
- **Motions**: a collection of plugins that help with moving around your windows and project 
- **UI**: these plugins alter the UI for some helpful information, such as line indenting signs or winbars

## Keymaps

There are a bunch of custom keymaps in the ~/lua/keymaps.lua file. There are also a few in ~/lua/plugins/core/tooling/lsp/handlers.lua that activate when you open a buffer.

## Options and Start Up Autocommands

In ~/lua/options.lua, there are a bunch of native vim options being set as well as an autocommand that runs when you first open NeoVim.
