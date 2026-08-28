-- Find files
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Search buffers" })

vim.keymap.set("n", "<leader>fr", function()
	Snacks.picker.registers()
end, { desc = "Search registers" })

vim.keymap.set("n", "<leader>fl", function()
	Snacks.picker.lines()
end, { desc = "Search buffer lines" })

vim.keymap.set("n", "<leader>fm", function()
	Snacks.picker.marks()
end, { desc = "Search marks" })

vim.keymap.set("n", "<leader>fG", function()
	Snacks.picker.grep()
end, { desc = "Grep" })

vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.git_status()
end, { desc = "Grep" })

-- File tree
vim.keymap.set("n", "<leader>yy", function()
	Snacks.explorer()
end, { noremap = true, desc = "Toggle file tree" })

-- Outline
vim.keymap.set("n", "<leader>oo", ":Outline<cr>", { desc = " Symbol Outline" })
vim.keymap.set("n", "<leader>of", ":OutlineFocus<cr>", { desc = " Focus Outline" })
vim.keymap.set("n", "<leader>oc", ":OutlineFocusCode<cr>", { desc = " Focus Code" })
vim.keymap.set("n", "<leader>or", ":OutlineRefresh<cr>", { desc = " Refresh symbols" })

-- Window Movement
vim.keymap.set("n", "<leader>ss", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })

vim.keymap.set("n", "<leader>sd", "<C-w>l", { desc = "Move cursor to right window" })
vim.keymap.set("n", "<leader>sD", "<C-w>L", { desc = "Move window to far right" })
vim.keymap.set("n", "<leader>sa", "<C-w>h", { desc = "Move cursor to left window" })
vim.keymap.set("n", "<leader>sA", "<C-w>H", { desc = "Move window to far left" })
vim.keymap.set("n", "<leader>sx", "<C-w>j", { desc = "Move cursor to window below" })
vim.keymap.set("n", "<leader>sX", "<C-w>J", { desc = "Move window to bottom" })
vim.keymap.set("n", "<leader>sw", "<C-w>k", { desc = "Move cursor to window above" })
vim.keymap.set("n", "<leader>sW", "<C-w>K", { desc = "Move window to top" })

vim.keymap.set("n", "<leader>sr", "<C-w>x", { desc = "Swap window with next" })
vim.keymap.set("n", "<leader>st", "<C-w>T", { desc = "Open new tab with window" })
vim.keymap.set("n", "<leader>s=", "<C-w>=", { desc = "Make all windows equal size" })
vim.keymap.set("n", "<leader>sq", ":close<cr>", { desc = "Close window" })

-- Tab Movement
vim.keymap.set("n", "<leader>kk", ":tabnew %<CR>", { desc = "Create new tab" })
vim.keymap.set("n", "<leader>kq", ":tabc<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>kl", ":tabn<CR>", { desc = "Move to next tab" })
vim.keymap.set("n", "<leader>kj", ":tabp<CR>", { desc = "Move to prev tab" })

-- Window Resize
-- Source: https://www.reddit.com/r/neovim/comments/10wru1c/how_do_i_resize_windows/
vim.keymap.set("n", "=", [[<cmd>vertical resize +5<cr>]]) -- make the window biger vertically
vim.keymap.set("n", "-", [[<cmd>vertical resize -5<cr>]]) -- make the window smaller vertically
vim.keymap.set("n", "+", [[<cmd>horizontal resize +2<cr>]]) -- make the window bigger horizontally by pressing shift and =
vim.keymap.set("n", "_", [[<cmd>horizontal resize -2<cr>]]) -- make the window smaller horizontally by pressing shift and -
