return {
  "windwp/nvim-autopairs",
  event = { "InsertEnter" },
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  config = function()
    local autopairs = require("nvim-autopairs")

    autopairs.setup({
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        java = false,
      },
    })

    -- Disable ' autopairing for Lisp languages (used for quoting)
    local cond = require("nvim-autopairs.conds")
    local lisp_fts = { "clojure", "scheme", "lisp", "fennel", "racket" }
    autopairs.get_rules("'")[1]:with_pair(cond.not_filetypes(lisp_fts))

  local cmp_autopairs = require("nvim-autopairs.completion.cmp")

  local cmp = require("cmp")

  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
}
