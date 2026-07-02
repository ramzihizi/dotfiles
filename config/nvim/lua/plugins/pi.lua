-- pi.nvim — quick one-shot AI edits/answers inside the buffer, backed by the
-- pi CLI already on this machine (brew: /opt/homebrew/bin/pi). This is the
-- "really quick ask" lane: no terminal split, no session — :PiAsk sends the
-- prompt + buffer context, :PiAskSelection adds the selected lines. For real
-- agentic work there's claudecode (<leader>ac) or pi/herdr in the terminal.
--
-- Provider/model are deliberately NOT set here: pi.nvim shells out to the pi
-- binary, so it inherits defaultProvider/defaultModel from the dotfiles-owned
-- ~/.pi/agent/settings.json (openai-codex / gpt-5.5 today) — one place to
-- change models. Thinking IS overridden: the CLI default is xhigh, which is
-- right for terminal sessions and far too slow for in-editor quick asks;
-- low keeps latency tight while giving gpt-5.5 a beat to reason.
--
-- Keymaps join the LazyVim +ai group from the claudecode extra. That extra
-- owns <leader>a{c,f,r,C,b,s,a,d}; pi takes the free ai/ax/al slots.
return {
  "pablopunk/pi.nvim",
  cmd = { "PiAsk", "PiAskSelection", "PiCancel", "PiLog" },
  keys = {
    { "<leader>ai", "<cmd>PiAsk<cr>", desc = "Ask pi (buffer)" },
    -- ":" not "<cmd>" so the visual range ('<,'>) is passed to the command.
    { "<leader>ai", ":PiAskSelection<cr>", mode = "v", desc = "Ask pi (selection)" },
    { "<leader>ax", "<cmd>PiCancel<cr>", desc = "Cancel pi request" },
    { "<leader>al", "<cmd>PiLog<cr>", desc = "Pi session log" },
  },
  opts = {
    thinking = "low",
    context = {
      -- Send LSP diagnostics with the context — "fix this error" asks work
      -- without pasting the error text by hand.
      diagnostics = { enabled = true },
    },
  },
}
