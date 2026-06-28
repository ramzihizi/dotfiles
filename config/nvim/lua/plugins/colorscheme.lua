return {

  {
    -- Solarized Dark, the restrained classic look: a faithful port of
    -- vim-solarized8 (Ethan Schoonover's base03 #002b36 palette). Chosen over
    -- the more saturated maxmx03/solarized.nvim, which painted markdown bold
    -- bright magenta and cycled headings through loud hues. Here `**bold**` is
    -- just bold base text and headings stay muted. Registers colorscheme
    -- "solarized" (variants: solarized-low / solarized-flat / solarized-high).
    "ishan9299/nvim-solarized-lua",
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.solarized_italics = 1
      vim.g.solarized_termtrans = 1 -- transparent: let the terminal bg show through
      vim.g.solarized_visibility = "normal"

      -- Markdown headings default to solarized's orange/red (#cb4b16), which
      -- reads harsh. Recolor them to the calmer signature blue (#268bd2). We
      -- define the per-level @markup.heading.N.markdown groups (normally empty,
      -- so they fall back to the red @markup.heading) plus the base group: this
      -- catches both treesitter-rendered heading text AND render-markdown, whose
      -- RenderMarkdownH{N} groups link to these same targets — so it works
      -- regardless of which plugin paints last.
      local function style_headings()
        if not (vim.g.colors_name or ""):find("solarized") then
          return
        end
        local hl = { fg = "#268bd2", bold = true }
        vim.api.nvim_set_hl(0, "@markup.heading", hl)
        for i = 1, 6 do
          vim.api.nvim_set_hl(0, "@markup.heading." .. i .. ".markdown", hl)
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "solarized*",
        callback = style_headings,
        desc = "Solarized: recolor markdown headings to blue",
      })
      style_headings() -- in case the scheme is already active when this runs
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent_mode = true,
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
    -- Solarized Dark in every environment (ghostty + herdr and wezterm + tmux).
    -- Force a dark background so the solarized scheme picks base03 (#002b36)
    -- rather than the light base3 palette.
    opts = function()
      vim.o.background = "dark"
      return { colorscheme = "solarized" }
    end,
    -- Manual alternates: "catppuccin", "catppuccin-mocha", "poimandres",
    -- "github_dark_default", "github_dark".
  },
}
