return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescriptreact = { "prettierd" },
				css = { "prettierd" },
				html = { "prettierd" },
				json = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				mdx = { "prettierd" },
				graphql = { "prettierd" },
				liquid = { "prettierd" },
				lua = { "stylua" },
				python = { "isort", "black" },
				fennel = { "fnlfmt" },
				scheme = { "scheme-indent" },
				clojure = { "cljfmt" },
			},
			formatters = {
				["scheme-indent"] = {
					command = "scheme-indent",
					stdin = true,
				},
			},
			format_after_save = {
				lsp_format = "fallback",
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({ lsp_format = "fallback", async = false, timeout_ms = 5000 })
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
