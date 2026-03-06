-- Static highlight overrides.
-- Transparent backgrounds — inherit from terminal (works with termguicolors = true).
vim.api.nvim_set_hl(0, "Normal",       { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn",   { bg = "NONE" })
vim.api.nvim_set_hl(0, "LineNr",       { bg = "NONE" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "NONE" })

-- ---------------------------------------------------------------------------
-- Matugen-generated colors (org headlines, links)
-- ---------------------------------------------------------------------------
-- Source: ~/.cache/matugen/nvim-highlights.lua (regenerated on each wallpaper change).
-- Restart nvim to apply new colors after a wallpaper change.
local cache = vim.fn.expand("~/.cache/matugen/nvim-highlights.lua")
if vim.fn.filereadable(cache) == 1 then
  dofile(cache)
end
