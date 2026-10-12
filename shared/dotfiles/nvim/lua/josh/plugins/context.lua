return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		-- The master branch predates Neovim 0.11's query API and crashes on
		-- markdown injections. Pin it so a lock update can't drift back.
		{ "nvim-treesitter/nvim-treesitter", branch = "main" },
	},
}
