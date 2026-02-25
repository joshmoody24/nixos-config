return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "markdown",
        "markdown_inline",
        "bash",
        "dockerfile",
        "lua",
        "vim",
        "gitignore",
        "sql",
        "astro",
        "clojure",
        "glsl",
        "fennel",
        "scheme",
        "elixir",
        "heex",
        "python",
        "gdscript",
      },
    })
  end
}
