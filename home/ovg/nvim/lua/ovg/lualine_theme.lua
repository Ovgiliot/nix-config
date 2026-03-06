-- Lualine theme using ANSI cterm indices (termguicolors = false).
-- Gradient rule: a.bg (lightest) stepping darker toward c via powerline separators.
--   a.bg = lightest,  a.fg = c.bg = darkest,  c.fg = b.bg = medium,  b.fg = a.bg
-- See highlights.lua for the full ANSI → M3 role mapping.

return {
  normal = {
    a = { bg = 4,  fg = 12, gui = "bold" },
    b = { bg = 0,  fg = 4  },
    c = { bg = 12, fg = 0  },
  },
  insert = {
    a = { bg = 2,  fg = 10, gui = "bold" },
    b = { bg = 0,  fg = 2  },
    c = { bg = 10, fg = 0  },
  },
  visual = {
    a = { bg = 3,  fg = 11, gui = "bold" },
    b = { bg = 0,  fg = 3  },
    c = { bg = 11, fg = 0  },
  },
  replace = {
    a = { bg = 13, fg = 5,  gui = "bold" },
    b = { bg = 0,  fg = 13 },
    c = { bg = 5,  fg = 0  },
  },
  command = {
    a = { bg = 1,  fg = 9,  gui = "bold" },
    b = { bg = 0,  fg = 1  },
    c = { bg = 9,  fg = 0  },
  },
  inactive = {
    a = { bg = 8,  fg = 0  },
    b = { bg = 7,  fg = 8  },
    c = { bg = 0,  fg = 7  },
  },
}
