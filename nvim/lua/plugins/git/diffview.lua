-- :DiffviewOpen origin/main...HEAD
-- Use git merge-base [feature-branch] [master or main] to get the commit hash 
-- Use git merge-base [name of feature branch] [master or main] to get the commit hash 
-- and then :DiffviewOpen [commit hash] 
return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		config = function()
			local diffview = require("diffview")
			diffview.setup({
				enhanced_diff_hl = true,
				file_panel = {
					win_config = {
						position = "right",
						width = 45,
					},
				},
			})
			vim.opt.fillchars:append({ diff = "╱" })
		end,
	},
}
