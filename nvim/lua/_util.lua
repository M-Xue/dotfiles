local M = {}

-- Function to perform a deep copy of a table
local function deep_copy(original)
	local copy
	-- If the original is a table, create a new table
	if type(original) == "table" then
		copy = {}
		for orig_key, orig_value in next, original, nil do
			copy[deep_copy(orig_key)] = deep_copy(orig_value)
		end
		setmetatable(copy, deep_copy(getmetatable(original)))
	else
		-- If the original is not a table, just return it (base case)
		copy = original
	end
	return copy
end

M.deep_copy = deep_copy

M.print_attached_clients = function()
	local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		vim.print("LSP Inactive")
		return
	end

	local buf_ft = vim.bo.filetype
	local buf_client_names = {}

	-- add client
	for _, client in pairs(buf_clients) do
		table.insert(buf_client_names, client.name)
	end

	-- Add linters (from nvim-lint)
	local lint_s, lint = pcall(require, "lint")
	if lint_s then
		for ft_k, ft_v in pairs(lint.linters_by_ft) do
			if type(ft_v) == "table" then
				for _, linter in ipairs(ft_v) do
					if buf_ft == ft_k then
						table.insert(buf_client_names, linter)
					end
				end
			elseif type(ft_v) == "string" then
				if buf_ft == ft_k then
					table.insert(buf_client_names, ft_v)
				end
			end
		end
	end

	-- Add formatters (from conform.nvim)
	local conform_s, conform = pcall(require, "conform")
	if conform_s then
		for _, formatter in ipairs(conform.list_formatters(0)) do
			if formatter then
				table.insert(buf_client_names, formatter.name)
			end
		end
	end

	-- This needs to be a string only table so we can use concat below
	local unique_client_names = {}
	for _, client_name_target in ipairs(buf_client_names) do
		local is_duplicate = false
		for _, client_name_compare in ipairs(unique_client_names) do
			if client_name_target == client_name_compare then
				is_duplicate = true
			end
		end
		if not is_duplicate then
			table.insert(unique_client_names, client_name_target)
		end
	end

	local client_names_str = table.concat(unique_client_names, ", ")
	local language_servers = string.format("[%s]", client_names_str)

	vim.print(language_servers)
end

--- @alias OperatingSystem
---| 'windows'
---| 'mac'

--- @return OperatingSystem?
M.get_os = function()
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	else
		return "mac"
	end
end

--- @return string
M.get_config_path = function()
	local home_path = vim.fn.expand("$HOME")
	if M.get_os() == "windows" then
		return home_path .. "\\AppData\\Local\\nvim"
	else
		return home_path .. "/.config/nvim"
	end
end

return M
