return {
	"folke/tokyonight.nvim",
	priority = 1000,
	config = function()
		require("tokyonight").setup({
			style = "night", -- storm, moon, night, day
			on_highlights = function(hl, c)
				hl["@comment.important"] = { fg = c.bg, bg = c.warning, bold = true, italic = false }
			end,
		})
		vim.cmd("colorscheme tokyonight")
	end,
}
