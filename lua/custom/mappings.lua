--@type MappingsTable
local M = {}

M.ignore = {}

-- Custom code actions menu - merges LSP actions with tracing options
local function show_code_actions_menu()
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }

  vim.lsp.buf_request_all(0, "textDocument/codeAction", params, function(results)
    local actions = {}

    -- Add LSP code actions
    for client_id, result in pairs(results or {}) do
      if result.result then
        for _, action in ipairs(result.result) do
          table.insert(actions, {
            label = action.title,
            action = function()
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
              end
              if action.command then
                local client = vim.lsp.get_client_by_id(client_id)
                if client then
                  client.request("workspace/executeCommand", action.command, function() end, 0)
                end
              end
            end,
          })
        end
      end
    end

    -- Add tracing options
    table.insert(actions, { label = " Incoming Calls (trace callers)", action = function() vim.cmd("Lspsaga incoming_calls") end })
    table.insert(actions, { label = " Outgoing Calls (trace callees)", action = function() vim.cmd("Lspsaga outgoing_calls") end })
    table.insert(actions, { label = " Find All References", action = function() vim.cmd("Lspsaga finder") end })
    table.insert(actions, { label = " Peek Definition", action = function() vim.cmd("Lspsaga peek_definition") end })
    table.insert(actions, { label = " Peek Type Definition", action = function() vim.cmd("Lspsaga peek_type_definition") end })

    -- Rust-specific actions (Flowistry data flow analysis)
    if vim.bo.filetype == "rust" then
      table.insert(actions, {
        label = " Focus Mode (data flow)",
        action = function()
          vim.notify("Flowistry: Analyzing data flow...", vim.log.levels.INFO)
          vim.cmd("Flowistry focus toggle")
        end
      })
      table.insert(actions, {
        label = " Mark for Tracing",
        action = function()
          vim.cmd("Flowistry mark set")
          vim.notify("Flowistry: Mark set at cursor", vim.log.levels.INFO)
        end
      })
      table.insert(actions, {
        label = " Remove Mark",
        action = function()
          vim.cmd("Flowistry mark remove")
          vim.notify("Flowistry: Mark removed", vim.log.levels.INFO)
        end
      })
    end

    if #actions == 0 then
      vim.notify("No code actions available", vim.log.levels.INFO)
      return
    end

    vim.ui.select(actions, {
      prompt = "Code Actions",
      format_item = function(item) return item.label end,
    }, function(choice)
      if choice then choice.action() end
    end)
  end)
