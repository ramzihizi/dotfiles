-- minuet-ai.nvim — LLM "as-you-type" completion as a blink.cmp source, backed
-- by a LOCAL Ollama model. This setup is tuned for PROSE (markdown: the wiki +
-- novel + research notes), not code, so it uses the CHAT provider with an
-- instruct model and a writing-oriented system prompt — not FIM.
--
-- Why chat (openai_compatible) and not FIM (openai_fim_compatible): the FIM
-- endpoint takes no system prompt and only suits code base-models, which makes
-- prose come out code-flavored / parroted. The chat endpoint lets us steer tone
-- and continue the author's voice. gemma3 writes the most natural English prose
-- of the open-weight models (tops EQ-Bench creative writing) and is good at both
-- fiction and expository notes.
--
-- Requires Ollama running with the model pulled:
--   ollama pull gemma3:12b
--
-- The `api_key = "TERM"` is the documented Ollama trick: minuet treats it as an
-- env-var NAME (TERM is always set) and sends its value as a throwaway bearer
-- token that Ollama ignores.
return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "InsertEnter",
    opts = {
      provider = "openai_compatible",
      n_completions = 1, -- one good continuation; 3 prose gens tank local latency
      context_window = 10000, -- enough voice context without stalling prefill
      request_timeout = 6, -- prose generations run longer than code snippets
      provider_options = {
        openai_compatible = {
          api_key = "TERM",
          name = "Ollama",
          end_point = "http://localhost:11434/v1/chat/completions",
          model = "gemma3:12b",
          system = {
            prompt = [[
You are a writing-continuation assistant embedded in a Markdown editor. Continue
the text at the cursor in the author's established voice, tense, and register —
whether it is narrative fiction or expository notes. Write natural English prose.
Do not summarize, restate, explain your output, or add headings or lists unless
the surrounding text clearly calls for them. Match the rhythm of the surrounding
paragraph and stop at a natural sentence or paragraph boundary.]],
          },
          optional = {
            max_tokens = 384, -- room to finish a sentence/short paragraph
            temperature = 0.8, -- creative, but not unhinged
            top_p = 0.9,
            num_ctx = 8192, -- Ollama context window; keep >= heavy prose context
          },
        },
      },
    },
  },

  -- Register minuet as a blink.cmp source without clobbering LazyVim's defaults.
  -- <A-y> manually triggers a minuet completion.
  {
    "saghen/blink.cmp",
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      if not vim.tbl_contains(opts.sources.default, "minuet") then
        table.insert(opts.sources.default, "minuet")
      end

      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 6000, -- match the longer prose request_timeout
        score_offset = 50, -- surface minuet above other sources
        -- Off in commit messages. Stays on for markdown/text — the whole point.
        enabled = function()
          return vim.bo.filetype ~= "gitcommit"
        end,
        -- Tag minuet's AI suggestions with a robot icon + "Minuet" kind so they
        -- are unmistakable next to LSP/buffer/snippet completions.
        transform_items = function(_, items)
          for _, item in ipairs(items) do
            item.kind_icon = "🤖"
            item.kind_name = "Minuet"
          end
          return items
        end,
      }

      -- Don't fire a request on every insert — only on demand / debounced.
      opts.completion = opts.completion or {}
      opts.completion.trigger = opts.completion.trigger or {}
      opts.completion.trigger.prefetch_on_insert = false

      -- Guard the manual-trigger map: if minuet ever fails to load, blink
      -- completion must still work — just without the <A-y> shortcut.
      local ok, minuet = pcall(require, "minuet")
      if ok then
        opts.keymap = opts.keymap or {}
        opts.keymap["<A-y>"] = minuet.make_blink_map()
      end

      return opts
    end,
  },
}
