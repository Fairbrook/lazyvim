return {
  "carlos-algms/agentic.nvim",

  --- @type agentic.PartialUserConfig
  opts = {
    -- Any ACP-compatible provider works. Built-in: "claude-agent-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "copilot-acp" | "auggie-acp" | "mistral-vibe-acp" | "cline-acp" | "goose-acp" | "kiro-acp" | "pi-acp"
    -- provider = "opencode-acp", -- setting the name here is all you need to get started
    provider = "claude-agent-acp",
    folding = {
      tool_calls = {
        enabled = true,
        threshold = 0,
        fold_on_error = false,
      },
      thinking = {
        enabled = true,
        threshold = 5,
      },
    },

    acp_providers = {
      -- Override existing provider (e.g., add API key)
      -- Agentic.nvim doesn't require API keys
      -- Only add it if that's how you prefer to authenticate
      ["claude-agent-acp"] = {
        initial_model = "sonnet",
        default_thought_level = "high",
        default_mode = "auto",
      },
    },

    keymaps = {
      -- Keybindings for ALL buffers in the widget (chat, prompt, code, files)
      widget = {
        close = "q", -- String for a single keybinding
        change_mode = {
          {
            "<S-Tab>",
            mode = { "i", "n", "v" }, -- Specify modes for this keybinding
          },
        },
        switch_provider = "<localLeader>s", -- Switch ACP provider
        switch_model = "<localLeader>m", -- Switch model
        change_thought_level = "<localLeader>t", -- Select thought effort level
        open_options = "<localLeader>o", -- Open options modal
        select_session = "<localLeader>l", -- List and open a session
        next_session = "<localLeader>]", -- Open the next session
        prev_session = "<localLeader>[", -- Open the previous session
        destroy_session = "<localLeader>D", -- Destroy the current session
        stop_generation = "<localLeader>S", -- Destroy the current session
      },
    },
  },

  -- agentic.nvim has no built-in folding for thinking blocks (they arrive as
  -- `agent_thought_chunk` and render as plain 🧠 lines). This applies a small
  -- idempotent patch to the installed source (see utils/agentic_thinking_fold_patch)
  -- so completed thinking blocks get folded like tool calls. `init` re-patches
  -- on load after any `:Lazy update` wiped the local edits.
  init = function(plugin)
    require("utils.agentic_thinking_fold_patch").patch(plugin.dir)
  end,
  build = function(plugin)
    require("utils.agentic_thinking_fold_patch").patch(plugin.dir)
  end,

  -- these are just suggested keymaps; customize as desired
  keys = {
    {
      "<C-\\>",
      function()
        require("agentic").toggle()
      end,
      mode = { "n", "v" },
      desc = "Toggle Agentic Chat",
    },
    {
      "<leader>ac", -- ai add to Context
      function()
        require("agentic").add_selection_or_file_to_context()
      end,
      mode = { "n", "v" },
      desc = "Add file or selection to Agentic to Context",
    },
    {
      "<leader>an",
      function()
        require("agentic").new_session()
      end,
      mode = { "n", "v" },
      desc = "New Agentic Session",
    },
    {
      "<leader>aS", -- ai Stop
      function()
        require("agentic").stop_generation()
      end,
      desc = "Agentic stop generation",
      silent = true,
      mode = { "n", "v" },
    },
    {
      "<leader>ar", -- ai Restore
      function()
        require("agentic").restore_session()
      end,
      desc = "Agentic Restore session",
      silent = true,
      mode = { "n", "v" },
    },
    {
      "<leader>ad", -- ai Diagnostics
      function()
        require("agentic").add_current_line_diagnostics()
      end,
      desc = "Add current line diagnostic to Agentic",
      mode = { "n" },
    },
    {
      "<leader>aD", -- ai all Diagnostics
      function()
        require("agentic").add_buffer_diagnostics()
      end,
      desc = "Add all buffer diagnostics to Agentic",
      mode = { "n" },
    },
  },
}
