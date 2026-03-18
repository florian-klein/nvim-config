-- Performance optimizations
vim.loader.enable() -- Enable faster Lua module loading

-- Suppress Node.js deprecation warnings from LSP servers (html-lsp, css-lsp)
vim.env.NODE_NO_WARNINGS = "1"

-- Reduce updatetime for faster CursorHold events
vim.opt.updatetime = 250

-- Faster timeout for key sequences
vim.opt.timeoutlen = 300

-- Limit syntax highlighting for long lines (performance)
vim.opt.synmaxcol = 300

-- Disable unused providers
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Debounce LSP diagnostics for better performance
vim.diagnostic.config({
  update_in_insert = false, -- Don't update diagnostics in insert mode
  virtual_text = { spacing = 4 },
  severity_sort = true,
})

-- Disable expensive features for large files
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function(args)
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
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
        pcall(vim.cmd, "IBLDisable") -- indent-blankline
        -- Detach LSP for very large files (>2MB)
        if stats.size > 2 * 1024 * 1024 then
          vim.schedule(function()
            vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = args.buf }))
          end)
        end
      end)
    end
  end,
})

-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
vim.g.leetcode_solution_filetype = "cpp"
vim.g.maplocalleader = ","
-- vim.g.copilot_disable_diagnostics = false
vim.g.leetcode_browser = "chrome"
-- vim.opt.conceallevel = 1
-- Copilot keybindings are set in plugins.lua config

vim.g.vimtex_format_enabled = true

-- Disable swap files entirely (prevents prompts during debugging)
-- Recovery is handled by undo persistence instead
vim.opt.swapfile = false

-- Enable persistent undo as alternative to swap file recovery
vim.opt.undofile = true

vim.g.vimtex_view_method = "skim"

vim.g.vimtex_compiler_latexmk = {
  options = {
    "-verbose",
    "-file-line-error",
    "-synctex=1",
    "-interaction=nonstopmode",
    "-shell-escape",
  },
}
