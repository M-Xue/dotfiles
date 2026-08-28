local gitsigns = require("gitsigns")

vim.keymap.set("n", "<leader>hh", ":LazyGit<cr>", { desc = "Open LazyGit" })

-- Hunks
vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Toggle stage hunk" })
vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset buffer" })
vim.keymap.set("n", "<leader>hj", gitsigns.next_hunk, { desc = "Next hunk" })
vim.keymap.set("n", "<leader>hk", gitsigns.prev_hunk, { desc = "Prev hunk" })
vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk_inline, { desc = "Preview hunk" })

-- Permalink
vim.keymap.set({ "n", "v" }, "<leader>hL", ":.GBrowse master:%", { desc = "Open permalink in remote" })

-- Diffs
local function toggle_diffview()
	if next(require("diffview.lib").views) == nil then
		vim.cmd("DiffviewOpen")
	else
		vim.cmd("DiffviewClose")
	end
end
vim.keymap.set("n", "<leader>hd", toggle_diffview, { desc = "Diff index" })
vim.keymap.set("n", "<leader>hm", ":DiffviewOpen origin/master...HEAD<cr>", { desc = "Diff merge base" })

-- Blame
vim.keymap.set("n", "<leader>hb", gitsigns.blame_line, { desc = "Blame line" })

-- Git history
vim.keymap.set(
	"n",
	"<leader>hl",
	":Telescope advanced_git_search diff_commit_line<cr>",
	{ desc = "Git commit history for line" }
)
vim.keymap.set(
	"n",
	"<leader>hf",
	":Telescope advanced_git_search diff_commit_file<cr>",
	{ desc = "Git commit history for file" }
)
vim.keymap.set("n", "<leader>ho", ":DiffviewFileHistory<cr>", { desc = "Git log" })
vim.keymap.set("n", "<leader>hO", function()
	Snacks.picker.git_log()
end, { desc = "Git log checkout" })
