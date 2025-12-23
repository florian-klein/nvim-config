local present, null_ls = pcall(require, "null-ls")

if not present then
  vim.notify("null-ls not found! Skipping null-ls setup.", vim.log.levels.ERROR)
  return
end
--
local b = null_ls.builtins

local sources = {
  -- Webdev stuff
  b.formatting.prettier, -- Prettier for HTML, Markdown, CSS, and JavaScript
  -- Rust
  -- b.formatting.rustfmt, -- Rustfmt for Rust
  -- python
  b.formatting.black,
  -- C/C++
  b.formatting.clang_format, -- Clang-format for C/C++
  -- formatting for lua
  b.formatting.stylua, -- Stylua for Lua
  -- -- latex formatting
  -- b.formatting.latexindent, -- Latexindent for Latex
  -- --- typescript
  -- b.formatting.eslint, -- Eslint for TypeScript
  --- google java formatting
  b.formatting.google_java_format, -- Google Java Format for Java

  -- Linting
  -- b.diagnostics.shellcheck, -- Shellcheck for Shell
  -- b.diagnostics.checkstyle.with({
  --       extra_args = { "-c", "/Users/florianklein/.config/checkstyle" }, -- or "/sun_checks.xml" or path to self written rules
  -- }),
}

-- null_ls.setup {
--   debug = true,
--   sources = sources,
-- }

-- -- Enable format on save for supported filetypes
-- -- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
-- require("null-ls").setup {
--   -- you can reuse a shared lspconfig on_attach callback here
--   on_attach = function(client, bufnr)
--     if client.supports_method "textDocument/formatting" then
--       vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
--       vim.api.nvim_create_autocmd("BufWritePre", {
--         group = augroup,
--         buffer = bufnr,
--         callback = function()
--           -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
--           -- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
--           vim.lsp.buf.formatting_sync()
--         end,
--       })
--     end
--   end,
-- }
