-- Extend which-key with custom group names
return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      { "<leader>a", group = "Avante" },
      { "<leader>t", group = "terminal" },
      { "<leader>C", group = "Claude Code" },
    },
  },
}

