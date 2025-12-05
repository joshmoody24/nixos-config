return {
  "julienvincent/nvim-paredit",
  config = function()
    local paredit = require("nvim-paredit")
    paredit.setup()

    -- Wrapping
    vim.keymap.set("n", "<localleader>w", function()
      paredit.api.wrap_element_under_cursor("(", ")")
    end, { desc = "Wrap element" })

    vim.keymap.set("n", "<localleader>W", function()
      paredit.api.wrap_enclosing_form_under_cursor("(", ")")
    end, { desc = "Wrap enclosing form" })

    vim.keymap.set("n", "<localleader>u", function()
      paredit.api.unwrap_form_under_cursor()
    end, { desc = "Unwrap form" })
  end,
}
