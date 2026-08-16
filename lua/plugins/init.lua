local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	require("plugins.snacks"),
	require("plugins.colorscheme"),
	require("plugins.mason"),

	require("plugins.autocomplete"),
	require("plugins.treesitter"),
	require("plugins.lsp"),

	require("plugins.formatter"),
	require("plugins.linter"),

	require("plugins.terminal"),

	require("plugins.trouble"),
	require("plugins.harpoon"),
	require("plugins.numb"),

	require("plugins.telescope"),
	require("plugins.git"),

	require("plugins.statusline"),
	require("plugins.icons"),

	require("plugins.alpha"),
	require("plugins.tabby"),
	require("plugins.indent-blankline"),

	require("plugins.textobjects"),
	require("plugins.parentheses"),
	require("plugins.comments"),
	require("plugins.help"),

	{
		"RRethy/vim-illuminate", -- Highlight other uses of the word under the cursor
		event = "VeryLazy",
	},
	{
		"unblevable/quick-scope", -- Unqiue character highlight
		event = "VeryLazy",
	},
}

require("lazy").setup(plugins)
