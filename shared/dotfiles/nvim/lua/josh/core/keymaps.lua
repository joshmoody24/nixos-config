vim.g.mapleader = ";"

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "g#", function()
	local tabnum = vim.fn.input("Go to tab #: ")
	if tabnum:match("^%d+$") then
		vim.cmd("tabn " .. tabnum)
	else
		print("Invalid tab number")
	end
end, { desc = "Go to tab number" })

for i = 1, 9 do
	keymap.set("n", "gn" .. i, function()
		vim.cmd("tabn " .. i)
	end, { desc = "Go to tab " .. i })
end
