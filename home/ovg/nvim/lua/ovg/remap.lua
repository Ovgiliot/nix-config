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

vim.keymap.set("n", "<leader>ac", function()
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

-- Tabs
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab" })
vim.keymap.set("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
vim.keymap.set("n", "<leader>td", "<cmd>tabclose<cr>", { desc = "Close tab" })

-- Search
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Window switching
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Switch to left window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Switch to bottom window" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Switch to top window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Switch to right window" })
vim.keymap.set("n", "<leader>ww", "<C-w>w", { desc = "Switch to other window" })
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows" })

-- Neogit
vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<cr>", { desc = "Neogit status" })
vim.keymap.set("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
vim.keymap.set("n", "<leader>gp", "<cmd>Neogit push<cr>", { desc = "Neogit push" })
vim.keymap.set("n", "<leader>gl", "<cmd>Neogit pull<cr>", { desc = "Neogit pull" })
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview open" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history" })

-- Obsidian
vim.keymap.set("n", "<leader>oo", "<cmd>Obsidian quick_switch<cr>", { desc = "Quick Switch" })
vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "New Note" })
vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "Search Vault" })
vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian today<cr>", { desc = "Today's Note" })
vim.keymap.set("n", "<leader>oy", "<cmd>Obsidian yesterday<cr>", { desc = "Yesterday's Note" })
vim.keymap.set("n", "<leader>om", "<cmd>Obsidian tomorrow<cr>", { desc = "Tomorrow's Note" })
vim.keymap.set("n", "<leader>of", "<cmd>Obsidian follow<cr>", { desc = "Follow Link" })
vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Backlinks" })
vim.keymap.set("n", "<leader>oi", "<cmd>Obsidian template<cr>", { desc = "Insert Template" })

