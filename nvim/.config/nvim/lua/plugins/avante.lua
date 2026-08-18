-- avante.nvim: Use Neovim like Cursor AI IDE
-- https://github.com/yetone/avante.nvim
--
-- OFF BY DEFAULT — OPT IN PER MACHINE.
--
-- This plugin ships buffer contents to a third-party inference endpoint
-- (api.deepseek.com below). On any machine where the code in your buffers is not
-- yours to send, that is a confidentiality problem, not a preference. The gate
-- is deliberately fail-safe: with the variable unset the plugin does not load,
-- so a machine that was never configured is protected rather than exposed.
--
-- To enable, on a machine where it is appropriate:
--     echo 'export NVIM_AI_EXTERNAL=1' >> ~/.bashrc.local
--
return {
  "yetone/avante.nvim",
  enabled = function()
    return os.getenv("NVIM_AI_EXTERNAL") == "1"
  end,
  event = "VeryLazy",
  version = false, -- Always use latest
  opts = {
    -- Provider configuration (DeepSeek V3.2 - fast, cheap, capable)
    provider = "deepseek",
    vendors = {
      deepseek = {
        __inherited_from = "openai",
        api_key_name = "DEEPSEEK_API_KEY",
        endpoint = "https://api.deepseek.com",
        model = "deepseek-chat", -- This is V3.2 (latest)
        max_tokens = 8192,
      },
    },
    -- Behavior settings
    behaviour = {
      auto_suggestions = false, -- Disable auto suggestions (use manual triggers)
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
      auto_focus_sidebar = true,
    },
    -- File selector for context (use native vim.ui.select)
    file_selector = {
      provider = "native",
    },
    -- RAG service for @codebase mentions (requires Docker)
    -- Disabled: requires OpenAI API key for embeddings
    rag_service = {
      enabled = false,
    },
    -- Mappings (defaults, can customize)
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      sidebar = {
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    hints = { enabled = true },
    windows = {
      position = "right", -- Sidebar position
      wrap = true,
      width = 30, -- Percentage of screen width
      sidebar_header = {
        align = "center",
        rounded = true,
      },
    },
    highlights = {
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
  },
  -- Register keymap group with which-key (Avante uses <leader>a prefix)
  keys = {
    { "<leader>a", group = "Avante" },
  },
  -- Build from source (required for some features)
  build = "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- Optional but recommended
    "nvim-tree/nvim-web-devicons",
    -- "zbirenbaum/copilot.lua", -- Disabled to save RAM
    {
      -- Support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      },
    },
    {
      -- Markdown rendering in sidebar
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
