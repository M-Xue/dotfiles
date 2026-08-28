local function configure_diagnostics()
	-- Documentation -> :help vim.diagnostic
	vim.diagnostic.config({
		virtual_text = false,
		signs = {
			text = {
				-- [vim.diagnostic.severity.ERROR] = "E",
				-- [vim.diagnostic.severity.WARN] = "W",
				-- [vim.diagnostic.severity.INFO] = "I",
				-- [vim.diagnostic.severity.HINT] = "H",
				[vim.diagnostic.severity.ERROR] = "",
				[vim.diagnostic.severity.WARN] = "",
				[vim.diagnostic.severity.INFO] = "",
				[vim.diagnostic.severity.HINT] = "",
			},
		},

		update_in_insert = false,
		severity_sort = true,
		float = {
			focusable = true,
			style = "minimal",
			source = true,
			header = "",
			prefix = "",
		},
	})
end

local function configure_lsp()
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	-- This function is used for passing in information about the LSP client after
	-- it attaches to a buffer.
	local on_attach = function(client, bufnr)
		local wk = require("which-key")
		wk.add({
			{ "<leader>e", group = "Diagnostics" },
			{ "<leader>g", group = "LSP" },
		})
		require("plugins.lsp.keymaps").init_lsp_keymaps(bufnr)
		require("plugins.lsp.keymaps").init_diagnostics_keymaps(bufnr)

		local navic = require("nvim-navic")
		if client.supports_method("textDocument/documentSymbol") then
			navic.attach(client, bufnr)
		end
	end

	vim.lsp.config("*", {
		capabilities = capabilities,
		on_attach = on_attach,
	})
end

return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			configure_diagnostics()
			configure_lsp()
		end,
		dependencies = {
			"saghen/blink.cmp",
		},
	},
	require("plugins.lsp.plugins"),
}
