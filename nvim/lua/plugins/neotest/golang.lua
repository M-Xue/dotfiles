-- Go adapter. Uses gotestsum (installed by mason) for nicer output and
-- nvim-dap-go + delve (also mason) for `<leader>ad`.
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"

return require("neotest-golang")({
	runner = vim.fn.executable(mason_bin .. "/gotestsum") == 1 and "gotestsum" or "go",
	go_test_args = { "-v", "-race", "-count=1" },
	gotestsum_args = { "--format=standard-verbose" },
	dap_mode = "dap-go",
	dap_go_opts = {
		delve = { path = mason_bin .. "/dlv" },
	},
	testify_enabled = false,
	warn_test_name_dupes = true,
})
