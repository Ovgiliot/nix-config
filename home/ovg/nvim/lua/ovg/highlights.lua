-- Static highlight overrides using ANSI cterm indices.
-- Actual hex values are provided by the terminal (matugen → ghostty palette).
-- Mapping (see home/ovg/matugen/templates/ghostty-colors.conf):
--   0  surface_container_high    8  surface_bright
--   1  error                     9  error_container
--   2  tertiary                  10 tertiary_container
--   3  secondary                 11 secondary_container
--   4  primary                   12 primary_container
--   5  tertiary_fixed_dim        13 tertiary_fixed
--   6  secondary_fixed_dim       14 secondary_fixed
--   7  on_surface_variant        15 on_surface

-- Transparent background — inherit from terminal.
vim.api.nvim_set_hl(0, "Normal", { ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn", { ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "LineNr", { ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "CursorLineNr", { ctermbg = "NONE" })

-- ---------------------------------------------------------------------------
-- Org-mode headlines (headlines.nvim)
-- ---------------------------------------------------------------------------
-- Background bars use container ANSI slots (tones ~30 — dim accent fills).
vim.api.nvim_set_hl(0, "Headline1", { ctermbg = 12 }) -- primary_container
vim.api.nvim_set_hl(0, "Headline2", { ctermbg = 11 }) -- secondary_container
vim.api.nvim_set_hl(0, "Headline3", { ctermbg = 10 }) -- tertiary_container
vim.api.nvim_set_hl(0, "Headline4", { ctermbg = 9  }) -- error_container
vim.api.nvim_set_hl(0, "Headline5", { ctermbg = 0  }) -- surface_container_high
vim.api.nvim_set_hl(0, "Headline6", { ctermbg = 8  }) -- surface_bright

-- Headline text — bright ANSI slots (tones ~80).
vim.api.nvim_set_hl(0, "@org.headline.level1", { ctermfg = 4,  bold = true }) -- primary
vim.api.nvim_set_hl(0, "@org.headline.level2", { ctermfg = 12, bold = true }) -- primary_container
vim.api.nvim_set_hl(0, "@org.headline.level3", { ctermfg = 10, bold = true }) -- tertiary_container
vim.api.nvim_set_hl(0, "@org.headline.level4", { ctermfg = 1,  bold = true }) -- error
vim.api.nvim_set_hl(0, "@org.headline.level5", { ctermfg = 3,  bold = true }) -- secondary
vim.api.nvim_set_hl(0, "@org.headline.level6", { ctermfg = 2,  bold = true }) -- tertiary
vim.api.nvim_set_hl(0, "@org.headline.level7", { ctermfg = 7,  bold = true }) -- on_surface_variant
vim.api.nvim_set_hl(0, "@org.headline.level8", { ctermfg = 11, bold = true }) -- secondary_container

-- Links
vim.api.nvim_set_hl(0, "@org.hyperlink",      { ctermfg = 4,  underline = true }) -- primary
vim.api.nvim_set_hl(0, "@org.hyperlink.desc", { ctermfg = 4,  underline = true }) -- primary
vim.api.nvim_set_hl(0, "@org.hyperlink.url",  { ctermfg = 12, underline = true }) -- primary_container
