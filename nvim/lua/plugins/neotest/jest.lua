-- Jest adapter. Resolves the jest config and working directory per test file so
-- monorepos (one jest config per package) work the same as single-package repos.
-- Only claims unit test files (see paths.lua) in packages that depend on jest.
local paths = require("plugins.neotest.paths")

local function is_jest_test_file(file)
	return paths.is_unit_test_file(file) and require("neotest-jest.jest-util").hasJestDependency(file)
end
local config_names = {
	"jest.config.ts",
	"jest.config.js",
	"jest.config.mjs",
	"jest.config.cjs",
	"jest.config.mts",
	"jest.config.cts",
	"jest.config.json",
}

local function find_up(names, file)
	return vim.fs.find(names, { upward = true, path = vim.fs.dirname(file), type = "file" })[1]
end

-- Nearest jest.config.*, otherwise the nearest package.json (jest accepts it as a
-- --config path and reads its "jest" key). nil only if neither exists.
local function jest_config(file)
	return find_up(config_names, file) or find_up({ "package.json" }, file)
end

local function jest_cwd(file)
	local config = jest_config(file)
	return config and vim.fs.dirname(config) or vim.fn.getcwd()
end

-- Sitting on a breakpoint for more than 5s would otherwise fail the test with
-- "Exceeded timeout of 5000 ms for a test", so lift jest's per-test timeout
-- whenever a test is launched under the debugger.
local debug_test_timeout_ms = 24 * 60 * 60 * 1000

local function strategy_config(default_config)
	if type(default_config) == "table" and type(default_config.args) == "table" then
		table.insert(default_config.args, "--testTimeout=" .. debug_test_timeout_ms)
	end
	return default_config
end

return require("neotest-jest")({
	jestConfigFile = jest_config,
	cwd = jest_cwd,
	env = { CI = "true" },
	jest_test_discovery = false,
	strategy_config = strategy_config,
	isTestFile = is_jest_test_file,
})
