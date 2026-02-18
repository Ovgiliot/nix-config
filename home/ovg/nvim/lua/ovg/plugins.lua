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
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				defaults = {
					prompt_prefix = "   ",
					sorting_strategy = "ascending",
					layout_config = { prompt_position = "top" },
				},
			})
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
			})
		end,
	},
	{
		"chipsenkbeil/org-roam.nvim",
		dependencies = {
			"nvim-orgmode/orgmode",
		},
		config = function()
			require("org-roam").setup({
				directory = "~/Documents/org/roam",
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

					-- Standard LSP mappings
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
					vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover", buffer = ev.buf })
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation", buffer = ev.buf })

					-- Requested <leader>c mappings
					vim.keymap.set("n", "<leader>cl", vim.lsp.buf.definition, { desc = "LSP: Go to Definition", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cr", vim.lsp.buf.references, { desc = "LSP: References", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename, { desc = "LSP: Rename", buffer = ev.buf })
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Action", buffer = ev.buf })
					vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "LSP: Hover", buffer = ev.buf })
					vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration", buffer = ev.buf })
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
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args) -- For `luasnip` users.
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<Tab>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm.
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
				}, {
					{ name = 'buffer' },
				})
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
				                    nix = { "alejandra" },
				                    bash = { "shfmt" },
				                    sh = { "shfmt" },
				                    fish = { "fish_indent" },
								},
				                format_on_save = {                timeout_ms = 500,
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
}, {
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})