return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>tb",
      function()
        require("snacks").terminal(nil, { win = { position = "bottom", height = 50 } })
      end,
      desc = "Open Terminal at Bottom",
    },
    {
      "<leader>tr",
      function()
        require("snacks").terminal(nil, { win = { position = "right", width = 200 } })
      end,
      desc = "Open Terminal at Right",
    },
    {
      "<leader>tf",
      function()
        require("snacks").terminal(nil, { win = { position = "float" } })
      end,
      desc = "Open Floating Terminal",
    },
    {
      "<leader>tR",
      function()
        require("snacks").terminal(nil, { cwd = LazyVim.root(), win = { position = "float" } })
      end,
      desc = "Terminal (Root Dir)",
    },
    {
      "<c-/>",
      function()
        require("snacks").terminal(nil, { cwd = LazyVim.root(), win = { position = "right", width = 200 } })
      end,
      desc = "Toggle Terminal (Root)",
    },
    {
      "<c-_>",
      function()
        require("snacks").terminal(nil, { cwd = LazyVim.root(), win = { position = "right", width = 200 } })
      end,
      desc = "which_key_ignore",
    },
  },
  opts = {
    terminal = {
      -- Default terminal configuration
      win = {
        position = "right", -- Default position when just using toggle
        width = 200, -- Width for right/left positions
        height = 80, -- Height for bottom/top positions
      },
      float = {
        -- Floating terminal specific options
        width = 0.8, -- 80% of editor width
        height = 0.8, -- 80% of editor height
        border = "rounded",
      },
    },
  },
}
