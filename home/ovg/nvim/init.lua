-- Enable the experimental Lua module loader for faster startup
if vim.loader then
	vim.loader.enable()
end

-- Leader keys (must be set before plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Enable treesitter highlighting for any filetype that has a parser available.
-- Parsers are provided by Nix (pkgs.vimPlugins.nvim-treesitter.withPlugins).
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

-- General Options
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.signcolumn = "yes" -- Always show the sign column (prevents text shifting)
vim.opt.cursorline = true -- Highlight the current line
vim.opt.termguicolors = true  -- Enable 24-bit RGB colors (required for matugen hex themes)
vim.opt.background = "dark"  -- Dark background hint for plugins that adapt to it

-- Clipboard
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard

-- Indentation
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.shiftwidth = 4 -- Size of an indent
vim.opt.softtabstop = 4 -- Number of spaces a <Tab> counts for while editing
vim.opt.breakindent = true -- Maintain indent on wrapped lines
vim.opt.linebreak = true -- Wrap at word boundaries, not mid-word

-- Keyboard layout — generated langmap for layout-agnostic normal mode.
-- See modules/home/core/keymap.nix for the source of truth.
require("ovg.langmap")

-- Search
vim.opt.ignorecase = true -- Ignore case when searching...
vim.opt.smartcase = true -- ...unless uppercase letters are used

-- Window Splitting
vim.opt.splitright = true -- Force all vertical splits to go to the right of current window
vim.opt.splitbelow = true -- Force all horizontal splits to go below current window

-- Undo
vim.opt.undofile = true -- Save undo history to a file
vim.opt.swapfile = false -- Disable swap files (prevents "ATTENTION" errors on improper exit)

-- UX/UI
vim.opt.scrolloff = 8 -- Minimal number of screen lines to keep above and below the cursor
vim.opt.updatetime = 250 -- Decrease update time (default 4000ms) for better IO/UX
vim.opt.timeoutlen = 400 -- Time to wait for a mapped sequence to complete (in ms)
vim.opt.conceallevel = 2 -- Conceal text (useful for Markdown/Org mode)
vim.opt.autoread = true -- Reload files changed outside of Neovim

require("ovg.remap")
require("ovg.plugins")
