return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup()

		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		mason_lspconfig.setup({
			ensure_installed = { "html", "emmet_ls", "pyright", "lua_ls" },
		})

		-- Modern approach: use vim.lsp.config instead of lspconfig.server.setup()
		vim.lsp.config("html", { capabilities = capabilities })
		vim.lsp.config("emmet_ls", { capabilities = capabilities })
		vim.lsp.config("pyright", { capabilities = capabilities })
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
				},
			},
		})
		vim.lsp.config("tsgo", {
			capabilities = capabilities,
		})
		vim.lsp.enable("tsgo")

		mason_tool_installer.setup({
			ensure_installed = { "prettier", "stylua", "eslint_d" },
		})
	end,
}
