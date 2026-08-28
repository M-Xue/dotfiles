local M = {}

M.init_lsp_keymaps = function(bufnr)
	vim.keymap.set(
		"n",
		"<leader>r",
		vim.lsp.buf.rename,
		{ noremap = true, silent = true, buffer = bufnr, desc = "Rename" }
	)

	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover({ max_width = 80 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Documentation" })
	-- Use "K" again to go into the float window.

	vim.keymap.set({ "n", "i" }, "<c-k>", function()
		vim.lsp.buf.signature_help({ max_width = 80 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Get signature" })

	vim.keymap.set(
		"n",
		"<leader>gl",
		vim.lsp.buf.declaration,
		{ noremap = true, silent = true, buffer = bufnr, desc = "Go to declaration" }
	)
	vim.keymap.set(
		"n",
		"<leader>ga",
		vim.lsp.buf.code_action,
		{ noremap = true, silent = true, buffer = bufnr, desc = "Get code actions" }
	)

	vim.keymap.set("n", "<leader>gd", function()
		Snacks.picker.lsp_definitions()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find definition" })

	vim.keymap.set(
		"n",
		"<leader>gD",
		"<cmd>Trouble lsp_definitions<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Definitions list" }
	)

	vim.keymap.set("n", "<leader>gt", function()
		Snacks.picker.lsp_type_definitions()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find type definition" })

	vim.keymap.set(
		"n",
		"<leader>gT",
		"<cmd>Trouble lsp_type_definitions<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Type definitions list" }
	)

	vim.keymap.set("n", "<leader>gi", function()
		Snacks.picker.lsp_implementations()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find implementation" })

	vim.keymap.set(
		"n",
		"<leader>gI",
		"<cmd>Trouble lsp_implementations<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Implementations list" }
	)

	vim.keymap.set("n", "<leader>gr", function()
		Snacks.picker.lsp_references()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find reference" })

	vim.keymap.set(
		"n",
		"<leader>gR",
		"<cmd>Trouble lsp_references<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "References list" }
	)

	vim.keymap.set("n", "<leader>gc", function()
		Snacks.picker.lsp_incoming_calls()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find incoming calls" })

	vim.keymap.set(
		"n",
		"<leader>gC",
		"<cmd>Trouble lsp_incoming_calls<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Incoming calls list" }
	)

	vim.keymap.set("n", "<leader>go", function()
		Snacks.picker.lsp_outgoing_calls()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find outgoing calls" })

	vim.keymap.set(
		"n",
		"<leader>gO",
		"<cmd>Trouble lsp_outgoing_calls<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Outgoing calls list" }
	)

	vim.keymap.set("n", "<leader>gs", function()
		Snacks.picker.lsp_workspace_symbols()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Search LSP symbols" })
end

M.init_diagnostics_keymaps = function(bufnr)
	vim.keymap.set("n", "<leader>ej", function()
		vim.diagnostic.jump({ count = 1 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Go to next diagnostic" })

	vim.keymap.set("n", "<leader>ek", function()
		vim.diagnostic.jump({ count = -1 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Go to previous diagnostic" })

	vim.keymap.set("n", "<leader>el", function()
		Snacks.picker.diagnostics()
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find diagnostics" })

	vim.keymap.set("n", "<leader>eE", function()
		Snacks.picker.diagnostics({ severity = vim.diagnostic.severity.ERROR })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find all errors" })

	vim.keymap.set("n", "<leader>ee", function()
		Snacks.picker.diagnostics({
			severity = vim.diagnostic.severity.ERROR,
			bufnr = 0,
		})
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find errors in current buffer" })

	vim.keymap.set("n", "<leader>ew", function()
		Snacks.picker.diagnostics({
			severity = vim.diagnostic.severity.WARN,
			bufnr = 0,
		})
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find warnings in current buffer" })

	vim.keymap.set("n", "<leader>eb", function()
		Snacks.picker.diagnostics({ bufnr = 0 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Find diagnostics in current buffer" })

	vim.keymap.set(
		"n",
		"<leader>eL",
		"<cmd>Trouble diagnostics<cr>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "List diagnostics" }
	)

	vim.keymap.set("n", "<leader>ei", function()
		vim.diagnostic.open_float({ width = 80 })
	end, { noremap = true, silent = true, buffer = bufnr, desc = "Get diagnostic info" })
end

return M
