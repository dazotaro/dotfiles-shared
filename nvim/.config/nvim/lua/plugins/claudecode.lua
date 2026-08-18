--
-- https://github.com/coder/claudecode.nvim
-- Uses WebSocket MCP protocol (same as VS Code/JetBrains extensions)
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- Terminal window settings
    terminal = {
      split_side = "right",
      split_width_percentage = 0.4,
      provider = "snacks",
    },
    -- Diff display settings
    diff_opts = {
      auto_close_on_accept = true,
      vertical = true,
    },
  },
  keys = {
    { "<leader>C", group = "Claude Code" },
    { "<leader>Cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>Cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>Co", "<cmd>ClaudeCodeOpen<cr>", desc = "Open Claude Code (new session)" },
    { "<leader>Ca", "<cmd>ClaudeCodeAdd<cr>", mode = { "n", "v" }, desc = "Add file/selection to context" },
  },
  config = function(_, opts)
    require("claudecode").setup(opts)
  end,
}
