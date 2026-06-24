return {

  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent_mode = true,
      bold = false,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      transparent = true,
    },
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    config = true,
    opts = {
      options = {
        transparent = true,
        darken = { -- Darken floating windows and sidebar-like windows
          floats = true,
          sidebars = {
            enable = true,
            list = {}, -- Apply dark background to specific windows
          },
        },
        styles = {
          comments = "italic",
          keywords = "bold",
          types = "italic,bold",
        },
      },
    },
  },
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      transparent_background = true,
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
  {
    "olivercederborg/poimandres.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      disable_background = true, -- disable background
    },
  },
  {
    "LazyVim/LazyVim",
    -- Per-environment colorscheme so the editor matches its terminal:
    --   wezterm + tmux (serious-work env)  -> gruvbox   (warm/amber)
    --   ghostty + herdr (everything else)  -> tokyonight (cool/blue)
    -- Detected via $TMUX (set only inside tmux) or wezterm's $TERM_PROGRAM
    -- (tmux rewrites TERM_PROGRAM to "tmux", so check both).
    opts = function()
      local in_wezterm = vim.env.TMUX ~= nil or vim.env.TERM_PROGRAM == "WezTerm"
      return { colorscheme = in_wezterm and "gruvbox" or "tokyonight" }
    end,
    -- Manual alternates: "catppuccin", "catppuccin-mocha", "poimandres",
    -- "github_dark_default", "github_dark".
  },
}
