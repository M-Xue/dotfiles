-- Scopes / breakpoints / stacks / watches / REPL / console panes.
-- Opens automatically when a session starts and closes when it ends.
return {
	"rcarriga/nvim-dap-ui",
	lazy = true,
	dependencies = { "nvim-neotest/nvim-nio" },
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dapui.setup({
			floating = { border = "single" },
			controls = { enabled = true },
			layouts = {
				{
					position = "left",
					size = 40,
					elements = {
						{ id = "scopes", size = 0.4 },
						{ id = "watches", size = 0.2 },
						{ id = "stacks", size = 0.2 },
						{ id = "breakpoints", size = 0.2 },
					},
				},
				{
					position = "bottom",
					size = 12,
					elements = {
						{ id = "console", size = 0.6 },
						{ id = "repl", size = 0.4 },
					},
				},
			},
		})

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end
	end,
}
