return {
	{
		"mason-org/mason.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		opts = {
			ui = {
				border = "none",
				icons = {
					package_installed = "◍",
					package_pending = "◍",
					package_uninstalled = "◍",
				},
			},
			log_level = vim.log.levels.INFO,
			max_concurrent_installers = 4,
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("mason").setup()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"gopls",
					"pyright",
					"rust_analyzer",
					"html",
					"jsonls",
					"emmet_language_server",
					"cssls",
					"cssmodules_ls",
					"tailwindcss",
					"astro",
					"svelte",
					"vimls",
					"bashls",

					"markdown_oxide",
					"marksman",
					"mdx_analyzer",
				},
			})

			require("mason-tool-installer").setup({
				ensure_installed = {
					-- Formatters
					"stylua",
					"markdownlint-cli2",
					"oxfmt",
					"prettierd",
					-- "prettier",
					"goimports-reviser",
					"golines",
					"gofumpt",

					-- Linters
					"cspell",
					"eslint_d",
					"markdownlint-cli2",
					"stylelint",
					"golangci-lint",
				},
				auto_update = true,
				run_on_start = true,
			})
		end,
	},
}
