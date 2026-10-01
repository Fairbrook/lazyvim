--- Idempotently patches agentic.nvim to fold thinking blocks.
---
--- agentic.nvim only folds tool-call bodies. Thinking arriving as
--- `agent_thought_chunk` is rendered as plain highlighted lines and never
--- folded. This patches the installed plugin source (lazy.nvim managed dir)
--- so completed thinking blocks are closed with the same manual folds used
--- for tool calls. The patch is re-applied via the plugin spec's `build` /
--- `init` hooks, so `:Lazy update` wiping the source does not disable it.
---
--- Uses only plain (non-pattern) matches, so every source anchor is matched
--- literally and applying twice is a no-op.

local M = {}

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

local function write_file(path, content)
    local f = io.open(path, "wb")
    if not f then
        return false
    end
    f:write(content)
    f:close()
    return true
end

--- Replace the first plain-text occurrence of `old` with `new` in `content`.
--- @param content string
--- @param old string
--- @param new string
--- @return string content
--- @return boolean changed
local function replace_once(content, old, new)
    local s, e = content:find(old, 1, true)
    if not s then
        return content, false
    end
    return content:sub(1, s - 1) .. new .. content:sub(e + 1), true
end

--- Run `replace_once` for each replacement and remember if any changed.
--- Each entry may carry an optional `guard` string: when present and already
--- found in `content`, the replacement is skipped (makes inserts idempotent).
--- @param content string
--- @param replacements table[] Entries are `{ old, new }` or `{ old, new, guard }`.
--- @return string
--- @return boolean
local function patch(content, replacements)
    local modified = false
    for _, rep in ipairs(replacements) do
        local guard = rep[3]
        if guard and content:find(guard, 1, true) then
            goto continue
        end
        local next_content, replaced = replace_once(content, rep[1], rep[2])
        content = next_content
        if replaced then
            modified = true
        end
        ::continue::
    end
    return content, modified
end

local function patch_config_default(root)
    local path = root
        .. "/lua/agentic/config_default.lua"
    local content = read_file(path)
    if not content then
        return false, path .. " not found"
    end

    content, _ = patch(content, {
        {
            "--- Folding behavior in the chat buffer\n--- @class agentic.UserConfig.Folding\n--- @field tool_calls agentic.UserConfig.Folding.ToolCalls",
            "--- Thinking block folding configuration\n--- @class agentic.UserConfig.Folding.Thinking\n--- @field enabled boolean Whether to fold thinking blocks.\n--- @field threshold integer Fold when the block occupies more than this many wrapped screen rows. 0 always folds. Negative values are clamped to 0.\n\n--- Folding behavior in the chat buffer\n--- @class agentic.UserConfig.Folding\n--- @field tool_calls agentic.UserConfig.Folding.ToolCalls\n--- @field thinking agentic.UserConfig.Folding.Thinking",
            "--- @class agentic.UserConfig.Folding.Thinking",
        },
        {
            "--- @class (partial) agentic.PartialUserConfig.Folding: agentic.UserConfig.Folding\n--- @field tool_calls? agentic.PartialUserConfig.Folding.ToolCalls",
            "--- @class (partial) agentic.PartialUserConfig.Folding.Thinking: agentic.UserConfig.Folding.Thinking\n\n--- @class (partial) agentic.PartialUserConfig.Folding: agentic.UserConfig.Folding\n--- @field tool_calls? agentic.PartialUserConfig.Folding.ToolCalls\n--- @field thinking? agentic.PartialUserConfig.Folding.Thinking",
            "--- @field thinking? agentic.PartialUserConfig.Folding.Thinking",
        },
        {
            "    folding = {\n        tool_calls = {\n            enabled = true,\n            threshold = 10,\n            fold_on_error = false,\n        },\n    },",
            "    folding = {\n        tool_calls = {\n            enabled = true,\n            threshold = 10,\n            fold_on_error = false,\n        },\n        thinking = {\n            enabled = false,\n            threshold = 10,\n        },\n    },",
            "        thinking = {",
        },
    })

    return write_file(path, content)
end

