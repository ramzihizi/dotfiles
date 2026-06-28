return {

  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent_mode = true,
      -- Darkest gruvbox: "hard" contrast pins the background to #1d2021 (matches
      -- the ghostty "Gruvbox Dark Hard" theme). transparent_mode lets the
      -- terminal background show through, so this sets the non-transparent tone.
      contrast = "hard",
      bold = false,
      -- Warm down the bright yellow (#fabd2f reads as harsh/distracting) to
      -- gruvbox's faded/ochre yellow — the same #b57614 used for the wezterm
      -- cursor, starship prompt, and tmux active window, so all four match.
      palette_overrides = {
        bright_yellow = "#b57614",
      },
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
    -- Gruvbox in every environment now (ghostty + herdr and wezterm + tmux),
    -- using gruvbox's "hard" contrast to match each terminal's "Gruvbox Dark
    -- Hard" theme. The old per-environment $TMUX / $TERM_PROGRAM switch (gruvbox
    -- vs tokyonight) is gone now that both terminals run gruvbox.
    opts = function()
      return { colorscheme = "gruvbox" }
    end,
    -- Manual alternates: "catppuccin", "catppuccin-mocha", "poimandres",
    -- "github_dark_default", "github_dark".
  },
}
