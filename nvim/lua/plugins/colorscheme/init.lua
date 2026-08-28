return {
	{
		"catppuccin/nvim",
		priority = 1000,
		lazy = false,
		config = function()
			local opts = require("plugins.colorscheme.catppuccin")
			require("catppuccin").setup(opts)
		end,
	},
}
