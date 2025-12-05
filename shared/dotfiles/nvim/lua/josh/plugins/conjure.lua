return {
	{
		"Olical/conjure",
		ft = { "clojure", "python", "fennel", "scheme", "racket" },
		lazy = true,
		init = function()
			-- Set configuration options here
			vim.g["conjure#filetype#fennel"] = "conjure.client.fennel.stdio"
			-- MIT Scheme is the default

			-- Auto-start nREPL for Clojure
			vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = true
			vim.g["conjure#client#clojure#nrepl#connection#auto_repl#cmd"] = "clj -Sdeps '{:deps {nrepl/nrepl {:mvn/version \"1.0.0\"} cider/cider-nrepl {:mvn/version \"0.42.1\"}}}' -M -m nrepl.cmdline --middleware '[\"cider.nrepl/cider-middleware\"]' --interactive"
		end,
		-- Optional cmp-conjure integration
		dependencies = { "PaterJason/cmp-conjure" },
	},
	{
		"PaterJason/cmp-conjure",
		lazy = true,
		config = function()
			local cmp = require("cmp")
			local config = cmp.get_config()
			table.insert(config.sources, { name = "conjure" })
			return cmp.setup(config)
		end,
	},
}
