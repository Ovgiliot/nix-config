-- Plugin configuration.
-- All plugins are declared in home/ovg/default.nix (programs.neovim.plugins).
-- This file only configures them — no plugin manager, no lazy specs.

-- ---------------------------------------------------------------------------
-- Highlights
-- ---------------------------------------------------------------------------
-- Static highlight overrides using ANSI cterm indices.
-- Actual colors are provided by the terminal (matugen → ghostty palette).
require("ovg.highlights")

-- ---------------------------------------------------------------------------
-- Status Line
-- ---------------------------------------------------------------------------
require("lualine").setup({ options = { theme = require("ovg.lualine_theme") } })

-- ---------------------------------------------------------------------------
-- Keybindings Help
-- ---------------------------------------------------------------------------
local wk = require("which-key")
wk.setup({})
wk.add({
	{ "<leader>a", group = "ai" },
	{ "<leader>b", group = "buffer" },
	{ "<leader>c", group = "code" },
	{ "<leader>f", group = "find" },
	{ "<leader>g", group = "git" },
	{ "<leader>m", group = "org-mode" },
	{ "<leader>o", group = "org" },
	{ "<leader>r", group = "roam" },
	{ "<leader>t", group = "tab" },
	{ "<leader>w", group = "window" },
})

-- ---------------------------------------------------------------------------
-- Telescope
-- ---------------------------------------------------------------------------
local telescope = require("telescope")
telescope.setup({
	defaults = {
		prompt_prefix = "   ",
		sorting_strategy = "ascending",
		layout_config = { prompt_position = "top" },
		file_ignore_patterns = { ".git/", "node_modules/" },
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})
telescope.load_extension("fzf")
telescope.load_extension("ui-select")

-- ---------------------------------------------------------------------------
-- File Management (ranger-nvim)
-- ---------------------------------------------------------------------------
require("ranger-nvim").setup({ replace_netrw = false })

-- ---------------------------------------------------------------------------
-- Org Mode
-- ---------------------------------------------------------------------------
require("orgmode").setup({
	org_agenda_files = "~/Documents/org/**/*",
	org_default_notes_file = "~/Documents/org/refile.org",
	org_todo_keywords = { "TODO(t)", "NEXT(n)", "STRT(s)", "WAIT(w)", "|", "DONE(d)", "KILL(k)" },
	org_indent_mode = "indent",
	org_hide_emphasis_markers = true,
	org_startup_folded = "showeverything",
	mappings = {
		org = {
			org_open_at_point = "<CR>",
			org_next_visible_heading = false,
			org_previous_visible_heading = false,
		},
		capture = {
			org_capture_finalize = "<C-c><C-c>",
			org_capture_refile = "<C-c><C-w>",
			org_capture_kill = "<C-c><C-k>",
		},
	},
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "org",
	callback = function()
		vim.keymap.set("n", "gd", function()
			require("orgmode").action("org_mappings.open_at_point")
		end, { buffer = true, desc = "Org: Follow Link" })

		vim.keymap.set("n", "<CR>", function()
			require("orgmode").action("org_mappings.open_at_point")
		end, { buffer = true, desc = "Org: Follow Link" })

		vim.keymap.set("n", "<leader>mt", "<cmd>Org todo<cr>", { buffer = true, desc = "Org: Todo" })
		vim.keymap.set("n", "<leader>ms", "<cmd>Org schedule<cr>", { buffer = true, desc = "Org: Schedule" })
		vim.keymap.set("n", "<leader>md", "<cmd>Org deadline<cr>", { buffer = true, desc = "Org: Deadline" })
		vim.keymap.set("n", "<leader>mi", "<cmd>Org toggle-checkbox<cr>", { buffer = true, desc = "Org: Toggle Checkbox" })
		vim.keymap.set("n", "<leader>ml", "<cmd>Org insert-link<cr>", { buffer = true, desc = "Org: Insert Link" })
		vim.keymap.set("n", "<leader>ma", "<cmd>Org agenda<cr>", { buffer = true, desc = "Org: Agenda" })
		vim.keymap.set("n", "<leader>mc", "<cmd>Org capture<cr>", { buffer = true, desc = "Org: Capture" })
		vim.keymap.set("n", "<leader>me", "<cmd>Org export-dispatch<cr>", { buffer = true, desc = "Org: Export" })
		vim.keymap.set("n", "<leader>mp", "<cmd>Org set-tags-command<cr>", { buffer = true, desc = "Org: Set Tags" })
	end,
})

-- ---------------------------------------------------------------------------
-- Org Roam
-- ---------------------------------------------------------------------------
local roam = require("org-roam")
roam.setup({
	directory = "~/Documents/org/roam",
	-- Suppress default <leader>nf/<leader>ni; we use <leader>rf/<leader>ri below
	bindings = { find_node = "", insert_node = "" },
	extensions = {
		dailies = { directory = "dailies" },
	},
	templates = {
		d = {
			description = "default",
			template = "%?",
			target = "%<%Y%m%d%H%M%S>-%[slug].org",
		},
	},
})
roam.database:load()

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*/Documents/org/roam/**/*.org",
	callback = function()
		require("org-roam").database:sync()
	end,
})

