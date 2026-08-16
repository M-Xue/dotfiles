return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		start_in_insert = true,
		persist_mode = true,
		insert_mappings = true,
		terminal_mappings = true,
		highlights = {
			FloatBorder = {
				guifg = "#8087a2",
				-- guifg = "#939ab7",
			},
		},
		float_opts = {
			-- border = "none",
			border = "single",
			width = function()
				return math.floor(vim.o.columns * 0.9)
			end,
			height = function()
				return math.floor(vim.o.lines * 0.85)
			end,
		},
	},
}
