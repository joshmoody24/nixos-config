return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
}