-- Org Roam keymaps
vim.keymap.set("n", "<leader>rf", function()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local entries = {}
	for _, id in ipairs(roam.database:ids()) do
		local node = roam.database:get_sync(id)
		if node then
			table.insert(entries, { id = id, title = node.title, node = node })
			for _, alias in ipairs(node.aliases or {}) do
				table.insert(entries, { id = id, title = alias, node = node })
			end
		end
	end

	pickers
		.new({}, {
			prompt_title = "OrgRoam: Find Node",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(e)
					return { value = e, display = e.title, ordinal = e.title }
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local sel = action_state.get_selected_entry()
					local input = action_state.get_current_line()
					actions.close(prompt_bufnr)
					if sel then
						local node = sel.value.node
						vim.cmd.edit(node.file)
						vim.api.nvim_win_set_cursor(0, { node.range.start.row + 1, node.range.start.column })
					elseif input and input ~= "" then
						roam.api.capture_node({ title = input })
					end
				end)
				return true
			end,
		})
		:find()
end, { desc = "OrgRoam: Find Node" })

vim.keymap.set("n", "<leader>ri", function()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local winnr = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(winnr)

	local entries = {}
	for _, id in ipairs(roam.database:ids()) do
		local node = roam.database:get_sync(id)
		if node then
			table.insert(entries, { id = id, title = node.title, node = node })
			for _, alias in ipairs(node.aliases or {}) do
				table.insert(entries, { id = id, title = alias, node = node })
			end
		end
	end

	pickers
		.new({}, {
			prompt_title = "OrgRoam: Insert Node",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(e)
					return { value = e, display = e.title, ordinal = e.title }
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local sel = action_state.get_selected_entry()
					local input = action_state.get_current_line()
					actions.close(prompt_bufnr)
					if sel then
						local link = string.format("[[id:%s][%s]]", sel.value.id, sel.value.title)
						vim.api.nvim_set_current_win(winnr)
						local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""
						local col = cursor[2]
						local new_line = line:sub(1, col) .. link .. line:sub(col + 1)
						vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
						vim.api.nvim_win_set_cursor(winnr, { cursor[1], col + #link })
					elseif input and input ~= "" then
						roam.api.insert_node({ title = input })
					end
				end)
				return true
			end,
		})
		:find()
end, { desc = "OrgRoam: Insert Node" })

vim.keymap.set("n", "<leader>rc", function()
	require("org-roam").api.capture_node()
end, { desc = "OrgRoam: Capture Node" })

vim.keymap.set("n", "<leader>rs", function()
	require("org-roam").api.sync()
end, { desc = "OrgRoam: Sync Database" })

vim.keymap.set("n", "<leader>rl", function()
	require("org-roam").ui.node_buffer.toggle()
end, { desc = "OrgRoam: Toggle Buffer" })

vim.keymap.set("n", "<leader>rt", function()
	require("org-roam").extensions.dailies.capture_today()
end, { desc = "OrgRoam: Today" })

vim.keymap.set("n", "<leader>ry", function()
	require("org-roam").extensions.dailies.capture_yesterday()
end, { desc = "OrgRoam: Yesterday" })

vim.keymap.set("n", "<leader>rm", function()
	require("org-roam").extensions.dailies.capture_tomorrow()
end, { desc = "OrgRoam: Tomorrow" })

-- ---------------------------------------------------------------------------
-- Org Mode Styling
-- ---------------------------------------------------------------------------
require("headlines").setup({
	org = {
		headline_highlights = {
			"Headline1",
			"Headline2",
			"Headline3",
			"Headline4",
			"Headline5",
			"Headline6",
		},
	},
})

-- Re-apply highlights after any :colorscheme command resets them.
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		require("ovg.highlights")
	end,
})

