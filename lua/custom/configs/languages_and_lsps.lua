local overrides = require "custom.configs.overrides"
local languages_and_lsps = {
  -- Git blame sidebar (fugitive-style) and inline virtual text
  {
    "FabijanZulj/blame.nvim",
    cmd = { "BlameToggle" },
    keys = {
      { "<leader>bl", "<cmd>BlameToggle window<cr>", desc = "Toggle git blame sidebar" },
    },
    opts = {
      date_format = "%Y-%m-%d %H:%M",
      merge_consecutive = true,
      commit_detail_view = "vsplit",
    },
  },
  -- Git blame with line background highlighting by commit age (like JetBrains)
  {
    "Yu-Leo/blame-column.nvim",
    cmd = "BlameColumnToggle",
    keys = {
      { "<leader>bL", "<cmd>BlameColumnToggle<cr>", desc = "Toggle blame line highlighting" },
    },
    config = function()
      require("blame-column").setup({
        side = "left",
        dynamic_width = true,
        max_width = 20,
        datetime_format = "%Y-%m-%d",
        relative_dates = true,
        -- Time-based background coloring (newer = lighter, older = darker)
        colorizer_fn = require("blame-column.colorizers").time_based_bg,
        time_based_bg_opts = {
          hue = 220,        -- Blue-ish hue
          saturation = 40,
          lightness_min = 10,
          lightness_max = 40,
        },
      })
    end,
  },
  -- Rust debugging with rustaceanvim
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = "rust",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
      "j-hui/fidget.nvim", -- For progress notifications
    },
    config = function()
      -- Format on save augroup
      local format_augroup = vim.api.nvim_create_augroup("RustFormatting", { clear = true })

      -- Find codelldb path (Mason installation)
      local codelldb_path = nil
      local liblldb_path = nil

      -- Try to find codelldb in Mason's install directory
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb"
      local extension_path = mason_path .. "/extension/"

      if vim.fn.isdirectory(mason_path) == 1 then
        codelldb_path = extension_path .. "adapter/codelldb"
        -- On macOS, the library has a different extension
        local uname = vim.loop.os_uname()
        if uname.sysname == "Darwin" then
          liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
        else
          liblldb_path = extension_path .. "lldb/lib/liblldb.so"
        end
        -- Verify the files exist
        if vim.fn.filereadable(codelldb_path) ~= 1 then
          codelldb_path = nil
          liblldb_path = nil
        end
      end

      -- Configure DAP adapter for rustaceanvim
      local adapter_config = nil
      if codelldb_path and liblldb_path then
        adapter_config = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path)
      end

      -- Custom executor that shows progress via fidget (silent, non-blocking for runnables)
      local function create_fidget_executor()
        return {
          execute_command = function(command, args, cwd, opts)
            -- Create fidget progress handle
            local progress_ok, progress = pcall(require, "fidget.progress")
            local handle = nil

            if progress_ok and progress.handle then
              handle = progress.handle.create({
                title = "Cargo",
                message = "Starting...",
                lsp_client = { name = "rustaceanvim" },
              })
            end

            -- Build command string for execution
            local cmd_str = command
            if args and #args > 0 then
              cmd_str = cmd_str .. " " .. table.concat(args, " ")
            end

            -- Run async for better UX (runnables don't need sync)
            local output_lines = {}
            local stderr_lines = {}

            -- Build command table for jobstart
            local cmd_parts = { command }
            if args then
              for _, arg in ipairs(args) do
                table.insert(cmd_parts, arg)
              end
            end

            vim.fn.jobstart(cmd_parts, {
              cwd = cwd,
              env = opts and opts.env or nil,
              stdout_buffered = false,
              stderr_buffered = false,
              on_stdout = function(_, data)
                if data then
                  for _, line in ipairs(data) do
                    if line and line ~= "" then
                      table.insert(output_lines, line)
                      -- Update fidget with meaningful cargo output
                      if handle then
                        local msg = nil
                        if line:match("Compiling") then
                          msg = line:match("Compiling%s+(%S+)")
                          if msg then msg = "Compiling " .. msg end
                        elseif line:match("Building") then
                          msg = "Building..."
                        elseif line:match("Finished") then
                          msg = "Finished build"
                        elseif line:match("Running") then
                          msg = "Running..."
                        end
                        if msg then
                          vim.schedule(function()
                            if handle then handle.message = msg end
                          end)
                        end
                      end
                    end
                  end
                end
              end,
              on_stderr = function(_, data)
                if data then
                  for _, line in ipairs(data) do
                    if line and line ~= "" then
                      table.insert(stderr_lines, line)
                      -- Also update fidget for errors
                      if handle and line:match("^error") then
                        vim.schedule(function()
                          if handle then handle.message = "Error detected..." end
                        end)
                      end
                    end
                  end
                end
              end,
              on_exit = function(_, exit_code)
                vim.schedule(function()
                  if handle then
                    if exit_code == 0 then
                      handle.message = "Complete"
                      handle:finish()
                    else
                      handle.message = "Failed (exit " .. exit_code .. ")"
                      handle:finish()
                      -- Show errors in quickfix for failed builds
                      if #stderr_lines > 0 then
                        vim.fn.setqflist({}, " ", {
                          title = "Cargo Build Errors",
                          lines = stderr_lines,
                        })
                        vim.notify("Build failed - see quickfix (:copen)", vim.log.levels.ERROR)
                      end
                    end
                  elseif exit_code ~= 0 then
                    vim.notify("Cargo command failed (exit " .. exit_code .. ")", vim.log.levels.ERROR)
                  end
                end)
              end,
            })
          end,
        }
      end

      vim.g.rustaceanvim = {
        tools = {
          hover_actions = { auto_focus = true },
          -- Use custom fidget executor for all runnables
          executor = create_fidget_executor(),
          -- Use background executor for test suites
          test_executor = "background",
          crate_test_executor = "background",
        },
        server = {
          on_attach = function(client, bufnr)
            -- Enable formatting
            client.server_capabilities.documentFormattingProvider = true
            -- Format on save
            vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = format_augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, async = false })
              end,
            })
          end,
          default_settings = {
            ["rust-analyzer"] = {
              lru = { capacity = 4096 },
              cargo = { allFeatures = false, buildScripts = { enable = true } },
              procMacro = { enable = true },
              diagnostics = { enable = true, experimental = { enable = false } },
              checkOnSave = {
                enable = true,
                command = "check",
                extraArgs = { "--target-dir", "target/analyzer" },
              },
              inlayHints = {
                parameterHints = { enable = false },
                chainingHints = { enable = false },
                closingBraceHints = { enable = false },
                typeHints = { enable = true },
              },
              completion = { limit = 50, autoimport = { enable = true } },
            },
          },
        },
        dap = {
          adapter = adapter_config,
        },
      }

      -- Also register the adapter with nvim-dap directly
      if codelldb_path and liblldb_path then
        local dap = require("dap")
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          host = "127.0.0.1",
          executable = {
            command = codelldb_path,
            args = { "--liblldb", liblldb_path, "--port", "${port}" },
          },
        }
        dap.configurations.rust = {
          {
            name = "Launch",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            -- Use integrated terminal instead of external
            terminal = "integrated",
            console = "integratedTerminal",
          },
        }
        -- Default configuration for debugging (suppress external terminal)
        dap.defaults.fallback.terminal_win_cmd = "enew"
        dap.defaults.fallback.force_external_terminal = false
        dap.defaults.fallback.external_terminal = nil
      end
    end,
  },
  -- DAP UI for debugging
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "DAP Eval", mode = { "n", "v" } },
      { "<leader>dK", function() require("dapui").eval() end, desc = "Eval under cursor" },
      { "<leader>dd", function()
        -- Ensure dapui is loaded before starting debug
        require("dapui")
        if vim.bo.filetype == "rust" then
          vim.cmd.RustLsp("debuggables")
        else
          require("dap").continue()
        end
      end, desc = "Start debugging" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      -- Create a help buffer with keybindings
      local help_buf = nil

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.40 },
              { id = "stacks", size = 0.30 },
              { id = "watches", size = 0.15 },
              { id = "breakpoints", size = 0.15 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 1.0 },
            },
            size = 10,
            position = "bottom",
          },
        },
        floating = {
          border = "rounded",
          mappings = { close = { "q", "<Esc>" } },
        },
        controls = {
          enabled = true,
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "",
            terminate = "",
          },
        },
        -- Don't open terminal/console automatically
        render = {
          max_type_length = nil,
          max_value_lines = 100,
        },
      })

      -- Ergonomic debug keymaps (only active during debug session)
      local debug_keymap_group = vim.api.nvim_create_augroup("DebugKeymaps", { clear = true })
      local debug_keymaps_set = false

      local function set_debug_keymaps()
        if debug_keymaps_set then return end
        debug_keymaps_set = true

        -- Store original mappings to restore later
        local opts = { noremap = true, silent = true }

        -- Single-key debug controls (only in normal mode, non-recursive)
        vim.keymap.set("n", "s", function() dap.step_over() end, { desc = "Debug: Step Over", unpack(opts) })
        vim.keymap.set("n", "S", function() dap.step_into() end, { desc = "Debug: Step Into", unpack(opts) })
        vim.keymap.set("n", "O", function() dap.step_out() end, { desc = "Debug: Step Out", unpack(opts) })
        vim.keymap.set("n", "c", function() dap.continue() end, { desc = "Debug: Continue", unpack(opts) })
        vim.keymap.set("n", "b", function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint", unpack(opts) })
        vim.keymap.set("n", "B", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Debug: Conditional Breakpoint", unpack(opts) })
        vim.keymap.set("n", "q", function()
          dap.terminate()
          dapui.close()
          clear_debug_keymaps()
          vim.notify("Debug session ended", vim.log.levels.INFO)
        end, { desc = "Debug: Quit/Terminate", unpack(opts) })
        vim.keymap.set("n", "<Esc>", function()
          dap.terminate()
          dapui.close()
          clear_debug_keymaps()
          vim.notify("Debug session ended", vim.log.levels.INFO)
        end, { desc = "Debug: Exit", unpack(opts) })
        vim.keymap.set("n", "e", function() dapui.eval() end, { desc = "Debug: Eval", unpack(opts) })
        vim.keymap.set("n", "K", function() dapui.eval() end, { desc = "Debug: Eval Under Cursor", unpack(opts) })
        vim.keymap.set("n", "p", function() dap.pause() end, { desc = "Debug: Pause", unpack(opts) })
        vim.keymap.set("n", "r", function() dap.run_to_cursor() end, { desc = "Debug: Run to Cursor", unpack(opts) })
        vim.keymap.set("n", "C", function() dap.clear_breakpoints() end, { desc = "Debug: Clear Breakpoints", unpack(opts) })
        vim.keymap.set("n", "?", function()
          local buf = get_help_buf()
          local width = 33
          local height = 12
          local win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            width = width,
            height = height,
            col = vim.o.columns - width - 2,
            row = 1,
            style = "minimal",
            border = "rounded",
            focusable = false,
            zindex = 50,
          })
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 5000)
        end, { desc = "Debug: Show Help", unpack(opts) })
      end

      local function clear_debug_keymaps()
        if not debug_keymaps_set then return end
        debug_keymaps_set = false

        -- Remove debug keymaps
        local keys = { "s", "S", "O", "c", "b", "B", "q", "e", "K", "p", "r", "C", "?", "<Esc>" }
        for _, key in ipairs(keys) do
          pcall(vim.keymap.del, "n", key)
        end
      end

      -- Update help text with new keybindings
      local function get_help_buf()
        if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
          return help_buf
        end
        help_buf = vim.api.nvim_create_buf(false, true)
        local help_lines = {
          "╭─ Debug Controls ─────────────╮",
          "│ s       Step Over            │",
          "│ S       Step Into            │",
          "│ O       Step Out             │",
          "│ c       Continue             │",
          "│ p       Pause                │",
          "│ b       Toggle Breakpoint    │",
          "│ B       Cond. Breakpoint     │",
          "│ C       Clear Breakpoints    │",
          "│ r       Run to Cursor        │",
          "│ e / K   Eval Expression      │",
          "│ q / Esc Exit Debug           │",
          "│ ?       Show This Help       │",
          "╰───────────────────────────────╯",
        }
        vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)
        vim.api.nvim_buf_set_option(help_buf, "modifiable", false)
        vim.api.nvim_buf_set_option(help_buf, "buftype", "nofile")
        return help_buf
      end

      -- Function to open debug UI and set keymaps
      local function on_debug_start()
        dapui.open()
        set_debug_keymaps()
        -- Show help in a floating window
        vim.defer_fn(function()
          local buf = get_help_buf()
          local width = 33
          local height = 14
          local win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            width = width,
            height = height,
            col = vim.o.columns - width - 2,
            row = 1,
            style = "minimal",
            border = "none",
            focusable = false,
            zindex = 50,
          })
          vim.api.nvim_win_set_option(win, "winblend", 10)
          -- Close help window after 6 seconds
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 6000)
        end, 300)
      end

      -- Function to close debug UI and clear keymaps
      local function on_debug_end()
        clear_debug_keymaps()
        dapui.close()
      end

      -- Register listeners for ALL debug events
      dap.listeners.before.attach.dapui_config = on_debug_start
      dap.listeners.before.launch.dapui_config = on_debug_start
      dap.listeners.after.event_initialized.dapui_config = on_debug_start

      dap.listeners.before.event_terminated.dapui_config = on_debug_end
      dap.listeners.before.event_exited.dapui_config = on_debug_end
      dap.listeners.after.disconnect.dapui_config = on_debug_end

      -- Also hook into session start/end directly
      dap.listeners.after.launch.dapui_config = function()
        vim.defer_fn(function()
          if dap.session() then
            on_debug_start()
          end
        end, 100)
      end
    end,
  },
  -- DAP virtual text (show variable values inline)
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = { commented = true },
  },
  -- Core DAP with keybindings
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue/Start debugging" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<F5>", function() require("dap").continue() end, desc = "Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Step out" },
    },
    config = function()
      -- Custom highlight groups for better visibility
      vim.api.nvim_set_hl(0, "DapBreakpointHL", { fg = "#ff5555", bg = "#3a1a1a" })
      vim.api.nvim_set_hl(0, "DapBreakpointLineHL", { bg = "#2a1515" })
      vim.api.nvim_set_hl(0, "DapStoppedHL", { fg = "#50fa7b", bg = "#1a3a1a" })
      vim.api.nvim_set_hl(0, "DapStoppedLineHL", { bg = "#1a2a1a" })

      -- Signs for breakpoints with visible red dot
      vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DapBreakpointHL",
        linehl = "DapBreakpointLineHL",
        numhl = "DapBreakpointHL",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DiagnosticWarn",
        linehl = "DapBreakpointLineHL",
        numhl = "DiagnosticWarn",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = "○",
        texthl = "DiagnosticError",
      })
      vim.fn.sign_define("DapStopped", {
        text = "→",
        texthl = "DapStoppedHL",
        linehl = "DapStoppedLineHL",
        numhl = "DapStoppedHL",
      })
      vim.fn.sign_define("DapLogPoint", {
        text = "◈",
        texthl = "DiagnosticInfo",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "nvimtools/none-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost", -- Load after file is read
  },
  --- display lsp errors using trouble
  {
    "folke/trouble.nvim",
    cmd = "Trouble", -- Load on command
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true<cr>", desc = "Diagnostics" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  -- refactor plugin
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar", -- Load on command only
    opts = {},
  },
  -- overrde plugin configs
  -- {
  --   'rcarriga/nvim-notify',
  --   lazy = false,
  --   config = function()
  --     require('notify').setup({
  --       background_colour = "NotifyBackground",
  --       fps = 30,
  --       icons = {
  --         DEBUG = "",
  --         ERROR = "",
  --         INFO = "",
  --         TRACE = "✎",
  --         WARN = ""
  --       },
  --       level = 2,
  --       minimum_width = 50,
  --       max_height = 1,
  --       render = "default",
  --       stages = "fade",
  --       time_formats = {
  --         notification = "%T",
  --         notification_history = "%FT%T"
  --       },
  --       timeout = 2000,
  --       top_down = false
  --   })
  --   end
  -- },
  -- {
  --   'mrded/nvim-lsp-notify',
  --   lazy = false,
  --   requires = { 'rcarriga/nvim-notify' },
  --   config = function()
  --     require('lsp-notify').setup({
  --       notify = require('notify'),
  --     })
  --   end
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },
  {
    "alaviss/nim.nvim",
    lazy = true,
  },
  {
    "lervag/vimtex",
    ft = "tex",
    lazy = true,
    config = function()
      vim.g.vimtex_format_enabled = true
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        callback = 1,
        continuous = 1,
        options = {
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
          "-shell-escape",
        },
      }
      -- Quickfix: don't open automatically
      vim.g.vimtex_quickfix_mode = 0
    end,
  },
  --- java
  {
    "nvim-java/nvim-java",
    ft = "java",
    lazy = true,
    dependencies = {
      "nvim-java/lua-async-await",
      "nvim-java/nvim-java-refactor",
      "nvim-java/nvim-java-core",
      "nvim-java/nvim-java-test",
      "nvim-java/nvim-java-dap",
      "MunifTanjim/nui.nvim",
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      {
        "JavaHello/spring-boot.nvim",
        commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
      },
      {
        "williamboman/mason.nvim",
        opts = {
          registries = {
            "github:nvim-java/mason-registry",
            "github:mason-org/mason-registry",
          },
        },
      },
    },
  },
  -- {
  --   "neoclide/coc.nvim",
  --   lazy = false,
  --   branch ="release",
  --   build = "yarn install --frozen-lockfile"
  -- },
  {
    "ianks/vim-tsx",
    lazy = true,
  },
  ---- coq
  {
    "whonore/Coqtail",
    lazy = true,
    ft = "coq",
  },
  ---- asm_lsp
  {
    "rush-rs/tree-sitter-asm",
    lazy = true,
    ft = "asm",
  },
  --- git
  { "tpope/vim-fugitive", version = "*", lazy = true },
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit", -- Load on command only
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  --- peeking on defintion under cursor
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "BufReadPost",
  },
  --- Typescript Tools
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
    lazy = true,
    ft = "typescript",
  },
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialNext", "AerialPrev" },
    keys = {
      { "<leader>a", "<cmd>AerialToggle!<CR>", desc = "Toggle Aerial" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },
  -- Flowistry: Data flow analysis for Rust (trace variable origins)
  {
    "lcian/flowistry.nvim",
    ft = "rust",
    config = function()
      -- Highlights: relevant code keeps normal syntax, only irrelevant is dimmed
      -- Mark: just underline the selected expression (no bg override)
      vim.api.nvim_set_hl(0, "FlowistryMark", { underline = true, bold = true, sp = "#a080ff" })
      -- Direct: no change - keeps normal syntax highlighting
      vim.api.nvim_set_hl(0, "FlowistryDirect", {})
      -- Indirect: no change - keeps normal syntax highlighting
      vim.api.nvim_set_hl(0, "FlowistryIndirect", {})
      -- Backdrop: gray out irrelevant code
      vim.api.nvim_set_hl(0, "FlowistryBackdrop", { fg = "#505050" })

      require("flowistry").setup({
        register_default_keymaps = false,
        toolchain = "nightly-2025-08-20",
        log_level = "info",
        highlight = {
          mark = { link = "FlowistryMark" },
          direct = { link = "FlowistryDirect" },
          indirect = { link = "FlowistryIndirect" },
          backdrop = { link = "FlowistryBackdrop" },
        },
      })
    end,
  },
  -- LSP enhancements (call hierarchy, symbols, etc.)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      symbol_in_winbar = {
        enable = false,
      },
      lightbulb = {
        enable = false,
      },
      outline = {
        enable = false,
      },
      finder = {
        keys = {
          edit = "<CR>",
          vsplit = "v",
          split = "s",
          quit = "q",
          close = "<Esc>",
        },
      },
      definition = {
        keys = {
          edit = "<CR>",
          vsplit = "v",
          split = "s",
          quit = "q",
          close = "<Esc>",
        },
      },
      callhierarchy = {
        layout = "float",
        keys = {
          edit = "<CR>",
          vsplit = "v",
          split = "s",
          quit = "q",
          toggle_or_req = "u",
          close = "<Esc>",
        },
      },
      ui = {
        border = "rounded",
        code_action = "",
      },
    },
  },
  -- LSP progress indicator
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        suppress_on_insert = true,
        ignore_done_already = true,
        display = {
          render_limit = 3,
          done_ttl = 1,
          done_icon = "",
          progress_icon = { pattern = "moon", period = 1 },
          icon_style = "Normal",
          group_style = "Title",
          progress_style = "Comment",
          done_style = "Constant",
          format_message = function(msg)
            if msg.message then
              return msg.message
            end
            return msg.done and "" or "..."
          end,
          format_group_name = function(group)
            return tostring(group):gsub("_", " ")
          end,
        },
      },
      notification = {
        -- Override vim.notify to display all notifications as fidget notifications
        -- This converts blocking inline messages to non-blocking side notifications
        override_vim_notify = true,
        window = {
          winblend = 0,
          border = "none",
          align = "bottom",
          relative = "editor",
        },
        view = {
          stack_upwards = true,
          render_message = function(msg, cnt)
            return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
          end,
        },
      },
    },
  },
}

return languages_and_lsps
