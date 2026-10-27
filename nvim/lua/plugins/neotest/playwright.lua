-- Playwright adapter. Owns test files under e2e directories only (see paths.lua).
--
-- `:NeotestPlaywrightProject` picks which playwright projects (browsers) to run,
-- `:NeotestPlaywrightPreset` switches between headless / headed / debug.
local paths = require("plugins.neotest.paths")

-- Nearest playwright config above the current file, falling back to cwd. The
-- adapter's own finders only ever look in cwd, which breaks monorepos.
local function project_root()
	local file = vim.api.nvim_buf_get_name(0)
	local start = file ~= "" and vim.fn.filereadable(file) == 1 and vim.fs.dirname(file) or vim.uv.cwd()
	local config = vim.fs.find(
		{ "playwright.config.ts", "playwright.config.js" },
		{ upward = true, path = start, type = "file" }
	)[1]
	return config and vim.fs.dirname(config) or vim.uv.cwd()
end

local function playwright_config()
	local root = project_root()
	for _, name in ipairs({ "playwright.config.ts", "playwright.config.js" }) do
		local path = root .. "/" .. name
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
	return root .. "/playwright.config.ts"
end

-- Nearest node_modules/.bin/playwright at or above the project root (hoisted in monorepos)
local function playwright_binary()
	local bin = vim.fs.find("node_modules", { upward = true, path = project_root(), type = "directory" })
	for _, dir in ipairs(bin) do
		local candidate = dir .. "/.bin/playwright"
		if vim.fn.executable(candidate) == 1 then
			return candidate
		end
	end
	return project_root() .. "/node_modules/.bin/playwright"
end

return require("neotest-playwright").adapter({
	options = {
		persist_project_selection = true,
		enable_dynamic_test_discovery = true,
		preset = "none",
		is_test_file = paths.is_e2e_test_file,
		get_playwright_binary = playwright_binary,
		get_playwright_config = playwright_config,
		get_cwd = project_root,
	},
})