local function patch_tool_call_fold(root)
    local path = root
        .. "/lua/agentic/ui/tool_call_fold.lua"
    local content = read_file(path)
    if not content then
        return false, path .. " not found"
    end

    content, _ = patch(content, {
        {
            "--- @return integer|nil threshold nil when folding is disabled\nfunction Fold.threshold()\n    local cfg = Config.folding and Config.folding.tool_calls\n    if not cfg or not cfg.enabled then\n        return nil\n    end\n    return math.max(0, cfg.threshold or 0)\nend",
            "--- @return integer|nil threshold nil when folding is disabled\nfunction Fold.threshold()\n    local cfg = Config.folding and Config.folding.tool_calls\n    if not cfg or not cfg.enabled then\n        return nil\n    end\n    return math.max(0, cfg.threshold or 0)\nend\n\n--- @return integer|nil threshold nil when folding is disabled\nfunction Fold.thinking_threshold()\n    local cfg = Config.folding and Config.folding.thinking\n    if not cfg or not cfg.enabled then\n        return nil\n    end\n    return math.max(0, cfg.threshold or 0)\nend",
            "function Fold.thinking_threshold()",
        },
        {
            "function Fold.setup_window(winid, _bufnr)\n    if Fold.threshold() == nil then\n        return\n    end",
            "function Fold.setup_window(winid, _bufnr)\n    if Fold.threshold() == nil and Fold.thinking_threshold() == nil then\n        return\n    end",
            "and Fold.thinking_threshold() == nil then",
        },
        {
            "    vim.api.nvim_win_call(wins[1], function()\n        vim.cmd(\n            string.format(\"silent! noautocmd %d,%dfold\", start_lnum, end_lnum)\n        )\n    end)\nend\n\nreturn Fold",
            "    vim.api.nvim_win_call(wins[1], function()\n        vim.cmd(\n            string.format(\"silent! noautocmd %d,%dfold\", start_lnum, end_lnum)\n        )\n    end)\nend\n\n--- Close a fold over a completed thinking block when its text exceeds the\n--- configured threshold. 0-indexed rows are converted to 1-indexed here.\n--- @param bufnr integer\n--- @param start_lnum integer 1-indexed inclusive\n--- @param end_lnum integer 1-indexed inclusive\nfunction Fold.close_thinking(bufnr, start_lnum, end_lnum)\n    local threshold = Fold.thinking_threshold()\n    if threshold == nil then\n        return\n    end\n    if start_lnum > end_lnum then\n        return\n    end\n    local wins = vim.fn.win_findbuf(bufnr)\n    if #wins == 0 then\n        return\n    end\n    local ok, result = pcall(vim.api.nvim_win_text_height, wins[1], {\n        start_row = start_lnum - 1,\n        end_row = end_lnum - 1,\n    })\n    if not ok or type(result) ~= \"table\" or result.all <= threshold then\n        return\n    end\n    vim.api.nvim_win_call(wins[1], function()\n        vim.cmd(\n            string.format(\"silent! noautocmd %d,%dfold\", start_lnum, end_lnum)\n        )\n    end)\nend\n\nreturn Fold",
            "function Fold.close_thinking(",
        },
    })

    return write_file(path, content)
end

local function patch_message_writer(root)
    local path = root
        .. "/lua/agentic/ui/message_writer.lua"
    local content = read_file(path)
    if not content then
        return false, path .. " not found"
    end

    content, _ = patch(content, {
        {
            "--- Clears thinking block tracking state.\n--- Called when a non-thought write breaks the thinking flow.\nfunction MessageWriter:_clear_thinking_state()\n    self._thinking_extmark_id = nil\n    self._thinking_start_line = nil\n    self._thinking_end_line = nil\nend",
            "--- Clears thinking block tracking state.\n--- Called when a non-thought write breaks the thinking flow.\nfunction MessageWriter:_clear_thinking_state()\n    if self._thinking_start_line and self._thinking_end_line then\n        Fold.close_thinking(\n            self.bufnr,\n            self._thinking_start_line + 1,\n            self._thinking_end_line + 1\n        )\n    end\n    self._thinking_extmark_id = nil\n    self._thinking_start_line = nil\n    self._thinking_end_line = nil\nend",
            "if self._thinking_start_line and self._thinking_end_line then",
        },
        {
            "            if start_line then\n                local end_line = start_line + #lines - 1\n                self:_set_thinking_extmark(start_line, end_line)\n            end",
            "            if start_line then\n                local end_line = start_line + #lines - 1\n                self:_set_thinking_extmark(start_line, end_line)\n                Fold.close_thinking(self.bufnr, start_line + 1, end_line + 1)\n            end",
            "Fold.close_thinking(self.bufnr, start_line + 1, end_line + 1)",
        },
    })

    return write_file(path, content)
end

--- Apply the thinking-folding patch to an installed agentic.nvim checkout.
--- Safe to call repeatedly.
--- @param root string Absolute path to the plugin directory.
--- @return boolean ok
--- @return string message
function M.patch(root)
    if not root or root == "" then
        return false, "invalid plugin dir"
    end

    local ok1, err1 = patch_config_default(root)
    local ok2, err2 = patch_tool_call_fold(root)
    local ok3, err3 = patch_message_writer(root)

    if ok1 and ok2 and ok3 then
        return true, "patched"
    end

    local errors = {}
    if not ok1 then
        table.insert(errors, tostring(err1))
    end
    if not ok2 then
        table.insert(errors, tostring(err2))
    end
    if not ok3 then
        table.insert(errors, tostring(err3))
    end
    return false, table.concat(errors, "; ")
end

return M