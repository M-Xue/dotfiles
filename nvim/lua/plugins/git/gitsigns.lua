local M = {}

M.guttersigns_bar = {
	add = { text = "▎" },
	change = { text = "▎" },
	untracked = { text = "▎" },
	delete = { text = "" },
	topdelete = { text = "" },
	changedelete = { text = "▎" },
}

-- cool icon: ┃

M.guttersigns_default = {
	add = { text = "+" },
	change = { text = "|" },
	untracked = { text = "┆" },
	delete = { text = "" },
	topdelete = { text = "" },
	changedelete = { text = "|" },
}

M.guttersigns_text = {
	add = { text = "+" },
	change = { text = "~" },
	untracked = { text = "~" },
	delete = { text = "" },
	topdelete = { text = "" },
	changedelete = { text = "-" },
}

M.config = {
	signs = M.guttersigns_default,
	-- staged signs: https://github.com/lewis6991/gitsigns.nvim?tab=readme-ov-file#installation--usage
	signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
	numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
	linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
	word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
	watch_gitdir = {
		interval = 1000,
		follow_files = true,
	},
	attach_to_untracked = true,
	current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
		delay = 1000,
		ignore_whitespace = false,
	},
	current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	max_file_length = 40000, -- Disable if file is longer than this (in lines)
	preview_config = {
		-- Options passed to nvim_open_win
		border = "single",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},
	-- yadm = {
	-- 	enable = false,
	-- },
}

M.plugin = {
	"lewis6991/gitsigns.nvim",
	config = function()
		local gitsigns = require("gitsigns")
		gitsigns.setup(M.config)
	end,
    event = "BufEnter",
}
return M
