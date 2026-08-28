return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.2",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope_actions = require("telescope.actions")
			local ok, trouble = pcall(require, "trouble")
			local smart_send_and_open_qfl = function(prompt_bufnr)
				telescope_actions.smart_send_to_qflist(prompt_bufnr)
				if not ok then
					telescope_actions.open_qflist(prompt_bufnr)
				else
					trouble.open("quickfix")
				end
			end
			local open_with_trouble = require("trouble.sources.telescope").open
			local add_to_trouble = require("trouble.sources.telescope").add

			local simple_qfl_mapping = {
				mappings = {
					i = {
						["<c-q>"] = smart_send_and_open_qfl,
						["<c-o>"] = open_with_trouble,
						["<c-a>"] = add_to_trouble,
					},
				},
			}

			local telescope = require("telescope")
			telescope.setup({
				pickers = {
					find_files = {
						find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
						mappings = {
							i = {
								["<c-q>"] = smart_send_and_open_qfl,
								["<c-o>"] = open_with_trouble,
								["<c-a>"] = add_to_trouble,
							},
						},
					},
					current_buffer_fuzzy_find = simple_qfl_mapping,
					diagnostics = simple_qfl_mapping,
					lsp_implementations = simple_qfl_mapping,
					lsp_definitions = simple_qfl_mapping,
					lsp_type_definitions = simple_qfl_mapping,
					lsp_incoming_calls = simple_qfl_mapping,
					lsp_outgoing_calls = simple_qfl_mapping,
					lsp_references = simple_qfl_mapping,
				},
				defaults = {
					path_display = { "truncate" },
					prompt_prefix = " 󰍉 ",
					selection_caret = "   ",
					entry_prefix = "   ",
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					-- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
					initial_mode = "insert",
					selection_strategy = "reset",
					sorting_strategy = "ascending",
					layout_strategy = "horizontal",
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							mirror = false,
						},
						width = 0.87,
						height = 0.80,
						preview_cutoff = 120,
					},
					color_devicons = true,
				},
				extensions = {
					-- file_browser = {
					-- 	hijack_netrw = true,
					-- },
					advanced_git_search = {
						diff_plugin = "diffview",
					},
					undo = {
						preview_width = 0.8,
					},
					live_grep_args = {
						mappings = {
							i = {
								["<c-q>"] = smart_send_and_open_qfl,
								["<c-f>"] = telescope_actions.to_fuzzy_refine,
								["<c-o>"] = open_with_trouble,
								["<c-a>"] = add_to_trouble,
							},
						},
					},
					fzf = {
						fuzzy = true, -- false will only do exact matching
						override_generic_sorter = true, -- override the generic sorter
						override_file_sorter = true, -- override the file sorter
						case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					},
				},
			})
			-- telescope.load_extension("file_browser")
			-- telescope.load_extension("toggleterm")
			telescope.load_extension("undo")
			telescope.load_extension("advanced_git_search")
			telescope.load_extension("live_grep_args")
			telescope.load_extension("fzf")
		end,
	},
	-- {
	-- 	"nvim-telescope/telescope-file-browser.nvim",
	-- 	dependencies = {
	-- 		"nvim-telescope/telescope.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 	},
	-- },
	-- {
	-- 	"https://git.sr.ht/~havi/telescope-toggleterm.nvim",
	-- 	dependencies = {
	-- 		"nvim-telescope/telescope.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"akinsho/toggleterm.nvim",
	-- 		"nvim-lua/popup.nvim",
	-- 	},
	-- 	event = "TermOpen",
	-- },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"debugloop/telescope-undo.nvim",
		},
	},
	{
		"nvim-telescope/telescope-live-grep-args.nvim",
		-- This will not install any breaking changes.
		-- For major updates, this must be adjusted manually.
		version = "^1.0.0",
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
}
