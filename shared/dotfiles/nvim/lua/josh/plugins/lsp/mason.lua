return {
	"williamboman/mason.nvim",
	dependencies = {
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
		local servers = { "html", "lua_ls", "emmet_ls", "pyright" }
		mason_lspconfig.setup({
			ensure_installed = servers,
		})
		for _, srv in ipairs(servers) do
			vim.lsp.config(srv, { capabilities = capabilities })
		end

		require("lspconfig").clojure_lsp.setup({
			cmd = { "/etc/profiles/per-user/josh/bin/clojure-lsp" },
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
