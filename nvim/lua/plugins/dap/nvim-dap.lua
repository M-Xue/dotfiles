-- Debug Adapter Protocol client. Adapters/configurations per language live in
-- sibling files (see plugins.dap.javascript). Keymaps are in keymaps/dap.lua.
return {
	"mfussenegger/nvim-dap",
	lazy = true, -- loaded on first require() from a keymap
	dependencies = {
		require("plugins.dap.nvim-dap-ui"),
		require("plugins.dap.nvim-dap-virtual-text"),
		require("plugins.dap.go"),
	},
	config = function()
		local dap = require("dap")

		-- Gutter signs. Nerd Font glyphs are written as escapes so they can't be mangled by copy/paste.
		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
		local signs = {
			DapBreakpoint = { text = "\u{F192}", texthl = "DiagnosticError" }, -- nf-fa-dot_circle_o
			DapBreakpointCondition = { text = "\u{F059}", texthl = "DiagnosticWarn" }, -- nf-fa-question_circle
			DapLogPoint = { text = "\u{F075}", texthl = "DiagnosticInfo" }, -- nf-fa-comment
			DapBreakpointRejected = { text = "\u{F06A}", texthl = "DiagnosticError" }, -- nf-fa-exclamation_circle
			DapStopped = { -- nf-md-arrow_right_bold
				text = "\u{F0055}",
				texthl = "DiagnosticWarn",
				linehl = "DapStoppedLine",
				numhl = "DiagnosticWarn",
			},
		}
		for name, sign in pairs(signs) do
			vim.fn.sign_define(name, sign)
		end

		-- Reuse an existing window/tab when the debugger jumps to a file
		dap.defaults.fallback.switchbuf = "usetab,uselast"

		require("plugins.dap.javascript").setup(dap)
	end,
}