-- ---------------------------------------------------------------------------
-- Git
-- ---------------------------------------------------------------------------
require("neogit").setup({})

-- ---------------------------------------------------------------------------
-- Copilot
-- ---------------------------------------------------------------------------
-- Disable default Tab mapping before plugin initialises
vim.g.copilot_no_tab_map = true

vim.keymap.set("i", "<C-l>", 'copilot#Accept("\\<CR>")', {
	expr = true,
	replace_keycodes = false,
})
vim.keymap.set("i", "<C-S-l>", "<Plug>(copilot-accept-word)", { remap = true })

-- ---------------------------------------------------------------------------
-- Snacks (required by opencode.nvim)
-- ---------------------------------------------------------------------------
require("snacks").setup({
	input = {},
	picker = {},
	terminal = {},
})

-- ---------------------------------------------------------------------------
-- OpenCode AI
-- ---------------------------------------------------------------------------
vim.keymap.set({ "n", "v" }, "<leader>aa", function()
	require("opencode").ask()
end, { desc = "OpenCode: Ask" })

vim.keymap.set({ "n", "v" }, "<leader>ao", function()
	require("opencode").toggle()
end, { desc = "OpenCode: Toggle" })

vim.keymap.set({ "n", "x" }, "go", function()
	return require("opencode").operator()
end, { expr = true, desc = "OpenCode: Operator" })

vim.keymap.set("n", "goo", function()
	return require("opencode").operator() .. "_"
end, { expr = true, desc = "OpenCode: Operator Line" })

-- ---------------------------------------------------------------------------
-- LSP
-- ---------------------------------------------------------------------------
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local servers = { "lua_ls", "nixd", "clangd", "pyright", "ts_ls", "rust_analyzer", "bashls", "omnisharp", "glslls" }

if vim.lsp.config and vim.lsp.enable then
	vim.lsp.config("*", { capabilities = capabilities })

	for _, lsp in ipairs(servers) do
		local config = {}
		local executable = lsp

		if lsp == "lua_ls" then
			if vim.fn.executable("lua-language-server") == 1 then
				executable = "lua-language-server"
			end
			config.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
		elseif lsp == "omnisharp" then
			if vim.fn.executable("OmniSharp") == 1 then
				config.cmd = { "OmniSharp" }
			elseif vim.fn.executable("omnisharp") == 1 then
				config.cmd = { "omnisharp" }
			end
			config.enable_roslyn_analyzers = true
			config.analyze_open_documents_only = true
			config.enable_import_completion = true
		end

		if vim.fn.executable(executable) == 1 then
			if next(config) ~= nil then
				vim.lsp.config(lsp, config)
			end
			vim.lsp.enable(lsp)
		end
	end
