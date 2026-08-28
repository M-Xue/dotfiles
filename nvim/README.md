# My NeoVim Configuration

## TL;DR

NeoVim sucks dont use it ive wasted so much time im in despair

## Dependencies

### Git
- Git 
- LazyGit

### Go 
- Delve

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
- Debugger (dap)
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
