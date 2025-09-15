return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      -- Desactivar Enter para aceptar sugerencias
      ["<CR>"] = {},
      -- Configurar Tab para aceptar sugerencias
      ["<Tab>"] = { "accept", "fallback" },
      -- Opcional: Shift+Tab para navegar hacia atrás
      ["<S-Tab>"] = { "select_prev", "fallback" },
      -- Mantener navegación con flechas
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      -- Ctrl+Space para mostrar completado manualmente
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      -- Escape para cerrar
      ["<C-e>"] = { "hide", "fallback" },
    },
  },
}
