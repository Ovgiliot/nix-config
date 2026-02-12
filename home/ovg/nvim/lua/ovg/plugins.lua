require("lazy").setup({
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

	{ "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
				return
			end
			configs.setup({
				ensure_installed = { "markdown", "markdown_inline" },
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
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
	{
		"francoiscabrol/ranger.vim",
		config = function()
			vim.g.ranger_map_keys = 0
		end,
	},
	{
		"obsidian-nvim/obsidian.nvim",
		event = "BufReadPost *.md",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Assuming Treesitter is needed for parsing
		config = function()
			require("obsidian").setup({
				workspaces = {
					{
						name = "home",
						path = "/home/ovg/Documents/home/",
					},
					{
						name = "mil",
						path = "/home/ovg/Documents/mil/",
					},
				},
				ui = {
					enable = false,
				},
			})
		end,
	},
	{
		"github/copilot.vim",
		event = "InsertEnter",
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
	},
})
