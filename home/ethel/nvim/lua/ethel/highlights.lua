-- Static highlight overrides.
-- Transparent backgrounds — inherit from terminal (works with termguicolors = true).
vim.api.nvim_set_hl(0, "Normal",       { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn",   { bg = "NONE" })
vim.api.nvim_set_hl(0, "LineNr",       { bg = "NONE" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "NONE" })

-- ---------------------------------------------------------------------------
-- Matugen-generated colors (org headlines, links, lualine)
-- ---------------------------------------------------------------------------
-- Source: ~/.cache/matugen/nvim-{highlights,lualine}.lua
-- Regenerated on each wallpaper change; live-reloaded via SIGUSR1.

local hl_cache = vim.fn.expand("~/.cache/matugen/nvim-highlights.lua")
local ll_cache = vim.fn.expand("~/.cache/matugen/nvim-lualine.lua")

local function load_matugen_colors()
  if vim.fn.filereadable(hl_cache) == 1 then
    dofile(hl_cache)
  end
  if vim.fn.filereadable(ll_cache) == 1 then
    require("lualine").setup({ options = { theme = dofile(ll_cache) } })
  end
end

load_matugen_colors()

-- Live reload: matugen post_hook sends SIGUSR1 to all nvim instances.
vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = load_matugen_colors,
})
