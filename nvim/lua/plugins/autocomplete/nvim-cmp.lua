local symbol_map = require("icons.lspkind").icons

local source_icons = {
	nvim_lsp = "",
	nvim_lua = "",
	luasnip = "",
	buffer = "",
	path = "󰝰",
	treesitter = "",
}

local verbose = {
	fields = { "kind", "abbr", "menu" },
	format = function(entry, vim_item)
		vim_item.kind = string.format("%s %s", symbol_map[vim_item.kind], vim_item.kind)
		vim_item.menu = source_icons[entry.source.name]
		return vim_item
	end,
}

return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				-- Need this for the regex to work: https://github.com/L3MON4D3/LuaSnip/discussions/538
				build = "make install_jsregexp",
				dependencies = "rafamadriz/friendly-snippets",
			},
			{
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-nvim-lua",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
				"saadparwaiz1/cmp_luasnip",
			},
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "./lua/plugins/autocomplete/luasnippets" },
			})

			-- local has_words_before = function()
			-- 	unpack = unpack or table.unpack
			-- 	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			-- 	return col ~= 0
			-- 		and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			-- end

			-- local function is_cmp_enabled()
			-- 	-- disable in Telescope
			-- 	if vim.bo.buftype == "prompt" then
			-- 		return false
			-- 	end
			-- 	-- disable completion in comments
			-- 	local context = require("cmp.config.context")
			-- 	-- keep command mode completion enabled when cursor is in a comment
			-- 	if vim.api.nvim_get_mode().mode == "c" then
			-- 		return true
			-- 	else
			-- 		return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
			-- 	end
			-- end

			-- cmp.setup({
			-- enabled = is_cmp_enabled,
			-- performance = {
			-- 	-- max_view_entries = 15,
			-- },
			-- preselect = cmp.PreselectMode.None,
			-- -- completion = {
			-- -- 	completeopt = "menu,menuone,noinsert",
			-- -- },
			-- snippet = {
			-- 	expand = function(args)
			-- 		require("luasnip").lsp_expand(args.body)
			-- 	end,
			-- },

			-- sources = cmp.config.sources({
			-- 	{ name = "nvim_lsp" },
			-- 	{ name = "luasnip" },
			-- 	{ name = "nvim_lua" }, -- For nvim Lua API autocomplete
			-- 	{ name = "path" },
			-- }, {
			-- 	{
			-- 		name = "buffer",
			-- 		max_item_count = 5,
			-- 	},
			-- }),
			-- formatting = verbose,
			-- mapping = cmp.mapping.preset.insert({
			-- 	["<C-k>"] = cmp.mapping.select_prev_item(),
			-- 	["<C-j>"] = cmp.mapping.select_next_item(),
			-- 	["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
			-- 	["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
			-- 	["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
			-- 	["<C-e>"] = cmp.mapping.abort(),
			-- 	["<CR>"] = cmp.mapping.confirm({ select = false }),
			-- 	["<Tab>"] = cmp.mapping(function(fallback)
			-- 		if cmp.visible() then
			-- 			cmp.select_next_item()
			-- 		elseif luasnip.expand_or_jumpable() then
			-- 			luasnip.expand_or_jump()
			-- 			-- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
			-- 			-- that way you will only jump inside the snippet region
			-- 		elseif has_words_before() then
			-- 			cmp.complete()
			-- 		else
			-- 			fallback()
			-- 		end
			-- 	end, { "i", "s" }),

			-- 	["<S-Tab>"] = cmp.mapping(function(fallback)
			-- 		if cmp.visible() then
			-- 			cmp.select_prev_item()
			-- 		elseif luasnip.jumpable(-1) then
			-- 			luasnip.jump(-1)
			-- 		else
			-- 			fallback()
			-- 		end
			-- 	end, { "i", "s" }),
			-- }),
			-- 	view = {
			-- 		docs = {
			-- 			auto_open = true,
			-- 		},
			-- 	},
			-- })

			-- -- `/` cmdline setup.
			-- cmp.setup.cmdline("/", {
			-- 	mapping = cmp.mapping.preset.cmdline(),
			-- 	sources = {
			-- 		{ name = "buffer" },
			-- 	},
			-- })

			-- -- `:` cmdline setup.
			-- cmp.setup.cmdline(":", {
			-- 	mapping = cmp.mapping.preset.cmdline(),
			-- 	sources = cmp.config.sources({
			-- 		{ name = "path" },
			-- 	}, {
			-- 		{ name = "cmdline" },
			-- 	}),
			-- })
		end,
	},
}
