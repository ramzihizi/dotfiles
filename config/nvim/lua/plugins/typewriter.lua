-- "Typewriter" writing mode via native scrolloff — flicker-free.
--
-- We tried typewriter.nvim, but it re-runs `zz` on every CursorMoved AND
-- WinScrolled, which oscillates on the long soft-wrapped paragraph lines a novel
-- uses (story.md averages ~230 chars/line, up to 1184) and produces visible
-- flicker. There's no option to disable that re-centering. A huge scrolloff pins
-- the cursor line to the vertical centre using Neovim's own viewport management
-- — one render pass, no autocmd loop — so it's flicker-free and works with
-- wrapped prose. Loses typewriter.nvim's treesitter block-centering, which we
-- didn't use anyway.
--
-- <leader>uW toggles it; snacks zen turns it on/off automatically.
-- (typewriter.nvim is no longer referenced; run :Lazy clean to uninstall it.)

local CENTER = 999

local function set_typewriter(on)
  if on and not vim.g.typewriter_on then
    vim.g.typewriter_prev_scrolloff = vim.o.scrolloff
  end
  vim.g.typewriter_on = on
  vim.o.scrolloff = on and CENTER or (vim.g.typewriter_prev_scrolloff or 4)
end

vim.keymap.set("n", "<leader>uW", function()
  set_typewriter(not vim.g.typewriter_on)
  vim.notify("Typewriter " .. (vim.g.typewriter_on and "on" or "off"))
end, { desc = "Typewriter (Writing) Mode" })

return {
  -- Auto-enable typewriter centering inside snacks zen (the focus mode already
  -- in this setup), and turn it back off on exit.
  {
    "folke/snacks.nvim",
    opts = {
      zen = {
        on_open = function()
          set_typewriter(true)
        end,
        on_close = function()
          set_typewriter(false)
        end,
      },
    },
  },
}
