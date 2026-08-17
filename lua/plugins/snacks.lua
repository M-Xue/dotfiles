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
