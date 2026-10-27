-- Testing: <leader>a
-- neotest is lazy loaded, so everything goes through functions that require() on use.

local function neotest()
	return require("neotest")
end

local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- Running
map("n", "<leader>aa", function()
	neotest().run.run()
end, "Run nearest test")
map("n", "<leader>af", function()
	neotest().run.run(vim.fn.expand("%"))
end, "Run current file")
map("n", "<leader>aA", function()
	neotest().run.run({ suite = true })
end, "Run whole suite")
map("n", "<leader>al", function()
	neotest().run.run_last()
end, "Run last")
map("n", "<leader>ad", function()
	neotest().run.run({ strategy = "dap" })
end, "Debug nearest test")
map("n", "<leader>aD", function()
	neotest().run.run_last({ strategy = "dap" })
end, "Debug last")
map("n", "<leader>aq", function()
	neotest().run.stop()
end, "Stop")
map("n", "<leader>at", function()
	neotest().run.attach()
end, "Attach to running test")
map("n", "<leader>aw", function()
	neotest().watch.toggle(vim.fn.expand("%"))
end, "Toggle watch current file")

-- Results
map("n", "<leader>as", function()
	neotest().summary.toggle()
end, "Toggle summary")
map("n", "<leader>ao", function()
	neotest().output.open({ enter = true, auto_close = true })
end, "Show test output")
map("n", "<leader>aO", function()
	neotest().output_panel.toggle()
end, "Toggle output panel")
map("n", "<leader>aj", function()
	neotest().jump.next({ status = "failed" })
end, "Next failed test")
map("n", "<leader>ak", function()
	neotest().jump.prev({ status = "failed" })
end, "Previous failed test")

-- Playwright
local function playwright_command(command)
	return function()
		neotest() -- make sure neotest (and with it neotest-playwright) is loaded
		vim.cmd(command)
	end
end
map("n", "<leader>ap", playwright_command("NeotestPlaywrightProject"), "Playwright: pick projects")
map("n", "<leader>aP", playwright_command("NeotestPlaywrightPreset"), "Playwright: headless/headed/debug")
map("n", "<leader>ar", playwright_command("NeotestPlaywrightRefresh"), "Playwright: refresh")
