local function toggle_upper_mark()
	local marks = require("marks")
	marks.refresh(true)

	local state = marks.mark_state
	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local buffer = state.buffers[bufnr] or { placed_marks = {} }
	local marks_to_delete = {}

	for mark, data in pairs(buffer.placed_marks) do
		if mark:match("^[A-Z]$") and data.line == line then
			table.insert(marks_to_delete, mark)
		end
	end

	if #marks_to_delete > 0 then
		for _, mark in ipairs(marks_to_delete) do
			state:delete_mark(mark)
		end
		marks.refresh(true)
		return
	end

	local next_mark
	for byte = string.byte("A"), string.byte("Z") do
		local mark = string.char(byte)
		if not buffer.placed_marks[mark] then
			next_mark = mark
			break
		end
	end

	if not next_mark then
		vim.notify("No available uppercase marks", vim.log.levels.WARN)
		return
	end

	state:place_mark_cursor(next_mark)
	vim.cmd("normal! m" .. next_mark)
	marks.refresh(true)
end

vim.keymap.set("n", "<leader>mm", function()
	require("marks").toggle()
end, { desc = "Toggle lowercase mark" })

vim.keymap.set("n", "<leader>mM", toggle_upper_mark, { desc = "Toggle uppercase mark" })

vim.keymap.set("n", "<leader>mD", function()
	require("marks").delete_buf()
end, { desc = "Delete marks in current file" })

vim.keymap.set("n", "<leader>mj", function()
	local marks = require("marks")
	marks.refresh(true)
	marks.next()
end, { desc = "Next mark" })

vim.keymap.set("n", "<leader>mk", function()
	local marks = require("marks")
	marks.refresh(true)
	marks.prev()
end, { desc = "Previous mark" })
