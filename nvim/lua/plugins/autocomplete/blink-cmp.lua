local icons = require("icons.lspkind").icons

local source_icons = {
	LSP = "",
	Snippets = "",
	Buffer = "",
	Path = "󰝰",
	Copilot = "",
}

return {
	"saghen/blink.cmp",
	lazy = false,
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			-- Need this for the regex to work: https://github.com/L3MON4D3/LuaSnip/discussions/538
			build = "make install_jsregexp",
			dependencies = {
				"rafamadriz/friendly-snippets",
				config = function()
					require("luasnip.loaders.from_vscode").lazy_load()
					require("luasnip.loaders.from_vscode").lazy_load({
						paths = { vim.fn.stdpath("config") .. "/snippets" },
					})
				end,
			},
		},
		{
			"giuxtaposition/blink-cmp-copilot",
			dependencies = "zbirenbaum/copilot.lua",
		},
	},
	version = "1.*",
	opts = {
		-- C-space: Open menu or open docs if already open
		-- C-e: Hide menu
		-- C-k: Toggle signature help (if signature.enabled = true)
		keymap = {
			preset = "enter",
			["<C-leader>"] = { "show" },
			["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
			["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
		},
		appearance = {
			nerd_font_variant = "mono",
			-- kind_icons = icons,
		},
		completion = {
			trigger = {
				show_on_insert = false,
				show_on_accept_on_trigger_character = false,
				show_on_insert_on_trigger_character = false,
				show_on_blocked_trigger_characters = { " ", "\n", "\t", "(", "[", "{" },
			},
			documentation = { auto_show = true },
			menu = {
				draw = {
					columns = {
						{ "kind_icon", "kind", gap = 1 },
						{ "label", "label_description", gap = 1 },
						{ "source_name" },
					},
					components = {
						kind_icon = {
							text = function(ctx)
								return icons[ctx.kind]
							end,
						},
						source_name = {
							text = function(ctx)
								return source_icons[ctx.source_name]
							end,
						},
					},
				},
			},
		},
		sources = {
			default = { "lsp", "snippets", "copilot", "path", "buffer" },
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					score_offset = 1000,
					async = true,
				},
			},
		},
		snippets = { preset = "luasnip" },
		signature = { enabled = true },
		cmdline = {
			enabled = true,
			keymap = { preset = "cmdline" },
			sources = { "buffer", "cmdline" },
			completion = {
				list = {
					selection = {
						preselect = false,
						auto_insert = true,
					},
				},
				menu = {
					auto_show = true,
				},
			},
		},
	},
}
