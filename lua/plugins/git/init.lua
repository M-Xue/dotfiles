return {
	require("plugins.git.gitsigns").plugin,
	require("plugins.git.lazygit"),
	require("plugins.git.diffview"),
	{
		"aaronhallaert/advanced-git-search.nvim",
		event = "BufEnter",
	},
	{
		"tpope/vim-fugitive",
		event = "BufEnter",
	},
	{
		"tpope/vim-rhubarb",
		event = "BufEnter",
	},
}
