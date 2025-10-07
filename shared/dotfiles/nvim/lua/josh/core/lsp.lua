  vim.api.nvim_create_autocmd("LspAttach", {
  	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  	callback = function(ev)
  		local opts = { buffer = ev.buf, silent = true }

  		opts.desc = "Show LSP references"
  		vim.keymap.set("n", "gR", function() Snacks.picker.lsp_references() end, opts)

  		opts.desc = "Go to declaration"
  		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

  		opts.desc = "Go to definition"
  		vim.keymap.set("n", "gd", function() Snacks.picker.lsp_definitions() end, opts)

  		opts.desc = "Show LSP implementations"
  		vim.keymap.set("n", "gi", function() Snacks.picker.lsp_implementations() end, opts)

  		opts.desc = "Show LSP type definitions"
  		vim.keymap.set("n", "gk", function() Snacks.picker.lsp_type_definitions() end, opts)

  		opts.desc = "See available code actions"
  		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

  		opts.desc = "Smart rename"
  		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

  		opts.desc = "Show buffer diagnostics"
  		vim.keymap.set("n", "<leader>D", function() Snacks.picker.diagnostics() end, opts)

  		opts.desc = "Show line diagnostics"
  		vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

  		opts.desc = "Go to previous diagnostic"
  		vim.keymap.set("n", "[d", function()
  			vim.diagnostic.jump({ count = -1, float = true })
  		end, opts)

  		opts.desc = "Go to next diagnostic"
  		vim.keymap.set("n", "]d", function()
  			vim.diagnostic.jump({ count = 1, float = true })
  		end, opts)

  		opts.desc = "Show documentation for what is under cursor"
  		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

  		opts.desc = "Restart LSP"
  		vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

  		opts.desc = "Copy diagnostic with context"
  		vim.keymap.set("n", "<leader>cy", function()
  			local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
  			if #diagnostics > 0 then
  				local diag = diagnostics[1]
  				local filename = vim.fn.expand('%:p')
  				local line = diag.lnum + 1
  				local col = diag.col + 1
  				local message = string.format(
  					"%s:%d:%d: %s: %s",
  					filename,
  					line,
  					col,
  					diag.severity == 1 and "error" or "warning",
  					diag.message
  				)
  				vim.fn.setreg('+', message)
  				vim.notify("Copied: " .. message)
  			else
  				vim.notify("No diagnostic on current line")
  			end
  		end, opts)
  	end,
  })
