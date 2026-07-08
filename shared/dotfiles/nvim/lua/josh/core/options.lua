vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

opt.wrap = false

-- search
opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

-- clipboard
-- opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

opt.mouse = "a"

opt.showmode = false

opt.cmdheight = 0

vim.filetype.add({ extension = { mdx = "mdx" } })
vim.treesitter.language.register("markdown", "mdx")

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

local sel_stack = {}

local function select_node(node)
  if not node then return end
  local sr, sc, er, ec = node:range()
  vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
  vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
  vim.cmd("normal! gv")
end

vim.keymap.set("n", "<CR>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local node = vim.treesitter.get_node({ pos = { row - 1, col } })
  sel_stack = { node }
  select_node(node)
end, { desc = "Init treesitter selection" })

vim.keymap.set("v", "<CR>", function()
  local cur = sel_stack[#sel_stack]
  local parent = cur and cur:parent()
  if parent then
    sel_stack[#sel_stack + 1] = parent
    select_node(parent)
  end
end, { desc = "Expand selection to parent node" })

vim.keymap.set("v", "<BS>", function()
  if #sel_stack > 1 then
    sel_stack[#sel_stack] = nil
    select_node(sel_stack[#sel_stack])
  end
end, { desc = "Shrink selection to child node" })
