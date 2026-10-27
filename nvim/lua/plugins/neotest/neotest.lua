-- Test runner framework. Adapters live in sibling files (see plugins.neotest.jest).
-- Keymaps are in keymaps/neotest.lua.
return {
	"nvim-neotest/neotest",
	ft = { "javascript", "typescript", "javascriptreact", "typescriptreact", "go" },
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-jest",
		"marilari88/neotest-vitest",
		"thenbe/neotest-playwright",
		{
			-- v2+ needs the Go grammar from nvim-treesitter's `main` branch; we are on
			-- `master`, whose pinned grammar lacks the `statement_list` node v2 queries use.
			-- Drop the pin when nvim-treesitter moves to `main`.
			"fredrikaverpil/neotest-golang",
			version = "^1",
		},
	},
	config = function()
		require("neotest").setup({
			-- Order matters: the first adapter whose is_test_file() accepts a file owns it.
			adapters = {
				require("plugins.neotest.playwright"),
				require("plugins.neotest.vitest"),
				require("plugins.neotest.jest"),
				require("plugins.neotest.golang"),
			},
			status = { virtual_text = true, signs = true },
			output = { open_on_run = false },
			output_panel = { open = "botright split | resize 15" },
			summary = { open = "botright vsplit | vertical resize 50" },
			quickfix = { enabled = false },
			diagnostic = { enabled = true, severity = vim.diagnostic.severity.ERROR },
			floating = { border = "single" },
		})

		-- neotest parses test files in a child Neovim started with `-u NONE`. That
		-- child never runs nvim-treesitter, so it doesn't know e.g. typescriptreact
		-- -> tsx and discovery fails for .tsx/.jsx tests. Copy the parent's
		-- filetype -> parser mappings into the child as soon as it starts.
		local subprocess = require("neotest.lib").subprocess
		local init = subprocess.init
		subprocess.init = function(...)
			init(...)
			if not subprocess.enabled() then
				return
			end
			local mappings = {}
			for _, filetype in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
				local lang = vim.treesitter.language.get_lang(filetype)
				if lang and lang ~= filetype then
					mappings[#mappings + 1] =
						string.format("vim.treesitter.language.register(%q, { %q })", lang, filetype)
				end
			end
			if #mappings > 0 then
				subprocess.request("nvim_exec_lua", table.concat(mappings, "\n"), {})
			end
		end
	end,
}
