vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("i", "jk", "<Esc>")

local function telescope_builtin(fn)
	return function()
		require("telescope.builtin")[fn]()
	end
end

vim.keymap.set("n", "<leader>ff", telescope_builtin("find_files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", telescope_builtin("live_grep"), { desc = "Live grep" })
vim.keymap.set("n", "<leader>,", telescope_builtin("buffers"), { desc = "Buffers" })
vim.keymap.set("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bk", "<cmd>bdelete<cr>", { desc = "Kill buffer" })
vim.keymap.set("n", "<leader>fh", telescope_builtin("help_tags"), { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", telescope_builtin("oldfiles"), { desc = "Recent files" })
vim.keymap.set("n", "<leader>fs", telescope_builtin("current_buffer_fuzzy_find"), { desc = "Search in buffer" })

vim.keymap.set("n", "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Markdown Render" })

vim.keymap.set("n", "<leader>tc", function()
	if vim.g.copilot_enabled == 1 or vim.g.copilot_enabled == nil then
		vim.cmd("Copilot disable")
		vim.g.copilot_enabled = 0
		print("Copilot disabled")
	else
		vim.cmd("Copilot enable")
		vim.g.copilot_enabled = 1
		print("Copilot enabled")
	end
end, { desc = "Toggle Copilot" })

vim.keymap.set("n", "<leader>.", "<cmd>Ranger<cr>", { desc = "Open ranger" })

