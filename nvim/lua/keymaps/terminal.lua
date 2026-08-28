local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Terminal" })
end

local function leave_terminal_mode()
	if vim.fn.mode() == "t" then
		vim.cmd.stopinsert()
	end
end

local function with_toggleterm(callback)
	local ok, terms = pcall(require, "toggleterm.terminal")
	if not ok then
		notify("toggleterm.nvim is not available", vim.log.levels.ERROR)
		return
	end

	return callback(terms)
end

local function with_current_terminal(callback)
	with_toggleterm(function(terms)
		local _, term = terms.identify()
		if not term then
			notify("Current buffer is not a terminal session", vim.log.levels.WARN)
			return
		end

		callback(term)
	end)
end

local function terminal_name(term)
	local name = vim.trim(term.display_name or "")
	if name ~= "" then
		return name
	end

	return "Terminal " .. term.id
end

local function terminal_cwd(term)
	local dir = vim.trim(term.dir or "")
	if dir == "" then
		dir = vim.fn.getcwd()
	end

	return vim.fn.fnamemodify(dir, ":~")
end

local function next_terminal_id(terms)
	local all = terms.get_all(true)
	for index, term in ipairs(all) do
		if term.id ~= index then
			return index
		end
	end

	return #all + 1
end

local function set_terminal_name(term, name)
	name = vim.trim(name or "")
	term.display_name = name ~= "" and name or nil

	local ok, ui = pcall(require, "toggleterm.ui")
	if ok and term:is_open() then
		ui.set_winbar(term)
	end
end

local function rename_terminal(term, on_rename)
	leave_terminal_mode()

	local input = Snacks and Snacks.input or vim.ui.input
	input({
		prompt = "Rename terminal",
		default = term.display_name or terminal_name(term),
	}, function(value)
		if value == nil then
			return
		end

		set_terminal_name(term, value)
		if on_rename then
			on_rename(term)
		end
	end)
end

local function focus_terminal(term)
	if term:is_open() then
		term:focus()
	else
		term:open()
	end
end

local function delete_terminal(term)
	term:shutdown()
end

local function open_new_float_terminal()
	leave_terminal_mode()

	local current_buf = vim.api.nvim_get_current_buf()
	local ok_current, current_terms = pcall(require, "toggleterm.terminal")
	if ok_current then
		local _, current_term = current_terms.identify(vim.api.nvim_buf_get_name(current_buf))
		if current_term and current_term:is_open() and current_term:is_float() then
			current_term:close()
			return
		end
	end

	local ok, terms = pcall(require, "toggleterm.terminal")
	if not ok then
		notify("toggleterm.nvim is not available", vim.log.levels.ERROR)
		return
	end

	local term = terms.Terminal:new({
		id = next_terminal_id(terms),
		direction = "float",
	})

	term:toggle()
end

local function terminal_picker_items()
	local terms = require("toggleterm.terminal")
	local items = {}

	for _, term in ipairs(terms.get_all()) do
		items[#items + 1] = {
			term = term,
			idx = term.id,
			text = string.format(
				"%d %s [%s] %s",
				term.id,
				terminal_name(term),
				term:is_open() and "open" or "hidden",
				terminal_cwd(term)
			),
		}
	end

	return items
end

local function pick_terminal_session()
	leave_terminal_mode()

	with_toggleterm(function(terms)
		if vim.tbl_isempty(terms.get_all()) then
			notify("No terminal sessions yet")
			return
		end

		Snacks.picker({
			title = "Terminal Sessions",
			focus = "list",
			auto_close = false,
			layout = { preset = "float", preview = false },
			finder = function()
				return terminal_picker_items()
			end,
			format = "text",
			confirm = function(picker, item)
				picker:close()
				if not (item and item.term) then
					return
				end

				vim.schedule(function()
					focus_terminal(item.term)
				end)
			end,
			actions = {
				terminal_rename = function(picker, item)
					item = item or picker:current()
					if not (item and item.term) then
						return
					end

					rename_terminal(item.term, function()
						vim.schedule(function()
							picker:refresh()
						end)
					end)
				end,
				terminal_delete = function(picker, item)
					item = item or picker:current()
					if not (item and item.term) then
						return
					end

					delete_terminal(item.term)
					vim.schedule(function()
						if vim.tbl_isempty(require("toggleterm.terminal").get_all()) then
							picker:close()
						else
							picker:refresh()
						end
					end)
				end,
			},
			win = {
				input = {
					keys = {
						["<C-r>"] = { "terminal_rename", mode = { "n", "i" } },
						["<C-d>"] = { "terminal_delete", mode = { "n", "i" } },
					},
				},
				list = {
					keys = {
						["r"] = "terminal_rename",
						["<C-d>"] = { "terminal_delete", mode = { "n", "i" } },
					},
				},
			},
		})
	end)
end

local function rename_current_terminal()
	with_current_terminal(function(term)
		rename_terminal(term)
	end)
end

local function exit_current_terminal()
	with_current_terminal(function(term)
		leave_terminal_mode()
		delete_terminal(term)
	end)
end

vim.keymap.set({ "n", "t" }, "<leader>tt", open_new_float_terminal, { desc = "New floating terminal" })
vim.keymap.set({ "n", "t" }, "<leader>ft", pick_terminal_session, { desc = "Pick terminal session" })
vim.keymap.set({ "n", "t" }, "<leader>tr", rename_current_terminal, { desc = "Rename terminal session" })
vim.keymap.set({ "n", "t" }, "<leader>tq", exit_current_terminal, { desc = "Exit terminal session" })