end

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["s"] = { ":vs<CR>", "split" },
    ["x"] = { ":wq<CR>", "quit" },
    ["<C-s>"] = { ":lua vim.lsp.buf.format()<CR>:w<CR>", "format and save file" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "Git branches" },
    -- Enhanced live grep with pattern support
    ["<leader>fw"] = {
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      "Live grep (with args)"
    },
    -- Undo history browser
    ["<leader>fu"] = { "<cmd>Telescope undo<CR>", "Undo history" },
    -- Frecency - frequency+recency based file finding
    ["<leader>fp"] = { "<cmd>Telescope frecency<CR>", "Frecency files" },
    ["<leader>xx"] = { "<cmd>Trouble diagnostics toggle focus=true<cr>", "Trouble" },
    ["<leader>qf"] = { "<cmd>Trouble qflist toggle<cr>", "View Quickfix Options" },
    ["<leader>xd"] = { "<cmd>lua require('trouble').toggle('document_diagnostics')<CR>", "Document Diagnostics" },
    ["<leader>xq"] = { "<cmd>lua require('trouble').toggle('quickfix')<CR>", "Quickfix" },
    ["<leader>xl"] = { "<cmd>lua require('trouble').toggle('loclist')<CR>", "Loclist" },
    ["<leader>a"] = { "<cmd>AerialToggle!<CR>" },
    ["<C-m>"] = { "<cmd>AerialPrev<CR>" },
    ["<C-n>"] = { ":cnext<CR>", "Next quickfix item" },
    ["<C-p>"] = { ":cprev<CR>", "Previous quickfix item" },
    ["<leader>cf"] = { ":cfirst<CR>", "First quickfix item" },
    ["<leader>cl"] = { ":clast<CR>", "Last quickfix item" },
    ["<C-M>"] = { "<cmd>AerialNext<CR>" },
    ["gR"] = { "<cmd>lua require('trouble').toggle('lsp_references')<CR>", "LSP References" },
    -- Git blame code highlighting (actual line backgrounds by commit age)
    ["<leader>bh"] = { function() require("custom.configs.blame-highlight").toggle() end, "Toggle blame line highlighting" },
    -- Code actions menu (includes LSP actions + call hierarchy + finder)
    ["<leader>ca"] = { function() show_code_actions_menu() end, "Code actions menu" },
    -- Rust-specific: rerun last debug (main debug keybinding is in nvim-dap-ui config)
    ["<leader>dL"] = {
      function()
        if vim.bo.filetype == "rust" then
          -- Rerun last debug session
          vim.cmd.RustLsp({ "debuggables", bang = true })
        else
          vim.notify("Not a Rust file", vim.log.levels.WARN)
        end
      end,
      "Rerun last Rust debug"
    },
    ["<leader>rt"] = {
      function()
        if vim.bo.filetype == "rust" then
          -- Run tests (no debug, uses cargo test/nextest)
          vim.cmd.RustLsp("testables")
        else
          vim.notify("Not a Rust file", vim.log.levels.WARN)
        end
      end,
      "Run Rust test"
    },
    ["<leader>rr"] = {
      function()
        if vim.bo.filetype == "rust" then
          -- Run any target (no debug)
          vim.cmd.RustLsp("runnables")
        else
          vim.notify("Not a Rust file", vim.log.levels.WARN)
        end
      end,
      "Run Rust target"
    },
    -- ["f"] = { "<cmd>lua require('leap').leap({target_windows = {vim.fn.win_getid()}})<CR>", "Leap forward" },
    -- ["F"] = { "<cmd>lua require('leap').leap({target_windows = {vim.fn.win_getid()}, backward = true})<CR>", "Leap backward" },

    -- ─── LaTeX Preview (fancy-cat in kitty) ───────────────────────────────────
    ["<leader>lp"] = {
      function()
        local pdf = vim.fn.expand("%:p:r") .. ".pdf"
        local socket = vim.env.KITTY_LISTEN_ON
        if not socket then
          vim.notify("KITTY_LISTEN_ON not set - restart kitty with remote control enabled", vim.log.levels.ERROR)
          return
        end
        if vim.fn.filereadable(pdf) == 1 then
          -- Switch to splits layout and launch fancy-cat in a 30% right split
          vim.fn.system("kitty @ --to " .. socket .. " goto-layout splits")
          vim.fn.system("kitty @ --to " .. socket .. " launch --location=vsplit --bias=30 fancy-cat " .. vim.fn.shellescape(pdf))
        else
          vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN)
        end
      end,
      "LaTeX: Preview PDF (30% right split)"
    },
    ["<leader>lc"] = {
      function()
        local file = vim.fn.expand("%")
        vim.notify("Compiling LaTeX...", vim.log.levels.INFO)
        vim.fn.jobstart({ "latexmk", "-pdf", "-interaction=nonstopmode", file }, {
          on_exit = function(_, code)
            if code == 0 then
              vim.notify("LaTeX compiled successfully", vim.log.levels.INFO)
            else
              vim.notify("LaTeX compilation failed", vim.log.levels.ERROR)
            end
          end,
        })
      end,
      "LaTeX: Compile PDF"
    },
    ["<leader>lw"] = {
      function()
        local file = vim.fn.expand("%")
        vim.notify("Starting latexmk watch mode...", vim.log.levels.INFO)
        vim.fn.jobstart({ "latexmk", "-pdf", "-pvc", "-interaction=nonstopmode", file }, {
          detach = true,
        })
      end,
      "LaTeX: Start watch mode (continuous compile)"
    },
    ["<leader>lx"] = {
      function()
        local dir = vim.fn.expand("%:p:h")
        vim.notify("Cleaning LaTeX auxiliary files...", vim.log.levels.INFO)
        vim.fn.jobstart({ "latexmk", "-c" }, {
          cwd = dir,
          on_exit = function(_, code)
            if code == 0 then
              vim.notify("LaTeX aux files cleaned", vim.log.levels.INFO)
            end
          end,
        })
      end,
      "LaTeX: Clean auxiliary files"
    },
  },
  v = {
    ["<TAB>"] = { ">gv", "shift selected text right" },
    ["<S-TAB>"] = { "<gv", "shift selected text left" },
  },
}

return M
