-- Vitest adapter. Only claims files in packages that depend on vitest (the
-- adapter checks package.json itself), and never e2e files (see paths.lua).
local paths = require("plugins.neotest.paths")

local config_names = {
	"vitest.config.ts",
	"vitest.config.js",
	"vitest.config.mts",
	"vitest.config.mjs",
	"vite.config.ts",
	"vite.config.js",
	"vite.config.mts",
	"vite.config.mjs",
}

local function find_up(names, file)
	return vim.fs.find(names, { upward = true, path = vim.fs.dirname(file), type = "file" })[1]
end

-- nil lets vitest resolve its own config from cwd
local function vitest_config(file)
	return find_up(config_names, file)
end

local function vitest_cwd(file)
	local config = vitest_config(file) or find_up({ "package.json" }, file)
	return config and vim.fs.dirname(config) or vim.fn.getcwd()
end

return require("neotest-vitest")({
	is_test_file = paths.is_unit_test_file,
	vitestConfigFile = vitest_config,
	cwd = vitest_cwd,
	env = { CI = "true" },
})
