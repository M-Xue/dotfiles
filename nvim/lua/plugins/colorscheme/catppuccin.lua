return {
	flavour = "macchiato", -- latte, frappe, macchiato, mocha
	show_end_of_buffer = true,
	styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
		comments = { "italic" }, -- Change the style of comments
	},
	integrations = {
		cmp = true,
		nvimtree = true,
		gitsigns = true,
		treesitter = true,
		alpha = true,
		mason = true,
	},
}
