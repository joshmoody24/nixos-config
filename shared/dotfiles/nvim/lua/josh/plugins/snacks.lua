return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		explorer = {
			enabled = true,
			follow_file = true,
			auto_close = true,
			jump = { close = true },
		},
		gitbrowse = { enabled = true },
		input = { enabled = true },
		picker = {
			enabled = true,
			-- Telescope layout with slight modifications to skew towards Snack defaults
			-- When it's a function, Snacks.explorer() continues to use the default for some reason (desirable)
			layout = function()
				return {
					reverse = true,
					cycle = true,
					layout = {
						box = "horizontal",
						backdrop = false,
						width = 0.8,
						height = 0.8,
						border = "none",
						{
							box = "vertical",
							{ win = "list", border = "none", title = " Results ", title_pos = "center", border = "rounded" },
							{ win = "input", height = 1, border = "rounded", title = "{title} {flags}", title_pos = "center" }, 
						},
						{
							win = "preview",
							title = "{preview}",
							width = 0.4,
							border = "rounded",
						},
					},
				}
			end,
			formatters = {
				file = {
					truncate = 60,
					filename_first = true,
				}
			},
			sources = {
				explorer = {
					follow_file = true,
					auto_close = true,
					jump = { close = true },
					layout = {
						layout = {
							position = "right",
						}
					}
				}
			},
		},
		notifier = { enabled = true },
		quickfile = { enabled = true },
		-- scope = { enabled = true },
		scroll = { enabled = true },
		terminal = { enabled = true },
		styles = {
			input = {
				relative = "cursor",
				row = -3,
				col = -5,
			},
		},
	},
	keys = {
		-- Pickers
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep files" },
		{ "<leader>fb", function() Snacks.explorer() end, desc = "File explorer" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files}" },
		{ "<leader>fc", function() Snacks.picker.commands() end, desc = "Commands explorer" },
		{ "<leader>fh", function() Snacks.picker.command_history() end, desc = "Commands explorer" },
		{ "<leader>f<space>", function() Snacks.picker.smart() end, desc = "Smart find files" },

		-- Terminal
		{ "<leader>t", function() Snacks.terminal() end, desc = "Terminal" },

		-- ast-grep structural search
		{ "<leader>faf", function()
			vim.ui.input({ prompt = "ast-grep pattern: " }, function(pattern)
				if not pattern or pattern == "" then return end
				local items = {}
				local output = vim.fn.system({ "ast-grep", "run", "--pattern", pattern, "--json" })
				local ok, matches = pcall(vim.json.decode, output)
				if ok and matches then
					for _, match in ipairs(matches) do
						local lnum = match.range.start.line + 1
						local col = match.range.start.column + 1
						table.insert(items, {
							text = match.file .. ":" .. lnum .. " " .. vim.trim(match.lines or ""),
							file = match.file,
							pos = { lnum, col },
						})
					end
				end
				Snacks.picker({
					title = 'ast-grep: "' .. pattern .. '" (' .. #items .. " matches)",
					items = items,
					format = "file",
				})
			end)
		end, desc = "ast-grep find" },

		-- ast-grep structural replace
		{ "<leader>far", function()
			vim.ui.input({ prompt = "ast-grep pattern: " }, function(pattern)
				if not pattern or pattern == "" then return end
				vim.ui.input({ prompt = "ast-grep rewrite: " }, function(rewrite)
					if rewrite == nil then return end
					local result = vim.fn.system({
						"ast-grep", "run",
						"--pattern", pattern,
						"--rewrite", rewrite,
						"--update-all",
					})
					vim.notify(result ~= "" and result or "ast-grep: no matches", vim.log.levels.INFO)
					vim.cmd("checktime") -- reload any modified buffers
				end)
			end)
		end, desc = "ast-grep replace" },

		-- Git
		{ "<leader>gr", function() Snacks.gitbrowse() end, desc = "Open file in browser on git remote" },
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git log for current line" },
	}
}

