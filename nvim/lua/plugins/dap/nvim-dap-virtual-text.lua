-- Shows variable values inline next to the code while stopped.
return {
	"theHamsta/nvim-dap-virtual-text",
	lazy = true,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		commented = false,
		virt_text_pos = "eol",
		all_frames = false,
	},
}
