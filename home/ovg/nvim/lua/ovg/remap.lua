-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Quick escape from insert mode using 'jk'
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Helper for Telescope commands
local function telescope_builtin(fn)
	return function()
		require("telescope.builtin")[fn]()
	end
end

-- File Navigation
vim.keymap.set("n", "<leader>ff", telescope_builtin("find_files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", telescope_builtin("live_grep"), { desc = "Live grep (text search)" })
vim.keymap.set("n", "<leader>,", telescope_builtin("buffers"), { desc = "Switch Buffers" })
vim.keymap.set("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bk", "<cmd>bdelete<cr>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>fh", telescope_builtin("help_tags"), { desc = "Search Help" })
vim.keymap.set("n", "<leader>fr", telescope_builtin("oldfiles"), { desc = "Recent files" })
vim.keymap.set("n", "<leader>fs", telescope_builtin("current_buffer_fuzzy_find"), { desc = "Search in current buffer" })

-- Markdown Preview
vim.keymap.set("n", "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Markdown Render" })

-- Copilot Toggle
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

-- File Manager (Ranger)
vim.keymap.set("n", "<leader>.", "<cmd>Ranger<cr>", { desc = "Open Ranger file manager" })

-- Tab Management
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab" })
vim.keymap.set("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
vim.keymap.set("n", "<leader>td", "<cmd>tabclose<cr>", { desc = "Close tab" })

-- Search Utilities
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Window Management
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Focus left window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Focus bottom window" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Focus top window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Focus right window" })
vim.keymap.set("n", "<leader>ww", "<C-w>w", { desc = "Cycle windows" })
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })

-- Git Integration (Neogit)
vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<cr>", { desc = "Neogit status" })
vim.keymap.set("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
vim.keymap.set("n", "<leader>gp", "<cmd>Neogit push<cr>", { desc = "Neogit push" })
vim.keymap.set("n", "<leader>gl", "<cmd>Neogit pull<cr>", { desc = "Neogit pull" })
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open Diffview" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history" })

-- Org Mode
vim.keymap.set("n", "<leader>oa", "<cmd>Org agenda<cr>", { desc = "Org: Open Agenda" })
vim.keymap.set("n", "<leader>oc", "<cmd>Org capture<cr>", { desc = "Org: Capture Task" })

