return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		explorer = { enabled = true },
		input = { enabled = true },
		picker = {
			enabled = true,
			-- Telescope layout with slight modifications to skew towards Snack defaults
			-- When it's a function, Snacks.explorer() continues to use the default for some reason (desirable)
			layout = function()
				return {
					reverse = true,
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
							width = 0.5,
							border = "rounded",
						},
					},
				}
			end
		},
		notifier = { enabled = true },
		quickfile = { enabled = true },
		-- scope = { enabled = true },
		scroll = { enabled = true },
		-- statuscolumn = { enabled = true },
		-- words = { enabled = true },
		styles = {
			input = {
				relative = "cursor",
				row = -3,
				col = -5,
			},
		},
	},
	keys = {
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep files" },
		{ "<leader>fb", function() Snacks.explorer() end, desc = "File explorer" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files}" }
	}
}

