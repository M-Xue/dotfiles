return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			picker = {
				layouts = {
					float = {
						layout = {
							backdrop = false,
							width = 0.5,
							min_width = 80,
							height = 0.8,
							min_height = 30,
							box = "vertical",
							border = true,
							title = "{title} {live} {flags}",
							title_pos = "center",
							{ win = "input", height = 1, border = "bottom" },
							{ win = "list", border = "none" },
						},
					},
				},
				formatters = {
					selected = {
						show_always = true,
						unselected = false,
					},
				},
				icons = {
					ui = {
						selected = " ",
					},
				},
				win = {
					input = {
						keys = {
							["<Tab>"] = { "list_down", mode = { "i", "n" } },
							["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
							["<Down>"] = { "select_and_next", mode = { "i", "n" } },
							["<Up>"] = { "select_and_prev", mode = { "i", "n" } },
						},
					},
				},
				-- auto_confirm = false,
				sources = {
					explorer = {
						focus = "list",
						auto_close = true,
						layout = "float",
						hidden = true,

						-- The list scrolls itself instead of letting Neovim do it, but it
						-- reads scrolloff off the window once on open and then clamps it to
						-- half the height. Anything large therefore means "always centred",
						-- rather than letting the entry sit on the last visible row.
						win = { list = { wo = { scrolloff = 999 } } },

						-- Path of whatever the cursor is on. The list window is minimal, so
						-- its winbar is free for this. on_change fires on every cursor move,
						-- with or without a preview window.
						on_change = function(picker, item)
							local list = picker.list
							if not (list and list.win and list.win:valid()) then
								return
							end
							local path = item and item.file and vim.fn.fnamemodify(item.file, ":~:.") or ""
							-- % is a statusline escape; a path containing one would corrupt it.
							vim.wo[list.win.win].winbar = path:gsub("%%", "%%%%")
						end,
					},

					files = { hidden = true },
					buffers = {},
					registers = { layout = "float", focus = "input" },
					lines = { layout = "float", focus = "input" },
					marks = {
						global = true,
						transform = function(item)
							if not item.label or not item.label:match("^[a-zA-Z]$") then
								return false
							end
						end,
					},
					grep = {},

					-- lsp_declarations = {},
					lsp_definitions = {
						include_current = true,
					},
					lsp_type_definitions = {
						include_current = true,
					},
					lsp_implementations = {
						include_current = true,
					},
					lsp_references = {
						include_current = true,
					},
					lsp_incoming_calls = {
						include_current = true,
					},
					lsp_outgoing_calls = {
						include_current = true,
					},
					lsp_workspace_symbols = {},
					diagnostics = {},
				},
			},
		},
	},
}
