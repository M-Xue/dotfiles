vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.linebreak = true
vim.opt.pumheight = 15

vim.opt.signcolumn = "yes:1"

vim.g.loaded_matchparen = 0

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.undofile = true

vim.opt.winborder = "solid"

vim.opt.wrap = true
vim.opt.breakindent = true

-- vim.o.autoindent = true
-- vim.o.smartindent = true

-- vim.opt.list = true
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- vim.opt.cursorline = true

-- if _util.get_os() == 'windows' then
--     vim.o.shell = "powershell.exe"
-- end

vim.cmd("set colorcolumn=80")
