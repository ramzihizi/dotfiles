return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    event = { "BufReadPre *.md", "BufNewFile *.md" },
    cmd = "Obsidian",
    keys = {
      { "<leader>on", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian Notes" },
    },
    ---@module "obsidian"
    ---@type obsidian.config
    opts = {
      legacy_commands = false,

      workspaces = {
        {
          name = "rmh-wiki",
          path = "/Users/rmh/bsdn/rmh-wiki",
          overrides = {
            notes_subdir = "wiki",
            attachments = {
              folder = "raw/assets",
            },
          },
        },
        { name = "secondBrain", path = "/Users/rmh/bsdn/secondBrain" },
        { name = "jrvs", path = "/Users/rmh/bsdn/jrvs-obsidian" },
        { name = "tcw", path = "/Users/rmh/bsdn/tcw" },
      },

      picker = {
        name = "snacks.pick",
      },

      completion = {
        -- Keep obsidian-ls for navigation, but keep note/tag completion quiet.
        min_chars = 9999,
        create_new = false,
      },

      frontmatter = {
        enabled = false,
      },

      templates = {
        enabled = false,
      },

      daily_notes = {
        enabled = false,
      },

      unique_note = {
        enabled = false,
      },

      checkbox = {
        enabled = false,
        create_new = false,
      },

      ui = {
        enable = false,
      },

      footer = {
        enabled = false,
      },

      statusline = {
        enabled = false,
      },
    },
  },
}
