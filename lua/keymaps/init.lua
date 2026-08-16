local _util = require("_util")

vim.keymap.set("n", "<leader>.", _util.print_attached_clients, { desc = "See attached clients" })

vim.keymap.set("v", "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>`", ":wa<CR>:qa<CR>", { desc = "Quit NeoVim" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>q", ":bd<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>p", ":Trouble qflist toggle<CR>", { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>?", ":Cheatsheet<CR>", { desc = "Cheatsheet" })
vim.keymap.set("n", "<leader>c", ":cd ", { desc = "Change directory" })
vim.keymap.set("n", "<leader>u", ":UndotreeToggle<cr>", { desc = "Undo tree" })

vim.keymap.set("v", "<leader>F", require("conform").format, { desc = "Format selection" })

-- Indenting
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })

-- This will remove all diagnostics so you need to do some text action to get them back
vim.keymap.set(
	"n",
	"<leader>,",
	require("plugins.linter.nvim-lint").toggle_spell_check,
	{ desc = "Toggle spell check linter" }
)

-- LSP
-- g: LSP
-- e: Diagnostics
require("keymaps.git")
require("keymaps.navigation")
require("keymaps.harpoon")
require("keymaps.terminal")
