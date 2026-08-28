-- Formatters to install
-- =====================
-- "prettierd",
-- "prettier",
-- "stylua",
-- "goimports-reviser",
-- "golines",
-- "gofumpt",
-- "markdownlint-cli2",

-- Linters to install
-- =====================
-- "eslint_d",
-- "stylelint",
-- "golangci-lint",
-- "markdownlint-cli2",
-- "cspell",

return {
	{
		"mason-org/mason.nvim",
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
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"gopls",
				"pyright",
				"rust_analyzer",

				"html",
				"jsonls",
				"marksman",
				"mdx_analyzer",

				"emmet_language_server",
				"cssls",
				"cssmodules_ls",
				"tailwindcss",
				"astro",
				"svelte",

				"vimls",
			},
		},
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
	},
}
