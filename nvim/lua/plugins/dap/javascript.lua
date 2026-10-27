-- JavaScript / TypeScript / React debugging via vscode-js-debug
-- (installed by mason as `js-debug-adapter`, see plugins/mason.lua).
--
-- Node debugging uses the `pwa-node` adapter, browser debugging uses `pwa-chrome`.
-- `.vscode/launch.json` files in a project are picked up automatically by nvim-dap
-- and merged with the configurations below; `type: "node"` / `type: "chrome"`
-- entries are rewritten to their pwa-* equivalents.
local M = {}

M.filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

local function js_debug_server()
	return vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
end

local function prompt(label, default)
	return function()
		return vim.fn.input(label, default)
	end
end

local function prompt_number(label, default)
	return function()
		return tonumber(vim.fn.input(label, default))
	end
end

function M.setup(dap)
	local server = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = "node",
			args = { js_debug_server(), "${port}" },
		},
	}

	dap.adapters["pwa-node"] = server
	dap.adapters["pwa-chrome"] = server

	-- Legacy types (commonly found in launch.json)
	for legacy, modern in pairs({ node = "pwa-node", chrome = "pwa-chrome" }) do
		dap.adapters[legacy] = function(callback, config)
			if config.type == legacy then
				config.type = modern
			end
			callback(server)
		end
	end

	local vscode = require("dap.ext.vscode")
	for _, type in ipairs({ "node", "pwa-node", "chrome", "pwa-chrome" }) do
		vscode.type_to_filetypes[type] = M.filetypes
	end

	local configurations = {
		-- Node
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch current file (node)",
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch current file (tsx)",
			runtimeExecutable = "npx",
			runtimeArgs = { "tsx" },
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch npm script",
			runtimeExecutable = "npm",
			runtimeArgs = function()
				return { "run", vim.fn.input("npm script: ", "dev") }
			end,
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to process",
			processId = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to port (node --inspect)",
			port = prompt_number("Port: ", "9229"),
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},

		-- Jest
		{
			type = "pwa-node",
			request = "launch",
			name = "Debug Jest: current file",
			runtimeExecutable = "node",
			runtimeArgs = {
				"${workspaceFolder}/node_modules/jest/bin/jest.js",
				"--runInBand",
				"--watchAll=false",
				"--testTimeout=86400000", -- don't fail tests while paused on a breakpoint
				"${file}",
			},
			rootPath = "${workspaceFolder}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},

		-- Browser (React etc.)
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome against dev server",
			url = prompt("URL: ", "http://localhost:3000"),
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "**/node_modules/**" },
		},
		{
			type = "pwa-chrome",
			request = "attach",
			name = "Attach to Chrome (--remote-debugging-port)",
			port = prompt_number("Port: ", "9222"),
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "**/node_modules/**" },
		},
	}

	for _, filetype in ipairs(M.filetypes) do
		dap.configurations[filetype] = configurations
	end
end

return M