else
	-- Fallback for older Neovim versions
	local lspconfig = require("lspconfig")
	for _, lsp in ipairs(servers) do
		local config = { capabilities = capabilities }
		local executable = lsp

		if lsp == "lua_ls" then
			if vim.fn.executable("lua-language-server") == 1 then
				executable = "lua-language-server"
			end
			config.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
		elseif lsp == "omnisharp" then
			if vim.fn.executable("OmniSharp") == 1 then
				config.cmd = { "OmniSharp" }
			elseif vim.fn.executable("omnisharp") == 1 then
				config.cmd = { "omnisharp" }
			end
			config.enable_roslyn_analyzers = true
			config.analyze_open_documents_only = true
			config.enable_import_completion = true
		end

		if vim.fn.executable(executable) == 1 then
			lspconfig[lsp].setup(config)
		end
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local builtin = require("telescope.builtin")

		vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "LSP: Go to Definition", buffer = ev.buf })
		vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP: References", buffer = ev.buf })
		vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "LSP: Go to Implementation", buffer = ev.buf })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover", buffer = ev.buf })

		vim.keymap.set("n", "<leader>cl", builtin.lsp_definitions, { desc = "LSP: Go to Definition", buffer = ev.buf })
		vim.keymap.set("n", "<leader>cr", builtin.lsp_references, { desc = "LSP: References", buffer = ev.buf })
		vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename, { desc = "LSP: Rename", buffer = ev.buf })
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Action", buffer = ev.buf })
		vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "LSP: Hover", buffer = ev.buf })
		vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration", buffer = ev.buf })
		vim.keymap.set("n", "<leader>cs", builtin.lsp_document_symbols, { desc = "LSP: Document Symbols", buffer = ev.buf })
		vim.keymap.set("n", "<leader>cw", builtin.lsp_workspace_symbols, { desc = "LSP: Workspace Symbols", buffer = ev.buf })
		vim.keymap.set("n", "<leader>ct", builtin.lsp_type_definitions, { desc = "LSP: Type Definition", buffer = ev.buf })
	end,
})

-- ---------------------------------------------------------------------------
-- Completion
-- ---------------------------------------------------------------------------
local cmp = require("cmp")
local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-y>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<Tab>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

-- ---------------------------------------------------------------------------
-- Formatting
-- ---------------------------------------------------------------------------
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettierd", "prettier" },
		nix = { "alejandra" },
		bash = { "shfmt" },
		sh = { "shfmt" },
		fish = { "fish_indent" },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
})

vim.keymap.set("", "<leader>cf", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- ---------------------------------------------------------------------------
-- Linting
-- ---------------------------------------------------------------------------
local lint = require("lint")
lint.linters_by_ft = {
	bash = { "shellcheck" },
	sh = { "shellcheck" },
	glsl = { "glslang" },
	hlsl = { "glslang" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		lint.try_lint()
	end,
})

-- ---------------------------------------------------------------------------
-- Debugging
-- ---------------------------------------------------------------------------
local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

dap.listeners.before.attach.dapui_config = function()
	dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
	dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	dapui.close()
end

dap.adapters.gdb = {
	type = "executable",
	command = "gdb",
	args = { "-i", "dap" },
}
dap.configurations.c = {
	{
		name = "Launch",
		type = "gdb",
		request = "launch",
		program = function()
			local co = coroutine.running()
			vim.ui.input(
				{ prompt = "Path to executable: ", default = vim.fn.getcwd() .. "/", completion = "file" },
				function(input)
					coroutine.resume(co, input or "")
				end
			)
			return coroutine.yield()
		end,
		cwd = "${workspaceFolder}",
		stopAtBeginningOfMainSubprogram = false,
	},
}
dap.configurations.cpp = dap.configurations.c

dap.adapters.coreclr = {
	type = "executable",
	command = "netcoredbg",
	args = { "--interpreter=vscode" },
}
dap.configurations.cs = {
	{
		type = "coreclr",
		name = "launch - netcoredbg",
		request = "launch",
		program = function()
			local co = coroutine.running()
			vim.ui.input(
				{ prompt = "Path to dll: ", default = vim.fn.getcwd() .. "/bin/Debug/", completion = "file" },
				function(input)
					coroutine.resume(co, input or "")
				end
			)
			return coroutine.yield()
		end,
	},
}

vim.keymap.set("n", "<leader>cb", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>cc", dap.continue, { desc = "Debug: Continue" })
vim.keymap.set("n", "<leader>ci", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<leader>co", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<leader>cx", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>cu", dapui.toggle, { desc = "Debug: Toggle UI" })

-- ---------------------------------------------------------------------------
-- Autosave
-- ---------------------------------------------------------------------------
require("auto-save").setup({})
