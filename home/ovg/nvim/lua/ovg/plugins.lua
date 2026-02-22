require("lazy").setup({
	-- Theme
	{
		"projekt0n/github-nvim-theme",
		lazy = false,
		priority = 1000,
		config = function()
			require("github-theme").setup({
				options = {
					transparent = true,
				},
			})
			vim.cmd.colorscheme("github_dark_default")
		end,
	},

	-- Status Line
	{ "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },

	-- Keybindings Help
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if ok then
				configs.setup({
					ensure_installed = { "markdown", "markdown_inline", "lua", "vim", "vimdoc", "query", "c", "cpp", "nix", "glsl", "hlsl", "bash", "fish", "c_sharp", "org" },
					highlight = { enable = true },
					indent = { enable = true },
				})
			else
				local ts = require("nvim-treesitter")
				ts.setup({
					auto_install = true,
					highlight = { enable = true },
				})
			end
		end,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make", -- Requires make and gcc/clang
			},
            "nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					prompt_prefix = "   ",
					sorting_strategy = "ascending",
					layout_config = { prompt_position = "top" },
					file_ignore_patterns = { ".git/", "node_modules/" }, -- Ignore common junk
				},
				extensions = {
					fzf = {
						fuzzy = true, -- false will only do exact matching
						override_generic_sorter = true, -- override the generic sorter
						override_file_sorter = true, -- override the file sorter
						case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					},
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {
                            -- even more opts
                        }
                    }
				},
			})
			-- Load extensions
			telescope.load_extension("fzf")
            telescope.load_extension("ui-select")
		end,
	},

	-- File Explorer
	{
		"francoiscabrol/ranger.vim",
		config = function()
			vim.g.ranger_map_keys = 0
		end,
	},

	-- Org Mode & Org Roam
	{
		"nvim-orgmode/orgmode",
		event = "VeryLazy",
		ft = { "org" },
		config = function()
			-- Setup orgmode
			require("orgmode").setup({
				org_agenda_files = "~/Documents/org/**/*",
				org_default_notes_file = "~/Documents/org/refile.org",
				org_todo_keywords = { "TODO(t)", "NEXT(n)", "STRT(s)", "WAIT(w)", "|", "DONE(d)", "KILL(k)" },
				org_indent_mode = "indent",
				org_hide_emphasis_markers = true,
				org_startup_folded = "inherit",
				mappings = {
					org = {
						org_open_at_point = "<CR>",
					},
					capture = {
						org_capture_finalize = "<C-c><C-c>",
						org_capture_refile = "<C-c><C-w>",
						org_capture_kill = "<C-c><C-k>",
					},
				},
			})

			-- Custom mappings for org files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "org",
				callback = function()
					-- Map gd to follow link in normal mode
					vim.keymap.set("n", "gd", function()
						require("orgmode").action("org_mappings.open_at_point")
					end, { buffer = true, desc = "Org: Follow Link" })

					-- Map <CR> to follow link in normal mode (like Doom Emacs)
					vim.keymap.set("n", "<CR>", function()
						require("orgmode").action("org_mappings.open_at_point")
					end, { buffer = true, desc = "Org: Follow Link" })

					-- Mimic Doom Emacs SPC m mappings for Org files
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
		end,
	},
	{
		"chipsenkbeil/org-roam.nvim",
		ft = { "org" },
		dependencies = {
			"nvim-orgmode/orgmode",
			"nvim-telescope/telescope.nvim",
			"kkharji/sqlite.lua",
		},
		keys = {
			{ "<leader>rf", function() require("org-roam").api.find_node() end, desc = "OrgRoam: Find Node" },
			{ "<leader>ri", function() require("org-roam").api.insert_node() end, desc = "OrgRoam: Insert Node" },
			{ "<leader>rc", function() require("org-roam").api.capture_node() end, desc = "OrgRoam: Capture Node" },
			{ "<leader>rs", function() require("org-roam").api.sync() end, desc = "OrgRoam: Sync Database" },
			{ "<leader>rl", function() require("org-roam").ui.node_buffer.toggle() end, desc = "OrgRoam: Toggle Buffer" },
			{ "<leader>rt", function() require("org-roam").extensions.dailies.capture_today() end, desc = "OrgRoam: Today" },
			{ "<leader>ry", function() require("org-roam").extensions.dailies.capture_yesterday() end, desc = "OrgRoam: Yesterday" },
			{ "<leader>rm", function() require("org-roam").extensions.dailies.capture_tomorrow() end, desc = "OrgRoam: Tomorrow" },
		},
		config = function()
			local roam = require("org-roam")
			roam.setup({
				directory = "~/Documents/org/roam",
				ui = {
					picker = {
						name = "telescope",
					},
				},
				extensions = {
					dailies = {
						directory = "dailies",
					},
				},
				templates = {
					d = {
						description = "default",
						template = "%?",
						target = "%<%Y%m%d%H%M%S>-%[slug].org",
					},
				},
			})
			-- Load the database to initialize it
			roam.database:load()
			pcall(require("telescope").load_extension, "org_roam")

			-- Sync roam database on save of any org file in roam directory
			vim.api.nvim_create_autocmd("BufWritePost", {
				pattern = "*/Documents/org/roam/**/*.org",
				callback = function()
					require("org-roam").database:sync()
				end,
			})
		end,
	},

	-- Git
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
	},

	-- Copilot
	{
		"github/copilot.vim",
		init = function()
			-- Disable default Tab mapping before plugin loads
			vim.g.copilot_no_tab_map = true
		end,
		config = function()
			-- Accept suggestion with Ctrl+l
			vim.keymap.set('i', '<C-l>', 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false
			})
			
			-- Accept word with Ctrl+Shift+l (mapped via <Plug>)
			vim.keymap.set('i', '<C-S-l>', '<Plug>(copilot-accept-word)', { remap = true })
		end
	},

	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local servers = { "lua_ls", "nixd", "clangd", "pyright", "ts_ls", "rust_analyzer", "bashls", "omnisharp", "glslls" }

			-- Support for Neovim 0.11+ using the new LSP configuration API
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

			-- Keymaps on attach
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Buffer local mappings
					local opts = { buffer = ev.buf }
                    local builtin = require("telescope.builtin")

					-- Standard LSP mappings (Telescope versions)
					vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "LSP: Go to Definition", buffer = ev.buf })
					vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP: References", buffer = ev.buf })
					vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "LSP: Go to Implementation", buffer = ev.buf })
					vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover", buffer = ev.buf })

					-- Requested <leader>c mappings
					vim.keymap.set("n", "<leader>cl", builtin.lsp_definitions, { desc = "LSP: Go to Definition", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cr", builtin.lsp_references, { desc = "LSP: References", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename, { desc = "LSP: Rename", buffer = ev.buf })
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Action", buffer = ev.buf })
					vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "LSP: Hover", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration", buffer = ev.buf })
                    vim.keymap.set("n", "<leader>cs", builtin.lsp_document_symbols, { desc = "LSP: Document Symbols", buffer = ev.buf })
                    vim.keymap.set("n", "<leader>cw", builtin.lsp_workspace_symbols, { desc = "LSP: Workspace Symbols", buffer = ev.buf })
				end,
			})
		end,
	},


	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets", -- Add useful snippets
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Load friendly-snippets
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
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<Tab>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item.
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					javascript = { "prettierd", "prettier" },
					nix = { "alejandra" }, -- Nix formatter
					bash = { "shfmt" },
					sh = { "shfmt" },
					fish = { "fish_indent" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},

	-- Linting
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				-- lua = { "luacheck" }, -- lua_ls handles diagnostics usually
                -- nix = { "nix" }, -- nixd handles it
                bash = { "shellcheck" },
                sh = { "shellcheck" },
                glsl = { "glslang" },
                hlsl = { "glslang" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function() --[[@as ev.buf]]
					lint.try_lint()
				end,
			})
		end,
	},

	-- Debugging
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			dap.listeners.before.attach.dapui_config = function() --[[@as ev.buf]]
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function() --[[@as ev.buf]]
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function() --[[@as ev.buf]]
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function() --[[@as ev.buf]]
				dapui.close()
			end
            
            -- Adapters
            dap.adapters.gdb = {
                type = "executable",
                command = "gdb",
                args = { "-i", "dap" }
            }
            dap.configurations.c = {
                {
                    name = "Launch",
                    type = "gdb",
                    request = "launch",
                    program = function() --[[@as ev.buf]]
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
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
                        return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
                    end,
                },
            }

			-- Keymaps
			vim.keymap.set("n", "<leader>cb", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>cc", dap.continue, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<leader>ci", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<leader>co", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<leader>cx", dap.terminate, { desc = "Debug: Terminate" })
			vim.keymap.set("n", "<leader>cu", dapui.toggle, { desc = "Debug: Toggle UI" })
		end,
	},

    -- Autosave
    {
        "okuuva/auto-save.nvim",
        cmd = "ASToggle",
        event = { "InsertLeave", "TextChanged" },
        opts = {
            trigger_events = { "InsertLeave", "TextChanged" },
            debounce_delay = 1000, -- Delay in ms before saving
        },
    },
}, {
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})