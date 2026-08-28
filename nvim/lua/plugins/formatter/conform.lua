-- https://github.com/stevearc/conform.nvim/issues/92#issuecomment-2077222348
local function format_git_modified_lines()
	local hunks = require("gitsigns").get_hunks()
	if hunks == nil then
		return
	end

	local format = require("conform").format

	local function format_range()
		if next(hunks) == nil then
			vim.notify("done formatting git hunks", "info", { title = "formatting" })
			return
		end
		local hunk = nil
		while next(hunks) ~= nil and (hunk == nil or hunk.type == "delete") do
			hunk = table.remove(hunks)
		end

		if hunk ~= nil and hunk.type ~= "delete" then
			local start = hunk.added.start
			local last = start + hunk.added.count
			-- nvim_buf_get_lines uses zero-based indexing -> subtract from last
			local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
			local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
			format({ range = range, async = true, lsp_fallback = true }, function()
				vim.defer_fn(function()
					format_range()
				end, 1)
			end)
		end
	end

	format_range()
end

-- vim.api.nvim_create_autocmd("BufWritePre", {
-- 	pattern = "*",
-- 	callback = function(args)
-- 		format_git_modified_lines()
-- 	end,
-- })

return {
	{
		"stevearc/conform.nvim",
		config = function()
			local conform = require("conform")

			conform.setup({
				formatters_by_ft = {
					javascript = { "prettierd" },
					javascriptreact = { "prettierd" },
					typescript = { "prettierd" },
					typescriptreact = { "prettierd" },
					html = { "prettierd" },
					css = { "prettierd" },

					astro = { "prettier" },
					svelte = { "prettier" },

					lua = { "stylua" },
					go = { "goimports-reviser", "golines", "gofumpt" },
					markdown = { "markdownlint" },
				},
				log_level = vim.log.levels.ERROR,
				notify_on_error = true,
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 500,
				},
				--[[
				--
				--]]
				-- formatters = {
				-- 	prettierd = {
				-- 		-- https://github.com/stevearc/conform.nvim/blob/0e61fc88f725b4411e63b43470a397c6102534c7/lua/conform/formatters/prettierd.lua
				-- 		-- https://github.com/stevearc/conform.nvim/issues/268
				-- 		env = {
				-- 			PRETTIERD_LOCAL_PRETTIER_ONLY = 1,
				-- 		},
				-- 	},
				-- },
			})
		end,
	},
}
