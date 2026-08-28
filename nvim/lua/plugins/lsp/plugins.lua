return {
	{
		"hedyhli/outline.nvim",
		event = "LspAttach",
		opts = {
			outline_window = {
				position = "right",
				width = 60,
				relative_width = false,
			},
			symbols = {
				icon_fetcher = function(kind, bufnr)
					return require("icons.lspkind").icons[kind]
				end,
			},
		},
	},
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},
	{
		"kosayoda/nvim-lightbulb",
		event = "LspAttach",
		opts = {
			autocmd = { enabled = true },
			-- ignore = {
			-- 	ft = { "NvimTree" },
			-- 	-- Ignore code actions without a `kind` like refactor.rewrite, quickfix.
			-- 	-- actions_without_kind = false,
			-- },
		},
	},
	{
		"SmiteshP/nvim-navic",
		event = "LspAttach",
		config = function()
			vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
			require("nvim-navic").setup({
				enabled = true,
				separator = " > ",
				highlight = true,
				depth_limit = 5,
				depth_limit_indicator = "..",
				lazy_update_context = true,
				icons = require("icons.lspkind").icons,
				format_text = function(text)
					return " " .. text
				end,
			})
		end,
	},
}
