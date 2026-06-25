-- table-nvim — format-as-you-type Markdown tables + cell navigation + row/column
-- ops. render-markdown only *renders* tables and dprint only reflows them on
-- save; this aligns the table live as you edit it.
--
-- Cell navigation is remapped off <Tab>/<S-Tab> (which collide with Neovim's
-- native snippet/completion mapping) onto <A-n>/<A-p>. Everything else keeps
-- table-nvim's Alt-key defaults (Alt-h/j/k/l to insert rows/columns, Alt-Shift
-- to move them). All maps are buffer-local to markdown.
return {
  "SCJangra/table-nvim",
  ft = "markdown",
  opts = {
    padd_column_separators = true,
    mappings = {
      next = "<A-n>", -- next cell (was <TAB>)
      prev = "<A-p>", -- prev cell (was <S-TAB>)
      insert_row_up = "<A-k>",
      insert_row_down = "<A-j>",
      move_row_up = "<A-S-k>",
      move_row_down = "<A-S-j>",
      insert_column_left = "<A-h>",
      insert_column_right = "<A-l>",
      move_column_left = "<A-S-h>",
      move_column_right = "<A-S-l>",
      insert_table = "<A-t>",
      insert_table_alt = "<A-S-t>",
      delete_column = "<A-d>",
    },
  },
}
