return {
	-- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
	settings = {
		gopls = {
			usePlaceholders = false,
			analyses = {
				unusedvariable = true,
				unusedparams = true,
				nilness = true,
			},
			staticcheck = true, -- https://staticcheck.dev/docs/checks/
		},
	},

	root_markers = { "go.mod", ".git" },
}
