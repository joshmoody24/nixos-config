return {
	"folke/tokyonight.nvim",
	priority = 1000,
	config = function()
		require("tokyonight").setup({
			style = "night", -- storm, moon, night, day
			on_highlights = function(hl, c)
				hl["@comment.important"] = { fg = c.yellow, bold = true, italic = false }
			end,
		})
		vim.cmd("colorscheme tokyonight")
	end,
}
