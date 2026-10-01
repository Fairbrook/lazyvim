-- Overrides for the LazyVim Dart/Flutter extra (lazyvim.plugins.extras.lang.dart).
-- The extra sets up flutter-tools.nvim, which starts the `dartls` LSP.
return {
  {
    "nvim-flutter/flutter-tools.nvim",
    opts = {
      -- Pin the SDK so dartls resolves even when nvim is launched without the
      -- shell PATH. Flutter lives at ~/develop/flutter on this machine.
      flutter_path = vim.fn.expand("~/develop/flutter/bin/flutter"),
      lsp = {
        color = { enabled = true }, -- show color swatches for Color(...) literals
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          renameFilesWithClasses = "prompt",
          lineLength = 100,
        },
      },
    },
  },
}
