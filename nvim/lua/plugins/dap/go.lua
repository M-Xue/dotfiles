-- Go debugging via delve (installed by mason as `delve`, see plugins/mason.lua).
-- nvim-dap-go registers the `go` adapter and launch configurations
-- (debug file / package / nearest test) and is also what neotest-golang uses
-- for `<leader>ad` in Go files.
return {
	"leoluz/nvim-dap-go",
	lazy = true,
	opts = {
		delve = {
			path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
		},
	},
}
