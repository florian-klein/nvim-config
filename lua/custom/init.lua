-- Performance optimizations
vim.loader.enable() -- Enable faster Lua module loading

-- Defer ShaDa (viminfo) loading to avoid blocking startup (~3.6ms saving)
local shada = vim.fn.stdpath("state") .. "/shada/main.shada"
vim.opt.shadafile = "NONE"
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.opt.shadafile = shada
    pcall(vim.cmd.rshada, { bang = true })
  end,
})

-- Suppress Node.js deprecation warnings from LSP servers (html-lsp, css-lsp)
vim.env.NODE_NO_WARNINGS = "1"

-- Faster timeout for key sequences
vim.opt.timeoutlen = 300

-- Limit syntax highlighting for long lines (performance)
vim.opt.synmaxcol = 300

-- Defer vim.diagnostic loading to avoid 0.33ms eager require
vim.api.nvim_create_autocmd("LspAttach", {
  once = true,
  callback = function()
    vim.diagnostic.config({
      update_in_insert = false,
      virtual_text = { spacing = 4 },
      severity_sort = true,
    })
  end,
})

-- Disable expensive features for large files
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 512 * 1024 then -- 512KB threshold
      vim.b[args.buf].large_buf = true
      -- Immediate lightweight disables
      vim.opt_local.syntax = "off"
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      -- Defer heavier operations to avoid blocking file open
      vim.schedule(function()
        pcall(vim.cmd, "TSBufDisable highlight")
        pcall(vim.cmd, "TSBufDisable indent")
        pcall(vim.cmd, "IBLDisable") -- indent-blankline v3
        -- Detach LSP for very large files (>2MB)
        if stats.size > 2 * 1024 * 1024 then
          vim.schedule(function()
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
              client:stop()
            end
          end)
        end
      end)
    end
  end,
})

vim.g.leetcode_solution_filetype = "cpp"
vim.g.maplocalleader = ","
vim.g.leetcode_browser = "chrome"

-- Disable swap files entirely (prevents prompts during debugging)
-- Recovery is handled by undo persistence instead
vim.opt.swapfile = false

-- OCaml treesitter highlight overrides
vim.api.nvim_set_hl(0, "@punctuation.delimiter.ocaml", { link = "Boolean" })
vim.api.nvim_set_hl(0, "@variable.parameter.ocaml", { link = "Boolean" })
