return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          local mason_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"

          -- Cross-platform fallback. This was a hardcoded linuxbrew path, which
          -- does not exist on macOS. Resolve from PATH so Homebrew's python3 is
          -- found under either prefix (/opt/homebrew or /home/linuxbrew/...).
          local system_python = vim.fn.exepath("python3")
          if system_python == "" then
            system_python = vim.fn.exepath("python")
          end

          local python_path = vim.fn.executable(mason_path) == 1 and mason_path or system_python
          require("dap-python").setup(python_path)
        end,
      },
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "debugpy")
        end,
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        controls = {
          enabled = true,
          element = "repl",
          icons = {
            pause = "⏸",
            play = "▶",
            step_into = "⏎",
            step_over = "⏭",
            step_out = "⏮",
            step_back = "b",
            run_last = "▶▶",
            terminate = "⏹",
            disconnect = "⏏",
          },
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              "breakpoints",
              "stacks",
              "watches",
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 0.25,
            position = "bottom",
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
      })

      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        clear_on_continue = false,
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == "inline" then
            return " = " .. variable.value
          else
            return variable.name .. " = " .. variable.value
          end
        end,
        virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "🟢", texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "➡️", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "❌", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })

      local keymap = vim.keymap.set
      keymap("n", "<F5>", function() dap.continue() end, { desc = "Debug: Start/Continue" })
      keymap("n", "<F10>", function() dap.step_over() end, { desc = "Debug: Step Over" })
      keymap("n", "<F11>", function() dap.step_into() end, { desc = "Debug: Step Into" })
      keymap("n", "<F12>", function() dap.step_out() end, { desc = "Debug: Step Out" })
      keymap("n", "<leader>db", function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
      keymap("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "Debug: Set Conditional Breakpoint" })
      keymap("n", "<leader>dr", function() dap.repl.open() end, { desc = "Debug: Open REPL" })
      keymap("n", "<leader>dl", function() dap.run_last() end, { desc = "Debug: Run Last" })
      keymap("n", "<leader>dt", function() require("dap-python").test_method() end, { desc = "Debug: Test Method" })
      keymap("n", "<leader>dc", function() require("dap-python").test_class() end, { desc = "Debug: Test Class" })
      keymap("n", "<leader>ds", function() require("dap-python").debug_selection() end, { desc = "Debug: Debug Selection" })
      keymap({ "n", "v" }, "<leader>de", function() dapui.eval() end, { desc = "Debug: Evaluate" })
      keymap("n", "<leader>du", function() dapui.toggle() end, { desc = "Debug: Toggle UI" })
      keymap("n", "<leader>dx", function() dap.terminate() end, { desc = "Debug: Terminate" })
    end,
  },
}