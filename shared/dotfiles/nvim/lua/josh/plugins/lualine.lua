return {
	"nvim-lualine/lualine.nvim",
	requires = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = {
		options = {
			icons_enabled = false,
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {},
			lualine_c = { { "filename", path = 1 } },
			lualine_x = {},
			lualine_y = { "progress" },
			lualine_z = {},
		},
	},
}
