return {
	{
		"goolord/alpha-nvim",
		priority = 999,
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("alpha").setup(require("alpha.themes.dashboard").config)
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.header.val = {
				"",
				"",
				"",
				"",
				"",
				"",
				"",
				"                                                     ",
				"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
				"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
				"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
				"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
				"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
				"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
				"                                                     ",
			}

			dashboard.section.buttons.val = {
				dashboard.button("f", "󰈞   Find file", ":lua Snacks.picker.files()<cr>"),
				dashboard.button(
					"'",
					"󰀱   Harpoon",
					":lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>"
				),
				dashboard.button(
					"h",
					"   LazyGit",
					":LazyGit<cr>"
				),
				dashboard.button("g", "󰬴   Grep", ":lua Snacks.picker.grep()<cr>"),
				dashboard.button(
					"c",
					"   Config",
					":cd " .. require("_util").get_config_path() .. "<cr>:lua Snacks.picker.files()<cr>",
					{
						silent = true,
					}
				),
				dashboard.button("`", "   Quit NVIM", ":qa<CR>"),
			}

			-- local date = os.date("┏   Today is %a %d %b ┓")
			local plugins = "  " .. #vim.tbl_keys(require("lazy").plugins()) .. " plugins in total"

			dashboard.section.footer.val = {
				plugins,
				os.date("  Today is %a %d %b"),
			}
		end,
	},
}
