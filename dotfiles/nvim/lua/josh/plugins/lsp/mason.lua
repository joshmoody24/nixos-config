return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup()

		mason_lspconfig.setup({
			ensure_installed = {
				"html",
				"lua_ls",
				"emmet_ls",
				"pyright",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				-- formatters
				"prettier",
				"stylua",
				-- linters
				"eslint_d",
			},
		})
	end,
}
